/**
 * anomalyScanner.ts
 *
 * Proactive anomaly scanning service
 *
 * Scans for:
 * 1. Statistical anomalies (unusual distributions)
 * 2. Pattern anomalies (repetitive suspicious behavior)
 * 3. Temporal anomalies (unusual timing patterns)
 * 4. Relationship anomalies (unusual connections)
 *
 * Runs on a schedule (e.g., daily) and compares current data to baselines
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { sendSecurityAlert } from '../utils/alerts';

if (!admin.apps.length) admin.initializeApp();

const db = admin.firestore();

/**
 * Statistical summary for a metric
 */
interface MetricStats {
  mean: number;
  stdDev: number;
  min: number;
  max: number;
  median: number;
  count: number;
}

/**
 * Calculate basic statistics from array of numbers
 */
function calculateStats(values: number[]): MetricStats {
  if (values.length === 0) {
    return { mean: 0, stdDev: 0, min: 0, max: 0, median: 0, count: 0 };
  }

  const sorted = [...values].sort((a, b) => a - b);
  const count = values.length;
  const sum = values.reduce((a, b) => a + b, 0);
  const mean = sum / count;
  const variance = values.reduce((acc, val) => acc + Math.pow(val - mean, 2), 0) / count;
  const stdDev = Math.sqrt(variance);
  const min = sorted[0];
  const max = sorted[count - 1];
  const median = count % 2 === 0
    ? (sorted[count / 2 - 1] + sorted[count / 2]) / 2
    : sorted[Math.floor(count / 2)];

  return { mean, stdDev, min, max, median, count };
}

/**
 * Check if value is statistical outlier (>2 std dev from mean)
 */
function isOutlier(value: number, stats: MetricStats): boolean {
  if (stats.stdDev === 0) return false;
  const zScore = Math.abs((value - stats.mean) / stats.stdDev);
  return zScore > 2; // 2 standard deviations
}

/**
 * Scan for expense anomalies by statistical analysis
 */
async function scanExpenseAnomalies(): Promise<string[]> {
  const anomalyIds: string[] = [];

  try {
    // Get all users with expenses
    const usersSnapshot = await db.collection('users').get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const expensesSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('expenses')
        .where('createdAt', '>=', admin.firestore.Timestamp.fromDate(
          new Date(Date.now() - 90 * 24 * 60 * 60 * 1000), // Last 90 days
        ))
        .get();

      if (expensesSnapshot.size < 5) continue; // Need minimum data

      // Calculate stats on amounts
      const amounts = expensesSnapshot.docs.map(d => (d.data().amount as number) || 0);
      const stats = calculateStats(amounts);

      // Scan current expenses for outliers
      for (const expenseDoc of expensesSnapshot.docs) {
        const expense = expenseDoc.data();
        const amount = (expense.amount as number) || 0;

        // Check 1: Statistical outlier
        if (isOutlier(amount, stats)) {
          const anomalyId = db.collection('anomalies').doc().id;
          await db.collection('anomalies').doc(anomalyId).set({
            entityType: 'expense',
            entityId: expenseDoc.id,
            severity: amount > stats.mean + 3 * stats.stdDev ? 'high' : 'medium',
            message: `Expense amount (${expense.currency} ${amount}) is statistical outlier. Normal range: ${stats.mean.toFixed(2)} ± ${stats.stdDev.toFixed(2)}`,
            recommendedAction: 'Review expense for accuracy. Verify receipt and merchant details.',
            context: {
              amount,
              mean: stats.mean,
              stdDev: stats.stdDev,
              zScore: (amount - stats.mean) / stats.stdDev,
            },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            resolved: false,
          });
          anomalyIds.push(anomalyId);
        }

        // Check 2: Merchant concentration (same merchant >50% of expenses)
        const merchantCounts = new Map<string, number>();
        expensesSnapshot.docs.forEach(doc => {
          const merchant = (doc.data().merchant as string) || 'unknown';
          merchantCounts.set(merchant, (merchantCounts.get(merchant) || 0) + 1);
        });

        const maxMerchantCount = Math.max(...merchantCounts.values());
        const merchantConcentration = maxMerchantCount / expensesSnapshot.size;

        if (merchantConcentration > 0.5) {
          const topMerchant = Array.from(merchantCounts.entries())
            .sort((a, b) => b[1] - a[1])[0][0];

          const anomalyId = db.collection('anomalies').doc().id;
          await db.collection('anomalies').doc(anomalyId).set({
            entityType: 'expense',
            entityId: userId,
            severity: 'medium',
            message: `High merchant concentration detected: ${topMerchant} appears in ${(merchantConcentration * 100).toFixed(0)}% of expenses`,
            recommendedAction: 'Review if this is normal business spending or potential misuse.',
            context: {
              topMerchant,
              concentration: merchantConcentration,
              totalExpenses: expensesSnapshot.size,
            },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            resolved: false,
          });
          anomalyIds.push(anomalyId);
        }
      }
    }
  } catch (err) {
    functions.logger.error('Expense anomaly scan failed', err);
  }

  return anomalyIds;
}

/**
 * Scan for invoice anomalies by pattern analysis
 */
async function scanInvoiceAnomalies(): Promise<string[]> {
  const anomalyIds: string[] = [];

  try {
    const usersSnapshot = await db.collection('users').get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const invoicesSnapshot = await db
        .collection('users')
        .doc(userId)
        .collection('invoices')
        .get();

      if (invoicesSnapshot.size < 3) continue;

      // Check 1: Payment collection rate
      const paid = invoicesSnapshot.docs.filter(d => d.data().status === 'paid').length;
      const paymentRate = paid / invoicesSnapshot.size;

      if (paymentRate < 0.3) {
        // Less than 30% payment rate is concerning
        const anomalyId = db.collection('anomalies').doc().id;
        await db.collection('anomalies').doc(anomalyId).set({
          entityType: 'invoice',
          entityId: userId,
          severity: 'high',
          message: `Low payment collection rate: ${(paymentRate * 100).toFixed(0)}% (${paid}/${invoicesSnapshot.size})`,
          recommendedAction: 'Review outstanding invoices and follow up with clients.',
          context: {
            paidCount: paid,
            totalInvoices: invoicesSnapshot.size,
            paymentRate,
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          resolved: false,
        });
        anomalyIds.push(anomalyId);
      }

      // Check 2: Invoice amount variance
      const amounts = invoicesSnapshot.docs.map(d => (d.data().amount as number) || 0);
      const stats = calculateStats(amounts);
      const coefficient = stats.stdDev / stats.mean; // Coefficient of variation

      if (coefficient > 1.5) {
        // High variance in invoice amounts
        const anomalyId = db.collection('anomalies').doc().id;
        await db.collection('anomalies').doc(anomalyId).set({
          entityType: 'invoice',
          entityId: userId,
          severity: 'low',
          message: `High variance in invoice amounts. Coefficient of variation: ${coefficient.toFixed(2)}`,
          recommendedAction: 'Review invoicing patterns. Consider standardizing invoice amounts if possible.',
          context: {
            mean: stats.mean,
            stdDev: stats.stdDev,
            coefficientOfVariation: coefficient,
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          resolved: false,
        });
        anomalyIds.push(anomalyId);
      }

      // Check 3: Temporal pattern - invoices created in clusters
      const invoicesByDay = new Map<string, number>();
      invoicesSnapshot.docs.forEach(doc => {
        const createdAt = (doc.data().createdAt as admin.firestore.Timestamp).toDate();
        const dayKey = createdAt.toISOString().split('T')[0];
        invoicesByDay.set(dayKey, (invoicesByDay.get(dayKey) || 0) + 1);
      });

      const dailyCounts = Array.from(invoicesByDay.values());
      const dayStats = calculateStats(dailyCounts);

      // Check for clustering (some days have much more than others)
      for (const [day, count] of invoicesByDay.entries()) {
        if (isOutlier(count, dayStats) && count > dayStats.mean) {
          const anomalyId = db.collection('anomalies').doc().id;
          await db.collection('anomalies').doc(anomalyId).set({
            entityType: 'invoice',
            entityId: userId,
            severity: 'low',
            message: `Invoice creation clustering detected on ${day}: ${count} invoices (unusual pattern)`,
            recommendedAction: 'Verify if batch invoicing is intentional or system issue.',
            context: {
              date: day,
              count,
              meanPerDay: dayStats.mean,
            },
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
            resolved: false,
          });
          anomalyIds.push(anomalyId);
        }
      }
    }
  } catch (err) {
    functions.logger.error('Invoice anomaly scan failed', err);
  }

  return anomalyIds;
}

/**
 * Scan for user behavior anomalies
 */
async function scanUserBehaviorAnomalies(): Promise<string[]> {
  const anomalyIds: string[] = [];

  try {
    const usersSnapshot = await db.collection('users').get();

    for (const userDoc of usersSnapshot.docs) {
      const userId = userDoc.id;
      const userData = userDoc.data();

      // Check 1: Unusual admin access time
      if (userData.lastAdminAccess) {
        const lastAccess = (userData.lastAdminAccess as admin.firestore.Timestamp).toDate();
        const hourOfDay = lastAccess.getHours();
        const dayOfWeek = lastAccess.getDay();

        // Flag admin access outside business hours (weekends or 10pm-6am)
        if (dayOfWeek === 0 || dayOfWeek === 6 || hourOfDay < 6 || hourOfDay > 22) {
          // Only flag if they're an admin
          if (userData.role === 'admin') {
            const anomalyId = db.collection('anomalies').doc().id;
            await db.collection('anomalies').doc(anomalyId).set({
              entityType: 'audit',
              entityId: userId,
              severity: 'medium',
              message: `Admin access outside business hours: ${lastAccess.toISOString()}`,
              recommendedAction: 'Verify if this admin access was authorized.',
              context: {
                timestamp: lastAccess.toISOString(),
                hourOfDay,
                dayOfWeek: ['Sun', 'Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat'][dayOfWeek],
              },
              createdAt: admin.firestore.FieldValue.serverTimestamp(),
              resolved: false,
            });
            anomalyIds.push(anomalyId);
          }
        }
      }
    }
  } catch (err) {
    functions.logger.error('User behavior anomaly scan failed', err);
  }

  return anomalyIds;
}

/**
 * Main scheduled scan function
 */
export const scanAnomaliesScheduled = functions.pubsub
  .schedule('every day 02:00') // 2 AM UTC daily
  .timeZone('UTC')
  .onRun(async () => {
    const startTime = Date.now();
    const allAnomalyIds: string[] = [];

    try {
      functions.logger.info('Starting anomaly scan');

      // Run all scans in parallel
      const [expenseAnomalies, invoiceAnomalies, behaviorAnomalies] = await Promise.all([
        scanExpenseAnomalies(),
        scanInvoiceAnomalies(),
        scanUserBehaviorAnomalies(),
      ]);

      allAnomalyIds.push(...expenseAnomalies, ...invoiceAnomalies, ...behaviorAnomalies);

      const duration = Date.now() - startTime;
      functions.logger.info('Anomaly scan completed', {
        totalAnomalies: allAnomalyIds.length,
        expenses: expenseAnomalies.length,
        invoices: invoiceAnomalies.length,
        behavior: behaviorAnomalies.length,
        durationMs: duration,
      });

      // Send alert if critical anomalies found
      if (expenseAnomalies.length + invoiceAnomalies.length > 5) {
        await sendSecurityAlert(
          'Anomaly Scan: Multiple Issues Detected',
          `Scan found ${allAnomalyIds.length} anomalies:\n- Expenses: ${expenseAnomalies.length}\n- Invoices: ${invoiceAnomalies.length}\n- Behavior: ${behaviorAnomalies.length}`,
          {
            scanDuration: duration,
            timestamp: new Date().toISOString(),
          },
        );
      }

      return { ok: true, anomalyCount: allAnomalyIds.length };
    } catch (err) {
      functions.logger.error('Anomaly scan error', err);
      await sendSecurityAlert(
        'Anomaly Scan Error',
        `Scan failed: ${err instanceof Error ? err.message : String(err)}`,
        { error: err },
      );
      throw err;
    }
  });

/**
 * Manual admin-callable scan
 */
export const scanAnomaliesManual = functions.https.onCall(
  async (data, context) => {
    if (!context.auth?.token.admin) {
      throw new functions.https.HttpsError('permission-denied', 'Admin only');
    }

    const { entityType = 'all' } = data;
    const results: Record<string, number> = {};

    try {
      if (entityType === 'all' || entityType === 'expense') {
        results.expenses = (await scanExpenseAnomalies()).length;
      }

      if (entityType === 'all' || entityType === 'invoice') {
        results.invoices = (await scanInvoiceAnomalies()).length;
      }

      if (entityType === 'all' || entityType === 'behavior') {
        results.behavior = (await scanUserBehaviorAnomalies()).length;
      }

      return {
        ok: true,
        message: 'Scan completed',
        results,
        totalAnomalies: Object.values(results).reduce((a, b) => a + b, 0),
      };
    } catch (err) {
      throw new functions.https.HttpsError(
        'internal',
        `Scan failed: ${err instanceof Error ? err.message : String(err)}`,
      );
    }
  },
);
