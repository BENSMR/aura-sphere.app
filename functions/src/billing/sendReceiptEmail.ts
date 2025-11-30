import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import * as pdfkit from "pdfkit";
import * as StreamBuffers from "stream-buffers";
import sgMail from "@sendgrid/mail";

if (!admin.apps.length) {
  admin.initializeApp();
}

const sendgridKey = functions.config()?.sendgrid?.key || "";
const sendgridSender = functions.config()?.sendgrid?.sender || "";
if (sendgridKey) {
  sgMail.setApiKey(sendgridKey);
} else {
  console.warn("SendGrid key not set.");
}

// Callable function to resend a receipt (admin/UI)
export const sendReceiptEmail = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Only authenticated users can call this function');
  }

  const uid = data?.uid || context.auth.uid;
  const invoiceId = data?.invoiceId;
  const recipient = data?.email;

  if (!invoiceId) {
    throw new functions.https.HttpsError('invalid-argument', 'invoiceId is required');
  }

  const invRef = admin.firestore().collection('users').doc(uid).collection('invoices').doc(invoiceId);
  const snap = await invRef.get();
  if (!snap.exists) {
    throw new functions.https.HttpsError('not-found', 'Invoice not found');
  }
  const inv = snap.data() as any;
  const to = recipient || inv?.customerEmail;
  if (!to) {
    throw new functions.https.HttpsError('failed-precondition', 'No recipient email available');
  }

  // Build PDF
  const doc = new (pdfkit as any)();
  const stream = new StreamBuffers.WritableStreamBuffer({
    initialSize: (100 * 1024),
    incrementAmount: (10 * 1024)
  });
  doc.pipe(stream);
  doc.fontSize(20).text('Payment Receipt', { align: 'center' });
  doc.moveDown();
  doc.fontSize(12).text(`Invoice: ${inv?.invoiceNumber ?? invoiceId}`);
  doc.text(`Amount: ${(inv?.total ?? 0).toFixed(2)} ${inv?.currency ?? ''}`);
  doc.text(`Date: ${(new Date()).toLocaleString()}`);
  doc.end();
  const pdfBuffer = stream.getContents() as Buffer;

  if (!sendgridKey || !sendgridSender) {
    throw new functions.https.HttpsError('failed-precondition', 'Email not configured on server');
  }

  const msg = {
    to,
    from: sendgridSender,
    subject: `Receipt - ${inv?.invoiceNumber ?? invoiceId}`,
    text: `Attached receipt for ${inv?.invoiceNumber ?? invoiceId}`,
    attachments: [
      {
        content: pdfBuffer.toString('base64'),
        filename: `receipt-${inv?.invoiceNumber ?? invoiceId}.pdf`,
        type: 'application/pdf',
        disposition: 'attachment'
      }
    ]
  };

  await sgMail.send(msg);
  return { success: true, message: 'Email sent' };
});
