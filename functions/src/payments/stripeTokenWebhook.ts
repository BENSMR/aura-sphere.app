import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import Stripe from 'stripe';
import { findPackById } from './tokenPacks';

if (!admin.apps.length) admin.initializeApp();
const db = admin.firestore();

const stripeSecret = functions.config().stripe?.secret || process.env.STRIPE_SECRET;
const webhookSecret = functions.config().stripe?.webhook_secret || process.env.STRIPE_WEBHOOK_SECRET;
const stripe = new Stripe(stripeSecret || '', { apiVersion: '2022-11-15' });

export const stripeTokenWebhook = functions.https.onRequest(async (req, res): Promise<void> => {
  const sig = req.headers['stripe-signature'] as string | undefined;
  let event: Stripe.Event;

  try {
    if (webhookSecret && req.rawBody) {
      event = stripe.webhooks.constructEvent(req.rawBody, sig || '', webhookSecret);
    } else {
      // Fallback for local testing (not secure for production)
      event = req.body as Stripe.Event;
    }
  } catch (err: any) {
    console.error('Stripe webhook signature failed:', err.message);
    res.status(400).send(`Webhook Error: ${err.message}`);
    return;
  }

  if (event.type === 'checkout.session.completed') {
    const session = event.data.object as Stripe.Checkout.Session;
    const metadata = session.metadata || {};
    const uid = metadata.uid;
    const packId = metadata.packId;

    if (!uid || !packId) {
      console.warn('Session missing uid or packId', session.id);
      await db.collection('payments_processed').doc(session.id).set({
        sessionId: session.id,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        note: 'missing_metadata',
      });
      res.status(200).send({ ok: true });
      return;
    }

    const processedRef = db.collection('payments_processed').doc(session.id);
    const processedSnap = await processedRef.get();
    if (processedSnap.exists) {
      console.log('Session already processed:', session.id);
      res.status(200).send({ ok: true });
      return;
    }

    const pack = findPackById(packId);
    if (!pack) {
      console.warn('Unknown packId:', packId);
      await processedRef.set({
        sessionId: session.id,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        note: 'unknown_pack',
      });
      res.status(200).send({ ok: true });
      return;
    }

    const userRef = db.collection('users').doc(uid);
    const userSnap = await userRef.get();
    if (!userSnap.exists) {
      console.warn('User not found for session:', session.id);
      await processedRef.set({
        sessionId: session.id,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        note: 'user_not_found',
      });
      res.status(200).send({ ok: true });
      return;
    }

    // Atomically credit tokens
    try {
      await db.runTransaction(async (tx) => {
        const userData = userSnap.data()!;
        const currentBalance = Number(
          userData.wallet?.aura?.balance ??
          userData.auraTokens?.balance ??
          0
        );
        const newBalance = currentBalance + pack.tokens;

        // Write to new or legacy path
        if (userData.wallet) {
          tx.update(userRef, {
            'wallet.aura.balance': newBalance,
            'wallet.aura.updatedAt': admin.firestore.FieldValue.serverTimestamp(),
          });
        } else {
          tx.update(userRef, {
            'auraTokens.balance': newBalance,
            'auraTokens.lifetimeEarned': admin.firestore.FieldValue.increment(pack.tokens),
          });
        }

        // Audit log
        tx.set(userRef.collection('token_audit').doc(), {
          action: 'purchase',
          sessionId: session.id,
          amount: pack.tokens,
          packId: pack.id,
          price_cents: pack.price_cents,
          currency: pack.currency,
          createdAt: admin.firestore.FieldValue.serverTimestamp(),
        });

        // Mark processed
        tx.set(processedRef, {
          sessionId: session.id,
          processedAt: admin.firestore.FieldValue.serverTimestamp(),
          uid,
          packId: pack.id,
        });
      });
    } catch (err: any) {
      console.error('Transaction failed for session', session.id, err);
      // Still mark as processed to avoid retry loops
      await processedRef.set({
        sessionId: session.id,
        processedAt: admin.firestore.FieldValue.serverTimestamp(),
        uid,
        packId: pack.id,
        error: err.message,
      });
    }
  }

  res.status(200).send({ received: true });
});
