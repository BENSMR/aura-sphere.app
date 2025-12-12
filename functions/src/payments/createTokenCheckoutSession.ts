import * as functions from 'firebase-functions';
import Stripe from 'stripe';
import { findPackById } from './tokenPacks';

const stripeSecret = functions.config().stripe?.secret || process.env.STRIPE_SECRET;
if (!stripeSecret) {
  console.warn('Stripe secret not configured. Set via: firebase functions:config:set stripe.secret="sk_xxx"');
}
const stripe = new Stripe(stripeSecret || '', { apiVersion: '2022-11-15' });

interface CreateTokenCheckoutData {
  packId: string;
  successUrl: string;
  cancelUrl: string;
}

export const createTokenCheckoutSession = functions.https.onCall(
  async (data: CreateTokenCheckoutData, context) => {
    const uid = context.auth?.uid;
    if (!uid) {
      throw new functions.https.HttpsError('unauthenticated', 'User must be signed in');
    }

    const { packId, successUrl, cancelUrl } = data;
    if (!packId || !successUrl || !cancelUrl) {
      throw new functions.https.HttpsError(
        'invalid-argument',
        'Missing packId, successUrl, or cancelUrl'
      );
    }

    const pack = findPackById(packId);
    if (!pack) {
      throw new functions.https.HttpsError('not-found', 'Invalid token pack');
    }

    const session = await stripe.checkout.sessions.create({
      payment_method_types: ['card'],
      mode: 'payment',
      line_items: [
        {
          price_data: {
            currency: pack.currency,
            product_data: {
              name: pack.title,
              description: pack.description,
            },
            unit_amount: pack.price_cents,
          },
          quantity: 1,
        },
      ],
      metadata: {
        uid,
        packId: pack.id,
        type: 'aura_tokens',
      },
      success_url: `${successUrl}?session_id={CHECKOUT_SESSION_ID}`,
      cancel_url: cancelUrl,
    });

    return { url: session.url, sessionId: session.id };
  }
);
