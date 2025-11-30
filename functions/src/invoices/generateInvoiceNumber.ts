import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { logger } from "../utils/logger";

// Initialize admin if not already done
if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Cloud Function: Generate next invoice number atomically
 * 
 * Uses Firestore transaction to:
 * 1. Read current counter from business profile
 * 2. Increment counter
 * 3. Generate formatted invoice number
 * 4. Update counter in single atomic operation
 * 
 * Prevents race conditions with concurrent requests.
 * 
 * Returns:
 * {
 *   success: true,
 *   invoiceNumber: string (e.g., "AS-000042"),
 *   counter: number (e.g., 42),
 *   generatedAt: string (ISO timestamp)
 * }
 */
export const generateInvoiceNumber = functions
  .runWith({
    memory: "256MB",
    timeoutSeconds: 10,
  })
  .region("us-central1")
  .https.onCall(async (data, context) => {
    // Authentication check
    if (!context.auth) {
      logger.error("Generate invoice number - unauthenticated", {});
      throw new functions.https.HttpsError(
        "unauthenticated",
        "Must be logged in."
      );
    }

    const userId = context.auth.uid;
    const businessRef = db
      .collection("users")
      .doc(userId)
      .collection("meta")
      .doc("business");

    try {
      logger.info("Generate invoice number - starting", { userId });

      // Atomic transaction: read counter, increment, update in single operation
      const result = await db.runTransaction(async (trx) => {
        const doc = await trx.get(businessRef);

        // Default values if business profile doesn't exist
        let prefix = "AS-";
        let counter = 1;

        // Read existing values if profile exists
        if (doc.exists) {
          const docData = doc.data()!;
          prefix = (docData.invoicePrefix || "AS-") as string;
          counter = ((docData.invoiceCounter || 0) as number) + 1;
        }

        // Format invoice number with prefix and zero-padded counter
        const invoiceNumber = `${prefix}${counter
          .toString()
          .padStart(6, "0")}`;

        // Update counter atomically within transaction
        trx.set(
          businessRef,
          {
            invoiceCounter: counter,
            lastInvoiceGeneratedAt: new Date().toISOString(),
          },
          { merge: true }
        );

        return {
          invoiceNumber,
          counter,
        };
      });

      logger.info("Generate invoice number - success", {
        userId,
        invoiceNumber: result.invoiceNumber,
        counter: result.counter,
      });

      return {
        success: true,
        invoiceNumber: result.invoiceNumber,
        counter: result.counter,
        generatedAt: new Date().toISOString(),
      };
    } catch (err: any) {
      logger.error("Generate invoice number - failed", {
        userId,
        error: err?.message,
        code: err?.code,
      });

      throw new functions.https.HttpsError(
        "internal",
        "Failed to generate invoice number",
        err?.message
      );
    }
  });
