import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { saveUserNotification, auditNotification, getUserDeviceTokens, sendPushToTokens } from './helpers';

const db = admin.firestore();

/**
 * Trigger: anomaly created under /anomalies/{docId}
 * Adjust to your data model – if anomalies are under users/{uid}/anomalies, adapt accordingly.
 */
export const onAnomalyCreate = functions.firestore
  .document('anomalies/{anomalyId}')
  .onCreate(async (snap, ctx) => {
    try {
      const data = snap.data() || {};
      const severity = (data.severity || 'medium') as string;
      const entityType = data.entityType || 'unknown';
      const entityId = data.entityId || snap.id;
      // target user(s) determination: if anomaly contains ownerUid, use that; else broadcast to admins
      const ownerUid = data.ownerUid || data.uid || null;

      const title = `Alert: ${severity.toUpperCase()} anomaly detected`;
      const body = `${entityType} ${entityId} flagged as ${severity}. Tap to review.`;

      if (ownerUid) {
        // persist notification, fetch tokens and push
        const severityCast = (severity as 'low' | 'medium' | 'high' | 'critical');
        await saveUserNotification(ownerUid, { type: 'anomaly', title, body, severity: severityCast, payload: { entityType, entityId }});
        const { tokens } = await getUserDeviceTokens(ownerUid);
        const message = {
          notification: { title, body },
          data: { type: 'anomaly', entityType: String(entityType), entityId: String(entityId), severity: String(severity) },
          android: { priority: 'high' },
          apns: { headers: { 'apns-priority': '10' } }
        };
        const res = await sendPushToTokens(tokens, message as any);
        await auditNotification(ownerUid, String(entityId), 'anomaly', 'sent');
        return null;
      } else {
        // broadcast - write to audit for admins
        await auditNotification('admin-broadcast', String(entityId), 'anomaly', 'queued');
      }
      return null;
    } catch (err) {
      console.error('onAnomalyCreate error', err);
      await auditNotification('system', ctx.params.anomalyId || null, 'anomaly', 'failed', String(err));
      return null;
    }
  });

/**
 * Trigger: invoice created/updated under users/{uid}/invoices/{invoiceId}
 * Example of sending invoice reminders on overdue
 */
export const onInvoiceWrite = functions.firestore
  .document('users/{uid}/invoices/{invoiceId}')
  .onWrite(async (change, ctx) => {
    try {
      const before = change.before.exists ? change.before.data() : null;
      const after = change.after.exists ? change.after.data() : null;
      const uid = ctx.params.uid as string;
      const invoiceId = ctx.params.invoiceId as string;

      // Example: if invoice becomes overdue or status changes to 'overdue'
      const statusAfter = after?.status || '';
      const statusBefore = before?.status || '';

      // Send only when status becomes overdue OR if dueDate passed and unpaid
      const becameOverdue = (statusBefore !== 'overdue' && statusAfter === 'overdue');

      // Optionally: check dueDate and current timestamp
      const dueDate = after?.dueDate ? new Date(after.dueDate) : null;
      const now = new Date();

      const shouldNotify = becameOverdue || (dueDate && dueDate < now && after?.status !== 'paid');

      if (!shouldNotify) return null;

      const title = `Invoice ${invoiceId} is overdue`;
      const body = `Invoice ${invoiceId} for ${after?.amount || ''} ${after?.currency || ''} is overdue.`;

      await saveUserNotification(uid, { type: 'invoice', title, body, severity: 'high', payload: { invoiceId }});
      const { tokens } = await getUserDeviceTokens(uid);
      const message = {
        notification: { title, body },
        data: { type: 'invoice', invoiceId },
        android: { priority: 'high' },
        apns: { headers: { 'apns-priority': '10' } }
      };
      const res = await sendPushToTokens(tokens, message as any);
      await auditNotification(uid, invoiceId, 'invoice_overdue', 'sent');
      return null;
    } catch (err) {
      console.error('onInvoiceWrite error', err);
      await auditNotification('system', ctx.params.invoiceId || null, 'invoice', 'failed', String(err));
      return null;
    }
  });
