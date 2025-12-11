# Firebase Emulators - Local Testing Guide

**Status:** ✅ Emulators Running

The Firebase emulators are now running locally for development and testing.

---

## Emulator Access

### Emulator UI Dashboard
- **URL:** http://127.0.0.1:4000
- **View all emulator data and logs**
- **Real-time updates**

### Firestore Emulator
- **Host:Port:** 127.0.0.1:8080
- **URL:** http://127.0.0.1:4000/firestore
- **Features:**
  - Browse collections and documents
  - View real-time changes
  - Export/import data

### Cloud Functions Emulator
- **Host:Port:** 127.0.0.1:5001
- **URL:** http://127.0.0.1:4000/functions
- **Features:**
  - View deployed functions
  - Call functions directly
  - Monitor logs in real-time
  - Trigger Firestore functions manually

### Emulator Hub
- **Host:Port:** 127.0.0.1:4400
- **Internal communication between emulators**

---

## Configure Your App to Use Emulators

### Dart (Flutter)

Add to your `main.dart` before initializing Firebase:

```dart
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Connect to emulators (only in development)
  if (kDebugMode) {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    
    // Connect to Firestore emulator
    FirebaseFirestore.instance.settings = const Settings(
      host: '127.0.0.1:8080',
      sslEnabled: false,
      persistenceEnabled: false,
    );
  } else {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  }
  
  // Rest of initialization...
}
```

### TypeScript/Node.js

For local testing scripts:

```typescript
import * as admin from 'firebase-admin';

// Connect to emulators
process.env.FIRESTORE_EMULATOR_HOST = '127.0.0.1:8080';
process.env.FIREBASE_EMULATOR_HUB = '127.0.0.1:4400';

admin.initializeApp({
  projectId: 'aurasphere-pro',
});

const db = admin.firestore();
// Now all operations use the emulator
```

---

## Testing Notification System Locally

### 1. Test Email Alert Function

```bash
# Call the sendEmailAlert function
curl -X POST http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "to": "test@example.com",
      "subject": "Test Email",
      "html": "<h1>Test Email</h1><p>This is a test from emulator</p>"
    }
  }'
```

### 2. Test SMS Alert Function

```bash
curl -X POST http://127.0.0.1:5001/aurasphere-pro/us-central1/sendSmsAlert \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "to": "+12025551234",
      "body": "Test SMS from local emulator"
    }
  }'
```

### 3. Trigger Firestore Event (Test onAnomalyCreate)

```bash
# Write to Firestore emulator
curl -X POST http://127.0.0.1:8080/v1/projects/aurasphere-pro/databases/\(default\)/documents/anomalies \
  -H "Content-Type: application/json" \
  -d '{
    "fields": {
      "severity": {"stringValue": "high"},
      "entityType": {"stringValue": "invoice"},
      "entityId": {"stringValue": "INV-001"},
      "ownerUid": {"stringValue": "user123"}
    }
  }'
```

### 4. Monitor Firestore Emulator

Open the Emulator UI and navigate to:
- **Firestore tab** → Select collection
- Watch documents appear/update in real-time
- Check `notifications_audit` collection for logged events

### 5. View Function Logs

The logs will appear in the terminal or in the Emulator UI:
- **Functions tab** → Select function
- View execution logs, errors, and output
- Real-time updates as functions run

---

## Common Testing Scenarios

### Scenario 1: Test Anomaly Detection

**Step 1:** Create anomaly document
```bash
# In Firestore emulator UI or via curl
# Collection: anomalies
# Doc: {
#   severity: "high"
#   entityType: "invoice"
#   entityId: "INV-001"
#   ownerUid: "test-user-123"
# }
```

**Step 2:** Verify trigger fired
- Check `users/test-user-123/notifications` collection
- Should have new notification document
- Check `notifications_audit` for logged event

**Step 3:** Verify email/push sent
- Check function logs for `sendEmailAlert` or `pushAnomalyAlert`
- Should show success or error

### Scenario 2: Test Invoice Overdue

**Step 1:** Create invoice document
```bash
# Collection: users/{uid}/invoices
# Doc: {
#   status: "unpaid"
#   dueDate: "2025-01-01" (past date)
#   amount: 1000
#   currency: "USD"
# }
```

**Step 2:** Update status to overdue
```bash
# Patch document to status: "overdue"
```

**Step 3:** Verify notification created
- Check `users/{uid}/notifications` collection
- Check `notifications_audit` for event log

### Scenario 3: Test Device Registration

**Step 1:** Call registerDevice
```bash
curl -X POST http://127.0.0.1:5001/aurasphere-pro/us-central1/registerDevice \
  -H "Content-Type: application/json" \
  -d '{
    "data": {
      "uid": "test-user-123",
      "token": "dummyFCMToken123",
      "platform": "android"
    }
  }'
```

**Step 2:** Verify device stored
- Check `users/test-user-123/devices` collection
- Should see device document with token

---

## Firestore Emulator Commands

### Export Data

```bash
# Save emulator data to file
firebase emulators:export ./firestore-export
```

### Import Data

```bash
# Load data from previous export
firebase emulators:start --import=./firestore-export
```

### Clear All Data

```bash
# Stop emulators and restart
# All data is cleared automatically
```

---

## Debugging Tips

### Check Function Execution
1. Open http://127.0.0.1:4000/functions
2. Select function from list
3. Click "Call" or wait for trigger
4. View logs in real-time

### Inspect Firestore Data
1. Open http://127.0.0.1:4000/firestore
2. Browse collections on left sidebar
3. Click document to view full data
4. Changes appear live as they happen

### View Raw Logs
```bash
# Terminal shows real-time logs from all emulators
tail -f functions/logs
```

### Check Emulator Config
```bash
# View emulator configuration
cat firebase.json
```

---

## Environment Variables

### Local Emulator Variables

These are automatically set when emulators run:

```
FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
FIREBASE_EMULATOR_HUB=127.0.0.1:4400
FIREBASE_FUNCTIONS_EMULATOR=true
```

### Connect to Specific Emulator

For testing outside emulator UI:

```bash
export FIRESTORE_EMULATOR_HOST=127.0.0.1:8080
export FIREBASE_AUTH_EMULATOR_HOST=127.0.0.1:9099
```

---

## Stopping Emulators

### Stop Gracefully

```bash
# Press Ctrl+C in the terminal running emulators
# or send signal:
firebase emulators:stop
```

### Kill All Emulator Processes

```bash
pkill -f "firebase emulators"
```

---

## Troubleshooting

### Functions Not Loading

**Error:** "Failed to load function definition from source"

**Solution:**
1. Check `.env.local` exists or create it
2. Verify functions/src/index.ts has exports
3. Check TypeScript compilation: `npm run build`
4. Restart emulators

### Firestore Connection Issues

**Error:** "Cannot connect to Firestore"

**Solution:**
1. Check port 8080 is not in use: `lsof -i :8080`
2. Clear Firebase cache: `rm -rf ~/.cache/firebase`
3. Restart emulators

### Functions Not Triggering

**Issue:** Firestore triggers not firing

**Solution:**
1. Verify collection path matches trigger (e.g., `anomalies/{id}`)
2. Check security rules allow write
3. View function logs for errors
4. Restart emulator

### Port Already in Use

**Error:** "Address already in use"

**Solution:**
```bash
# Find process using port
lsof -i :5001  # Functions
lsof -i :8080  # Firestore
lsof -i :4000  # UI

# Kill the process
kill -9 <PID>
```

---

## Next Steps

1. **Update your app** to use emulator endpoints (see "Configure Your App" above)
2. **Run Flutter app** with emulator connected
3. **Test end-to-end:**
   - Register device via app
   - Create test anomaly
   - Verify notification appears in app
4. **Test callables:**
   - Call sendEmailAlert
   - Call sendSmsAlert
   - View logs in Emulator UI
5. **Monitor real-time:**
   - Watch Firestore collections update
   - Check notification audit logs
   - Verify device preferences

---

## Performance Testing

### Stress Test Notifications

```bash
# Create 100 notifications rapidly
for i in {1..100}; do
  curl -X POST http://127.0.0.1:5001/aurasphere-pro/us-central1/sendEmailAlert \
    -H "Content-Type: application/json" \
    -d "{\"data\": {\"to\": \"test$i@example.com\", \"subject\": \"Test $i\", \"html\": \"<p>Test $i</p>\"}}" &
done
wait
```

### Monitor Performance

- Check Emulator UI for function execution times
- View Firestore query performance
- Monitor memory usage in terminal

---

**Happy testing! 🧪**

All emulators are ready for local development and testing.
