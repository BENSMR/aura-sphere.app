/**
 * functions/src/crm/auto_invoice_on_deal_won.ts
 *
 * Automatically creates a draft invoice when a deal is marked as "won"
 * 
 * Triggers: onUpdate for users/{userId}/deals/{dealId}
 * Creates: Draft invoice with deal data
 * Prevents: Duplicate invoices via dealId check
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";

const db = admin.firestore();

export const autoCreateInvoiceOnWonDeal = functions.firestore
  .document("users/{userId}/deals/{dealId}")
  .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();

    if (!before || !after) return;

    // Only trigger when stage changes TO "won"
    if (before.stage === "won" || after.stage !== "won") {
      return;
    }

    const { userId, dealId } = context.params;

    const clientId = after.clientId;
    const amount = after.amount ?? 0;
    const title = after.title ?? "Deal Invoice";

    console.log(`✅ Deal ${dealId} marked as WON → Creating invoice`);

    // 🔎 Prevent duplicate invoice
    const existing = await db
      .collection("users")
      .doc(userId)
      .collection("invoices")
      .where("dealId", "==", dealId)
      .limit(1)
      .get();

    if (!existing.empty) {
      console.log("⏭ Invoice already exists for this deal.");
      return;
    }

    // 📄 CREATE INVOICE
    const invoicePayload = {
      dealId,
      clientId,
      title,
      amount,
      status: "draft",
      currency: after.currency ?? "USD",
      issuedAt: admin.firestore.FieldValue.serverTimestamp(),
      dueAt: admin.firestore.FieldValue.serverTimestamp(),
      createdBy: "system",
      createdFrom: "auto_deal_close",
      items: [
        {
          name: title,
          quantity: 1,
          unitPrice: amount,
          total: amount,
        },
      ],
      totals: {
        subtotal: amount,
        tax: 0,
        total: amount,
      },
    };

    const invoiceRef = await db
      .collection("users")
      .doc(userId)
      .collection("invoices")
      .add(invoicePayload);

    // 🧠 TIMELINE EVENT
    if (clientId) {
      await db
        .collection("users")
        .doc(userId)
        .collection("clients")
        .doc(clientId)
        .collection("timeline")
        .add({
          type: "system",
          title: "Invoice created automatically",
          description: `Invoice generated from won deal: ${title}`,
          relatedDealId: dealId,
          relatedInvoiceId: invoiceRef.id,
          sourceId: invoiceRef.id,
          createdBy: "system",
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });
    }

    console.log(`✅ Invoice ${invoiceRef.id} created from Deal ${dealId}`);
    return;
  });
