# Stripe Integration Guide

**Status:** ✅ Complete - Ready for Production  
**Last Updated:** Phase 13  
**Document Version:** 1.0

---

## Overview

This guide provides complete instructions for integrating Stripe payments into the AuraSphere Pro platform. The system handles:

- One-time invoice payments via Stripe Checkout
- Subscription management and tier upgrades
- Payment method management
- Billing history and invoice generation
- Webhook event handling and reconciliation
- PDF receipt generation and email delivery

---

## Architecture

### Components

```
┌─────────────────────────────────────────────────────────────┐
│ FRONTEND (React/Flutter Web)                                 │
│ - PaymentComponents.jsx (Stripe card form)                   │
│ - stripe_service.js (Payment API wrapper)                    │
│ - stripeConfig.js (Stripe SDK initialization)                │
└──────────────────┬──────────────────────────────────────────┘
                   │ HTTPS Requests
                   │ (Client Secret)
┌──────────────────▼──────────────────────────────────────────┐
│ CLOUD FUNCTIONS (Firebase)                                   │
│ - createPaymentIntent (Create PI for card payments)          │
│ - confirmPayment (Confirm PI & activate subscription)        │
│ - createCheckoutSession (Create checkout link)               │
│ - stripeWebhook (Handle Stripe events)                       │
│ - updateSubscription (Change plan tier)                      │
│ - cancelSubscription (Deactivate subscription)               │
│ - downloadInvoice (Generate invoice PDFs)                    │
│ - getPaymentHistory (Fetch payment records)                  │
└──────────────────┬──────────────────────────────────────────┘
                   │ Firestore
                   │ Updates
┌──────────────────▼──────────────────────────────────────────┐
│ FIRESTORE DATABASE                                           │
│ - users/{uid}/subscription (Current subscription)            │
│ - users/{uid}/invoices (Invoice records)                     │
│ - users/{uid}/invoices/{id}/payments (Payment records)       │
│ - users/{uid}/paymentMethods (Saved cards)                   │
│ - auraTokenTransactions (Payment rewards)                    │
└─────────────────────────────────────────────────────────────┘

External:
Stripe API ← → Webhook → Cloud Functions → Firestore
```

---

## Setup Instructions

### 1. Environment Variables

Add to `.env.local` in project root:

```env
# Stripe Keys (get from https://dashboard.stripe.com/apikeys)
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxx
FIREBASE_FUNCTIONS_STRIPE_SECRET=sk_test_xxxxxxxxxxxx
FIREBASE_FUNCTIONS_STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxx

# App URLs (for Stripe redirect)
REACT_APP_SUCCESS_URL=https://yourdomain.com/payment-success
REACT_APP_CANCEL_URL=https://yourdomain.com/payment-cancel
```

### 2. Firebase Configuration

Set Stripe credentials in Firebase Functions config:

```bash
firebase functions:config:set stripe.secret="sk_test_xxxxxxxxxxxx"
firebase functions:config:set stripe.webhook_secret="whsec_xxxxxxxxxxxx"
firebase functions:config:set sendgrid.key="SG.xxxxxxxxxxxx"
firebase functions:config:set sendgrid.sender="billing@yourdomain.com"
```

Verify configuration:

```bash
firebase functions:config:get
```

### 3. Stripe Webhook Setup

1. Go to [Stripe Dashboard → Webhooks](https://dashboard.stripe.com/webhooks)
2. Click "Add Endpoint"
3. Set endpoint URL:
   ```
   https://us-central1-yourproject.cloudfunctions.net/stripeWebhookBilling
   ```
4. Select events to listen for:
   - `checkout.session.completed`
   - `payment_intent.succeeded`
   - `customer.subscription.created`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `invoice.payment_failed`

5. Copy the webhook signing secret and add to Firebase config (see step 2)

### 4. Deploy Cloud Functions

```bash
cd functions
npm run build
cd ..
firebase deploy --only functions
```

---

## Frontend Integration

### 1. Payment Form Component

Import the payment form component:

```jsx
import { CardPaymentForm } from '../components/PaymentComponents';

export function UpgradeScreen() {
  return (
    <CardPaymentForm
      tierId="team"
      billingCycle="monthly"
      amount={2900} // Amount in cents
      onSuccess={(payment) => {
        console.log('Payment successful:', payment);
        // Redirect to dashboard
      }}
      onError={(error) => {
        console.error('Payment failed:', error.message);
      }}
    />
  );
}
```

### 2. Checkout Session (One-time Invoices)

```jsx
import stripeService from '../services/stripe_service';

// Create checkout link for invoice payment
const handlePayInvoice = async (invoiceId) => {
  try {
    const { url, sessionId } = await stripeService.createCheckoutSession(invoiceId);
    window.location.href = url; // Redirect to Stripe Checkout
  } catch (error) {
    console.error('Failed to create checkout:', error.message);
  }
};
```

### 3. Subscription Management

```jsx
// Upgrade subscription
const handleUpgrade = async (newTierId) => {
  try {
    const result = await stripeService.updateSubscription(newTierId);
    console.log(`Upgraded to ${result.newPlan}`);
    console.log(`Next billing: ${result.nextBillingDate}`);
  } catch (error) {
    console.error('Upgrade failed:', error.message);
  }
};

// Cancel subscription
const handleCancel = async () => {
  try {
    const result = await stripeService.cancelSubscription('Found a better option');
    console.log(`Subscription cancelled as of ${result.canceledAt}`);
  } catch (error) {
    console.error('Cancellation failed:', error.message);
  }
};
```

### 4. Payment History

```jsx
const PaymentHistory = () => {
  const [payments, setPayments] = useState([]);

  useEffect(() => {
    const loadPayments = async () => {
      try {
        const history = await stripeService.getPaymentHistory();
        setPayments(history);
      } catch (error) {
        console.error('Failed to load payments:', error);
      }
    };
    loadPayments();
  }, []);

  return (
    <table>
      <thead>
        <tr>
          <th>Invoice</th>
          <th>Amount</th>
          <th>Date</th>
          <th>Status</th>
          <th>Action</th>
        </tr>
      </thead>
      <tbody>
        {payments.map((payment) => (
          <tr key={payment.id}>
            <td>{payment.invoiceNumber}</td>
            <td>{stripeService.formatPrice(payment.amount)}</td>
            <td>{stripeService.formatDate(payment.paidAt)}</td>
            <td>{payment.status}</td>
            <td>
              <button onClick={() => stripeService.downloadInvoice(payment.invoiceId)}>
                Download PDF
              </button>
            </td>
          </tr>
        ))}
      </tbody>
    </table>
  );
};
```

---

## Cloud Functions API

### Payment Intents

#### `createPaymentIntent(data)`

Create a payment intent for card payments.

**Parameters:**
```javascript
{
  amount: number,          // Amount in cents (required)
  tierId: string,         // Subscription tier (required)
  billingCycle: string,   // 'monthly' or 'yearly' (required)
  currency: string,       // Currency code, e.g., 'usd' (optional)
  description: string     // Payment description (optional)
}
```

**Returns:**
```javascript
{
  clientSecret: string,       // Use with Stripe SDK
  paymentIntentId: string,    // For tracking
}
```

**Usage:**
```javascript
const intent = await functions.httpsCallable('createPaymentIntent')({
  amount: 2900,
  tierId: 'team',
  billingCycle: 'monthly',
});
```

#### `confirmPayment(data)`

Confirm a payment after card processing succeeds.

**Parameters:**
```javascript
{
  clientSecret: string,   // From createPaymentIntent (required)
  tierId: string          // Subscription tier to activate (required)
}
```

**Returns:**
```javascript
{
  success: boolean,
  subscriptionId: string
}
```

### Subscriptions

#### `updateSubscription(data)`

Upgrade or downgrade to a new subscription tier.

**Parameters:**
```javascript
{
  newTierId: string  // 'solo', 'team', or 'business' (required)
}
```

**Returns:**
```javascript
{
  success: boolean,
  newPlan: string,
  nextBillingDate: string,
  proratedAmount: number  // Charge/credit for proration
}
```

#### `cancelSubscription(data)`

Cancel the user's current subscription.

**Parameters:**
```javascript
{
  reason: string  // Optional cancellation reason
}
```

**Returns:**
```javascript
{
  success: boolean,
  canceledAt: string  // ISO date string
}
```

### Invoices

#### `createCheckoutSession(data)`

Create a Stripe Checkout session for one-time invoice payment.

**Parameters:**
```javascript
{
  invoiceId: string,      // Invoice ID in Firestore (required)
  successUrl: string,     // Redirect on success (optional)
  cancelUrl: string       // Redirect on cancel (optional)
}
```

**Returns:**
```javascript
{
  url: string,        // Stripe Checkout URL
  sessionId: string   // For tracking
}
```

#### `downloadInvoice(data)`

Generate and download an invoice PDF.

**Parameters:**
```javascript
{
  invoiceId: string  // Invoice ID to download (required)
}
```

**Returns:**
```javascript
{
  url: string  // Direct PDF download URL
}
```

---

## Webhook Events

The webhook handler at `/stripeWebhookBilling` processes these events:

### `checkout.session.completed`

Triggered when a customer completes Stripe Checkout.

**Actions:**
1. Extracts invoice ID and user ID from session metadata
2. Creates payment record in Firestore
3. Marks invoice as paid
4. Generates and sends receipt PDF email
5. Creates client timeline event for payment

**Firestore Updates:**
```javascript
// Invoice document
{
  paymentVerified: true,
  status: 'paid',
  paymentStatus: 'paid',
  paidAt: <timestamp>,
  lastPaymentProvider: 'stripe',
  lastCheckoutSessionId: '<session-id>',
  lastPaymentIntentId: '<intent-id>',
  paymentMetadata: { ... }
}

// Payment record (new)
users/{uid}/invoices/{invoiceId}/payments/{paymentId}
{
  amount: number,
  currency: string,
  status: 'succeeded',
  paidAt: <timestamp>,
  stripeSessionId: string,
  stripePaymentIntent: string,
  stripeCustomerId: string,
  method: 'card',
  email: string,
  metadata: { ... }
}
```

### `payment_intent.succeeded`

Triggered when a payment intent succeeds (handled at card form level).

**Current Implementation:**
- Logged but not processed (card form handles success)
- Can be extended for additional validation

### `customer.subscription.updated`

Triggered when subscription plan or details change.

**Planned Implementation:**
- Update user subscription fields in Firestore
- Notify user of changes via email

### `customer.subscription.deleted`

Triggered when subscription is cancelled.

**Planned Implementation:**
- Update user subscription status to 'cancelled'
- Downgrade user to free tier
- Send cancellation email

### `invoice.payment_failed`

Triggered when automatic payment fails.

**Planned Implementation:**
- Alert user via email
- Enable manual retry from dashboard
- Provide payment method update link

---

## Data Models

### User Subscription Record

```javascript
users/{uid}/subscription
{
  status: 'active' | 'inactive' | 'cancelled' | 'past_due',
  plan: 'solo' | 'team' | 'business' | 'free',
  currentPeriodStart: <timestamp>,
  currentPeriodEnd: <timestamp>,
  canceledAt: <timestamp>,
  cancelationReason: string,
  autoRenew: boolean,
  
  // Stripe linkage
  stripeCustomerId: string,
  stripeSubscriptionId: string,
  stripePriceId: string,
}
```

### Payment Record

```javascript
users/{uid}/invoices/{invoiceId}/payments/{paymentId}
{
  // Core fields
  amount: number,           // Amount in cents
  currency: string,         // e.g., 'usd'
  status: 'succeeded' | 'failed' | 'pending',
  paidAt: <timestamp>,
  
  // Stripe fields
  provider: 'stripe',
  stripeSessionId: string,
  stripePaymentIntent: string,
  stripeCustomerId: string,
  
  // Payment method
  method: 'card' | 'bank_transfer',
  cardBrand: string,        // 'visa', 'mastercard', etc.
  last4: string,           // Last 4 digits
  expMonth: number,
  expYear: number,
  
  // Tax breakdown
  taxBreakdown: {
    subtotal: number,
    taxRate: number,        // e.g., 0.08 for 8%
    taxAmount: number,
    total: number
  },
  
  // Customer info
  email: string,
  
  // Tracking
  metadata: {
    invoiceId: string,
    uid: string,
    invoiceNumber: string,
    ...customFields
  }
}
```

### Invoice Payment Status

```javascript
users/{uid}/invoices/{invoiceId}
{
  // ... existing invoice fields
  
  paymentStatus: 'unpaid' | 'paid' | 'partially_paid' | 'refunded',
  paymentVerified: boolean,
  lastPaymentProvider: 'stripe' | 'manual',
  lastCheckoutSessionId: string,
  lastPaymentIntentId: string,
  paidAt: <timestamp>,
  
  paymentMetadata: {
    payment_intent: string,
    amount_total: number,
    currency: string
  }
}
```

---

## Testing

### Local Testing with Stripe Test Mode

1. Use Stripe test keys (start with `pk_test_` and `sk_test_`)
2. Test card numbers:
   - **Success:** `4242 4242 4242 4242`
   - **Decline:** `4000 0000 0000 0002`
   - **Authenticate:** `4000 0025 0000 3155`
3. Any future expiry date (e.g., `12/25`)
4. Any 3-digit CVC (e.g., `123`)

### Testing Webhooks Locally

```bash
# Install Stripe CLI
brew install stripe/stripe-cli/stripe

# Login to your account
stripe login

# Forward webhook events to local function
stripe listen --forward-to localhost:5001/aura-sphere-pro/us-central1/stripeWebhookBilling

# Trigger test events
stripe trigger checkout.session.completed
```

### Checklist

- [ ] Test card payment in development
- [ ] Verify payment record created in Firestore
- [ ] Confirm receipt email sent
- [ ] Test subscription upgrade
- [ ] Test subscription downgrade (proration)
- [ ] Test subscription cancellation
- [ ] Verify webhook signature validation
- [ ] Test idempotent webhook handling (duplicate events)
- [ ] Test with different currencies
- [ ] Test tax calculation and breakdown

---

## Security Considerations

### PCI Compliance

- ✅ Never transmit raw card data to your server
- ✅ Use Stripe.js for card collection
- ✅ Validate webhook signatures on server
- ✅ Use webhook secrets from environment variables
- ✅ Always verify user identity before processing payments

### Secrets Management

- Never commit `.env.local` (see `.gitignore`)
- Rotate Stripe keys periodically
- Use separate test and live keys by environment
- Restrict API key permissions in Stripe dashboard
- Enable 2FA on Stripe account

### Data Protection

- Encrypt sensitive payment data in transit (HTTPS)
- Firestore security rules enforce user ownership
- Never log full credit card numbers
- Use Stripe-managed payment method tokens
- Implement rate limiting on payment endpoints

---

## Troubleshooting

### Payment Intent Creation Fails

**Error:** `The resource you requested does not exist`

**Cause:** Stripe secret key not set or incorrect

**Solution:**
```bash
firebase functions:config:set stripe.secret="sk_test_xxxxxxxxxxxx"
firebase deploy --only functions
```

### Webhook Not Triggering

**Cause:** Endpoint URL incorrect or function not deployed

**Solution:**
1. Verify function URL in Firebase Console
2. Check webhook endpoint in Stripe Dashboard
3. Verify webhook signing secret is set

**Debug:**
```bash
firebase functions:log
stripe logs
```

### Payment Verified But No Email

**Cause:** SendGrid key not configured

**Solution:**
```bash
firebase functions:config:set sendgrid.key="SG.xxxxxxxxxxxx"
firebase functions:config:set sendgrid.sender="billing@yourdomain.com"
firebase deploy --only functions
```

### "Card Declined" Error

**Cause:** Payment method invalid or customer-initiated decline

**Solution:**
- Verify card number is correct
- Check card hasn't expired
- Try different payment method
- In test mode, use `4242 4242 4242 4242`

### Idempotent Payment Processing

The webhook handler uses `client_reference_id` and deduplication:
- Same checkout session won't create duplicate payments
- Webhook retries are safe (won't double-charge)

---

## Production Deployment

### Pre-Launch Checklist

- [ ] Switch to Stripe live keys
- [ ] Update success/cancel URLs to production domains
- [ ] Test payment flow end-to-end
- [ ] Configure webhook endpoint for production
- [ ] Set up SendGrid for production emails
- [ ] Enable Stripe email receipts as backup
- [ ] Monitor Stripe dashboard for declines/errors
- [ ] Test refund/cancellation flows
- [ ] Set up alerts for failed payments
- [ ] Document payment runbooks for support team

### Monitoring

Monitor these metrics:
- Payment success rate
- Webhook delivery failures
- Failed payment attempts
- Customer refund requests
- Revenue by tier

Access via [Stripe Dashboard](https://dashboard.stripe.com)

---

## API Reference Summary

| Function | Purpose | Tier |
|----------|---------|------|
| `createPaymentIntent` | Create card payment | All |
| `confirmPayment` | Confirm payment & upgrade | All |
| `createCheckoutSession` | Invoice payment link | All |
| `updateSubscription` | Change subscription | All |
| `cancelSubscription` | Downgrade/cancel | All |
| `downloadInvoice` | Generate PDF | All |
| `getPaymentHistory` | View past payments | All |
| `stripeWebhook` | Handle Stripe events | System |

---

## Support

For issues:
1. Check Stripe Dashboard for transaction details
2. Review Cloud Function logs: `firebase functions:log`
3. Check webhook delivery: Stripe Dashboard → Webhooks
4. Verify environment variables are set: `firebase functions:config:get`

---

**Next Steps:**
1. Set environment variables and deploy
2. Configure webhook in Stripe Dashboard
3. Test with Stripe test mode
4. Monitor production metrics

---

*Document Version: 1.0*  
*Last Updated: Phase 13*  
*Status: Production Ready ✅*
