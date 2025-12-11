import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import { logger } from "../utils/logger";

const db = admin.firestore();

/**
 * Firestore trigger: Invoice paid - Nested invoices
 * Path: users/{userId}/invoices/{invoiceId}
 * 
 * Triggered when invoice status is updated to "paid"
 * Updates client payment metrics, lifetime value, and VIP status
 */
export const onInvoicePaid = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const userId = context.params.userId;
      const invoiceId = change.after.id;
      const clientId = afterData.clientId;

      // Skip if no client associated with invoice
      if (!clientId) {
        logger.warn(`Invoice ${invoiceId} has no clientId, skipping payment update`);
        return null;
      }

      // Only process if status changed to "paid" (not already paid)
      if (beforeData.status === "paid" || afterData.status !== "paid") {
        return null;
      }

      const amountTotal = afterData.amountTotal ?? 0;
      const clientRef = db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .doc(clientId);

      // Get current client data for VIP evaluation
      const clientSnap = await clientRef.get();
      const clientData = clientSnap.data();
      const currentLifetimeValue = clientData?.lifetimeValue ?? 0;
      const newLifetimeValue = currentLifetimeValue + amountTotal;

      // Determine if client should be VIP
      // VIP if: lifetime value > 5000 OR single invoice > 1000
      const shouldBeVip = newLifetimeValue > 5000 || amountTotal > 1000;

      // Update client with payment metrics
      await clientRef.update({
        // Financial metrics
        lifetimeValue: admin.firestore.FieldValue.increment(amountTotal),
        lastPaymentDate: admin.firestore.Timestamp.now(),
        lastActivityAt: admin.firestore.Timestamp.now(),

        // AI and engagement metrics
        aiScore: admin.firestore.FieldValue.increment(20), // Boost for payment
        churnRisk: admin.firestore.FieldValue.increment(-15), // Reduce churn risk

        // VIP status
        vipStatus: shouldBeVip,

        // Timeline event
        timeline: admin.firestore.FieldValue.arrayUnion([
          {
            type: "payment_received",
            amount: amountTotal,
            invoiceId: invoiceId,
            message: `Invoice paid (€${amountTotal.toFixed(2)})`,
            createdAt: admin.firestore.Timestamp.now(),
          },
        ]),
      });

      logger.info(
        `Updated client ${clientId} for invoice ${invoiceId} payment. Amount: €${amountTotal}, New VIP: ${shouldBeVip}`
      );
      return null;
    } catch (error) {
      logger.error("Error in onInvoicePaid", error);
      throw error;
    }
  });

/**
 * Firestore trigger: Invoice marked as overdue - Nested invoices
 * Path: users/{userId}/invoices/{invoiceId}
 * 
 * Triggered when invoice status changes to "overdue"
 * Increases churn risk and records timeline event
 */
export const onInvoiceOverdue = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const userId = context.params.userId;
      const invoiceId = change.after.id;
      const clientId = afterData.clientId;

      // Skip if no client associated with invoice
      if (!clientId) {
        logger.warn(`Invoice ${invoiceId} has no clientId, skipping overdue update`);
        return null;
      }

      // Only process if status changed to "overdue" (not already overdue)
      if (beforeData.status === "overdue" || afterData.status !== "overdue") {
        return null;
      }

      const amountTotal = afterData.amountTotal ?? 0;
      const daysOverdue = afterData.daysOverdue ?? 0;
      const clientRef = db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .doc(clientId);

      // Increase churn risk based on days overdue
      // 1-7 days: +10, 8-30 days: +25, 30+ days: +40
      let churnRiskIncrease = 10;
      if (daysOverdue > 30) churnRiskIncrease = 40;
      else if (daysOverdue > 7) churnRiskIncrease = 25;

      // Update client with overdue metrics
      await clientRef.update({
        lastActivityAt: admin.firestore.Timestamp.now(),
        churnRisk: admin.firestore.FieldValue.increment(churnRiskIncrease),
        aiScore: admin.firestore.FieldValue.increment(-10), // Penalty for overdue
        timeline: admin.firestore.FieldValue.arrayUnion([
          {
            type: "invoice_overdue",
            amount: amountTotal,
            invoiceId: invoiceId,
            message: `Invoice overdue (€${amountTotal.toFixed(2)}) - ${daysOverdue} days`,
            createdAt: admin.firestore.Timestamp.now(),
          },
        ]),
      });

      logger.warn(
        `Invoice ${invoiceId} marked overdue for client ${clientId}. Days: ${daysOverdue}, Churn risk increase: +${churnRiskIncrease}`
      );
      return null;
    } catch (error) {
      logger.error("Error in onInvoiceOverdue", error);
      throw error;
    }
  });

/**
 * Firestore trigger: Invoice cancelled - Nested invoices
 * Path: users/{userId}/invoices/{invoiceId}
 * 
 * Triggered when invoice status changes to "cancelled"
 * Records cancellation event and logs it
 */
export const onInvoiceCancelled = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const userId = context.params.userId;
      const invoiceId = change.after.id;
      const clientId = afterData.clientId;

      // Skip if no client associated with invoice
      if (!clientId) {
        logger.warn(`Invoice ${invoiceId} has no clientId, skipping cancellation update`);
        return null;
      }

      // Only process if status changed to "cancelled"
      if (beforeData.status === "cancelled" || afterData.status !== "cancelled") {
        return null;
      }

      const amountTotal = afterData.amountTotal ?? 0;
      const clientRef = db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .doc(clientId);

      // Update client with cancellation event
      await clientRef.update({
        lastActivityAt: admin.firestore.Timestamp.now(),
        timeline: admin.firestore.FieldValue.arrayUnion([
          {
            type: "invoice_cancelled",
            amount: amountTotal,
            invoiceId: invoiceId,
            message: `Invoice cancelled (€${amountTotal.toFixed(2)})`,
            createdAt: admin.firestore.Timestamp.now(),
          },
        ]),
      });

      logger.info(
        `Invoice ${invoiceId} cancelled for client ${clientId}`
      );
      return null;
    } catch (error) {
      logger.error("Error in onInvoiceCancelled", error);
      throw error;
    }
  });

/**
 * Firestore trigger: Invoice refunded - Nested invoices
 * Path: users/{userId}/invoices/{invoiceId}
 * 
 * Triggered when invoice status changes to "refunded"
 * Decreases lifetime value and records refund
 */
export const onInvoiceRefunded = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const userId = context.params.userId;
      const invoiceId = change.after.id;
      const clientId = afterData.clientId;

      // Skip if no client associated with invoice
      if (!clientId) {
        logger.warn(`Invoice ${invoiceId} has no clientId, skipping refund update`);
        return null;
      }

      // Only process if status changed to "refunded"
      if (beforeData.status === "refunded" || afterData.status !== "refunded") {
        return null;
      }

      const amountTotal = afterData.amountTotal ?? 0;
      const clientRef = db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .doc(clientId);

      // Get current client data
      const clientSnap = await clientRef.get();
      const clientData = clientSnap.data();
      const currentLifetimeValue = clientData?.lifetimeValue ?? 0;
      const newLifetimeValue = Math.max(0, currentLifetimeValue - amountTotal);

      // Update client with refund metrics
      await clientRef.update({
        lifetimeValue: admin.firestore.FieldValue.increment(-amountTotal),
        lastActivityAt: admin.firestore.Timestamp.now(),
        // Reduce VIP status if lifetime value drops below threshold
        vipStatus: newLifetimeValue > 5000,
        // Penalty for refund
        aiScore: admin.firestore.FieldValue.increment(-25),
        timeline: admin.firestore.FieldValue.arrayUnion([
          {
            type: "invoice_refunded",
            amount: amountTotal,
            invoiceId: invoiceId,
            message: `Refund issued (€${amountTotal.toFixed(2)})`,
            createdAt: admin.firestore.Timestamp.now(),
          },
        ]),
      });

      logger.warn(
        `Invoice ${invoiceId} refunded for client ${clientId}. Refund amount: €${amountTotal}, New lifetime value: €${newLifetimeValue.toFixed(2)}`
      );
      return null;
    } catch (error) {
      logger.error("Error in onInvoiceRefunded", error);
      throw error;
    }
  });

/**
 * Firestore trigger: Invoice sent/viewed - Nested invoices
 * Path: users/{userId}/invoices/{invoiceId}
 * 
 * Triggered when invoice is sent to client or marked as viewed
 * Updates last activity and records engagement
 */
export const onInvoiceEngagement = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onUpdate(async (change, context) => {
    try {
      const beforeData = change.before.data();
      const afterData = change.after.data();
      const userId = context.params.userId;
      const invoiceId = change.after.id;
      const clientId = afterData.clientId;

      // Skip if no client associated with invoice
      if (!clientId) {
        return null;
      }

      // Check if sent or viewed status changed
      const wasSent = beforeData.sentAt !== null;
      const isSent = afterData.sentAt !== null;
      const wasViewed = beforeData.viewedAt !== null;
      const isViewed = afterData.viewedAt !== null;

      if ((wasSent && isSent) || (wasViewed && isViewed)) {
        // No change in sent/viewed status
        return null;
      }

      const clientRef = db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .doc(clientId);

      let eventType = "";
      let message = "";

      if (!wasSent && isSent) {
        eventType = "invoice_sent";
        message = "Invoice sent";
      } else if (!wasViewed && isViewed) {
        eventType = "invoice_viewed";
        message = "Invoice viewed";
        // Boost AI score slightly for engagement
      }

      if (!eventType) {
        return null;
      }

      // Update client with engagement event
      await clientRef.update({
        lastActivityAt: admin.firestore.Timestamp.now(),
        // Boost AI score for engagement
        aiScore: admin.firestore.FieldValue.increment(5),
        timeline: admin.firestore.FieldValue.arrayUnion([
          {
            type: eventType,
            invoiceId: invoiceId,
            message: message,
            createdAt: admin.firestore.Timestamp.now(),
          },
        ]),
      });

      logger.info(
        `Invoice ${invoiceId} engagement event (${eventType}) recorded for client ${clientId}`
      );
      return null;
    } catch (error) {
      logger.error("Error in onInvoiceEngagement", error);
      throw error;
    }
  });
