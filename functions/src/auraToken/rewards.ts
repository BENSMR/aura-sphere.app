import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { writeAuditEntry } from '../audit/auditHelpers';

const db = admin.firestore();

// Token constants (you can move to functions.config later)
const TOKEN_VALUES: { [key: string]: number } = {
  welcome_bonus: 200,
  daily_login: 5,
  referral_signup: 100,
  create_project: 10,
  complete_project: 25,
  create_invoice: 8,
  invoice_paid: 15
};

// Helper to check admin
async function isAdmin(uid: string): Promise<boolean> {
  if (!uid) return false;
  try {
    const doc = await db.doc(`admins/${uid}`).get();
    return doc.exists;
  } catch (e) {
    return false;
  }
}

export const rewardUser = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Only authenticated users can call this function.');
  }

  const callerUid = context.auth.uid;
  const { userId, action, metadata } = data;

  if (!userId || !action) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing userId or action.');
  }

  // Only allow awarding to yourself, unless caller is admin
  const callerIsAdmin = await isAdmin(callerUid);
  if (callerUid !== userId && !callerIsAdmin) {
    throw new functions.https.HttpsError('permission-denied', 'You are not allowed to award tokens to other users.');
  }

  const tokenAmount = TOKEN_VALUES[action] ?? 0;
  if (tokenAmount <= 0) {
    return { success: true, tokensAwarded: 0, message: 'No reward for this action' };
  }

  const userRef = db.collection('users').doc(userId);
  const walletRef = userRef.collection('wallet').doc('aura');

  const result = await db.runTransaction(async (tx) => {
    const userSnap = await tx.get(userRef);
    if (!userSnap.exists) {
      throw new functions.https.HttpsError('not-found', 'User not found.');
    }

    const walletSnap = await tx.get(walletRef);
    const currentBalance = walletSnap.exists ? (walletSnap.data()?.balance ?? 0) : 0;
    const newBalance = currentBalance + tokenAmount;

    tx.set(walletRef, {
      balance: newBalance,
      updatedAt: admin.firestore.FieldValue.serverTimestamp()
    }, { merge: true });

    const auditRef = userRef.collection('token_audit').doc();
    tx.set(auditRef, {
      action,
      amount: tokenAmount,
      awardedBy: callerUid,
      metadata: metadata || {},
      createdAt: admin.firestore.FieldValue.serverTimestamp()
    });

    return { newBalance, tokenAmount, oldBalance: currentBalance };
  });

  // Write to unified audit trail (after transaction succeeds)
  try {
    await writeAuditEntry('wallet', userId, {
      actor: {
        uid: callerUid,
        role: callerIsAdmin ? 'admin' : 'user'
      },
      action: `token.${action}`,
      source: 'functions:rewardUser',
      before: { balance: result.oldBalance },
      after: { balance: result.newBalance },
      meta: {
        amount: result.tokenAmount,
        awardType: action,
        awardedBy: callerUid,
        metadata: metadata || {}
      },
      tags: ['token', 'reward', action]
    });
  } catch (auditErr) {
    console.error(`[audit-error] wallet_${userId}: token.${action}`, auditErr);
    // Don't throw — wallet was updated successfully, audit is secondary
  }

  return { success: true, tokensAwarded: result.tokenAmount, newBalance: result.newBalance };
});
