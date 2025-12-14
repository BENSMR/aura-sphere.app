/**
 * STRIPE PAYMENT UI COMPONENTS
 * 
 * React/Flutter components for:
 * - Payment card form
 * - Subscription upgrade/downgrade
 * - Billing history
 * - Payment methods management
 */

import React, { useState, useEffect } from 'react';
import { loadStripe } from '@stripe/js';
import {
  Elements,
  CardElement,
  useStripe,
  useElements
} from '@stripe/react-stripe-js';
import stripeService from '../services/stripe_service';
import './PaymentComponents.css';

// Initialize Stripe
const stripePromise = loadStripe(process.env.REACT_APP_STRIPE_PUBLISHABLE_KEY || '');

// ─────────────────────────────────────────────────────────────────────────
// PAYMENT CARD FORM
// ─────────────────────────────────────────────────────────────────────────

/**
 * CardPaymentForm - Handles card payment processing
 */
export function CardPaymentForm({ tierId, billingCycle, amount, onSuccess, onError }) {
  const stripe = useStripe();
  const elements = useElements();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);
  const [succeeded, setSucceeded] = useState(false);

  const handlePayment = async (e) => {
    e.preventDefault();

    if (!stripe || !elements) {
      return;
    }

    setLoading(true);
    setError(null);

    try {
      // Step 1: Create payment intent on backend
      const { clientSecret, paymentIntentId } = await stripeService.createPaymentIntent(
        amount,
        tierId,
        billingCycle
      );

      // Step 2: Confirm payment with card
      const cardElement = elements.getElement(CardElement);
      const { error: stripeError, paymentIntent } = await stripe.confirmCardPayment(
        clientSecret,
        {
          payment_method: {
            card: cardElement,
            billing_details: {
              name: document.getElementById('cardholder-name')?.value || 'Customer'
            }
          }
        }
      );

      if (stripeError) {
        setError(stripeError.message);
        onError?.(stripeError);
      } else if (paymentIntent.status === 'succeeded') {
        // Step 3: Confirm in backend and update subscription
        await stripeService.confirmPayment(clientSecret, tierId);
        setSucceeded(true);
        onSuccess?.({ paymentIntentId, tierId });
      }
    } catch (err) {
      const errorMsg = stripeService.getPaymentErrorMessage(err);
      setError(errorMsg);
      onError?.(err);
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handlePayment} className="payment-form">
      <div className="form-group">
        <label htmlFor="cardholder-name">Full Name</label>
        <input
          id="cardholder-name"
          type="text"
          placeholder="John Doe"
          required
          disabled={loading || succeeded}
        />
      </div>

      <div className="form-group">
        <label>Card Details</label>
        <div className="card-element-wrapper">
          <CardElement
            disabled={loading || succeeded}
            options={{
              style: {
                base: {
                  fontSize: '16px',
                  color: '#424770',
                  '::placeholder': {
                    color: '#aab7c4'
                  }
                },
                invalid: {
                  color: '#fa755a'
                }
              }
            }}
          />
        </div>
      </div>

      {error && <div className="error-message">{error}</div>}

      {succeeded && (
        <div className="success-message">
          ✓ Payment successful! Upgrading subscription...
        </div>
      )}

      <button
        type="submit"
        disabled={loading || !stripe || succeeded}
        className="payment-button"
      >
        {loading ? 'Processing...' : `Pay ${stripeService.formatPrice(amount)}`}
      </button>

      <p className="payment-info">
        Your payment is secure and encrypted. We'll never store your card information.
      </p>
    </form>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// SUBSCRIPTION UPGRADE/DOWNGRADE
// ─────────────────────────────────────────────────────────────────────────

/**
 * SubscriptionUpgrade - UI for upgrading subscription tier
 */
export function SubscriptionUpgrade({ currentTierId, onUpgradeComplete }) {
  const [tiers] = useState([
    { id: 'solo', name: 'Solo', price: 9, features: ['5 invoices', '1 user'] },
    { id: 'team', name: 'Team', price: 29, features: ['Unlimited invoices', '5 users'] },
    { id: 'business', name: 'Business', price: 79, features: ['Everything', '20 users'] }
  ]);

  const [selectedTier, setSelectedTier] = useState(null);
  const [loading, setLoading] = useState(false);

  const handleUpgrade = async () => {
    if (!selectedTier || selectedTier === currentTierId) {
      return;
    }

    setLoading(true);

    try {
      const result = await stripeService.updateSubscription(selectedTier);
      onUpgradeComplete?.(result);
    } catch (error) {
      console.error('Upgrade failed:', error);
      alert('Upgrade failed. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="subscription-upgrade">
      <h2>Upgrade Your Subscription</h2>

      <div className="tier-selector">
        {tiers.map(tier => (
          <div
            key={tier.id}
            className={`tier-card ${selectedTier === tier.id ? 'selected' : ''} ${
              tier.id === currentTierId ? 'current' : ''
            }`}
            onClick={() => setSelectedTier(tier.id)}
          >
            <h3>{tier.name}</h3>
            <p className="price">${tier.price}/month</p>

            {tier.id === currentTierId && (
              <span className="badge">Current Plan</span>
            )}

            <ul className="features">
              {tier.features.map((feature, idx) => (
                <li key={idx}>✓ {feature}</li>
              ))}
            </ul>

            {tier.id !== currentTierId && selectedTier === tier.id && (
              <p className="upgrade-price">
                Upgrade cost prorated to {tier.name}
              </p>
            )}
          </div>
        ))}
      </div>

      <button
        onClick={handleUpgrade}
        disabled={!selectedTier || selectedTier === currentTierId || loading}
        className="upgrade-button"
      >
        {loading ? 'Processing...' : 'Confirm Upgrade'}
      </button>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// BILLING HISTORY
// ─────────────────────────────────────────────────────────────────────────

/**
 * BillingHistory - Display payment history and invoices
 */
export function BillingHistory({ userId }) {
  const [payments, setPayments] = useState([]);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    loadPaymentHistory();
  }, [userId]);

  const loadPaymentHistory = async () => {
    setLoading(true);

    try {
      const paymentHistory = await stripeService.getPaymentHistory(userId);
      setPayments(paymentHistory);
    } catch (error) {
      console.error('Failed to load payment history:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDownloadInvoice = async (paymentId) => {
    try {
      await stripeService.downloadInvoice(userId, paymentId);
    } catch (error) {
      console.error('Failed to download invoice:', error);
      alert('Failed to download invoice');
    }
  };

  if (loading) {
    return <div className="loading">Loading billing history...</div>;
  }

  if (payments.length === 0) {
    return <div className="empty-state">No payments yet</div>;
  }

  return (
    <div className="billing-history">
      <h2>Billing History</h2>

      <table className="payments-table">
        <thead>
          <tr>
            <th>Date</th>
            <th>Amount</th>
            <th>Plan</th>
            <th>Status</th>
            <th>Actions</th>
          </tr>
        </thead>

        <tbody>
          {payments.map(payment => (
            <tr key={payment.id}>
              <td>{new Date(payment.timestamp?.toDate()).toLocaleDateString()}</td>
              <td>{stripeService.formatPrice(payment.amount)}</td>
              <td>{payment.tierId}</td>
              <td>
                <span className={`status ${payment.status}`}>
                  {payment.status === 'succeeded' ? '✓ Paid' : 'Pending'}
                </span>
              </td>
              <td>
                <button
                  onClick={() => handleDownloadInvoice(payment.id)}
                  className="action-button"
                >
                  Download Invoice
                </button>
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// PAYMENT METHODS
// ─────────────────────────────────────────────────────────────────────────

/**
 * PaymentMethodManager - Add, view, and delete payment methods
 */
export function PaymentMethodManager({ userId }) {
  const [paymentMethods, setPaymentMethods] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showForm, setShowForm] = useState(false);

  useEffect(() => {
    loadPaymentMethods();
  }, [userId]);

  const loadPaymentMethods = async () => {
    setLoading(true);

    try {
      const methods = await stripeService.getPaymentMethods(userId);
      setPaymentMethods(methods);
    } catch (error) {
      console.error('Failed to load payment methods:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDeletePaymentMethod = async (paymentMethodId) => {
    if (!window.confirm('Are you sure you want to delete this payment method?')) {
      return;
    }

    try {
      await stripeService.deletePaymentMethod(userId, paymentMethodId);
      loadPaymentMethods(); // Refresh list
    } catch (error) {
      console.error('Failed to delete payment method:', error);
      alert('Failed to delete payment method');
    }
  };

  if (loading) {
    return <div className="loading">Loading payment methods...</div>;
  }

  return (
    <div className="payment-methods">
      <h2>Payment Methods</h2>

      {paymentMethods.length === 0 ? (
        <p className="empty-state">No payment methods saved</p>
      ) : (
        <div className="methods-list">
          {paymentMethods.map(method => (
            <div key={method.id} className="method-card">
              <div className="method-info">
                <p className="card-brand">•••• {method.last4}</p>
                {method.isDefault && <span className="badge">Default</span>}
              </div>

              <button
                onClick={() => handleDeletePaymentMethod(method.id)}
                className="delete-button"
              >
                Delete
              </button>
            </div>
          ))}
        </div>
      )}

      <button
        onClick={() => setShowForm(!showForm)}
        className="add-method-button"
      >
        {showForm ? 'Cancel' : 'Add Payment Method'}
      </button>

      {showForm && (
        <AddPaymentMethodForm
          userId={userId}
          onSuccess={() => {
            setShowForm(false);
            loadPaymentMethods();
          }}
        />
      )}
    </div>
  );
}

/**
 * AddPaymentMethodForm - Form to add new payment method
 */
function AddPaymentMethodForm({ userId, onSuccess }) {
  const stripe = useStripe();
  const elements = useElements();
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState(null);

  const handleAddPaymentMethod = async (e) => {
    e.preventDefault();

    if (!stripe || !elements) {
      return;
    }

    setLoading(true);
    setError(null);

    try {
      const cardElement = elements.getElement(CardElement);

      const { error: stripeError, paymentMethod } = await stripe.createPaymentMethod({
        type: 'card',
        card: cardElement
      });

      if (stripeError) {
        setError(stripeError.message);
      } else {
        await stripeService.savePaymentMethod(userId, paymentMethod.id, true);
        onSuccess?.();
      }
    } catch (err) {
      setError('Failed to add payment method');
    } finally {
      setLoading(false);
    }
  };

  return (
    <form onSubmit={handleAddPaymentMethod} className="add-payment-form">
      <div className="form-group">
        <label>Card Details</label>
        <div className="card-element-wrapper">
          <CardElement disabled={loading} />
        </div>
      </div>

      {error && <div className="error-message">{error}</div>}

      <button type="submit" disabled={loading} className="payment-button">
        {loading ? 'Adding...' : 'Add Payment Method'}
      </button>
    </form>
  );
}

// ─────────────────────────────────────────────────────────────────────────
// MAIN PAYMENT CONTAINER
// ─────────────────────────────────────────────────────────────────────────

/**
 * StripePaymentContainer - Wraps all payment components with Stripe provider
 */
export function StripePaymentContainer({ children }) {
  return (
    <Elements stripe={stripePromise}>
      {children}
    </Elements>
  );
}

export default {
  CardPaymentForm,
  SubscriptionUpgrade,
  BillingHistory,
  PaymentMethodManager,
  StripePaymentContainer
};
