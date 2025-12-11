import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import * as nodemailer from 'nodemailer';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

type EmailRequest = {
  to: string;
  subject: string;
  html: string;
  text?: string;
  from?: string;
};

function getTransporter() {
  const sgKey = functions.config().sendgrid?.key;
  if (sgKey) {
    // Using SendGrid SMTP (username: apikey, password: KEY)
    const transporter = nodemailer.createTransport({
      host: 'smtp.sendgrid.net',
      port: 587,
      auth: { user: 'apikey', pass: sgKey }
    });
    return transporter;
  }
  // Fallback to SMTP config (e.g., Gmail SMTP) - set functions.config().smtp.*
  const smtpHost = functions.config().smtp?.host;
  if (!smtpHost) throw new Error('No email transport configured. Set sendgrid.key or smtp.* config.');
  const transporter = nodemailer.createTransport({
    host: smtpHost,
    port: functions.config().smtp?.port || 587,
    secure: !!functions.config().smtp?.secure,
    auth: {
      user: functions.config().smtp?.user,
      pass: functions.config().smtp?.pass
    }
  });
  return transporter;
}

export const sendEmailAlert = functions.https.onCall(async (data, ctx) => {
  // protect: only server/admin can call
  if (!ctx.auth) throw new functions.https.HttpsError('unauthenticated', 'Auth required');
  // Optionally restrict to admins:
  // if (!ctx.auth.token.admin) throw new functions.https.HttpsError('permission-denied', 'Admin only');

  try {
    const req = data as EmailRequest;
    if (!req || !req.to || !req.subject || !req.html) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing email fields');
    }

    const transporter = getTransporter();
    const from = req.from || functions.config().email?.from || 'noreply@aurasphere.app';

    const mailOptions = {
      from,
      to: req.to,
      subject: req.subject,
      html: req.html,
      text: req.text || ''
    };

    const info = await transporter.sendMail(mailOptions);
    await db.collection('notifications_audit').doc().set({
      type: 'email',
      to: req.to,
      subject: req.subject,
      info,
      createdAt: admin.firestore.FieldValue.serverTimestamp(),
      actor: ctx.auth.uid || 'system'
    });
    return { success: true, info };
  } catch (err: any) {
    console.error('sendEmailAlert error', err);
    throw new functions.https.HttpsError('internal', 'Email sending failed');
  }
});
