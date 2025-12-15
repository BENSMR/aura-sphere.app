# OpenAI Key Setup & Configuration Guide

**Goal:** Get your OpenAI API key configured and test all AI features  
**Time Required:** 5-10 minutes  
**Difficulty:** Easy

---

## Step 1: Get Your OpenAI API Key

### Option A: Use Existing Organization Account
If you already have an OpenAI account with organization access:

1. Go to: https://platform.openai.com/api-keys
2. Sign in with your account
3. Click "Create new secret key"
4. Copy the key (it will look like: `sk-proj-abc123def456...`)
5. **Keep this secret - don't share or commit to git**

### Option B: Create New OpenAI Account
If you don't have an account:

1. Go to: https://platform.openai.com/signup
2. Create account (email + password, or use GitHub/Google login)
3. Add payment method (required for API access)
4. Go to: https://platform.openai.com/api-keys
5. Click "Create new secret key"
6. Copy the key

**Note:** You'll be charged based on API usage (very cheap - ~$10/month for this app)

---

## Step 2: Set the Key in Firebase

### Option A: Using Firebase CLI (Recommended)

```bash
# 1. Open terminal in your project directory
cd /workspaces/aura-sphere-pro

# 2. Set the OpenAI key in Firebase config
# Replace YOUR_KEY_HERE with your actual key from Step 1
firebase functions:config:set openai.key="sk-proj-YOUR_KEY_HERE"

# Example with real key format (DO NOT use this actual key):
# firebase functions:config:set openai.key="sk-proj-abcdefg123456789"

# 3. Verify it was set correctly
firebase functions:config:get | grep openai

# You should see:
# {
#   "openai": {
#     "key": "sk-proj-..."
#   }
# }
```

### Option B: Using Firebase Console (Web UI)

1. Go to: https://console.firebase.google.com/project/aurasphere-pro/functions/config
2. Scroll to "Runtime configuration"
3. Click "Edit Configuration"
4. Add new key-value pair:
   - Key: `openai.key`
   - Value: `sk-proj-YOUR_KEY_HERE`
5. Click "Save"

---

## Step 3: Deploy Updated Cloud Functions

```bash
# Deploy only Cloud Functions (faster than full deploy)
firebase deploy --only functions

# Or if using GitHub Actions, just push to main:
git add .
git commit -m "Add OpenAI configuration"
git push origin main
# GitHub Actions will auto-deploy
```

---

## Step 4: Test OpenAI Integration

### Test 1: Using Firebase CLI Shell

```bash
# Start Firebase functions shell
firebase functions:shell

# In the shell, test the aiAssistant function
aiAssistant({prompt: "What is 2+2?"}, {auth: {uid: "test-user"}})

# You should see a response like:
# {
#   "response": "2 + 2 = 4"
# }

# Type 'exit' to quit the shell
```

### Test 2: Using HTTP Request

```bash
# Get your function URL
firebase deploy --only functions:aiAssistant

# Then call it (replace with your actual URL):
curl -X POST https://us-central1-aurasphere-pro.cloudfunctions.net/aiAssistant \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{"prompt": "Hello, what can you do?"}'

# Should return JSON with AI response
```

### Test 3: From the Flutter App

1. Launch the app: `flutter run`
2. Navigate to AI Chat screen
3. Type a message: "What's the weather?"
4. You should see the AI response
5. If you see errors, check Firebase logs:
   - Go to: https://console.firebase.google.com/project/aurasphere-pro/functions

---

## Step 5: Verify All AI Features Work

### Feature 1: AI Chat (aiAssistant)

**Test Command:**
```bash
firebase functions:shell
> aiAssistant({prompt: "Tell me about finance"}, {auth: {uid: "test"}})
```

**Expected Result:** AI response about finance  
**Status:** ✅ Should work

### Feature 2: Email Generation (generateEmail)

**Test Command:**
```bash
firebase functions:shell
> generateEmail({
  type: "invoice_reminder",
  clientName: "Acme Corp",
  invoiceAmount: 1500
}, {auth: {uid: "test"}})
```

**Expected Result:** Generated email subject + body  
**Status:** ✅ Should work

### Feature 3: Finance Coach (financeCoach)

**Test Command:**
```bash
firebase functions:shell
> financeCoach({userId: "test-user"}, {auth: {uid: "test"}})
```

**Expected Result:** Finance analysis with recommendations  
**Status:** ✅ Should work

---

## 🔍 Verify Configuration

### Check if Key is Set

```bash
# List all Firebase config
firebase functions:config:get

# Output should include:
{
  "openai": {
    "key": "sk-proj-..." ← Should show here
  }
}

# If openai section is missing, key wasn't set
```

### Check Deployed Functions Have the Key

```bash
# View function logs to see if initialization works
firebase functions:log --tail

# Look for logs from deployed functions
# If you see "OpenAI API key not configured", the key didn't deploy correctly
```

---

## ❌ Troubleshooting

### Error: "OpenAI API key not configured"

**Problem:** Key wasn't set in Firebase  
**Solution:**
```bash
# Set it again
firebase functions:config:set openai.key="sk-proj-YOUR_KEY"

# Redeploy
firebase deploy --only functions

# Wait 2-3 minutes for deployment
```

### Error: "401 Unauthorized"

**Problem:** API key is invalid  
**Solution:**
1. Go to https://platform.openai.com/api-keys
2. Check the key hasn't been revoked
3. Generate a new key
4. Update Firebase: `firebase functions:config:set openai.key="new-key"`

### Error: "429 Too Many Requests"

**Problem:** Hit rate limit  
**Solution:**
- Wait 1-2 minutes
- Check usage at: https://platform.openai.com/account/usage
- Consider limiting AI calls in app

### Firebase CLI Says "No API key"

**Problem:** You're not authenticated to Firebase  
**Solution:**
```bash
# Login to Firebase
firebase login

# If logged in but config won't work:
firebase logout
firebase login
```

---

## 📊 Monitor Costs

### View OpenAI Usage

1. Go to: https://platform.openai.com/account/usage
2. Check "API usage" by model
3. View billing: https://platform.openai.com/account/billing/overview

### Estimate Monthly Cost

For **moderate usage** (100 AI requests/month):
- aiAssistant (20 req, GPT-4): ~$1/month
- financeCoach (50 req, gpt-4o-mini): ~$0.01/month
- generateEmail (30 req, gpt-3.5-turbo): ~$0.02/month

**Total:** ~$1-2/month ✅ Very affordable

### Set Spending Limit (Recommended)

1. Go to: https://platform.openai.com/account/billing/limits
2. Set "Hard limit" to $20/month (or your budget)
3. You'll be notified if approaching limit

---

## ✅ Checklist

- [ ] Obtained OpenAI API key
- [ ] Set key in Firebase: `firebase functions:config:set openai.key="..."`
- [ ] Verified key was set: `firebase functions:config:get | grep openai`
- [ ] Deployed functions: `firebase deploy --only functions`
- [ ] Tested aiAssistant in Firebase shell
- [ ] Tested in Flutter app (AI chat works)
- [ ] Checked finance coach generates insights
- [ ] Verified email generation works
- [ ] Monitored first API calls in Firebase logs
- [ ] Set spending limit on OpenAI account

---

## 🎯 Next Steps

After getting OpenAI working:

1. **Add Cost Monitoring** (Optional but recommended)
   - Track API usage per user
   - Alert on unusual activity
   - See instructions in AI_FUNCTIONALITY_AND_KEYS_AUDIT.md

2. **Implement Rate Limiting** (Optional)
   - Limit users to 10 AI calls/day
   - Prevent cost overruns
   - Better user experience

3. **Optimize Model Usage** (Optional)
   - Use gpt-4o-mini for simple tasks
   - Save ~50% on costs
   - Update model names in Cloud Functions

4. **Add Caching** (Optional)
   - Cache common AI responses
   - Reduce API calls by 20-30%
   - Faster user experience

---

## 📞 Getting Help

**If something doesn't work:**

1. Check logs: `firebase functions:log --tail`
2. Verify key is valid at: https://platform.openai.com/api-keys
3. Check OpenAI status: https://status.openai.com
4. See troubleshooting section above
5. Read full audit: AI_FUNCTIONALITY_AND_KEYS_AUDIT.md

**Firebase Functions Documentation:**
- https://firebase.google.com/docs/functions
- https://firebase.google.com/docs/functions/config-env

**OpenAI Documentation:**
- https://platform.openai.com/docs
- https://community.openai.com (forum for help)

---

That's it! Your OpenAI integration should now be working. 🎉
