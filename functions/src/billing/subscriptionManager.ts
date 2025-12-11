import { CallableContext } from 'firebase-functions/v1/https';
import Stripe from 'stripe';

const stripe = new Stripe(process.env.STRIPE_SECRET_KEY || '', {
  apiVersion: '2022-11-15',
});

export const subscriptionManager = {
  create: async (data: any, context: CallableContext) => {
    if (!context.auth) {
      throw new Error('Unauthorized');
    }

    const { userId, plan } = data;

    // TODO: Create Stripe subscription
    // This is a placeholder implementation

    return {
      subscriptionId: 'sub_' + Date.now(),
      status: 'active',
      plan: plan,
    };
  },

  getStatus: async (data: any, context: CallableContext) => {
    if (!context.auth) {
      throw new Error('Unauthorized');
    }

    const { userId } = data;

    // TODO: Retrieve subscription from Firestore or Stripe
    return {
      status: 'active',
      plan: 'pro',
      expiresAt: new Date(Date.now() + 30 * 24 * 60 * 60 * 1000).toISOString(),
    };
  },
};
