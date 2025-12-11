/**
 * functions/src/crm/timeline_triggers.ts
 *
 * Automatically creates timeline events for:
 *  - Invoice creation
 *  - Payment receipt
 *  - AI insight updates
 *
 * Timeline events are stored in:
 *   users/{userId}/clients/{clientId}/timeline/{eventId}
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

async function addTimelineEvent(
  userId: string,
  clientId: string,
  data: any
) {
  const ref = db
    .collection("users")
    .doc(userId)
    .collection("clients")
    .doc(clientId)
    .collection("timeline");

  return ref.add({
    ...data,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}

// 1️⃣ Invoice → Timeline
export const onInvoiceTimeline = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data?.clientId) return null;

    return addTimelineEvent(context.params.userId, data.clientId, {
      type: "invoice",
      title: "Invoice Created",
      description: `Invoice ${data.number} for ${data.total} ${data.currency}`,
      amount: data.total,
      currency: data.currency,
      sourceId: context.params.invoiceId,
      createdBy: context.params.userId,
    });
  });

// 2️⃣ Payment → Timeline
export const onPaymentTimeline = functions.firestore
  .document("users/{userId}/payments/{paymentId}")
  .onCreate(async (snap, context) => {
    const data = snap.data();
    if (!data?.clientId) return null;

    return addTimelineEvent(context.params.userId, data.clientId, {
      type: "payment",
      title: "Payment Received",
      description: `Payment of ${data.amount} ${data.currency}`,
      amount: data.amount,
      currency: data.currency,
      sourceId: context.params.paymentId,
      createdBy: context.params.userId,
    });
  });

// 3️⃣ AI Insight Change → Timeline
export const onAiInsightTimeline = functions.firestore
  .document("users/{userId}/clients/{clientId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data()?.ai;
    const after = change.after.data()?.ai;
    if (!before || !after) return null;

    if (after.riskScore !== before.riskScore) {
      return addTimelineEvent(
        context.params.userId,
        context.params.clientId,
        {
          type: "ai",
          title: "AI Risk Updated",
          description: `Risk changed from ${before.riskScore} to ${after.riskScore}`,
          aiImpact: {
            riskDelta: after.riskScore - before.riskScore,
          },
          createdBy: "ai",
        }
      );
    }
    return null;
  });
