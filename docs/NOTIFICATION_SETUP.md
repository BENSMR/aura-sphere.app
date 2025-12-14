# Notification System Configuration Guide

This guide covers setup and configuration for the AuraSphere Pro notification system, including email (SendGrid/SMTP) and SMS (Twilio) delivery.

## Prerequisites

- Firebase project with Cloud Functions enabled
- `firebase-cli` installed and authenticated (`firebase login`)
- Credentials for your email and SMS providers

---

## Email Configuration

### Option 1: SendGrid (Recommended)

SendGrid is the preferred option for reliable, scalable email delivery.

**1. Get SendGrid API Key**
- Create/log in to [SendGrid account](https://sendgrid.com)
- Go to **Settings > API Keys**
- Create new Full Access API Key
- Copy the key (starts with `SG.`)

**2. Set Firebase Config**
```bash
firebase functions:config:set \
  sendgrid.key="SG.xxxxxxxxxxxxxx" \
  email.from="noreply@yourdomain.com"
```

**3. Verify Config**
```bash
firebase functions:config:get
```

Expected output:
```json
{
  "sendgrid": {
    "key": "SG.xxxxxxxxxxxxxx"
  },
  "email": {
    "from": "noreply@yourdomain.com"
  }
}
```

---

### Option 2: SMTP (Gmail, Office 365, Custom)

For Gmail or custom SMTP servers.

**1. Get SMTP Credentials**

**Gmail:**
- Enable 2-factor authentication
- Go to [myaccount.google.com/apppasswords](https://myaccount.google.com/apppasswords)
- Generate App Password for Gmail
- Copy the 16-character password

**Custom SMTP (e.g., Office 365, SendMail):**
- Obtain SMTP host, port, username, password from your provider

**2. Set Firebase Config**
```bash
firebase functions:config:set \
  smtp.host="smtp.gmail.com" \
  smtp.port="587" \
  smtp.user="your.email@gmail.com" \
  smtp.pass="xxxx xxxx xxxx xxxx" \
  email.from="noreply@yourdomain.com"
```

**Common SMTP Servers:**
| Provider | Host | Port | Security |
|----------|------|------|----------|
| Gmail | smtp.gmail.com | 587 | TLS |
| Office 365 | smtp.office365.com | 587 | TLS |
| SendMail | mail.yourdomain.com | 587 | TLS |
| Mailgun | smtp.mailgun.org | 587 | TLS |

**3. Verify Config**
```bash
firebase functions:config:get
```

---

## SMS Configuration

### Twilio Setup

**1. Get Twilio Credentials**
- Create/log in to [Twilio account](https://www.twilio.com)
- Go to **Console > Account Info**
- Copy **Account SID** and **Auth Token**
- Go to **Phone Numbers** and copy your Twilio phone number (format: `+1234567890`)

**2. Set Firebase Config**
```bash
firebase functions:config:set \
  twilio.sid="ACxxxxxxxxxxxx" \
  twilio.token="your_auth_token" \
  twilio.from="+12345678900"
```

**3. Verify Config**
```bash
firebase functions:config:get
```

Expected output:
```json
{
  "twilio": {
    "sid": "ACxxxxxxxxxxxx",
    "token": "your_auth_token",
    "from": "+12345678900"
  }
}
```

---

## Complete Setup Example

```bash
# 1. Configure SendGrid email
firebase functions:config:set \
  sendgrid.key="SG.xxxxxxxxxxxxxx" \
  email.from="noreply@aurasphere.app"

# 2. Configure Twilio SMS
firebase functions:config:set \
  twilio.sid="ACxxxxxxxxxxxx" \
  twilio.token="your_auth_token" \
  twilio.from="+12025551234"

# 3. Verify all settings
firebase functions:config:get

# 4. Deploy functions
firebase deploy --only functions
```

---

## Usage in Cloud Functions

### Sending Email

```typescript
import { sendEmailAlert } from './notifications/sendEmailAlert';
import { renderAlertEmail } from './notifications/emailTemplates';

// Render HTML
const html = renderAlertEmail({
  subject: 'Invoice Overdue',
  subtitle: 'Payment Due',
  body: 'Invoice #INV-001 is 5 days overdue. Please pay now.',
  severity: 'high',
  action_url: 'https://app.aura-sphere.app/invoices/INV-001'
});

// Call the function from Cloud Function
const result = await sendEmailAlert.run({
  to: 'user@example.com',
  subject: 'Invoice Overdue',
  html
}, context);
```

### Sending SMS

```typescript
import { sendSmsAlert } from './notifications/sendSmsAlert';

const result = await sendSmsAlert.run({
  to: '+12025551234',
  body: 'Invoice #INV-001 is overdue. Pay now: https://aura.app/inv/001'
}, context);
```

---

## Environment Variables Reference

### SendGrid
- `sendgrid.key` — API key starting with `SG.`
- `email.from` — Sender email address (must be verified in SendGrid)

### SMTP
- `smtp.host` — SMTP server hostname
- `smtp.port` — Port number (usually 587 for TLS)
- `smtp.user` — SMTP username/email
- `smtp.pass` — SMTP password or app-specific password
- `email.from` — Sender email address

### Twilio
- `twilio.sid` — Account SID starting with `AC`
- `twilio.token` — Auth token (keep secret!)
- `twilio.from` — Twilio phone number in E.164 format (+1234567890)

---

## Security Best Practices

✅ **DO:**
- Store credentials in Firebase config (not in code)
- Use environment-specific keys
- Rotate API keys periodically
- Use app-specific passwords (Gmail, Office 365)
- Restrict SendGrid IP whitelist if possible
- Keep Auth tokens secret (never commit to git)

❌ **DON'T:**
- Hardcode API keys in source code
- Commit `.env` files
- Share credentials in repos or Slack
- Use personal API keys for production

---

## Testing Configuration

### Test Email Delivery

```bash
# Using Firebase emulator
firebase emulators:start

# Call sendEmailAlert from CLI or UI
firebase functions:call sendEmailAlert \
  --data '{"to":"test@example.com","subject":"Test","html":"<p>Test</p>"}'
```

### Test SMS Delivery

```bash
firebase functions:call sendSmsAlert \
  --data '{"to":"+12025551234","body":"Test message"}'
```

---

## Troubleshooting

### Email Not Sending

**SendGrid:**
- Verify API key is correct: `firebase functions:config:get`
- Check SendGrid dashboard for failed sends
- Ensure sender email is verified in SendGrid
- Check function logs: `firebase functions:log`

**SMTP:**
- Verify SMTP credentials are correct
- Test with telnet: `telnet smtp.gmail.com 587`
- For Gmail: enable Less Secure Apps or use App Password
- Check firewall allows outbound port 587

### SMS Not Sending

- Verify Twilio account has credits
- Check phone number format (E.164: +1234567890)
- Verify SID and token are correct
- Check Twilio dashboard for failed messages
- Ensure recipient number is valid for country

### Config Not Applied

```bash
# Re-deploy functions after config changes
firebase functions:config:get
firebase deploy --only functions

# Clear local cache if needed
rm ~/.config/configstore/firebase-tools.json
firebase login
```

---

## Production Checklist

- [ ] SendGrid or SMTP configured
- [ ] Email sender domain verified
- [ ] Twilio account set up (if using SMS)
- [ ] All credentials in Firebase config (not in code)
- [ ] Functions deployed: `firebase deploy --only functions`
- [ ] Email/SMS tested end-to-end
- [ ] Security rules deployed
- [ ] Notification audit logging enabled
- [ ] Error handling and monitoring in place
