import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { saveUserNotification, getUserDeviceTokens, sendPushToTokens } from './helpers';
import { shouldSendNotification, DedupeKey, recordSkippedAudit, recordSentAudit, recordFailedAudit } from './dedupeThrottle';

const db = admin.firestore();

/**
 * Trigger: anomaly created under /anomalies/{docId}
 * Includes deduplication & throttling to prevent notification spam
 */
export const onAnomalyCreate = functions.firestore
  .document('anomalies/{anomalyId}')
  .onCreate(async (snap, ctx) => {
    try {
      const data = snap.data() || {};
      const severity = (data.severity || 'medium') as string;
      const entityType = data.entityType || 'unknown';
      const entityId = data.entityId || snap.id;
      const ownerUid = data.ownerUid || data.uid || null;

      if (!ownerUid) {
        await recordFailedAudit('system', snap.id, 'anomaly', 'No owner UID');
        return null;
      }

      // Build dedup key
      const dedupeKey: DedupeKey = {
        targetUid: ownerUid,
        eventType: 'anomaly',
        entityType: String(entityType),
        entityId: String(entityId),
      };

      // Check deduplication & throttling
      const dedupeResult = await shouldSendNotification(dedupeKey, severity);
      if (!dedupeResult.send) {
        await recordSkippedAudit(ownerUid, snap.id, 'anomaly', dedupeResult.reason);
        return null;
      }

      // Build notification
      const title = `Alert: ${severity.toUpperCase()} anomaly detected`;
      const body = `${entityType} ${entityId} flagged as ${severity}. Tap to review.`;
      const severityCast = (severity as 'low' | 'medium' | 'high' | 'critical');

      // Save to user notifications
      await saveUserNotification(ownerUid, {
        type: 'anomaly',
        title,
        body,
        severity: severityCast,
        payload: { entityType, entityId },
      });

      // Send push notifications
      const { tokens } = await getUserDeviceTokens(ownerUid);
      if (tokens.length > 0) {
        const message = {
          notification: { title, body },
          data: { type: 'anomaly', entityType: String(entityType), entityId: String(entityId), severity: String(severity) },
          android: { priority: 'high' },
          apns: { headers: { 'apns-priority': '10' } },
        };
        try {
          const res = await sendPushToTokens(tokens, message as any);
          await recordSentAudit(ownerUid, snap.id, 'anomaly', { sent: tokens.length - res.failureCount, failed: res.failureCount });
        } catch (pushErr) {
          await recordFailedAudit(ownerUid, snap.id, 'anomaly', String(pushErr));
        }
      }

      return null;
    } catch (err) {
      console.error('onAnomalyCreate error', err);
      await recordFailedAudit('system', ctx.params.anomalyId || null, 'anomaly', String(err));
      return null;
    }
  });

/**
 * Trigger: invoice created/updated under users/{uid}/invoices/{invoiceId}
 * Sends overdue/payment reminders with deduplication & throttling
 */
export const onInvoiceWrite = functions.firestore
  .document('users/{uid}/invoices/{invoiceId}')
  .onWrite(async (change, ctx) => {
    try {
      const before = change.before.exists ? change.before.data() : null;
      const after = change.after.exists ? change.after.data() : null;
      const uid = ctx.params.uid as string;
      const invoiceId = ctx.params.invoiceId as string;

      // Check if status changed to overdue or if due date passed
      const statusAfter = after?.status || '';
      const statusBefore = before?.status || '';
      const becameOverdue = statusBefore !== 'overdue' && statusAfter === 'overdue';

      const dueDate = after?.dueDate ? new Date(after.dueDate) : null;
      const now = new Date();
      const isPastDue = dueDate && dueDate < now && after?.status !== 'paid';

      if (!becameOverdue && !isPastDue) return null;

      // Build dedup key
      const dedupeKey: DedupeKey = {
        targetUid: uid,
        eventType: 'invoice_overdue',
        entityType: 'invoice',
        entityId: invoiceId,
      };

      // Check deduplication & throttling
      const dedupeResult = await shouldSendNotification(dedupeKey, 'high');
      if (!dedupeResult.send) {
        await recordSkippedAudit(uid, invoiceId, 'invoice_overdue', dedupeResult.reason);
        return null;
      }

      // Build notification
      const title = `Invoice ${invoiceId} is overdue`;
      const body = `Invoice ${invoiceId} for ${after?.amount || ''} ${after?.currency || ''} is overdue.`;

      // Save to user notifications
      await saveUserNotification(uid, {
        type: 'invoice',
        title,
        body,
        severity: 'high',
        payload: { invoiceId },
      });

      // Send push notifications
      const { tokens } = await getUserDeviceTokens(uid);
      if (tokens.length > 0) {
        const message = {
          notification: { title, body },
          data: { type: 'invoice', invoiceId },
          android: { priority: 'high' },
          apns: { headers: { 'apns-priority': '10' } },
        };
        try {
          const res = await sendPushToTokens(tokens, message as any);
          await recordSentAudit(uid, invoiceId, 'invoice_overdue', { sent: tokens.length - res.failureCount, failed: res.failureCount });
        } catch (pushErr) {
          await recordFailedAudit(uid, invoiceId, 'invoice_overdue', String(pushErr));
        }
      }

      return null;
    } catch (err) {
      console.error('onInvoiceWrite error', err);
      await recordFailedAudit('system', ctx.params.invoiceId || null, 'invoice', String(err));
      return null;
    }
  });
