import { Resend } from 'resend';
import * as logger from 'firebase-functions/logger';

const resend = new Resend(process.env.RESEND_API_KEY);

interface EmailOptions {
  to: string | string[];
  subject: string;
  html: string;
  replyTo?: string;
}

/**
 * Send transactional email via Resend
 */
export async function sendEmail(options: EmailOptions): Promise<{ id: string }> {
  try {
    const result = await resend.emails.send({
      from: 'Aurasphere <hello@aura-sphere.app>',
      to: options.to,
      subject: options.subject,
      html: options.html,
      replyTo: options.replyTo,
    });

    if (result.error) {
      logger.error('Resend email error:', result.error);
      throw new Error(`Failed to send email: ${result.error.message}`);
    }

    logger.info('Email sent successfully:', { id: result.data?.id });
    return { id: result.data?.id || '' };
  } catch (error: any) {
    logger.error('Resend service error:', error);
    throw error;
  }
}

/**
 * Send contact form submission email
 */
export async function sendContactFormEmail(
  userEmail: string,
  name: string,
  message: string
): Promise<{ id: string }> {
  const html = `
    <div style="font-family: Arial, sans-serif; color: #333;">
      <h2>New Contact Form Submission</h2>
      <p><strong>From:</strong> ${name} (${userEmail})</p>
      <p><strong>Message:</strong></p>
      <p>${message.replace(/\n/g, '<br>')}</p>
      <hr style="border: none; border-top: 1px solid #ddd; margin: 2rem 0;" />
      <p style="color: #777; font-size: 0.9rem;">
        Sent via Aurasphere — <a href="https://aura-sphere.app">aura-sphere.app</a>
      </p>
    </div>
  `;

  return sendEmail({
    to: 'hello@aura-sphere.app',
    subject: `New Contact: ${name}`,
    html,
    replyTo: userEmail,
  });
}

/**
 * Send CRM export confirmation email
 */
export async function sendCrmExportEmail(
  userEmail: string,
  fileName: string,
  downloadUrl: string
): Promise<{ id: string }> {
  const html = `
    <div style="font-family: Arial, sans-serif; color: #333;">
      <h2>Your CRM Export is Ready</h2>
      <p>Hi,</p>
      <p>Your CRM data has been successfully exported as <strong>${fileName}</strong></p>
      <p style="margin: 2rem 0;">
        <a href="${downloadUrl}" style="
          display: inline-block;
          background: #00e0ff;
          color: #000;
          padding: 12px 24px;
          text-decoration: none;
          border-radius: 6px;
          font-weight: bold;
        ">Download Export</a>
      </p>
      <p style="color: #777; font-size: 0.9rem;">
        This link will expire in 7 days. If you have any questions, reply to this email.
      </p>
      <hr style="border: none; border-top: 1px solid #ddd; margin: 2rem 0;" />
      <p style="color: #777; font-size: 0.9rem;">
        Sent by AuraSphere — <a href="https://aura-sphere.app">aura-sphere.app</a>
      </p>
    </div>
  `;

  return sendEmail({
    to: userEmail,
    subject: 'Your CRM Export is Ready',
    html,
  });
}

/**
 * Send payment receipt email
 */
export async function sendPaymentReceiptEmail(
  userEmail: string,
  amount: number,
  currency: string,
  invoiceNumber: string,
  invoiceUrl?: string
): Promise<{ id: string }> {
  const html = `
    <div style="font-family: Arial, sans-serif; color: #333;">
      <h2>Payment Receipt</h2>
      <p>Hi,</p>
      <p>Thank you for your payment. Here's your receipt:</p>
      <div style="background: #f5f5f5; padding: 1.5rem; border-radius: 6px; margin: 2rem 0;">
        <p><strong>Amount:</strong> ${currency} ${(amount / 100).toFixed(2)}</p>
        <p><strong>Invoice:</strong> ${invoiceNumber}</p>
      </div>
      ${invoiceUrl ? `<p><a href="${invoiceUrl}">View Full Invoice</a></p>` : ''}
      <p style="color: #777; font-size: 0.9rem;">
        If you have any questions, contact us at hello@aura-sphere.app
      </p>
      <hr style="border: none; border-top: 1px solid #ddd; margin: 2rem 0;" />
      <p style="color: #777; font-size: 0.9rem;">
        Sent by AuraSphere — <a href="https://aura-sphere.app">aura-sphere.app</a>
      </p>
    </div>
  `;

  return sendEmail({
    to: userEmail,
    subject: `Payment Receipt #${invoiceNumber}`,
    html,
  });
}

/**
 * Send verification email
 */
export async function sendVerificationEmail(
  userEmail: string,
  verificationLink: string
): Promise<{ id: string }> {
  const html = `
    <div style="font-family: Arial, sans-serif; color: #333;">
      <h2>Verify Your Email</h2>
      <p>Hi,</p>
      <p>Please verify your email address to complete your Aurasphere account setup:</p>
      <p style="margin: 2rem 0;">
        <a href="${verificationLink}" style="
          display: inline-block;
          background: #00e0ff;
          color: #000;
          padding: 12px 24px;
          text-decoration: none;
          border-radius: 6px;
          font-weight: bold;
        ">Verify Email</a>
      </p>
      <p style="color: #777; font-size: 0.9rem;">
        This link will expire in 24 hours.
      </p>
      <hr style="border: none; border-top: 1px solid #ddd; margin: 2rem 0;" />
      <p style="color: #777; font-size: 0.9rem;">
        Sent by AuraSphere — <a href="https://aura-sphere.app">aura-sphere.app</a>
      </p>
    </div>
  `;

  return sendEmail({
    to: userEmail,
    subject: 'Verify Your Email Address',
    html,
  });
}
