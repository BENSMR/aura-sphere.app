import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();

const db = admin.firestore();

export const onExpenseCreatedNotify = functions.firestore
  .document('users/{uid}/expenses/{expenseId}')
  .onCreate(async (snap, context) => {
    const expense = snap.data();
    const uid = context.params.uid;
    const expenseId = context.params.expenseId;

    if (!expense) {
      console.warn('Expense document exists but has no data');
      return;
    }

    try {
      // Create approval task in subcollection
      const approvalsRef = snap.ref.collection('approvals');
      const approvalDoc = {
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        notified: false,
        expenseAmount: expense.totalAmount || null,
        merchant: expense.merchant || null,
        expenseDate: expense.date || null,
      };

      const approvalSnap = await approvalsRef.add(approvalDoc);
      console.log(`Approval task created for expense ${expenseId}:`, approvalSnap.id);

      // Optional: Send notification to approvers (push notification, email, etc.)
      // This can be enhanced to:
      // 1. Query user's approvers/managers from profile
      // 2. Send push notifications via FCM
      // 3. Send email notifications via SendGrid
      // 4. Create in-app notification in a notifications collection

      // For now, just mark as notified in the approvals collection
      await approvalSnap.update({
        notified: true,
        notifiedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      // Optional: Create audit log entry
      const auditRef = db.collection('users').doc(uid).collection('auditLog');
      await auditRef.add({
        action: 'expense_created_approval_initiated',
        expenseId,
        approvalId: approvalSnap.id,
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        details: {
          merchant: expense.merchant,
          amount: expense.totalAmount,
          currency: expense.currency,
        }
      });

      return { success: true, approvalId: approvalSnap.id };
    } catch (error: any) {
      console.error(`Error creating approval for expense ${expenseId}:`, error);
      throw new Error(`Failed to create approval task: ${error.message}`);
    }
  });
