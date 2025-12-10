/**
 * alerts.ts
 *
 * Slack notification system for critical events
 *
 * Sends alerts for:
 * - Admin role changes (grant/revoke)
 * - High-value transactions
 * - Audit system errors
 * - Critical security events
 *
 * Usage:
 * ```typescript
 * await sendAlert('Admin Role Change', 'User granted admin access', { uid, grantedBy });
 * await sendHighValueAlert('Invoice', 'invoice-001', 5000, 'USD');
 * await sendErrorAlert('Audit Archival Failed', error);
 * ```
 *
 * Configuration: SLACK_WEBHOOK_URL environment variable
 * Gracefully degrades if webhook not configured (logs warning)
 */

import axios, { AxiosError } from 'axios';

/**
 * Slack webhook URL from environment
 * Set via: SLACK_WEBHOOK_URL=https://hooks.slack.com/services/...
 */
const SLACK_WEBHOOK_URL = process.env.SLACK_WEBHOOK_URL || '';

/**
 * Alert severity levels
 */
export enum AlertSeverity {
  INFO = 'info',
  WARNING = 'warning',
  ERROR = 'error',
  CRITICAL = 'critical',
}

/**
 * Slack message colors by severity
 */
const SEVERITY_COLORS: Record<AlertSeverity, string> = {
  [AlertSeverity.INFO]: '#36a64f',
  [AlertSeverity.WARNING]: '#ff9900',
  [AlertSeverity.ERROR]: '#ff0000',
  [AlertSeverity.CRITICAL]: '#cc0000',
};

/**
 * Format extra data for Slack message
 */
function formatExtra(extra: any): string {
  if (!extra || Object.keys(extra).length === 0) {
    return '';
  }

  try {
    const formatted = JSON.stringify(extra, null, 2);
    // Limit to 500 chars to avoid cluttering Slack
    return formatted.length > 500
      ? formatted.substring(0, 500) + '...'
      : formatted;
  } catch (e) {
    return String(extra);
  }
}

/**
 * Build Slack message block
 */
interface SlackBlock {
  type: string;
  [key: string]: any;
}

function buildMessageBlocks(
  title: string,
  message: string,
  severity: AlertSeverity,
  extra?: any,
): SlackBlock[] {
  const blocks: SlackBlock[] = [
    {
      type: 'header',
      text: {
        type: 'plain_text',
        text: title,
        emoji: true,
      },
    },
    {
      type: 'section',
      text: {
        type: 'mrkdwn',
        text: message,
      },
    },
  ];

  if (extra) {
    const extraText = formatExtra(extra);
    if (extraText) {
      blocks.push({
        type: 'section',
        text: {
          type: 'mrkdwn',
          text: `\`\`\`${extraText}\`\`\``,
        },
      });
    }
  }

  blocks.push({
    type: 'context',
    elements: [
      {
        type: 'mrkdwn',
        text: `_${new Date().toISOString()}_`,
      },
    ],
  });

  return blocks;
}

/**
 * Send alert to Slack
 *
 * @param title Alert title
 * @param message Alert message (supports Slack markdown)
 * @param extra Optional additional data to include
 * @param severity Alert severity level
 *
 * Gracefully fails if:
 * - Webhook not configured (logs warning)
 * - Network error (logs error, doesn't throw)
 */
export async function sendAlert(
  title: string,
  message: string,
  extra?: any,
  severity: AlertSeverity = AlertSeverity.WARNING,
): Promise<void> {
  // Skip if webhook not configured
  if (!SLACK_WEBHOOK_URL) {
    console.warn(`[alerts] Slack webhook not configured; alert skipped: ${title}`);
    return;
  }

  try {
    const blocks = buildMessageBlocks(title, message, severity, extra);
    const color = SEVERITY_COLORS[severity];

    const payload = {
      blocks,
      attachments: [
        {
          color,
          footer: 'AuraSphere Pro Alerts',
        },
      ],
    };

    await axios.post(SLACK_WEBHOOK_URL, payload, {
      timeout: 5000,
    });

    console.log(`[alerts] Sent: ${title}`);
  } catch (err) {
    const error = err as AxiosError;
    console.error('[alerts-error] Failed to send alert:', {
      title,
      status: error.response?.status,
      message: error.message,
    });
    // Don't throw — alert failure shouldn't crash the operation
  }
}

/**
 * Send admin role change alert
 *
 * @param action 'granted' or 'revoked'
 * @param targetUid User who gained/lost admin
 * @param actorUid User who made the change
 * @param actorName Name of user who made the change
 */
export async function sendAdminChangeAlert(
  action: 'granted' | 'revoked',
  targetUid: string,
  actorUid: string,
  actorName?: string,
): Promise<void> {
  const title = `Admin Role ${action === 'granted' ? '✅ Granted' : '❌ Revoked'}`;
  const message = `Admin access ${action} for user \`${targetUid}\` by ${actorName || actorUid}`;

  await sendAlert(title, message, { targetUid, actorUid, actorName }, AlertSeverity.WARNING);
}

/**
 * Send high-value transaction alert
 *
 * @param entityType Type of entity (invoice, payment, refund)
 * @param entityId ID of entity
 * @param amount Transaction amount
 * @param currency Currency code
 * @param extra Additional context
 */
export async function sendHighValueAlert(
  entityType: string,
  entityId: string,
  amount: number,
  currency: string,
  extra?: any,
): Promise<void> {
  const title = `💰 High-Value ${entityType.toUpperCase()}`;
  const message = `*${amount.toFixed(2)} ${currency}* for \`${entityId}\``;

  await sendAlert(title, message, extra, AlertSeverity.WARNING);
}

/**
 * Send error alert for critical failures
 *
 * @param title Error title
 * @param error Error object or message
 * @param context Additional context
 */
export async function sendErrorAlert(
  title: string,
  error: Error | string,
  context?: any,
): Promise<void> {
  const message =
    error instanceof Error ? error.message : String(error);
  const extra = {
    ...context,
    stack: error instanceof Error ? error.stack?.split('\n').slice(0, 5) : undefined,
  };

  await sendAlert(`🚨 ${title}`, `\`\`\`${message}\`\`\``, extra, AlertSeverity.ERROR);
}

/**
 * Send security alert for suspicious activity
 *
 * @param title Alert title
 * @param description Description of suspicious activity
 * @param context User/IP/timestamp context
 */
export async function sendSecurityAlert(
  title: string,
  description: string,
  context?: any,
): Promise<void> {
  await sendAlert(`🔒 ${title}`, description, context, AlertSeverity.CRITICAL);
}

/**
 * Send audit system status alert
 *
 * @param status 'success' or 'failure'
 * @param operation Operation name (archive, export, encrypt)
 * @param details Operation details
 */
export async function sendAuditStatusAlert(
  status: 'success' | 'failure',
  operation: string,
  details?: any,
): Promise<void> {
  const icon = status === 'success' ? '✅' : '❌';
  const title = `${icon} Audit ${operation}`;
  const severity =
    status === 'success' ? AlertSeverity.INFO : AlertSeverity.ERROR;

  await sendAlert(title, `Audit ${operation} ${status}`, details, severity);
}

/**
 * Batch send multiple alerts (useful for batch operations)
 *
 * @param alerts Array of alert data
 * @returns Promise that resolves when all alerts sent
 */
export async function sendAlertBatch(
  alerts: Array<{
    title: string;
    message: string;
    extra?: any;
    severity?: AlertSeverity;
  }>,
): Promise<void> {
  await Promise.all(
    alerts.map((alert) =>
      sendAlert(alert.title, alert.message, alert.extra, alert.severity),
    ),
  );
}

/**
 * Test alert function (for verification)
 *
 * Usage: Call this to verify webhook is working
 * ```typescript
 * await sendTestAlert();
 * ```
 */
export async function sendTestAlert(): Promise<void> {
  await sendAlert(
    '🧪 Test Alert',
    'This is a test alert from AuraSphere Pro',
    {
      timestamp: new Date().toISOString(),
      environment: process.env.NODE_ENV,
    },
    AlertSeverity.INFO,
  );
}
