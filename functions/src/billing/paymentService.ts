import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import { logger } from './utils/logger';
import { validateExpense } from './finance/expenseValidator';

const stripe = new Stripe(
  process.env.STRIPE_SECRET_KEY || '',
  { apiVersion: '2023-10-16' }
);

/**
 * Create Payment Intent with Idempotency
 * 
 * Creates a Stripe PaymentIntent with idempotency key support to prevent
 * duplicate charges from network retries or user button clicks.
 * 
 * IMPORTANT: Idempotency keys ensure that:
 * - Multiple requests with same key return same result
 * - No duplicate charges even if request is retried
 * - Safe for unreliable networks
 * 
 * Idempotency Key Format:
 * - UUID v4 recommended: "550e8400-e29b-41d4-a716-446655440000"
 * - Include userId + timestamp: "user123_1702778400000"
 * - Generated client-side before first request
 * - Same key for retries
 * 
 * Request Headers:
 * {
 *   "idempotency-key": "550e8400-e29b-41d4-a716-446655440000"
 * }
 * 
 * Request Body:
 * {
 *   "amount": 9999,              // cents ($99.99)
 *   "currency": "usd",
 *   "customerId": "cus_ABC123",
 *   "description": "Invoice INV-2025-001",
 *   "metadata": { "invoiceId": "inv_123" }
 * }
 */
export const createPayment = functions
  .https.onCall(async (data, context) => {
    try {
      // ==================== AUTHENTICATION ====================
      if (!context.auth?.uid) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const userId = context.auth.uid;

      // ==================== IDEMPOTENCY KEY ====================
      // Extract from custom headers (must be passed from client)
      const idempotencyKey =
        (context.rawRequest?.headers?.['idempotency-key'] as string) ||
        (context.rawRequest?.headers?.['x-idempotency-key'] as string);

      if (!idempotencyKey) {
        logger.warn('Missing idempotency key', { userId });
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Idempotency key is required (header: idempotency-key)'
        );
      }

      // Validate idempotency key format (UUID or custom format)
      if (!isValidIdempotencyKey(idempotencyKey)) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Invalid idempotency key format'
        );
      }

      // ==================== REQUEST VALIDATION ====================
      const { amount, currency = 'usd', customerId, description, metadata } =
        data;

      // Validate amount
      if (typeof amount !== 'number' || amount <= 0) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Amount must be a positive number (in cents)'
        );
      }

      if (amount < 50) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Amount must be at least $0.50 (50 cents)'
        );
      }

      if (amount > 10000000) {
        // $100,000 max
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Amount cannot exceed $100,000'
        );
      }

      // Validate currency
      const validCurrencies = ['usd', 'eur', 'gbp', 'cad', 'aud'];
      if (!validCurrencies.includes(currency.toLowerCase())) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Currency must be one of: ${validCurrencies.join(', ')}`
        );
      }

      // Validate customerId
      if (!customerId || typeof customerId !== 'string') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Customer ID is required'
        );
      }

      // Validate description (optional)
      if (description && typeof description !== 'string') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Description must be a string'
        );
      }

      // Validate metadata (optional)
      if (metadata && typeof metadata !== 'object') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Metadata must be an object'
        );
      }

      // ==================== IDEMPOTENCY CHECK ====================
      // Check if payment already exists for this idempotency key
      const existingPaymentRef = await admin
        .firestore()
        .collection('payments')
        .where('idempotencyKey', '==', idempotencyKey)
        .where('userId', '==', userId)
        .limit(1)
        .get();

      if (!existingPaymentRef.empty) {
        const existingPayment = existingPaymentRef.docs[0].data();

        logger.info('Idempotent request - returning existing payment', {
          userId,
          idempotencyKey,
          paymentId: existingPayment.paymentId,
        });

        // Return existing payment intent if already created
        if (existingPayment.status === 'succeeded' || existingPayment.status === 'processing') {
          return {
            success: true,
            clientSecret: existingPayment.clientSecret,
            paymentId: existingPayment.paymentId,
            status: existingPayment.status,
            message: 'Payment already processed (idempotent)',
          };
        }

        // If payment failed, allow retry with same key
        if (existingPayment.status === 'failed') {
          logger.info('Previous payment failed, allowing retry', {
            userId,
            idempotencyKey,
          });
          // Continue to create new attempt below
        }
      }

      // ==================== CREATE PAYMENT INTENT ====================
      logger.info('Creating payment intent', {
        userId,
        idempotencyKey,
        amount,
        currency,
        customerId,
      });

      const paymentIntent = await stripe.paymentIntents.create(
        {
          amount,
          currency: currency.toLowerCase(),
          customer: customerId,
          description: description || `Payment from ${userId}`,
          metadata: {
            userId,
            ...metadata,
          },
          automatic_payment_methods: {
            enabled: true,
          },
        },
        {
          // CRITICAL: Idempotency key prevents duplicate charges
          idempotencyKey,
          // Add timeout for slow networks
          timeout: 30000,
        }
      );

      // ==================== STORE PAYMENT RECORD ====================
      // Always store payment intent in Firestore for audit trail
      const paymentRef = admin
        .firestore()
        .collection('payments')
        .doc(paymentIntent.id);

      await paymentRef.set({
        userId,
        paymentId: paymentIntent.id,
        idempotencyKey,
        amount,
        currency,
        customerId,
        description: description || `Payment from ${userId}`,
        status: paymentIntent.status,
        clientSecret: paymentIntent.client_secret,
        metadata: paymentIntent.metadata || {},
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        // For tracking payment status changes
        lastStatusChange: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info('Payment intent created', {
        userId,
        idempotencyKey,
        paymentId: paymentIntent.id,
        amount,
        status: paymentIntent.status,
      });

      return {
        success: true,
        clientSecret: paymentIntent.client_secret,
        paymentId: paymentIntent.id,
        status: paymentIntent.status,
        amount,
        currency,
        message: 'Payment intent created successfully',
      };
    } catch (error: any) {
      logger.error('Payment creation error', {
        error: error.message,
        userId: context.auth?.uid,
        code: error.code,
      });

      // Return specific Stripe errors
      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      if (error.type === 'StripeInvalidRequestError') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          `Stripe error: ${error.message}`
        );
      }

      if (error.type === 'StripeAuthenticationError') {
        throw new functions.https.HttpsError(
          'internal',
          'Payment service authentication failed'
        );
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to create payment intent'
      );
    }
  });

/**
 * Confirm Payment
 * 
 * Confirms a payment intent (called after user completes payment)
 * Updates payment status in Firestore
 */
export const confirmPayment = functions
  .https.onCall(async (data, context) => {
    try {
      if (!context.auth?.uid) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const userId = context.auth.uid;
      const { paymentId } = data;

      if (!paymentId || typeof paymentId !== 'string') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Payment ID is required'
        );
      }

      // Verify ownership
      const paymentRef = admin.firestore().collection('payments').doc(paymentId);
      const paymentDoc = await paymentRef.get();

      if (!paymentDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Payment not found'
        );
      }

      const payment = paymentDoc.data() as any;
      if (payment.userId !== userId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Payment does not belong to user'
        );
      }

      // Retrieve updated payment intent from Stripe
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentId);

      // Update Firestore record
      await paymentRef.update({
        status: paymentIntent.status,
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
        lastStatusChange: admin.firestore.FieldValue.serverTimestamp(),
      });

      logger.info('Payment confirmed', {
        userId,
        paymentId,
        status: paymentIntent.status,
      });

      return {
        success: true,
        paymentId,
        status: paymentIntent.status,
        message: 'Payment confirmed',
      };
    } catch (error: any) {
      logger.error('Payment confirmation error', {
        error: error.message,
        userId: context.auth?.uid,
      });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to confirm payment'
      );
    }
  });

/**
 * Get Payment Status
 * 
 * Retrieves current payment status from Stripe and Firestore
 * Used by client to poll payment completion
 */
export const getPaymentStatus = functions
  .https.onCall(async (data, context) => {
    try {
      if (!context.auth?.uid) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const userId = context.auth.uid;
      const { paymentId } = data;

      if (!paymentId || typeof paymentId !== 'string') {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Payment ID is required'
        );
      }

      // Verify ownership
      const paymentRef = admin.firestore().collection('payments').doc(paymentId);
      const paymentDoc = await paymentRef.get();

      if (!paymentDoc.exists) {
        throw new functions.https.HttpsError(
          'not-found',
          'Payment not found'
        );
      }

      const payment = paymentDoc.data() as any;
      if (payment.userId !== userId) {
        throw new functions.https.HttpsError(
          'permission-denied',
          'Payment does not belong to user'
        );
      }

      // Get current status from Stripe
      const paymentIntent = await stripe.paymentIntents.retrieve(paymentId);

      // Update Firestore if status changed
      if (paymentIntent.status !== payment.status) {
        await paymentRef.update({
          status: paymentIntent.status,
          updatedAt: admin.firestore.FieldValue.serverTimestamp(),
          lastStatusChange: admin.firestore.FieldValue.serverTimestamp(),
        });
      }

      return {
        success: true,
        paymentId,
        status: paymentIntent.status,
        amount: paymentIntent.amount,
        currency: paymentIntent.currency,
        message: `Payment status: ${paymentIntent.status}`,
      };
    } catch (error: any) {
      logger.error('Get payment status error', {
        error: error.message,
        userId: context.auth?.uid,
      });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to get payment status'
      );
    }
  });

/**
 * Webhook: Handle Stripe Events
 * 
 * Listens for Stripe events and updates payment status
 * Called by Stripe when payment status changes
 * 
 * URL: https://region-project.cloudfunctions.net/handleStripeWebhook
 * Setup in Stripe Dashboard → Developers → Webhooks
 */
export const handleStripeWebhook = functions
  .https.onRequest(async (req, res) => {
    if (req.method !== 'POST') {
      res.status(405).send('Method Not Allowed');
      return;
    }

    let event;

    try {
      // Verify webhook signature
      const sig = req.headers['stripe-signature'] as string;
      const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET || '';

      event = stripe.webhooks.constructEvent(
        req.rawBody as string,
        sig,
        webhookSecret
      );
    } catch (err: any) {
      logger.warn('Webhook signature verification failed', {
        error: err.message,
      });
      res.status(400).send('Webhook Error');
      return;
    }

    try {
      switch (event.type) {
        case 'payment_intent.succeeded':
          await handlePaymentIntentSucceeded(event.data.object);
          break;

        case 'payment_intent.payment_failed':
          await handlePaymentIntentFailed(event.data.object);
          break;

        case 'payment_intent.canceled':
          await handlePaymentIntentCanceled(event.data.object);
          break;

        default:
          logger.info(`Unhandled event type: ${event.type}`);
      }

      res.status(200).json({ received: true });
    } catch (error: any) {
      logger.error('Webhook processing error', {
        error: error.message,
        eventType: event.type,
      });
      res.status(500).send('Internal Server Error');
    }
  });

/**
 * Handle payment_intent.succeeded event
 */
async function handlePaymentIntentSucceeded(paymentIntent: any) {
  const { id: paymentId, metadata } = paymentIntent;

  logger.info('Payment succeeded', {
    paymentId,
    userId: metadata?.userId,
    amount: paymentIntent.amount,
  });

  // Update payment record
  await admin.firestore().collection('payments').doc(paymentId).update({
    status: 'succeeded',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    lastStatusChange: admin.firestore.FieldValue.serverTimestamp(),
  });

  // TODO: Handle business logic (e.g., create order, send receipt)
  // Example: Update user credits, send invoice, etc.
}

/**
 * Handle payment_intent.payment_failed event
 */
async function handlePaymentIntentFailed(paymentIntent: any) {
  const { id: paymentId, metadata, last_payment_error } = paymentIntent;

  logger.warn('Payment failed', {
    paymentId,
    userId: metadata?.userId,
    error: last_payment_error?.message,
  });

  // Update payment record with error
  await admin.firestore().collection('payments').doc(paymentId).update({
    status: 'failed',
    error: last_payment_error?.message || 'Payment failed',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    lastStatusChange: admin.firestore.FieldValue.serverTimestamp(),
  });

  // TODO: Notify user of payment failure
}

/**
 * Handle payment_intent.canceled event
 */
async function handlePaymentIntentCanceled(paymentIntent: any) {
  const { id: paymentId, metadata } = paymentIntent;

  logger.info('Payment canceled', {
    paymentId,
    userId: metadata?.userId,
  });

  // Update payment record
  await admin.firestore().collection('payments').doc(paymentId).update({
    status: 'canceled',
    updatedAt: admin.firestore.FieldValue.serverTimestamp(),
    lastStatusChange: admin.firestore.FieldValue.serverTimestamp(),
  });
}

/**
 * Validate idempotency key format
 * 
 * Accepts:
 * - UUID v4: 550e8400-e29b-41d4-a716-446655440000
 * - Custom: user123_1702778400000
 */
function isValidIdempotencyKey(key: string): boolean {
  if (typeof key !== 'string' || key.length === 0) {
    return false;
  }

  // UUID v4 format
  const uuidPattern =
    /^[0-9a-f]{8}-[0-9a-f]{4}-4[0-9a-f]{3}-[89ab][0-9a-f]{3}-[0-9a-f]{12}$/i;
  if (uuidPattern.test(key)) {
    return true;
  }

  // Custom format: alphanumeric + underscore + dash, 10-100 chars
  const customPattern = /^[a-zA-Z0-9_\-]{10,100}$/;
  return customPattern.test(key);
}
