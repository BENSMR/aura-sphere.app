import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Stripe from "stripe";

const db = admin.firestore();

const STRIPE_SECRET = functions.config().stripe?.secret || process.env.STRIPE_SECRET;
if (!STRIPE_SECRET) {
  console.error("❌ STRIPE SECRET not found. Set functions config: firebase functions:config:set stripe.secret=\"sk_...\"");
}
const stripe = new Stripe(STRIPE_SECRET || "", { apiVersion: "2024-04-10" });

export const createCheckoutSession = functions.https.onCall(async (data, context) => {
  try {
    if (!context.auth) {
      throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
    }

    const userId = context.auth.uid;
    const { invoiceId, successUrl, cancelUrl } = data;
    if (!invoiceId) {
      throw new functions.https.HttpsError("invalid-argument", "invoiceId is required");
    }

    // Load invoice document
    const invoiceDoc = await db.collection("invoices").doc(invoiceId).get();
    if (!invoiceDoc.exists) {
      throw new functions.https.HttpsError("not-found", "Invoice not found");
    }
    const invoice = invoiceDoc.data() as any;

    // Build line items from invoice
    const line_items = (invoice.items || []).map((it: any) => {
      const qty = Number(it.quantity || 1);
      const unit = Number(it.unitPrice || 0);
      const name = it.name || "Item";
      const amount = Math.round(unit * 100); // convert to cents
      return {
        price_data: {
          currency: (invoice.currency || "eur").toLowerCase(),
          product_data: { name },
          unit_amount: amount,
        },
        quantity: qty,
      };
    });

    // fallback single item if no items
    if (line_items.length === 0) {
      const total = Math.round((invoice.total || 0) * 100);
      line_items.push({
        price_data: {
          currency: (invoice.currency || "eur").toLowerCase(),
          product_data: { name: invoice.invoiceNumber || "Invoice" },
          unit_amount: total,
        },
        quantity: 1,
      });
    }

    // Create Stripe Checkout session
    const session = await stripe.checkout.sessions.create({
      payment_method_types: ["card"],
      mode: "payment",
      line_items,
      metadata: {
        invoiceId: invoiceId,
        userId: userId
      },
      success_url: successUrl || "https://yourapp.com/pay-success?session_id={CHECKOUT_SESSION_ID}",
      cancel_url: cancelUrl || "https://yourapp.com/pay-cancel",
    });

    // Save a pointer on invoice for traceability (not authoritative)
    await db.collection("invoices").doc(invoiceId).set({
      lastCheckoutSessionId: session.id,
      lastCheckoutCreatedAt: admin.firestore.FieldValue.serverTimestamp(),
    }, { merge: true });

    return { success: true, url: session.url, sessionId: session.id };
  } catch (err: any) {
    console.error("createCheckoutSession error:", err);
    throw new functions.https.HttpsError("internal", err.message || "Failed to create session");
  }
});
