# Stripe Integration - Quick Reference

**Last Updated:** Phase 13  
**Status:** Production Ready ✅

---

## Quick Start (5 Minutes)

### 1. Set Environment Variables
```bash
# Copy .env.example to .env.local
cp .env.example .env.local

# Add Stripe test keys
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxx
REACT_APP_SUCCESS_URL=http://localhost:3000/billing/success
REACT_APP_CANCEL_URL=http://localhost:3000/billing/cancel
```

### 2. Configure Firebase
```bash
firebase functions:config:set \
  stripe.secret="sk_test_xxxxxxxxxxxx" \
  stripe.webhook_secret="whsec_xxxxxxxxxxxx"
```

### 3. Deploy
```bash
firebase deploy --only functions
```

### 4. Test with Stripe Test Card
- Card: `4242 4242 4242 4242`
- Expiry: Any future date (e.g., `12/25`)
- CVC: Any 3 digits (e.g., `123`)

---

## API Quick Reference

### Payment Intent (Card Payment)
```javascript
import stripeService from '../services/stripe_service';

const { clientSecret, paymentIntentId } = 
  await stripeService.createPaymentIntent(
    2900,        // Amount in cents ($29.00)
    'team',      // Tier ID
    'monthly'    // Billing cycle
  );
```

### Checkout Session (Invoice Payment)
```javascript
const { url, sessionId } = 
  await stripeService.createCheckoutSession(invoiceId);

// Redirect user to payment
window.location.href = url;
```

### Subscription Management
```javascript
// Upgrade
await stripeService.updateSubscription('team');

// Downgrade
await stripeService.updateSubscription('solo');

// Cancel
await stripeService.cancelSubscription('Trying other service');
```

### Payment History
```javascript
const payments = await stripeService.getPaymentHistory();
// Returns array of payment records with invoices

payments.forEach(payment => {
  console.log(`Invoice ${payment.invoiceNumber}: ${payment.amount}`);
});
```

### Download Invoice
```javascript
await stripeService.downloadInvoice(invoiceId);
// Triggers browser download of PDF
```

---

## Component Integration

### Payment Form in a Screen
```jsx
import { CardPaymentForm } from '../components/PaymentComponents';

export function BillingScreen() {
  return (
    <CardPaymentForm
      tierId="team"
      billingCycle="monthly"
      amount={2900}
      onSuccess={(payment) => {
        console.log('Payment succeeded:', payment);
        navigate('/dashboard');
      }}
      onError={(error) => {
        showError(error.message);
      }}
    />
  );
}
```

### Payment History Display
```jsx
import { BillingHistoryComponent } from '../components/PaymentComponents';

export function HistoryScreen() {
  return <BillingHistoryComponent />;
}
```

### Subscription Selector
```jsx
import { SubscriptionUpgradeModal } from '../components/PaymentComponents';

<SubscriptionUpgradeModal
  onUpgrade={(tier) => {
    console.log(`Upgrading to ${tier}`);
  }}
/>
```

---

## Common Errors & Solutions

| Error | Cause | Solution |
|-------|-------|----------|
| "Stripe secret not set" | Config not set | `firebase functions:config:set stripe.secret="sk_..."` |
| "Card declined" | Invalid test card | Use `4242 4242 4242 4242` |
| "Webhook not triggering" | Endpoint misconfigured | Check Stripe Dashboard webhooks |
| "Payment succeeded but no update" | Firestore rule issue | Verify security rules deployed |
| "PubKey not found" | Env var missing | Add to `.env.local` and restart dev server |

---

## Testing Checklist

- [ ] Payment succeeds with `4242 4242 4242 4242`
- [ ] Payment fails with `4000 0000 0000 0002`
- [ ] Webhook triggers on Stripe Dashboard
- [ ] Firestore updates after payment
- [ ] Email receipt sent (if configured)
- [ ] Subscription tier changes after payment
- [ ] Invoice marked as paid
- [ ] Payment appears in history

---

## Deployment to Production

### 1. Get Live Keys
1. Go to [Stripe Dashboard](https://dashboard.stripe.com/apikeys)
2. Switch to live mode (toggle top-left)
3. Copy live keys (start with `pk_live_` and `sk_live_`)

### 2. Update Configuration
```bash
firebase functions:config:set stripe.secret="sk_live_xxxxxxxxxxxx"
firebase functions:config:set stripe.webhook_secret="whsec_xxxxxxxxxxxx"
```

### 3. Update Environment
```env
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxx
REACT_APP_SUCCESS_URL=https://yourdomain.com/billing/success
REACT_APP_CANCEL_URL=https://yourdomain.com/billing/cancel
```

### 4. Deploy
```bash
firebase deploy --only functions
```

### 5. Verify
```bash
firebase functions:log
# Should show no errors
```

---

## File Locations

| Component | File | Lines |
|-----------|------|-------|
| Service Layer | `web/src/services/stripe_service.js` | 450+ |
| Config Module | `web/src/stripe/stripeConfig.js` | 200+ |
| UI Components | `web/src/components/PaymentComponents.jsx` | 489 |
| Webhook Handler | `functions/src/billing/stripeWebhook.ts` | 226 |
| Checkout Session | `functions/src/billing/createCheckoutSession.ts` | 94 |
| Full Guide | `docs/STRIPE_INTEGRATION_COMPLETE.md` | 500+ |
| Deployment Check | `docs/STRIPE_DEPLOYMENT_CHECKLIST.md` | 400+ |

---

## Debug Tips

### View Function Logs
```bash
firebase functions:log --follow
firebase functions:log --function=stripeWebhookBilling
```

### Check Firestore
```bash
# Go to Firebase Console
# Collection: users → {uid} → subscription
# Document: See current plan, stripeCustomerId, etc.

# Collection: users → {uid} → invoices → {id} → payments
# Documents: See payment records with amount, status, etc.
```

### Stripe Dashboard
- [API Keys](https://dashboard.stripe.com/apikeys) - View test/live keys
- [Webhooks](https://dashboard.stripe.com/webhooks) - Configure endpoint
- [Events](https://dashboard.stripe.com/events) - View webhook deliveries
- [Customers](https://dashboard.stripe.com/customers) - View customer records
- [Payments](https://dashboard.stripe.com/payments) - View transactions

### Firebase Console
- [Functions](https://console.firebase.google.com/functions) - View logs
- [Firestore](https://console.firebase.google.com/firestore) - View data
- [Rules](https://console.firebase.google.com/firestore/rules) - Check rules

---

## Important Constants

```javascript
// Subscription tiers
const TIERS = {
  SOLO: 'solo',      // $9/month
  TEAM: 'team',      // $29/month
  BUSINESS: 'business' // $79/month
};

// Billing cycles
const CYCLES = {
  MONTHLY: 'monthly',
  YEARLY: 'yearly'
};

// Amounts in cents
const AMOUNTS = {
  SOLO: {
    monthly: 900,      // $9.00
    yearly: 9900       // $99.00
  },
  TEAM: {
    monthly: 2900,     // $29.00
    yearly: 29900      // $299.00
  },
  BUSINESS: {
    monthly: 7900,     // $79.00
    yearly: 79900      // $799.00
  }
};

// Payment statuses
const STATUSES = {
  UNPAID: 'unpaid',
  PAID: 'paid',
  FAILED: 'failed',
  REFUNDED: 'refunded'
};
```

---

## Security Checklist

- [ ] Never commit `.env` files
- [ ] Use `process.env.REACT_APP_*` for frontend keys (publishable only)
- [ ] Use Firebase Functions config for backend keys (secret)
- [ ] Validate webhook signatures on server
- [ ] Verify user authentication before payments
- [ ] Use HTTPS in production
- [ ] Restrict Stripe API key permissions
- [ ] Enable 2FA on Stripe account
- [ ] Rotate keys periodically

---

## Performance Tips

1. **Cache subscription data** - Query once, store in user state
2. **Lazy load Stripe.js** - Only when payment screen loads
3. **Debounce card validation** - Don't validate on every keystroke
4. **Use Stripe's built-in retry** - Webhooks auto-retry on failure
5. **Index Firestore queries** - For payment history queries

---

## Next Steps

1. **Set environment variables** → See "Quick Start" above
2. **Deploy functions** → `firebase deploy --only functions`
3. **Test with test cards** → Use `4242 4242 4242 4242`
4. **Configure webhook** → See [Setup Instructions](docs/STRIPE_INTEGRATION_COMPLETE.md)
5. **Deploy to production** → See "Deployment to Production" above

---

## Useful Links

- 📖 [Full Integration Guide](docs/STRIPE_INTEGRATION_COMPLETE.md)
- ✅ [Deployment Checklist](docs/STRIPE_DEPLOYMENT_CHECKLIST.md)
- 📊 [Phase 13 Summary](PHASE_13_STRIPE_COMPLETE.md)
- 🔑 [Get Stripe Keys](https://dashboard.stripe.com/apikeys)
- 📚 [Stripe Docs](https://stripe.com/docs)
- 🐛 [Firebase Functions Logs](https://console.firebase.google.com/functions/logs)

---

*For detailed information, see the full integration guide.*

*Questions? Check the troubleshooting section in STRIPE_INTEGRATION_COMPLETE.md*
