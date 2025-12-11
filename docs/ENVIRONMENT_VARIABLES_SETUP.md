# 📧 Environment Variables Setup Guide

**Date:** December 9, 2025  
**Project:** AuraSphere Pro  
**Focus:** SendGrid Email Integration + Firebase Configuration

---

## 🔐 Security Notice

**IMPORTANT:** Never commit `.env` files to version control. These contain sensitive API keys.

```bash
# .gitignore should already contain:
.env
.env.local
.env.production
.env*.local
```

---

## 📁 Environment Files Structure

Your project uses three environment files:

| File | Purpose | Location |
|------|---------|----------|
| `.env` | Base configuration (shared) | `functions/.env` |
| `.env.local` | Local development overrides | `functions/.env.local` |
| `.env.production` | Production secrets (not in repo) | `functions/.env.production` |

---

## 🚀 Quick Setup

### 1. Local Development Setup

Create/update `functions/.env.local`:

```bash
cd /workspaces/aura-sphere-pro/functions
cp .env.local .env.local.bak  # Backup existing
```

Then add your configuration (see templates below).

### 2. Production Setup

Create `functions/.env.production` (NOT committed to git):

```bash
cd /workspaces/aura-sphere-pro/functions
touch .env.production
# Add production secrets here
```

### 3. Verify Setup

```bash
# Check environment file format
cd functions
npm run build  # TypeScript should compile without errors
```

---

## 📝 Configuration Templates

### Option A: SendGrid Email Service (Recommended)

**Use Case:** Cloud-based email delivery, highest reliability

```dotenv
# SendGrid Configuration
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx
EMAIL_FROM=billing@aurasphere.com
EMAIL_FROM_NAME=AuraSphere Pro

# Firebase Configuration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_DATABASE_URL=https://your-project.firebaseio.com

# OpenAI Configuration (for AI features)
OPENAI_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Google Cloud Configuration
GOOGLE_PROJECT_ID=your-gcp-project

# AuraToken Rewards
WELCOME_BONUS=200
DAILY_LOGIN=5

# Environment
NODE_ENV=production
```

### Option B: Gmail SMTP Service

**Use Case:** Lower cost alternative, good for development

```dotenv
# Gmail Configuration
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USER=your-email@gmail.com
MAIL_PASS=your-app-specific-password
MAIL_FROM=your-email@gmail.com
EMAIL_FROM_NAME=AuraSphere Pro

# Firebase Configuration
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_DATABASE_URL=https://your-project.firebaseio.com

# OpenAI Configuration
OPENAI_KEY=sk_test_xxxxxxxxxxxxxxxxxxxxxxxxxxxxxxxx

# Google Cloud Configuration
GOOGLE_PROJECT_ID=your-gcp-project

# AuraToken Rewards
WELCOME_BONUS=200
DAILY_LOGIN=5

# Environment
NODE_ENV=development
```

### Option C: Cloud Storage Configuration

```dotenv
# Firebase Storage (for file uploads)
FIREBASE_STORAGE_BUCKET=your-project.appspot.com

# Combined with email configuration above
SENDGRID_API_KEY=SG.xxxxxxxx
EMAIL_FROM=noreply@aurasphere.com
```

---

## 🔑 Getting Your API Keys

### SendGrid API Key

1. **Create SendGrid Account**
   - Go to [sendgrid.com](https://sendgrid.com)
   - Sign up for free tier (12,500 emails/month)

2. **Generate API Key**
   - Dashboard → Settings → API Keys
   - Create new key: "AuraSphere Cloud Functions"
   - Copy full key (starts with `SG.`)
   - ⚠️ Only shown once! Save it securely

3. **Verify Sender Email**
   - Settings → Sender Verification
   - Add verified sender (billing@aurasphere.com)
   - Click confirmation link in email

4. **Add to .env.local**
   ```dotenv
   SENDGRID_API_KEY=SG.your_actual_key_here
   EMAIL_FROM=billing@aurasphere.com
   EMAIL_FROM_NAME=AuraSphere Pro
   ```

### OpenAI API Key

1. **Create OpenAI Account**
   - Go to [platform.openai.com](https://platform.openai.com)
   - Sign up and verify email

2. **Generate API Key**
   - Account → API Keys
   - Create new secret key
   - Copy key (starts with `sk-`)

3. **Add to .env.local**
   ```dotenv
   OPENAI_KEY=sk_your_actual_key_here
   ```

### Firebase Configuration

1. **Get from Firebase Console**
   - Go to [console.firebase.google.com](https://console.firebase.google.com)
   - Select your project
   - Project Settings (gear icon)
   - Copy Project ID and Database URL

2. **Add to .env.local**
   ```dotenv
   FIREBASE_PROJECT_ID=your-project-id
   FIREBASE_DATABASE_URL=https://your-project.firebaseio.com
   ```

### Google Cloud Vision API Key

1. **Enable Vision API**
   - Google Cloud Console → APIs & Services
   - Enable "Vision API"
   - Create service account (if not using default Firebase one)
   - Download JSON key

2. **Store Securely**
   - Never commit JSON key to git
   - Use Firebase service account (automatic for Cloud Functions)

---

## 📊 Environment Variable Reference

### Email Configuration

| Variable | Type | Required | Example |
|----------|------|----------|---------|
| `SENDGRID_API_KEY` | String | For SendGrid | `SG.xxxxxxxx` |
| `EMAIL_FROM` | String | Yes | `billing@aurasphere.com` |
| `EMAIL_FROM_NAME` | String | Yes | `AuraSphere Pro` |
| `MAIL_HOST` | String | For SMTP | `smtp.gmail.com` |
| `MAIL_PORT` | Number | For SMTP | `587` |
| `MAIL_USER` | String | For SMTP | `your@gmail.com` |
| `MAIL_PASS` | String | For SMTP | `app-password` |

### Firebase Configuration

| Variable | Type | Required | Example |
|----------|------|----------|---------|
| `FIREBASE_PROJECT_ID` | String | Yes | `aurasphere-prod` |
| `FIREBASE_DATABASE_URL` | String | Yes | `https://project.firebaseio.com` |
| `FIREBASE_STORAGE_BUCKET` | String | For uploads | `project.appspot.com` |

### AI & Services

| Variable | Type | Required | Example |
|----------|------|----------|---------|
| `OPENAI_KEY` | String | For AI | `sk_test_xxx` |
| `GOOGLE_PROJECT_ID` | String | For Vision API | `gcp-project` |

### Rewards System

| Variable | Type | Default | Purpose |
|----------|------|---------|---------|
| `WELCOME_BONUS` | Number | 200 | New user AuraToken bonus |
| `DAILY_LOGIN` | Number | 5 | Daily login reward |

### System Configuration

| Variable | Type | Options | Purpose |
|----------|------|---------|---------|
| `NODE_ENV` | String | development/production | Runtime environment |

---

## 🔒 Security Best Practices

### Do's ✅

```bash
✅ Use strong, randomly generated API keys
✅ Rotate keys every 90 days
✅ Store in .env files (git-ignored)
✅ Use different keys for dev/production
✅ Enable API key restrictions on Google Cloud
✅ Monitor API usage in SendGrid dashboard
✅ Use environment-specific configurations
```

### Don'ts ❌

```bash
❌ Commit .env files to git
❌ Share API keys via email or chat
❌ Use same key across environments
❌ Hardcode keys in source code
❌ Log API keys in error messages
❌ Use test keys in production
❌ Store keys in plaintext in documentation
```

---

## 🧪 Testing Environment Variables

### Test Local Configuration

```bash
# From functions directory
cd /workspaces/aura-sphere-pro/functions

# Check environment loads correctly
npm run build  # Should compile without errors

# View loaded variables (safely)
node -e "console.log(process.env.FIREBASE_PROJECT_ID)"
```

### Test SendGrid Integration

```bash
# Install sendgrid client (if not already)
npm install @sendgrid/mail

# Create test script: test-sendgrid.js
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(process.env.SENDGRID_API_KEY);

const msg = {
  to: 'test@example.com',
  from: process.env.EMAIL_FROM,
  subject: 'Test Email from AuraSphere',
  text: 'This is a test email.',
  html: '<strong>This is a test email.</strong>',
};

sgMail
  .send(msg)
  .then(() => console.log('Email sent'))
  .catch(error => console.error(error));

# Run test
node test-sendgrid.js
```

### Test Firebase Connection

```bash
# Create test script: test-firebase.js
const admin = require('firebase-admin');

const projectId = process.env.FIREBASE_PROJECT_ID;
console.log('Connecting to Firebase project:', projectId);

if (!admin.apps.length) {
  admin.initializeApp({
    projectId: projectId,
  });
}

admin.firestore().collection('_test').doc('connection').set({
  timestamp: new Date(),
  message: 'Connection test successful'
}).then(() => {
  console.log('✅ Firebase connection successful');
  process.exit(0);
}).catch(err => {
  console.error('❌ Firebase connection failed:', err.message);
  process.exit(1);
});

# Run test
node test-firebase.js
```

---

## 🚀 Deployment to Firebase

### Before Deploying

1. **Verify .env.production exists** (outside git)
   ```bash
   ls functions/.env.production  # Should exist
   cat .gitignore | grep .env    # Should exclude .env
   ```

2. **Test locally**
   ```bash
   cd functions
   npm run build
   npm run serve  # Local emulator
   ```

### Deploy Function Environment Variables

```bash
# Method 1: Deploy with local .env.production
firebase deploy --only functions

# Method 2: Set via Firebase Console (alternative)
firebase functions:config:set \
  sendgrid.key="SG.xxxxx" \
  sendgrid.from="billing@aurasphere.com" \
  firebase.project="your-project"

# Method 3: Deploy via Google Cloud (for complex configs)
gcloud functions deploy yourFunction \
  --set-env-vars SENDGRID_API_KEY=SG.xxxxx
```

### Verify Deployment

```bash
# Check deployed functions have access to variables
firebase functions:log --limit 50

# Monitor environment variable usage
firebase functions:config:get
```

---

## 📝 Environment File Templates

### Complete Development Template

```dotenv
# .env.local (Development)

# Email - SendGrid
SENDGRID_API_KEY=SG.dev_key_xxxxxxxx
EMAIL_FROM=dev@aurasphere.local
EMAIL_FROM_NAME=AuraSphere (Dev)

# Firebase
FIREBASE_PROJECT_ID=aurasphere-dev
FIREBASE_DATABASE_URL=https://aurasphere-dev.firebaseio.com
FIREBASE_STORAGE_BUCKET=aurasphere-dev.appspot.com

# OpenAI (Testing/Development)
OPENAI_KEY=sk_test_xxxxxxxxxxxxxxxx

# Google Cloud
GOOGLE_PROJECT_ID=aurasphere-dev

# AuraToken Rewards (Development)
WELCOME_BONUS=1000
DAILY_LOGIN=10

# Environment
NODE_ENV=development
```

### Complete Production Template

```dotenv
# .env.production (Production - DO NOT COMMIT)

# Email - SendGrid
SENDGRID_API_KEY=SG.prod_key_xxxxxxxx
EMAIL_FROM=billing@aurasphere.com
EMAIL_FROM_NAME=AuraSphere Pro

# Firebase
FIREBASE_PROJECT_ID=aurasphere-prod
FIREBASE_DATABASE_URL=https://aurasphere-prod.firebaseio.com
FIREBASE_STORAGE_BUCKET=aurasphere-prod.appspot.com

# OpenAI (Production)
OPENAI_KEY=sk_live_xxxxxxxxxxxxxxxx

# Google Cloud
GOOGLE_PROJECT_ID=aurasphere-prod

# AuraToken Rewards (Production)
WELCOME_BONUS=200
DAILY_LOGIN=5

# Environment
NODE_ENV=production
```

---

## 🔧 Troubleshooting

### "SENDGRID_API_KEY is undefined"

```bash
# 1. Check .env file exists
ls functions/.env.local

# 2. Verify key format (starts with SG.)
grep SENDGRID_API_KEY functions/.env.local

# 3. Check for syntax errors
cat functions/.env.local

# 4. Ensure npm installed dependencies
cd functions && npm install

# 5. Rebuild and test
npm run build
```

### "Cannot connect to Firebase"

```bash
# 1. Verify project ID
grep FIREBASE_PROJECT_ID functions/.env.local

# 2. Check if project exists
firebase projects:list

# 3. Verify authentication
firebase auth:export temp.json

# 4. Check Firestore access
firebase firestore:indexes
```

### Email sending fails

```bash
# 1. Verify SendGrid API key is valid
# Log into SendGrid dashboard → check usage

# 2. Check sender email is verified
# SendGrid → Settings → Sender Verification

# 3. Review error logs
firebase functions:log --limit 100

# 4. Test manually (see Testing section above)
node test-sendgrid.js
```

---

## ✅ Deployment Checklist

Before deploying to production:

- [ ] Created `.env.production` (NOT in git)
- [ ] Verified SendGrid API key is correct
- [ ] Verified email sender is verified in SendGrid
- [ ] Updated FIREBASE_PROJECT_ID for production
- [ ] Tested locally with `npm run serve`
- [ ] Ran `npm run build` with no errors
- [ ] Tested email sending locally
- [ ] Verified no .env files will be committed
- [ ] Set up monitoring alerts in Firebase Console
- [ ] Have backup API keys (rotate when deployed)

---

## 📞 Support & References

### SendGrid Documentation
- [SendGrid API Reference](https://docs.sendgrid.com/api-reference/mail-send/mail-send)
- [SendGrid Node.js Library](https://github.com/sendgrid/sendgrid-nodejs)
- [Email Best Practices](https://docs.sendgrid.com/ui/sending-email/sender-verification)

### Firebase Documentation
- [Firebase Environment Configuration](https://firebase.google.com/docs/functions/config)
- [Cloud Functions Security](https://firebase.google.com/docs/functions/organize-functions)

### OpenAI Documentation
- [OpenAI API Reference](https://platform.openai.com/docs)
- [Rate Limits & Quotas](https://platform.openai.com/docs/guides/rate-limits)

---

**Last Updated:** December 9, 2025  
**Version:** 1.0  
**Status:** ✅ Ready for Use
