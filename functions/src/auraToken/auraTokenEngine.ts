import { CallableContext } from 'firebase-functions/v1/https';
import * as admin from 'firebase-admin';

const db = admin.firestore();

export const auraTokenEngine = {
  getBalance: async (data: any, context: CallableContext) => {
    if (!context.auth) {
      throw new Error('Unauthorized');
    }

    const { userId } = data;
    const userDoc = await db.collection('users').doc(userId).get();
    const userData = userDoc.data();

    return {
      balance: userData?.auraTokens || 0,
    };
  },
};

export const rewardTokens = async (data: any, context: CallableContext) => {
  if (!context.auth) {
    throw new Error('Unauthorized');
  }

  const { userId, amount, reason } = data;

  await db.collection('users').doc(userId).update({
    auraTokens: admin.firestore.FieldValue.increment(amount),
  });

  await db.collection('auraTokenTransactions').add({
    userId,
    amount,
    reason,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
};
