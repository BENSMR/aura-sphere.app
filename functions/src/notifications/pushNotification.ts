import * as functions from 'firebase-functions';
import admin from 'firebase-admin';
import { logAuditEvent, AuditType, AuditStatus, updateAuditStatus } from './auditLogger';

const db = admin.firestore();
const messaging = admin.messaging();
const logger = functions.logger;

interface PushNotificationPayload {
  userId: string;
  title: string;
  body: string;
  notificationType: 'anomaly' | 'invoice' | 'expense' | 'payment' | 'system';
  severity?: 'critical' | 'high' | 'medium' | 'low';
  actionUrl?: string;
  data?: Record<string, string>;
}

interface SendResult {
  success: boolean;
  messageIds?: string[];
  failureCount?: number;
  error?: string;
}

/**
 * Send push notification to user(s)
 * Retrieves FCM tokens from devices and sends via Firebase Cloud Messaging
 */
export const sendPushNotification = async (
  payload: PushNotificationPayload
): Promise<SendResult> => {
  try {
    const { userId, title, body, notificationType, severity, actionUrl, data } = payload;

    // Log as queued
    const auditId = await logAuditEvent(
      userId,
      AuditType.PUSH_QUEUED,
      AuditStatus.QUEUED,
      undefined,
      undefined,
      { title, body, type: notificationType }
    );

    // Get user's registered devices
    const devicesSnapshot = await db.collection('users').doc(userId).collection('devices').get();
    if (devicesSnapshot.empty) {
      logger.warn(`No devices registered for user ${userId}`);
      if (auditId) {
        await updateAuditStatus(auditId, AuditStatus.FAILED, 'No devices registered');
      }
      return { success: false, error: 'No devices registered' };
    }

    // Filter devices by notification preferences
    const deviceDocs = devicesSnapshot.docs.filter((doc) => {
      const prefs = doc.data().prefs || {};
      
      // Check if 'all' notifications are enabled
      if (!prefs.all) return false;

      // Check specific notification type
      const typeKey = notificationType.toLowerCase();
      if (typeKey === 'anomaly') return prefs.anomalies !== false;
      if (typeKey === 'invoice') return prefs.invoices !== false;
      if (typeKey === 'inventory') return prefs.inventory !== false;
      return true;
    });

    if (deviceDocs.length === 0) {
      logger.info(`Notification type ${notificationType} disabled for all devices of user ${userId}`);
      return { success: false, error: 'Notification type disabled on all devices' };
    }

    // Check quiet hours for non-critical notifications
    let skipQuietHours = false;
    if (severity === 'critical') {
      skipQuietHours = true;
    }

    // Get user preferences
    const prefsDoc = await db
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('notifications')
        .get();
    const prefs = prefsDoc.data() || {};

    // Check quiet hours
    const now = new Date().getHours();
    if (!skipQuietHours && prefs.quietHoursEnabled && prefs.quietHoursStart && prefs.quietHoursEnd) {
      const start = parseInt(prefs.quietHoursStart);
      const end = parseInt(prefs.quietHoursEnd);
      
      const inQuietHours = end > start 
        ? (now >= start && now < end)
        : (now >= start || now < end);

      if (inQuietHours) {
        logger.info(`Quiet hours active for user ${userId}, skipping ${notificationType}`);
        return { success: false, error: 'Quiet hours active' };
      }
    }

    // Build notification message
    const message = {
      notification: {
        title,
        body,
      },
      webpush: {
        notification: {
          title,
          body,
          icon: 'https://aurasphere.app/assets/logo.png',
          badge: 'https://aurasphere.app/assets/badge.png',
        },
        fcmOptions: { link: actionUrl || process.env.APP_URL },
      },
      apns: {
        payload: {
          aps: {
            alert: { title, body },
            sound: severity === 'critical' ? 'default' : 'silent',
            badge: 1,
          },
        },
      },
      data: {
        notificationType,
        severity: severity || 'low',
        ...(actionUrl && { actionUrl }),
        ...data,
      },
    };

    // Send to all device tokens
    const results = await Promise.allSettled(
      deviceDocs.map((doc: any) => {
        const token = doc.data().token;
        const platform = doc.data().platform;
        
        return messaging.send({
          notification: message.notification,
          webpush: message.webpush,
          apns: message.apns,
          android: {
            priority: severity === 'critical' ? 'high' : 'normal',
            notification: {
              title,
              body,
              clickAction: actionUrl || process.env.APP_URL,
              channelId: `${notificationType}-${severity || 'normal'}`,
            },
          },
          data: message.data,
          token,
        });
      })
    );

    // Count successes/failures and collect message IDs
    let successCount = 0;
    let failureCount = 0;
    const messageIds: string[] = [];

    for (let i = 0; i < results.length; i++) {
      if (results[i].status === 'fulfilled') {
        successCount++;
        const result = results[i] as PromiseFulfilledResult<string>;
        messageIds.push(result.value);
        
        // Update device lastSeen
        await deviceDocs[i].ref.update({
          lastSeen: admin.firestore.FieldValue.serverTimestamp(),
        });
      } else {
        failureCount++;
        const error = (results[i] as PromiseRejectedResult).reason;
        const deviceId = deviceDocs[i].id;
        
        logger.error(`Failed to send to device ${deviceId}: ${error?.code || error?.message}`);
        
        // Remove invalid tokens
        if (
          error?.code === 'messaging/invalid-registration-token' ||
          error?.code === 'messaging/registration-token-not-registered'
        ) {
          await removeInvalidDevice(userId, deviceId);
        }
      }
    }

    // Update audit status
    if (auditId) {
      if (failureCount === 0) {
        await updateAuditStatus(auditId, AuditStatus.SENT);
      } else if (successCount === 0) {
        await updateAuditStatus(auditId, AuditStatus.FAILED, `All ${failureCount} devices failed`);
      } else {
        await updateAuditStatus(
          auditId,
          AuditStatus.SENT,
          `Partial delivery: ${successCount} sent, ${failureCount} failed`
        );
      }
    }

    logger.info(`Push notification sent to user ${userId}: ${successCount} success, ${failureCount} failed`);

    return {
      success: successCount > 0,
      messageIds,
      failureCount,
    };
  } catch (error) {
    logger.error(`Failed to send push notification: ${error}`);
    return { success: false, error: String(error) };
  }
};

/**
 * Callable function: Send push notification on demand (admin only)
 */
export const sendPushNotificationCallable = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const userId = context.auth.uid;

  // Check admin role
  const userDoc = await db.collection('users').doc(userId).get();
  const auraRole = userDoc.data()?.auraRole;
  if (auraRole !== 'admin') {
    throw new functions.https.HttpsError('permission-denied', 'Admin role required');
  }

  const result = await sendPushNotification(data as PushNotificationPayload);
  if (!result.success) {
    throw new functions.https.HttpsError('internal', result.error || 'Failed to send notification');
  }

  return result;
});

/**
 * Trigger: Send push notification on critical anomaly
 */
export const pushAnomalyAlert = functions.firestore
  .document('anomalies/{anomalyId}')
  .onCreate(async (snap) => {
    try {
      const anomaly = snap.data();
      
      // Only alert on critical/high
      if (!['critical', 'high'].includes(anomaly.severity)) {
        return;
      }

      await sendPushNotification({
        userId: anomaly.userId,
        title: `🚨 ${anomaly.entityType.toUpperCase()} Anomaly`,
        body: `${anomaly.description}`,
        notificationType: 'anomaly',
        severity: anomaly.severity,
        actionUrl: `${process.env.APP_URL}/anomalies/${snap.id}`,
        data: {
          anomalyId: snap.id,
          entityType: anomaly.entityType,
          score: anomaly.score.toString(),
        },
      });

      logger.info(`Push notification sent for anomaly ${snap.id}`);
    } catch (error) {
      logger.error(`Failed to send anomaly notification: ${error}`);
    }
  });

/**
 * Trigger: Send push on high-risk risk score update
 */
export const pushRiskAlert = functions.firestore
  .document('analytics/anomaly_summary/latest')
  .onUpdate(async (change) => {
    try {
      const oldData = change.before.data() || {};
      const newData = change.after.data() || {};

      const oldRisk = oldData.businessRiskScore || 0;
      const newRisk = newData.businessRiskScore || 0;

      // Alert if risk jumped significantly or exceeded threshold
      if (newRisk > 70 && oldRisk <= 70) {
        // Risk just exceeded critical threshold
        const users = await db.collection('users').where('auraRole', 'in', ['admin', 'analyst']).get();

        for (const userDoc of users.docs) {
          await sendPushNotification({
            userId: userDoc.id,
            title: '🔴 Critical Risk Alert',
            body: `Business risk score is now ${Math.round(newRisk)}%`,
            notificationType: 'anomaly',
            severity: 'critical',
            actionUrl: `${process.env.APP_URL}/anomalies/dashboard`,
            data: {
              riskScore: newRisk.toString(),
              threshold: '70',
            },
          });
        }
      }

      logger.info(`Risk alert triggered: ${oldRisk} → ${newRisk}`);
    } catch (error) {
      logger.error(`Failed to send risk alert: ${error}`);
    }
  });

/**
 * Helper: Remove invalid device
 */
async function removeInvalidDevice(userId: string, deviceId: string): Promise<void> {
  try {
    await db.collection('users').doc(userId).collection('devices').doc(deviceId).delete();
    logger.info(`Removed invalid device ${deviceId} for user ${userId}`);
  } catch (error) {
    logger.warn(`Failed to remove device: ${error}`);
  }
}

/**
 * Helper: Log notification to Firestore for tracking
 */
async function logNotification(userId: string, data: any): Promise<void> {
  try {
    await db
      .collection('users')
      .doc(userId)
      .collection('notifications')
      .add(data);
  } catch (error) {
    logger.warn(`Failed to log notification: ${error}`);
  }
}

/**
 * Cleanup: Remove FCM token when user logs out
 */
export const removeFCMToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const userId = context.auth.uid;
  const { deviceId } = data;

  if (!deviceId) {
    throw new functions.https.HttpsError('invalid-argument', 'Device ID required');
  }

  try {
    await removeInvalidDevice(userId, deviceId);
    return { success: true };
  } catch (error) {
    logger.error(`Failed to remove device: ${error}`);
    throw new functions.https.HttpsError('internal', 'Failed to remove device');
  }
});

/**
 * Callable: Register device with FCM token
 */
export const registerDevice = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const userId = context.auth.uid;
  const { deviceId, token, platform } = data;

  if (!deviceId || !token || !platform) {
    throw new functions.https.HttpsError('invalid-argument', 'Device ID, token, and platform required');
  }

  try {
    const validPlatforms = ['android', 'ios', 'web'];
    if (!validPlatforms.includes(platform)) {
      throw new Error('Invalid platform');
    }

    await db.collection('users').doc(userId).collection('devices').doc(deviceId).set({
      token,
      platform,
      lastSeen: admin.firestore.FieldValue.serverTimestamp(),
      prefs: {
        anomalies: true,
        invoices: true,
        inventory: true,
        all: true,
      },
    }, { merge: true });

    logger.info(`Device registered: ${deviceId} (${platform}) for user ${userId}`);
    return { success: true };
  } catch (error) {
    logger.error(`Failed to register device: ${error}`);
    throw new functions.https.HttpsError('internal', 'Failed to register device');
  }
});
