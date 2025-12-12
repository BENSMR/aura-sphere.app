import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { recordResendWebhookEvent } from './sendDigestEmail';

const logger = functions.logger;

/**
 * HTTP endpoint to receive Resend webhook events
 * Set this URL in Resend dashboard: https://your-project.cloudfunctions.net/resendWebhook
 *
 * Webhook configuration:
 * - Endpoint: https://your-project.cloudfunctions.net/resendWebhook
 * - Events: email.delivered, email.bounced, email.complained
 * - Signing secret: Store in Firebase config
 */
export const resendWebhook = functions.https.onRequest(async (req, res) => {
  try {
    // Verify webhook signature (optional but recommended)
    const signature = req.header('x-resend-signature');
    const secret = process.env.RESEND_WEBHOOK_SECRET || functions.config()?.resend?.webhook_secret;

    if (secret && signature) {
      const isValid = verifyResendSignature(req.body, signature, secret);
      if (!isValid) {
        logger.warn('[resendWebhook] Invalid signature');
        res.status(401).json({ error: 'Invalid signature' });
        return;
      }
    }

    const event = req.body;

    if (!event.type || !event.data) {
      logger.warn('[resendWebhook] Invalid event structure');
      res.status(400).json({ error: 'Invalid event' });
      return;
    }

    // Handle webhook event
    if (event.type === 'email.delivered') {
      await recordResendWebhookEvent(event);
    } else if (event.type === 'email.bounced') {
      await recordResendWebhookEvent(event);
    } else if (event.type === 'email.complained') {
      await recordResendWebhookEvent(event);
    } else {
      logger.info(`[resendWebhook] Unhandled event type: ${event.type}`);
    }

    // Acknowledge receipt
    res.status(200).json({ received: true });
  } catch (error) {
    logger.error('[resendWebhook] Error processing webhook:', error);
    res.status(500).json({ error: 'Internal server error' });
  }
});

/**
 * Verify Resend webhook signature
 * Resend signs webhooks with HMAC-SHA256
 */
function verifyResendSignature(body: any, signature: string, secret: string): boolean {
  try {
    const crypto = require('crypto');
    const bodyStr = typeof body === 'string' ? body : JSON.stringify(body);
    const hash = crypto
      .createHmac('sha256', secret)
      .update(bodyStr)
      .digest('base64');

    return hash === signature;
  } catch (error) {
    logger.error('[verifyResendSignature] Error:', error);
    return false;
  }
}
