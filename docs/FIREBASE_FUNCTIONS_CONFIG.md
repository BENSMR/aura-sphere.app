# Firebase Functions Environment Configuration Guide

## Current Setup Status

✅ Legacy config set via Firebase CLI:
```bash
firebase functions:config:set mail.host="smtp.gmail.com" mail.port="587" ...
```

⚠️ **Deprecation Notice**: This API will be shut down in March 2026

---

## Migration Options

### Option 1: Environment Variables (Recommended - Modern)

**1. Set up `.env.production` file:**
```bash
cp functions/.env.local functions/.env.production
# Edit with real values
```

**2. Install dotenv package in functions:**
```bash
cd functions
npm install dotenv
```

**3. Update `functions/src/index.ts`:**
```typescript
import * as dotenv from 'dotenv';
dotenv.config();

const mailConfig = {
  host: process.env.MAIL_HOST,
  port: parseInt(process.env.MAIL_PORT || '587'),
  user: process.env.MAIL_USER,
  pass: process.env.MAIL_PASS,
  from: process.env.MAIL_FROM,
};
```

**4. Deploy:**
```bash
firebase deploy --only functions
```

### Option 2: Cloud Secret Manager (Enterprise)

**Best for**: Sensitive credentials, multiple environments

```bash
# Create secrets
gcloud secrets create MAIL_PASSWORD --data-file=-
gcloud secrets create SENDGRID_API_KEY --data-file=-

# Grant Cloud Functions access
gcloud projects add-iam-policy-binding PROJECT_ID \
  --member=serviceAccount:PROJECT_ID@appspot.gserviceaccount.com \
  --role=roles/secretmanager.secretAccessor
```

**Use in functions:**
```typescript
const {SecretManagerServiceClient} = require('@google-cloud/secret-manager');

async function getSecret(secretId: string): Promise<string> {
  const client = new SecretManagerServiceClient();
  const name = client.secretVersionPath(projectId, secretId, 'latest');
  const [version] = await client.accessSecretVersion({name});
  return version.payload?.data?.toString() || '';
}
```

### Option 3: Firebase Realtime Database (Config Pattern)

Store non-sensitive config in database:
```typescript
const db = admin.database();
const config = await db.ref('config/email').once('value');
const mailConfig = config.val();
```

---

## Recommended Email Solutions

### 1. SendGrid (Recommended for Scale)
- **Pros**: Reliable, good deliverability, scales well
- **Setup**:
  ```bash
  npm install @sendgrid/mail
  ```
- **Usage**:
  ```typescript
  import sgMail from '@sendgrid/mail';
  sgMail.setApiKey(process.env.SENDGRID_API_KEY!);
  
  await sgMail.send({
    to: recipient,
    from: process.env.SENDGRID_FROM,
    subject: 'Your Subject',
    html: '<p>Email content</p>',
  });
  ```

### 2. Gmail SMTP (Free, Good for Low Volume)
- **Pros**: Free, built-in authentication
- **Setup**:
  ```bash
  npm install nodemailer
  ```
- **Usage**:
  ```typescript
  import * as nodemailer from 'nodemailer';
  
  const transporter = nodemailer.createTransport({
    host: process.env.MAIL_HOST,
    port: parseInt(process.env.MAIL_PORT!),
    secure: true,
    auth: {
      user: process.env.MAIL_USER,
      pass: process.env.MAIL_PASS,
    },
  });
  
  await transporter.sendMail({
    from: process.env.MAIL_FROM,
    to: recipient,
    subject: 'Subject',
    html: '<p>Content</p>',
  });
  ```

### 3. AWS SES (Good for High Volume)
- **Pros**: Pay-per-email, good rates at scale
- **Setup**: Use AWS SDK for Node.js

---

## Step-by-Step Migration

### Step 1: Create `.env.production`
```bash
cd functions
cp .env.local .env.production
# Edit with production values
```

### Step 2: Install dotenv
```bash
npm install dotenv
```

### Step 3: Create Email Service

**`functions/src/services/emailService.ts`:**
```typescript
import * as dotenv from 'dotenv';
import * as nodemailer from 'nodemailer';

dotenv.config();

class EmailService {
  private transporter: nodemailer.Transporter;

  constructor() {
    this.transporter = nodemailer.createTransport({
      host: process.env.MAIL_HOST,
      port: parseInt(process.env.MAIL_PORT || '587'),
      secure: process.env.MAIL_PORT === '465',
      auth: {
        user: process.env.MAIL_USER,
        pass: process.env.MAIL_PASS,
      },
    });
  }

  async sendInvoiceEmail(
    recipient: string,
    invoiceNumber: string,
    subject: string,
    htmlContent: string
  ): Promise<void> {
    try {
      await this.transporter.sendMail({
        from: process.env.MAIL_FROM,
        to: recipient,
        subject,
        html: htmlContent,
        replyTo: process.env.MAIL_FROM,
      });
      console.log(`Email sent to ${recipient}`);
    } catch (error) {
      console.error('Email sending failed:', error);
      throw error;
    }
  }

  async sendPaymentNotification(
    recipient: string,
    amount: number,
    invoiceNumber: string
  ): Promise<void> {
    const htmlContent = `
      <h2>Payment Received</h2>
      <p>We've received your payment for invoice ${invoiceNumber}</p>
      <p><strong>Amount: $${amount.toFixed(2)}</strong></p>
    `;

    await this.sendInvoiceEmail(
      recipient,
      invoiceNumber,
      'Payment Confirmation',
      htmlContent
    );
  }
}

export const emailService = new EmailService();
```

### Step 4: Create Callable Function

**`functions/src/invoicing/sendInvoice.ts`:**
```typescript
import * as functions from 'firebase-functions';
import { emailService } from '../services/emailService';

export const sendInvoice = functions.https.onCall(async (data, context) => {
  // Verify authentication
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated'
    );
  }

  const { recipientEmail, invoiceNumber, htmlContent } = data;

  try {
    await emailService.sendInvoiceEmail(
      recipientEmail,
      invoiceNumber,
      `Invoice ${invoiceNumber}`,
      htmlContent
    );

    return { success: true, message: 'Invoice sent successfully' };
  } catch (error) {
    console.error('Send invoice error:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Failed to send invoice'
    );
  }
});
```

### Step 5: Update `functions/src/index.ts`

```typescript
import * as dotenv from 'dotenv';
import { sendInvoice } from './invoicing/sendInvoice';

// Load environment variables
dotenv.config();

export { sendInvoice };
```

### Step 6: Update `.gitignore`

```bash
echo ".env.production" >> functions/.gitignore
echo ".env.local" >> functions/.gitignore
```

### Step 7: Deploy

```bash
cd functions
npm run build
firebase deploy --only functions
```

---

## Testing Locally

```bash
# Start emulator
firebase emulators:start --only functions

# In another terminal, test the function
curl -X POST http://localhost:5001/your-project/us-central1/sendInvoice \
  -H "Content-Type: application/json" \
  -d '{
    "recipientEmail": "test@example.com",
    "invoiceNumber": "INV-001",
    "htmlContent": "<p>Test invoice</p>"
  }'
```

---

## Production Deployment Checklist

- [ ] `.env.production` created with real values
- [ ] SendGrid API key or Gmail credentials set
- [ ] Email service module created
- [ ] Callable functions updated
- [ ] `.gitignore` includes `.env.production`
- [ ] Environment variables verified
- [ ] Cloud Functions deployed
- [ ] Test email sent successfully
- [ ] Error handling in place
- [ ] Rate limiting configured (if needed)

---

## Troubleshooting

### Email not sending
- Check SMTP credentials
- Verify port (587 for TLS, 465 for SSL)
- Check firewall/network access
- Review Cloud Functions logs

### Gmail issues
- Enable "Less secure app access" or use App Passwords
- For App Passwords: Go to myaccount.google.com → Security

### Rate limiting
- Implement queue system with Cloud Tasks
- Batch emails if sending many
- Add exponential backoff for retries

---

**Status**: Migration guide ready for implementation
**Timeline**: Complete before March 2026 deadline
**Priority**: High (API deprecation)
