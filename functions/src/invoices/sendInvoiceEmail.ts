import * as functions from "firebase-functions";
import nodemailer from "nodemailer";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Callable: sendInvoiceEmail
 * Payload: { invoiceId: string }
 */
export const sendInvoiceEmail = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError(
      "unauthenticated",
      "User must be authenticated"
    );
  }

  const invoiceId = data.invoiceId;
  if (!invoiceId) {
    throw new functions.https.HttpsError(
      "invalid-argument",
      "Missing invoiceId"
    );
  }

  // Load invoice
  const invoiceRef = db.collection("invoices").doc(invoiceId);
  const invoiceSnap = await invoiceRef.get();

  if (!invoiceSnap.exists) {
    throw new functions.https.HttpsError(
      "not-found",
      "Invoice does not exist"
    );
  }

  const invoice = invoiceSnap.data();
  const clientEmail = invoice?.clientEmail;
  const amount = invoice?.total?.toFixed(2) ?? "0.00";
  const dueDate = invoice?.dueDate ?? "N/A";
  const invoiceNumber = invoice?.invoiceNumber ?? "Invoice";

  if (!clientEmail) {
    throw new functions.https.HttpsError(
      "failed-precondition",
      "Invoice missing client email"
    );
  }

  // Load user's business info
  const userId = context.auth.uid;
  const userSnap = await db.collection("users").doc(userId).get();
  const user = userSnap.data();

  const businessName = user?.businessName ?? "Your Business";
  const businessEmail = user?.businessEmail ?? "no-reply@yourbusiness.com";
  const businessAddress = user?.businessAddress ?? "—";

  // Configure SMTP transport
  const transporter = nodemailer.createTransport({
    host: functions.config().mail.host,
    port: functions.config().mail.port,
    secure: false,
    auth: {
      user: functions.config().mail.user,
      pass: functions.config().mail.pass,
    },
  });

  const mailOptions = {
    from: functions.config().mail.from || businessEmail,
    to: clientEmail,
    subject: `${invoiceNumber} from ${businessName}`,
    html: `
      <h2 style="font-family:Arial;">${invoiceNumber}</h2>
      <p>Hello,</p>
      <p>You have received a new invoice from <b>${businessName}</b>.</p>
      <p><b>Amount:</b> $${amount}</p>
      <p><b>Due Date:</b> ${dueDate}</p>

      <h3>Business Information</h3>
      <p>${businessName}<br>${businessAddress}</p>

      <p>You can view your invoice inside the AuraSphere app.</p>
      <br>
      <p>Thank you.</p>
    `,
  };

  // Attempt to send
  try {
    await transporter.sendMail(mailOptions);

    // Save audit log
    await invoiceRef.update({
      lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
      sentCount: admin.firestore.FieldValue.increment(1),
    });

    return { success: true };
  } catch (err: any) {
    console.error("Email send error:", err);
    throw new functions.https.HttpsError("unknown", err.message);
  }
});
