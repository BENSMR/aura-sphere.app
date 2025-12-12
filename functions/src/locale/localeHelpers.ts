// functions/src/locale/localeHelpers.ts
import * as admin from 'firebase-admin';
import { DateTime } from 'luxon';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

export type LocaleDoc = {
  locale?: string;       // e.g. 'en-US'
  currency?: string;     // e.g. 'USD'
  country?: string;      // e.g. 'US'
  dateFormat?: string;   // optional custom format e.g. 'dd/MM/yyyy'
  invoicePrefix?: string;
  updatedAt?: FirebaseFirestore.Timestamp;
};

// Minimal country -> currency mapping (extend as needed)
const COUNTRY_CURRENCY: Record<string, string> = {
  US: 'USD',
  GB: 'GBP',
  FR: 'EUR',
  DE: 'EUR',
  ES: 'EUR',
  BR: 'BRL',
  IN: 'INR',
  AE: 'AED',
  SA: 'SAR',
  CN: 'CNY'
};

export async function getUserLocaleDoc(uid: string): Promise<LocaleDoc> {
  if (!uid) return {};
  const doc = await db.collection('users').doc(uid).collection('settings').doc('locale').get();
  if (!doc.exists) return {};
  return doc.data() as LocaleDoc;
}

export async function setUserLocaleDoc(uid: string, payload: Partial<LocaleDoc>) {
  if (!uid) throw new Error('uid-required');
  const ref = db.collection('users').doc(uid).collection('settings').doc('locale');
  const docPayload = {
    ...payload,
    updatedAt: admin.firestore.FieldValue.serverTimestamp()
  };
  await ref.set(docPayload, { merge: true });
  return ref.get();
}

export function defaultCurrencyForCountry(country?: string): string {
  if (!country) return 'USD';
  const c = country.toUpperCase();
  return COUNTRY_CURRENCY[c] || 'USD';
}

/** Format server-side dates into user's locale and timezone (uses luxon) */
export async function formatDateForUser(
  uid: string,
  isoTimestamp: string | Date,
  options?: { zoneOverride?: string; fmt?: string }
): Promise<string> {
  const localeDoc = await getUserLocaleDoc(uid);
  const tzDoc = await db.collection('users').doc(uid).collection('settings').doc('timezone').get();
  const zone = tzDoc.exists ? (tzDoc.data()?.timezone as string) || 'UTC' : 'UTC';

  const dt = typeof isoTimestamp === 'string'
    ? DateTime.fromISO(isoTimestamp, { zone: 'utc' })
    : DateTime.fromJSDate(isoTimestamp as Date, { zone: 'utc' });

  const dtLocal = dt.setZone(options?.zoneOverride || zone);
  const fmt = options?.fmt || localeDoc.dateFormat || DateTime.DATE_MED;

  if (typeof fmt === 'string') {
    return dtLocal.toFormat(fmt);
  }
  return dtLocal.setLocale(localeDoc.locale || 'en').toLocaleString(fmt as any);
}

/** Trimmed locale info for audit logs */
export function trimLocaleForAudit(localeDoc: LocaleDoc) {
  return {
    locale: localeDoc.locale || null,
    currency: localeDoc.currency || null,
    country: localeDoc.country || null,
    invoicePrefix: localeDoc.invoicePrefix || null
  };
}
