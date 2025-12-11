/**
 * functions/src/billing/create_payment_link.ts
 *
 * Automatically creates a Stripe payment link when an invoice is created
 * 
 * Triggers: onCreate for users/{userId}/invoices/{invoiceId}
 * Creates: Stripe Product, Price, and Payment Link
 * Updates: Invoice document with payment link and Stripe IDs
 */

import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Stripe from "stripe";

const db = admin.firestore();

// Initialize Stripe with config or environment variable
const STRIPE_SECRET =
  functions.config()?.stripe?.secret || process.env.STRIPE_SECRET_KEY || "";

let stripe: Stripe | null = null;
if (STRIPE_SECRET) {
  stripe = new Stripe(STRIPE_SECRET, { apiVersion: "2022-11-15" });
}

export const createPaymentLinkOnInvoiceCreate = functions.firestore
  .document("users/{userId}/invoices/{invoiceId}")
  .onCreate(async (snap, context) => {
    if (!stripe) {
      console.warn("⚠️ Stripe not configured. Skipping payment link creation.");
      return;
    }

    const data = snap.data();
    const { userId, invoiceId } = context.params;

    if (!data || data.paymentLink) {
      console.log("⏭ Invoice already has payment link or no data");
      return;
    }

    try {
      const amount = Math.round((data.totals?.total || data.amount || 0) * 100);
      const currency = (data.currency || "USD").toLowerCase();

      // Create Stripe Product
      const product = await stripe.products.create({
        name: data.title || `Invoice ${invoiceId}`,
        metadata: {
          userId,
          invoiceId,
        },
      });

      // Create Stripe Price
      const price = await stripe.prices.create({
        product: product.id,
        unit_amount: amount,
        currency,
      });

      // Create Payment Link
      const paymentLink = await stripe.paymentLinks.create({
        line_items: [{ price: price.id, quantity: 1 }],
        metadata: {
          userId,
          invoiceId,
        },
        after_completion: {
          type: "redirect",
          redirect: {
            url: `https://app.aurasphere.com/invoices/${invoiceId}?status=success`,
          },
        },
      });

      // Update invoice with payment details
      await snap.ref.update({
        paymentLink: paymentLink.url,
        stripePriceId: price.id,
        stripeProductId: product.id,
        paymentStatus: "pending",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });

      console.log(`✅ Payment link created for invoice ${invoiceId}: ${paymentLink.url}`);
    } catch (error) {
      console.error(`❌ Error creating payment link for ${invoiceId}:`, error);
      
      // Update invoice with error status
      await snap.ref.update({
        paymentLinkError: error instanceof Error ? error.message : "Unknown error",
        paymentStatus: "error",
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      });
    }
  });
