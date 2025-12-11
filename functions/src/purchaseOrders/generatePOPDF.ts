import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { logger } from "../utils/logger";
import { generatePOPDFBuffer } from "./generatePOPDFUtil";

if (!admin.apps.length) admin.initializeApp();

/**
 * Cloud Function: Generate Purchase Order PDF
 *
 * Callable function that generates a PDF for a purchase order.
 * Returns base64-encoded PDF and optionally saves to Storage.
 */
export const generatePOPDF = functions.https.onCall(
  async (data, context) => {
    try {
      // Authentication check
      if (!context.auth) {
        throw new functions.https.HttpsError(
          "unauthenticated",
          "Must be signed in"
        );
      }

      const uid = context.auth.uid;
      const { poId, saveToStorage = false } = data;

      if (!poId) {
        throw new functions.https.HttpsError(
          "invalid-argument",
          "poId is required"
        );
      }

      logger.info("Generating PO PDF", { uid, poId, saveToStorage });

      // Use shared utility to generate PDF
      const pdfBuffer = await generatePOPDFBuffer(uid, poId, saveToStorage);
      const pdfBase64 = pdfBuffer.toString("base64");

      logger.info("PO PDF generated successfully", {
        uid,
        poId,
        size: pdfBuffer.length,
      });

      return {
        success: true,
        base64: pdfBase64,
        size: pdfBuffer.length,
      };
    } catch (error: any) {
      logger.error("PO PDF generation failed", {
        error: error.message,
        stack: error.stack,
      });

      // Re-throw known errors
      if (
        error.code === "unauthenticated" ||
        error.code === "invalid-argument" ||
        error.code === "not-found"
      ) {
        throw error;
      }

      throw new functions.https.HttpsError(
        "internal",
        "PDF generation failed: " + error.message
      );
    }
  }
);
