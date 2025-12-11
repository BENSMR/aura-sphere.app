import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { logger } from '../utils/logger';

const db = admin.firestore();

/**
 * Trigger: Fires when a new invoice is created in users/{userId}/invoices/{invoiceId}
 * 
 * Purpose: Synchronize invoice creation with client records
 * - Update client totalInvoices count
 * - Track lastInvoiceAmount and lastInvoiceDate
 * - Add timeline event to client record
 * - Update client's lastActivityAt timestamp
 * 
 * Preconditions:
 * - Invoice must have clientId field
 * - Client must exist in users/{userId}/clients/{clientId}
 * 
 * Side Effects:
 * - Updates client document with new invoice metadata
 * - Appends timeline event (non-blocking)
 * - Triggers potential churn risk recalculation
 */
export const onClientInvoiceCreated = functions.firestore
  .document('users/{userId}/invoices/{invoiceId}')
  .onCreate(async (snap, context) => {
    const { userId, invoiceId } = context.params;
    const invoiceData = snap.data();

    try {
      // Validate required fields
      if (!userId || !invoiceId) {
        logger.error('Missing userId or invoiceId in document path', {
          userId,
          invoiceId,
        });
        return { success: false, error: 'Invalid document path' };
      }

      if (!invoiceData) {
        logger.error('Invoice document has no data', { userId, invoiceId });
        return { success: false, error: 'Invoice data missing' };
      }

      // Extract invoice data
      const {
        clientId,
        clientName,
        amount,
        invoiceNumber,
        description,
        status,
      } = invoiceData;

      // Check if invoice has a clientId (required to sync with clients)
      if (!clientId) {
        logger.warn('Invoice has no clientId, skipping client sync', {
          userId,
          invoiceId,
          invoiceNumber,
        });
        return { success: false, reason: 'No clientId in invoice' };
      }

      // Verify client exists
      const clientRef = db
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId);

      const clientSnap = await clientRef.get();
      if (!clientSnap.exists) {
        logger.warn('Client not found for invoice', {
          userId,
          invoiceId,
          clientId,
          invoiceNumber,
        });
        return { success: false, error: 'Client not found' };
      }

      // Update client with invoice metadata (atomic)
      const now = admin.firestore.FieldValue.serverTimestamp();
      const timelineEvent = {
        type: 'invoice_created',
        message: `Invoice ${invoiceNumber || invoiceId} created for ${amount}`,
        amount: amount || 0,
        createdAt: now,
      };

      await clientRef.update({
        // Increment invoice count
        totalInvoices: admin.firestore.FieldValue.increment(1),
        // Track most recent invoice
        lastInvoiceAmount: amount || 0,
        lastInvoiceDate: now,
        // Update activity timestamp
        lastActivityAt: now,
        // Add timeline event
        'timeline.events': admin.firestore.FieldValue.arrayUnion(timelineEvent),
        // Update modified timestamp
        updatedAt: now,
      });

      logger.info('Client invoice metadata updated', {
        userId,
        invoiceId,
        clientId,
        invoiceNumber,
        clientName,
        amount,
        status,
      });

      // Trigger churn risk recalculation (async, non-blocking)
      // This is a background task that updates client risk scores
      triggerChurnRiskUpdate(userId, clientId).catch((err) => {
        logger.error('Failed to trigger churn risk update', {
          userId,
          clientId,
          error: err.message,
        });
        // Don't fail the main function
      });

      return {
        success: true,
        invoiceId,
        clientId,
        invoiceNumber,
        clientName,
        amount,
      };
    } catch (error: any) {
      logger.error('onClientInvoiceCreated function failed', {
        userId,
        invoiceId,
        error: error.message,
        code: error.code,
      });

      return {
        success: false,
        error: error.message || 'Failed to sync invoice with client',
      };
    }
  });

/**
 * Trigger: Fires when invoice payment status is updated
 * 
 * Purpose: Track payment received and update client metrics
 * - Increment lifetimeValue
 * - Update lastPaymentDate
 * - Reduce churn risk
 * - Boost aiScore
 * - Add timeline event
 */
export const onClientInvoicePaid = functions.firestore
  .document('users/{userId}/invoices/{invoiceId}')
  .onUpdate(async (change, context) => {
    const { userId, invoiceId } = context.params;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    try {
      // Check if status changed to 'paid'
      if (beforeData.status === 'paid' || afterData.status !== 'paid') {
        return { success: false, reason: 'Status not changed to paid' };
      }

      const {
        clientId,
        clientName,
        amount,
        invoiceNumber,
      } = afterData;

      if (!clientId) {
        logger.warn('Invoice has no clientId, skipping client sync', {
          userId,
          invoiceId,
        });
        return { success: false, reason: 'No clientId in invoice' };
      }

      // Verify client exists
      const clientRef = db
        .collection('users')
        .doc(userId)
        .collection('clients')
        .doc(clientId);

      const clientSnap = await clientRef.get();
      if (!clientSnap.exists) {
        logger.warn('Client not found for paid invoice', {
          userId,
          invoiceId,
          clientId,
        });
        return { success: false, error: 'Client not found' };
      }

      const clientData = clientSnap.data() as any;
      const now = admin.firestore.FieldValue.serverTimestamp();

      // Calculate new metrics
      const paymentAmount = amount || 0;
      const newLifetimeValue = (clientData.lifetimeValue || 0) + paymentAmount;

      // Boost aiScore by 20 (capped at 100)
      const currentAiScore = clientData.aiScore || 0;
      const newAiScore = Math.min(100, currentAiScore + 20);

      // Reduce churn risk by 15%
      const currentChurnRisk = clientData.churnRisk || 0;
      const newChurnRisk = Math.floor(currentChurnRisk * 0.85);

      // Evaluate VIP status (lifetime value > 10,000)
      const newVipStatus = newLifetimeValue > 10000;

      // Create timeline event
      const timelineEvent = {
        type: 'payment_received',
        message: `Payment received for invoice ${invoiceNumber || invoiceId}: ${paymentAmount}`,
        amount: paymentAmount,
        createdAt: now,
      };

      // Update client with payment metrics (atomic)
      await clientRef.update({
        // Increase lifetime value
        lifetimeValue: newLifetimeValue,
        // Update payment date
        lastPaymentDate: now,
        // Update activity
        lastActivityAt: now,
        // Boost relationship score
        aiScore: newAiScore,
        // Reduce churn risk
        churnRisk: newChurnRisk,
        // Evaluate VIP status
        vipStatus: newVipStatus,
        // Add timeline event
        'timeline.events': admin.firestore.FieldValue.arrayUnion(timelineEvent),
        // Update modified timestamp
        updatedAt: now,
      });

      logger.info('Client payment metrics updated', {
        userId,
        invoiceId,
        clientId,
        invoiceNumber,
        clientName,
        paymentAmount,
        newLifetimeValue,
        newAiScore,
        newChurnRisk,
        newVipStatus,
      });

      return {
        success: true,
        invoiceId,
        clientId,
        paymentAmount,
        newLifetimeValue,
        newAiScore,
        newChurnRisk,
        newVipStatus,
      };
    } catch (error: any) {
      logger.error('onClientInvoicePaid function failed', {
        userId,
        invoiceId,
        error: error.message,
        code: error.code,
      });

      // Don't fail - allow invoice to be marked paid even if client sync fails
      return {
        success: false,
        error: error.message || 'Failed to sync payment with client',
      };
    }
  });

/**
 * Background: Trigger churn risk recalculation for a client
 * 
 * This is a non-blocking operation that calls the churn risk
 * calculation engine. It can be run async without blocking
 * the invoice creation flow.
 */
async function triggerChurnRiskUpdate(
  userId: string,
  clientId: string
): Promise<void> {
  try {
    // Call a callable function to recalculate churn risk
    // This would be implemented in a separate Cloud Function
    // that does the heavy lifting of churn risk analysis
    logger.warn('Churn risk update triggered', {
      userId,
      clientId,
    });

    // For now, this is a placeholder for future implementation
    // In production, this would call an AI analysis service
  } catch (error: any) {
    logger.error('Failed to trigger churn risk update', {
      userId,
      clientId,
      error: error.message,
    });
    // Don't rethrow - this is a background operation
  }
}

/**
 * Trigger: Fires when top-level invoice payment status is updated
 * 
 * Purpose: Track payment received and update client metrics
 * - Increment lifetimeValue by payment amount
 * - Update lastPaymentDate and lastActivityAt
 * - Set vipStatus based on payment amount threshold (>300)
 * - Add timeline event for payment
 * 
 * Preconditions:
 * - Invoice must have clientId field
 * - Status must change TO 'paid' (not from 'paid')
 * - Client must exist in top-level clients collection
 * 
 * Side Effects:
 * - Updates client document with payment metadata
 * - Appends timeline event
 * - Evaluates VIP status
 */
export const onTopLevelInvoicePaid = functions.firestore
  .document('invoices/{invoiceId}')
  .onUpdate(async (change, context) => {
    const { invoiceId } = context.params;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    try {
      // Check if status changed TO 'paid' (not FROM 'paid')
      if (beforeData?.status === 'paid' || afterData?.status !== 'paid') {
        return { success: false, reason: 'Status not changed to paid' };
      }

      const {
        clientId,
        clientName,
        amount,
        reference,
        userId,
      } = afterData;

      // Validate required fields
      if (!clientId) {
        logger.warn('Invoice has no clientId, skipping client sync', {
          invoiceId,
          reference,
        });
        return { success: false, reason: 'No clientId in invoice' };
      }

      if (!userId) {
        logger.error('Invoice has no userId, cannot sync with client', {
          invoiceId,
          clientId,
        });
        return { success: false, error: 'No userId in invoice' };
      }

      // Reference client in top-level clients collection
      const clientRef = db.collection('clients').doc(clientId);

      // Get client to verify exists
      const clientSnap = await clientRef.get();
      if (!clientSnap.exists) {
        logger.warn('Client not found for paid invoice', {
          invoiceId,
          clientId,
          userId,
        });
        return { success: false, error: 'Client not found' };
      }

      const now = new Date();
      const paymentAmount = amount || 0;

      // Determine VIP status based on payment amount (>300)
      const newVipStatus = paymentAmount > 300 ? true : false;

      // Create timeline event
      const timelineEvent = {
        type: 'invoice_paid',
        message: `Invoice ${reference || invoiceId} paid for ${paymentAmount}`,
        amount: paymentAmount,
        createdAt: now,
      };

      // Update client with payment metrics (atomic merge)
      await clientRef.set(
        {
          // Increase lifetime value by payment amount
          lifetimeValue: admin.firestore.FieldValue.increment(paymentAmount),
          // Update payment date
          lastPaymentDate: now,
          // Update activity timestamp
          lastActivityAt: now,
          // Set VIP status based on single payment amount (>300)
          vipStatus: newVipStatus,
          // Add timeline event
          timeline: admin.firestore.FieldValue.arrayUnion(timelineEvent),
        },
        { merge: true } // Merge to preserve other fields
      );

      logger.info('Top-level client payment metrics updated', {
        invoiceId,
        clientId,
        reference,
        clientName,
        paymentAmount,
        newVipStatus,
        userId,
      });

      return {
        success: true,
        invoiceId,
        clientId,
        paymentAmount,
        newVipStatus,
      };
    } catch (error: any) {
      logger.error('onTopLevelInvoicePaid function failed', {
        invoiceId,
        error: error.message,
        code: error.code,
      });

      // Don't fail - allow invoice to be marked paid even if client sync fails
      return {
        success: false,
        error: error.message || 'Failed to sync payment with client',
      };
    }
  });

/**
 * Trigger: Fires when top-level invoice is created
 * 
 * Purpose: Synchronize invoice creation with top-level client records
 * - Update client totalInvoices count
 * - Track lastInvoiceAmount and lastInvoiceDate
 * - Add timeline event to client record
 * - Update client's lastActivityAt timestamp
 * 
 * Preconditions:
 * - Invoice must have clientId field
 * - Client must exist in top-level clients collection
 * 
 * Side Effects:
 * - Updates client document with new invoice metadata
 * - Appends timeline event
 */
export const onTopLevelInvoiceCreated = functions.firestore
  .document('invoices/{invoiceId}')
  .onCreate(async (snap, context) => {
    const { invoiceId } = context.params;
    const invoiceData = snap.data();

    try {
      // Validate required fields
      if (!invoiceId) {
        logger.error('Missing invoiceId in document path', {
          invoiceId,
        });
        return { success: false, error: 'Invalid document path' };
      }

      if (!invoiceData) {
        logger.error('Invoice document has no data', { invoiceId });
        return { success: false, error: 'Invoice data missing' };
      }

      // Extract invoice data
      const {
        clientId,
        clientName,
        amount,
        reference,
        status,
        userId,
      } = invoiceData;

      // Check if invoice has a clientId (required to sync with clients)
      if (!clientId) {
        logger.warn('Invoice has no clientId, skipping client sync', {
          invoiceId,
          reference,
        });
        return { success: false, reason: 'No clientId in invoice' };
      }

      if (!userId) {
        logger.error('Invoice has no userId, cannot sync with client', {
          invoiceId,
          clientId,
        });
        return { success: false, error: 'No userId in invoice' };
      }

      // Reference client in top-level clients collection
      const clientRef = db.collection('clients').doc(clientId);

      // Verify client exists
      const clientSnap = await clientRef.get();
      if (!clientSnap.exists) {
        logger.warn('Client not found for invoice', {
          invoiceId,
          clientId,
          userId,
        });
        return { success: false, error: 'Client not found' };
      }

      const now = new Date();
      const timelineEvent = {
        type: 'invoice_created',
        message: `Invoice ${reference || invoiceId} created for ${amount}`,
        amount: amount || 0,
        createdAt: now,
      };

      // Update client with invoice metadata (atomic merge)
      await clientRef.set(
        {
          // Increment invoice count
          totalInvoices: admin.firestore.FieldValue.increment(1),
          // Track most recent invoice
          lastInvoiceAmount: amount || 0,
          lastInvoiceDate: now,
          // Update activity timestamp
          lastActivityAt: now,
          // Add timeline event
          timeline: admin.firestore.FieldValue.arrayUnion(timelineEvent),
        },
        { merge: true } // Merge to preserve other fields
      );

      logger.info('Top-level client invoice metadata updated', {
        invoiceId,
        clientId,
        reference,
        clientName,
        amount,
        status,
        userId,
      });

      return {
        success: true,
        invoiceId,
        clientId,
        reference,
        clientName,
        amount,
      };
    } catch (error: any) {
      logger.error('onTopLevelInvoiceCreated function failed', {
        invoiceId,
        error: error.message,
        code: error.code,
      });

      return {
        success: false,
        error: error.message || 'Failed to sync invoice with client',
      };
    }
  });
