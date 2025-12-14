# 🔐 API Keys & Configuration Checklist

**Status:** Production Ready (Missing some keys to deploy)  
**Last Updated:** December 14, 2025  
**Platform:** AuraSphere Pro

---

## 📋 Configuration Summary

| Service | Purpose | Status | Priority | Action |
|---------|---------|--------|----------|--------|
| **Firebase** | Backend, Auth, Storage | ✅ Configured | CRITICAL | Already set up |
| **Stripe** | Payment processing | ⏳ Partial | CRITICAL | Set SECRET + WEBHOOK |
| **Resend** | Email service | ⏳ Partial | HIGH | Set API_KEY |
| **OpenAI** | AI features | ⏳ Optional | MEDIUM | Set API_KEY |
| **SendGrid** | Email fallback | ⏳ Optional | LOW | Set API_KEY (if needed) |

---

## 🔑 Required API Keys (Must Set Before Going Live)

### 1. **Stripe Payment Processing** (CRITICAL)
**Purpose:** Handle all payment transactions  
**Status:** ⚠️ Not configured yet

#### Where to get:
- Go to: https://dashboard.stripe.com/apikeys
- Copy test keys (starting with `pk_test_` and `sk_test_`)

#### What you need:
- `sk_test_...` (Secret key for backend)
- `whsec_test_...` (Webhook signing secret)
- `pk_test_...` (Publishable key for frontend)

#### How to set (2 options):

**Option A: Firebase CLI (Recommended)**
```bash
firebase functions:config:set \
  stripe.secret="sk_test_YOUR_KEY_HERE" \
  stripe.webhook_secret="whsec_YOUR_KEY_HERE"
```

**Option B: GitHub Actions Secret** (for automated deployment)
1. Go to: https://github.com/BENSMR/aura-sphere.app/settings/secrets/actions
2. Click "New repository secret"
3. Name: `FIREBASE_STRIPE_SECRET` 
4. Value: `sk_test_YOUR_KEY_HERE`

#### Frontend (.env):
```bash
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_KEY_HERE
```

**Test Cards:**
- Success: `4242 4242 4242 4242`
- Decline: `4000 0000 0000 0002`

---

### 2. **Resend Email Service** (HIGH PRIORITY)
**Purpose:** Send transactional emails (welcome, receipts, etc)  
**Status:** ⚠️ Installed but not configured

#### Where to get:
- Go to: https://resend.com
- Sign up → API Keys section
- Copy your API key (starts with `re_`)

#### How to set:
```bash
firebase functions:config:set resend.api_key="re_YOUR_KEY_HERE"
```

#### What it's used for:
- ✅ Welcome emails on user signup
- ✅ Payment receipts
- ✅ CRM export confirmations
- ✅ Contact form submissions
- ✅ Password reset emails

#### Files using Resend:
- `functions/src/email/resendService.ts`
- `functions/src/auth/welcomeEmail.ts`

---

### 3. **Firebase Service Account** (CRITICAL for CI/CD)
**Purpose:** Automated GitHub Actions deployment  
**Status:** ⏳ Needed for GitHub Actions

#### Where to get:
1. Go to: https://console.firebase.google.com/project/aurasphere-pro/settings/serviceaccounts/adminsdk
2. Click "Generate New Private Key"
3. Download JSON file

#### How to set (base64 encode):
```bash
# 1. Encode the JSON file to base64
base64 -i /path/to/firebase-key.json | pbcopy  # macOS
cat /path/to/firebase-key.json | base64 -w0 | pbcopy  # Linux

# 2. Go to GitHub:
# https://github.com/BENSMR/aura-sphere.app/settings/secrets/actions

# 3. Create secret named: FIREBASE_SERVICE_ACCOUNT
# 4. Paste the base64-encoded content
```

#### Used by:
- `.github/workflows/deploy.yml` (automatic Cloud Functions deployment)

---

## 🔧 Optional API Keys (Nice to have, not blocking)

### 4. **OpenAI** (OPTIONAL - AI Chat Features)
**Purpose:** AI-powered features  
**Status:** ⏳ Not configured

#### Where to get:
- Go to: https://platform.openai.com/api-keys
- Create new API key

#### How to set:
```bash
firebase functions:config:set openai.key="sk_YOUR_KEY_HERE"
```

#### What it's used for:
- AI chat assistant
- Email suggestions
- Content generation
- Financial insights

#### Files using OpenAI:
- `functions/src/ai/aiAssistant.ts`
- `functions/src/ai/financeCoach.ts`

---

### 5. **SendGrid Email** (OPTIONAL - Email Backup)
**Purpose:** Alternative email service  
**Status:** ⏳ Not configured

#### Where to get:
- Go to: https://sendgrid.com
- Settings → API Keys
- Create new API key (copy full key starting with `SG.`)

#### How to set:
```bash
firebase functions:config:set sendgrid.key="SG_YOUR_KEY_HERE"
```

#### When to use:
- Only if Resend fails
- Currently using Resend as primary

---

## ✅ Checklist - What to Do Now

### Phase 1: Get Your Keys (5 minutes)
- [ ] **Stripe** - Get from https://dashboard.stripe.com/apikeys
  - [ ] Copy `sk_test_...` (secret key)
  - [ ] Copy `whsec_test_...` (webhook secret)
  - [ ] Copy `pk_test_...` (publishable key)

- [ ] **Resend** - Get from https://resend.com/api-keys
  - [ ] Copy `re_...` API key

- [ ] **Firebase Service Account** - Get from Firebase Console
  - [ ] Download JSON file from service accounts

### Phase 2: Configure Firebase Functions (3 minutes)
```bash
# Set Stripe
firebase functions:config:set \
  stripe.secret="sk_test_YOUR_SECRET_KEY" \
  stripe.webhook_secret="whsec_YOUR_WEBHOOK_SECRET"

# Set Resend
firebase functions:config:set resend.api_key="re_YOUR_API_KEY"

# Verify
firebase functions:config:get
```

### Phase 3: Configure Frontend (.env)
Create or update `.env.production`:
```bash
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_test_YOUR_PUBLISHABLE_KEY
```

### Phase 4: Configure GitHub Actions (for auto-deploy)
1. Go to: https://github.com/BENSMR/aura-sphere.app/settings/secrets/actions
2. Create secret: `FIREBASE_SERVICE_ACCOUNT` (base64-encoded JSON)
3. Push to GitHub to trigger auto-deployment

### Phase 5: Test Everything (5 minutes)
```bash
# Build functions
cd functions && npm run build && cd ..

# Deploy functions
firebase deploy --only functions

# Test Stripe with test card 4242 4242 4242 4242
# Check Firebase logs
firebase functions:log
```

---

## 🚨 Keys Currently Missing

| Key | File | Status | Blocking Deploy? |
|-----|------|--------|------------------|
| `stripe.secret` | Functions config | ❌ Not set | YES |
| `stripe.webhook_secret` | Functions config | ❌ Not set | YES |
| `REACT_APP_STRIPE_PUBLISHABLE_KEY` | `.env.production` | ❌ Not set | YES |
| `resend.api_key` | Functions config | ❌ Not set | NO (falls back gracefully) |
| `FIREBASE_SERVICE_ACCOUNT` | GitHub secret | ❌ Not set | YES (for CI/CD) |
| `openai.key` | Functions config | ❌ Not set | NO (optional features) |

---

## 🔗 Critical File Locations

### Backend (Functions)
- **Stripe config used in:**
  - `functions/src/stripe/stripePayments.ts` - Line 17
  - `functions/src/billing/stripeWebhook.ts` - Line 32

- **Resend config used in:**
  - `functions/src/email/resendService.ts` - Line 11
  - `functions/src/auth/welcomeEmail.ts` - Line 3

### Frontend
- **Stripe config used in:**
  - `web/src/stripe/stripeConfig.js` - Line 20
  - `web/src/services/stripe_service.js` - Throughout

### CI/CD
- **GitHub Actions workflow:**
  - `.github/workflows/deploy.yml` - Line 21
  - Uses `FIREBASE_SERVICE_ACCOUNT` secret

---

## 🏃 Quick Start (Do This Now)

```bash
# 1. Get your Stripe test keys from dashboard
# 2. Run this command:

firebase functions:config:set \
  stripe.secret="sk_test_YOUR_KEY" \
  stripe.webhook_secret="whsec_YOUR_KEY"

# 3. Get Resend API key
# 4. Run this command:

firebase functions:config:set resend.api_key="re_YOUR_KEY"

# 5. Build and deploy
cd functions && npm run build && cd ..
firebase deploy --only functions

# 6. Test a payment with card: 4242 4242 4242 4242
```

---

## 📊 Configuration Status by Environment

### Development
- ✅ Firebase: Configured (emulator)
- ⏳ Stripe: Test keys (when set)
- ⏳ Resend: Test mode (when set)
- ✅ Localhost: Working

### Staging
- ✅ Firebase: Production DB
- ⏳ Stripe: Test keys
- ⏳ Resend: Test mode
- ✅ GitHub Pages: Live

### Production (Go-Live)
- ✅ Firebase: Production DB (same as staging)
- ⚠️ Stripe: Switch to LIVE keys (`sk_live_...`)
- ⚠️ Resend: Production API key
- ✅ GitHub Pages: aura-sphere.app (live)

**To switch to production:**
```bash
firebase functions:config:set \
  stripe.secret="sk_live_YOUR_LIVE_KEY" \
  stripe.webhook_secret="whsec_live_YOUR_WEBHOOK_SECRET"
```

---

## 🔒 Security Best Practices

✅ **Do:**
- [ ] Never commit `.env` files to Git
- [ ] Use Firebase config for backend secrets
- [ ] Use GitHub secrets for CI/CD
- [ ] Rotate keys periodically
- [ ] Enable 2FA on all service accounts
- [ ] Limit API key permissions in dashboards
- [ ] Use test keys in development
- [ ] Use separate live keys for production

❌ **Don't:**
- Never hardcode keys in code
- Never commit keys to GitHub
- Never share API keys in Slack/email
- Never use live keys in development
- Never use test keys in production
- Never grant unnecessary API permissions

---

## 🆘 Troubleshooting

### "Stripe secret not set" error
```bash
# Check current config
firebase functions:config:get

# Should show stripe.secret value
# If not, set it:
firebase functions:config:set stripe.secret="sk_test_YOUR_KEY"
```

### "RESEND_API_KEY not found" error
```bash
firebase functions:config:set resend.api_key="re_YOUR_KEY"
```

### GitHub Actions deployment failing
1. Check secret is set: https://github.com/BENSMR/aura-sphere.app/settings/secrets/actions
2. Verify it's base64-encoded Firebase service account JSON
3. Check workflow file: `.github/workflows/deploy.yml`

### Payment declining during test
- Use test card: `4242 4242 4242 4242`
- Use test mode in Stripe Dashboard
- Check Stripe logs: https://dashboard.stripe.com/events
- Verify webhook endpoint is configured

---

## 📞 Support Links

| Service | Documentation | Dashboard | Support |
|---------|---|---|---|
| **Stripe** | https://stripe.com/docs | https://dashboard.stripe.com | Stripe support chat |
| **Resend** | https://resend.com/docs | https://resend.com | Email support |
| **Firebase** | https://firebase.google.com/docs | https://console.firebase.google.com | Firebase support |
| **OpenAI** | https://platform.openai.com/docs | https://platform.openai.com | OpenAI forum |

---

## ✨ Next Steps

1. **Immediately:** Collect Stripe & Resend keys from dashboards ✅
2. **Configure Firebase:** Set keys using `firebase functions:config:set` ✅
3. **Update .env:** Add frontend keys to `.env.production` ✅
4. **Deploy:** Run `firebase deploy --only functions` ✅
5. **Test:** Use Stripe test card to verify payments work ✅
6. **Monitor:** Check Firebase logs and Stripe dashboard ✅
7. **Go Live:** Switch to production keys when ready ✅

---

**Questions?** Check `.github/copilot-instructions.md` for platform architecture overview.

