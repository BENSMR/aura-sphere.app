import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { logger } from '../utils/logger';

const db = admin.firestore();

/**
 * Monitor expense status changes
 * Triggers on update of expense document status field
 */
export const onExpenseStatusChange = functions
  .region('us-central1')
  .firestore
  .document('expenses/{expenseId}')
  .onUpdate(async (change, context) => {
    try {
      const expenseId = context.params.expenseId;
      const oldData = change.before.data();
      const newData = change.after.data();

      // Only process if status changed
      if (oldData.status === newData.status) {
        return { success: false, message: 'No status change' };
      }

      const oldStatus = oldData.status;
      const newStatus = newData.status;

      logger.info(`Expense ${expenseId} status changed: ${oldStatus} → ${newStatus}`, {
        userId: newData.userId,
        amount: newData.amount,
      });

      // Handle different status transitions
      switch (newStatus) {
        case 'inventory_added':
          await handleInventoryAdded(expenseId, newData);
          break;
        case 'approved':
          await handleExpenseApproved(expenseId, newData);
          break;
        case 'rejected':
          await handleExpenseRejected(expenseId, newData);
          break;
        case 'paid':
          await handleExpensePaid(expenseId, newData);
          break;
      }

      // Log status change to audit trail
      await logStatusChange(expenseId, oldStatus, newStatus, newData);

      return {
        success: true,
        message: `Status changed to ${newStatus}`,
      };
    } catch (error) {
      logger.error('Error processing expense status change', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to process status change'
      );
    }
  });

/**
 * Handle inventory_added status - expense added to stock
 */
async function handleInventoryAdded(
  expenseId: string,
  expenseData: any
): Promise<void> {
  try {
    // Create success notification
    const notification = {
      type: 'inventory_success',
      expenseId,
      userId: expenseData.userId,
      title: 'Added to Stock',
      message: `${expenseData.vendor} items added to inventory`,
      vendor: expenseData.vendor,
      amount: expenseData.amount,
      items: expenseData.items || [],
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      action: 'view_inventory',
    };

    // Store notification
    await db
      .collection('users')
      .doc(expenseData.userId)
      .collection('notifications')
      .add(notification);

    // Update inventory collection (if using separate inventory tracking)
    await updateInventoryFromExpense(expenseId, expenseData);

    logger.info(`Inventory added notification sent for expense ${expenseId}`);
  } catch (error) {
    logger.error('Error handling inventory_added status', error);
  }
}

/**
 * Handle approved status - expense approved
 */
async function handleExpenseApproved(
  expenseId: string,
  expenseData: any
): Promise<void> {
  try {
    const notification = {
      type: 'expense_approved',
      expenseId,
      userId: expenseData.userId,
      title: 'Expense Approved',
      message: `Your ${expenseData.vendor} expense has been approved`,
      amount: expenseData.amount,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      action: 'view_expense',
    };

    await db
      .collection('users')
      .doc(expenseData.userId)
      .collection('notifications')
      .add(notification);

    // Update user stats
    await updateApprovedExpenseStats(expenseData.userId);

    logger.info(`Approval notification sent for expense ${expenseId}`);
  } catch (error) {
    logger.error('Error handling approved status', error);
  }
}

/**
 * Handle rejected status - expense rejected
 */
async function handleExpenseRejected(
  expenseId: string,
  expenseData: any
): Promise<void> {
  try {
    const notification = {
      type: 'expense_rejected',
      expenseId,
      userId: expenseData.userId,
      title: 'Expense Rejected',
      message: `Your ${expenseData.vendor} expense was rejected. Please review and resubmit.`,
      amount: expenseData.amount,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      action: 'edit_expense',
      urgent: true,
    };

    await db
      .collection('users')
      .doc(expenseData.userId)
      .collection('notifications')
      .add(notification);

    logger.info(`Rejection notification sent for expense ${expenseId}`);
  } catch (error) {
    logger.error('Error handling rejected status', error);
  }
}

/**
 * Handle paid status - expense marked as paid
 */
async function handleExpensePaid(
  expenseId: string,
  expenseData: any
): Promise<void> {
  try {
    const notification = {
      type: 'expense_paid',
      expenseId,
      userId: expenseData.userId,
      title: 'Expense Paid',
      message: `Payment for ${expenseData.vendor} (${expenseData.amount}) processed`,
      amount: expenseData.amount,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    };

    await db
      .collection('users')
      .doc(expenseData.userId)
      .collection('notifications')
      .add(notification);

    // Record payment transaction
    await recordPaymentTransaction(expenseData.userId, expenseData);

    logger.info(`Payment notification sent for expense ${expenseId}`);
  } catch (error) {
    logger.error('Error handling paid status', error);
  }
}

/**
 * Update inventory from expense
 */
async function updateInventoryFromExpense(
  expenseId: string,
  expenseData: any
): Promise<void> {
  try {
    const userId = expenseData.userId;
    const items = expenseData.items || [];

    // Create inventory record
    const inventoryRecord = {
      expenseId,
      userId,
      vendor: expenseData.vendor,
      items,
      quantity: items.length,
      amount: expenseData.amount,
      addedAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'in_stock',
    };

    await db
      .collection('users')
      .doc(userId)
      .collection('inventory')
      .add(inventoryRecord);

    logger.info(`Inventory record created for expense ${expenseId}`);
  } catch (error) {
    logger.error('Error updating inventory', error);
  }
}

/**
 * Update approved expense statistics
 */
async function updateApprovedExpenseStats(userId: string): Promise<void> {
  try {
    const approvedExpenses = await db
      .collection('expenses')
      .where('userId', '==', userId)
      .where('status', '==', 'approved')
      .get();

    let totalApproved = 0;
    approvedExpenses.forEach((doc) => {
      totalApproved += doc.data().amount || 0;
    });

    await db.collection('users').doc(userId).update({
      'expenseStats.approvedCount': approvedExpenses.size,
      'expenseStats.approvedAmount': totalApproved,
    });
  } catch (error) {
    logger.error('Error updating approved stats', error);
  }
}

/**
 * Record payment transaction
 */
async function recordPaymentTransaction(
  userId: string,
  expenseData: any
): Promise<void> {
  try {
    const transaction = {
      type: 'expense_payment',
      amount: expenseData.amount,
      vendor: expenseData.vendor,
      expenseId: expenseData.id,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      status: 'completed',
    };

    await db
      .collection('users')
      .doc(userId)
      .collection('transactions')
      .add(transaction);

    logger.info(`Payment transaction recorded for user ${userId}`);
  } catch (error) {
    logger.error('Error recording payment transaction', error);
  }
}

/**
 * Log status change to audit trail
 */
async function logStatusChange(
  expenseId: string,
  oldStatus: string,
  newStatus: string,
  expenseData: any
): Promise<void> {
  try {
    const auditLog = {
      action: 'status_change',
      expenseId,
      userId: expenseData.userId,
      oldStatus,
      newStatus,
      vendor: expenseData.vendor,
      amount: expenseData.amount,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      details: {
        category: expenseData.category,
        items: expenseData.items,
      },
    };

    await db.collection('auditLogs').add(auditLog);

    logger.info(`Status change logged: ${oldStatus} → ${newStatus}`);
  } catch (error) {
    logger.error('Error logging status change', error);
  }
}
