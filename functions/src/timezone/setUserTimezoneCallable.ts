// functions/src/timezone/setUserTimezoneCallable.ts
import * as functions from 'firebase-functions';
import { setUserTimezone } from './userTimezone';

export const setUserTimezoneCallable = functions.https.onCall(async (data, context) => {
  const uid = context.auth?.uid;
  if (!uid) throw new functions.https.HttpsError('unauthenticated', 'Not signed in');
  const timezone = data?.timezone;
  const locale = data?.locale;
  const country = data?.country;
  if (!timezone) throw new functions.https.HttpsError('invalid-argument', 'timezone required');
  await setUserTimezone(uid, { timezone, locale, country });
  return { ok: true };
});
