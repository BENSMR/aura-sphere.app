import * as functions from "firebase-functions";
import * as admin from "firebase-admin";
import Stripe from "stripe";
import express from "express";
import bodyParser from "body-parser";
import * as pdfkit from "pdfkit";
import * as StreamBuffers from "stream-buffers";
import sgMail from "@sendgrid/mail";

if (!admin.apps.length) {
  admin.initializeApp();
}

const stripeSecret = functions.config()?.stripe?.secret || "";
const webhookSecret = functions.config()?.stripe?.webhook_secret || "";
const sendgridKey = functions.config()?.sendgrid?.key || "";
const sendgridSender = functions.config()?.sendgrid?.sender || "";

if (sendgridKey) {
  sgMail.setApiKey(sendgridKey);
} else {
  console.warn("SendGrid key not set. Set with: firebase functions:config:set sendgrid.key=\"SG...\" sendgrid.sender=\"no-reply@yourdomain.com\"");
}

const stripe = new Stripe(stripeSecret, { apiVersion: "2024-04-10" });

// Express app to handle raw body required by Stripe signature verification
const app = express();
// Stripe requires the raw body to validate the signature. We use the raw body parser for the webhook route only.
app.post('/webhook', bodyParser.raw({ type: 'application/json' }), async (req, res) => {
  const sig = req.headers['stripe-signature'] as string | undefined;
  if (!sig) {
    console.error('Missing stripe-signature header');
    return res.status(400).send('Missing signature');
  }

  let event: Stripe.Event;
  try {
    event = stripe.webhooks.constructEvent(req.body as Buffer, sig, webhookSecret);
  } catch (err: any) {
    console.error('Webhook signature verification failed:', err?.message);
    return res.status(400).send(`Webhook Error: ${err?.message}`);
  }

  // Handle the event types we care about
  try {
    switch (event.type) {
      case 'checkout.session.completed':
        {
          const session = event.data.object as Stripe.Checkout.Session;
          const metadata = session.metadata || {};
          const uid = metadata.uid;
          const invoiceId = metadata.invoiceId;
          console.log(`checkout.session.completed for uid=${uid} invoiceId=${invoiceId}`);

          if (uid && invoiceId) {
            const invRef = admin.firestore().collection('users').doc(uid).collection('invoices').doc(invoiceId);
            const paymentId = (session.payment_intent as string | undefined) || session.id;
            const paymentsRef = invRef.collection('payments').doc(paymentId);

            // Create detailed payment record with full schema
            const paymentRecord = {
              // Core fields
              amount: session.amount_total || 0,
              currency: session.currency || 'usd',
              provider: 'stripe',
              status: 'succeeded',
              paidAt: admin.firestore.FieldValue.serverTimestamp(),

              // Stripe fields
              stripeSessionId: session.id,
              stripePaymentIntent: session.payment_intent || null,
              stripeCustomerId: session.customer || null,

              // Payment method (card)
              method: 'card',
              cardBrand: session.payment_method_types?.[0] || 'unknown',
              last4: '0000', // Placeholder - Stripe doesn't expose in session object
              expMonth: null,
              expYear: null,
              fingerprint: null,

              // Tax breakdown
              taxBreakdown: {
                subtotal: session.amount_subtotal || 0,
                taxRate: 0.0,
                taxAmount: (session.amount_total || 0) - (session.amount_subtotal || 0),
                total: session.amount_total || 0
              },

              // Customer info
              email: session.customer_email || session.customer_details?.email || '',

              // Metadata for reference
              metadata: {
                invoiceId: invoiceId,
                uid: uid,
                invoiceNumber: metadata.invoiceNumber || null
              }
            };

            // Save payment record
            await paymentsRef.set(paymentRecord);
            console.log(`Payment record created: ${paymentId}`);

            // Try to send receipt email via SendGrid (if configured)
            const customerEmail = session.customer_email || session.customer_details?.email;
            if (sendgridKey && sendgridSender && customerEmail) {
              try {
                // Fetch invoice for receipt details
                const invSnap = await invRef.get();
                const invData = invSnap.exists ? invSnap.data() : {};

                // Build a simple PDF in memory
                const doc = new (pdfkit as any)();
                const stream = new StreamBuffers.WritableStreamBuffer({
                  initialSize: (100 * 1024),
                  incrementAmount: (10 * 1024)
                });
                doc.pipe(stream);
                doc.fontSize(20).text('Payment Receipt', { align: 'center' });
                doc.moveDown();
                doc.fontSize(12).text(`Invoice: ${invData?.invoiceNumber ?? invoiceId}`);
                doc.text(`Amount: ${((session.amount_total ?? 0)/100).toFixed(2)} ${session.currency?.toUpperCase() ?? ''}`);
                doc.text(`Date: ${(new Date()).toLocaleString()}`);
                doc.moveDown();
                doc.text('Thank you for your payment.');
                doc.end();

                const pdfBuffer = stream.getContents() as Buffer;

                const msg = {
                  to: customerEmail,
                  from: sendgridSender,
                  subject: `Receipt - ${invData?.invoiceNumber ?? invoiceId}`,
                  text: `Thank you. Attached is your receipt for invoice ${invData?.invoiceNumber ?? invoiceId}.`,
                  attachments: [
                    {
                      content: pdfBuffer.toString('base64'),
                      filename: `receipt-${invData?.invoiceNumber ?? invoiceId}.pdf`,
                      type: 'application/pdf',
                      disposition: 'attachment'
                    }
                  ]
                };

                await sgMail.send(msg);
                console.log(`Receipt emailed to ${customerEmail}`);
              } catch (err) {
                console.error('Failed to send receipt email:', err);
              }
            }

            // Mark invoice as paid with payment info
            await invRef.set({
              paymentVerified: true,
              paidAt: admin.firestore.FieldValue.serverTimestamp(),
              lastPaymentProvider: 'stripe',
              lastCheckoutSessionId: session.id,
              lastPaymentIntentId: session.payment_intent || null,
              paymentMetadata: {
                payment_intent: session.payment_intent ?? null,
                amount_total: session.amount_total ?? null,
                currency: session.currency ?? null
              }
            }, { merge: true });
            console.log(`Invoice ${invoiceId} for user ${uid} marked as paid.`);
          } else {
            console.warn('Missing metadata on session; cannot reconcile invoice.');
          }
        }
        break;
      case 'payment_intent.succeeded':
        {
          // optional: additional handling for payment intents
          console.log('payment_intent.succeeded');
        }
        break;
      default:
        console.log(`Unhandled event type ${event.type}`);
    }
  } catch (err) {
    console.error('Error processing webhook event:', err);
    return res.status(500).send('Server error');
  }

  res.json({ received: true });
});

// Export as a Cloud Function (Express)
export const stripeWebhook = functions.https.onRequest(app);
