import { CallableContext } from 'firebase-functions/v1/https';
import { firestore } from '../utils/firestore';

export const auraTokenEngine = {
  getBalance: async (data: any, context: CallableContext) => {
    if (!context.auth) {
      throw new Error('Unauthorized');
    }

    const { userId } = data;
    const userDoc = await firestore.collection('users').doc(userId).get();
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

  await firestore.collection('users').doc(userId).update({
    auraTokens: firestore.FieldValue.increment(amount),
  });

  await firestore.collection('auraTokenTransactions').add({
    userId,
    amount,
    reason,
    timestamp: firestore.FieldValue.serverTimestamp(),
  });

  return { success: true };
};
