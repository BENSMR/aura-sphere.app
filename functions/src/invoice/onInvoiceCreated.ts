import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { logger } from '../utils/logger';

const db = admin.firestore();

/**
 * Trigger: Fires when a new invoice is created in users/{userId}/invoices/{invoiceId}
 * 
 * Purpose:
 * - Award AuraTokens to user for creating an invoice
 * - Log invoice creation event
 * - Validate invoice data integrity
 * 
 * Side Effects:
 * - Updates user's auraTokens balance
 * - Creates token_audit entry
 * - Logs to Firebase Functions logs
 */
export const onInvoiceCreated = functions.firestore
  .document('users/{userId}/invoices/{invoiceId}')
  .onCreate(async (snap, context) => {
    const { userId, invoiceId } = context.params;
    const invoiceData = snap.data();

    try {
      // Validate required fields
      if (!userId) {
        logger.error('Missing userId in document path', { invoiceId });
        return { success: false, error: 'Invalid document path' };
      }

      if (!invoiceData) {
        logger.error('Invoice document has no data', { userId, invoiceId });
        return { success: false, error: 'Invoice data missing' };
      }

      // Validate invoice structure
      const { clientName, clientEmail, items, total, invoiceNumber, status } = invoiceData;

      if (!clientName || !clientEmail) {
        logger.warn('Invoice missing client information', { userId, invoiceId, invoiceNumber });
        return { success: false, error: 'Invalid invoice: missing client data' };
      }

      if (!Array.isArray(items) || items.length === 0) {
        logger.warn('Invoice has no items', { userId, invoiceId, invoiceNumber });
        return { success: false, error: 'Invalid invoice: no items' };
      }

      if (typeof total !== 'number' || total <= 0) {
        logger.warn('Invoice has invalid total', { userId, invoiceId, invoiceNumber, total });
        return { success: false, error: 'Invalid invoice: total must be > 0' };
      }

      // Verify invoice exists and belongs to user
      const userDoc = await db.collection('users').doc(userId).get();
      if (!userDoc.exists) {
        logger.error('User not found', { userId, invoiceId });
        return { success: false, error: 'User not found' };
      }

      // Award tokens in a transaction
      const rewardResult = await awardInvoiceCreationTokens(userId, invoiceId, invoiceData);

      if (!rewardResult.success) {
        logger.error('Failed to award tokens', { userId, invoiceId, error: rewardResult.error });
        return rewardResult;
      }

      logger.info('Invoice created successfully and tokens awarded', {
        userId,
        invoiceId,
        invoiceNumber,
        clientName,
        total,
        tokensAwarded: rewardResult.tokensAwarded,
        newBalance: rewardResult.newBalance,
      });

      return {
        success: true,
        invoiceId,
        tokensAwarded: rewardResult.tokensAwarded,
        newBalance: rewardResult.newBalance,
      };
    } catch (error: any) {
      logger.error('onInvoiceCreated function failed', {
        userId,
        invoiceId,
        error: error.message,
        code: error.code,
      });

      return {
        success: false,
        error: error.message || 'Failed to process invoice creation',
      };
    }
  });

/**
 * Award tokens for invoice creation
 * - Token amount: 8 AuraTokens (defined in rewards.ts TOKEN_VALUES)
 * - Creates audit trail
 * - Uses transaction for consistency
 */
async function awardInvoiceCreationTokens(
  userId: string,
  invoiceId: string,
  invoiceData: any
): Promise<{
  success: boolean;
  tokensAwarded?: number;
  newBalance?: number;
  error?: string;
}> {
  try {
    const TOKEN_AMOUNT = 8; // AuraTokens for creating invoice
    const userRef = db.collection('users').doc(userId);
    const walletRef = userRef.collection('wallet').doc('aura');

    const result = await db.runTransaction(async (tx) => {
      // Get current balance
      const walletSnap = await tx.get(walletRef);
      const currentBalance = walletSnap.exists ? (walletSnap.data()?.balance ?? 0) : 0;
      const newBalance = currentBalance + TOKEN_AMOUNT;

      // Update balance
      tx.update(walletRef, {
        balance: newBalance,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Create audit entry
      const auditRef = userRef.collection('token_audit').doc();
      tx.set(auditRef, {
        action: 'create_invoice',
        amount: TOKEN_AMOUNT,
        awardedBy: 'system',
        metadata: {
          invoiceId,
          invoiceNumber: invoiceData.invoiceNumber || 'N/A',
          clientName: invoiceData.clientName,
          total: invoiceData.total,
          status: invoiceData.status || 'draft',
          itemCount: (invoiceData.items || []).length,
        },
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return { newBalance, tokensAwarded: TOKEN_AMOUNT };
    });

    return {
      success: true,
      tokensAwarded: result.tokensAwarded,
      newBalance: result.newBalance,
    };
  } catch (error: any) {
    logger.error('Failed to award invoice creation tokens', {
      userId,
      invoiceId,
      error: error.message,
    });

    return {
      success: false,
      error: error.message || 'Transaction failed',
    };
  }
}

/**
 * Optional: Trigger when invoice is marked as paid
 * - Awards additional tokens for payment
 * - Updates invoice status tracking
 */
export const onInvoicePaid = functions.firestore
  .document('users/{userId}/invoices/{invoiceId}')
  .onUpdate(async (change, context) => {
    const { userId, invoiceId } = context.params;
    const beforeData = change.before.data();
    const afterData = change.after.data();

    try {
      // Only process if status changed to 'paid'
      if (beforeData.status === 'paid' || afterData.status !== 'paid') {
        return { success: false, reason: 'Status not changed to paid' };
      }

      logger.info('Invoice marked as paid', {
        userId,
        invoiceId,
        invoiceNumber: afterData.invoiceNumber,
        total: afterData.total,
      });

      // Award tokens for payment
      const TOKEN_AMOUNT = 15; // AuraTokens for receiving payment
      const userRef = db.collection('users').doc(userId);
      const walletRef = userRef.collection('wallet').doc('aura');

      const result = await db.runTransaction(async (tx) => {
        const walletSnap = await tx.get(walletRef);
        const currentBalance = walletSnap.exists ? (walletSnap.data()?.balance ?? 0) : 0;
        const newBalance = currentBalance + TOKEN_AMOUNT;

        tx.update(walletRef, {
          balance: newBalance,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        const auditRef = userRef.collection('token_audit').doc();
        tx.set(auditRef, {
          action: 'invoice_paid',
          amount: TOKEN_AMOUNT,
          awardedBy: 'system',
          metadata: {
            invoiceId,
            invoiceNumber: afterData.invoiceNumber,
            total: afterData.total,
          },
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        return { newBalance, tokensAwarded: TOKEN_AMOUNT };
      });

      logger.info('Invoice payment tokens awarded', {
        userId,
        invoiceId,
        tokensAwarded: result.tokensAwarded,
        newBalance: result.newBalance,
      });

      return {
        success: true,
        tokensAwarded: result.tokensAwarded,
        newBalance: result.newBalance,
      };
    } catch (error: any) {
      logger.error('onInvoicePaid function failed', {
        userId,
        invoiceId,
        error: error.message,
      });

      // Don't throw - allow invoice to be marked paid even if token award fails
      return {
        success: false,
        error: error.message,
      };
    }
  });
