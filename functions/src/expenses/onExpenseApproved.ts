import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Cloud Function: onExpenseApproved
 * 
 * Triggers when an expense status changes to 'approved'
 * 
 * Actions:
 * 1. Send FCM notification to expense submitter
 * 2. Award AuraTokens as reward
 * 3. Create audit trail entry
 * 
 * Path: users/{userId}/expenses/{expenseId}
 */
export const onExpenseApproved = functions.firestore
  .document('users/{userId}/expenses/{expenseId}')
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return null;

    // Check if status changed to 'approved'
    if (before.status !== 'approved' && after.status === 'approved') {
      const userId = context.params.userId;
      const expenseId = context.params.expenseId;

      try {
        // 1. Send FCM notification
        await _sendApprovalNotification(userId, after);

        // 2. Award AuraTokens
        await _awardTokens(userId, expenseId, after);

        // 3. Create audit entry
        await _createAuditEntry(userId, expenseId, 'approved_trigger');

        console.log(
          `Expense ${expenseId} approved for user ${userId}. Notifications sent, tokens awarded.`
        );
      } catch (error) {
        console.error(`Error processing expense approval for ${expenseId}:`, error);
        throw error;
      }
    }

    return null;
  });

/**
 * Send FCM notification to user
 */
async function _sendApprovalNotification(
  userId: string,
  expense: any
): Promise<void> {
  const userRef = db.collection('users').doc(userId);
  const userDoc = await userRef.get();
  const user = userDoc.data();

  if (!user) {
    console.warn(`User ${userId} not found for notification`);
    return;
  }

  const fcmTokens: string[] = user.fcmTokens || [];

  if (!fcmTokens || fcmTokens.length === 0) {
    console.log(`No FCM tokens for user ${userId}`);
    return;
  }

  const merchant = expense.merchant || 'Unknown';
  const amount = expense.amount ? `${expense.currency} ${expense.amount}` : '';

  const payload = {
    notification: {
      title: '✅ Expense Approved',
      body: `Your expense "${merchant}" (${amount}) was approved!`,
    },
    data: {
      expenseId: expense.id,
      type: 'expense_approved',
      merchant: merchant,
    },
  };

  try {
    await admin.messaging().sendToDevice(fcmTokens, payload);
    console.log(`Notification sent to ${fcmTokens.length} devices for user ${userId}`);
  } catch (error) {
    console.error(`Failed to send notification to user ${userId}:`, error);
    // Don't throw - notification failure shouldn't block the function
  }
}

/**
 * Award AuraTokens to user for expense approval
 */
async function _awardTokens(
  userId: string,
  expenseId: string,
  expense: any
): Promise<void> {
  const userRef = db.collection('users').doc(userId);
  const rewardAmount = 10; // 10 tokens per approved expense

  try {
    // Create token audit entry
    const auditRef = userRef.collection('auraTokenTransactions').doc();
    await auditRef.set({
      type: 'reward',
      action: 'expense_approved',
      expenseId: expenseId,
      amount: rewardAmount,
      merchant: expense.merchant || 'Unknown',
      currency: expense.currency || 'EUR',
      transactionAmount: expense.amount || 0,
      description: `Reward for approving expense from ${expense.merchant}`,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    });

    // Update user's total AuraTokens balance
    await userRef.update({
      auraTokens: admin.firestore.FieldValue.increment(rewardAmount),
    });

    console.log(`Awarded ${rewardAmount} tokens to user ${userId}`);
  } catch (error) {
    console.error(`Failed to award tokens to user ${userId}:`, error);
    throw error;
  }
}

/**
 * Create audit trail entry in expense
 */
async function _createAuditEntry(
  userId: string,
  expenseId: string,
  action: string
): Promise<void> {
  const auditRef = db
    .collection('users')
    .doc(userId)
    .collection('expenses')
    .doc(expenseId)
    .collection('audit');

  try {
    await auditRef.add({
      action: action,
      trigger: 'onUpdate',
      ts: admin.firestore.FieldValue.serverTimestamp(),
    });

    console.log(`Audit entry created for expense ${expenseId}: ${action}`);
  } catch (error) {
    console.error(
      `Failed to create audit entry for expense ${expenseId}:`,
      error
    );
    throw error;
  }
}
