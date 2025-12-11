# 🚀 Environment Variables Deployment Guide

**Last Updated:** December 9, 2025  
**Status:** Ready for Production Deployment

---

## Quick Reference

Your SendGrid configuration:
- **Provider:** SendGrid (cloud-based, recommended)
- **API Key Format:** `SG.xxxxxxxxxxxxx`
- **From Email:** `billing@aurasphere.com` (must be verified in SendGrid)
- **From Name:** `AuraSphere Pro`

---

## Pre-Deployment Checklist

### Step 1: Prepare Production Environment File

```bash
# Create production environment file (NOT committed to git)
touch /workspaces/aura-sphere-pro/functions/.env.production

# Make it readable only by you
chmod 600 /workspaces/aura-sphere-pro/functions/.env.production
```

### Step 2: Add Your SendGrid Configuration

Edit `.env.production` and add:

```dotenv
# SendGrid Email Configuration
SENDGRID_API_KEY=SG.your_actual_key_here_from_sendgrid_dashboard
EMAIL_FROM=billing@aurasphere.com
EMAIL_FROM_NAME=AuraSphere Pro

# Firebase Production Project
FIREBASE_PROJECT_ID=your-production-project-id
FIREBASE_DATABASE_URL=https://your-production-project.firebaseio.com
FIREBASE_STORAGE_BUCKET=your-production-project.appspot.com

# OpenAI (Production)
OPENAI_KEY=sk_live_your_production_key

# Google Cloud
GOOGLE_PROJECT_ID=your-production-gcp-project

# Rewards (Production Values)
WELCOME_BONUS=200
DAILY_LOGIN=5

# Environment
NODE_ENV=production
```

### Step 3: Verify .env.production is NOT in Git

```bash
# Check .gitignore
cat /workspaces/aura-sphere-pro/.gitignore | grep -E "\.env|\.env\."

# Expected output should include:
# .env
# .env.local
# .env.production
# .env*.local

# Verify it's not staged for commit
git status | grep .env
# Should show NO .env files
```

### Step 4: Test Local Configuration

```bash
# Build functions to ensure environment variables load
cd /workspaces/aura-sphere-pro/functions
npm run build

# Expected: TypeScript compilation succeeds with no errors
```

---

## Deployment Methods

### Method 1: Firebase Emulator (Local Testing)

```bash
# Test with local configuration before production
cd /workspaces/aura-sphere-pro

# Start emulator with all services
firebase emulators:start

# In another terminal, test the functions
curl http://localhost:5001/YOUR_PROJECT/us-central1/sendEmailNotification \
  -H "Content-Type: application/json" \
  -d '{"to":"test@example.com","subject":"Test"}'
```

### Method 2: Deploy to Firebase (Recommended)

```bash
# 1. Ensure you're logged in to Firebase
firebase login

# 2. Select your project
firebase use your-production-project

# 3. Deploy Cloud Functions (will use .env.production)
firebase deploy --only functions

# 4. Verify deployment
firebase functions:log --limit 50
```

### Method 3: Manual Firebase Environment Setup

If you prefer not to use .env.production file:

```bash
# Set individual environment variables via Firebase CLI
firebase functions:config:set \
  sendgrid.key="SG.your_actual_key" \
  sendgrid.from="billing@aurasphere.com" \
  sendgrid.name="AuraSphere Pro" \
  firebase.project="your-project" \
  openai.key="sk_live_xxxxx"

# Verify configuration
firebase functions:config:get

# Deploy
firebase deploy --only functions
```

### Method 4: Google Cloud Deployment (Alternative)

```bash
# Deploy specific function with environment variables
gcloud functions deploy sendEmailNotification \
  --runtime nodejs20 \
  --trigger-http \
  --set-env-vars \
    SENDGRID_API_KEY=SG.xxxxx,\
    EMAIL_FROM=billing@aurasphere.com,\
    FIREBASE_PROJECT_ID=your-project
```

---

## Verification Steps

### Verify Deployment Success

```bash
# 1. Check Cloud Functions are deployed
firebase functions:list
# Should show: sendEmailNotification, etc. with status: OK

# 2. Check logs for errors
firebase functions:log --limit 100
# Look for any "ERROR" lines related to environment variables

# 3. Test function manually
firebase functions:call sendEmailNotification \
  --data='{"to":"test@example.com","subject":"Test","body":"Test message"}'
```

### Verify SendGrid Integration

```bash
# Check SendGrid dashboard
# 1. Go to sendgrid.com → Dashboard
# 2. Check "Mail Send" stats
# 3. Verify recent email sends succeeded

# Alternative: Check Firebase logs
firebase functions:log --limit 50 | grep -i sendgrid
```

---

## Environment Variable Locations

### Local Development
- **File:** `functions/.env.local`
- **Read by:** `firebase emulators:start`
- **In Git:** NO (should be ignored)

### Production Deployment
- **File:** `functions/.env.production`
- **Read by:** `firebase deploy --only functions`
- **In Git:** NO (must be ignored)
- **Location:** Local filesystem only (not committed)

### Fallback (Firebase Console)
- **Location:** Firebase Console → Cloud Functions Settings
- **Read by:** Deployed functions
- **When Used:** If .env file is not available
- **Recommended:** Use .env files instead

---

## Troubleshooting

### Problem: "SENDGRID_API_KEY is undefined"

**Cause:** Environment variable not loaded during deployment

**Solution:**
```bash
# 1. Verify .env.production exists and has the key
ls -la functions/.env.production
grep SENDGRID_API_KEY functions/.env.production

# 2. Ensure correct format (starts with SG.)
# 3. Rebuild and redeploy
cd functions
npm run build
firebase deploy --only functions

# 4. Check if deployed function can access it
firebase functions:log --limit 50
```

### Problem: "Failed to verify SendGrid API key"

**Cause:** Invalid or expired API key

**Solution:**
```bash
# 1. Check SendGrid dashboard
# 2. Verify API key starts with "SG."
# 3. Check if key was revoked or expired
# 4. Generate new key: sendgrid.com → Settings → API Keys
# 5. Update functions/.env.production with new key
# 6. Redeploy: firebase deploy --only functions
```

### Problem: "Email from address not verified"

**Cause:** Sender email not verified in SendGrid

**Solution:**
```bash
# 1. Go to sendgrid.com
# 2. Settings → Sender Verification
# 3. Add new sender: billing@aurasphere.com
# 4. Click verification link in confirmation email
# 5. Update EMAIL_FROM in .env.production
# 6. Redeploy
```

### Problem: Secrets visible in function logs

**Cause:** Accidental logging of environment variables

**Solution:**
```bash
# Never log full API keys
// ❌ WRONG:
console.log('Using API key:', process.env.SENDGRID_API_KEY);

// ✅ CORRECT:
console.log('SendGrid API key loaded:', !!process.env.SENDGRID_API_KEY ? 'YES' : 'NO');
```

---

## Security Best Practices

### ✅ Do's

```bash
✅ Keep .env.production ONLY on deployment machine
✅ Use strong, unique API keys for production
✅ Rotate API keys every 90 days
✅ Monitor API usage in SendGrid dashboard
✅ Use different keys for dev/staging/production
✅ Enable 2FA on SendGrid account
✅ Review and revoke unused API keys
✅ Use environment-specific Firebase projects
```

### ❌ Don'ts

```bash
❌ Commit .env.production to git repository
❌ Share API keys via email or Slack
❌ Use development keys in production
❌ Hardcode API keys in source code
❌ Log API keys or sensitive data
❌ Share .env files in pull requests
❌ Use same key for multiple services
❌ Store keys in plaintext documentation
```

---

## File Structure

```
/workspaces/aura-sphere-pro/
├── .gitignore                                  (excludes .env files)
├── .env.example                                (template for all envs)
├── docs/
│   └── ENVIRONMENT_VARIABLES_SETUP.md          (comprehensive guide)
│
├── functions/
│   ├── .env                                    (base config)
│   ├── .env.local                              (dev overrides)
│   ├── .env.production                         (NEVER COMMIT)
│   ├── package.json
│   └── src/
│       └── [email, billing functions...]
│
└── firestore.rules                             (security rules)
```

---

## Next Steps

1. **Create .env.production**
   ```bash
   touch functions/.env.production
   chmod 600 functions/.env.production
   ```

2. **Add your SendGrid credentials**
   - Get API key from SendGrid dashboard
   - Verify sender email
   - Update .env.production with values

3. **Test locally**
   ```bash
   cd functions
   npm run build
   firebase emulators:start
   ```

4. **Deploy to Firebase**
   ```bash
   firebase deploy --only functions
   ```

5. **Verify in production**
   ```bash
   firebase functions:log --limit 50
   firebase functions:call sendEmailNotification \
     --data='{"to":"test@email.com"}'
   ```

---

## Quick Commands Reference

```bash
# Local testing
firebase emulators:start

# Build TypeScript
cd functions && npm run build

# Deploy only functions (uses .env.production)
firebase deploy --only functions

# Deploy everything
firebase deploy

# View logs
firebase functions:log --limit 50

# View specific function logs
firebase functions:log sendEmailNotification --limit 50

# List deployed functions
firebase functions:list

# Test function locally
firebase functions:call myFunction --data='{"key":"value"}'

# Delete a function
firebase functions:delete myFunction

# Set specific env var via CLI
firebase functions:config:set sendgrid.key="SG.xxxxx"

# Get all env variables
firebase functions:config:get

# Monitor Cloud Functions
firebase extensions
```

---

## Support

- **SendGrid Help:** https://sendgrid.com/docs/
- **Firebase Functions:** https://firebase.google.com/docs/functions
- **Environment Config:** https://firebase.google.com/docs/functions/config
- **Troubleshooting:** https://firebase.google.com/docs/functions/troubleshooting

---

**Status:** ✅ Ready for Production  
**Last Tested:** December 9, 2025
