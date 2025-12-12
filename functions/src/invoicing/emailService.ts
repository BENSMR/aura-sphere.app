import * as functions from "firebase-functions";
import * as nodemailer from "nodemailer";
import * as admin from "firebase-admin";

const db = admin.firestore();

/**
 * Email transporter configuration
 * Uses environment variables or Firebase config
 */
function createTransporter() {
  const mailConfig = {
    host: process.env.MAIL_HOST || functions.config().mail?.host,
    port: parseInt(process.env.MAIL_PORT || functions.config().mail?.port || "587"),
    secure: (process.env.MAIL_PORT || functions.config().mail?.port) === "465",
    auth: {
      user: process.env.MAIL_USER || functions.config().mail?.user,
      pass: process.env.MAIL_PASS || functions.config().mail?.pass,
    },
  };

  // Validate configuration
  if (!mailConfig.auth.user || !mailConfig.auth.pass) {
    throw new Error("Email configuration missing: MAIL_USER or MAIL_PASS not set");
  }

  return nodemailer.createTransport(mailConfig);
}

/**
 * Generate HTML email template for invoice
 */
function generateInvoiceEmailHTML(
  invoiceNumber: string,
  businessName: string,
  amount: string,
  dueDate: string,
  businessAddress: string,
  clientName?: string
): string {
  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: #0f172a; color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
          .header h2 { margin: 0; font-size: 24px; }
          .section { margin: 20px 0; padding: 15px; background: #f8fafc; border-radius: 6px; border-left: 4px solid #0ea5e9; }
          .section-title { font-weight: bold; color: #0f172a; margin-bottom: 10px; }
          .detail-row { display: flex; justify-content: space-between; margin: 8px 0; }
          .label { font-weight: 500; color: #475569; }
          .value { color: #0f172a; font-weight: 600; }
          .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #e2e8f0; text-align: center; font-size: 12px; color: #64748b; }
          .button { display: inline-block; padding: 12px 24px; background: #0ea5e9; color: white; text-decoration: none; border-radius: 6px; margin: 15px 0; }
          .warning { background: #fef3c7; border-left-color: #f59e0b; color: #92400e; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>${invoiceNumber}</h2>
            <p style="margin: 5px 0; font-size: 14px;">from <strong>${businessName}</strong></p>
          </div>

          <p>Hello${clientName ? " " + clientName : ""},</p>
          <p>You have received a new invoice from <strong>${businessName}</strong>. Please review the details below.</p>

          <div class="section">
            <div class="section-title">Invoice Amount</div>
            <div class="detail-row">
              <span class="label">Total Due:</span>
              <span class="value">$${amount}</span>
            </div>
            <div class="detail-row">
              <span class="label">Due Date:</span>
              <span class="value">${dueDate}</span>
            </div>
          </div>

          <div class="section">
            <div class="section-title">Business Information</div>
            <p style="margin: 5px 0;">
              <strong>${businessName}</strong><br>
              ${businessAddress}
            </p>
          </div>

          <div style="text-align: center;">
            <a href="https://aurasphere.app/invoices" class="button">View Invoice in App</a>
          </div>

          <p style="font-size: 14px; color: #64748b; margin-top: 20px;">
            If you have any questions about this invoice, please contact ${businessName} directly.
          </p>

          <div class="footer">
            <p>This email was sent to you by AuraSphere Pro. If you believe this was sent in error, please contact the sender.</p>
            <p>&copy; ${new Date().getFullYear()} AuraSphere Pro. All rights reserved.</p>
          </div>
        </div>
      </body>
    </html>
  `;
}

/**
 * Generate payment confirmation email
 */
function generatePaymentConfirmationEmailHTML(
  invoiceNumber: string,
  businessName: string,
  amount: string,
  paymentDate: string
): string {
  return `
    <!DOCTYPE html>
    <html>
      <head>
        <meta charset="UTF-8">
        <style>
          body { font-family: -apple-system, BlinkMacSystemFont, "Segoe UI", Arial, sans-serif; color: #333; }
          .container { max-width: 600px; margin: 0 auto; padding: 20px; }
          .header { background: linear-gradient(135deg, #10b981, #059669); color: white; padding: 20px; border-radius: 8px; margin-bottom: 20px; }
          .header h2 { margin: 0; font-size: 24px; }
          .success-badge { display: inline-block; background: #10b981; color: white; padding: 10px 15px; border-radius: 20px; font-size: 14px; margin: 10px 0; }
          .section { margin: 20px 0; padding: 15px; background: #f0fdf4; border-radius: 6px; border-left: 4px solid #10b981; }
          .detail-row { display: flex; justify-content: space-between; margin: 8px 0; }
          .label { font-weight: 500; color: #475569; }
          .value { color: #059669; font-weight: 600; }
          .footer { margin-top: 30px; padding-top: 20px; border-top: 1px solid #e2e8f0; text-align: center; font-size: 12px; color: #64748b; }
        </style>
      </head>
      <body>
        <div class="container">
          <div class="header">
            <h2>Payment Received</h2>
            <div class="success-badge">✓ Confirmed</div>
          </div>

          <p>Thank you for your payment!</p>
          <p>We have successfully received your payment for <strong>${invoiceNumber}</strong>.</p>

          <div class="section">
            <div class="detail-row">
              <span class="label">Invoice Number:</span>
              <span class="value">${invoiceNumber}</span>
            </div>
            <div class="detail-row">
              <span class="label">Amount Received:</span>
              <span class="value">$${amount}</span>
            </div>
            <div class="detail-row">
              <span class="label">Payment Date:</span>
              <span class="value">${paymentDate}</span>
            </div>
          </div>

          <p style="font-size: 14px; color: #64748b;">
            Your receipt has been recorded in our system. You can view your transaction history in the AuraSphere app.
          </p>

          <div class="footer">
            <p>&copy; ${new Date().getFullYear()} ${businessName}. All rights reserved.</p>
          </div>
        </div>
      </body>
    </html>
  `;
}

/**
 * Callable: sendInvoiceEmail
 * Sends invoice notification to client
 * Payload: { invoiceId: string }
 */
export const sendInvoiceEmail = functions.https.onCall(async (data, context) => {
  try {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError(
        "unauthenticated",
        "User must be authenticated"
      );
    }

    // Validate input
    const { invoiceId } = data;
    if (!invoiceId || typeof invoiceId !== "string") {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Missing or invalid invoiceId"
      );
    }

    const userId = context.auth.uid;
    console.log(`[sendInvoiceEmail] userId=${userId}, invoiceId=${invoiceId}`);

    // Load invoice
    const invoiceRef = db.collection("invoices").doc(invoiceId);
    const invoiceSnap = await invoiceRef.get();

    if (!invoiceSnap.exists) {
      throw new functions.https.HttpsError(
        "not-found",
        `Invoice ${invoiceId} does not exist`
      );
    }

    const invoice = invoiceSnap.data()!;

    // Verify ownership
    if (invoice.userId !== userId) {
      throw new functions.https.HttpsError(
        "permission-denied",
        "You do not have permission to send this invoice"
      );
    }

    // Extract invoice details
    const clientEmail = invoice.clientEmail;
    const clientName = invoice.clientName;
    const amount = invoice.total?.toFixed(2) ?? "0.00";
    const dueDate = invoice.dueDate ? new Date(invoice.dueDate).toLocaleDateString() : "N/A";
    const invoiceNumber = invoice.invoiceNumber ?? "Invoice";

    if (!clientEmail) {
      throw new functions.https.HttpsError(
        "failed-precondition",
        "Invoice missing client email address"
      );
    }

    // Load user's business info
    const userRef = db.collection("users").doc(userId);
    const userSnap = await userRef.get();
    const user = userSnap.data();

    const businessName = user?.businessName ?? "Your Business";
    const businessEmail = (user?.businessEmail ?? process.env.MAIL_FROM) || "noreply@aurasphere.com";
    const businessAddress = user?.businessAddress ?? "";

    // Create transporter and send email
    const transporter = createTransporter();

    const htmlContent = generateInvoiceEmailHTML(
      invoiceNumber,
      businessName,
      amount,
      dueDate,
      businessAddress,
      clientName
    );

    const mailOptions = {
      from: process.env.MAIL_FROM || businessEmail,
      to: clientEmail,
      subject: `${invoiceNumber} from ${businessName}`,
      html: htmlContent,
      replyTo: businessEmail,
      headers: {
        "X-Priority": "3",
        "X-Mailer": "AuraSphere Pro",
      },
    };

    console.log(`[sendInvoiceEmail] Sending to ${clientEmail}`);
    await transporter.sendMail(mailOptions);
    console.log(`[sendInvoiceEmail] Email sent successfully`);

    // Update invoice audit log
    await invoiceRef.update({
      lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
      sentCount: admin.firestore.FieldValue.increment(1),
    });

    return {
      success: true,
      message: `Invoice ${invoiceNumber} sent to ${clientEmail}`,
      sentAt: new Date().toISOString(),
    };
  } catch (error: any) {
    console.error("[sendInvoiceEmail] Error:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError(
      "internal",
      error.message || "Failed to send invoice email"
    );
  }
});

/**
 * Callable: sendPaymentConfirmation
 * Sends payment confirmation to payer
 * Payload: { invoiceId: string, paidAmount: number, paymentDate: string }
 */
export const sendPaymentConfirmation = functions.https.onCall(
  async (data, context) => {
    try {
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "User must be authenticated"
        );
      }

      const { invoiceId, paidAmount, paymentDate } = data;

      if (!invoiceId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Missing invoiceId"
        );
      }

      const userId = context.auth.uid;
      console.log(`[sendPaymentConfirmation] userId=${userId}, invoiceId=${invoiceId}`);

      // Load invoice
      const invoiceRef = db.collection("invoices").doc(invoiceId);
      const invoiceSnap = await invoiceRef.get();

      if (!invoiceSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Invoice not found");
      }

      const invoice = invoiceSnap.data()!;

      // Verify ownership
      if (invoice.userId !== userId) {
        throw new functions.https.HttpsError(
          "permission-denied",
          "Unauthorized"
        );
      }

      const clientEmail = invoice.clientEmail;
      const invoiceNumber = invoice.invoiceNumber ?? "Invoice";
      const businessName = invoice.businessName ?? "Your Business";

      if (!clientEmail) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "No client email on file"
        );
      }

      const transporter = createTransporter();
      const amount = (paidAmount ?? invoice.total ?? 0).toFixed(2);
      const payDate = paymentDate
        ? new Date(paymentDate).toLocaleDateString()
        : new Date().toLocaleDateString();

      const htmlContent = generatePaymentConfirmationEmailHTML(
        invoiceNumber,
        businessName,
        amount,
        payDate
      );

      const mailOptions = {
        from: process.env.MAIL_FROM,
        to: clientEmail,
        subject: `Payment Confirmation - ${invoiceNumber}`,
        html: htmlContent,
        headers: {
          "X-Priority": "3",
          "X-Mailer": "AuraSphere Pro",
        },
      };

      console.log(`[sendPaymentConfirmation] Sending confirmation to ${clientEmail}`);
      await transporter.sendMail(mailOptions);

      // Update invoice
      await invoiceRef.update({
        paymentConfirmationSentAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      return {
        success: true,
        message: `Payment confirmation sent to ${clientEmail}`,
      };
    } catch (error: any) {
      console.error("[sendPaymentConfirmation] Error:", error);
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }
      throw new functions.https.HttpsError("internal", error.message);
    }
  }
);

/**
 * Callable: sendBulkInvoices
 * Sends multiple invoices to different clients
 * Payload: { invoiceIds: string[] }
 */
export const sendBulkInvoices = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "Auth required");
    }

    const { invoiceIds } = data;

    if (!Array.isArray(invoiceIds) || invoiceIds.length === 0) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "invoiceIds must be a non-empty array"
      );
    }

    if (invoiceIds.length > 50) {
      throw new functions.https.HttpsError(
        "invalid-argument",
        "Maximum 50 invoices per request"
      );
    }

    const userId = context.auth.uid;
    console.log(`[sendBulkInvoices] userId=${userId}, count=${invoiceIds.length}`);

    const transporter = createTransporter();
    const results = { sent: 0, failed: 0, errors: [] as string[] };

    for (const invoiceId of invoiceIds) {
      try {
        const invoiceRef = db.collection("invoices").doc(invoiceId);
        const invoiceSnap = await invoiceRef.get();

        if (!invoiceSnap.exists) {
          results.errors.push(`Invoice ${invoiceId} not found`);
          results.failed++;
          continue;
        }

        const invoice = invoiceSnap.data()!;

        if (invoice.userId !== userId) {
          results.errors.push(`Unauthorized for invoice ${invoiceId}`);
          results.failed++;
          continue;
        }

        const clientEmail = invoice.clientEmail;
        if (!clientEmail) {
          results.errors.push(`No email for invoice ${invoiceId}`);
          results.failed++;
          continue;
        }

        const userSnap = await db.collection("users").doc(userId).get();
        const user = userSnap.data();

        const htmlContent = generateInvoiceEmailHTML(
          invoice.invoiceNumber ?? "Invoice",
          user?.businessName ?? "Your Business",
          invoice.total?.toFixed(2) ?? "0.00",
          invoice.dueDate ? new Date(invoice.dueDate).toLocaleDateString() : "N/A",
          user?.businessAddress ?? ""
        );

        await transporter.sendMail({
          from: process.env.MAIL_FROM,
          to: clientEmail,
          subject: `${invoice.invoiceNumber} from ${user?.businessName}`,
          html: htmlContent,
          replyTo: user?.businessEmail,
        });

        await invoiceRef.update({
          lastSentAt: admin.firestore.FieldValue.serverTimestamp(),
          sentCount: admin.firestore.FieldValue.increment(1),
        });

        results.sent++;
        console.log(`[sendBulkInvoices] Sent invoice ${invoiceId}`);
      } catch (error: any) {
        results.failed++;
        results.errors.push(`${invoiceId}: ${error.message}`);
        console.error(`[sendBulkInvoices] Failed to send ${invoiceId}:`, error);
      }
    }

    console.log(`[sendBulkInvoices] Complete: sent=${results.sent}, failed=${results.failed}`);

    return {
      success: results.failed === 0,
      sent: results.sent,
      failed: results.failed,
      errors: results.errors.length > 0 ? results.errors : undefined,
    };
  } catch (error: any) {
    console.error("[sendBulkInvoices] Error:", error);
    if (error instanceof functions.https.HttpsError) {
      throw error;
    }
    throw new functions.https.HttpsError("internal", error.message);
  }
});
