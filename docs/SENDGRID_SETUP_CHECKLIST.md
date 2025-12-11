# ✅ SendGrid Environment Setup Checklist

**Date:** December 9, 2025  
**Status:** Production Ready  

---

## 📋 Pre-Deployment Setup Checklist

### Phase 1: SendGrid Account Setup

- [ ] **Create SendGrid Account**
  - [ ] Visit [sendgrid.com](https://sendgrid.com)
  - [ ] Sign up for free account (12,500 emails/month)
  - [ ] Verify email address
  - [ ] Set up billing (if needed)

- [ ] **Generate API Key**
  - [ ] Log into SendGrid dashboard
  - [ ] Go to: Settings → API Keys
  - [ ] Click "Create API Key"
  - [ ] Name: "AuraSphere Cloud Functions"
  - [ ] Permissions: Mail Send (can be restricted)
  - [ ] Copy key (format: SG.xxxxxxxxxxxxx)
  - [ ] ⚠️ Save securely - shown only once!

- [ ] **Verify Sender Email**
  - [ ] Go to: Settings → Sender Verification
  - [ ] Click "Create New Sender"
  - [ ] Add: billing@aurasphere.com
  - [ ] Fill in sender details
  - [ ] Check email for verification link
  - [ ] Click link to verify

### Phase 2: Firebase Configuration

- [ ] **Get Firebase Project Details**
  - [ ] Go to [console.firebase.google.com](https://console.firebase.google.com)
  - [ ] Select your project
  - [ ] Click gear icon → Project Settings
  - [ ] Copy Project ID: _______________
  - [ ] Copy Database URL: _______________
  - [ ] Copy Storage Bucket: _______________

- [ ] **Verify Cloud Functions Runtime**
  - [ ] Firebase Console → Functions
  - [ ] All functions should show Node.js 20 or later
  - [ ] No errors in deployment history

### Phase 3: Local Environment Setup

- [ ] **Update functions/.env.local**
  ```bash
  cd /workspaces/aura-sphere-pro
  # File should already exist, verify contents:
  cat functions/.env.local
  ```
  Should contain:
  ```
  SENDGRID_API_KEY=SG.dev_test_xxxxx
  EMAIL_FROM=dev@aurasphere.local
  FIREBASE_PROJECT_ID=aurasphere-dev
  ...
  ```

- [ ] **Verify .gitignore Protection**
  ```bash
  grep ".env" .gitignore
  # Should show: .env, .env.local, functions/.env
  ```

### Phase 4: Production Environment Setup

- [ ] **Create Production Environment File**
  ```bash
  cd /workspaces/aura-sphere-pro/functions
  touch .env.production
  chmod 600 .env.production
  ```

- [ ] **Add Production Configuration to .env.production**
  ```
  SENDGRID_API_KEY=SG.your_actual_production_key
  EMAIL_FROM=billing@aurasphere.com
  EMAIL_FROM_NAME=AuraSphere Pro
  FIREBASE_PROJECT_ID=your-production-project
  FIREBASE_DATABASE_URL=https://your-production-project.firebaseio.com
  FIREBASE_STORAGE_BUCKET=your-production-project.appspot.com
  OPENAI_KEY=sk_live_xxxxx
  GOOGLE_PROJECT_ID=your-production-gcp
  WELCOME_BONUS=200
  DAILY_LOGIN=5
  NODE_ENV=production
  ```

- [ ] **Verify File Permissions**
  ```bash
  ls -la functions/.env.production
  # Should show: -rw------- (600 permissions)
  ```

- [ ] **Confirm Not in Git**
  ```bash
  git status | grep .env.production
  # Should show: nothing (file is ignored)
  ```

### Phase 5: Local Testing

- [ ] **Build Cloud Functions**
  ```bash
  cd functions
  npm run build
  # Expected: ✅ Compilation successful
  ```

- [ ] **Start Firebase Emulator**
  ```bash
  firebase emulators:start
  # Expected: ✅ All emulators running
  ```

- [ ] **Test Email Function** (in another terminal)
  ```bash
  firebase functions:call sendEmailNotification \
    --data='{"to":"test@example.com","subject":"Test"}'
  # Expected: ✅ Function executes (check logs)
  ```

- [ ] **Verify SendGrid Receives Email**
  - [ ] Check SendGrid dashboard → Mail Send stats
  - [ ] Should show delivery count increased

### Phase 6: Pre-Deployment Verification

- [ ] **Code Review**
  - [ ] No hardcoded API keys in source code
  - [ ] No .env files in git history
  - [ ] All imports/dependencies present
  - [ ] TypeScript compiles without errors

- [ ] **Security Check**
  - [ ] API keys not logged anywhere
  - [ ] .env.production exists and is protected (600)
  - [ ] .gitignore properly excludes .env files
  - [ ] No secrets in error messages

- [ ] **Firebase Console**
  - [ ] All Firestore collections visible
  - [ ] Security rules are in place
  - [ ] Storage rules configured
  - [ ] Functions have adequate quota

### Phase 7: Production Deployment

- [ ] **Final Verification**
  ```bash
  # Check environment will be loaded
  ls -la functions/.env.production
  
  # Verify not staged for commit
  git status | grep .env
  
  # Ensure TypeScript builds
  cd functions && npm run build
  ```

- [ ] **Deploy to Firebase**
  ```bash
  firebase login
  firebase use your-production-project
  firebase deploy --only functions
  # Expected: ✅ Deploy complete
  ```

- [ ] **Verify Deployment**
  ```bash
  firebase functions:list
  # All functions should show status: OK
  
  firebase functions:log --limit 50
  # Check for any errors related to SENDGRID_API_KEY
  ```

### Phase 8: Production Testing

- [ ] **Test Email Delivery**
  - [ ] Send test email via function
  - [ ] Verify email received in inbox
  - [ ] Check SendGrid dashboard for delivery status

- [ ] **Monitor for 24 Hours**
  - [ ] Check Firebase logs regularly
  - [ ] Monitor SendGrid usage stats
  - [ ] Set up email delivery alerts
  - [ ] Verify no error patterns

- [ ] **Enable Alerts** (Firebase Console)
  - [ ] Alert on function errors
  - [ ] Alert on quota exceeded
  - [ ] Alert on high latency

---

## 🔐 Security Checklist

- [ ] `.env.production` created with 600 permissions
- [ ] No .env files committed to git
- [ ] API key format verified (starts with SG.)
- [ ] API key has minimum required permissions
- [ ] Sender email verified in SendGrid
- [ ] 2FA enabled on SendGrid account
- [ ] Unused API keys revoked
- [ ] No API keys logged in code
- [ ] Different keys for dev/prod environments
- [ ] No sensitive data in Firebase rules

---

## 📊 Configuration Reference

### SendGrid

| Item | Value |
|------|-------|
| API Key Format | `SG.xxxxxxxxxxxxx` |
| From Email | `billing@aurasphere.com` |
| From Name | `AuraSphere Pro` |
| Account | https://sendgrid.com/dashboard |
| Rate Limit | 100 emails/second |
| Monthly Quota | 12,500 (free) or paid plan |

### Firebase

| Item | Development | Production |
|------|------------|------------|
| Project ID | `aurasphere-dev` | `aurasphere-prod` |
| Environment | `.env.local` | `.env.production` |
| Node.js Version | 20+ | 20+ |
| Database URL | https://dev.firebaseio.com | https://prod.firebaseio.com |
| Storage Bucket | `dev.appspot.com` | `prod.appspot.com` |

---

## 📞 Quick Reference

### Critical Files

| File | Purpose | Git Status |
|------|---------|-----------|
| `.env` | Base configuration | ✅ Ignored |
| `.env.local` | Dev overrides | ✅ Ignored |
| `.env.production` | Production secrets | ✅ Ignored |
| `.env.example` | Template (no secrets) | 📝 Committed |
| `.gitignore` | Exclude .env files | 📝 Committed |

### Key Commands

```bash
# Setup
firebase login
firebase use your-project

# Testing
firebase emulators:start
firebase functions:call myFunction --data='{}'

# Deployment
npm run build
firebase deploy --only functions

# Monitoring
firebase functions:log --limit 50
firebase functions:list
```

### Help & Documentation

- SendGrid API: https://docs.sendgrid.com/api-reference/mail-send/mail-send
- Firebase Functions: https://firebase.google.com/docs/functions
- Environment Config: https://firebase.google.com/docs/functions/config
- TypeScript Setup: https://www.typescriptlang.org/docs/

---

## ✅ Sign-Off

- **Setup Date:** December 9, 2025
- **Last Verified:** December 9, 2025
- **Status:** ✅ READY FOR PRODUCTION
- **Next Review:** After first production deployment

---

## 📝 Notes

```
Use this section to track any custom configurations:

SendGrid Account: ___________________________
API Key (first 10 chars): SG.________________
From Email: _________________________________
Project ID: ________________________________
Deployment Date: ____________________________
Deployed By: ________________________________
```

---

**Print this checklist and keep a copy for deployment day!**
