import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

if (!admin.apps.length) {
  admin.initializeApp();
}

const db = admin.firestore();

/**
 * Audit Payment Processing
 * Logs all payment activities for compliance and troubleshooting
 */
export const auditPaymentEvent = async (
  uid: string,
  invoiceId: string,
  eventType: "payment_initiated" | "payment_completed" | "payment_failed" | "payment_refunded",
  details: Record<string, any>
): Promise<void> => {
  const auditRef = db
    .collection("users")
    .doc(uid)
    .collection("paymentAudit")
    .doc();

  const auditEntry = {
    uid,
    invoiceId,
    eventType,
    timestamp: admin.firestore.FieldValue.serverTimestamp(),
    details: {
      ...details,
      userAgent: details.userAgent || "unknown",
      ipAddress: details.ipAddress || "unknown",
      provider: details.provider || "stripe"
    },
    status: "logged"
  };

  await auditRef.set(auditEntry);
  console.log(`Payment audit logged: ${eventType} for invoice ${invoiceId}`);
};

/**
 * Get Payment Audit Trail for Invoice
 */
export const getPaymentAuditTrail = async (
  uid: string,
  invoiceId: string
): Promise<any[]> => {
  const snapshot = await db
    .collection("users")
    .doc(uid)
    .collection("paymentAudit")
    .where("invoiceId", "==", invoiceId)
    .orderBy("timestamp", "desc")
    .get();

  return snapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data()
  }));
};

/**
 * Export Payment Records for Compliance
 */
export const exportPaymentRecords = functions.https.onCall(async (data, context) => {
  if (!context.auth || !context.auth.uid) {
    throw new functions.https.HttpsError("unauthenticated", "User not authenticated");
  }

  const uid = context.auth.uid;
  const { invoiceId, format = "json" } = data;

  // Get payment records
  const paymentsSnapshot = await db
    .collection("users")
    .doc(uid)
    .collection("invoices")
    .doc(invoiceId)
    .collection("payments")
    .get();

  // Get audit trail
  const auditSnapshot = await db
    .collection("users")
    .doc(uid)
    .collection("paymentAudit")
    .where("invoiceId", "==", invoiceId)
    .get();

  const payments = paymentsSnapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data()
  }));

  const auditTrail = auditSnapshot.docs.map((doc) => ({
    id: doc.id,
    ...doc.data()
  }));

  const exportData = {
    invoiceId,
    exportedAt: new Date().toISOString(),
    payments,
    auditTrail
  };

  console.log(`Payment records exported for invoice ${invoiceId}`);

  return {
    success: true,
    data: exportData,
    count: {
      payments: payments.length,
      auditEvents: auditTrail.length
    }
  };
});
