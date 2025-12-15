# 🔑 API Keys Quick Reference Card

**Last Updated:** December 15, 2025  
**For:** AuraSphere Pro Application

---

## 📋 All Required & Optional Keys

| Service | Type | Status | Priority | How to Set | Key Format |
|---------|------|--------|----------|-----------|-----------|
| **Firebase** | Auth & DB | ✅ SET | CRITICAL | Auto configured | (Google managed) |
| **Stripe** | Payments | ⚠️ PARTIAL | CRITICAL | `firebase functions:config:set stripe.secret="..."` | `sk_test_...` |
| **Resend** | Email | ⚠️ PARTIAL | HIGH | `firebase functions:config:set resend.api_key="..."` | `re_...` |
| **OpenAI** | AI Features | ❌ NOT SET | MEDIUM | `firebase functions:config:set openai.key="..."` | `sk-proj-...` |
| **SendGrid** | Email (alt) | ❌ NOT SET | LOW | `firebase functions:config:set sendgrid.key="..."` | `SG....` |

---

## 🟢 CRITICAL - MUST SET BEFORE GOING LIVE

### 1️⃣ Stripe Secret Key
**What it does:** Processes payments  
**Get it:** https://dashboard.stripe.com/apikeys  
**Set it:**
```bash
firebase functions:config:set stripe.secret="sk_test_YOUR_KEY_HERE"
```
**Current Status:** ⚠️ Needs webhook secret  
**Priority:** 🔴 CRITICAL

### 2️⃣ Stripe Webhook Secret
**What it does:** Listens for payment events  
**Get it:** https://dashboard.stripe.com/webhooks  
**Set it:**
```bash
firebase functions:config:set stripe.webhook_secret="whsec_YOUR_KEY_HERE"
```
**Files Using It:**
- `functions/src/billing/stripeWebhook.ts`

---

## 🟡 HIGH PRIORITY - NEEDED FOR EMAILS

### 3️⃣ Resend API Key
**What it does:** Sends transactional emails  
**Get it:** https://resend.com → API Keys  
**Set it:**
```bash
firebase functions:config:set resend.api_key="re_YOUR_KEY_HERE"
```
**Files Using It:**
- `functions/src/email/resendService.ts`
- `functions/src/auth/welcomeEmail.ts`

**Features Using It:**
- ✅ Welcome emails
- ✅ Invoice receipts
- ✅ Payment confirmations
- ✅ Password resets

**Current Status:** ⚠️ Installed, not configured  
**Priority:** 🟡 HIGH

---

## 🟠 MEDIUM PRIORITY - AI FEATURES

### 4️⃣ OpenAI API Key ⭐ FOCUS HERE
**What it does:** Powers all AI features  
**Get it:** https://platform.openai.com/api-keys  
**Set it:**
```bash
firebase functions:config:set openai.key="sk-proj-YOUR_KEY_HERE"
```

**Files Using It:**
- `functions/src/ai/aiAssistant.ts` - Chat
- `functions/src/ai/financeCoach.ts` - Finance analysis
- `functions/src/ai/generateEmail.ts` - Email generation

**Features Using It:**
- 🤖 AI Chat Assistant
- 📊 Finance Coach insights
- 📧 Email generation
- 💡 CRM recommendations

**Current Status:** ❌ Code ready, key not set  
**Priority:** 🟠 MEDIUM (optional but recommended)

**Cost:** ~$1-2/month for moderate usage

---

## 🔵 LOW PRIORITY - OPTIONAL

### 5️⃣ SendGrid API Key (Backup)
**What it does:** Alternative email service  
**Get it:** https://sendgrid.com → Settings → API Keys  
**Set it:**
```bash
firebase functions:config:set sendgrid.key="SG.YOUR_KEY_HERE"
```
**Current Status:** ❌ Not needed (Resend is primary)  
**Priority:** 🔵 LOW - Only if Resend fails

---

## 📱 Frontend Environment Variables

**File:** `.env.production`

```env
# ✅ ALREADY SET
REACT_APP_FIREBASE_API_KEY=AIzaSyCebiYzfLJBFtQVKSJu0LZRhOFT1I1LeQY
REACT_APP_STRIPE_PUBLISHABLE_KEY=pk_test_51SeGAg...

# ❌ DON'T ADD OPENAI KEY HERE (Server-side only)
# ❌ DON'T ADD SECRET KEYS HERE (Never expose to client)
```

---

## ☁️ Backend (Firebase Functions) Config

**Set via Firebase CLI:**
```bash
firebase functions:config:set \
  stripe.secret="sk_test_..." \
  stripe.webhook_secret="whsec_..." \
  resend.api_key="re_..." \
  openai.key="sk-proj-..."
```

**View current config:**
```bash
firebase functions:config:get
```

**Output looks like:**
```json
{
  "stripe": {
    "secret": "sk_test_...",
    "webhook_secret": "whsec_..."
  },
  "resend": {
    "api_key": "re_..."
  },
  "openai": {
    "key": "sk-proj-..."
  }
}
```

---

## 🚀 Quick Setup (5 Minutes)

### Must-Do (Critical)
```bash
# 1. Set OpenAI (for AI features to work)
firebase functions:config:set openai.key="sk-proj-YOUR_KEY"

# 2. Deploy
firebase deploy --only functions

# 3. Test
firebase functions:shell
# > aiAssistant({prompt: "Hi"}, {auth: {uid: "test"}})
```

### Should-Do (If using emails)
```bash
# Ensure Resend key is set
firebase functions:config:get | grep resend

# If not set:
firebase functions:config:set resend.api_key="re_YOUR_KEY"
```

### Already Done ✅
- Firebase configuration
- Stripe publishable key (frontend)
- Stripe secret key (backend) - partially

---

## 📊 Cost Breakdown

| Service | Monthly Cost | Notes |
|---------|------------|-------|
| **Firebase** | $0-25 | Included in Spark plan (free tier) |
| **Stripe** | 2.9% + 30¢ per transaction | Only charged on successful payments |
| **Resend** | $20/month | 100 emails free, then $0.20/email |
| **OpenAI** | $0-10 | Based on API usage (very cheap) |
| **SendGrid** | $0-30 | Only if used as backup |
| **Google Vision** | $0-3 | For receipt OCR (included) |
| **Total** | ~$25-50/month | Scales with growth |

---

## 🔒 Security Checklist

- ✅ Never commit `.env` files with real keys
- ✅ Use Firebase config for sensitive keys (server-side only)
- ✅ Never expose secret keys to frontend
- ✅ Rotate keys every 90 days
- ✅ Use different keys for dev/staging/prod
- ✅ Monitor usage for unusual activity
- ✅ Set spending limits on each service

---

## 🆘 Troubleshooting

### Key Not Working?
```bash
# 1. Verify it's set
firebase functions:config:get | grep openai

# 2. If missing, set it again
firebase functions:config:set openai.key="sk-proj-..."

# 3. Redeploy
firebase deploy --only functions

# 4. Wait 2-3 minutes for deployment
```

### Function Crashes on AI Call?
```bash
# Check logs
firebase functions:log --tail

# Should show error like:
# Error: OpenAI API key not configured
```

### Authorization Failed?
- Verify key hasn't been revoked
- Check key is correct (copy from source again)
- Generate new key if needed
- Update Firebase config with new key

---

## 📚 Documentation Links

| Topic | Link |
|-------|------|
| **OpenAI Setup** | See: OPENAI_SETUP_GUIDE.md |
| **Full Audit** | See: AI_FUNCTIONALITY_AND_KEYS_AUDIT.md |
| **API Configuration** | See: API_KEYS_CONFIGURATION_CHECKLIST.md |
| **Firebase Config** | https://firebase.google.com/docs/functions/config-env |
| **OpenAI API Docs** | https://platform.openai.com/docs |
| **Stripe Docs** | https://stripe.com/docs/api |
| **Resend Docs** | https://resend.com/docs |

---

## ✅ Setup Verification

Run this to verify all keys:

```bash
# Show all config
firebase functions:config:get

# Should see sections for:
# - stripe (secret, webhook_secret)
# - resend (api_key)
# - openai (key) ← Should be here

# If any are missing, use commands above to set them
```

---

**Status:** ⚠️ OpenAI key missing - everything else ready  
**Action:** Set OpenAI key (see OPENAI_SETUP_GUIDE.md)  
**Time to Complete:** 5 minutes
