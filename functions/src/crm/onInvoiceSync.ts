import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { logger } from "../utils/logger";

const db = admin.firestore();

/**
 * Firestore trigger: Nested invoice created
 * Path: users/{userId}/invoices/{invoiceId}
 * 
 * Updates client metrics when invoice is created
 */
export const onNestedInvoiceCreated = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onCreate(async (snap, context) => {
    try {
      const invoiceData = snap.data();
      const userId = context.params.userId;
      const invoiceId = snap.id;
      const clientId = invoiceData.clientId;

      if (!clientId) {
        logger.warn(
          `Invoice ${invoiceId} has no clientId, skipping client update`
        );
        return null;
      }

      const clientRef = db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .doc(clientId);

      const amountTotal = invoiceData.amountTotal ?? 0;
      const invoiceDate = invoiceData.invoiceDate || admin.firestore.Timestamp.now();

      // Update client with invoice metrics
      await clientRef.update({
        totalInvoices: admin.firestore.FieldValue.increment(1),
        lastInvoiceAmount: amountTotal,
        lastInvoiceDate: invoiceDate,
        lastActivityAt: admin.firestore.Timestamp.now(),
        timeline: admin.firestore.FieldValue.arrayUnion([
          {
            type: "invoice_created",
            amount: amountTotal,
            invoiceId: invoiceId,
            message: `Invoice created (€${amountTotal.toFixed(2)})`,
            createdAt: admin.firestore.Timestamp.now(),
          },
        ]),
      });

      logger.info(
        `Updated client ${clientId} after nested invoice ${invoiceId} created`
      );
      return null;
    } catch (error) {
      logger.error("Error in onNestedInvoiceCreated", error);
      throw error;
    }
  });

/**
 * Firestore trigger: Nested invoice paid (status updated)
 * Path: users/{userId}/invoices/{invoiceId}
 * 
 * Updates client payment metrics when invoice is marked as paid
 */
export const onNestedInvoicePaid = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const userId = context.params.userId;
      const invoiceId = change.after.id;
      const clientId = afterData.clientId;

      // Only process if status changed to "paid"
      if (beforeData.status === afterData.status || afterData.status !== "paid") {
        return null;
      }

      if (!clientId) {
        logger.warn(
          `Invoice ${invoiceId} has no clientId, skipping client update`
        );
        return null;
      }

      const clientRef = db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .doc(clientId);

      const amountTotal = afterData.amountTotal ?? 0;

      // Update client with payment metrics
      await clientRef.update({
        lifetimeValue: admin.firestore.FieldValue.increment(amountTotal),
        lastPaymentDate: admin.firestore.Timestamp.now(),
        lastActivityAt: admin.firestore.Timestamp.now(),
        // Boost AI score (+20 points) for payment
        aiScore: admin.firestore.FieldValue.increment(20),
        // Reduce churn risk (multiply by 0.85, subtract 15%)
        churnRisk: admin.firestore.FieldValue.increment(-15),
        // Update VIP status if lifetime value > 5000
        vipStatus: (await clientRef.get()).data()?.lifetimeValue ?? 0 + amountTotal > 5000,
        timeline: admin.firestore.FieldValue.arrayUnion([
          {
            type: "payment_received",
            amount: amountTotal,
            invoiceId: invoiceId,
            message: `Payment received (€${amountTotal.toFixed(2)})`,
            createdAt: admin.firestore.Timestamp.now(),
          },
        ]),
      });

      logger.info(
        `Updated client ${clientId} after nested invoice ${invoiceId} paid`
      );
      return null;
    } catch (error) {
      logger.error("Error in onNestedInvoicePaid", error);
      throw error;
    }
  });

/**
 * Firestore trigger: Top-level invoice created
 * Path: invoices/{invoiceId}
 * 
 * Updates client metrics when top-level invoice is created
 * Uses merge strategy to preserve existing fields
 */
export const onTopLevelInvoiceCreated = functions.firestore
  .document("invoices/{invoiceId}")
  .onCreate(async (snap, context) => {
    try {
      const invoiceData = snap.data();
      const invoiceId = snap.id;
      const userId = invoiceData.userId;
      const clientId = invoiceData.clientId;

      if (!userId || !clientId) {
        logger.warn(
          `Invoice ${invoiceId} has missing userId or clientId, skipping client update`
        );
        return null;
      }

      const clientRef = db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .doc(clientId);

      const amountTotal = invoiceData.amountTotal ?? 0;
      const invoiceDate = invoiceData.invoiceDate || admin.firestore.Timestamp.now();

      // Update client with invoice metrics using merge
      await clientRef.set(
        {
          totalInvoices: admin.firestore.FieldValue.increment(1),
          lastInvoiceAmount: amountTotal,
          lastInvoiceDate: invoiceDate,
          lastActivityAt: admin.firestore.Timestamp.now(),
          timeline: admin.firestore.FieldValue.arrayUnion([
            {
              type: "invoice_created",
              amount: amountTotal,
              invoiceId: invoiceId,
              message: `Invoice created (€${amountTotal.toFixed(2)})`,
              createdAt: admin.firestore.Timestamp.now(),
            },
          ]),
        },
        { merge: true }
      );

      logger.info(
        `Updated client ${clientId} after top-level invoice ${invoiceId} created`
      );
      return null;
    } catch (error) {
      logger.error("Error in onTopLevelInvoiceCreated", error);
      throw error;
    }
  });

/**
 * Firestore trigger: Top-level invoice paid (status updated)
 * Path: invoices/{invoiceId}
 * 
 * Updates client payment metrics when top-level invoice is marked as paid
 */
export const onTopLevelInvoicePaid = functions.firestore
  .document("invoices/{invoiceId}")
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const invoiceId = change.after.id;
      const userId = afterData.userId;
      const clientId = afterData.clientId;

      // Only process if status changed to "paid"
      if (beforeData.status === afterData.status || afterData.status !== "paid") {
        return null;
      }

      if (!userId || !clientId) {
        logger.warn(
          `Invoice ${invoiceId} has missing userId or clientId, skipping client update`
        );
        return null;
      }

      const clientRef = db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .doc(clientId);

      const amountTotal = afterData.amountTotal ?? 0;

      // Get current client data for VIP status calculation
      const clientSnap = await clientRef.get();
      const currentLifetimeValue = clientSnap.data()?.lifetimeValue ?? 0;
      const newLifetimeValue = currentLifetimeValue + amountTotal;

      // Update client with payment metrics using merge
      await clientRef.set(
        {
          lifetimeValue: admin.firestore.FieldValue.increment(amountTotal),
          lastPaymentDate: admin.firestore.Timestamp.now(),
          lastActivityAt: admin.firestore.Timestamp.now(),
          // Boost AI score (+20 points) for payment
          aiScore: admin.firestore.FieldValue.increment(20),
          // Reduce churn risk (subtract 15%)
          churnRisk: admin.firestore.FieldValue.increment(-15),
          // Update VIP status if lifetime value > 5000
          vipStatus: newLifetimeValue > 5000,
          timeline: admin.firestore.FieldValue.arrayUnion([
            {
              type: "payment_received",
              amount: amountTotal,
              invoiceId: invoiceId,
              message: `Payment received (€${amountTotal.toFixed(2)})`,
              createdAt: admin.firestore.Timestamp.now(),
            },
          ]),
        },
        { merge: true }
      );

      logger.info(
        `Updated client ${clientId} after top-level invoice ${invoiceId} paid`
      );
      return null;
    } catch (error) {
      logger.error("Error in onTopLevelInvoicePaid", error);
      throw error;
    }
  });
