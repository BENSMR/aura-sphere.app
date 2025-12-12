// functions/src/timezone/userTimezone.ts
import * as admin from 'firebase-admin';
import { DateTime } from 'luxon';
import { isValidIanaZone } from './utils';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

export type UserTimezoneDoc = {
  timezone?: string; // IANA e.g. "Europe/Paris"
  locale?: string;   // BCP-47 e.g. "fr-FR"
  country?: string;  // ISO2 e.g. "FR"
  updatedAt?: FirebaseFirestore.Timestamp;
};

/**
 * getUserTimezone
 * returns the user's timezone doc or defaults
 */
export async function getUserTimezone(uid: string): Promise<UserTimezoneDoc> {
  if (!uid) return {};
  const doc = await db.collection('users').doc(uid).collection('settings').doc('timezone').get();
  if (!doc.exists) return {};
  return doc.data() as UserTimezoneDoc;
}

/**
 * setUserTimezone
 * saves/updates timezone doc (server-side)
 */
export async function setUserTimezone(uid: string, payload: Partial<UserTimezoneDoc>) {
  if (!uid) throw new Error('uid-required');
  if (payload.timezone && !isValidIanaZone(payload.timezone)) {
    throw new Error('invalid_timezone');
  }
  const ref = db.collection('users').doc(uid).collection('settings').doc('timezone');
  const docPayload = {
    ...payload,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };
  await ref.set(docPayload, { merge: true });
  return await ref.get();
}

/**
 * convertToUserLocalTime
 * Convert ISO timestamp (or Date) to user's timezone DateTime (Luxon)
 */
export async function convertToUserLocalTime(uid: string, isoTimestamp: string | Date): Promise<DateTime> {
  const tzDoc = await getUserTimezone(uid);
  const zone = tzDoc.timezone || 'UTC';
  const dt = typeof isoTimestamp === 'string' ? DateTime.fromISO(isoTimestamp, { zone: 'utc' }) : DateTime.fromJSDate(isoTimestamp as Date, { zone: 'utc' });
  return dt.setZone(zone);
}

/**
 * isWithinQuietHours
 * Check user's quiet hours for given Date (defaults to user local now)
 * quietHours: { enabled: boolean, startHour: number, endHour: number }
 * returns { inside: boolean, startHour, endHour, currentHour }
 */
export async function isWithinQuietHours(uid: string, date?: Date) {
  const tzDoc = await getUserTimezone(uid);
  const prefsDoc = await db.collection('users').doc(uid).collection('settings').doc('notification_preferences').get();
  const prefs: any = prefsDoc.exists ? prefsDoc.data() : null;

  if (!prefs || !prefs.quietHours || !prefs.quietHours.enabled) {
    return { inside: false };
  }

  const zone = tzDoc.timezone || 'UTC';
  const nowUtc = date ? DateTime.fromJSDate(date, { zone: 'utc' }) : DateTime.utc();
  const nowLocal = nowUtc.setZone(zone);
  const h = nowLocal.hour; // 0-23

  const start = Number(prefs.quietHours.startHour ?? 22);
  const end = Number(prefs.quietHours.endHour ?? 7);
  const inside = start < end ? (h >= start && h < end) : (h >= start || h < end);
  return { inside, startHour: start, endHour: end, currentHour: h, zone };
}

/**
 * formatForAudit
 * Return trimmed timezone info to include in audit logs
 */
export function formatPrefsForAudit(tzDoc: UserTimezoneDoc, prefs: any) {
  return {
    timezone: tzDoc.timezone || 'UTC',
    locale: tzDoc.locale || null,
    country: tzDoc.country || null,
    quietHours: prefs?.quietHours ?? null
  };
}
