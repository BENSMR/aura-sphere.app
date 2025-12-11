# 🔧 Firebase Functions Configuration Guide — SendGrid Setup

**Date:** December 9, 2025  
**Status:** Ready for Deployment  

---

## 📋 Quick Setup

You have two options to set SendGrid configuration:

### Option 1: Firebase CLI (Recommended for Production)

```bash
# Set individual SendGrid variables
firebase functions:config:set \
  sendgrid.key="SG.your_actual_api_key_here" \
  email.from="billing@aurasphere.com" \
  email.from_name="AuraSphere Pro"

# Verify configuration was set
firebase functions:config:get

# Deploy Cloud Functions (will use new config)
firebase deploy --only functions
```

### Option 2: Manual .runtimeconfig.json (Local Development)

Create `functions/.runtimeconfig.json`:

```json
{
  "sendgrid": {
    "key": "SG.your_actual_api_key_here"
  },
  "email": {
    "from": "billing@aurasphere.com",
    "from_name": "AuraSphere Pro"
  }
}
```

Then use locally:
```bash
firebase emulators:start
```

---

## 🔐 Configuration Methods

### Method 1: Firebase CLI (Best for Production)

**Advantages:**
- ✅ Secrets never stored in files
- ✅ Encrypted in Firebase
- ✅ Easy to rotate keys
- ✅ No git security risk
- ✅ Different configs per environment

**Command:**
```bash
firebase functions:config:set sendgrid.key="SG_xxx"
```

**Verify:**
```bash
firebase functions:config:get
```

---

### Method 2: .runtimeconfig.json (Local Only)

**Advantages:**
- ✅ Works with emulator
- ✅ Fast local development
- ✅ No network calls

**Note:** ⚠️ Never commit to git!

Create `functions/.runtimeconfig.json`:
```json
{
  "sendgrid": {
    "key": "SG.dev_test_key_xxxxxxxxxxxx"
  },
  "email": {
    "from": "dev@aurasphere.local",
    "from_name": "AuraSphere (Dev)"
  }
}
```

Add to `.gitignore`:
```
functions/.runtimeconfig.json
```

---

### Method 3: .env.production (Alternative)

**File:** `functions/.env.production`

```dotenv
SENDGRID_API_KEY=SG.your_actual_key
EMAIL_FROM=billing@aurasphere.com
EMAIL_FROM_NAME=AuraSphere Pro
```

**Usage:** Deploy with `firebase deploy --only functions`

---

## 📊 Current Firebase Configuration

Your Firebase project already has this structure:

```json
{
  "stripe": { "publishable": "...", "secret": "..." },
  "mail": { "from": "...", "host": "...", "port": "..." },
  "openai": { "key": "..." },
  "aurasphere": { "tokens": { "daily_login": "5", "welcome_bonus": "200" } },
  "vision": { "key": "..." },
  "app": { "cancel_url": "...", "success_url": "..." },
  "sendgrid": { }  // ← Ready to add your config here
}
```

---

## ✅ Step-by-Step Setup

### Step 1: Prepare Your API Key

```bash
# Ensure you have your SendGrid API key
# Format: SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxx
# Get from: https://sendgrid.com/dashboard → Settings → API Keys

echo "Your API key: SG.___________________________"
```

### Step 2: Set SendGrid Configuration

```bash
# Login to Firebase
firebase login

# Select your project
firebase use your-project-id

# Set SendGrid configuration
firebase functions:config:set \
  sendgrid.key="SG.your_actual_key_here" \
  email.from="billing@aurasphere.com" \
  email.from_name="AuraSphere Pro"
```

### Step 3: Verify Configuration

```bash
# View all config
firebase functions:config:get

# View only SendGrid config
firebase functions:config:get sendgrid
firebase functions:config:get email
```

Expected output:
```json
{
  "sendgrid": {
    "key": "SG...."
  },
  "email": {
    "from": "billing@aurasphere.com",
    "from_name": "AuraSphere Pro"
  }
}
```

### Step 4: Deploy Functions

```bash
# Build TypeScript
cd functions
npm run build

# Deploy with new config
firebase deploy --only functions
```

### Step 5: Verify Deployment

```bash
# Check function logs
firebase functions:log --limit 50

# Check if config is accessible
# Log should show no SENDGRID_KEY errors
```

---

## 🔑 Configuration Variables Reference

### SendGrid Configuration

| Variable | CLI Path | Type | Example | Required |
|----------|----------|------|---------|----------|
| **API Key** | `sendgrid.key` | String | `SG.xxxxx...` | ✅ Yes |
| **From Email** | `email.from` | String | `billing@aurasphere.com` | ✅ Yes |
| **From Name** | `email.from_name` | String | `AuraSphere Pro` | ✅ Yes |

### Complete CLI Command

```bash
firebase functions:config:set \
  sendgrid.key="SG.your_api_key_from_sendgrid" \
  email.from="billing@aurasphere.com" \
  email.from_name="AuraSphere Pro" \
  sendgrid.rate_limit="100" \
  sendgrid.timeout="30000"
```

### Optional Additional Config

```bash
# Add optional SendGrid settings
firebase functions:config:set \
  sendgrid.rate_limit="100" \
  sendgrid.timeout="30000" \
  sendgrid.verify_ssl="true"
```

---

## 📝 Access Config in Cloud Functions

### TypeScript/Node.js

```typescript
import * as functions from 'firebase-functions';

const sendgridKey = functions.config().sendgrid.key;
const emailFrom = functions.config().email.from;
const emailFromName = functions.config().email.from_name;

// Use in function
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(sendgridKey);

const msg = {
  to: 'user@example.com',
  from: {
    email: emailFrom,
    name: emailFromName
  },
  subject: 'Test Email',
  text: 'Hello World',
};

await sgMail.send(msg);
```

### Accessing Configuration

```typescript
// Get all config
const config = functions.config();

// Get specific value
const key = functions.config().sendgrid.key;

// Check if exists
if (functions.config().sendgrid?.key) {
  console.log('SendGrid key configured');
}

// With fallback
const timeout = functions.config().sendgrid?.timeout || 30000;
```

---

## 🔀 Switching Between Configurations

### Development (Local)

Use `.runtimeconfig.json`:
```json
{
  "sendgrid": { "key": "SG.dev_test_key" },
  "email": { "from": "dev@aurasphere.local" }
}
```

Run:
```bash
firebase emulators:start
```

### Staging (Firebase Project)

```bash
firebase use aurasphere-staging

firebase functions:config:set \
  sendgrid.key="SG.staging_key" \
  email.from="staging@aurasphere.com"

firebase deploy --only functions
```

### Production (Firebase Project)

```bash
firebase use aurasphere-production

firebase functions:config:set \
  sendgrid.key="SG.production_key" \
  email.from="billing@aurasphere.com"

firebase deploy --only functions
```

---

## 🧪 Testing Configuration

### Test with Emulator

```bash
# Terminal 1: Start emulator
firebase emulators:start

# Terminal 2: Call test function
firebase functions:call sendEmailNotification \
  --data='{"to":"test@example.com","subject":"Test"}'

# Check logs
firebase functions:log
```

### Test in Production

```bash
# Call deployed function
firebase functions:call sendEmailNotification \
  --data='{"to":"test@example.com","subject":"Test"}'

# Monitor logs
firebase functions:log --limit 50
```

---

## ⚠️ Troubleshooting

### Issue: "Cannot read properties of undefined"

**Cause:** Configuration not set or not deployed

**Solution:**
```bash
# Check if config is set
firebase functions:config:get

# If empty, set config
firebase functions:config:set sendgrid.key="SG.xxx"

# Redeploy
firebase deploy --only functions

# Wait 30 seconds for deployment
# Then test again
```

### Issue: "API key invalid"

**Cause:** Wrong or expired API key

**Solution:**
```bash
# Get new key from SendGrid dashboard
# Update config
firebase functions:config:set sendgrid.key="SG.new_key_here"

# Redeploy
firebase deploy --only functions
```

### Issue: "Configuration changes not taking effect"

**Cause:** Old build deployed

**Solution:**
```bash
# Rebuild
cd functions
npm run build

# Redeploy
firebase deploy --only functions

# Clear local cache
rm -rf ~/.cache/firebase
```

### Issue: "Cannot access config in local development"

**Cause:** .runtimeconfig.json missing

**Solution:**
```bash
# Create .runtimeconfig.json
cat > functions/.runtimeconfig.json << 'EOF'
{
  "sendgrid": {
    "key": "SG.dev_test_key"
  },
  "email": {
    "from": "dev@aurasphere.local"
  }
}
EOF

# Ensure it's in .gitignore
echo "functions/.runtimeconfig.json" >> .gitignore

# Start emulator
firebase emulators:start
```

---

## 📊 Configuration Comparison

| Feature | CLI | .runtimeconfig.json | .env.production |
|---------|-----|-------------------|-----------------|
| **Encryption** | ✅ Yes | ❌ No | ❌ No |
| **Git Safe** | ✅ Yes | ⚠️ Must ignore | ⚠️ Must ignore |
| **Local Dev** | ⚠️ No | ✅ Yes | ✅ Yes |
| **Production** | ✅ Yes | ❌ No | ✅ Yes |
| **Easy Rotation** | ✅ Yes | ⚠️ Manual | ⚠️ Manual |
| **Environment Specific** | ✅ Yes | ✅ Yes | ✅ Yes |

**Recommendation:** Use **Firebase CLI** (Method 1) for production and **`.runtimeconfig.json`** for local development.

---

## 🚀 Deployment Commands Summary

### First-Time Setup

```bash
# 1. Login
firebase login

# 2. Select project
firebase use your-project-id

# 3. Set configuration
firebase functions:config:set \
  sendgrid.key="SG.your_api_key" \
  email.from="billing@aurasphere.com" \
  email.from_name="AuraSphere Pro"

# 4. Deploy
firebase deploy --only functions

# 5. Verify
firebase functions:log --limit 50
```

### Update Existing Configuration

```bash
# Update just the API key
firebase functions:config:set sendgrid.key="SG.new_key"

# Redeploy
firebase deploy --only functions
```

### View All Configuration

```bash
# Get entire config
firebase functions:config:get

# Pretty print
firebase functions:config:get | jq
```

### Remove/Reset Configuration

```bash
# Unset a specific config
firebase functions:config:unset sendgrid.key

# Then redeploy
firebase deploy --only functions
```

---

## 📌 Important Notes

### Security

✅ **Do:**
- Use Firebase CLI for production secrets
- Rotate API keys every 90 days
- Use different keys for dev/staging/prod
- Monitor API usage in SendGrid dashboard

❌ **Don't:**
- Commit .runtimeconfig.json to git
- Share API keys via chat/email
- Hardcode keys in source code
- Use same key across environments

### Best Practices

```bash
# Always verify before deploying
firebase functions:config:get

# Check only what you need
firebase functions:config:get sendgrid

# Use meaningful variable names
firebase functions:config:set sendgrid.key="SG_xxx"  # ✅
# NOT: firebase functions:config:set apikey="SG_xxx"  # ❌

# Deploy after config changes
firebase deploy --only functions  # ✅
# NOT: Just send code without deploying config  # ❌
```

---

## ✅ Verification Checklist

Before using SendGrid in production:

- [ ] Firebase project selected: `firebase use <project>`
- [ ] SendGrid API key set: `firebase functions:config:get sendgrid.key`
- [ ] Email from address set: `firebase functions:config:get email.from`
- [ ] Functions rebuilt: `cd functions && npm run build`
- [ ] Functions deployed: `firebase deploy --only functions`
- [ ] Config verified: `firebase functions:config:get`
- [ ] Logs checked: `firebase functions:log --limit 50`
- [ ] No errors in logs
- [ ] Test email sent successfully
- [ ] SendGrid dashboard shows delivery

---

## 📞 Quick Commands

```bash
# Show current config
firebase functions:config:get

# Set SendGrid config
firebase functions:config:set sendgrid.key="SG.xxx"

# Update multiple values
firebase functions:config:set \
  sendgrid.key="SG.xxx" \
  email.from="user@example.com"

# Remove a config
firebase functions:config:unset sendgrid.key

# Deploy with config
firebase deploy --only functions

# View logs
firebase functions:log

# List all functions
firebase functions:list

# Call a function
firebase functions:call sendEmailNotification --data='{"to":"test@example.com"}'
```

---

## 🔗 Related Documentation

- [Firebase Functions Config](https://firebase.google.com/docs/functions/config)
- [SendGrid API](https://docs.sendgrid.com/api-reference/mail-send/mail-send)
- [Node.js SendGrid Client](https://github.com/sendgrid/sendgrid-nodejs)
- [Environment Variables Setup](./ENVIRONMENT_VARIABLES_SETUP.md)

---

**Status:** ✅ Ready to Configure  
**Last Updated:** December 9, 2025
