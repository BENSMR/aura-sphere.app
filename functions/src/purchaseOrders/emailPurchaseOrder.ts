import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import sgMail from "@sendgrid/mail";
import { logger } from "../utils/logger";
import { generatePOPDFBuffer } from "./generatePOPDFUtil";

if (!admin.apps.length) admin.initializeApp();

// Initialize SendGrid with API key
const sendgridKey =
  functions.config().sendgrid?.key || process.env.SENDGRID_API_KEY || "";
if (sendgridKey) {
  sgMail.setApiKey(sendgridKey);
}

interface EmailPORequest {
  poId: string;
  to: string | string[];
  cc?: string | string[];
  bcc?: string | string[];
  subject?: string;
  message?: string;
  saveToStorage?: boolean;
}

interface SendGridAttachment {
  content: string;
  filename: string;
  type: string;
  disposition: string;
}

interface SendGridMessage {
  to: string | string[];
  from: { email: string; name: string };
  subject: string;
  text: string;
  html?: string;
  attachments: SendGridAttachment[];
  cc?: string | string[];
  bcc?: string | string[];
  replyTo?: { email: string; name: string };
}

/**
 * Helper: Validate email format
 */
function isValidEmail(email: string): boolean {
  const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
  return emailRegex.test(email);
}

/**
 * Helper: Normalize email array
 */
function normalizeEmails(
  emails: string | string[] | undefined
): string[] | undefined {
  if (!emails) return undefined;
  const arr = Array.isArray(emails) ? emails : [emails];
  return arr.filter((e) => isValidEmail(e));
}

/**
 * Cloud Function: Email Purchase Order with PDF attachment
 *
 * Generates a PDF for the PO and sends it via SendGrid with tracking
 */
export const emailPurchaseOrder = functions.https.onCall(
  async (data: EmailPORequest, context) => {
    try {
      // ===== VALIDATION =====
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Authentication required"
        );
      }

      if (!sendgridKey) {
        throw new functions.https.HttpsError(
          "failed-precondition",
          "SendGrid API key not configured"
        );
      }

      const uid = context.auth.uid;
      const { poId, to, cc, bcc, subject, message, saveToStorage = false } =
        data;

      if (!poId || !to) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "poId and to email are required"
        );
      }

      // Validate recipient email(s)
      const toEmails = normalizeEmails(to);
      if (!toEmails || toEmails.length === 0) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "Valid recipient email required"
        );
      }

      const ccEmails = normalizeEmails(cc);
      const bccEmails = normalizeEmails(bcc);

      logger.info("Starting PO email", {
        uid,
        poId,
        to: toEmails,
        hasCC: !!ccEmails,
        hasBCC: !!bccEmails,
      });

      // ===== FETCH PO =====
      const db = admin.firestore();
      const poRef = db
        .collection("users")
        .doc(uid)
        .collection("purchase_orders")
        .doc(poId);
      const poSnap = await poRef.get();

      if (!poSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Purchase Order not found");
      }

      const po = poSnap.data() as any;

      // ===== GENERATE PDF =====
      logger.info("Generating PDF for PO", { uid, poId });

      const pdfBuffer = await generatePOPDFBuffer(uid, poId, saveToStorage);
      const pdfBase64 = pdfBuffer.toString("base64");

      // ===== BUILD EMAIL MESSAGE =====
      const fromEmail =
        functions.config().email?.from ||
        process.env.EMAIL_FROM ||
        "noreply@aurasphere.app";
      const fromName =
        functions.config().email?.from_name ||
        process.env.EMAIL_FROM_NAME ||
        "AuraSphere";

      const emailSubject =
        subject || `Purchase Order ${po.poNumber || poId}`;
      const emailText =
        message ||
        `Please find attached Purchase Order ${po.poNumber || poId} from AuraSphere.`;

      const msg: SendGridMessage = {
        to: toEmails,
        from: { email: fromEmail, name: fromName },
        subject: emailSubject,
        text: emailText,
        attachments: [
          {
            content: pdfBase64,
            filename: `PO-${po.poNumber || poId}.pdf`,
            type: "application/pdf",
            disposition: "attachment",
          },
        ],
      };

      if (ccEmails && ccEmails.length > 0) {
        msg.cc = ccEmails;
      }

      if (bccEmails && bccEmails.length > 0) {
        msg.bcc = bccEmails;
      }

      // Optional: Add reply-to
      if (po.supplierEmail) {
        msg.replyTo = {
          email: po.supplierEmail,
          name: po.supplierName || "Supplier",
        };
      }

      // ===== SEND EMAIL =====
      logger.info("Sending email via SendGrid", {
        uid,
        poId,
        to: toEmails,
        from: fromEmail,
      });

      const result = await sgMail.send(msg);

      logger.info("SendGrid response", {
        uid,
        poId,
        statusCode: result[0]?.statusCode,
      });

      // ===== UPDATE PO METADATA =====
      try {
        await poRef.update({
          lastEmailSentAt: admin.firestore.FieldValue.serverTimestamp(),
          lastEmailSentTo: Array.isArray(to) ? to.join(",") : to,
          emailCount: admin.firestore.FieldValue.increment(1),
        });

        logger.info("PO metadata updated", { uid, poId });
      } catch (updateErr: any) {
        logger.warn("Failed to update PO metadata", {
          uid,
          poId,
          error: updateErr.message,
        });
        // Don't throw - email was sent successfully, metadata update is optional
      }

      logger.info("PO email sent successfully", {
        uid,
        poId,
        to: toEmails,
      });

      return {
        success: true,
        message: `Email sent to ${toEmails.join(", ")}`,
        recipients: toEmails.length,
        pdfSize: pdfBuffer.length,
      };
    } catch (error: any) {
      logger.error("Failed to email PO", {
        error: error.message,
        stack: error.stack,
        code: error.code,
      });

      // Return appropriate error
      if (error.code === "unauthenticated") {
        throw error;
      }
      if (error.code === "invalid-argument") {
        throw error;
      }
      if (error.code === "not-found") {
        throw error;
      }

      // Handle SendGrid-specific errors
      if (error.response) {
        logger.error("SendGrid API error", {
          status: error.response.status,
          errors: error.response.body?.errors,
        });

        throw new functions.https.HttpsError(
          "internal",
          `Failed to send email: ${
            error.response.body?.errors?.[0]?.message ||
            "Unknown SendGrid error"
          }`
        );
      }

      throw new functions.https.HttpsError(
        "internal",
        `Failed to send purchase order email: ${error.message}`
      );
    }
  }
);
