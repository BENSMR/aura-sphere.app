import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Stripe from "stripe";

// Initialize admin if not already initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// Read secret from functions config (set with: firebase functions:config:set stripe.secret="sk_...")
const stripeSecret = functions.config()?.stripe?.secret;
if (!stripeSecret) {
  console.warn("Stripe secret not set in functions config. Set it with: firebase functions:config:set stripe.secret=\"sk_xxx\"");
}

const stripe = new Stripe(stripeSecret || "", { apiVersion: "2024-04-10" });

/**
 * Callable function: createCheckoutSession
 * Expects:
 *   { invoiceId: string, successUrl?: string, cancelUrl?: string }
 *
 * Returns:
 *   { url: string, id: string }
 */
export const createCheckoutSession = functions
  .runWith({ memory: "1GB", timeoutSeconds: 60 })
  .https.onCall(async (data, context) => {
    try {
      if (!context.auth || !context.auth.uid) {
        throw new functions.https.HttpsError("unauthenticated", "User must be authenticated");
      }
      const uid = context.auth.uid;
      const invoiceId = data?.invoiceId;
      const successUrl = data?.successUrl || functions.config()?.app?.success_url || "https://example.com/success";
      const cancelUrl = data?.cancelUrl || functions.config()?.app?.cancel_url || "https://example.com/cancel";

      if (!invoiceId) {
        throw new functions.https.HttpsError("invalid-argument", "invoiceId is required");
      }

      const invRef = admin.firestore().collection("users").doc(uid).collection("invoices").doc(invoiceId);
      const invSnap = await invRef.get();
      if (!invSnap.exists) {
        throw new functions.https.HttpsError("not-found", "Invoice not found");
      }

      const invoice = invSnap.data() as any;
      const total = Number(invoice?.total ?? 0);
      if (isNaN(total) || total <= 0) {
        throw new functions.https.HttpsError("failed-precondition", "Invoice total invalid");
      }

      // Stripe expects amounts in smallest currency unit (cents)
      // NOTE: currency handling should be enhanced for non-decimal currencies
      const currency = (invoice?.currency ?? "EUR").toString().toLowerCase();
      const amount = Math.round(total * 100);

      // Create a simple one-line Checkout session
      const session = await stripe.checkout.sessions.create({
        payment_method_types: ["card"],
        mode: "payment",
        line_items: [
          {
            price_data: {
              currency,
              product_data: {
                name: `Invoice ${invoice?.invoiceNumber ?? invoiceId}`,
                description: invoice?.description ?? `Invoice for ${invoice?.customerName ?? "client"}`,
              },
              unit_amount: amount,
            },
            quantity: 1,
          },
        ],
        metadata: {
          uid,
          invoiceId,
        },
        success_url: successUrl,
        cancel_url: cancelUrl,
      });

      // Save session id to invoice for reconciliation (optional)
      await invRef.set({ lastCheckoutSessionId: session.id }, { merge: true });

      return { url: session.url, id: session.id };
    } catch (err: any) {
      console.error("createCheckoutSession error:", err);
      if (err instanceof functions.https.HttpsError) throw err;
      throw new functions.https.HttpsError("internal", err?.message || "Internal error");
    }
  });
