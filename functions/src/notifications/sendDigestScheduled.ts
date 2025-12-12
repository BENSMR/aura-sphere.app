import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { shouldSendDigestNow, getDigestPreferences, getDigestScope } from './digestPreferences';
import { buildDigestForUser, formatDigestForEmail, getDigestCounts } from './buildDigest';
import { sendDigestEmail } from './sendDigestEmail';
import { convertFirestoreTimestampToUserLocal } from '../utils/timestampConverters';

const db = admin.firestore();
const messaging = admin.messaging();
const logger = functions.logger;

interface DigestItem {
  id: string;
  title: string;
  type: 'invoice' | 'expense' | 'task' | 'stock' | 'crm';
  timestamp: admin.firestore.Timestamp;
}

/**
 * Scheduled function: runs every hour to send digest notifications
 * Checks which users should receive a digest in their timezone
 */
export const sendHourlyDigests = functions.pubsub
  .schedule('0 * * * *') // Every hour at :00
  .timeZone('UTC')
  .onRun(async (context) => {
    logger.info('[sendHourlyDigests] Starting hourly digest check');

    try {
      const usersSnapshot = await db.collection('users').get();
      let digestCount = 0;
      let errorCount = 0;

      // Check each user
      for (const userDoc of usersSnapshot.docs) {
        const uid = userDoc.id;
        
        try {
          const shouldSend = await shouldSendDigestNow(uid);
          if (shouldSend) {
            await sendUserDigest(uid);
            digestCount++;
          }
        } catch (error) {
          logger.error(`[sendHourlyDigests] Error sending digest for user ${uid}:`, error);
          errorCount++;
        }
      }

      logger.info(
        `[sendHourlyDigests] Completed: ${digestCount} sent, ${errorCount} errors`
      );
    } catch (error) {
      logger.error('[sendHourlyDigests] Unexpected error:', error);
      throw error;
    }
  });

/**
 * Send a complete digest for a user
 */
async function sendUserDigest(uid: string): Promise<void> {
  try {
    const prefs = await getDigestPreferences(uid);
    if (!prefs || !prefs.digestEnabled) return;

    const scope = getDigestScope(prefs);
    if (scope.length === 0) return; // Nothing to include

    // Build digest content
    const summary = await buildDigestForUser(uid, prefs);
    const counts = getDigestCounts(summary);

    if (counts.total === 0) {
      logger.info(`[sendUserDigest] No items for user ${uid}, skipping digest`);
      return;
    }

    // Format email content
    const htmlContent = formatDigestForEmail(summary, prefs.digestFrequency);
    const subject = `Your ${prefs.digestFrequency.charAt(0).toUpperCase() + prefs.digestFrequency.slice(1)} Digest - ${counts.total} items`;

    // Send email
    const emailResult = await sendDigestEmail(uid, htmlContent, subject);
    if (!emailResult.success) {
      logger.warn(`[sendUserDigest] Failed to send email for user ${uid}: ${emailResult.error}`);
      return;
    }

    // Send push notification
    const devicesSnapshot = await db
      .collection('users')
      .doc(uid)
      .collection('devices')
      .get();

    const tokens: string[] = [];
    devicesSnapshot.docs.forEach((doc) => {
      const token = doc.data().fcmToken;
      if (token) tokens.push(token);
    });

    if (tokens.length > 0) {
      const message = {
        notification: {
          title: `Your ${prefs.digestFrequency} Digest`,
          body: `${counts.total} item${counts.total !== 1 ? 's' : ''} to review`,
        },
        data: {
          type: 'digest',
          frequency: prefs.digestFrequency,
          itemCount: String(counts.total),
          categories: scope.join(','),
        },
        tokens,
      };

      const pushResult = await messaging.sendMulticast(message);
      logger.info(
        `[sendUserDigest] Push notifications: ${pushResult.successCount}/${tokens.length} sent`
      );
    }

    // Log digest delivery
    await db
      .collection('users')
      .doc(uid)
      .collection('digestLog')
      .add({
        frequency: prefs.digestFrequency,
        itemCounts: counts.breakdown,
        totalItems: counts.total,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        emailSent: emailResult.success,
        pushTokens: tokens.length,
      });

    logger.info(
      `[sendUserDigest] Sent digest to user ${uid}: ${counts.total} items, ` +
      `email: ${emailResult.success}, push: ${tokens.length} tokens`
    );
  } catch (error) {
    logger.error(`[sendUserDigest] Error for user ${uid}:`, error);
    throw error;
  }
}
