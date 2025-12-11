import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

if (!admin.apps.length) admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

export type NotificationPayload = {
  type: string;
  title: string;
  body: string;
  severity?: 'low'|'medium'|'high'|'critical';
  payload?: Record<string, any>;
  meta?: Record<string, any>;
};

export async function saveUserNotification(uid: string, notif: NotificationPayload) {
  const notifRef = db.collection('users').doc(uid).collection('notifications').doc();
  const record = {
    type: notif.type,
    title: notif.title,
    body: notif.body,
    severity: notif.severity || 'low',
    payload: notif.payload || {},
    meta: notif.meta || {},
    read: false,
    delivered: false,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  };
  await notifRef.set(record);
  return notifRef.id;
}

export async function auditNotification(targetUid: string, eventId: string | null, type: string, status: string, error?: string) {
  const auditRef = db.collection('notifications_audit').doc();
  await auditRef.set({
    actor: 'server',
    targetUid,
    eventId: eventId || null,
    type,
    status,
    error: error || null,
    createdAt: admin.firestore.FieldValue.serverTimestamp()
  });
}

export async function getUserDeviceTokens(uid: string) : Promise<{tokens:string[], platforms: Record<string, number>}> {
  const snap = await db.collection('users').doc(uid).collection('devices').get();
  const tokens: string[] = [];
  const platforms: Record<string, number> = {};
  snap.forEach(d => {
    const data = d.data() as any;
    if (data?.token) {
      tokens.push(data.token);
      platforms[data.platform || 'unknown'] = (platforms[data.platform || 'unknown'] || 0) + 1;
    }
  });
  return { tokens, platforms };
}

export async function sendPushToTokens(tokens: string[], payload: admin.messaging.MulticastMessage) {
  if (!tokens || tokens.length === 0) return { successCount: 0, failureCount: 0, responses: [] };
  const res = await messaging.sendMulticast({ ...payload, tokens } as any);
  return res;
}
