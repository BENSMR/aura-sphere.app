import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Stripe from "stripe";

const db = admin.firestore();

const STRIPE_SECRET = functions.config().stripe?.secret || process.env.STRIPE_SECRET;
const STRIPE_WEBHOOK_SECRET = functions.config().stripe?.webhook_secret || process.env.STRIPE_WEBHOOK_SECRET;
const stripe = new Stripe(STRIPE_SECRET || "", { apiVersion: "2022-11-15" });

export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers["stripe-signature"] as string | undefined;
  let event: Stripe.Event;

  try {
    if (STRIPE_WEBHOOK_SECRET) {
      event = stripe.webhooks.constructEvent(req.rawBody as Buffer, sig || "", STRIPE_WEBHOOK_SECRET);
    } else {
      // If webhook secret not set, try parsing (development only - not recommended for prod)
      event = req.body;
    }
  } catch (err: any) {
    console.error("Webhook signature verification failed:", err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  try {
    switch (event.type) {
      case "checkout.session.completed": {
        const session = event.data.object as Stripe.Checkout.Session;
        const invoiceId = session.metadata?.invoiceId;
        const userId = session.metadata?.userId;
        const paymentIntentId = session.payment_intent as string | undefined;

        if (!invoiceId) {
          console.warn("⚠️ Invoice ID missing from session metadata");
          break;
        }

        const invoiceRef = db.collection("invoices").doc(invoiceId);

        // 1. Fetch PaymentIntent to verify actual charge details
        if (!paymentIntentId) {
          console.error("❌ PaymentIntent ID missing from session");
          break;
        }

        let paymentIntent: Stripe.PaymentIntent;

        try {
          paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);
        } catch (err) {
          console.error("❌ Failed to retrieve PaymentIntent:", paymentIntentId, err);
          break;
        }

        if (paymentIntent.status !== "succeeded") {
          console.warn("⚠️ PaymentIntent not succeeded:", paymentIntentId, paymentIntent.status);
          break; // do not mark invoice paid
        }

        // 2. Calculate invoice total from Firestore
        const invoiceSnap = await invoiceRef.get();
        if (!invoiceSnap.exists) {
          console.error("❌ Invoice not found:", invoiceId);
          break;
        }

        const invoiceData = invoiceSnap.data() as any;
        const expectedTotal = Math.round((invoiceData.total || 0) * 100); // to cents
        const chargedTotal = paymentIntent.amount_received;

        // 3. Secure numeric comparison
        if (expectedTotal !== chargedTotal) {
          console.error("❌ PAYMENT MISMATCH DETECTED", {
            invoiceId,
            expectedTotal,
            chargedTotal,
            paymentIntentId,
          });

          // Log mismatch but DO NOT mark invoice paid
          await invoiceRef.collection("paymentErrors").doc(paymentIntentId || "unknown").set({
            issue: "amount_mismatch",
            expectedTotal,
            chargedTotal,
            createdAt: admin.firestore.FieldValue.serverTimestamp(),
          });

          break; // stop processing
        }

        // 4. Amount is correct → mark invoice paid
        await invoiceRef.set({
          paymentStatus: "paid",
          paidAt: admin.firestore.FieldValue.serverTimestamp(),
          paymentMethod: "stripe",
          lastPaymentIntentId: paymentIntentId,
          paidAmount: chargedTotal / 100,
          paidCurrency: paymentIntent.currency,
          paymentVerified: true,
        }, { merge: true });

        // 5. Save secure audit record
        await invoiceRef.collection("payments").doc(paymentIntentId || session.id).set({
          type: "stripe_checkout",
          sessionId: session.id,
          paymentIntentId,
          amount: chargedTotal / 100,
          currency: paymentIntent.currency,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
          verified: true,
          metadata: session.metadata || {},
        });

        console.log("✅ Invoice verified & paid:", invoiceId);

        break;
      }
      default:
        console.log(`Unhandled event type ${event.type}`);
    }

    res.json({ received: true });
  } catch (err) {
    console.error("Processing webhook failed:", err);
    res.status(500).send();
  }
});
