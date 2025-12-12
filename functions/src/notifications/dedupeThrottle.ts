/**
 * dedupeThrottle.ts
 *
 * Robust deduplication + burst-throttle engine for notifications.
 * Designed to be simple, testable and safe for production.
 *
 * Behavior summary:
 * - Critical severity bypasses dedupe (always send).
 * - For non-critical events:
 *   → Check per-entity dedupe doc: `notification_dedupe/{docId}`
 *   → If `lastSent` is within `dedupeWindow` → SKIP (audit as skipped)
 *   → Else allow send and update `lastSent`
 * - Also apply burst throttle: max N sent notifications per user in rolling window.
 *
 * TTL / cleanup:
 * - The `notification_dedupe` collection should have Firestore TTL on `lastSent`
 *   (configure in Firebase Console) to auto-clean old entries.
 */

import * as admin from 'firebase-admin';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

// -------------------------
// Configurable defaults
// -------------------------
export const DEFAULT_DEDUPE_HOURS = 6;    // dedupe window for identical events
export const DEFAULT_BURST_LIMIT = 3;     // max sent notifications per user
export const BURST_WINDOW_MINUTES = 60;   // rolling window for burst limit


export interface DedupeKey {
  targetUid: string;
  eventType: string;
  entityType?: string;
  entityId?: string;
}

/**
 * Normalizes a string part for safe, deterministic ID generation.
 */
function normalizePart(s?: string): string {
  return (s || 'any').toString().trim().replace(/\s+/g, '_').toLowerCase();
}

/**
 * Builds a stable Firestore document ID for deduplication.
 */
export function buildDedupeDocId(key: DedupeKey): string {
  return `${normalizePart(key.targetUid)}_${normalizePart(key.eventType)}_${normalizePart(key.entityType)}_${normalizePart(key.entityId)}`;
}

/**
 * Converts hours to milliseconds.
 */
export function dedupeWindowMs(hours: number): number {
  return hours * 3600 * 1000;
}

/**
 * Determines whether a notification should be sent based on dedupe and burst rules.
 *
 * @returns {Promise<{ send: boolean; reason: string }>}
 */
export async function shouldSendNotification(
  key: DedupeKey,
  severity: string,
  options?: {
    dedupeHours?: number;
    burstLimit?: number;
    burstWindowMinutes?: number;
  }
): Promise<{ send: boolean; reason: string }> {
  // Critical notifications always bypass throttling
  if (severity === 'critical') {
    return { send: true, reason: 'critical_bypass' };
  }

  const dedupeHours = options?.dedupeHours ?? DEFAULT_DEDUPE_HOURS;
  const burstLimit = options?.burstLimit ?? DEFAULT_BURST_LIMIT;
  const burstWindowMinutes = options?.burstWindowMinutes ?? BURST_WINDOW_MINUTES;

  const dedupeDocId = buildDedupeDocId(key);
  const dedupeRef = db.collection('notification_dedupe').doc(dedupeDocId);
  const now = admin.firestore.Timestamp.now();
  const dedupeWindowMsVal = dedupeWindowMs(dedupeHours);

  // Check dedupe document
  const dedupeSnap = await dedupeRef.get();
  if (dedupeSnap.exists) {
    const data = dedupeSnap.data();
    const lastSent = data?.lastSent instanceof admin.firestore.Timestamp ? data.lastSent : null;

    if (lastSent) {
      const msSinceLast = now.toMillis() - lastSent.toMillis();
      if (msSinceLast < dedupeWindowMsVal) {
        return {
          send: false,
          reason: `deduped_recently_${Math.floor(msSinceLast / 1000)}s`,
        };
      }
    }
  }

  // Burst throttle: count recent 'sent' audits
  const burstWindowStart = admin.firestore.Timestamp.fromMillis(
    now.toMillis() - burstWindowMinutes * 60 * 1000
  );

  const recentAuditSnapshot = await db
    .collection('notifications_audit')
    .where('targetUid', '==', key.targetUid)
    .where('status', '==', 'sent')
    .where('createdAt', '>=', burstWindowStart)
    .get();

  if (recentAuditSnapshot.size >= burstLimit) {
    return {
      send: false,
      reason: `burst_limit_reached_${recentAuditSnapshot.size}`,
    };
  }

  // Allow send: update dedupe record
  await dedupeRef.set(
    {
      targetUid: key.targetUid,
      eventType: key.eventType,
      entityType: key.entityType || null,
      entityId: key.entityId || null,
      lastSent: admin.firestore.FieldValue.serverTimestamp(),
      count: admin.firestore.FieldValue.increment(1),
    },
    { merge: true }
  );

  return { send: true, reason: 'ok' };
}

// --- Audit helpers (minimal, focused) ---

interface AuditBase {
  targetUid: string;
  eventId: string | null;
  type: string;
}

export async function recordSkippedAudit(
  targetUid: string,
  eventId: string | null,
  type: string,
  reason: string
): Promise<void> {
  await db.collection('notifications_audit').add({
    ...getBaseAudit(targetUid, eventId, type),
    status: 'skipped',
    reason,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export async function recordSentAudit(
  targetUid: string,
  eventId: string | null,
  type: string,
  meta: Record<string, unknown> = {}
): Promise<void> {
  await db.collection('notifications_audit').add({
    ...getBaseAudit(targetUid, eventId, type),
    status: 'sent',
    meta,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

export async function recordFailedAudit(
  targetUid: string,
  eventId: string | null,
  type: string,
  error: string
): Promise<void> {
  await db.collection('notifications_audit').add({
    ...getBaseAudit(targetUid, eventId, type),
    status: 'failed',
    error,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

function getBaseAudit(targetUid: string, eventId: string | null, type: string): AuditBase {
  return { targetUid, eventId, type };
}
