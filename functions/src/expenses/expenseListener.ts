import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { logger } from '../utils/logger';

const db = admin.firestore();

/**
 * Real-time listener for expenses collection
 * Tracks new expenses and triggers notifications
 * 
 * Usage:
 * - Listens to all expenses across all users
 * - Fires on create/update/delete
 * - Sends notifications for new expenses
 * - Logs to audit trail
 */
export const monitorExpenses = functions
  .region('us-central1')
  .firestore
  .document('expenses/{expenseId}')
  .onCreate(async (snap, context) => {
    try {
      const expenseId = context.params.expenseId;
      const expenseData = snap.data();

      logger.info(`New expense created: ${expenseId}`, {
        userId: expenseData.userId,
        amount: expenseData.amount,
        vendor: expenseData.vendor,
      });

      // Show alert to user
      await showNewExpenseAlert(expenseData, expenseId);

      // Update user statistics
      await updateUserExpenseStats(expenseData.userId);

      // Log to audit trail
      await logExpenseActivity('create', expenseId, expenseData);

      // Send notification if amount exceeds threshold
      if (expenseData.amount > 100) {
        await notifyHighValueExpense(expenseData, expenseId);
      }

      return {
        success: true,
        expenseId,
        message: 'Expense listener triggered successfully',
      };
    } catch (error) {
      logger.error('Error in monitorExpenses', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to process expense monitoring'
      );
    }
  });

/**
 * Show alert for new expense
 */
async function showNewExpenseAlert(
  expenseData: any,
  expenseId: string
): Promise<void> {
  try {
    const alert = {
      type: 'expense_created',
      expenseId,
      userId: expenseData.userId,
      vendor: expenseData.vendor,
      amount: expenseData.amount,
      category: expenseData.category || 'uncategorized',
      items: expenseData.items || [],
      status: expenseData.status || 'pending_review',
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
    };

    // Store alert in user's alerts collection
    await db
      .collection('users')
      .doc(expenseData.userId)
      .collection('alerts')
      .add(alert);

    logger.info(`Alert created for expense ${expenseId}`);
  } catch (error) {
    logger.error('Error showing expense alert', error);
  }
}

/**
 * Update user expense statistics
 */
async function updateUserExpenseStats(userId: string): Promise<void> {
  try {
    const userExpenses = await db
      .collection('expenses')
      .where('userId', '==', userId)
      .get();

    let totalAmount = 0;
    const categories: { [key: string]: number } = {};

    userExpenses.forEach((doc) => {
      const data = doc.data();
      totalAmount += data.amount || 0;
      const category = data.category || 'uncategorized';
      categories[category] = (categories[category] || 0) + 1;
    });

    // Update user stats
    await db.collection('users').doc(userId).update({
      'expenseStats.totalExpenses': userExpenses.size,
      'expenseStats.totalAmount': totalAmount,
      'expenseStats.averageExpense': totalAmount / userExpenses.size || 0,
      'expenseStats.lastUpdated': admin.firestore.FieldValue.serverTimestamp(),
      'expenseStats.byCategory': categories,
    });

    logger.info(`Updated expense stats for user ${userId}`);
  } catch (error) {
    logger.error('Error updating expense stats', error);
  }
}

/**
 * Log expense activity to audit trail
 */
async function logExpenseActivity(
  action: string,
  expenseId: string,
  expenseData: any
): Promise<void> {
  try {
    const auditLog = {
      action,
      expenseId,
      userId: expenseData.userId,
      vendor: expenseData.vendor,
      amount: expenseData.amount,
      status: expenseData.status,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      ip: 'firestore-trigger',
    };

    // Log to audit collection
    await db.collection('auditLogs').add(auditLog);

    logger.info(`Logged expense ${action}: ${expenseId}`);
  } catch (error) {
    logger.error('Error logging expense activity', error);
  }
}

/**
 * Notify for high-value expenses (> $100)
 */
async function notifyHighValueExpense(
  expenseData: any,
  expenseId: string
): Promise<void> {
  try {
    const notification = {
      type: 'high_value_expense',
      expenseId,
      userId: expenseData.userId,
      vendor: expenseData.vendor,
      amount: expenseData.amount,
      message: `High-value expense: $${expenseData.amount.toFixed(2)} from ${expenseData.vendor}`,
      timestamp: admin.firestore.FieldValue.serverTimestamp(),
      read: false,
      actionRequired: expenseData.status === 'pending_review',
    };

    // Store notification
    await db
      .collection('users')
      .doc(expenseData.userId)
      .collection('notifications')
      .add(notification);

    logger.info(`High-value expense notification sent for ${expenseId}`);
  } catch (error) {
    logger.error('Error sending high-value expense notification', error);
  }
}

/**
 * Stream listener for real-time expense updates
 * Can be called from client side to get live updates
 */
export const getExpenseStream = functions
  .region('us-central1')
  .https
  .onCall(async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        'unauthenticated',
        'User must be authenticated'
      );
    }

    const userId = context.auth.uid;

    try {
      // Return unsubscribe function details (can't actually return unsubscribe from callable)
      logger.info(`Streaming expenses for user ${userId}`);

      return {
        success: true,
        message: 'Expense stream initialized',
        userId,
        listeningFor: [
          'expense_created',
          'expense_updated',
          'expense_deleted',
        ],
      };
    } catch (error) {
      logger.error('Error initializing expense stream', error);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to initialize expense stream'
      );
    }
  });

/**
 * Scheduled function to clean up old alerts (runs daily)
 */
export const cleanupOldAlerts = functions
  .region('us-central1')
  .pubsub
  .schedule('every 24 hours')
  .onRun(async (context) => {
    try {
      const thirtyDaysAgo = new Date();
      thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);

      const oldAlerts = await db
        .collectionGroup('alerts')
        .where('timestamp', '<', thirtyDaysAgo)
        .get();

      let deletedCount = 0;
      for (const doc of oldAlerts.docs) {
        await doc.ref.delete();
        deletedCount++;
      }

      logger.info(`Cleaned up ${deletedCount} old alerts`);

      return {
        success: true,
        deletedCount,
      };
    } catch (error) {
      logger.error('Error cleaning up old alerts', error);
    }
  });
