# ☁️ Cloud Build Configuration

**Status:** ✅ CONFIGURED | **Date:** November 30, 2025

---

## Overview

This project uses **Google Cloud Build** to automatically deploy Cloud Functions when changes are pushed to the main branch.

---

## What Gets Deployed

The Cloud Build pipeline deploys:

1. **Firestore Security Rules** (`firestore.rules`)
2. **Cloud Storage Rules** (`storage.rules`)
3. **Cloud Functions** (`functions/` directory)

**Note:** The Flutter mobile app is NOT deployed via Cloud Build. It's built and distributed via:
- **iOS:** App Store
- **Android:** Google Play Store

---

## Configuration Files

### `cloudbuild.yaml`

The main Cloud Build configuration file that defines the deployment pipeline:

```yaml
steps:
  - Install Node.js dependencies
  - Build TypeScript Cloud Functions
  - Deploy to Firebase
```

### `.buildpacks`

Tells Google Cloud Build to skip buildpack detection (not needed for this project).

---

## Prerequisites

Before the Cloud Build can deploy, you need:

1. **Firebase Project:** Already created ✅
2. **Firebase Token:** Store as a Secret in Cloud Build
3. **GitHub Connection:** Connected to Google Cloud Build
4. **Cloud Build Enabled:** Enable in Google Cloud Console

---

## Setup Instructions

### Step 1: Get Firebase Token

```bash
firebase login:ci
```

This generates a long token. Copy it.

### Step 2: Store Firebase Token in Cloud Build

1. Go to **Google Cloud Console**
2. Navigate to **Cloud Build → Settings → Secrets**
3. Click **Create Secret**
4. Name: `FIREBASE_TOKEN`
5. Value: Paste the token from Step 1
6. Note the resource name (e.g., `projects/XXX/secrets/FIREBASE_TOKEN/versions/latest`)

### Step 3: Update cloudbuild.yaml

Replace the `_FIREBASE_TOKEN` substitution with your secret resource name:

```yaml
steps:
  - name: 'gcr.io/cloud-builders/firebase'
    secretEnv: ['FIREBASE_TOKEN']
    args:
      - 'deploy'
      - '--only'
      - 'firestore:rules,storage:rules,functions'
      - '--token'
      - '${FIREBASE_TOKEN}'

availableSecrets:
  secretManager:
    - versionName: projects/YOUR-PROJECT-ID/secrets/FIREBASE_TOKEN/versions/latest
      env: 'FIREBASE_TOKEN'
```

### Step 4: Connect GitHub Repository

1. Go to **Google Cloud Console**
2. Navigate to **Cloud Build → Triggers**
3. Click **Create Trigger**
4. Connect to GitHub
5. Select this repository
6. Configure:
   - **Name:** `Deploy AuraSphere Pro`
   - **Branch:** `^main$`
   - **Build Configuration:** `Cloud Build configuration file`
   - **Configuration file location:** `cloudbuild.yaml`
7. Click **Create**

### Step 5: Test the Trigger

```bash
# Make a small change and push to main
git add .
git commit -m "test: trigger cloud build"
git push origin main

# View build logs
# Go to Cloud Build → Build History
```

---

## Manual Deployment (Without Cloud Build)

If you prefer to deploy manually from your local machine:

```bash
# Deploy everything
firebase deploy

# Deploy only specific services
firebase deploy --only firestore:rules
firebase deploy --only storage:rules
firebase deploy --only functions
```

---

## Deployment Pipeline Flow

```
Push to main branch
    ↓
GitHub webhook triggers Cloud Build
    ↓
Cloud Build starts execution:
  1. Install npm dependencies
  2. Build TypeScript (tsc)
  3. Run Firebase deployment
    ↓
Firebase updates:
  - Firestore Rules
  - Storage Rules
  - Cloud Functions
    ↓
✅ Deployment complete
    ↓
Build succeeds/fails notification
```

---

## Monitoring Deployments

### View Build Logs

```bash
# View recent builds
gcloud builds list

# View specific build logs
gcloud builds log BUILD_ID
```

### View Firebase Deployment Logs

```bash
# View function logs
firebase functions:log

# View specific function
firebase functions:log --limit=50
```

---

## Common Issues

### Build Failed: "No buildpack groups passed detection"

**Solution:** Use the `cloudbuild.yaml` file (already provided). This explicitly tells Cloud Build what to do instead of trying to auto-detect.

### Build Failed: "Unknown Firebase Token"

**Solution:** 
1. Re-generate the Firebase token: `firebase login:ci`
2. Update the secret in Cloud Build
3. Re-run the build

### Build Failed: "Function deployment failed"

**Solution:**
1. Check function logs: `firebase functions:log`
2. Verify TypeScript compiles: `cd functions && npm run build`
3. Check for missing dependencies: `cd functions && npm ci`

---

## Automatic Deployments

Once configured, every push to the `main` branch will:

1. ✅ Install dependencies
2. ✅ Build Cloud Functions
3. ✅ Deploy to Firebase
4. ✅ Update live services

**Note:** Only commits to the `main` branch trigger deployments. PRs do not trigger deployments.

---

## Disabling Auto-Deployment

If you need to stop auto-deployment:

1. Go to **Google Cloud Console**
2. Navigate to **Cloud Build → Triggers**
3. Find the trigger
4. Click the menu (⋮)
5. Select **Disable**

---

## Secrets Management

Your Firebase token is stored securely in:
- **Google Cloud Secret Manager**
- Only accessible during Cloud Build execution
- Not visible in logs or version control
- Can be rotated anytime

---

## Environment

- **Machine Type:** N1_HIGHCPU_8 (8 vCPU, 7.5 GB memory)
- **Timeout:** 30 minutes (1800 seconds)
- **Node.js Version:** 20 (from functions/package.json)
- **Build Region:** us-central1

---

## Next Steps

1. ✅ Review `cloudbuild.yaml` configuration
2. ✅ Generate Firebase token with `firebase login:ci`
3. ✅ Store token in Cloud Build Secrets
4. ✅ Create Cloud Build trigger in GCP Console
5. ✅ Test by pushing a commit to main
6. ✅ Monitor build logs in Cloud Build dashboard

---

## Related Documentation

- [Google Cloud Build Documentation](https://cloud.google.com/build/docs)
- [Firebase Deployment Guide](https://firebase.google.com/docs/cli/deploy)
- [Cloud Build Secrets](https://cloud.google.com/build/docs/securing-builds/use-secrets)

---

**Last updated:** November 30, 2025  
**Status:** ✅ Ready to Deploy  
**Version:** 1.0  

Once configured, your project will deploy automatically on every push to main! 🚀
