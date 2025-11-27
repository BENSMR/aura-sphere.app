# Firebase Email Extension - Task Email Delivery

## Overview

Uses Google's **Firebase Extensions - Email by Resend** (or compatible email extension) to send task reminder emails. Much simpler than SendGrid with zero external API key configuration.

**Key Differences from SendGrid:**
- ✅ No external API key needed (uses Firebase Extensions)
- ✅ Built-in Firebase integration
- ✅ Simpler setup and deployment
- ✅ Auto-scaling with Firebase
- ⚠️ Slightly less control over sender domain (depends on extension)

---

## How It Works

### 1. Cloud Function Queues Email
```
sendTaskEmail() → Writes to /mail collection → Firebase Extension picks up → Email sent
```

### 2. Email Flow

```
User clicks "Send Email" on Task
         ↓
sendTaskEmail() validates:
  - User auth ✓
  - Task exists ✓
  - Recipient email ✓
         ↓
Writes document to /mail collection:
  {
    to: "john@example.com",
    message: {
      subject: "Follow-up: Q4 Proposal",
      text: "Contact about pricing...",
      html: "<div>HTML email...</div>"
    },
    userId: "user_123",
    taskId: "task_abc",
    createdBy: "user_123",
    createdAt: Timestamp(...)
  }
         ↓
Firebase Email Extension:
  - Polls /mail collection
  - Sends email via Resend API (or configured provider)
  - Updates document with delivery status
         ↓
Cloud Function updates task status:
  - status: "sent"
  - sentAt: Timestamp(...)
  - emailQueueId: "mail_doc_id"
         ↓
Audit trail created in users/{uid}/task_audit
```

---

## Prerequisites

### Step 1: Install Firebase Email Extension

#### Option A: Email by Resend (Recommended)
1. Go to **Firebase Console** → **Extensions**
2. Search for **"Email by Resend"**
3. Click **Install**
4. Follow the setup wizard:
   - Create Resend account: https://resend.com (free tier available)
   - Get API key: https://resend.com/api-keys
   - Enter API key in extension setup
5. Grant required permissions
6. Extension will create `/mail` collection automatically

#### Option B: Alternative Providers
Firebase Email Extensions also available for:
- **SendGrid** (if you prefer)
- **Mailgun**
- **SMTP** (custom email server)

### Step 2: Verify Installation

After installation:
```bash
# Check if /mail collection exists
firebase firestore:list --collection-size | grep mail

# Should show:
# ___ mail (documents: 0)
```

### Step 3: Test Extension Locally (Optional)

```bash
# Start emulators
firebase emulators:start

# In another terminal, write test email to /mail
firebase firestore:set-doc \
  --project=$PROJECT_ID \
  --database='(default)' \
  'mail/test-email' \
  '{
    "to": "test@example.com",
    "message": {
      "subject": "Test",
      "text": "Hello from Firebase Email"
    }
  }'
```

---

## Function Usage

### Cloud Function Signature

```typescript
export const sendTaskEmail = functions.https.onCall(
  async (data, context) => { ... }
)
```

### Required Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `userId` | string | User who owns the task |
| `taskId` | string | Task document ID to send |

### Optional Parameters

| Parameter | Type | Description |
|-----------|------|-------------|
| `overrideEmail` | string | Custom recipient email (overrides auto-detection) |
| `overrideSubject` | string | Custom email subject (default: task.title) |
| `overrideBody` | string | Custom HTML body (default: task.template or task.description) |

### Usage Example 1: Simple Send

```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('sendTaskEmail')
  .call({
    'userId': currentUser.uid,
    'taskId': 'task_abc123'
  });

// Response:
// {
//   "success": true,
//   "message": "Email queued for delivery",
//   "emailQueueId": "mail_xyz789"
// }
```

### Usage Example 2: Custom Email

```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('sendTaskEmail')
  .call({
    'userId': currentUser.uid,
    'taskId': 'task_abc123',
    'overrideEmail': 'custom@client.com',
    'overrideSubject': 'Urgent: Q4 Proposal Follow-up',
    'overrideBody': '''
      <h2>Hello,</h2>
      <p>We need your feedback on the Q4 pricing proposal.</p>
      <p>Please reply by Nov 30.</p>
      <p>Thanks!</p>
    '''
  });
```

### Usage Example 3: From Task Detail Screen

```dart
// In task_detail_screen.dart
ElevatedButton(
  onPressed: () async {
    try {
      final result = await FirebaseFunctions.instance
        .httpsCallable('sendTaskEmail')
        .call({
          'userId': Provider.of<AuthProvider>(context, listen: false).user!.uid,
          'taskId': widget.task.id,
        });
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result.data['message']))
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red)
      );
    }
  },
  child: Text('📧 Send Email'),
)
```

---

## Firestore Collections Updated

### Task Document Changes

**Before:**
```firestore
users/{uid}/tasks/{taskId}
{
  "status": "pending",
  "title": "Email John about Q4...",
  "description": "Contact about pricing",
  ...
}
```

**After Email Sent:**
```firestore
users/{uid}/tasks/{taskId}
{
  "status": "sent",
  "title": "Email John about Q4...",
  "description": "Contact about pricing",
  "sentAt": Timestamp(2025-11-27T10:30:00Z),
  "lastSentBy": "user_123",
  "emailQueueId": "mail_xyz789",  # Links to /mail collection
  ...
}
```

### Email Queue Collection

```firestore
mail/{mailId}
{
  "to": "john@example.com",
  "message": {
    "subject": "Email John about Q4 proposal",
    "text": "Contact about pricing",
    "html": "<div style=...>Contact about pricing</div>"
  },
  "userId": "user_123",
  "taskId": "task_abc123",
  "createdBy": "user_123",
  "createdAt": Timestamp(2025-11-27T10:30:00Z),
  "delivery": {
    "startTime": Timestamp(...),
    "endTime": Timestamp(...),
    "state": "SUCCESS",  # or PENDING, ERROR
    "error": null
  }
}
```

### Audit Trail

```firestore
users/{uid}/task_audit/{auditId}
{
  "action": "email_sent",
  "taskId": "task_abc123",
  "to": "john@example.com",
  "subject": "Email John about Q4 proposal",
  "mailId": "mail_xyz789",
  "createdAt": Timestamp(2025-11-27T10:30:00Z),
  "sentBy": "user_123",
  "userId": "user_123"
}
```

---

## Monitoring & Logging

### View Email Queue Status

1. **Firebase Console** → **Firestore** → **Collections** → **mail**
   - Shows all queued and sent emails
   - Each document has a `delivery` field with status

2. **Check Delivery Status**
   ```bash
   # View pending emails
   firebase firestore:query \
     'mail' \
     --where='delivery.state==PENDING'
   
   # View failed emails
   firebase firestore:query \
     'mail' \
     --where='delivery.state==ERROR'
   ```

### View Cloud Function Logs

```bash
# Real-time function logs
firebase functions:log --follow

# Filter for email sends
firebase functions:log | grep -E "Email queued|Failed to queue"

# Filter for errors
firebase functions:log | grep ERROR
```

### Example Log Output

**Successful Send:**
```
Nov 27, 10:30:00 AM  info    sendTaskEmail called
  userId: user_123, taskId: task_abc, callerUid: user_123

Nov 27, 10:30:01 AM  info    Email queued for delivery
  userId: user_123, taskId: task_abc, to: john@example.com, 
  subject: "Email John...", mailId: mail_xyz789
```

**Failed Send:**
```
Nov 27, 10:30:02 AM  error   No recipient email found
  userId: user_123, taskId: task_abc, contactId: contact_123

Nov 27, 10:30:02 AM  error   Task not found
  userId: user_123, taskId: invalid_id
```

---

## Error Handling

### Common Errors

| Error | Cause | Solution |
|-------|-------|----------|
| `unauthenticated` | Not logged in | Log in first |
| `invalid-argument` | Missing userId/taskId | Check parameters |
| `permission-denied` | Not task owner or admin | Ask owner to send |
| `not-found` | Task doesn't exist | Create task first |
| `failed-precondition` | No recipient email | Add contact email or override |
| `internal` | Email extension issue | Check Firebase Extensions status |

### Graceful Error Recovery

**In Flutter:**
```dart
try {
  final result = await FirebaseFunctions.instance
    .httpsCallable('sendTaskEmail')
    .call({...});
  
  if (result.data['success']) {
    print('Email queued: ${result.data['emailQueueId']}');
  }
} on FirebaseFunctionsException catch (e) {
  if (e.code == 'failed-precondition') {
    // Show UI to enter custom email
    showDialog(
      context: context,
      builder: (_) => CustomEmailDialog(
        onSend: (email) => sendWithOverride(email),
      ),
    );
  } else {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: ${e.message}'))
    );
  }
}
```

---

## Testing

### Unit Test Example

```typescript
// Test: sendTaskEmail queues email
import * as admin from 'firebase-admin';
import { sendTaskEmail } from '../tasks/sendTaskEmail';

describe('sendTaskEmail', () => {
  it('should queue email to /mail collection', async () => {
    const context = { auth: { uid: 'user_123' } };
    const data = { userId: 'user_123', taskId: 'task_abc' };
    
    // Mock task document
    await admin.firestore()
      .collection('users').doc('user_123')
      .collection('tasks').doc('task_abc')
      .set({
        title: 'Test Task',
        description: 'Test description',
        status: 'pending',
        userId: 'user_123'
      });
    
    // Call function
    const result = await sendTaskEmail(data, context as any);
    
    // Verify /mail document created
    expect(result.success).toBe(true);
    expect(result.emailQueueId).toBeDefined();
    
    const mailDoc = await admin.firestore()
      .collection('mail').doc(result.emailQueueId).get();
    expect(mailDoc.exists).toBe(true);
  });
});
```

### Manual Testing

1. **Queue an email:**
   ```
   Open app → Go to Tasks → Find task → Click "Send Email"
   ```

2. **Check /mail collection:**
   ```
   Firebase Console → Firestore → mail collection
   Should see new document with your task
   ```

3. **Monitor delivery:**
   ```
   Wait 30 seconds → Check 'delivery' field in mail document
   Should show: { state: "SUCCESS", endTime: ... }
   ```

4. **Verify email received:**
   ```
   Check inbox for email from configured Resend sender
   Should contain task subject and description
   ```

5. **Check task status:**
   ```
   Go back to task → Status should now be "sent"
   sentAt timestamp should be recent
   ```

---

## Security & Compliance

### Authentication
✅ Cloud Function requires `context.auth` (logged-in user)

### Authorization
✅ Owner or admin can send emails for user
✅ Cannot send emails for other users unless admin

### Email Validation
✅ Task must exist
✅ Task status must be "pending" or "ready_to_send"
✅ Recipient email required (from contact or override)

### Audit Trail
✅ All email sends logged in `task_audit` collection
✅ Failed attempts also logged
✅ Shows who sent, when, to whom

### Data Privacy
✅ Email content stored in /mail only during queue
✅ Deleted after successful delivery (depends on extension settings)
✅ Audit trail retained for compliance

---

## Firestore Security Rules

Ensure these rules are in place:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Email queue (read-only from frontend, write by extension)
    match /mail/{document=**} {
      allow read: if request.auth.uid != null;
      allow write: if false;  // Only extension writes
    }
    
    // Task audit (user can read their own)
    match /users/{uid}/task_audit/{document=**} {
      allow read: if request.auth.uid == uid;
      allow write: if false;  // Only Cloud Functions write
    }
  }
}
```

---

## Integration With Task Workflow

### Complete Task Delivery Pipeline

```
1. Create Task (Manual or AI)
   ├─ status: "pending"
   └─ title, description, dueDate, etc.

2. processDueReminders (Every 5 min)
   ├─ Finds tasks with remindAt <= now
   └─ Creates entry in task_queue

3. sendTaskEmail (Called from UI or scheduled)
   ├─ Queues email to /mail collection
   ├─ Firebase Extension sends email
   └─ Updates task status to "sent"

4. Audit Trail
   └─ Records all email actions for compliance
```

### Manual Email Workflow

```
User on Task Detail Screen
    ↓
Clicks "📧 Send Email" button
    ↓
sendTaskEmail() called
    ↓
Email queued to /mail
    ↓
Firebase Extension sends
    ↓
Task status updates to "sent"
    ↓
Audit entry created
    ↓
Email arrives in recipient inbox
```

---

## Configuration

### Set Email Sender

After installing Firebase Email Extension:

1. Go to **Firebase Console** → **Extensions**
2. Find **Email by Resend** (or your provider)
3. Configure sender email/domain
4. Save configuration

Your emails will be sent from the configured sender address.

### Customize Email Templates

Email content is built in `sendTaskEmail()`:
- Default subject: `task.title`
- Default body: `task.template` or `task.description`
- Can override via `overrideSubject` / `overrideBody`

To customize HTML template, edit `/functions/src/tasks/sendTaskEmail.ts`:

```typescript
const message = data.overrideBody ?? (taskData.template || `
  <div style="font-family:sans-serif;padding:20px;max-width:600px;">
    <h2>${subject}</h2>
    <p>${message}</p>
    <br><hr>
    <p style="font-size:12px;color:#777;">
      Sent automatically by AuraSphere Pro ✨
    </p>
  </div>
`);
```

---

## Cost Comparison

### Firebase Email Extension (Current)
- **Setup:** Free
- **Sending:** Pay per email (Resend: $0.20-0.30 per email for free tier → $20-30/month for ~100 emails)
- **Monthly:** ~$0-30 depending on volume

### SendGrid (Alternative)
- **Setup:** Free API key
- **Sending:** Free up to 100/day, then paid
- **Monthly:** $0-30+ depending on volume

✅ **Firebase Email Extension is recommended** for simpler setup with zero external configuration after initial installation.

---

## Related Files

- `/functions/src/tasks/sendTaskEmail.ts` - Cloud Function implementation
- `/functions/src/utils/logger.ts` - Logging utility
- `/functions/src/index.ts` - Function exports
- `/functions/package.json` - Dependencies (no SendGrid)
- `docs/sendgrid_email_delivery.md` - Alternative SendGrid approach

---

## Next Steps

1. ✅ Install Firebase Email Extension (Email by Resend)
2. ✅ Deploy Cloud Functions: `firebase deploy --only functions`
3. ✅ Test email sending via app
4. ✅ Monitor /mail collection for delivery status
5. ✅ Add "Send Email" button to task detail screen

All done! Your email delivery is now live.
