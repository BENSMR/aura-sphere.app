import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';

/// Audit event types
export enum AuditType {
  EMAIL_QUEUED = 'emailQueued',
  EMAIL_SENT = 'emailSent',
  EMAIL_FAILED = 'emailFailed',
  PUSH_QUEUED = 'pushQueued',
  PUSH_SENT = 'pushSent',
  PUSH_FAILED = 'pushFailed',
  DEVICE_REGISTERED = 'deviceRegistered',
  DEVICE_REMOVED = 'deviceRemoved',
  PREFERENCES_UPDATED = 'preferencesUpdated',
}

/// Audit status
export enum AuditStatus {
  QUEUED = 'queued',
  SENT = 'sent',
  FAILED = 'failed',
  PROCESSING = 'processing',
}

/// Log audit event to Firestore
export async function logAuditEvent(
  userId: string,
  type: AuditType,
  status: AuditStatus,
  eventId?: string,
  error?: string,
  metadata?: Record<string, any>
): Promise<string | null> {
  try {
    const db = admin.firestore();
    const actor = 'server'; // Cloud Functions runs as 'server'

    const auditDoc = await db.collection('notifications_audit').add({
      actor,
      targetUid: userId,
      type,
      eventId,
      status,
      error: error || null,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      metadata: metadata || {},
    });

    functions.logger.log(`📝 Audit recorded: ${type} -> ${status} for user ${userId}`);
    return auditDoc.id;
  } catch (error) {
    functions.logger.error(`❌ Failed to log audit: ${error}`);
    return null;
  }
}

/// Get audit records for user
export async function getUserAudits(
  userId: string,
  limit: number = 50
): Promise<any[]> {
  try {
    const db = admin.firestore();
    const snapshot = await db
      .collection('notifications_audit')
      .where('targetUid', '==', userId)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map((doc) => ({
      auditId: doc.id,
      ...doc.data(),
    }));
  } catch (error) {
    functions.logger.error(`❌ Failed to get user audits: ${error}`);
    return [];
  }
}

/// Get failed audits (for admin/monitoring)
export async function getFailedAudits(
  limit: number = 100
): Promise<any[]> {
  try {
    const db = admin.firestore();
    const snapshot = await db
      .collection('notifications_audit')
      .where('status', '==', AuditStatus.FAILED)
      .orderBy('createdAt', 'desc')
      .limit(limit)
      .get();

    return snapshot.docs.map((doc) => ({
      auditId: doc.id,
      ...doc.data(),
    }));
  } catch (error) {
    functions.logger.error(`❌ Failed to get failed audits: ${error}`);
    return [];
  }
}

/// Update audit status
export async function updateAuditStatus(
  auditId: string,
  newStatus: AuditStatus,
  error?: string
): Promise<boolean> {
  try {
    const db = admin.firestore();
    const updates: Record<string, any> = { status: newStatus };
    if (error) {
      updates.error = error;
    }

    await db.collection('notifications_audit').doc(auditId).update(updates);
    functions.logger.log(`📝 Audit ${auditId} updated to ${newStatus}`);
    return true;
  } catch (error) {
    functions.logger.error(`❌ Failed to update audit: ${error}`);
    return false;
  }
}

/// Get audit statistics for user
export async function getAuditStats(
  userId: string,
  startDate?: Date,
  endDate?: Date
): Promise<Record<string, number>> {
  try {
    const db = admin.firestore();
    let query = db
      .collection('notifications_audit')
      .where('targetUid', '==', userId);

    if (startDate) {
      query = query.where(
        'createdAt',
        '>=',
        admin.firestore.Timestamp.fromDate(startDate)
      );
    }

    if (endDate) {
      query = query.where(
        'createdAt',
        '<=',
        admin.firestore.Timestamp.fromDate(endDate)
      );
    }

    const snapshot = await query.get();
    const stats: Record<string, number> = {
      total: snapshot.size,
      queued: 0,
      sent: 0,
      failed: 0,
      processing: 0,
      emailQueued: 0,
      emailSent: 0,
      emailFailed: 0,
      pushQueued: 0,
      pushSent: 0,
      pushFailed: 0,
    };

    snapshot.docs.forEach((doc) => {
      const data = doc.data();
      const status = data.status;
      const type = data.type;

      stats[status] = (stats[status] || 0) + 1;

      if (type.startsWith('email')) {
        stats[`email${status}`] = (stats[`email${status}`] || 0) + 1;
      } else if (type.startsWith('push')) {
        stats[`push${status}`] = (stats[`push${status}`] || 0) + 1;
      }
    });

    return stats;
  } catch (error) {
    functions.logger.error(`❌ Failed to get audit stats: ${error}`);
    return {};
  }
}

/// Clean up old audit records
export async function deleteOldAudits(
  olderThanDays: number
): Promise<number> {
  try {
    const db = admin.firestore();
    const cutoffDate = new Date();
    cutoffDate.setDate(cutoffDate.getDate() - olderThanDays);

    const snapshot = await db
      .collection('notifications_audit')
      .where(
        'createdAt',
        '<',
        admin.firestore.Timestamp.fromDate(cutoffDate)
      )
      .get();

    let deletedCount = 0;
    for (const doc of snapshot.docs) {
      await doc.ref.delete();
      deletedCount++;
    }

    functions.logger.log(`🗑️ Deleted ${deletedCount} old audit records`);
    return deletedCount;
  } catch (error) {
    functions.logger.error(`❌ Failed to delete old audits: ${error}`);
    return 0;
  }
}
