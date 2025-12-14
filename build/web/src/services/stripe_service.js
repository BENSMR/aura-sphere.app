/**
 * STRIPE SERVICE
 * 
 * Manages all Stripe payment operations for the web application
 * Handles:
 * - Payment intents and card payments
 * - Subscription management
 * - Payment method management
 * - Billing history and invoices
 * - Error handling and formatting
 */

import { getFunctions, httpsCallable } from 'firebase/functions';
import { getFirestore, collection, query, where, getDocs, doc, getDoc, updateDoc } from 'firebase/firestore';
import { getAuth } from 'firebase/auth';

class StripeService {
  constructor() {
    this.functions = getFunctions();
    this.db = getFirestore();
    this.auth = getAuth();
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT INTENTS & CHECKOUT
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Create a payment intent for one-time payments
   * @param {number} amount - Amount in smallest currency unit (e.g., cents)
   * @param {string} tierId - Subscription tier ID (for metadata)
   * @param {string} billingCycle - 'monthly' or 'yearly'
   * @returns {Promise<{clientSecret: string, paymentIntentId: string}>}
   */
  async createPaymentIntent(amount, tierId, billingCycle = 'monthly') {
    try {
      const createPaymentIntent = httpsCallable(
        this.functions,
        'createPaymentIntent'
      );

      const result = await createPaymentIntent({
        amount,
        tierId,
        billingCycle,
        currency: 'usd',
        description: `Subscription upgrade to ${tierId}`,
      });

      return {
        clientSecret: result.data.clientSecret,
        paymentIntentId: result.data.paymentIntentId,
      };
    } catch (error) {
      console.error('Error creating payment intent:', error);
      throw this.handleStripeError(error);
    }
  }

  /**
   * Confirm payment after client-side card processing
   * @param {string} clientSecret - Client secret from createPaymentIntent
   * @param {string} tierId - Subscription tier to activate
   * @returns {Promise<{success: boolean}>}
   */
  async confirmPayment(clientSecret, tierId) {
    try {
      const confirmPaymentFn = httpsCallable(
        this.functions,
        'confirmPayment'
      );

      const result = await confirmPaymentFn({
        clientSecret,
        tierId,
      });

      return {
        success: result.data.success,
        subscriptionId: result.data.subscriptionId,
      };
    } catch (error) {
      console.error('Error confirming payment:', error);
      throw this.handleStripeError(error);
    }
  }

  /**
   * Create a checkout session for one-time invoice payment
   * @param {string} invoiceId - Invoice ID from Firestore
   * @param {string} successUrl - Redirect on success (optional, uses default)
   * @param {string} cancelUrl - Redirect on cancel (optional, uses default)
   * @returns {Promise<{url: string, sessionId: string}>}
   */
  async createCheckoutSession(invoiceId, successUrl, cancelUrl) {
    try {
      const createCheckoutSession = httpsCallable(
        this.functions,
        'createCheckoutSession'
      );

      const result = await createCheckoutSession({
        invoiceId,
        successUrl: successUrl || `${window.location.origin}/billing/payment-success`,
        cancelUrl: cancelUrl || `${window.location.origin}/billing/payment-cancel`,
      });

      return {
        url: result.data.url,
        sessionId: result.data.id,
      };
    } catch (error) {
      console.error('Error creating checkout session:', error);
      throw this.handleStripeError(error);
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // SUBSCRIPTION MANAGEMENT
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Upgrade or downgrade subscription to a new tier
   * @param {string} newTierId - Target subscription tier (solo, team, business)
   * @returns {Promise<{success: boolean, newPlan: string, nextBillingDate: string}>}
   */
  async updateSubscription(newTierId) {
    try {
      const updateSubscription = httpsCallable(
        this.functions,
        'updateSubscription'
      );

      const result = await updateSubscription({
        newTierId,
      });

      return {
        success: result.data.success,
        newPlan: result.data.newPlan,
        nextBillingDate: result.data.nextBillingDate,
        proratedAmount: result.data.proratedAmount,
      };
    } catch (error) {
      console.error('Error updating subscription:', error);
      throw this.handleStripeError(error);
    }
  }

  /**
   * Cancel current subscription
   * @param {string} reason - Reason for cancellation (optional)
   * @returns {Promise<{success: boolean, canceledAt: string}>}
   */
  async cancelSubscription(reason = '') {
    try {
      const cancelSubscription = httpsCallable(
        this.functions,
        'cancelSubscription'
      );

      const result = await cancelSubscription({
        reason,
      });

      return {
        success: result.data.success,
        canceledAt: result.data.canceledAt,
      };
    } catch (error) {
      console.error('Error canceling subscription:', error);
      throw this.handleStripeError(error);
    }
  }

  /**
   * Get current subscription details
   * @returns {Promise<{status: string, plan: string, current_period_start: number, current_period_end: number}>}
   */
  async getSubscriptionDetails() {
    try {
      const user = this.auth.currentUser;
      if (!user) throw new Error('User not authenticated');

      const userRef = doc(this.db, 'users', user.uid);
      const userSnap = await getDoc(userRef);
      const userData = userSnap.data();

      return {
        status: userData?.subscription?.status || 'inactive',
        plan: userData?.subscription?.plan || 'free',
        customerId: userData?.stripeCustomerId,
        currentPeriodStart: userData?.subscription?.currentPeriodStart,
        currentPeriodEnd: userData?.subscription?.currentPeriodEnd,
      };
    } catch (error) {
      console.error('Error getting subscription details:', error);
      throw error;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT METHODS
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Get all saved payment methods for the user
   * @returns {Promise<Array>}
   */
  async getPaymentMethods() {
    try {
      const user = this.auth.currentUser;
      if (!user) throw new Error('User not authenticated');

      const methodsRef = collection(
        this.db,
        'users',
        user.uid,
        'paymentMethods'
      );
      const q = query(methodsRef, where('deleted', '!=', true));
      const querySnapshot = await getDocs(q);

      return querySnapshot.docs.map(doc => ({
        id: doc.id,
        ...doc.data(),
      }));
    } catch (error) {
      console.error('Error getting payment methods:', error);
      throw error;
    }
  }

  /**
   * Save a payment method and optionally set as default
   * @param {string} paymentMethodId - Stripe payment method ID
   * @param {boolean} setAsDefault - Whether to set as default payment method
   * @returns {Promise<{success: boolean}>}
   */
  async savePaymentMethod(paymentMethodId, setAsDefault = false) {
    try {
      const user = this.auth.currentUser;
      if (!user) throw new Error('User not authenticated');

      const savePaymentMethod = httpsCallable(
        this.functions,
        'savePaymentMethod'
      );

      const result = await savePaymentMethod({
        paymentMethodId,
        setAsDefault,
      });

      return {
        success: result.data.success,
        methodId: result.data.methodId,
      };
    } catch (error) {
      console.error('Error saving payment method:', error);
      throw this.handleStripeError(error);
    }
  }

  /**
   * Delete a saved payment method
   * @param {string} paymentMethodId - ID of the payment method to delete
   * @returns {Promise<{success: boolean}>}
   */
  async deletePaymentMethod(paymentMethodId) {
    try {
      const user = this.auth.currentUser;
      if (!user) throw new Error('User not authenticated');

      const methodRef = doc(
        this.db,
        'users',
        user.uid,
        'paymentMethods',
        paymentMethodId
      );

      await updateDoc(methodRef, {
        deleted: true,
        deletedAt: new Date(),
      });

      return { success: true };
    } catch (error) {
      console.error('Error deleting payment method:', error);
      throw error;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // PAYMENT HISTORY & INVOICES
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Get payment history for the user
   * @returns {Promise<Array>}
   */
  async getPaymentHistory() {
    try {
      const user = this.auth.currentUser;
      if (!user) throw new Error('User not authenticated');

      // Get all invoices with their payment records
      const invoicesRef = collection(
        this.db,
        'users',
        user.uid,
        'invoices'
      );
      const invoicesSnap = await getDocs(invoicesRef);

      const payments = [];

      for (const invoiceDoc of invoicesSnap.docs) {
        const invoiceData = invoiceDoc.data();
        
        if (invoiceData.paymentStatus === 'paid' || invoiceData.status === 'paid') {
          const paymentsRef = collection(
            this.db,
            'users',
            user.uid,
            'invoices',
            invoiceDoc.id,
            'payments'
          );
          const paymentsSnap = await getDocs(paymentsRef);

          paymentsSnap.docs.forEach(paymentDoc => {
            payments.push({
              id: paymentDoc.id,
              invoiceId: invoiceDoc.id,
              invoiceNumber: invoiceData.invoiceNumber,
              ...paymentDoc.data(),
            });
          });
        }
      }

      // Sort by date descending
      return payments.sort((a, b) => {
        const dateA = a.paidAt?.toDate?.() || new Date(a.paidAt);
        const dateB = b.paidAt?.toDate?.() || new Date(b.paidAt);
        return dateB - dateA;
      });
    } catch (error) {
      console.error('Error getting payment history:', error);
      throw error;
    }
  }

  /**
   * Download an invoice PDF
   * @param {string} invoiceId - Invoice ID to download
   * @returns {Promise<void>}
   */
  async downloadInvoice(invoiceId) {
    try {
      const user = this.auth.currentUser;
      if (!user) throw new Error('User not authenticated');

      const downloadInvoice = httpsCallable(
        this.functions,
        'downloadInvoice'
      );

      const result = await downloadInvoice({
        invoiceId,
      });

      // Create blob and download
      const link = document.createElement('a');
      link.href = result.data.url;
      link.download = `invoice-${invoiceId}.pdf`;
      document.body.appendChild(link);
      link.click();
      document.body.removeChild(link);
    } catch (error) {
      console.error('Error downloading invoice:', error);
      throw error;
    }
  }

  /**
   * Get detailed invoice information
   * @param {string} invoiceId - Invoice ID
   * @returns {Promise<Object>}
   */
  async getInvoice(invoiceId) {
    try {
      const user = this.auth.currentUser;
      if (!user) throw new Error('User not authenticated');

      const invoiceRef = doc(
        this.db,
        'users',
        user.uid,
        'invoices',
        invoiceId
      );
      const invoiceSnap = await getDoc(invoiceRef);

      if (!invoiceSnap.exists()) {
        throw new Error('Invoice not found');
      }

      return {
        id: invoiceSnap.id,
        ...invoiceSnap.data(),
      };
    } catch (error) {
      console.error('Error getting invoice:', error);
      throw error;
    }
  }

  // ─────────────────────────────────────────────────────────────────────────
  // UTILITY FUNCTIONS
  // ─────────────────────────────────────────────────────────────────────────

  /**
   * Format price for display
   * @param {number} amount - Amount in smallest currency unit
   * @param {string} currency - Currency code (default 'usd')
   * @returns {string}
   */
  formatPrice(amount, currency = 'usd') {
    const formatter = new Intl.NumberFormat('en-US', {
      style: 'currency',
      currency: currency.toUpperCase(),
    });
    return formatter.format(amount / 100);
  }

  /**
   * Format date for display
   * @param {Date|Timestamp} date - Date to format
   * @returns {string}
   */
  formatDate(date) {
    if (!date) return '';
    const dateObj = date.toDate ? date.toDate() : new Date(date);
    return dateObj.toLocaleDateString('en-US', {
      year: 'numeric',
      month: 'short',
      day: 'numeric',
    });
  }

  /**
   * Handle and format Stripe errors
   * @param {Error} error - Error from Stripe or Cloud Function
   * @returns {Error}
   */
  handleStripeError(error) {
    let message = 'An error occurred with your payment';

    if (error.code === 'functions/unauthenticated') {
      message = 'Please log in to make a payment';
    } else if (error.code === 'functions/invalid-argument') {
      message = 'Invalid payment information provided';
    } else if (error.code === 'functions/not-found') {
      message = 'Invoice or payment method not found';
    } else if (error.code === 'functions/failed-precondition') {
      message = 'Unable to process this payment. Please check your invoice details.';
    } else if (error.code === 'functions/aborted') {
      message = 'Payment processing was cancelled. Please try again.';
    } else if (error.code === 'functions/resource-exhausted') {
      message = 'You have exceeded your payment attempt limit. Please try again later.';
    } else if (error.code === 'functions/internal') {
      message = 'Server error processing payment. Please contact support.';
    } else if (error.message) {
      message = error.message;
    }

    const customError = new Error(message);
    customError.code = error.code;
    customError.originalError = error;
    return customError;
  }

  /**
   * Get human-readable error message for payment errors
   * @param {Error} error - Error object
   * @returns {string}
   */
  getPaymentErrorMessage(error) {
    if (error.payment_method?.type === 'card') {
      const code = error.payment_method.card?.error_code;
      
      const errorMessages = {
        card_declined: 'Your card was declined. Please check your card details.',
        expired_card: 'Your card has expired. Please use a different card.',
        incorrect_cvc: 'The CVC code is incorrect.',
        lost_card: 'This card has been reported as lost.',
        stolen_card: 'This card has been reported as stolen.',
        compromised_card: 'This card has been compromised.',
      };

      return errorMessages[code] || 'Card payment failed. Please try another card.';
    }

    return this.handleStripeError(error).message;
  }

  /**
   * Validate card details format (client-side check)
   * @param {string} cardNumber - Card number (spaces removed)
   * @param {string} expiry - Expiry in MM/YY format
   * @param {string} cvc - CVC code
   * @returns {{valid: boolean, errors: string[]}}
   */
  validateCard(cardNumber, expiry, cvc) {
    const errors = [];

    // Remove spaces
    const cleanNumber = cardNumber.replace(/\s/g, '');

    // Check length
    if (cleanNumber.length < 13 || cleanNumber.length > 19) {
      errors.push('Card number must be 13-19 digits');
    }

    // Check Luhn algorithm (basic)
    if (!this._luhnCheck(cleanNumber)) {
      errors.push('Card number is invalid');
    }

    // Check expiry format (MM/YY)
    if (!/^\d{2}\/\d{2}$/.test(expiry)) {
      errors.push('Expiry must be in MM/YY format');
    } else {
      const [month, year] = expiry.split('/');
      const now = new Date();
      const currentYear = now.getFullYear() % 100;
      const currentMonth = now.getMonth() + 1;

      if (
        parseInt(year) < currentYear ||
        (parseInt(year) === currentYear && parseInt(month) < currentMonth)
      ) {
        errors.push('Card has expired');
      }
    }

    // Check CVC (3-4 digits)
    if (!/^\d{3,4}$/.test(cvc)) {
      errors.push('CVC must be 3-4 digits');
    }

    return {
      valid: errors.length === 0,
      errors,
    };
  }

  /**
   * Luhn algorithm check for credit card validity
   * @private
   */
  _luhnCheck(cardNumber) {
    let sum = 0;
    let isEven = false;

    for (let i = cardNumber.length - 1; i >= 0; i--) {
      let digit = parseInt(cardNumber[i], 10);

      if (isEven) {
        digit *= 2;
        if (digit > 9) {
          digit -= 9;
        }
      }

      sum += digit;
      isEven = !isEven;
    }

    return sum % 10 === 0;
  }
}

// Export singleton instance
export default new StripeService();
