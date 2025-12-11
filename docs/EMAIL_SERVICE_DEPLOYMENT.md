# Email Service Deployment Guide

## Overview

The email service provides three Cloud Functions for sending invoices and payment confirmations to clients:

- **`sendInvoiceEmail`** — Send individual invoices
- **`sendPaymentConfirmation`** — Send payment confirmation receipts
- **`sendBulkInvoices`** — Send multiple invoices in one batch (max 50)

All functions require user authentication and validate invoice ownership before sending.

## Prerequisites

### 1. Environment Configuration

Your Firebase Functions need email credentials. Choose one option:

#### Option A: Gmail SMTP (Recommended for Low Volume)

1. **Create a Gmail App Password:**
   - Enable 2-factor authentication on your Gmail account
   - Go to [Google Account Security](https://myaccount.google.com/security)
   - Find "App passwords" (appears only if 2FA is enabled)
   - Select "Mail" and "Windows Computer" (or your device)
   - Google generates a 16-character password
   - Copy this password

2. **Set Firebase Configuration:**
   ```bash
   cd /workspaces/aura-sphere-pro
   
   firebase functions:config:set \
     mail.host="smtp.gmail.com" \
     mail.port="587" \
     mail.user="your-email@gmail.com" \
     mail.pass="YOUR_APP_PASSWORD" \
     mail.from="noreply@yourbusiness.com"
   ```

3. **Or use `.env.production` (Modern Approach):**
   ```bash
   cp functions/.env.local functions/.env.production
   ```

   Then edit `functions/.env.production`:
   ```env
   MAIL_HOST=smtp.gmail.com
   MAIL_PORT=587
   MAIL_USER=your-email@gmail.com
   MAIL_PASS=YOUR_APP_PASSWORD
   MAIL_FROM=noreply@yourbusiness.com
   NODE_ENV=production
   ```

#### Option B: SendGrid (Recommended for High Volume)

1. **Create SendGrid Account:**
   - Sign up at [sendgrid.com](https://sendgrid.com)
   - Create an API key with "Mail Send" permissions

2. **Update `functions/.env.production`:**
   ```env
   SENDGRID_API_KEY=SG.xxxxxxxxxxxxx
   MAIL_FROM=noreply@yourbusiness.com
   NODE_ENV=production
   ```

3. **Modify `emailService.ts` to use SendGrid:**
   ```typescript
   import sgMail from '@sendgrid/mail';
   
   function createTransporter() {
     sgMail.setApiKey(process.env.SENDGRID_API_KEY!);
     return sgMail;
   }
   ```

#### Option C: AWS SES (Best for Enterprise)

1. **Set up AWS SES:**
   - Verify sender email in AWS SES
   - Create IAM credentials with SES permissions

2. **Update environment:**
   ```env
   AWS_ACCESS_KEY_ID=xxxxx
   AWS_SECRET_ACCESS_KEY=xxxxx
   AWS_REGION=us-east-1
   MAIL_FROM=noreply@yourbusiness.com
   ```

### 2. Firebase Dependencies

Verify `nodemailer` and types are installed:

```bash
cd /workspaces/aura-sphere-pro/functions

# Check if nodemailer is installed
npm list nodemailer
npm list --save-dev @types/nodemailer

# If not installed:
npm install nodemailer
npm install --save-dev @types/nodemailer
```

### 3. .env File Setup

Create `.env.production` in the functions directory:

```bash
cp functions/.env.local functions/.env.production
```

Edit with your credentials:

```env
# Email Configuration (Gmail)
MAIL_HOST=smtp.gmail.com
MAIL_PORT=587
MAIL_USER=your-email@gmail.com
MAIL_PASS=your_app_password
MAIL_FROM=noreply@yourbusiness.com

# Firebase
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_DATABASE_URL=https://your-project.firebaseio.com
NODE_ENV=production
```

## Build and Deploy

### 1. Build Functions

```bash
cd /workspaces/aura-sphere-pro/functions

# Install dependencies
npm install

# Compile TypeScript
npm run build

# Check for errors
npm run build 2>&1 | grep error
```

### 2. Deploy to Firebase

```bash
cd /workspaces/aura-sphere-pro

# Deploy only functions
firebase deploy --only functions

# Or specific functions
firebase deploy --only functions:sendInvoiceEmail,functions:sendPaymentConfirmation,functions:sendBulkInvoices

# Watch deployment logs
firebase functions:log --limit 100
```

### 3. Verify Deployment

```bash
# List deployed functions
firebase functions:list

# Check configuration
firebase functions:config:get

# View logs
firebase functions:log --limit 50
```

## Usage Examples

### Send Invoice Email

**From Flutter/Dart:**

```dart
import 'package:cloud_functions/cloud_functions.dart';

Future<void> sendInvoiceByEmail(String invoiceId) async {
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('sendInvoiceEmail')
        .call({'invoiceId': invoiceId});
    
    print('Email sent: ${result.data['message']}');
  } catch (e) {
    print('Error: $e');
  }
}
```

**Response:**
```json
{
  "success": true,
  "message": "Invoice INV-001 sent to client@example.com",
  "sentAt": "2025-12-02T10:30:00.000Z"
}
```

### Send Payment Confirmation

```dart
Future<void> confirmPayment(String invoiceId, double amount) async {
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('sendPaymentConfirmation')
        .call({
          'invoiceId': invoiceId,
          'paidAmount': amount,
          'paymentDate': DateTime.now().toIso8601String(),
        });
    
    print('Confirmation sent: ${result.data['message']}');
  } catch (e) {
    print('Error: $e');
  }
}
```

### Send Bulk Invoices

```dart
Future<void> sendBulkInvoices(List<String> invoiceIds) async {
  try {
    final result = await FirebaseFunctions.instance
        .httpsCallable('sendBulkInvoices')
        .call({'invoiceIds': invoiceIds});
    
    print('Sent: ${result.data['sent']}, Failed: ${result.data['failed']}');
    if (result.data['errors'] != null) {
      print('Errors: ${result.data['errors']}');
    }
  } catch (e) {
    print('Error: $e');
  }
}
```

## Testing

### 1. Local Testing with Emulator

```bash
cd /workspaces/aura-sphere-pro

# Start Firebase emulator (in one terminal)
firebase emulators:start

# In another terminal, run tests
firebase emulators:exec "npm run test"

# Or manually test using curl
curl -X POST http://localhost:5001/your-project/us-central1/sendInvoiceEmail \
  -H "Content-Type: application/json" \
  -d '{"data":{"invoiceId":"test-invoice-123"}}'
```

### 2. Production Testing

Create a test script:

```dart
// lib/screens/debug/email_service_test.dart
import 'package:cloud_functions/cloud_functions.dart';

class EmailServiceTest {
  static Future<void> testSendInvoice(String invoiceId) async {
    try {
      print('Calling sendInvoiceEmail with ID: $invoiceId');
      
      final result = await FirebaseFunctions.instance
          .httpsCallable('sendInvoiceEmail')
          .call({'invoiceId': invoiceId});
      
      print('Success: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      print('Firebase Error: ${e.code} - ${e.message}');
    } catch (e) {
      print('General Error: $e');
    }
  }
}
```

### 3. Check Function Logs

```bash
# View real-time logs
firebase functions:log

# View logs from last hour
firebase functions:log --limit 100

# View specific function logs
firebase functions:log --only sendInvoiceEmail
```

## Troubleshooting

### Issue: "Functions config not found"

**Solution:** Ensure environment variables are set:
```bash
firebase functions:config:get

# If empty, set them:
firebase functions:config:set \
  mail.host="smtp.gmail.com" \
  mail.port="587" \
  mail.user="your-email@gmail.com" \
  mail.pass="your-app-password" \
  mail.from="noreply@yourbusiness.com"
```

### Issue: "Email configuration missing: MAIL_USER or MAIL_PASS not set"

**Solution:** Check `.env.production` exists and is loaded:
```bash
# Verify file exists
ls -la functions/.env.production

# Verify contains credentials
grep MAIL_USER functions/.env.production

# Check Firebase config is also set
firebase functions:config:get
```

### Issue: "SMTP authentication failed"

**Solution:** Verify credentials:
- Gmail: Ensure you're using an [App Password](https://support.google.com/accounts/answer/185833), not your regular password
- SendGrid: Verify API key is valid and has "Mail Send" permission
- Check for spaces in credentials

### Issue: "Permission denied for invoice"

**Solution:** Verify invoice ownership:
```firestore
// In Firestore, ensure invoice has correct userId
/invoices/{invoiceId}
{
  userId: "authenticated-user-id",  // Must match request.auth.uid
  ...
}
```

### Issue: "Email bounced or not received"

**Solution:**
1. Check sender email is verified (or matches business email)
2. Verify recipient email is valid
3. Check spam folder
4. View function logs: `firebase functions:log`
5. Test with your own email first

### Issue: Build fails with "Cannot find module 'nodemailer'"

**Solution:**
```bash
cd /workspaces/aura-sphere-pro/functions

# Install dependencies
npm install

# Rebuild
npm run build
```

## Performance & Limits

### Rate Limits
- **Individual sends:** No limit per user
- **Bulk sends:** Max 50 invoices per request
- **Concurrent:** Firebase handles up to 1000 concurrent executions

### Email Limits by Provider
- **Gmail:** 300 emails/day (free account)
- **SendGrid:** Based on plan (up to unlimited)
- **AWS SES:** 50,000 emails/day in sandbox

### Timeouts
- Function execution: 540 seconds (9 minutes)
- Email send: Typically < 5 seconds
- Batch operations: Scale with invoice count

## Security Considerations

✅ **Implemented:**
- User authentication required (HTTP 401 if not authenticated)
- Invoice ownership validation (HTTP 403 if not owner)
- Input validation (HTTP 400 for invalid data)
- Error logging without sensitive data exposure
- Firestore security rules enforcement

✅ **Best Practices:**
- Never log email addresses in production logs
- Use separate SMTP credentials from main account
- Rotate credentials regularly (especially API keys)
- Monitor functions quota and logs for abuse
- Use Cloud Audit Logs to track sensitive operations

## Next Steps

1. **Set up environment variables** (choose Gmail, SendGrid, or AWS SES)
2. **Build and deploy functions** (`firebase deploy --only functions`)
3. **Test with sample invoice** (use Email Service Test screen)
4. **Monitor function logs** (`firebase functions:log`)
5. **Integrate with Flutter app** (add "Send Email" button to invoice screens)

## Documentation References

- [Firebase Cloud Functions](https://firebase.google.com/docs/functions)
- [Nodemailer Documentation](https://nodemailer.com/)
- [SendGrid API](https://docs.sendgrid.com/for-developers/sending-email/api-overview)
- [Gmail SMTP Setup](https://support.google.com/mail/answer/7126229)
- [AWS SES Setup](https://docs.aws.amazon.com/ses/latest/dg/send-email.html)

