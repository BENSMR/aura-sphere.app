# 🚀 Firebase Functions Config — Execution Guide

**Quick Reference for Setting SendGrid Configuration**

---

## Command Format

```bash
firebase functions:config:set \
  sendgrid.key="SG_xxx" \
  email.from="noreply@aurasphere.app" \
  email.from_name="AuraSphere"
```

---

## Your Configuration

Based on your request, here's the exact command to run:

### Option A: Your Specified Configuration

```bash
firebase functions:config:set \
  sendgrid.key="SG.your_actual_api_key_here" \
  email.from="noreply@aurasphere.app" \
  email.from_name="AuraSphere"
```

**Replace:** `SG.your_actual_api_key_here` with your real SendGrid API key

### Option B: Recommended Configuration

```bash
firebase functions:config:set \
  sendgrid.key="SG.your_actual_api_key_here" \
  email.from="billing@aurasphere.app" \
  email.from_name="AuraSphere Pro"
```

---

## Step-by-Step Execution

### 1. Ensure You're Logged In

```bash
firebase login
```

### 2. Select Your Project

```bash
firebase use aurasphere-prod
# or: firebase projects:list (to see available projects)
```

### 3. Get Your SendGrid API Key

Login to SendGrid:
- Go to: https://sendgrid.com/dashboard
- Settings → API Keys
- Copy your API key (format: `SG.xxxxxxxxxxxxx`)

### 4. Set Configuration

```bash
# Single command (copy-paste ready)
firebase functions:config:set \
  sendgrid.key="SG.paste_your_key_here" \
  email.from="noreply@aurasphere.app" \
  email.from_name="AuraSphere"
```

### 5. Verify Configuration

```bash
# View all config
firebase functions:config:get

# View just SendGrid
firebase functions:config:get sendgrid
firebase functions:config:get email
```

Expected output:
```json
{
  "sendgrid": {
    "key": "SG.xxxx"
  },
  "email": {
    "from": "noreply@aurasphere.app",
    "from_name": "AuraSphere"
  }
}
```

### 6. Deploy Functions

```bash
cd functions
npm run build
firebase deploy --only functions
```

### 7. Verify Deployment

```bash
# Check logs
firebase functions:log --limit 50

# Test a function
firebase functions:call sendEmailNotification \
  --data='{"to":"test@example.com","subject":"Test"}'
```

---

## Alternative: Use .env.production

If you prefer using environment files instead of Firebase CLI:

### Create `functions/.env.production`

```bash
cd functions
touch .env.production
chmod 600 .env.production
```

### Add Configuration

```dotenv
SENDGRID_API_KEY=SG.your_actual_api_key_here
EMAIL_FROM=noreply@aurasphere.app
EMAIL_FROM_NAME=AuraSphere
```

### Deploy

```bash
firebase deploy --only functions
```

---

## Troubleshooting

### Error: "Not authenticated"

```bash
# Login first
firebase login

# Then set config
firebase functions:config:set sendgrid.key="SG.xxx"
```

### Error: "No project found"

```bash
# List projects
firebase projects:list

# Select one
firebase use your-project-id
```

### Changes Not Taking Effect

```bash
# Rebuild
cd functions && npm run build

# Redeploy
firebase deploy --only functions

# Wait 30 seconds
# Check logs
firebase functions:log
```

---

## Configuration Hierarchy

When functions run, they use config in this order:

1. **Firebase CLI Config** (highest priority)
   - `firebase functions:config:set ...`
   - Used in production deployment

2. **.runtimeconfig.json** (for emulator)
   - Local development only
   - Must create manually

3. **.env files** (lowest priority)
   - Development environment variables

---

## Accessing in Cloud Functions

### In TypeScript/Node.js

```typescript
import * as functions from 'firebase-functions';

export const sendEmail = functions.https.onCall(async (data) => {
  // Access SendGrid config
  const sendgridKey = functions.config().sendgrid.key;
  const emailFrom = functions.config().email.from;
  const emailFromName = functions.config().email.from_name;
  
  // Use with SendGrid
  const sgMail = require('@sendgrid/mail');
  sgMail.setApiKey(sendgridKey);
  
  const msg = {
    to: data.to,
    from: {
      email: emailFrom,
      name: emailFromName
    },
    subject: 'Hello from AuraSphere',
    text: 'Welcome!',
  };
  
  return sgMail.send(msg);
});
```

---

## Complete Workflow

### First Time Setup (10 minutes)

```bash
# 1. Navigate to project
cd /workspaces/aura-sphere-pro

# 2. Login to Firebase
firebase login

# 3. Select project
firebase use aurasphere-prod

# 4. Set configuration (replace SG.xxx with your key)
firebase functions:config:set \
  sendgrid.key="SG.your_actual_api_key_here" \
  email.from="noreply@aurasphere.app" \
  email.from_name="AuraSphere"

# 5. Verify
firebase functions:config:get

# 6. Deploy
cd functions
npm run build
firebase deploy --only functions

# 7. Monitor
firebase functions:log --limit 50
```

### Update Configuration (5 minutes)

```bash
# Update just the key
firebase functions:config:set sendgrid.key="SG.new_key"

# Redeploy
firebase deploy --only functions

# Verify
firebase functions:log
```

---

## Security Checklist

Before running the command:

- [ ] You have your SendGrid API key (format: `SG.xxxxx`)
- [ ] API key is for the correct SendGrid account
- [ ] No other developers need different keys right now
- [ ] You're in the correct Firebase project
- [ ] You have permission to deploy functions
- [ ] Email sender is verified in SendGrid

---

## Command Variations

### Set Only API Key

```bash
firebase functions:config:set sendgrid.key="SG.xxx"
```

### Set All Email Config

```bash
firebase functions:config:set \
  sendgrid.key="SG.xxx" \
  email.from="billing@example.com" \
  email.from_name="Company Name"
```

### Add Additional Settings

```bash
firebase functions:config:set \
  sendgrid.key="SG.xxx" \
  sendgrid.sandbox_mode="false" \
  sendgrid.rate_limit="100"
```

### Unset a Configuration

```bash
firebase functions:config:unset sendgrid.key
```

---

## Common Issues & Solutions

| Issue | Solution |
|-------|----------|
| **"Invalid API key"** | Check SendGrid dashboard for correct key |
| **"Permission denied"** | Run `firebase login` and select correct project |
| **"Config not updated"** | Run `firebase deploy --only functions` after setting |
| **"Cannot read config"** | Check function uses `functions.config().sendgrid.key` |
| **"Keys aren't secret"** | Use Firebase CLI (not .env files) for production |

---

## Next Steps

1. **Get API Key** from SendGrid dashboard
2. **Run Configuration Command** (see section above)
3. **Verify Settings** with `firebase functions:config:get`
4. **Deploy Functions** with `firebase deploy --only functions`
5. **Test** with `firebase functions:call sendEmailNotification`
6. **Monitor** with `firebase functions:log`

---

**Status:** Ready to Execute  
**Time to Complete:** 10 minutes  
**Last Updated:** December 9, 2025
