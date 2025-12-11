# sendEmailAlert Cloud Function - Testing Guide

**Last Updated:** December 11, 2025  
**Status:** ✅ Function deployed and ready for testing

---

## Quick Start

### Via curl (simplest)
```bash
curl -X POST http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "to": "test@example.com",
      "subject": "Test Email",
      "html": "<h1>Hello</h1><p>This is a test.</p>"
    }
  }'
```

### Via Node.js (with emulator)
```bash
# Start emulators first
firebase emulators:start --only firestore,functions

# In another terminal
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node functions/test_sendEmailAlert_callable.js
```

### Via Flutter
```dart
final result = await FirebaseFunctions.instance
    .httpsCallable('sendEmailAlert')
    .call({
  'to': 'test@example.com',
  'subject': 'Test',
  'html': '<b>Hello</b>'
});
```

---

## Testing Methods

### Method 1: cURL (Emulator)
**Best for:** Quick testing, CI/CD pipelines

```bash
# Basic test
curl -X POST http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "to": "test@example.com",
      "subject": "Test Email",
      "html": "<h1>Test</h1>"
    }
  }'

# With all parameters
curl -X POST http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "to": "user@example.com",
      "cc": "manager@example.com",
      "bcc": "archive@example.com",
      "subject": "Invoice Alert",
      "html": "<h1>Invoice Due</h1><p>INV-001 is due today.</p>",
      "userId": "user-123",
      "type": "invoice",
      "severity": "high"
    }
  }'
```

### Method 2: Node.js Test Script

**File:** `functions/test_sendEmailAlert_callable.js`

**Setup:**
```bash
cd functions
npm install  # Ensure dependencies installed
```

**Run with emulator:**
```bash
# Terminal 1: Start emulators
firebase emulators:start --only firestore,functions

# Terminal 2: Run tests
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080 node test_sendEmailAlert_callable.js
```

**Run against production:**
```bash
# Requires valid Firebase credentials
node test_sendEmailAlert_callable.js
```

**What it tests:**
- HTTP POST to callable function
- Admin SDK callable invocation
- Multiple recipient configurations
- Different email providers (SendGrid, SMTP)
- Error handling

### Method 3: Flutter Integration

**File:** `lib/services/email_alert_test.dart`

**Usage in your app:**
```dart
// Simple test
await EmailAlertTest.testSendEmailAlert(
  to: 'test@example.com',
  subject: 'Hello',
  html: '<b>Test email</b>',
);

// Run multiple test cases
await EmailAlertTest.testVariousEmails();
```

**Or add to your app UI:**
```dart
ElevatedButton(
  onPressed: () => EmailAlertTest.testSendEmailAlert(
    to: 'admin@example.com',
    subject: 'Test',
    html: '<h1>Test</h1>',
  ),
  child: Text('Send Test Email'),
),
```

### Method 4: Firebase Console

**Steps:**
1. Go to Firebase Console → Project → Functions
2. Click `sendEmailAlert`
3. Go to "Testing" tab
4. Enter test data:
   ```json
   {
     "to": "test@example.com",
     "subject": "Test",
     "html": "<h1>Test</h1>"
   }
   ```
5. Click "Test the function"

### Method 5: Postman

**Setup:**
1. Open Postman
2. Create new POST request
3. URL: `http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert`
4. Headers:
   ```
   Content-Type: application/json
   ```
5. Body (raw JSON):
   ```json
   {
     "data": {
       "to": "test@example.com",
       "subject": "Postman Test",
       "html": "<h1>Hello from Postman</h1>"
     }
   }
   ```
6. Click "Send"

---

## Expected Responses

### Success Response
```json
{
  "success": true,
  "message": "Email sent successfully",
  "messageId": "0000018c87a8c2f9-abcd1234",
  "provider": "sendgrid",
  "timestamp": "2025-12-11T12:34:56.789Z"
}
```

### Error Response (No Configuration)
```json
{
  "success": false,
  "message": "Email provider not configured",
  "error": "Neither SendGrid nor SMTP configuration found"
}
```

### Error Response (Invalid Email)
```json
{
  "success": false,
  "message": "Invalid email address",
  "error": "Email validation failed"
}
```

---

## Testing Checklist

### Before Testing
- [ ] Firebase emulators running (if testing locally)
- [ ] SendGrid API key configured (if testing SendGrid)
- [ ] SMTP credentials configured (if testing SMTP)
- [ ] Email address is valid
- [ ] HTML is properly formatted

### Local Testing (Emulator)
- [ ] Emulators started: `firebase emulators:start`
- [ ] HTTP request sent to `http://127.0.0.1:5001/...`
- [ ] Response received (success or error)
- [ ] Check Firestore emulator console for data
- [ ] Check Functions logs: `firebase functions:log`

### Staging Testing
- [ ] Deploy to staging Firebase project
- [ ] Configure email provider in staging
- [ ] Send test email
- [ ] Verify email received in test inbox
- [ ] Check delivery status in provider console

### Production Testing
- [ ] Deploy to production Firebase project
- [ ] Configure email provider in production
- [ ] Send test email to internal address
- [ ] Verify email received
- [ ] Check production logs: `firebase functions:log --region us-central1`

---

## Configuration for Testing

### SendGrid Setup
```bash
# Set API key
firebase functions:config:set sendgrid.key="sg_your_api_key_here"

# Verify configuration
firebase functions:config:get sendgrid
```

### SMTP Setup
```bash
# Gmail example
firebase functions:config:set \
  smtp.host="smtp.gmail.com" \
  smtp.port="587" \
  smtp.user="your-email@gmail.com" \
  smtp.pass="your-app-password"

# Office 365 example
firebase functions:config:set \
  smtp.host="smtp.office365.com" \
  smtp.port="587" \
  smtp.user="your-email@company.com" \
  smtp.pass="your-password"
```

### Verify Configuration
```bash
firebase functions:config:get
```

---

## Troubleshooting

### Email not sending
**Symptom:** Function returns success but no email received

**Solutions:**
1. Check email address is correct (check spam folder)
2. Verify API key or credentials are valid
3. Check function logs: `firebase functions:log`
4. Test with different email address
5. Check provider's email delivery dashboard

### Authentication Error
**Symptom:** "Missing credentials" or "Invalid API key"

**Solutions:**
1. Verify API key is set: `firebase functions:config:get`
2. Check key format (should start with `sg_` for SendGrid)
3. Regenerate key in provider console
4. Redeploy functions after updating config

### Function Timeout
**Symptom:** Request times out or returns 504 error

**Solutions:**
1. Check network connectivity
2. Verify provider service is up
3. Increase timeout in function config
4. Check function logs for errors

### Invalid HTML
**Symptom:** Email received but formatting is wrong

**Solutions:**
1. Validate HTML syntax (use online validator)
2. Use plain HTML without script tags
3. Include `<style>` tags for CSS
4. Test with simple HTML first

### CORS Error
**Symptom:** Browser blocks request with CORS error

**Solutions:**
1. Don't call from browser directly (use Flutter/backend)
2. Enable CORS if needed: Configure in firebaserc
3. Use authorized domain (configure in Firebase)

---

## Test Scenarios

### Scenario 1: Anomaly Alert
```bash
curl -X POST http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "to": "admin@company.com",
      "subject": "⚠️ High Severity Anomaly Detected",
      "html": "<h2 style=\"color:red;\">Anomaly Alert</h2><p>Invoice INV-001 shows unusual activity.</p><p><a href=\"https://app.com/invoices/1\">View Invoice</a></p>",
      "userId": "user-001",
      "type": "anomaly",
      "severity": "high"
    }
  }'
```

### Scenario 2: Invoice Overdue
```bash
curl -X POST http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "to": "accounting@company.com",
      "cc": "manager@company.com",
      "subject": "📋 Invoice Payment Due: INV-002",
      "html": "<h2>Invoice Overdue</h2><p>Invoice INV-002 is now 5 days overdue.</p><p><strong>Amount:</strong> $1,000.00</p><p><a href=\"https://app.com/invoices/2\">Pay Now</a></p>",
      "userId": "user-002",
      "type": "invoice",
      "severity": "medium"
    }
  }'
```

### Scenario 3: System Notification
```bash
curl -X POST http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "to": "team@company.com",
      "subject": "✅ System Update Completed",
      "html": "<h2>Notification System Updated</h2><p>The notification system has been successfully updated with new features.</p>",
      "userId": "system",
      "type": "system",
      "severity": "low"
    }
  }'
```

---

## Performance Testing

### Load Test (Send 10 emails)
```bash
for i in {1..10}; do
  curl -X POST http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert \
    -H "Content-Type: application/json" \
    -d "{\"data\": {\"to\": \"test-$i@example.com\", \"subject\": \"Test $i\", \"html\": \"<p>Test $i</p>\"}}" &
done
wait
```

### Stress Test (Concurrent requests)
```bash
ab -n 100 -c 10 -p payload.json -T application/json \
  http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert
```

---

## Monitoring

### View Logs
```bash
# Last 50 logs
firebase functions:log --limit 50

# Filter by function
firebase functions:log --limit 50 | grep sendEmailAlert

# Real-time logs
firebase functions:log --follow
```

### Check Metrics
1. Go to Firebase Console
2. Select Project → Functions
3. Click `sendEmailAlert`
4. View:
   - Execution count
   - Success/failure rate
   - Error rate
   - Performance metrics

---

## Next Steps

1. **Local Testing:**
   - [ ] Start emulators
   - [ ] Run `test_sendEmailAlert_callable.js`
   - [ ] Verify response

2. **Configuration:**
   - [ ] Set up SendGrid or SMTP
   - [ ] Deploy configuration to Firebase

3. **Staging:**
   - [ ] Deploy to staging
   - [ ] Send test emails
   - [ ] Verify delivery

4. **Production:**
   - [ ] Configure in production
   - [ ] Deploy function
   - [ ] Monitor logs
   - [ ] Verify emails sent

---

**Status:** ✅ Ready for testing  
**Contact:** Check SYSTEM_VERIFICATION_REPORT.md for support
