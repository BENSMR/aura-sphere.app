/**
 * STRIPE PAYMENT FUNCTIONS
 * 
 * Cloud Functions for:
 * - Creating payment intents
 * - Managing subscriptions
 * - Processing webhooks
 * - Billing operations
 */

import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import { logger } from 'firebase-functions';

const db = admin.firestore();
const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2022-11-15'
});

// Ensure Firebase is initialized
if (!admin.apps.length) {
  admin.initializeApp();
}

// ─────────────────────────────────────────────────────────────────────────
// CREATE PAYMENT INTENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Creates a payment intent for subscription purchase
 * Callable function: stripe_createPaymentIntent
 */
export const stripe_createPaymentIntent = functions.https.onCall(
  async (data, context) => {
    // Verify authentication
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    const userId = context.auth.uid;
    const { amount, tierId, billingCycle, description } = data;

    // Validate input
    if (!amount || amount < 100) {
      throw new functions.https.HttpsError('invalid-argument', 'Invalid amount');
    }
    if (!tierId) {
      throw new functions.https.HttpsError('invalid-argument', 'Tier ID required');
    }

    try {
      // Get or create Stripe customer
      let customerId = await getOrCreateStripeCustomer(userId);

      // Create payment intent
      const paymentIntent = await stripe.paymentIntents.create({
        amount,
        currency: 'usd',
        customer: customerId,
        description: description || `AuraSphere ${tierId}`,
        metadata: {
          userId,
          tierId,
          billingCycle
        },
        automatic_payment_methods: {
          enabled: true
        }
      });

      // Log payment intent creation
      logger.info('Payment intent created', {
        userId,
        paymentIntentId: paymentIntent.id,
        amount,
        tierId
      });

      return {
        clientSecret: paymentIntent.client_secret,
        paymentIntentId: paymentIntent.id
      };
    } catch (error: any) {
      logger.error('Failed to create payment intent', { userId, error: error?.message || "Error" });
      throw new functions.https.HttpsError('internal', error?.message || "Error" || 'Payment failed');
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────
// CONFIRM PAYMENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Confirms payment and updates user subscription
 * Callable function: stripe_confirmPayment
 */
export const stripe_confirmPayment = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    const userId = context.auth.uid;
    const { clientSecret, tierId } = data;

    if (!clientSecret || !tierId) {
      throw new functions.https.HttpsError('invalid-argument', 'Missing required fields');
    }

    try {
      // Extract payment intent ID from client secret
      const paymentIntentId = clientSecret.split('_secret_')[0];

      // Retrieve payment intent from Stripe
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentIntentId);

      // Verify payment succeeded
      if (paymentIntent.status !== 'succeeded') {
        throw new Error(`Payment not succeeded. Status: ${paymentIntent.status}`);
      }

      // Update user subscription in Firestore
      const userRef = db.collection('users').doc(userId);
      await userRef.update({
        'subscription.tierId': tierId,
        'subscription.status': 'active',
        'subscription.lastPaymentDate': admin.firestore.FieldValue.serverTimestamp(),
        'subscription.stripeCustomerId': paymentIntent.customer,
        'subscription.paymentIntentId': paymentIntentId
      });

      // Record payment in payment history
      await db.collection('users').doc(userId).collection('payments').add({
        paymentIntentId,
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
        tierId,
        status: 'succeeded',
        timestamp: admin.firestore.FieldValue.serverTimestamp(),
        chargeId: (paymentIntent as any)?.charges?.data?.[0]?.id || null
      });

      logger.info('Payment confirmed', {
        userId,
        tierId,
        amount: paymentIntent.amount
      });

      return {
        success: true,
        message: 'Payment successful',
        tierId,
        subscriptionStatus: 'active'
      };
    } catch (error: any) {
      logger.error('Failed to confirm payment', { userId, error: error?.message || "Error" });
      throw new functions.https.HttpsError('internal', error?.message || "Error");
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────
// CREATE SUBSCRIPTION
// ─────────────────────────────────────────────────────────────────────────

/**
 * Creates a recurring subscription
 * Callable function: stripe_createSubscription
 */
export const stripe_createSubscription = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    const userId = context.auth.uid;
    const { tierId, billingCycle, paymentMethodId } = data;

    try {
      // Get or create Stripe customer
      let customerId = await getOrCreateStripeCustomer(userId);

      // Attach payment method to customer
      if (paymentMethodId) {
        await stripe.paymentMethods.attach(paymentMethodId, {
          customer: customerId
        });

        // Set as default
        await stripe.customers.update(customerId, {
          invoice_settings: {
            default_payment_method: paymentMethodId
          }
        });
      }

      // Get subscription tier price ID
      const priceId = getPriceIdForTier(tierId, billingCycle);

      // Create subscription
      const subscription = await stripe.subscriptions.create({
        customer: customerId,
        items: [{ price: priceId }],
        metadata: {
          userId,
          tierId
        },
        payment_settings: {
          payment_method_types: ['card'],
          save_default_payment_method: 'on_subscription'
        }
      });

      // Update user in Firestore
      await db.collection('users').doc(userId).update({
        'subscription.tierId': tierId,
        'subscription.status': subscription.status,
        'subscription.stripeSubscriptionId': subscription.id,
        'subscription.stripeCustomerId': customerId,
        'subscription.billingCycle': billingCycle,
        'subscription.currentPeriodStart': new Date(subscription.current_period_start * 1000),
        'subscription.currentPeriodEnd': new Date(subscription.current_period_end * 1000),
        'subscription.startDate': admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Subscription created', {
        userId,
        tierId,
        billingCycle,
        subscriptionId: subscription.id
      });

      return {
        success: true,
        subscriptionId: subscription.id,
        status: subscription.status,
        message: 'Subscription created successfully'
      };
    } catch (error: any) {
      logger.error('Failed to create subscription', { userId, error: error?.message || "Error" });
      throw new functions.https.HttpsError('internal', error?.message || "Error");
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────
// UPDATE SUBSCRIPTION
// ─────────────────────────────────────────────────────────────────────────

/**
 * Updates subscription tier (upgrade/downgrade)
 * Callable function: stripe_updateSubscription
 */
export const stripe_updateSubscription = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    const userId = context.auth.uid;
    const { newTierId } = data;

    try {
      // Get user's current subscription
      const userDoc = await db.collection('users').doc(userId).get();
      const currentSubscription = userDoc.data()?.subscription;

      if (!currentSubscription?.stripeSubscriptionId) {
        throw new Error('No active subscription found');
      }

      // Get new price ID
      const newPriceId = getPriceIdForTier(
        newTierId,
        currentSubscription.billingCycle
      );

      // Update subscription
      const subscription = await stripe.subscriptions.update(
        currentSubscription.stripeSubscriptionId,
        {
          items: [
            {
              id: currentSubscription.stripeSubscriptionItemId,
              price: newPriceId
            }
          ],
          metadata: { tierId: newTierId }
        }
      );

      // Update Firestore
      await db.collection('users').doc(userId).update({
        'subscription.tierId': newTierId,
        'subscription.status': subscription.status
      });

      logger.info('Subscription updated', {
        userId,
        oldTierId: currentSubscription.tierId,
        newTierId
      });

      return {
        success: true,
        tierId: newTierId,
        message: 'Subscription updated successfully'
      };
    } catch (error: any) {
      logger.error('Failed to update subscription', { userId, error: error?.message || "Error" });
      throw new functions.https.HttpsError('internal', error?.message || "Error");
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────
// CANCEL SUBSCRIPTION
// ─────────────────────────────────────────────────────────────────────────

/**
 * Cancels subscription
 * Callable function: stripe_cancelSubscription
 */
export const stripe_cancelSubscription = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    const userId = context.auth.uid;

    try {
      const userDoc = await db.collection('users').doc(userId).get();
      const subscriptionId = userDoc.data()?.subscription?.stripeSubscriptionId;

      if (!subscriptionId) {
        throw new Error('No active subscription found');
      }

      // Cancel subscription
      const subscription = await stripe.subscriptions.del(subscriptionId);

      // Update Firestore
      await db.collection('users').doc(userId).update({
        'subscription.status': 'canceled',
        'subscription.canceledAt': admin.firestore.FieldValue.serverTimestamp()
      });

      logger.info('Subscription canceled', { userId });

      return {
        success: true,
        message: 'Subscription canceled'
      };
    } catch (error: any) {
      logger.error('Failed to cancel subscription', { userId, error: error?.message || "Error" });
      throw new functions.https.HttpsError('internal', error?.message || "Error");
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────
// PAYMENT METHODS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Save payment method
 * Callable function: stripe_savePaymentMethod
 */
export const stripe_savePaymentMethod = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    const userId = context.auth.uid;
    const { paymentMethodId, makeDefault } = data;

    try {
      const customerId = await getOrCreateStripeCustomer(userId);

      // Attach payment method
      await stripe.paymentMethods.attach(paymentMethodId, {
        customer: customerId
      });

      // Save to Firestore
      await db.collection('users').doc(userId).collection('paymentMethods').add({
        stripePaymentMethodId: paymentMethodId,
        isDefault: makeDefault || false,
        createdAt: admin.firestore.FieldValue.serverTimestamp()
      });

      if (makeDefault) {
        await stripe.customers.update(customerId, {
          invoice_settings: {
            default_payment_method: paymentMethodId
          }
        });
      }

      return { success: true, message: 'Payment method saved' };
    } catch (error: any) {
      logger.error('Failed to save payment method', { userId, error: error?.message || "Error" });
      throw new functions.https.HttpsError('internal', error?.message || "Error");
    }
  }
);

/**
 * Delete payment method
 * Callable function: stripe_deletePaymentMethod
 */
export const stripe_deletePaymentMethod = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    const userId = context.auth.uid;
    const { paymentMethodId } = data;

    try {
      await stripe.paymentMethods.detach(paymentMethodId);

      // Remove from Firestore
      const snapshot = await db
        .collection('users')
        .doc(userId)
        .collection('paymentMethods')
        .where('stripePaymentMethodId', '==', paymentMethodId)
        .get();

      snapshot.docs.forEach(doc => doc.ref.delete());

      return { success: true, message: 'Payment method deleted' };
    } catch (error: any) {
      logger.error('Failed to delete payment method', { userId, error: error?.message || "Error" });
      throw new functions.https.HttpsError('internal', error?.message || "Error");
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────
// BILLING PORTAL & INVOICES
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get Stripe billing portal session
 * Callable function: stripe_getBillingPortalUrl
 */
export const stripe_getBillingPortalUrl = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    const userId = context.auth.uid;

    try {
      const customerId = await getOrCreateStripeCustomer(userId);

      const session = await stripe.billingPortal.sessions.create({
        customer: customerId,
        return_url: 'https://aura-sphere.app/account/billing' // Update to your domain
      });

      return { url: session.url };
    } catch (error: any) {
      logger.error('Failed to get billing portal URL', { userId, error: error?.message || "Error" });
      throw new functions.https.HttpsError('internal', error?.message || "Error");
    }
  }
);

/**
 * Get invoice
 * Callable function: stripe_getInvoice
 */
export const stripe_getInvoice = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    const { invoiceId } = data;

    try {
      const invoice = await stripe.invoices.retrieve(invoiceId);

      return {
        id: invoice.id,
        number: invoice.number,
        amount: invoice.amount_paid,
        date: new Date(invoice.created * 1000),
        pdfUrl: (invoice as any).pdf || invoice.hosted_invoice_url || null,
        status: invoice.status
      };
    } catch (error: any) {
      logger.error('Failed to get invoice', { error: error?.message || "Error" });
      throw new functions.https.HttpsError('internal', error?.message || "Error");
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────
// REFUNDS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Process refund (admin only)
 * Callable function: stripe_refund
 */
export const stripe_refund = functions.https.onCall(
  async (data, context) => {
    if (!context.auth) {
      throw new functions.https.HttpsError('unauthenticated', 'Must be logged in');
    }

    // Check if user is admin
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    if (userDoc.data()?.role !== 'owner') {
      throw new functions.https.HttpsError('permission-denied', 'Admin access required');
    }

    const { paymentIntentId, amount, reason } = data;

    try {
      const refund = await stripe.refunds.create({
        payment_intent: paymentIntentId,
        amount: amount || undefined,
        reason: reason || 'requested_by_customer'
      });

      logger.info('Refund processed', {
        paymentIntentId,
        refundId: refund.id
      });

      return {
        success: true,
        refundId: refund.id,
        amount: refund.amount
      };
    } catch (error: any) {
      logger.error('Failed to process refund', { error: error?.message || "Error" });
      throw new functions.https.HttpsError('internal', error?.message || "Error");
    }
  }
);

// ─────────────────────────────────────────────────────────────────────────
// WEBHOOKS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Webhook handler for Stripe events
 * HTTP function: stripe_webhook
 */
export const stripe_webhook = functions.https.onRequest(async (req, res): Promise<void> => {
  const sig = req.headers['stripe-signature'] || '';
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';

  let event;

  try {
    event = stripe.webhooks.constructEvent(req.rawBody, sig, webhookSecret);
  } catch (error: any) {
    logger.error('Webhook signature verification failed', { error: error?.message || "Error" });
    res.status(400).send('Webhook Error');
    return;
  }

  try {
    switch (event.type) {
      case 'invoice.paid':
        await handleInvoicePaid(event.data.object);
        break;

      case 'invoice.payment_failed':
        await handleInvoicePaymentFailed(event.data.object);
        break;

      case 'customer.subscription.updated':
        await handleSubscriptionUpdated(event.data.object);
        break;

      case 'customer.subscription.deleted':
        await handleSubscriptionDeleted(event.data.object);
        break;

      case 'charge.refunded':
        await handleChargeRefunded(event.data.object);
        break;

      default:
        logger.info('Unhandled webhook event', { type: event.type });
    }

    res.json({ received: true });
  } catch (error: any) {
    logger.error('Webhook processing failed', { error: error?.message || "Error" });
    res.status(500).send('Webhook processing failed');
  }
});

// ─────────────────────────────────────────────────────────────────────────
// WEBHOOK HANDLERS
// ─────────────────────────────────────────────────────────────────────────

async function handleInvoicePaid(invoice: any) {
  const userId = invoice.metadata?.userId;
  if (!userId) return;

  await db.collection('users').doc(userId).update({
    'subscription.status': 'active',
    'subscription.lastPaymentDate': admin.firestore.FieldValue.serverTimestamp()
  });

  logger.info('Invoice paid', { userId, invoiceId: invoice.id });
}

async function handleInvoicePaymentFailed(invoice: any) {
  const userId = invoice.metadata?.userId;
  if (!userId) return;

  await db.collection('users').doc(userId).update({
    'subscription.status': 'past_due',
    'subscription.paymentFailedAt': admin.firestore.FieldValue.serverTimestamp()
  });

  logger.warn('Invoice payment failed', { userId, invoiceId: invoice.id });
}

async function handleSubscriptionUpdated(subscription: any) {
  const userId = subscription.metadata?.userId;
  if (!userId) return;

  await db.collection('users').doc(userId).update({
    'subscription.status': subscription.status,
    'subscription.currentPeriodEnd': new Date(subscription.current_period_end * 1000)
  });

  logger.info('Subscription updated', { userId, status: subscription.status });
}

async function handleSubscriptionDeleted(subscription: any) {
  const userId = subscription.metadata?.userId;
  if (!userId) return;

  await db.collection('users').doc(userId).update({
    'subscription.status': 'canceled',
    'subscription.canceledAt': admin.firestore.FieldValue.serverTimestamp()
  });

  logger.info('Subscription deleted', { userId });
}

async function handleChargeRefunded(charge: any) {
  logger.info('Charge refunded', { chargeId: charge.id, amount: charge.amount_refunded });
}

// ─────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get or create Stripe customer for user
 */
async function getOrCreateStripeCustomer(userId: string): Promise<string> {
  const userDoc = await db.collection('users').doc(userId).get();
  const userData = userDoc.data();

  // Return existing customer ID
  if (userData?.stripeCustomerId) {
    return userData.stripeCustomerId;
  }

  // Create new customer
  const customer = await stripe.customers.create({
    metadata: { userId },
    email: userData?.email,
    name: userData?.displayName || userData?.businessName
  });

  // Save customer ID
  await db.collection('users').doc(userId).update({
    stripeCustomerId: customer.id
  });

  return customer.id;
}

/**
 * Get Stripe price ID for tier and billing cycle
 * Maps tierId + billingCycle to Stripe price IDs
 */
function getPriceIdForTier(tierId: string, billingCycle: string): string {
  // These IDs come from your Stripe dashboard
  // Set STRIPE_PRICE_IDS environment variable or hardcode here
  const priceMap: Record<string, Record<string, string>> = {
    solo: {
      monthly: process.env.STRIPE_PRICE_SOLO_MONTHLY || 'price_1234567890abcdef',
      yearly: process.env.STRIPE_PRICE_SOLO_YEARLY || 'price_0987654321fedcba'
    },
    team: {
      monthly: process.env.STRIPE_PRICE_TEAM_MONTHLY || 'price_1234567890abcdef',
      yearly: process.env.STRIPE_PRICE_TEAM_YEARLY || 'price_0987654321fedcba'
    },
    business: {
      monthly: process.env.STRIPE_PRICE_BUSINESS_MONTHLY || 'price_1234567890abcdef',
      yearly: process.env.STRIPE_PRICE_BUSINESS_YEARLY || 'price_0987654321fedcba'
    }
  };

  return priceMap[tierId]?.[billingCycle] || '';
}

export default {
  stripe_createPaymentIntent,
  stripe_confirmPayment,
  stripe_createSubscription,
  stripe_updateSubscription,
  stripe_cancelSubscription,
  stripe_savePaymentMethod,
  stripe_deletePaymentMethod,
  stripe_getBillingPortalUrl,
  stripe_getInvoice,
  stripe_refund,
  stripe_webhook
};
