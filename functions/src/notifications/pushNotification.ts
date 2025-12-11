import * as functions from 'firebase-functions';
import admin from 'firebase-admin';

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
 * Retrieves FCM tokens and sends via Firebase Cloud Messaging
 */
export const sendPushNotification = async (
  payload: PushNotificationPayload
): Promise<SendResult> => {
  try {
    const { userId, title, body, notificationType, severity, actionUrl, data } = payload;

    // Get user's FCM tokens
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return { success: false, error: 'User not found' };
    }

    const fcmTokens = userDoc.data()?.fcmTokens || [];
    if (fcmTokens.length === 0) {
      logger.warn(`No FCM tokens for user ${userId}`);
      return { success: false, error: 'No FCM tokens registered' };
    }

    // Check notification preferences
    const prefsDoc = await db
      .collection('users')
      .doc(userId)
      .collection('preferences')
      .doc('notifications')
      .get();
    const prefs = prefsDoc.data() || {};

    // Check if this notification type is enabled
    if (prefs.disabledNotifications?.includes(notificationType)) {
      logger.info(`Notification type ${notificationType} disabled for user ${userId}`);
      return { success: false, error: 'Notification type disabled by user' };
    }

    // Check quiet hours
    const now = new Date().getHours();
    if (prefs.quietHoursEnabled && prefs.quietHoursStart && prefs.quietHoursEnd) {
      const start = parseInt(prefs.quietHoursStart);
      const end = parseInt(prefs.quietHoursEnd);
      
      // If end < start, quiet hours span midnight
      const inQuietHours = end > start 
        ? (now >= start && now < end)
        : (now >= start || now < end);

      // Only skip non-critical notifications during quiet hours
      if (inQuietHours && severity !== 'critical') {
        logger.info(`Quiet hours active for user ${userId}, skipping ${notificationType}`);
        return { success: false, error: 'Quiet hours active' };
      }
    }

    // Build notification message
    const message = {
      notification: {
        title,
        body,
        ...(severity && { customData: JSON.stringify({ severity }) }),
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
      android: {
        priority: severity === 'critical' ? 'high' : 'normal',
        notification: {
          title,
          body,
          clickAction: actionUrl || process.env.APP_URL,
          channelId: `${notificationType}-${severity || 'normal'}`,
        },
      },
      data: {
        notificationType,
        severity: severity || 'low',
        ...(actionUrl && { actionUrl }),
        ...data,
      },
    };

    // Send to all user tokens
    const results = await Promise.allSettled(
      fcmTokens.map((token: string) =>
        messaging.send({
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
        })
      )
    );

    // Count successes/failures
    let successCount = 0;
    let failureCount = 0;
    const messageIds: string[] = [];

    for (let i = 0; i < results.length; i++) {
      if (results[i].status === 'fulfilled') {
        successCount++;
        const result = results[i] as PromiseFulfilledResult<string>;
        messageIds.push(result.value);
      } else {
        failureCount++;
        const error = results[i] as PromiseRejectedResult;
        
        // Remove invalid tokens
        if (
          error.reason?.code === 'messaging/invalid-registration-token' ||
          error.reason?.code === 'messaging/registration-token-not-registered'
        ) {
          await removeInvalidToken(userId, fcmTokens[i] as string);
        }
      }
    }

    // Log notification
    await logNotification(userId, {
      title,
      body,
      notificationType,
      severity: severity || 'low',
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'sent',
      successCount,
      failureCount,
    });

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
 * Helper: Remove invalid FCM token
 */
async function removeInvalidToken(userId: string, token: string): Promise<void> {
  try {
    await db.collection('users').doc(userId).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove([token]),
    });
    logger.info(`Removed invalid token for user ${userId}`);
  } catch (error) {
    logger.warn(`Failed to remove token: ${error}`);
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
      .collection('pushNotifications')
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
  const { token } = data;

  if (!token) {
    throw new functions.https.HttpsError('invalid-argument', 'Token required');
  }

  try {
    await db.collection('users').doc(userId).update({
      fcmTokens: admin.firestore.FieldValue.arrayRemove([token]),
    });
    return { success: true };
  } catch (error) {
    logger.error(`Failed to remove FCM token: ${error}`);
    throw new functions.https.HttpsError('internal', 'Failed to remove token');
  }
});

/**
 * Callable: Register FCM token
 */
export const registerFCMToken = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const userId = context.auth.uid;
  const { token } = data;

  if (!token) {
    throw new functions.https.HttpsError('invalid-argument', 'Token required');
  }

  try {
    // Add token if not already registered
    const userDoc = await db.collection('users').doc(userId).get();
    const existingTokens = userDoc.data()?.fcmTokens || [];

    if (!existingTokens.includes(token)) {
      await db.collection('users').doc(userId).update({
        fcmTokens: admin.firestore.FieldValue.arrayUnion([token]),
      });
    }

    logger.info(`Registered FCM token for user ${userId}`);
    return { success: true };
  } catch (error) {
    logger.error(`Failed to register FCM token: ${error}`);
    throw new functions.https.HttpsError('internal', 'Failed to register token');
  }
});
