import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

const db = admin.firestore();

/**
 * Verify AuraToken wallet and audit data for a user
 * Callable function: data { userId }
 */
export const verifyUserTokenData = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Only authenticated clients can call this function.');
  }

  const { userId } = data;

  if (!userId) {
    throw new functions.https.HttpsError('invalid-argument', 'Missing userId.');
  }

  try {
    const userRef = db.collection('users').doc(userId);
    const walletRef = userRef.collection('wallet').doc('aura');
    const auditRef = userRef.collection('token_audit');

    // Get wallet data
    const walletSnap = await walletRef.get();
    const walletData = walletSnap.exists ? walletSnap.data() : null;

    // Get recent audit records (last 10)
    const auditSnap = await auditRef
      .orderBy('createdAt', 'desc')
      .limit(10)
      .get();

    const auditRecords = auditSnap.docs.map(doc => ({
      id: doc.id,
      ...doc.data(),
      createdAt: doc.data().createdAt?.toDate?.()?.toISOString() || null,
    }));

    return {
      success: true,
      wallet: walletData,
      auditRecords,
      walletPath: `users/${userId}/wallet/aura`,
      auditPath: `users/${userId}/token_audit`,
    };
  } catch (error) {
    console.error('Error verifying token data:', error);
    throw new functions.https.HttpsError('internal', 'Failed to verify token data');
  }
});