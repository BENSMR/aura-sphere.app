/**
 * STRIPE CONFIGURATION
 * 
 * Initializes Stripe SDK and provides utility functions for Stripe integration
 */

import { loadStripe } from '@stripe/js';

let stripeInstance = null;

/**
 * Initialize and return Stripe instance
 * @returns {Promise<Stripe>}
 */
export async function initializeStripe() {
  if (stripeInstance) {
    return stripeInstance;
  }

  const publishableKey = process.env.REACT_APP_STRIPE_PUBLISHABLE_KEY;
  
  if (!publishableKey) {
    console.error(
      'REACT_APP_STRIPE_PUBLISHABLE_KEY environment variable is not set. ' +
      'Please add your Stripe publishable key to your .env file.'
    );
    return null;
  }

  try {
    stripeInstance = await loadStripe(publishableKey, {
      apiVersion: '2022-11-15',
    });
    return stripeInstance;
  } catch (error) {
    console.error('Failed to initialize Stripe:', error);
    return null;
  }
}

/**
 * Get the Stripe instance (must call initializeStripe first)
 * @returns {Stripe|null}
 */
export function getStripeInstance() {
  return stripeInstance;
}

/**
 * Redirect to Stripe Checkout
 * @param {string} sessionId - Stripe checkout session ID
 * @returns {Promise<void>}
 */
export async function redirectToCheckout(sessionId) {
  const stripe = await initializeStripe();
  
  if (!stripe) {
    throw new Error('Stripe failed to initialize');
  }

  const { error } = await stripe.redirectToCheckout({
    sessionId,
  });

  if (error) {
    throw new Error(error.message);
  }
}

/**
 * Retrieve a payment element for custom checkout form
 * @param {string} clientSecret - Client secret from payment intent
 * @returns {Promise<{elements: any, payment: any}>}
 */
export async function createPaymentElement(clientSecret) {
  const stripe = await initializeStripe();
  
  if (!stripe) {
    throw new Error('Stripe failed to initialize');
  }

  const elements = stripe.elements({
    clientSecret,
    appearance: {
      theme: 'stripe',
      variables: {
        colorPrimary: '#635BFF',
        colorText: '#31325F',
      },
    },
  });

  const paymentElement = elements.create('payment');

  return {
    stripe,
    elements,
    paymentElement,
  };
}

/**
 * Create a card element for custom forms
 * @param {Object} options - Element creation options
 * @returns {Promise<any>}
 */
export async function createCardElement(options = {}) {
  const stripe = await initializeStripe();
  
  if (!stripe) {
    throw new Error('Stripe failed to initialize');
  }

  const elements = stripe.elements({
    appearance: {
      theme: 'stripe',
      variables: {
        colorPrimary: '#635BFF',
        colorText: '#31325F',
        colorBackground: '#FFFFFF',
        colorDanger: '#FA755A',
        fontFamily: '-apple-system, BlinkMacSystemFont, "Segoe UI", Roboto, Helvetica, Arial, sans-serif',
        spacingUnit: '2px',
      },
      rules: {
        '.Label': {
          marginBottom: '8px',
        },
        '.Input': {
          border: '1px solid #ccc',
          borderRadius: '4px',
          padding: '10px 12px',
        },
        '.Input:focus': {
          borderColor: '#635BFF',
          boxShadow: '0 0 0 2px rgba(99, 91, 255, 0.1)',
        },
      },
    },
    ...options,
  });

  return elements.create('card', {
    hidePostalCode: false,
  });
}

/**
 * Confirm card payment
 * @param {Object} stripe - Stripe instance
 * @param {string} clientSecret - Client secret from payment intent
 * @param {Object} cardElement - Card element or payment element
 * @param {Object} billingDetails - Billing details
 * @returns {Promise<{paymentIntent: Object, error: Object|null}>}
 */
export async function confirmCardPayment(
  stripe,
  clientSecret,
  cardElement,
  billingDetails
) {
  return await stripe.confirmCardPayment(clientSecret, {
    payment_method: {
      card: cardElement,
      billing_details: billingDetails,
    },
  });
}

/**
 * Confirm payment with payment element
 * @param {Object} stripe - Stripe instance
 * @param {string} clientSecret - Client secret from payment intent
 * @param {Object} elements - Elements instance
 * @param {Object} options - Confirmation options
 * @returns {Promise<Object>}
 */
export async function confirmPayment(
  stripe,
  clientSecret,
  elements,
  options = {}
) {
  return await stripe.confirmPayment({
    elements,
    clientSecret,
    confirmParams: {
      return_url: options.returnUrl || `${window.location.origin}/payment-success`,
      ...options.confirmParams,
    },
    redirect: options.redirect || 'if_required',
  });
}

/**
 * Handle card/payment errors with user-friendly messages
 * @param {Object} error - Stripe error object
 * @returns {string}
 */
export function handlePaymentError(error) {
  const errorMessages = {
    card_declined: 'Your card was declined.',
    expired_card: 'Your card has expired.',
    incorrect_cvc: 'Your card\'s CVC is invalid.',
    processing_error: 'An error occurred while processing your card.',
    rate_limit: 'Too many requests. Please wait a moment and try again.',
    authentication_required: 'This card requires additional authentication.',
    invalid_expiry_month: 'The expiration month is invalid.',
    invalid_expiry_year: 'The expiration year is invalid.',
  };

  if (error.code && errorMessages[error.code]) {
    return errorMessages[error.code];
  }

  return error.message || 'An error occurred. Please try again.';
}

/**
 * Check if Stripe is available
 * @returns {boolean}
 */
export function isStripeAvailable() {
  return stripeInstance !== null && process.env.REACT_APP_STRIPE_PUBLISHABLE_KEY !== undefined;
}

/**
 * Get Stripe API version
 * @returns {string}
 */
export function getStripeApiVersion() {
  return '2022-11-15';
}

/**
 * Format Stripe error for logging
 * @param {Error} error - Error object
 * @returns {Object}
 */
export function formatStripeError(error) {
  return {
    code: error.code,
    message: error.message,
    type: error.type,
    param: error.param,
    charge: error.charge,
    doc_url: error.doc_url,
    timestamp: new Date().toISOString(),
  };
}
