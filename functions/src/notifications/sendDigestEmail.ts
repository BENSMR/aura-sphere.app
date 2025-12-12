import * as admin from 'firebase-admin';
import * as functions from 'firebase-functions';
import { DigestSummary } from './buildDigest';

const db = admin.firestore();
const logger = functions.logger;

// Initialize Resend (requires Firebase config: firebase functions:config:set resend.api_key="...")
let resendClient: any = null;
try {
  const Resend = require('resend').Resend;
  const apiKey = process.env.RESEND_API_KEY || functions.config()?.resend?.api_key;
  if (apiKey) {
    resendClient = new Resend(apiKey);
  }
} catch (error) {
  logger.warn('[sendDigestEmail] Resend not configured or unavailable:', error);
}

/**
 * Send digest email via Resend
 */
export async function sendDigestEmail(
  uid: string,
  htmlContent: string,
  subject: string
): Promise<{ success: boolean; messageId?: string; error?: string }> {
  try {
    // Get user's email
    const userDoc = await db.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      logger.warn(`[sendDigestEmail] User ${uid} not found`);
      return { success: false, error: 'user_not_found' };
    }

    const userData = userDoc.data();
    const email = userData?.email;
    const displayName = userData?.firstName ? `${userData.firstName} ${userData.lastName || ''}`.trim() : 'there';

    if (!email) {
      logger.warn(`[sendDigestEmail] No email for user ${uid}`);
      return { success: false, error: 'no_email' };
    }

    // If Resend is not configured, just log and queue
    if (!resendClient) {
      logger.info(`[sendDigestEmail] Resend not configured, queuing email for ${uid}`);
      return queueEmailToFirestore(uid, email, subject);
    }

    // Send via Resend
    const response = await resendClient.emails.send({
      from: 'AuraSphere <digest@aurasphere.app>',
      to: email,
      subject: subject,
      html: htmlContent,
      replyTo: 'support@aurasphere.app',
    });

    if (response.error) {
      logger.error(`[sendDigestEmail] Resend error for ${uid}:`, response.error);
      // Fallback to Firestore queue
      return queueEmailToFirestore(uid, email, subject);
    }

    // Log successful send
    const emailRecordRef = await db
      .collection('users')
      .doc(uid)
      .collection('sentEmails')
      .add({
        type: 'digest',
        to: email,
        subject,
        resendMessageId: response.id,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'sent',
      });

    logger.info(`[sendDigestEmail] Email sent via Resend for ${uid} (${email}), ID: ${response.id}`);

    return {
      success: true,
      messageId: response.id,
    };
  } catch (error) {
    logger.error(`[sendDigestEmail] Error sending digest for ${uid}:`, error);
    return {
      success: false,
      error: String(error),
    };
  }
}

/**
 * Queue email to Firestore if Resend is unavailable
 */
async function queueEmailToFirestore(
  uid: string,
  email: string,
  subject: string
): Promise<{ success: boolean; messageId?: string; error?: string }> {
  try {
    const emailRecordRef = await db
      .collection('users')
      .doc(uid)
      .collection('sentEmails')
      .add({
        type: 'digest',
        to: email,
        subject,
        sentAt: admin.firestore.FieldValue.serverTimestamp(),
        status: 'queued',
      });

    logger.info(`[sendDigestEmail] Queued email to Firestore for ${uid}`);

    return {
      success: true,
      messageId: emailRecordRef.id,
    };
  } catch (error) {
    logger.error(`[sendDigestEmail] Error queueing email:`, error);
    return {
      success: false,
      error: String(error),
    };
  }
}

/**
 * Send bulk digest emails to multiple users
 * Used by scheduled Cloud Function
 */
export async function sendDigestEmailBatch(
  emails: Array<{
    uid: string;
    to: string;
    subject: string;
    htmlContent: string;
  }>
): Promise<{
  sent: number;
  failed: number;
  errors: Array<{ uid: string; error: string }>;
}> {
  const results = {
    sent: 0,
    failed: 0,
    errors: [] as Array<{ uid: string; error: string }>,
  };

  for (const email of emails) {
    try {
      const result = await sendDigestEmail(email.uid, email.htmlContent, email.subject);
      if (result.success) {
        results.sent++;
      } else {
        results.failed++;
        results.errors.push({
          uid: email.uid,
          error: result.error || 'unknown_error',
        });
      }
    } catch (error) {
      results.failed++;
      results.errors.push({
        uid: email.uid,
        error: String(error),
      });
    }
  }

  logger.info('[sendDigestEmailBatch] Results:', results);
  return results;
}

/**
 * Mark digest email as sent
 */
export async function markDigestEmailSent(
  uid: string,
  emailRecordId: string
): Promise<void> {
  try {
    await db
      .collection('users')
      .doc(uid)
      .collection('sentEmails')
      .doc(emailRecordId)
      .update({
        status: 'sent',
        deliveredAt: admin.firestore.FieldValue.serverTimestamp(),
      });
  } catch (error) {
    logger.error(`[markDigestEmailSent] Error for ${uid}:`, error);
  }
}

/**
 * Record email event from Resend webhook
 * Resend events: 'delivered' | 'bounced' | 'complained'
 */
export async function recordResendWebhookEvent(
  event: {
    type: 'email.delivered' | 'email.bounced' | 'email.complained';
    data: {
      email: string;
      messageId?: string;
      timestamp?: string;
      reason?: string;
    };
  }
): Promise<void> {
  try {
    const email = event.data.email;
    const eventType = event.type;

    // Find user by email
    const userQuery = await db.collection('users').where('email', '==', email).limit(1).get();
    if (userQuery.empty) {
      logger.warn(`[recordResendWebhookEvent] No user found for email ${email}`);
      return;
    }

    const uid = userQuery.docs[0].id;
    let eventName: 'bounce' | 'complaint' | 'delivery' = 'delivery';

    if (eventType === 'email.bounced') {
      eventName = 'bounce';
    } else if (eventType === 'email.complained') {
      eventName = 'complaint';
    }

    // Record event
    await db
      .collection('users')
      .doc(uid)
      .collection('emailEvents')
      .add({
        event: eventName,
        resendEventType: eventType,
        messageId: event.data.messageId,
        reason: event.data.reason,
        recordedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    logger.info(`[recordResendWebhookEvent] ${eventType} for user ${uid} (${email})`);

    // If bounce or complaint, disable digests
    if (eventName === 'bounce' || eventName === 'complaint') {
      logger.warn(`[recordResendWebhookEvent] Disabling digests for ${uid} due to ${eventName}`);
      await db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('digest')
        .update({
          digestEnabled: false,
          disabledReason: eventName,
          disabledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
  } catch (error) {
    logger.error(`[recordResendWebhookEvent] Error:`, error);
  }
}

/**
 * Record email bounce/complaint (legacy function for other email services)
 */
export async function recordEmailEvent(
  uid: string,
  event: 'bounce' | 'complaint' | 'delivery' | 'open' | 'click',
  metadata?: any
): Promise<void> {
  try {
    await db
      .collection('users')
      .doc(uid)
      .collection('emailEvents')
      .add({
        event,
        metadata,
        recordedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

    // If bounce or complaint, disable digests
    if (event === 'bounce' || event === 'complaint') {
      logger.warn(`[recordEmailEvent] ${event} for user ${uid}, disabling digests`);
      await db
        .collection('users')
        .doc(uid)
        .collection('settings')
        .doc('digest')
        .update({
          digestEnabled: false,
          disabledReason: event,
          disabledAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }
  } catch (error) {
    logger.error(`[recordEmailEvent] Error for ${uid}:`, error);
  }
}
