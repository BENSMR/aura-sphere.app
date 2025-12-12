/**
 * functions/src/notifications/userPrefs.ts
 *
 * Helper: load user notification preferences and evaluate whether to send.
 * Usage:
 *   import { getUserPrefs, shouldNotify } from './notifications/userPrefs';
 *
 * Notes:
 *  - preferences are stored in: users/{uid}/settings/notification_preferences (doc id: prefs)
 *  - server writes remain authoritative. Clients may only update their own prefs.
 */

import * as admin from 'firebase-admin';
if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

export type CategoryKey = 'anomaly'|'invoice'|'inventory'|'crm'|'promotions';

export type Severity = 'info'|'warning'|'high'|'critical';

export interface NotificationPreferences {
  enabled: { [K in CategoryKey]?: boolean };
  minSeverity: { [K in CategoryKey]?: Severity };
  quietHours?: { enabled: boolean; startHour: number; endHour: number }; // local hours 0-23
  globalDnd?: boolean;
  allowOverrideThrottle?: boolean; // (admin/user toggle)
  updatedAt?: FirebaseFirestore.Timestamp;
}

// default preference (safe)
export const DEFAULT_PREFS: NotificationPreferences = {
  enabled: { anomaly: true, invoice: true, inventory: true, crm: true, promotions: false },
  minSeverity: { anomaly: 'info', invoice: 'warning', inventory: 'warning', crm: 'info', promotions: 'info' },
  quietHours: { enabled: false, startHour: 22, endHour: 7 },
  globalDnd: false,
  allowOverrideThrottle: false
};

export async function getUserPrefs(uid: string): Promise<NotificationPreferences> {
  if (!uid) return DEFAULT_PREFS;
  const doc = await db.collection('users').doc(uid).collection('settings').doc('notification_preferences').get();
  if (!doc.exists) return DEFAULT_PREFS;
  const data = doc.data() || {};
  // shallow merge defaults
  const merged: NotificationPreferences = {
    ...DEFAULT_PREFS,
    ...data,
    enabled: { ...DEFAULT_PREFS.enabled, ...(data.enabled || {}) },
    minSeverity: { ...DEFAULT_PREFS.minSeverity, ...(data.minSeverity || {}) },
    quietHours: data.quietHours ?? DEFAULT_PREFS.quietHours,
    globalDnd: typeof data.globalDnd === 'boolean' ? data.globalDnd : DEFAULT_PREFS.globalDnd,
    allowOverrideThrottle: typeof data.allowOverrideThrottle === 'boolean' ? data.allowOverrideThrottle : DEFAULT_PREFS.allowOverrideThrottle,
    updatedAt: doc.updateTime ?? doc.createTime ?? admin.firestore.Timestamp.now()
  };
  return merged;
}

// Map severity string to numeric level for easy comparison
const severityLevel = (s: Severity) => {
  switch (s) {
    case 'info': return 10;
    case 'warning': return 20;
    case 'high': return 30;
    case 'critical': return 40;
    default: return 0;
  }
};

/**
 * shouldNotify
 * - uid: target user
 * - category: category key (anomaly, invoice...)
 * - severity: event severity of the notification
 * - options.quietHoursLocal?: user's local time (Date) - if provided, we check quiet hours using local hour
 *
 * returns { allowed: boolean, reason: string, effectivePrefs }
 */
export async function shouldNotify(uid: string, category: CategoryKey, severity: Severity, options?: { nowDate?: Date }) {
  const prefs = await getUserPrefs(uid);

  // 1) global DND
  if (prefs.globalDnd) return { allowed: false, reason: 'global_dnd_enabled', effectivePrefs: prefs };

  // 2) category enabled?
  const categoryEnabled = prefs.enabled?.[category] ?? DEFAULT_PREFS.enabled?.[category] ?? true;
  if (!categoryEnabled) return { allowed: false, reason: 'category_disabled', effectivePrefs: prefs };

  // 3) severity threshold
  const minS = prefs.minSeverity?.[category] ?? DEFAULT_PREFS.minSeverity?.[category] ?? 'info';
  if (severityLevel(severity) < severityLevel(minS)) {
    return { allowed: false, reason: `below_min_severity (${severity} < ${minS})`, effectivePrefs: prefs };
  }

  // 4) quiet hours (local)
  const now = options?.nowDate ?? new Date();
  const q = prefs.quietHours;
  if (q?.enabled) {
    const h = now.getHours(); // server receives local time via client or assume UTC; recommend send local nowDate from client when possible.
    const start = q.startHour;
    const end = q.endHour;
    // handle wrap-around (e.g., start 22, end 7)
    const inQuiet = start < end ? (h >= start && h < end) : (h >= start || h < end);
    if (inQuiet) return { allowed: false, reason: 'quiet_hours', effectivePrefs: prefs };
  }

  // 5) allowed
  return { allowed: true, reason: 'allowed_by_prefs', effectivePrefs: prefs };
}

/**
 * Useful helper to snapshot effective prefs into audit records.
 * Example: call auditRecord.effectivePreferences = prefs (or a trimmed version)
 */
export function trimPrefsForAudit(prefs: NotificationPreferences) {
  return {
    enabled: prefs.enabled,
    minSeverity: prefs.minSeverity,
    quietHours: prefs.quietHours ? { enabled: prefs.quietHours.enabled, startHour: prefs.quietHours.startHour, endHour: prefs.quietHours.endHour } : null,
    globalDnd: prefs.globalDnd,
    allowOverrideThrottle: prefs.allowOverrideThrottle,
  };
}
