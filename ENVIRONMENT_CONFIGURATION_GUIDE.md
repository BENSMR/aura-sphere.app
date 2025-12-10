# Environment Configuration Guide

## Overview

AuraSphere Pro uses environment variables for:
- Firebase and Google Cloud configuration
- Audit archival and encryption settings
- External service integrations (SendGrid, Slack, OpenAI, Stripe)
- Security and admin setup codes

Environment variables are loaded from `.env` (production) or `.env.local` (development).

## Files

- **`.env.example`** — Template for all available settings (tracked in git)
- **`.env`** — Production configuration (`.gitignore` — never commit)
- **`.env.local`** — Local development configuration (`.gitignore` — never commit)
- **`functions/.env`** — Cloud Functions configuration (deployed to Firebase)

## Setup Instructions

### 1. Create Environment Files

```bash
# Create production config from template
cp .env.example .env

# Create local development config
cp .env.example .env.local
```

### 2. Fill in Required Values

#### Firebase & Google Cloud (Required)

```bash
FIREBASE_PROJECT_ID=your-project-id
GOOGLE_PROJECT_ID=your-gcp-project
```

Get from: https://console.firebase.google.com → Project Settings

#### Archive Storage (Required for Audit Archival)

```bash
# Create a GCS bucket for audit archives
gsutil mb gs://your-bucket-name

# Set in environment
ARCHIVE_BUCKET=your-bucket-name
ARCHIVE_RETENTION_DAYS=365
```

#### Encryption (Optional but Recommended)

```bash
# Generate encryption key
openssl rand -base64 32
# Output: AbCdEfGhIjKlMnOpQrStUvWxYz1234567890==

# Set in environment
ENCRYPTION_KEY_BASE64=AbCdEfGhIjKlMnOpQrStUvWxYz1234567890==
```

Or use Google Cloud KMS:

```bash
# Create KMS key
gcloud kms keyrings create audit-keys --location=us-central1
gcloud kms keys create audit-key --location=us-central1 --keyring=audit-keys --purpose=encryption

# Get key ID
gcloud kms keys list --location=us-central1 --keyring=audit-keys

# Set in environment
KMS_KEY_ID=projects/YOUR_PROJECT/locations/us-central1/keyRings/audit-keys/cryptoKeys/audit-key
```

#### Email (Required)

```bash
# Using SendGrid (recommended)
SENDGRID_API_KEY=SG.xxxxxxxxxxxxxxxxxxxxx
EMAIL_FROM=billing@aurasphere.com
EMAIL_FROM_NAME=AuraSphere Pro
```

Get SendGrid key: https://sendgrid.com → Settings → API Keys

#### Slack Notifications (Recommended)

```bash
# Create Slack incoming webhook
# 1. Go to your Slack workspace
# 2. Click "Apps" → "Incoming Webhooks"
# 3. "Add New Webhook to Workspace"
# 4. Copy the webhook URL

SLACK_WEBHOOK_URL=https://hooks.slack.com/services/T00000000/B00000000/XXXXXXXXXXXXXXXXXXXX
SLACK_NOTIFY_ADMIN_CHANGES=true
SLACK_NOTIFY_HIGH_VALUE=true
HIGH_VALUE_THRESHOLD=5000
```

#### Admin Setup (Required for First Admin)

```bash
# Generate secure setup code
openssl rand -hex 32

# Set in environment
SETUP_CODE=your_secure_code_here
```

This is used once during `setFirstAdmin` endpoint call.

#### OpenAI (For AI Features)

```bash
# Get from: https://platform.openai.com/api-keys
OPENAI_KEY=sk_live_xxxxxxxxxxxxxxxxxxxxx
```

#### Stripe (For Payment Processing)

```bash
# Get from: https://dashboard.stripe.com/apikeys
STRIPE_SECRET_KEY=sk_live_xxxxxxxxxxxxxxxxxxxxx
STRIPE_PUBLISHABLE_KEY=pk_live_xxxxxxxxxxxxxxxxxxxxx
```

## Environment-Specific Configuration

### Production (`.env`)

```bash
NODE_ENV=production
LOG_LEVEL=info
ARCHIVE_RETENTION_DAYS=365
SIGNED_URL_EXPIRATION_SECONDS=3600
SLACK_NOTIFY_ADMIN_CHANGES=true
SLACK_NOTIFY_HIGH_VALUE=true
```

### Development (`.env.local`)

```bash
NODE_ENV=development
LOG_LEVEL=debug
ARCHIVE_RETENTION_DAYS=7
SLACK_NOTIFY_ADMIN_CHANGES=false
VERBOSE_AUDIT_LOGGING=true

# Point to local Firebase emulator
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
```

### Local Testing (Firebase Emulator)

```bash
# Start emulator
firebase emulators:start

# In another terminal, set environment variables
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
export FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
export FIREBASE_PROJECT_ID=aurasphere-pro-dev

# Deploy to emulator
firebase deploy
```

## Deploying to Cloud Functions

### Option 1: Using Environment File

```bash
# Copy .env to functions/.env
cp .env functions/.env

# Deploy (Firebase CLI reads functions/.env)
firebase deploy --only functions
```

### Option 2: Using Firebase Configuration

```bash
# Set via Firebase CLI
firebase functions:config:set \
  archive.bucket="your-bucket" \
  archive.retention_days="365" \
  encryption.key="YOUR_BASE64_KEY" \
  slack.webhook_url="YOUR_WEBHOOK" \
  admin.setup_code="YOUR_CODE"

# Deploy
firebase deploy --only functions
```

Access in Cloud Functions:

```typescript
import * as functions from 'firebase-functions';

const config = functions.config();
const archiveBucket = config.archive?.bucket;
const encryptionKey = config.encryption?.key;
```

### Option 3: Using Secret Manager

```bash
# Store secrets in Google Cloud Secret Manager
gcloud secrets create archive-bucket --data-file=- <<< "your-bucket-name"
gcloud secrets create encryption-key --data-file=- <<< "YOUR_BASE64_KEY"
gcloud secrets create slack-webhook --data-file=- <<< "YOUR_WEBHOOK"

# Grant Cloud Functions access
gcloud secrets add-iam-policy-binding archive-bucket \
  --member=serviceAccount:PROJECT_ID@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor

# Reference in cloud.json
# Then use: admin.secretmanager.accessSecret('archive-bucket')
```

## Validation Checklist

Before deploying, verify:

- [ ] `FIREBASE_PROJECT_ID` is set and valid
- [ ] `ARCHIVE_BUCKET` exists in GCS and is readable
- [ ] `ENCRYPTION_KEY_BASE64` is valid base64 (or empty)
- [ ] `SENDGRID_API_KEY` starts with `SG.`
- [ ] `SLACK_WEBHOOK_URL` starts with `https://hooks.slack.com`
- [ ] `SETUP_CODE` is set to a strong random string
- [ ] `OPENAI_KEY` starts with `sk_` (if using AI features)
- [ ] `STRIPE_SECRET_KEY` starts with `sk_live_` or `sk_test_`
- [ ] `.env` and `.env.local` are in `.gitignore`

## Troubleshooting

### Issue: "Cannot read environment variable"

**Cause:** Variable not set in `.env` or Cloud Functions config

**Fix:**
```bash
# Check .env exists and has variable
cat .env | grep VARIABLE_NAME

# Or check Firebase config
firebase functions:config:get
```

### Issue: "Encryption key invalid"

**Cause:** `ENCRYPTION_KEY_BASE64` is not valid base64 or wrong length (must be 32 bytes)

**Fix:**
```bash
# Generate valid key
openssl rand -base64 32

# Verify it decodes to 32 bytes
echo "YOUR_KEY" | base64 -d | wc -c  # Should output 32
```

### Issue: "Slack webhook URL not reachable"

**Cause:** Invalid URL or workspace revoked webhook

**Fix:**
```bash
# Test webhook
curl -X POST -H 'Content-type: application/json' \
  --data '{"text":"Test"}' \
  YOUR_WEBHOOK_URL

# If fails, regenerate webhook in Slack
```

### Issue: SendGrid emails not sending

**Cause:** Invalid API key or sender not verified

**Fix:**
```bash
# Verify API key starts with SG.
echo $SENDGRID_API_KEY | grep "^SG\."

# Verify sender email is verified in SendGrid
# https://app.sendgrid.com/settings/sender_auth
```

## Security Best Practices

✅ **DO:**
- Store real credentials in `.env` (never commit)
- Use strong random strings for setup codes
- Rotate encryption keys periodically
- Use service account keys for GCP access
- Enable Secret Manager for sensitive values
- Audit environment variable access logs

❌ **DON'T:**
- Commit `.env` or `.env.local` to version control
- Share credentials in Slack, email, or chat
- Use same setup code across environments
- Store plaintext keys in code comments
- Use test credentials in production

## Next Steps

1. **Create `.env` from `.env.example`**
2. **Fill in required values (Firebase, GCS, SendGrid)**
3. **Generate encryption key** (optional but recommended)
4. **Set up Slack webhook** (for notifications)
5. **Test with emulator** (`.env.local` + `firebase emulators:start`)
6. **Deploy to Cloud Functions** (`firebase deploy`)

---

**Last Updated:** December 10, 2025
**Status:** Production Ready
