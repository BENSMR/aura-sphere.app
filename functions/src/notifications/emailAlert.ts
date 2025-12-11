import * as functions from 'firebase-functions';
import * as nodemailer from 'nodemailer';
import admin from 'firebase-admin';

const db = admin.firestore();
const logger = functions.logger;

// Configure email transporter (using SendGrid)
const transporter = nodemailer.createTransport({
  service: 'sendgrid',
  auth: {
    user: 'apikey',
    pass: process.env.SENDGRID_API_KEY || '',
  },
});

interface AlertPayload {
  userId: string;
  recipientEmail: string;
  alertType: 'anomaly' | 'invoice' | 'expense' | 'payment';
  severity: 'critical' | 'high' | 'medium' | 'low';
  subject: string;
  title: string;
  description: string;
  actionUrl?: string;
  metadata?: Record<string, any>;
}

interface EmailResult {
  success: boolean;
  messageId?: string;
  error?: string;
}

/**
 * Send email alert to user
 * Triggered by: Cloud Functions, Pub/Sub, or direct callable
 * Usage: Call from anomaly scanner, invoice reminders, etc.
 */
export const sendEmailAlert = async (
  payload: AlertPayload
): Promise<EmailResult> => {
  try {
    const { userId, recipientEmail, alertType, severity, subject, title, description, actionUrl, metadata } = payload;

    // Verify user exists and email is confirmed
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      return { success: false, error: 'User not found' };
    }

    const userData = userDoc.data();
    if (!userData?.emailVerified) {
      logger.warn(`Email not verified for user ${userId}, skipping alert`);
      return { success: false, error: 'Email not verified' };
    }

    // Get user preferences (do not disturb, etc)
    const prefsDoc = await db.collection('users').doc(userId).collection('preferences').doc('notifications').get();
    const prefs = prefsDoc.data() || {};

    // Check if user has disabled this alert type
    if (prefs.disabledAlerts?.includes(alertType)) {
      logger.info(`Alert type ${alertType} disabled for user ${userId}`);
      return { success: false, error: 'Alert type disabled by user' };
    }

    // Build email HTML
    const html = buildEmailHTML({
      title,
      description,
      severity,
      alertType,
      actionUrl,
      userName: userData.displayName || 'User',
    });

    // Send email
    const info = await transporter.sendMail({
      from: process.env.SENDER_EMAIL || 'noreply@aurasphere.app',
      to: recipientEmail,
      subject: `[${severity.toUpperCase()}] ${subject}`,
      html,
      replyTo: 'support@aurasphere.app',
    });

    // Log email sent to Firestore
    await logEmailAlert(userId, {
      messageId: info.messageId,
      alertType,
      severity,
      subject,
      sentAt: admin.firestore.FieldValue.serverTimestamp(),
      status: 'sent',
    });

    logger.info(`Email alert sent to ${recipientEmail} | Message ID: ${info.messageId}`);
    return { success: true, messageId: info.messageId };
  } catch (error) {
    logger.error(`Failed to send email alert: ${error}`);
    return { success: false, error: String(error) };
  }
};

/**
 * Callable function: Send email alert on demand (admin only)
 */
export const sendEmailAlertCallable = functions.https.onCall(async (data, context) => {
  // Check authentication
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User not authenticated');
  }

  const userId = context.auth.uid;

  // Check admin role
  const userDoc = await db.collection('users').doc(userId).get();
  const auraRole = userDoc.data()?.auraRole;
  if (auraRole !== 'admin' && auraRole !== 'analyst') {
    throw new functions.https.HttpsError('permission-denied', 'Admin/Analyst role required');
  }

  const result = await sendEmailAlert(data as AlertPayload);
  if (!result.success) {
    throw new functions.https.HttpsError('internal', result.error || 'Failed to send email');
  }

  return result;
});

/**
 * Pub/Sub trigger: Send alert emails based on Firestore events
 * Subscription: Send email alerts (created by this function)
 */
export const emailAlertPubSubHandler = functions.pubsub
  .topic('send-email-alerts')
  .onPublish(async (message) => {
    try {
      const payload = JSON.parse(Buffer.from(message.data, 'base64').toString()) as AlertPayload;
      const result = await sendEmailAlert(payload);
      
      logger.info(`Email alert processed: ${result.success ? 'success' : 'failed'}`);
      return result;
    } catch (error) {
      logger.error(`Email alert Pub/Sub handler failed: ${error}`);
      throw error;
    }
  });

/**
 * Trigger: Send email on high-risk anomaly detected
 * Watches: /anomalies collection for critical/high anomalies
 */
export const emailAnomalyAlert = functions.firestore
  .document('anomalies/{anomalyId}')
  .onCreate(async (snap) => {
    try {
      const anomaly = snap.data();
      const userId = anomaly.userId;

      // Only alert on critical/high severity
      if (!['critical', 'high'].includes(anomaly.severity)) {
        return;
      }

      // Get user email
      const userDoc = await db.collection('users').doc(userId).get();
      const userEmail = userDoc.data()?.email;

      if (!userEmail) {
        logger.warn(`User ${userId} has no email on file`);
        return;
      }

      // Send alert
      await sendEmailAlert({
        userId,
        recipientEmail: userEmail,
        alertType: 'anomaly',
        severity: anomaly.severity,
        subject: `${anomaly.severity === 'critical' ? '🚨' : '⚠️'} ${anomaly.entityType} Anomaly Detected`,
        title: `${anomaly.entityType.charAt(0).toUpperCase() + anomaly.entityType.slice(1)} Anomaly`,
        description: `${anomaly.description}\n\nAmount: ${anomaly.amount}\nDate: ${anomaly.detectedAt}`,
        actionUrl: `${process.env.APP_URL}/anomalies`,
        metadata: {
          anomalyId: snap.id,
          score: anomaly.score,
          amount: anomaly.amount,
        },
      });

      logger.info(`Email alert sent for anomaly ${snap.id}`);
    } catch (error) {
      logger.error(`Failed to send anomaly email alert: ${error}`);
    }
  });

/**
 * Trigger: Send invoice reminder emails (24 hours before due date)
 * Watches: /invoices collection for upcoming due dates
 */
export const emailInvoiceReminder = functions.pubsub
  .schedule('every 24 hours')
  .onRun(async () => {
    try {
      const tomorrow = new Date();
      tomorrow.setDate(tomorrow.getDate() + 1);
      const endOfTomorrow = new Date(tomorrow);
      endOfTomorrow.setHours(23, 59, 59);

      // Query invoices due tomorrow
      const invoicesSnapshot = await db.collectionGroup('invoices')
        .where('dueDate', '>=', new Date(tomorrow.setHours(0, 0, 0)))
        .where('dueDate', '<=', endOfTomorrow)
        .where('status', '!=', 'paid')
        .get();

      let count = 0;
      for (const invoiceDoc of invoicesSnapshot.docs) {
        const invoice = invoiceDoc.data();
        const userId = invoice.userId;

        // Get user email
        const userDoc = await db.collection('users').doc(userId).get();
        const userEmail = userDoc.data()?.email;

        if (!userEmail) continue;

        // Send reminder
        await sendEmailAlert({
          userId,
          recipientEmail: userEmail,
          alertType: 'invoice',
          severity: 'medium',
          subject: `Invoice #${invoice.invoiceNumber} Due Tomorrow`,
          title: 'Invoice Payment Due Soon',
          description: `Invoice #${invoice.invoiceNumber} is due on ${invoice.dueDate}.\n\nAmount: ${invoice.currency} ${invoice.total}`,
          actionUrl: `${process.env.APP_URL}/invoices/${invoiceDoc.id}`,
          metadata: {
            invoiceId: invoiceDoc.id,
            invoiceNumber: invoice.invoiceNumber,
            amount: invoice.total,
          },
        });

        count++;
      }

      logger.info(`Sent ${count} invoice reminder emails`);
      return { success: true, emailsSent: count };
    } catch (error) {
      logger.error(`Failed to send invoice reminders: ${error}`);
      throw error;
    }
  });

/**
 * Helper: Build HTML email template
 */
function buildEmailHTML(params: {
  title: string;
  description: string;
  severity: string;
  alertType: string;
  actionUrl?: string;
  userName: string;
}): string {
  const severityColor = {
    critical: '#dc2626',
    high: '#ea580c',
    medium: '#eab308',
    low: '#16a34a',
  }[params.severity] || '#6366f1';

  return `
    <html>
      <head>
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', sans-serif; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #667eea 0%, #764ba2 100%); color: white; padding: 20px; border-radius: 8px 8px 0 0; }
          .content { background: #f9fafb; padding: 20px; }
          .severity { color: ${severityColor}; font-weight: bold; }
          .footer { color: #999; font-size: 12px; margin-top: 20px; }
          .button { background: #667eea; color: white; padding: 10px 20px; border-radius: 4px; text-decoration: none; display: inline-block; margin-top: 10px; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>🔔 AuraSphere Alert</h2>
            <p>Hi ${params.userName},</p>
          </div>
          <div class="content">
            <p><strong>${params.title}</strong></p>
            <p class="severity">Severity: ${params.severity.toUpperCase()}</p>
            <p>${params.description}</p>
            ${params.actionUrl ? `<a href="${params.actionUrl}" class="button">View Details →</a>` : ''}
          </div>
          <div class="footer">
            <p>You received this email because you're registered with AuraSphere Pro.</p>
            <p><a href="${process.env.APP_URL}/settings/notifications">Manage notification preferences</a></p>
          </div>
        </div>
      </body>
    </html>
  `;
}

/**
 * Helper: Log sent email to Firestore for tracking
 */
async function logEmailAlert(userId: string, alertData: any): Promise<void> {
  try {
    await db
      .collection('users')
      .doc(userId)
      .collection('emailAlerts')
      .add(alertData);
  } catch (error) {
    logger.warn(`Failed to log email alert: ${error}`);
  }
}
