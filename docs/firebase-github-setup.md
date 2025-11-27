# Firebase + GitHub Integration Guide

## Prerequisites
- Firebase project created and configured
- GitHub repository initialized
- Firebase CLI installed locally

## Step 1: Generate Firebase CI Token

Run locally on your machine:

```bash
firebase login:ci
```

This will:
1. Open your browser for authentication
2. Generate a CI token
3. Display the token in your terminal

**Copy this token** - you'll need it for GitHub.

## Step 2: Add Firebase Token to GitHub Secrets

1. Navigate to your GitHub repository
2. Go to **Settings** → **Secrets and variables** → **Actions**
3. Click **New repository secret**
4. Name: `FIREBASE_TOKEN`
5. Value: Paste the token from Step 1
6. Click **Add secret**

## Step 3: Verify Workflow File

The workflow file is already created at `.github/workflows/firebase-deploy.yml`

This workflow will:
- ✅ Deploy Firestore rules
- ✅ Deploy Storage rules  
- ✅ Deploy Cloud Functions
- ✅ Deploy Firestore indexes

Triggers on:
- Push to `main` branch
- Manual workflow dispatch

## Step 4: Test the Deployment

### Option A: Push to main
```bash
git add .
git commit -m "Setup Firebase CI/CD"
git push origin main
```

### Option B: Manual trigger
1. Go to **Actions** tab in GitHub
2. Select "Deploy to Firebase" workflow
3. Click **Run workflow**

## Step 5: Monitor Deployment

1. Go to **Actions** tab in your GitHub repo
2. Click on the running workflow
3. Watch real-time logs for each deployment step

## Troubleshooting

### Token Invalid
If deployment fails with authentication error:
```bash
# Generate new token
firebase login:ci

# Update GitHub secret with new token
```

### Missing Firebase Config
Ensure these files exist locally (do NOT commit to public repo):
- `android/app/google-services.json`
- `ios/Runner/GoogleService-Info.plist`
- `web/firebase-config.js`

### Functions Build Fails
```bash
cd functions
npm install
npm run build
```

Fix any TypeScript errors before pushing.

## Security Notes

⚠️ **DO NOT** commit these files to public repos:
- `google-services.json`
- `GoogleService-Info.plist`
- `.env` files with secrets

✅ **Safe to commit**:
- `firebase.json`
- `firestore.rules`
- `storage.rules`
- `firestore.indexes.json`
- `web/firebase-config.js` (contains only public API keys)

## Next Steps

After successful deployment:

1. **Enable Auth Providers**: Go to Firebase Console → Authentication → Sign-in method → Enable Email/Password and Google
2. **Add SHA-1 for Android**: Firebase Console → Project Settings → Add SHA-1 fingerprint for Google Sign-In
3. **Test locally**: `flutter run -d chrome`
4. **Monitor usage**: Firebase Console → Usage and billing

## Local Testing Before Deploy

```bash
# Test Firestore rules locally
firebase emulators:start --only firestore

# Deploy specific components
firebase deploy --only firestore:rules
firebase deploy --only functions
firebase deploy --only storage:rules
```
