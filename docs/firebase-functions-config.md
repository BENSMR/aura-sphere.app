# Firebase Functions Configuration Guide

## Overview
AuraSphere Pro uses Firebase Functions to integrate with external services like OpenAI and Resend. Configuration is managed via Firebase Functions Config.

## Setting Environment Variables

Before deploying, configure your API keys:

```bash
# Set OpenAI API Key (optional but required for AI features)
firebase functions:config:set openai.key="sk_XXXXXXXXXXXXXXXXXXXXXXXX"

# Set Resend API Key (required for email delivery)
firebase functions:config:set resend.api_key="re_XXXXXXXXXXXXXXXXXXXXX"

# Set other environment variables as needed
firebase functions:config:set stripe.key="sk_XXXXXXXXXXXXXXXXXXXXX"
firebase functions:config:set vision.key="XXXXXXXXXXXXXXXXXXXXX"
```

## Accessing Configuration in Code

All configuration is available via `functions.config()`:

```typescript
import * as functions from 'firebase-functions';

const OPENAI_KEY = functions.config().openai?.key || null;
const RESEND_KEY = functions.config().resend?.api_key || null;
const STRIPE_KEY = functions.config().stripe?.key || null;
```

The optional chaining (`?.`) ensures graceful degradation if a key isn't set.

## Feature Gating

Features automatically degrade if API keys are missing:

| Feature | Env Var | Fallback | Impact |
|---------|---------|----------|--------|
| AI Finance Coach | `openai.key` | Rule-based advisor only | AI narrative disabled |
| Email Digests | `resend.api_key` | In-app notifications only | Email delivery disabled |
| Payments | `stripe.key` | No payment processing | Payment features unavailable |
| Receipt OCR | `vision.key` | Manual entry required | Receipt scanning disabled |

## Deployment

After setting config, deploy functions:

```bash
# Deploy all functions with current config
firebase deploy --only functions

# Or deploy specific function groups
firebase deploy --only functions:getFinanceCoachCallable,functions:sendDigestEmail
```

## Verifying Configuration

Check current config:

```bash
firebase functions:config:get
```

## Managing Secrets (Production)

For production deployments, use Firebase Secret Manager:

```bash
# Create a secret
gcloud secrets create openai-key --data-file=- <<< "sk_XXXXX"

# Reference in functions:
gcloud functions deploy getFinanceCoachCallable \
  --set-env-vars OPENAI_KEY=projects/PROJECT_ID/secrets/openai-key/versions/latest
```

## Development / Local Testing

For local emulation, create `.env.local` in the `functions` directory:

```bash
# functions/.env.local
openai__key=sk_test_XXXXX
resend__api_key=re_test_XXXXX
stripe__key=sk_test_XXXXX
```

Then start emulator:

```bash
firebase emulators:start
```

## Troubleshooting

### Missing API Key Error
If you see `OPENAI_KEY is undefined`, ensure:
1. You set the config: `firebase functions:config:set openai.key="sk_XXXXX"`
2. You deployed after setting: `firebase deploy --only functions`
3. Check config: `firebase functions:config:get`

### Config Not Updating
Config changes require redeployment:
```bash
firebase functions:config:set openai.key="new_key"
firebase deploy --only functions
```

## API Key Sources

- **OpenAI**: https://platform.openai.com/account/api-keys
- **Resend**: https://resend.com/api-keys
- **Stripe**: https://dashboard.stripe.com/apikeys
- **Google Vision**: Google Cloud Console → APIs & Services → Credentials
