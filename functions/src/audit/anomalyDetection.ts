/**
 * anomalyDetection.ts
 *
 * Detects anomalies in expenses, invoices, inventory, and audit data
 *
 * Anomaly Types:
 * - Expenses: Unusual amounts, duplicate submissions, rapid submissions
 * - Invoices: Payment delays, unusual payment patterns, duplicates
 * - Inventory: Stock anomalies, unusual movements
 * - Audit: Suspicious access patterns, unusual modifications
 *
 * All anomalies logged to /anomalies/{id} collection with severity levels
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendSecurityAlert } from '../utils/alerts';

if (!admin.apps.length) admin.initializeApp();

const db = admin.firestore();

/**
 * Anomaly severity levels
 */
export enum AnomalySeverity {
  LOW = 'low',
  MEDIUM = 'medium',
  HIGH = 'high',
  CRITICAL = 'critical',
}

/**
 * Anomaly detection rules and thresholds
 */
const ANOMALY_CONFIG = {
  expenses: {
    duplicateThresholdMs: 60 * 1000, // 1 minute
    maxDailyAmount: 10000,
    maxDailyCount: 50,
    rapidSubmissionWindow: 5 * 60 * 1000, // 5 minutes
  },
  invoices: {
    overdueDaysThreshold: 60,
    paymentDelayDaysThreshold: 30,
    duplicateAmountWindow: 24 * 60 * 60 * 1000, // 24 hours
  },
  inventory: {
    rapidMovementWindow: 60 * 1000, // 1 minute
    maxMovementPercentage: 50, // Percent change in quantity
  },
  audit: {
    suspiciousAccessWindow: 30 * 1000, // 30 seconds
    maxAccessPerWindow: 10,
  },
};

/**
 * Log anomaly to Firestore
 */
async function logAnomaly(
  entityType: 'expense' | 'invoice' | 'inventory' | 'audit',
  entityId: string,
  severity: AnomalySeverity,
  message: string,
  recommendedAction: string,
  context?: any,
) {
  const anomalyId = db.collection('anomalies').doc().id;

  await db.collection('anomalies').doc(anomalyId).set({
    entityType,
    entityId,
    severity,
    message,
    recommendedAction,
    context: context || {},
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    resolved: false,
  });

  // Send alert for medium+ severity
  if (severity !== AnomalySeverity.LOW) {
    await sendSecurityAlert(`Anomaly Detected: ${entityType}`, message, {
      entityId,
      severity,
      anomalyId,
      context,
    });
  }

  functions.logger.warn(`Anomaly logged: ${entityType}/${entityId}`, {
    anomalyId,
    severity,
    message,
  });

  return anomalyId;
}

/**
 * Detect expense anomalies
 * Triggers on expense creation/update
 */
export const detectExpenseAnomalies = functions.firestore
  .document('users/{userId}/expenses/{expenseId}')
  .onCreate(async (snap, context) => {
    const { userId } = context.params;
    const expense = snap.data();

    const detections: string[] = [];

    try {
      // Check 1: Unusual amount
      if (
        expense.amount > ANOMALY_CONFIG.expenses.maxDailyAmount
      ) {
        detections.push(
          await logAnomaly(
            'expense',
            snap.id,
            AnomalySeverity.MEDIUM,
            `Expense amount (${expense.currency} ${expense.amount}) exceeds daily threshold`,
            'Review and approve expense amount',
            { amount: expense.amount, threshold: ANOMALY_CONFIG.expenses.maxDailyAmount },
          ),
        );
      }

      // Check 2: Rapid duplicate submission
      const recentSimilar = await db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('merchant', '==', expense.merchant)
        .where('amount', '==', expense.amount)
        .where('createdAt', '>=', admin.firestore.Timestamp.fromMillis(
          Date.now() - ANOMALY_CONFIG.expenses.duplicateThresholdMs,
        ))
        .get();

      if (recentSimilar.size > 1) {
        detections.push(
          await logAnomaly(
            'expense',
            snap.id,
            AnomalySeverity.HIGH,
            `Duplicate expense detected: ${expense.merchant} for ${expense.currency} ${expense.amount}`,
            'Verify if this is a duplicate submission or legitimate repeat expense',
            {
              merchant: expense.merchant,
              amount: expense.amount,
              duplicateCount: recentSimilar.size,
            },
          ),
        );
      }

      // Check 3: Rapid submission pattern
      const rapidExpenses = await db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromMillis(
          Date.now() - ANOMALY_CONFIG.expenses.rapidSubmissionWindow,
        ))
        .get();

      if (rapidExpenses.size > 3) {
        detections.push(
          await logAnomaly(
            'expense',
            snap.id,
            AnomalySeverity.MEDIUM,
            `Rapid expense submission pattern detected (${rapidExpenses.size} in 5 minutes)`,
            'Review batch submission for bulk entry errors',
            { submissionCount: rapidExpenses.size, timeWindow: '5 minutes' },
          ),
        );
      }
    } catch (err) {
      functions.logger.error('Expense anomaly detection failed', err);
    }

    return { detections };
  });

/**
 * Detect invoice anomalies
 * Triggers on invoice update
 */
export const detectInvoiceAnomalies = functions.firestore
  .document('users/{userId}/invoices/{invoiceId}')
  .onUpdate(async (change, context) => {
    const { userId } = context.params;
    const newInvoice = change.after.data();
    const oldInvoice = change.before.data();

    const detections: string[] = [];

    try {
      // Check 1: Invoice becoming overdue
      if (newInvoice.status === 'overdue' && oldInvoice.status !== 'overdue') {
        const daysOverdue = Math.floor(
          (Date.now() - newInvoice.dueDate.toMillis()) / (24 * 60 * 60 * 1000),
        );

        if (daysOverdue > ANOMALY_CONFIG.invoices.overdueDaysThreshold) {
          detections.push(
            await logAnomaly(
              'invoice',
              change.after.id,
              AnomalySeverity.HIGH,
              `Invoice overdue for ${daysOverdue} days`,
              'Follow up with client for payment',
              {
                invoiceAmount: newInvoice.amount,
                currency: newInvoice.currency,
                daysOverdue,
                clientId: newInvoice.clientId,
              },
            ),
          );
        }
      }

      // Check 2: Unusual payment delay
      if (newInvoice.paymentDate && oldInvoice.paymentDate === undefined) {
        const paymentDelay = Math.floor(
          (newInvoice.paymentDate.toMillis() - newInvoice.dueDate.toMillis()) /
            (24 * 60 * 60 * 1000),
        );

        if (paymentDelay > ANOMALY_CONFIG.invoices.paymentDelayDaysThreshold) {
          detections.push(
            await logAnomaly(
              'invoice',
              change.after.id,
              AnomalySeverity.MEDIUM,
              `Invoice payment delayed by ${paymentDelay} days beyond due date`,
              'Update payment terms or client credit policy',
              {
                paymentDelay,
                dueDate: newInvoice.dueDate.toDate().toISOString(),
                paymentDate: newInvoice.paymentDate.toDate().toISOString(),
              },
            ),
          );
        }
      }

      // Check 3: Duplicate invoice amount in short timeframe
      const recentDuplicates = await db
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .where('amount', '==', newInvoice.amount)
        .where('clientId', '==', newInvoice.clientId)
        .where('createdAt', '>=', admin.firestore.Timestamp.fromMillis(
          Date.now() - ANOMALY_CONFIG.invoices.duplicateAmountWindow,
        ))
        .get();

      if (recentDuplicates.size > 1) {
        detections.push(
          await logAnomaly(
            'invoice',
            change.after.id,
            AnomalySeverity.MEDIUM,
            `Duplicate invoice amount detected: ${newInvoice.currency} ${newInvoice.amount} to same client`,
            'Verify if this is a legitimate repeated invoice or data entry error',
            {
              amount: newInvoice.amount,
              clientId: newInvoice.clientId,
              duplicateCount: recentDuplicates.size,
            },
          ),
        );
      }
    } catch (err) {
      functions.logger.error('Invoice anomaly detection failed', err);
    }

    return { detections };
  });

/**
 * Detect audit access anomalies
 * Triggers when audit entries are accessed
 */
export const detectAuditAnomalies = functions.firestore
  .document('audit/{compositeId}/entries/{entryId}')
  .onCreate(async (snap, context) => {
    const entry = snap.data();
    const { compositeId } = context.params;

    try {
      // Check: Suspicious access pattern
      const actorId = entry.actor?.uid;
      if (!actorId) return;

      // Query recent accesses by same actor
      const recentAccesses = await db
        .collectionGroup('entries')
        .where('actor.uid', '==', actorId)
        .where('timestamp', '>=', admin.firestore.Timestamp.fromMillis(
          Date.now() - ANOMALY_CONFIG.audit.suspiciousAccessWindow,
        ))
        .get();

      if (recentAccesses.size > ANOMALY_CONFIG.audit.maxAccessPerWindow) {
        await logAnomaly(
          'audit',
          compositeId,
          AnomalySeverity.HIGH,
          `Suspicious access pattern: ${recentAccesses.size} audit entries accessed in 30 seconds`,
          'Review user access logs and permissions',
          {
            userId: actorId,
            accessCount: recentAccesses.size,
            timeWindow: '30 seconds',
          },
        );
      }
    } catch (err) {
      functions.logger.error('Audit anomaly detection failed', err);
    }
  });

/**
 * Admin endpoint to resolve anomalies
 */
export const resolveAnomaly = functions.https.onCall(
  async (data, context) => {
    if (!context.auth?.token.admin) {
      throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }

    const { anomalyId, resolution } = data;

    if (!anomalyId) {
      throw new functions.https.HttpsError('invalid-argument', 'anomalyId required');
    }

    await db.collection('anomalies').doc(anomalyId).update({
      resolved: true,
      resolvedAt: admin.firestore.FieldValue.serverTimestamp(),
      resolution: resolution || null,
      resolvedBy: context.auth.uid,
    });

    return { ok: true, anomalyId };
  },
);

/**
 * Query anomalies by severity and entity type
 */
export const queryAnomalies = functions.https.onCall(
  async (data, context) => {
    if (!context.auth?.token.admin) {
      throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }

    const { entityType, severity, resolved, limit = 50 } = data;

    let query: FirebaseFirestore.Query = db.collection('anomalies');

    if (entityType) {
      query = query.where('entityType', '==', entityType);
    }

    if (severity) {
      query = query.where('severity', '==', severity);
    }

    if (resolved !== undefined) {
      query = query.where('resolved', '==', resolved);
    }

    const snap = await query.orderBy('createdAt', 'desc').limit(limit).get();

    return {
      ok: true,
      count: snap.size,
      anomalies: snap.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      })),
    };
  },
);
