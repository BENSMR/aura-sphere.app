import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();
const SENDGRID_API_KEY = functions.config()?.sendgrid?.api_key || "";

// Import SendGrid SDK (requires: npm install @sendgrid/mail)
let sgMail: any = null;
try {
  const sgModule = require("@sendgrid/mail");
  sgMail = sgModule;
  if (SENDGRID_API_KEY) {
    sgMail.setApiKey(SENDGRID_API_KEY);
  }
} catch (err) {
  console.warn("SendGrid module not installed or configured");
}

/**
 * Send Payment Confirmation Email
 */
export const sendPaymentConfirmationEmail = async (
  uid: string,
  invoiceId: string,
  customerEmail: string,
  paymentDetails: Record<string, any>
): Promise<void> => {
  if (!sgMail || !SENDGRID_API_KEY) {
    console.warn("SendGrid not configured, skipping email");
    return;
  }

  try {
    // Get invoice details
    const invoiceDoc = await db
      .collection("users")
      .doc(uid)
      .collection("invoices")
      .doc(invoiceId)
      .get();

    const invoice = invoiceDoc.data() || {};
    const amount = (paymentDetails.amount / 100).toFixed(2);
    const currency = paymentDetails.currency?.toUpperCase() || "USD";

    // Email template
    const emailContent = `
<!DOCTYPE html>
<html>
  <head>
    <style>
      body { font-family: Arial, sans-serif; color: #333; }
      .container { max-width: 600px; margin: 0 auto; padding: 20px; }
      .header { background: #4CAF50; color: white; padding: 20px; text-align: center; }
      .content { padding: 20px; border: 1px solid #ddd; }
      .details { margin: 20px 0; }
      .detail-row { display: flex; justify-content: space-between; padding: 10px 0; border-bottom: 1px solid #eee; }
      .footer { text-align: center; color: #999; font-size: 12px; padding: 20px; }
    </style>
  </head>
  <body>
    <div class="container">
      <div class="header">
        <h1>Payment Received ✓</h1>
      </div>
      <div class="content">
        <p>Dear ${invoice.customerName || "Valued Customer"},</p>
        <p>Thank you for your payment! We have successfully received your payment for invoice <strong>${invoice.invoiceNumber}</strong>.</p>

        <div class="details">
          <div class="detail-row">
            <span><strong>Invoice Number:</strong></span>
            <span>${invoice.invoiceNumber}</span>
          </div>
          <div class="detail-row">
            <span><strong>Amount Paid:</strong></span>
            <span>${currency} ${amount}</span>
          </div>
          <div class="detail-row">
            <span><strong>Payment Method:</strong></span>
            <span>${paymentDetails.cardBrand || "Card"} ending in ${paymentDetails.last4 || "****"}</span>
          </div>
          <div class="detail-row">
            <span><strong>Payment Date:</strong></span>
            <span>${new Date(paymentDetails.paidAt).toLocaleDateString()}</span>
          </div>
          <div class="detail-row">
            <span><strong>Transaction ID:</strong></span>
            <span style="font-family: monospace;">${paymentDetails.stripePaymentIntent || "N/A"}</span>
          </div>
        </div>

        <p>If you have any questions about this payment or invoice, please don't hesitate to contact us.</p>
        <p>Thank you for your business!</p>
      </div>
      <div class="footer">
        <p>This is an automated email. Please do not reply to this message.</p>
      </div>
    </div>
  </body>
</html>
    `;

    // Send email
    await sgMail.send({
      to: customerEmail,
      from: functions.config()?.sendgrid?.from_email || "noreply@yourdomain.com",
      subject: `Payment Confirmation - Invoice ${invoice.invoiceNumber}`,
      html: emailContent,
      replyTo: functions.config()?.sendgrid?.reply_to || "support@yourdomain.com"
    });

    console.log(`Payment confirmation email sent to ${customerEmail}`);
  } catch (err) {
    console.error("Error sending payment confirmation email:", err);
    throw err;
  }
};

/**
 * Send Payment Receipt Email - Cloud Function
 */
export const paymentReceiptEmail = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError("unauthenticated", "User not authenticated");
  }

  const uid = context.auth.uid;
  const { invoiceId, email: customerEmail } = data;

  // Get payment details
  const paymentsSnapshot = await db
    .collection("users")
    .doc(uid)
    .collection("invoices")
    .doc(invoiceId)
    .collection("payments")
    .where("status", "==", "succeeded")
    .orderBy("paidAt", "desc")
    .limit(1)
    .get();

  if (paymentsSnapshot.empty) {
    throw new functions.https.HttpsError("not-found", "No payment found for this invoice");
  }

  const paymentData = paymentsSnapshot.docs[0].data();
  await sendPaymentConfirmationEmail(uid, invoiceId, customerEmail, paymentData);

  return { success: true, message: "Receipt email sent" };
});
