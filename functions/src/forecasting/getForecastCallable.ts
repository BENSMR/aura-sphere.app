// functions/src/forecasting/getForecastCallable.ts
import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { generateForecastForUser } from './generateForecast';

if (!admin.apps.length) admin.initializeApp();

export const getForecastCallable = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) {
    throw new functions.https.HttpsError('unauthenticated', 'Not signed in');
  }

  const horizon = Number(data?.horizon ?? 90);
  if (isNaN(horizon) || horizon <= 0 || horizon > 365) {
    throw new functions.https.HttpsError('invalid-argument', 'Invalid horizon');
  }

  const forecastRef = admin.firestore().collection('users').doc(uid).collection('forecasts').doc('cashflow');
  const cached = await forecastRef.get();

  const MAX_AGE_MS = 12 * 60 * 60 * 1000; // 12 hours
  if (
    cached.exists &&
    cached.data()?.generatedAt &&
    Date.now() - cached.data()!.generatedAt.toDate().getTime() < MAX_AGE_MS &&
    (cached.data()!.horizonDays === horizon || horizon === 90)
  ) {
    return cached.data();
  }

  return await generateForecastForUser(uid, { daysPast: 120, horizon });
});
