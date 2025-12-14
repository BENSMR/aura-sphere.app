import * as functions from 'firebase-functions';
import * as logger from 'firebase-functions/logger';
import { sendVerificationEmail } from '../email/resendService';

/**
 * Send welcome email when a new user is created
 * Triggers on Firebase Auth user creation
 */
export const sendWelcomeEmail = functions.auth.user().onCreate(async (user) => {
  try {
    if (!user.email) {
      logger.warn('User created without email:', user.uid);
      return;
    }

    const verificationLink = `https://aura-sphere.app/auth/verify?uid=${user.uid}`;

    await sendVerificationEmail(user.email, verificationLink);

    logger.info('Welcome email sent to', { email: user.email, uid: user.uid });
  } catch (error: any) {
    logger.error('Welcome email failed:', { error: error.message, uid: user.uid });
    // Don't throw - we don't want to fail account creation if email fails
  }
});

/**
 * Send password reset confirmation email
 */
export const sendPasswordResetEmail = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be authenticated');
  }

  const { email, resetLink } = data;

  if (!email || !resetLink) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'email and resetLink are required'
    );
  }

  try {
    const html = `
      <div style="font-family: Arial, sans-serif; color: #333;">
        <h2>Reset Your Password</h2>
        <p>Hi,</p>
        <p>We received a request to reset your Aurasphere password. Click the link below to proceed:</p>
        <p style="margin: 2rem 0;">
          <a href="${resetLink}" style="
            display: inline-block;
            background: #00e0ff;
            color: #000;
            padding: 12px 24px;
            text-decoration: none;
            border-radius: 6px;
            font-weight: bold;
          ">Reset Password</a>
        </p>
        <p style="color: #777; font-size: 0.9rem;">
          This link will expire in 1 hour. If you didn't request this, ignore this email.
        </p>
        <hr style="border: none; border-top: 1px solid #ddd; margin: 2rem 0;" />
        <p style="color: #777; font-size: 0.9rem;">
          Sent by AuraSphere — <a href="https://aura-sphere.app">aura-sphere.app</a>
        </p>
      </div>
    `;

    await sendVerificationEmail(email, resetLink);

    logger.info('Password reset email sent to:', { email });
    return { success: true, message: 'Password reset email sent' };
  } catch (error: any) {
    logger.error('Password reset email failed:', error);
    throw new functions.https.HttpsError('internal', 'Failed to send reset email');
  }
});
