import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { handleDailyLogin } from '../loyalty/loyaltyEngine';

export const onUserLogin = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }
  const uid = context.auth.uid;
  try {
    const result = await handleDailyLogin(uid);
    return { ok: true, result };
  } catch (err) {
    console.error('onUserLogin error', err);
    throw new functions.https.HttpsError('internal', 'Failed to run loyalty login');
  }
});
