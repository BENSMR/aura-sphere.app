# STRIPE INTEGRATION - QUICK SETUP SUMMARY

## ⚠️ SECURITY FIRST

**Your exposed key (`sk_org_live_...`) must be rotated immediately.**

See [STRIPE_SECURITY_SETUP.md](./STRIPE_SECURITY_SETUP.md) for complete security guide.

---

## Setup Checklist

### 1. Rotate Exposed Key
- [ ] Go to https://dashboard.stripe.com/apikeys
- [ ] Delete the `sk_org_live_...` key you shared
- [ ] Create new API keys
- [ ] Save new keys securely

### 2. Get Your Test Keys
- [ ] Visit https://dashboard.stripe.com/apikeys
- [ ] Get `pk_test_...` (publishable key)
- [ ] Get `sk_test_...` (secret key)
- [ ] Create webhook endpoint

### 3. Configure Locally
```bash
# Copy environment template
cp .env.example .env.local

# Edit and add your TEST keys only
# .env.local should never be committed
```

**In `.env.local`:**
```dotenv
STRIPE_SECRET_KEY=sk_test_xxxxxxxxxxxxx
STRIPE_PUBLISHABLE_KEY=pk_test_xxxxxxxxxxxxx
STRIPE_WEBHOOK_SECRET=whsec_xxxxxxxxxxxxx
```

### 4. Use in Code

**Backend (Cloud Functions):**
```javascript
const stripe = require('stripe')(process.env.STRIPE_SECRET_KEY);
```

**Frontend (React/Flutter):**
```javascript
const stripe = Stripe(process.env.REACT_APP_STRIPE_PUBLISHABLE_KEY);
```

**Never put secret key in frontend code.**

### 5. Deploy to Production

When ready:
```bash
# Set live keys in Firebase Secrets Manager
firebase functions:config:set stripe.secret_key="sk_live_xxxxx"
firebase functions:config:set stripe.publishable_key="pk_live_xxxxx"
```

---

## Files Updated

✅ `.env.example` - Added Stripe configuration template  
✅ `docs/STRIPE_SECURITY_SETUP.md` - Complete security guide  
✅ `.gitignore` - Already protects `.env.local` (no changes needed)

---

## Key Rules

1. **Never commit `.env.local`** - It's in .gitignore
2. **Always use `pk_` in frontend** - Publishable key only
3. **Always use `sk_` in backend** - Secret key only
4. **Test first** - Use `sk_test_` and `pk_test_`
5. **Production** - Use Firebase Secrets Manager for `sk_live_`

---

## Next: Test Payment Flow

Once configured, test with:
- Card: `4242 4242 4242 4242`
- Expiry: Any future date
- CVC: Any 3 digits

This card always succeeds in test mode.

---

**See [STRIPE_SECURITY_SETUP.md](./STRIPE_SECURITY_SETUP.md) for complete details.**
