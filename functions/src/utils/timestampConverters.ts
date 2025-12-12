import * as admin from 'firebase-admin';
import { DateTime } from 'luxon';
import { convertToUserLocalTime } from '../timezone/userTimezone';

/**
 * Converts Firestore Timestamp to user's local time
 * 
 * Usage:
 *   const localDate = await convertFirestoreTimestampToUserLocal(uid, entry.date);
 * 
 * @param uid User ID
 * @param timestamp Firestore Timestamp
 * @returns Luxon DateTime in user's timezone
 */
export async function convertFirestoreTimestampToUserLocal(
  uid: string,
  timestamp?: admin.firestore.Timestamp
): Promise<DateTime | null> {
  if (!timestamp) return null;
  return convertToUserLocalTime(uid, timestamp.toDate());
}

/**
 * Format a Firestore timestamp in user's local timezone
 * 
 * Usage:
 *   const formatted = await formatTimestampForUser(uid, entry.date, 'MMMM dd, yyyy HH:mm');
 * 
 * @param uid User ID
 * @param timestamp Firestore Timestamp
 * @param format Luxon format string
 * @returns Formatted date string
 */
export async function formatTimestampForUser(
  uid: string,
  timestamp?: admin.firestore.Timestamp,
  format: string = 'MMMM dd, yyyy HH:mm'
): Promise<string | null> {
  const localDate = await convertFirestoreTimestampToUserLocal(uid, timestamp);
  if (!localDate) return null;
  return localDate.toFormat(format);
}

/**
 * Get relative time (e.g., "2 hours ago") for a Firestore timestamp in user's local time
 * 
 * Usage:
 *   const relative = await getRelativeTime(uid, entry.date);
 * 
 * @param uid User ID
 * @param timestamp Firestore Timestamp
 * @returns Relative time string
 */
export async function getRelativeTime(
  uid: string,
  timestamp?: admin.firestore.Timestamp
): Promise<string | null> {
  const localDate = await convertFirestoreTimestampToUserLocal(uid, timestamp);
  if (!localDate) return null;
  
  const now = DateTime.now().setZone(localDate.zone);
  const diff = now.diff(localDate, ['hours', 'minutes', 'seconds']);
  
  if (diff.hours > 24) {
    return `${Math.floor(diff.hours / 24)} days ago`;
  }
  if (diff.hours > 0) {
    return `${Math.floor(diff.hours)} hours ago`;
  }
  if (diff.minutes > 0) {
    return `${Math.floor(diff.minutes)} minutes ago`;
  }
  return 'just now';
}
