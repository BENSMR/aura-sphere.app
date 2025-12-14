/**
 * STRIPE PAYMENT SERVICE
 * 
 * Complete payment processing integration
 * Handles:
 * - Payment intents
 * - Subscription management
 * - Payment history
 * - Refunds
 */

import { httpsCallable } from 'firebase/functions';
import { functions, db } from '../config/firebase';
import { doc, updateDoc, collection, addDoc, query, where, getDocs } from 'firebase/firestore';

// ─────────────────────────────────────────────────────────────────────────
// PAYMENT INTENTS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Create a payment intent for subscription or one-time payment
 * @param {string} userId - User ID
 * @param {number} amount - Amount in cents (e.g., 2900 = $29.00)
 * @param {string} tierId - Subscription tier (solo, team, business)
 * @param {string} billingCycle - 'monthly' or 'yearly'
 * @returns {Promise<object>} { clientSecret, paymentIntentId }
 */
export async function createPaymentIntent(userId, amount, tierId, billingCycle = 'monthly') {
  try {
    const createIntent = httpsCallable(functions, 'stripe_createPaymentIntent');
    
    const result = await createIntent({
      userId,
      amount,
      tierId,
      billingCycle,
      description: `AuraSphere ${tierId} - ${billingCycle}`
    });
    
    return result.data;
  } catch (error) {
    console.error('Error creating payment intent:', error);
    throw error;
  }
}

/**
 * Confirm payment and update user subscription
 * @param {string} userId - User ID
 * @param {string} clientSecret - From Stripe
 * @param {string} tierId - Subscription tier
 * @returns {Promise<object>} Confirmation result
 */
export async function confirmPayment(userId, clientSecret, tierId) {
  try {
    const confirmPaymentFn = httpsCallable(functions, 'stripe_confirmPayment');
    
    const result = await confirmPaymentFn({
      userId,
      clientSecret,
      tierId
    });
    
    return result.data;
  } catch (error) {
    console.error('Error confirming payment:', error);
    throw error;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// SUBSCRIPTION MANAGEMENT
// ─────────────────────────────────────────────────────────────────────────

/**
 * Create or update a subscription
 * @param {string} userId - User ID
 * @param {string} tierId - Subscription tier
 * @param {string} billingCycle - 'monthly' or 'yearly'
 * @param {string} paymentMethodId - Stripe payment method ID
 * @returns {Promise<object>} Subscription data
 */
export async function createSubscription(userId, tierId, billingCycle, paymentMethodId) {
  try {
    const createSub = httpsCallable(functions, 'stripe_createSubscription');
    
    const result = await createSub({
      userId,
      tierId,
      billingCycle,
      paymentMethodId
    });
    
    return result.data;
  } catch (error) {
    console.error('Error creating subscription:', error);
    throw error;
  }
}

/**
 * Upgrade or downgrade subscription
 * @param {string} userId - User ID
 * @param {string} newTierId - New tier ID
 * @returns {Promise<object>} Updated subscription
 */
export async function updateSubscription(userId, newTierId) {
  try {
    const updateSub = httpsCallable(functions, 'stripe_updateSubscription');
    
    const result = await updateSub({
      userId,
      newTierId
    });
    
    return result.data;
  } catch (error) {
    console.error('Error updating subscription:', error);
    throw error;
  }
}

/**
 * Cancel subscription
 * @param {string} userId - User ID
 * @returns {Promise<object>} Cancellation details
 */
export async function cancelSubscription(userId) {
  try {
    const cancelSub = httpsCallable(functions, 'stripe_cancelSubscription');
    
    const result = await cancelSub({ userId });
    
    return result.data;
  } catch (error) {
    console.error('Error canceling subscription:', error);
    throw error;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PAYMENT HISTORY
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get payment history for user
 * @param {string} userId - User ID
 * @param {number} limit - Max results (default 10)
 * @returns {Promise<array>} Array of payment objects
 */
export async function getPaymentHistory(userId, limit = 10) {
  try {
    const paymentsRef = collection(db, 'users', userId, 'payments');
    const q = query(paymentsRef, where('status', '==', 'succeeded'));
    
    const snapshot = await getDocs(q);
    return snapshot.docs
      .map(doc => ({
        id: doc.id,
        ...doc.data()
      }))
      .slice(0, limit);
  } catch (error) {
    console.error('Error fetching payment history:', error);
    return [];
  }
}

/**
 * Get single payment record
 * @param {string} userId - User ID
 * @param {string} paymentId - Payment ID
 * @returns {Promise<object>} Payment object
 */
export async function getPayment(userId, paymentId) {
  try {
    const paymentRef = doc(db, 'users', userId, 'payments', paymentId);
    const snapshot = await getDocs(paymentRef);
    
    if (snapshot.exists()) {
      return { id: snapshot.id, ...snapshot.data() };
    }
    return null;
  } catch (error) {
    console.error('Error fetching payment:', error);
    return null;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// PAYMENT METHODS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Save payment method for future use
 * @param {string} userId - User ID
 * @param {string} paymentMethodId - Stripe payment method ID
 * @param {boolean} makeDefault - Set as default payment method
 * @returns {Promise<object>} Saved payment method
 */
export async function savePaymentMethod(userId, paymentMethodId, makeDefault = false) {
  try {
    const savePM = httpsCallable(functions, 'stripe_savePaymentMethod');
    
    const result = await savePM({
      userId,
      paymentMethodId,
      makeDefault
    });
    
    return result.data;
  } catch (error) {
    console.error('Error saving payment method:', error);
    throw error;
  }
}

/**
 * Get saved payment methods
 * @param {string} userId - User ID
 * @returns {Promise<array>} Array of payment methods
 */
export async function getPaymentMethods(userId) {
  try {
    const pmRef = collection(db, 'users', userId, 'paymentMethods');
    const snapshot = await getDocs(pmRef);
    
    return snapshot.docs.map(doc => ({
      id: doc.id,
      ...doc.data()
    }));
  } catch (error) {
    console.error('Error fetching payment methods:', error);
    return [];
  }
}

/**
 * Delete payment method
 * @param {string} userId - User ID
 * @param {string} paymentMethodId - Payment method ID
 * @returns {Promise<void>}
 */
export async function deletePaymentMethod(userId, paymentMethodId) {
  try {
    const deletePM = httpsCallable(functions, 'stripe_deletePaymentMethod');
    
    await deletePM({
      userId,
      paymentMethodId
    });
  } catch (error) {
    console.error('Error deleting payment method:', error);
    throw error;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// INVOICES & BILLING
// ─────────────────────────────────────────────────────────────────────────

/**
 * Get billing portal session URL (manage subscriptions in Stripe)
 * @param {string} userId - User ID
 * @returns {Promise<string>} Stripe billing portal URL
 */
export async function getBillingPortalUrl(userId) {
  try {
    const getPortal = httpsCallable(functions, 'stripe_getBillingPortalUrl');
    
    const result = await getPortal({ userId });
    return result.data.url;
  } catch (error) {
    console.error('Error getting billing portal URL:', error);
    throw error;
  }
}

/**
 * Get invoice
 * @param {string} userId - User ID
 * @param {string} invoiceId - Invoice ID
 * @returns {Promise<object>} Invoice object with PDF URL
 */
export async function getInvoice(userId, invoiceId) {
  try {
    const getInvoiceFn = httpsCallable(functions, 'stripe_getInvoice');
    
    const result = await getInvoiceFn({
      userId,
      invoiceId
    });
    
    return result.data;
  } catch (error) {
    console.error('Error fetching invoice:', error);
    throw error;
  }
}

/**
 * Download invoice PDF
 * @param {string} userId - User ID
 * @param {string} invoiceId - Invoice ID
 * @returns {Promise<string>} PDF URL
 */
export async function downloadInvoice(userId, invoiceId) {
  try {
    const invoice = await getInvoice(userId, invoiceId);
    
    if (invoice.pdfUrl) {
      // Open in new window or download
      window.open(invoice.pdfUrl, '_blank');
      return invoice.pdfUrl;
    }
    
    throw new Error('No PDF available for invoice');
  } catch (error) {
    console.error('Error downloading invoice:', error);
    throw error;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// REFUNDS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Request refund (admin/support only)
 * @param {string} paymentIntentId - Payment intent ID
 * @param {number} amount - Amount to refund (optional, defaults to full refund)
 * @param {string} reason - Reason for refund
 * @returns {Promise<object>} Refund result
 */
export async function requestRefund(paymentIntentId, amount = null, reason = '') {
  try {
    const refundFn = httpsCallable(functions, 'stripe_refund');
    
    const result = await refundFn({
      paymentIntentId,
      amount,
      reason
    });
    
    return result.data;
  } catch (error) {
    console.error('Error requesting refund:', error);
    throw error;
  }
}

// ─────────────────────────────────────────────────────────────────────────
// HELPERS
// ─────────────────────────────────────────────────────────────────────────

/**
 * Format price for display
 * @param {number} amount - Amount in cents
 * @param {string} currency - Currency code (default USD)
 * @returns {string} Formatted price (e.g., "$29.00")
 */
export function formatPrice(amount, currency = 'USD') {
  return new Intl.NumberFormat('en-US', {
    style: 'currency',
    currency: currency
  }).format(amount / 100);
}

/**
 * Handle payment errors
 * @param {object} error - Stripe error object
 * @returns {string} User-friendly error message
 */
export function getPaymentErrorMessage(error) {
  if (error.type === 'card_error') {
    // Card declined
    return `Card declined: ${error.message}`;
  } else if (error.type === 'validation_error') {
    // Invalid parameters
    return `Invalid payment information: ${error.message}`;
  } else {
    // Network error or other
    return 'Payment failed. Please try again.';
  }
}

export default {
  createPaymentIntent,
  confirmPayment,
  createSubscription,
  updateSubscription,
  cancelSubscription,
  getPaymentHistory,
  getPayment,
  savePaymentMethod,
  getPaymentMethods,
  deletePaymentMethod,
  getBillingPortalUrl,
  getInvoice,
  downloadInvoice,
  requestRefund,
  formatPrice,
  getPaymentErrorMessage
};
