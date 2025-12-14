# STRIPE INTEGRATION SECURITY GUIDE

## ⚠️ CRITICAL: Your Live Key Has Been Exposed

You shared a **LIVE Stripe API key** (`sk_org_live_...`). This key is now **COMPROMISED** and must be rotated immediately.

### Immediate Actions Required

1. **Rotate the key NOW**
   - Go to https://dashboard.stripe.com/apikeys
   - Delete the exposed key
   - Create a new API key
   - Update your environment

2. **Audit your account**
   - Check Stripe transaction history
   - Review recent API calls
   - Enable 2FA on Stripe account

3. **Never share keys in plain text**
   - Use secure secret management (1Password, LastPass, Vault)
   - Use GitHub Secrets for CI/CD
   - Use Firebase Secret Manager for Cloud Functions
   - Use .env files (never commit them)

---

## Proper Setup Instructions

### Step 1: Get Your Keys from Stripe

1. Go to https://dashboard.stripe.com/apikeys
2. You'll see two keys:
   - **Publishable Key** (`pk_...`) - Safe to expose in frontend
   - **Secret Key** (`sk_...`) - KEEP SECRET
3. Also create a Webhook Secret for payment events

### Step 2: Store Keys Securely

**For Development:**
```
cp .env.example .env.local
# Edit .env.local and add your TEST keys
```

**For Production (Firebase Cloud Functions):**
```bash
# Use Firebase Secrets Manager
firebase functions:config:set stripe.secret_key="sk_live_..."
firebase functions:config:set stripe.publishable_key="pk_live_..."
firebase functions:config:set stripe.webhook_secret="whsec_..."
```

**For GitHub Actions / CI/CD:**
```
Repository Settings → Secrets and Variables → Actions
Add secrets:
- STRIPE_SECRET_KEY
- STRIPE_PUBLISHABLE_KEY
- STRIPE_WEBHOOK_SECRET
```

### Step 3: Update Environment Variables

**Local file (.env.local):**
```dotenv
STRIPE_SECRET_KEY=sk_test_xxxxx  # For testing
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxx
```

**Production (Firebase):**
```bash
firebase functions:config:set stripe.secret_key="sk_live_xxxxx"
```

### Step 4: Use in Your Code

**Backend (Cloud Functions):**
```javascript
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);

exports.createPaymentIntent = functions.https.onCall(async (data, context) => {
  const paymentIntent = await stripe.paymentIntents.create({
    amount: data.amount,
    currency: 'usd',
    description: 'AuraSphere subscription'
  });
  
  return { clientSecret: paymentIntent.client_secret };
});
```

**Frontend (React/Flutter):**
```javascript
// NEVER put secret key here
const stripe = Stripe('pk_test_xxxxx'); // Publishable key only

// Call backend to get client secret
const response = await fetch('/create-payment-intent', {
  method: 'POST',
  body: JSON.stringify({ amount: 2900, tierId: 'team' })
});

const { clientSecret } = await response.json();
const result = await stripe.confirmCardPayment(clientSecret);
```

### Step 5: Handle Webhooks Securely

**Cloud Function (functions/src/billing/stripeWebhook.ts):**
```typescript
export const stripeWebhook = functions.https.onRequest(async (req, res) => {
  const sig = req.headers['stripe-signature'];
  const webhookSecret = process.env.STRIPE_WEBHOOK_SECRET;
  
  let event;
  try {
    event = stripe.webhooks.constructEvent(
      req.rawBody,
      sig,
      webhookSecret
    );
  } catch (error) {
    res.status(400).send(`Webhook Error: ${error.message}`);
    return;
  }
  
  // Handle different event types
  switch (event.type) {
    case 'payment_intent.succeeded':
      await handlePaymentSuccess(event.data.object);
      break;
    case 'charge.failed':
      await handlePaymentFailure(event.data.object);
      break;
    case 'customer.subscription.updated':
      await handleSubscriptionUpdate(event.data.object);
      break;
  }
  
  res.json({ received: true });
});
```

---

## Security Checklist

- [ ] Exposed key has been rotated in Stripe dashboard
- [ ] New key is stored ONLY in .env.local (not committed)
- [ ] .env.local is in .gitignore
- [ ] .env.example shows structure but NOT actual keys
- [ ] Production keys stored in Firebase Secrets Manager
- [ ] GitHub Actions secrets configured
- [ ] Stripe webhook signature validated
- [ ] Only publishable key used in frontend code
- [ ] 2FA enabled on Stripe account
- [ ] Audit log reviewed for unauthorized access

---

## Files to Update

| File | Contains | Action |
|------|----------|--------|
| `.env.local` | TEST keys for dev | Edit locally (NOT committed) |
| `.env.example` | Structure only | Commit (shows format, no secrets) |
| `firebase/functions/...` | Backend logic | Use `process.env.STRIPE_SECRET_KEY` |
| `functions/.env.production` | LIVE keys | Store in Firebase Secrets, NOT file |
| `lib/services/payment_service.dart` | Frontend client | Use publishable key only |

---

## Environment Files Structure

```
.env.local              ← Dev keys (local testing) [NOT COMMITTED]
.env.example           ← Template (structure only) [COMMITTED]
.env.production        ← Prod keys (Cloud Functions) [NOT COMMITTED]
firebase/...           ← Backend code
lib/services/...       ← Frontend code
```

---

## Testing with Stripe Test Data

Use Stripe's test card numbers:

| Card | Behavior |
|------|----------|
| `4242 4242 4242 4242` | Success |
| `4000 0000 0000 0002` | Card declined |
| `4000 0025 0000 3155` | Requires 3D Secure |

**Test with:**
- Email: any email
- Expiry: any future date
- CVC: any 3 digits

---

## Next Steps

1. ✅ Rotate your exposed key
2. ✅ Get new test keys from Stripe
3. ✅ Update `.env.local` with test keys
4. ✅ Test payment flow locally
5. ✅ Get live keys and update Firebase Secrets
6. ✅ Deploy to production

---

**Questions?** See [Stripe Docs](https://stripe.com/docs) or your project's STRIPE_PAYMENT_INTEGRATION_GUIDE.md
