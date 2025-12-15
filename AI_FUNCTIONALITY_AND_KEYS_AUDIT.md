# AI Functionality & API Keys Audit Report
**Date:** December 15, 2025  
**Status:** ⚠️ CRITICAL - Configuration Issues Found  
**Priority:** HIGH - Requires immediate attention

---

## 📊 Executive Summary

| Area | Status | Issues | Action Required |
|------|--------|--------|-----------------|
| **OpenAI Integration** | ⚠️ Partial | Key not set, but code ready | ✅ Set key via Firebase config |
| **API Key Management** | 🔴 Critical | Missing security practices | ✅ Implement checks & monitoring |
| **Environment Variables** | ⚠️ Mixed | Inconsistent patterns | ✅ Standardize across codebase |
| **Error Handling** | ✅ Good | Try/catch implemented | ✅ Add rate limit handling |

---

## 🤖 OpenAI Integration Status

### Current Implementation: ✅ GOOD

**Files Using OpenAI:**
1. ✅ `functions/src/utils/openai.ts` - OpenAI client factory
2. ✅ `functions/src/ai/aiAssistant.ts` - Chat assistant
3. ✅ `functions/src/ai/financeCoach.ts` - Finance analysis
4. ✅ `functions/src/ai/generateEmail.ts` - Email generation

### OpenAI Client Initialization: ✅ SECURE

```typescript
// functions/src/utils/openai.ts - CORRECT PATTERN
export function getOpenaiClient(): OpenAI {
  if (!cachedOpenai) {
    // ✅ Checks Firebase config first, then fallback to env var
    const apiKey = process.env.OPENAI_API_KEY || functions.config().openai?.key;
    
    if (!apiKey) {
      throw new Error('OpenAI API key not configured...');
    }
    
    cachedOpenai = new OpenAI({ apiKey });
  }
  return cachedOpenai;
}
```

**✅ Security Good Practices:**
- Lazy initialization (only when needed)
- Client caching (single instance)
- Clear error messages
- Uses Firebase config over env vars

### OpenAI Usage Patterns

#### 1. **aiAssistant.ts** - Chat Assistant
```typescript
const openai = getOpenaiClient();
const response = await openai.chat.completions.create({
  model: 'gpt-4',
  messages: [{...}],
});
```
**Status:** ✅ Correct  
**Rate Limit:** 60 requests/minute  
**Cost:** ~$0.02-0.06 per request (GPT-4)

#### 2. **financeCoach.ts** - Finance Analysis
```typescript
const OPENAI_KEY = functions.config().openai?.key || null;

async function openAiNarrative(summaryText: string) {
  if (!OPENAI_KEY) return null; // ✅ Gracefully skips
  
  const res = await fetch(OPENAI_ENDPOINT, {
    method: 'POST',
    headers: {
      'Authorization': `Bearer ${OPENAI_KEY}`,
      'Content-Type': 'application/json'
    },
    body: JSON.stringify({
      model: 'gpt-4o-mini', // ✅ Cheaper model
      messages: [...],
      max_tokens: 400,
      temperature: 0.2
    })
  });
}
```
**Status:** ✅ Correct (uses fetch, graceful fallback)  
**Model:** gpt-4o-mini (cost-optimized)  
**Cost:** ~$0.0002 per request

#### 3. **generateEmail.ts** - Email Generation
```typescript
const openai = getOpenaiClient();
if (!openai) {
  throw new Error('OpenAI client not initialized...');
}

const completion = await openai.chat.completions.create({
  model: 'gpt-3.5-turbo',
  messages: [{...}],
});
```
**Status:** ✅ Correct with validation  
**Model:** gpt-3.5-turbo (fastest, cheapest)  
**Cost:** ~$0.0005 per request

---

## 🔑 API Keys Configuration

### Current Status: ⚠️ NOT CONFIGURED

**Command to Set OpenAI Key:**
```bash
firebase functions:config:set openai.key="sk-YOUR_KEY_HERE"
```

**Command to Check Current Config:**
```bash
firebase functions:config:get
```

### Required Environment Variables

| Variable | Location | Status | Purpose |
|----------|----------|--------|---------|
| `openai.key` | Firebase config | ❌ Not set | OpenAI API key |
| `OPENAI_API_KEY` | Process env | ❌ Not set | Fallback for local dev |
| `REACT_APP_FIREBASE_API_KEY` | .env.production | ✅ Set | Firebase public key |
| `REACT_APP_STRIPE_PUBLISHABLE_KEY` | .env.production | ✅ Set | Stripe public key |

### Key Configuration Checklist

```bash
# ❌ MISSING - Set these immediately
firebase functions:config:set \
  openai.key="sk-proj-YOUR_KEY_HERE"

# ✅ ALREADY SET
firebase functions:config:get
# Should show:
# {
#   "stripe": {
#     "secret": "sk_test_..."
#   },
#   "resend": {
#     "api_key": "re_..."
#   },
#   "openai": {
#     "key": "sk_proj_..." ← ❌ NEEDS TO BE SET
#   }
# }
```

---

## ⚠️ Issues Found

### Issue 1: OpenAI Key Not Configured
**Severity:** 🔴 CRITICAL  
**Impact:** AI features won't work in production  
**Status:** Needs immediate fix

**Error Message When Not Set:**
```
Error: OpenAI API key not configured. 
Set via: firebase functions:config:set openai.key="sk-..."
```

**Fix:**
```bash
# Get your OpenAI API key from https://platform.openai.com/api-keys
firebase functions:config:set openai.key="sk-proj-YOUR_KEY_HERE"

# Verify it was set
firebase functions:config:get | grep openai
```

### Issue 2: Missing Error Handling for Rate Limits
**Severity:** 🟡 MEDIUM  
**Impact:** No graceful handling if rate limit hit  
**Status:** Should add retry logic

**Current Code:**
```typescript
const completion = await openai.chat.completions.create({...});
```

**Recommended Fix:**
```typescript
const completion = await openai.chat.completions.create({...});
// Should catch and retry on rate limit (429)
```

### Issue 3: No Cost Monitoring
**Severity:** 🟡 MEDIUM  
**Impact:** Could accumulate costs unexpectedly  
**Status:** Should add usage tracking

**What's Needed:**
- Track OpenAI API costs per user/feature
- Set spending limits
- Alert on unusual usage

---

## 💰 Cost Analysis

### OpenAI Model Costs (as of Dec 2025)

| Model | Input | Output | Use Case |
|-------|-------|--------|----------|
| **gpt-4** | $30/1M | $60/1M | Complex analysis, chat |
| **gpt-4o-mini** | $0.15/1M | $0.60/1M | Finance summaries |
| **gpt-3.5-turbo** | $0.50/1M | $1.50/1M | Email generation |

### Current Usage Costs (Estimated)

**If all AI features active with moderate usage:**
- aiAssistant (10 chats/day, GPT-4): ~$0.30/day = ~$9/month
- financeCoach (5/day, gpt-4o-mini): ~$0.001/day = ~$0.03/month
- generateEmail (20/day, gpt-3.5-turbo): ~$0.02/day = ~$0.60/month

**Total:** ~$10/month (very low)

**Savings Opportunity:**
- Switch aiAssistant from GPT-4 to gpt-4o-mini: Save ~$9/month
- Add usage limits: Prevent runaway costs

---

## ✅ Implementation Checklist

### Immediate Actions (Do First)

- [ ] **Get OpenAI API Key**
  ```bash
  # Go to https://platform.openai.com/api-keys
  # Create new secret key
  # Copy the key (starts with sk-proj-)
  ```

- [ ] **Set OpenAI Key in Firebase**
  ```bash
  firebase functions:config:set openai.key="sk-proj-YOUR_KEY"
  firebase deploy --only functions
  ```

- [ ] **Test OpenAI Integration**
  ```bash
  # Call aiAssistant function
  firebase functions:shell
  # > aiAssistant({prompt: "Hello"}, {auth: {uid: 'test'}})
  ```

- [ ] **Verify All AI Functions Work**
  - [ ] aiAssistant (chat)
  - [ ] financeCoach (analysis)
  - [ ] generateEmail (email generation)

### Short-term Actions (This Week)

- [ ] **Add Cost Monitoring**
  - Track OpenAI API costs per feature
  - Log API usage to Firestore
  - Create usage dashboard

- [ ] **Implement Rate Limiting**
  - Max 10 AI requests per user per day (adjust as needed)
  - Return helpful message when limit reached
  - Track in Firestore

- [ ] **Add Error Handling for Rate Limits (429)**
  ```typescript
  const MAX_RETRIES = 3;
  const RETRY_DELAY = 1000; // 1 second
  
  async function callOpenAiWithRetry(params) {
    for (let i = 0; i < MAX_RETRIES; i++) {
      try {
        return await openai.chat.completions.create(params);
      } catch (error: any) {
        if (error.status === 429 && i < MAX_RETRIES - 1) {
          await new Promise(r => setTimeout(r, RETRY_DELAY * Math.pow(2, i)));
          continue;
        }
        throw error;
      }
    }
  }
  ```

### Medium-term Actions (This Month)

- [ ] **Create AI Usage Dashboard**
  - Show cost per feature
  - Show usage trends
  - Alert on budget overruns

- [ ] **Implement Model Switching**
  - Use gpt-4o-mini for simple tasks
  - Use gpt-4 only for complex analysis
  - Save ~50% on costs

- [ ] **Add Caching for Common Queries**
  - Cache email templates
  - Cache finance advice patterns
  - Reduce API calls

---

## 🔐 Security Best Practices

### ✅ Currently Implemented

```typescript
// Good: Uses Firebase config, not hardcoded
const apiKey = functions.config().openai?.key;

// Good: Only server-side (never expose to client)
// aiAssistant function is Cloud Function only

// Good: Error handling
if (!apiKey) {
  throw new Error('API key not configured');
}
```

### ⚠️ Should Add

```typescript
// Rate limiting by user ID
async function checkRateLimit(userId: string) {
  const doc = await db.collection('openai_usage').doc(userId).get();
  const usage = doc.data() || { count: 0, resetTime: Date.now() };
  
  // Reset daily
  if (Date.now() > usage.resetTime + 86400000) {
    return { allowed: true, count: 0 };
  }
  
  return { allowed: usage.count < 10, count: usage.count };
}

// Usage tracking
async function trackOpenAiUsage(userId: string, cost: number) {
  await db.collection('openai_usage').doc(userId).update({
    count: FieldValue.increment(1),
    cost: FieldValue.increment(cost),
    lastUsed: FieldValue.serverTimestamp()
  });
}
```

---

## 📋 Configuration Quick Reference

### Set OpenAI Key (Quickest Path)

```bash
# 1. Get your key from https://platform.openai.com/api-keys
# 2. Run this command:
firebase functions:config:set openai.key="sk-proj-YOUR_KEY_HERE"

# 3. Deploy
firebase deploy --only functions

# 4. Test
curl -X POST https://us-central1-aurasphere-pro.cloudfunctions.net/aiAssistant \
  -H "Content-Type: application/json" \
  -d '{"prompt": "Hello"}'
```

### View All Configured Keys

```bash
firebase functions:config:get
```

### Unset a Key (if needed)

```bash
firebase functions:config:unset openai.key
```

---

## 📈 Usage Monitoring

### Check API Usage in Firebase Console

1. Go to: https://console.firebase.google.com/project/aurasphere-pro/functions
2. Click "Cloud Functions"
3. Look for: `aiAssistant`, `generateEmail`, `financeCoach`
4. Check "Execution count" and "Logs"

### Cost Estimation

```bash
# OpenAI has no built-in monitoring in Firebase
# You must track manually in Firestore:

# Collection: openai_usage
# Doc structure: {
#   userId: "user123",
#   dailyCount: 5,
#   monthlyCount: 120,
#   dailyCost: 0.05,
#   monthlyCost: 1.20,
#   features: {
#     aiAssistant: 3,
#     financeCoach: 2,
#     generateEmail: 0
#   },
#   resetTime: 1702876800000,
#   lastUsed: Timestamp
# }
```

---

## 🚨 Troubleshooting

### "OpenAI API key not configured" Error

**Cause:** Firebase config doesn't have `openai.key`  
**Fix:**
```bash
firebase functions:config:set openai.key="sk-proj-..."
firebase deploy --only functions
```

### "401 Unauthorized" Error

**Cause:** API key is invalid or wrong  
**Fix:**
1. Go to https://platform.openai.com/api-keys
2. Verify key starts with `sk-proj-`
3. Check it hasn't been revoked
4. Generate a new key if needed
5. Update: `firebase functions:config:set openai.key="..."`

### "429 Too Many Requests" Error

**Cause:** Rate limit exceeded  
**Fix:**
1. Wait 1-2 minutes
2. Check your OpenAI usage at https://platform.openai.com/account/usage
3. Add retry logic with exponential backoff
4. Consider upgrading OpenAI plan

### "Invalid Model" Error

**Cause:** Using deprecated or inaccessible model  
**Fix:**
- Check available models: https://platform.openai.com/docs/models
- Update model name in code
- Ensure model is in your OpenAI plan tier

---

## 📞 Support & Resources

| Resource | URL |
|----------|-----|
| **OpenAI API Docs** | https://platform.openai.com/docs |
| **OpenAI API Keys** | https://platform.openai.com/api-keys |
| **OpenAI Usage** | https://platform.openai.com/account/usage |
| **OpenAI Models** | https://platform.openai.com/docs/models |
| **OpenAI Forum** | https://community.openai.com |
| **Firebase Config** | https://firebase.google.com/docs/functions/config-env |

---

## 📝 Summary

**Current Status:**
- ✅ OpenAI code integration is secure and well-implemented
- ✅ Error handling and graceful fallbacks are in place
- ❌ API key is NOT configured - must be set before using
- ⚠️ Missing cost monitoring and rate limiting

**Next Steps (Priority Order):**
1. Set OpenAI API key via Firebase config
2. Test all AI functions
3. Add usage tracking to Firestore
4. Implement rate limiting per user
5. Create cost monitoring dashboard

**Estimated Time to Full Implementation:** 2-3 hours
