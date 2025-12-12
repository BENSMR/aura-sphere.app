import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { convertToUserLocalTime, isWithinQuietHours } from '../timezone/userTimezone';

const db = admin.firestore();
const messaging = admin.messaging();
const logger = functions.logger;

interface BusinessNotificationPayload {
  uid: string;
  title: string;
  body: string;
  notificationType: 'invoice' | 'payment' | 'crm' | 'expense' | 'task' | 'system';
  severity?: 'critical' | 'high' | 'medium' | 'low';
  data?: Record<string, string>;
  actionUrl?: string;
}

/**
 * sendBusinessNotification
 * Sends a notification to a user, respecting their timezone and quiet hours.
 * Critical severity notifications bypass quiet hours.
 *
 * @param uid User ID
 * @param payload Notification details
 * @returns true if sent, false if skipped (quiet hours), or error
 */
export async function sendBusinessNotification(
  uid: string,
  payload: BusinessNotificationPayload
): Promise<{ sent: boolean; reason?: string }> {
  try {
    const { title, body, notificationType, severity, data, actionUrl } = payload;

    // Get current UTC time
    const nowUtc = new Date();

    // Convert to user's local time
    const userLocalTime = await convertToUserLocalTime(uid, nowUtc);

    // Check quiet hours (passes user's local Date)
    const quietHoursCheck = await isWithinQuietHours(uid, nowUtc);

    // Skip if within quiet hours (unless critical)
    if (quietHoursCheck.inside && severity !== 'critical') {
      logger.info(
        `[sendBusinessNotification] User ${uid} in quiet hours (${quietHoursCheck.startHour}-${quietHoursCheck.endHour}), ` +
        `current hour: ${quietHoursCheck.currentHour}, timezone: ${quietHoursCheck.zone}`
      );
      return { sent: false, reason: 'quiet_hours' };
    }

    // Get user's registered FCM tokens
    const devicesSnapshot = await db
      .collection('users')
      .doc(uid)
      .collection('devices')
      .get();

    if (devicesSnapshot.empty) {
      logger.warn(`[sendBusinessNotification] No devices for user ${uid}`);
      return { sent: false, reason: 'no_devices' };
    }

    // Collect FCM tokens
    const tokens: string[] = [];
    devicesSnapshot.docs.forEach((doc) => {
      const token = doc.data().fcmToken;
      if (token) tokens.push(token);
    });

    if (tokens.length === 0) {
      logger.warn(`[sendBusinessNotification] No FCM tokens for user ${uid}`);
      return { sent: false, reason: 'no_tokens' };
    }

    // Prepare notification
    const message = {
      notification: {
        title,
        body,
      },
      data: {
        ...data,
        notificationType,
        severity: severity || 'medium',
        userTimezone: userLocalTime.zoneName || 'UTC',
        userLocalTime: userLocalTime.toISO() || '',
        actionUrl: actionUrl || '',
      },
      tokens, // Send to all tokens
    };

    // Send via Firebase Cloud Messaging
    const response = await messaging.sendMulticast(message);

    logger.info(
      `[sendBusinessNotification] User ${uid} (${notificationType}): ` +
      `${response.successCount} sent, ${response.failureCount} failed`
    );

    // Log success
    await db
      .collection('users')
      .doc(uid)
      .collection('notificationLog')
      .add({
        title,
        body,
        type: notificationType,
        severity: severity || 'medium',
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        userLocalTime: userLocalTime.toISO(),
        zone: userLocalTime.zoneName,
        tokensCount: response.successCount,
        failureCount: response.failureCount,
      });

    return {
      sent: response.successCount > 0,
      reason: response.successCount > 0 ? undefined : 'send_failed',
    };
  } catch (error) {
    logger.error(`[sendBusinessNotification] Error for user ${uid}:`, error);
    return { sent: false, reason: 'error' };
  }
}
