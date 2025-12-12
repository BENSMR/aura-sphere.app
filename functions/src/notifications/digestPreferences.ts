import * as admin from 'firebase-admin';
import { DateTime } from 'luxon';
import { convertToUserLocalTime } from '../timezone/userTimezone';

const db = admin.firestore();

export interface DigestPreferences {
  digestEnabled: boolean;
  digestFrequency: 'daily' | 'weekly'; // "daily" = every day, "weekly" = every Monday
  preferredHour: number; // 0-23, in user's local timezone
  includeInvoices: boolean;
  includeExpenses: boolean;
  includeTasks: boolean;
  includeStock: boolean;
  includeCRM: boolean;
  updatedAt?: admin.firestore.Timestamp;
}

/**
 * Get user's digest preferences
 */
export async function getDigestPreferences(uid: string): Promise<DigestPreferences | null> {
  try {
    const doc = await db
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('digest')
      .get();
    
    if (!doc.exists) return null;
    return doc.data() as DigestPreferences;
  } catch (error) {
    console.error(`[getDigestPreferences] Error for user ${uid}:`, error);
    return null;
  }
}

/**
 * Save/update user's digest preferences
 */
export async function setDigestPreferences(
  uid: string,
  prefs: Partial<DigestPreferences>
): Promise<void> {
  try {
    const ref = db
      .collection('users')
      .doc(uid)
      .collection('settings')
      .doc('digest');

    await ref.set(
      {
        ...prefs,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      },
      { merge: true }
    );
  } catch (error) {
    console.error(`[setDigestPreferences] Error for user ${uid}:`, error);
    throw error;
  }
}

/**
 * Check if user should receive a digest NOW based on their preferences
 * Returns true if:
 * - Digest is enabled
 * - Current hour matches preferred hour in user's timezone
 * - Frequency matches today (daily always matches, weekly only Monday)
 */
export async function shouldSendDigestNow(uid: string): Promise<boolean> {
  try {
    const prefs = await getDigestPreferences(uid);
    if (!prefs || !prefs.digestEnabled) return false;

    // Get current time in user's timezone
    const nowUtc = new Date();
    const userLocalTime = await convertToUserLocalTime(uid, nowUtc);

    // Check hour match
    if (userLocalTime.hour !== prefs.preferredHour) return false;

    // Check frequency
    if (prefs.digestFrequency === 'daily') {
      return true; // Send every day at this hour
    }

    if (prefs.digestFrequency === 'weekly') {
      // Send only on Monday (weekday 1)
      return userLocalTime.weekday === 1;
    }

    return false;
  } catch (error) {
    console.error(`[shouldSendDigestNow] Error for user ${uid}:`, error);
    return false;
  }
}

/**
 * Get next digest send time for a user
 * Useful for UI to show when digest will be sent
 */
export async function getNextDigestTime(uid: string): Promise<DateTime | null> {
  try {
    const prefs = await getDigestPreferences(uid);
    if (!prefs || !prefs.digestEnabled) return null;

    const nowUtc = DateTime.utc();
    const userLocalTime = await convertToUserLocalTime(uid, nowUtc.toJSDate());
    
    let nextTime = userLocalTime.set({ hour: prefs.preferredHour, minute: 0, second: 0 });

    // If preferred hour already passed today
    if (nextTime < userLocalTime) {
      if (prefs.digestFrequency === 'daily') {
        nextTime = nextTime.plus({ days: 1 });
      } else if (prefs.digestFrequency === 'weekly') {
        // Move to next Monday
        const daysUntilMonday = (1 - userLocalTime.weekday + 7) % 7 || 7;
        nextTime = nextTime.plus({ days: daysUntilMonday });
      }
    }

    // If daily and not Monday, but we're on weekly - adjust to next Monday
    if (prefs.digestFrequency === 'weekly' && nextTime.weekday !== 1) {
      const daysUntilMonday = (1 - nextTime.weekday + 7) % 7 || 7;
      nextTime = nextTime.plus({ days: daysUntilMonday });
    }

    return nextTime;
  } catch (error) {
    console.error(`[getNextDigestTime] Error for user ${uid}:`, error);
    return null;
  }
}

/**
 * Get digest scope (which categories to include)
 */
export function getDigestScope(prefs: DigestPreferences): string[] {
  const scope = [];
  if (prefs.includeInvoices) scope.push('invoices');
  if (prefs.includeExpenses) scope.push('expenses');
  if (prefs.includeTasks) scope.push('tasks');
  if (prefs.includeStock) scope.push('stock');
  if (prefs.includeCRM) scope.push('crm');
  return scope;
}
