# STRIPE INTEGRATION - COMPLETE SETUP GUIDE

## 📋 Phase 12 Stripe Payment Integration

Complete Stripe payment processing system for AuraSphere Pro. This guide covers setup, testing, and deployment.

---

## 1. STRIPE DASHBOARD SETUP

### Step 1: Create Stripe Account
- Go to https://stripe.com
- Sign up or log in
- Navigate to Dashboard

### Step 2: Get API Keys
1. Click **Settings** → **API Keys**
2. You'll see two modes:
   - **Test Mode** (default) - Use for development
   - **Live Mode** - Use for production

3. Copy these keys:
   - **Publishable Key** (starts with `pk_`)
   - **Secret Key** (starts with `sk_`)

### Step 3: Create Products & Prices
For our 3-tier structure, create:

#### Solo Plan
```
Product: AuraSphere Solo
- Monthly: $9/month → Copy Price ID
- Yearly: $99/year → Copy Price ID
```

#### Team Plan
```
Product: AuraSphere Team
- Monthly: $29/month → Copy Price ID
- Yearly: $299/year → Copy Price ID
```

#### Business Plan
```
Product: AuraSphere Business
- Monthly: $79/month → Copy Price ID
- Yearly: $799/year → Copy Price ID
```

### Step 4: Setup Webhooks
1. Go to **Settings** → **Webhooks**
2. Click **Add endpoint**
3. Endpoint URL: `https://your-domain.com/api/stripe/webhook`
4. Select events to receive:
   - `invoice.paid`
   - `invoice.payment_failed`
   - `customer.subscription.updated`
   - `customer.subscription.deleted`
   - `charge.refunded`
5. Copy webhook signing secret

---

## 2. ENVIRONMENT VARIABLES

### Update `.env.local` (Frontend)
```bash
# Stripe Publishable Key (test mode)
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY_HERE

# Optional: For production
# REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_live_YOUR_KEY_HERE
```

### Update `functions/.env` (Backend)
```bash
# Stripe Secret Key (test mode)
STRIPE_SECRET_KEY=sk_test_YOUR_KEY_HERE

# Stripe Webhook Secret
STRIPE_WEBHOOK_SECRET=whsec_YOUR_SECRET_HERE

# Price IDs from Stripe Dashboard
STRIPE_PRICE_SOLO_MONTHLY=price_XXXXXX
STRIPE_PRICE_SOLO_YEARLY=price_XXXXXX
STRIPE_PRICE_TEAM_MONTHLY=price_XXXXXX
STRIPE_PRICE_TEAM_YEARLY=price_XXXXXX
STRIPE_PRICE_BUSINESS_MONTHLY=price_XXXXXX
STRIPE_PRICE_BUSINESS_YEARLY=price_XXXXXX

# Optional: For production
# STRIPE_SECRET_KEY=sk_live_YOUR_KEY_HERE
```

⚠️ **IMPORTANT**: 
- Never commit `.env` files
- Add to `.gitignore`
- Use GitHub Secrets for CI/CD
- Rotate keys immediately if exposed

---

## 3. CODE INTEGRATION

### A. Register Cloud Functions

Add to `functions/src/index.ts`:

```typescript
// Import Stripe functions
export { 
  stripe_createPaymentIntent,
  stripe_confirmPayment,
  stripe_createSubscription,
  stripe_updateSubscription,
  stripe_cancelSubscription,
  stripe_savePaymentMethod,
  stripe_deletePaymentMethod,
  stripe_getBillingPortalUrl,
  stripe_getInvoice,
  stripe_refund,
  stripe_webhook
} from './stripe/stripePayments';
```

### B. Update Frontend Payment Service

The `lib/services/stripe_service.dart` handles all payment operations:

```javascript
// Create payment intent
const { clientSecret } = await stripeService.createPaymentIntent(
  userId,      // User ID
  2900,        // Amount in cents ($29.00)
  'team',      // Tier ID
  'monthly'    // Billing cycle
);

// Confirm payment
await stripeService.confirmPayment(
  userId,
  clientSecret,
  'team'
);

// Create subscription
await stripeService.createSubscription(
  userId,
  'team',
  'monthly',
  paymentMethodId
);

// Upgrade/downgrade
await stripeService.updateSubscription(userId, 'business');

// Cancel
await stripeService.cancelSubscription(userId);

// Get payment history
const payments = await stripeService.getPaymentHistory(userId, 10);

// Get billing portal URL
const portalUrl = await stripeService.getBillingPortalUrl(userId);
```

### C. Add Payment UI Components

Use in React components:

```jsx
import {
  StripePaymentContainer,
  CardPaymentForm,
  SubscriptionUpgrade,
  BillingHistory,
  PaymentMethodManager
} from './components/PaymentComponents';

export function SettingsPage() {
  return (
    <StripePaymentContainer>
      <div className="settings">
        {/* Payment form for purchases */}
        <CardPaymentForm
          tierId="team"
          billingCycle="monthly"
          amount={2900}
          onSuccess={(result) => {
            console.log('Payment successful!', result);
            // Redirect to dashboard
          }}
          onError={(error) => {
            console.error('Payment failed:', error);
          }}
        />

        {/* Upgrade UI */}
        <SubscriptionUpgrade
          currentTierId="solo"
          onUpgradeComplete={(result) => {
            console.log('Upgraded to:', result.tierId);
          }}
        />

        {/* Billing history */}
        <BillingHistory userId={userId} />

        {/* Payment methods */}
        <PaymentMethodManager userId={userId} />
      </div>
    </StripePaymentContainer>
  );
}
```

---

## 4. TESTING PAYMENT FLOW

### Test Card Numbers
Use these in test mode:

| Card Type | Number | Exp | CVC |
|-----------|--------|-----|-----|
| Visa (Success) | 4242 4242 4242 4242 | 12/25 | 123 |
| Visa (Decline) | 4000 0000 0000 0002 | 12/25 | 123 |
| Amex | 3782 822463 10005 | 12/25 | 1234 |

### Test Steps
1. **Create Payment Intent**
   ```bash
   curl -X POST http://localhost:5001/aurasphere-pro/us-central1/stripe_createPaymentIntent \
     -H "Authorization: Bearer TEST_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "userId": "test-user-id",
       "amount": 2900,
       "tierId": "team",
       "billingCycle": "monthly"
     }'
   ```

2. **Use test card in UI**
   - Card: 4242 4242 4242 4242
   - Exp: 12/25
   - CVC: 123

3. **Confirm Payment**
   ```bash
   curl -X POST http://localhost:5001/aurasphere-pro/us-central1/stripe_confirmPayment \
     -H "Authorization: Bearer TEST_TOKEN" \
     -H "Content-Type: application/json" \
     -d '{
       "userId": "test-user-id",
       "clientSecret": "pi_xxx_secret_xxx",
       "tierId": "team"
     }'
   ```

4. **Verify in Stripe Dashboard**
   - Go to Payments (test mode)
   - Should see payment succeeded

---

## 5. FIRESTORE SCHEMA

Payment records are automatically stored:

```
users/
  {userId}/
    payments/
      {paymentId}/
        paymentIntentId: "pi_xxx"
        amount: 2900
        currency: "usd"
        tierId: "team"
        status: "succeeded"
        timestamp: Timestamp
        chargeId: "ch_xxx"
    
    paymentMethods/
      {methodId}/
        stripePaymentMethodId: "pm_xxx"
        isDefault: true
        createdAt: Timestamp
    
    subscription/ (top-level in user doc)
      tierId: "team"
      status: "active"
      stripeSubscriptionId: "sub_xxx"
      stripeCustomerId: "cus_xxx"
      billingCycle: "monthly"
      currentPeriodStart: Date
      currentPeriodEnd: Date
      startDate: Timestamp
      lastPaymentDate: Timestamp
```

---

## 6. WEBHOOK HANDLING

The webhook endpoint automatically:
1. **invoice.paid** → Update subscription status to "active"
2. **invoice.payment_failed** → Update status to "past_due"
3. **customer.subscription.updated** → Sync subscription data
4. **customer.subscription.deleted** → Mark as "canceled"
5. **charge.refunded** → Log refund activity

---

## 7. SECURITY CHECKLIST

- [ ] Stripe keys added to `.env` (not committed)
- [ ] Test keys working in development
- [ ] Webhook secret configured
- [ ] HTTPS enabled for production
- [ ] Client-side validation on card form
- [ ] Server-side validation on payment intent
- [ ] Payment methods attached to customer
- [ ] Refund permission restricted to admins
- [ ] Error messages don't leak sensitive info
- [ ] PCI compliance verified (Stripe handles this)

---

## 8. DEPLOYMENT CHECKLIST

### Pre-Deployment
```bash
# 1. Build backend functions
cd functions
npm install
npm run build

# 2. Deploy functions
firebase deploy --only functions

# 3. Build web app
flutter build web --release

# 4. Deploy web app
firebase deploy --only hosting
```

### Update Environment
1. Swap test keys for live keys
2. Update `.env` in production
3. Verify webhook endpoint is live
4. Test with small payment
5. Monitor logs for errors

### Post-Deployment
- Test full payment flow end-to-end
- Verify emails are sent
- Check Stripe dashboard for activity
- Monitor payment success rate
- Set up Stripe alerts

---

## 9. STRIPE COST STRUCTURE

- **Transaction fees**: 2.9% + $0.30 per successful card charge
- **Monthly subscription**: No additional fees
- **Refunds**: Same percentage
- **Example**: $29 tier = $0.84 fee + $29.00 = ~2.8% effective rate

---

## 10. USEFUL COMMANDS

### Local Testing
```bash
# Start Stripe CLI listener (downloads test events)
stripe listen --forward-to localhost:5001/aurasphere-pro/us-central1/stripe_webhook

# View test events
stripe events list --limit 10

# Trigger test payment
stripe charges create -a 2900 -c tok_visa --description "Test payment"
```

### Database Operations
```bash
# View test payments in Firestore
firebase firestore:inspect users/test-user-id/payments

# Clear test data
firebase firestore:delete users/test-user-id/payments --project aurasphere-pro-test
```

---

## 11. SUPPORT & TROUBLESHOOTING

### Common Issues

**Issue**: "No such parameter: 'amount'" in payment intent
- **Fix**: Use amount in cents (e.g., 2900 for $29.00)

**Issue**: "Invalid API Key"
- **Fix**: Verify key matches environment (test vs live)

**Issue**: "Webhook signature verification failed"
- **Fix**: Ensure webhook secret is correct

**Issue**: Card declined
- **Fix**: In test mode, use 4242 4242 4242 4242 (for success)

### Debug Mode
```javascript
// Enable in stripe_service.dart
const DEBUG = true;

if (DEBUG) {
  console.log('Payment intent:', result);
  console.log('Stripe response:', paymentIntent);
}
```

### Stripe Documentation
- API Reference: https://stripe.com/docs/api
- React Integration: https://stripe.com/docs/stripe-js/react
- Webhooks: https://stripe.com/docs/webhooks

---

## 12. NEXT STEPS

1. ✅ Create Stripe account and get keys
2. ✅ Create products and prices
3. ✅ Set up webhook endpoint
4. ✅ Add environment variables
5. ✅ Test payment flow with test cards
6. ✅ Deploy functions and web app
7. ✅ Monitor logs for errors
8. ✅ Swap to live keys when ready
9. ✅ Set up monitoring and alerts
10. ✅ Document for team

---

## Summary

You now have a **complete, production-ready Stripe integration** with:
- ✅ Payment intent creation
- ✅ Subscription management
- ✅ Payment history tracking
- ✅ Invoice generation
- ✅ Webhook handling
- ✅ Refund processing
- ✅ Secure payment UI
- ✅ Billing portal access

**To activate**: Add your Stripe API keys to the environment files and run the deployment commands above.

Need help? Check the Stripe docs or contact support@stripe.com
