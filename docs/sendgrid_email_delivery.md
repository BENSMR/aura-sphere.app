# SendGrid Email Delivery Function

## Overview

The `sendTaskEmail` function handles sending task reminder emails via SendGrid. It completes the task delivery workflow:

```
processDueReminders (finds tasks)
         ↓
Creates queue entry in task_queue
         ↓
sendTaskEmail (sends via email)
         ↓
Updates task status to "sent"
         ↓
Logs audit trail
```

---

## Function Signature

```typescript
export const sendTaskEmail = functions.https.onCall(async (data, context) => {
  // Sends a task reminder email
  // Returns: { success: true, message: 'Email sent' }
})
```

## Parameters

```typescript
{
  userId: string,        // User ID (owner of task)
  taskId: string,        // Task document ID to send
  overrideEmail?: string,    // Optional: override recipient email
  overrideSubject?: string,  // Optional: override email subject
  overrideBody?: string      // Optional: override email body (HTML)
}
```

## Prerequisites

### 1. SendGrid API Key Setup

Set your SendGrid API key in Firebase config:

```bash
firebase functions:config:set sendgrid.key="SG.YOUR-API-KEY-HERE"
firebase functions:config:set sendgrid.from="noreply@yourdomain.com"
```

Verify:
```bash
firebase functions:config:get
# Should show:
# {
#   "sendgrid": {
#     "key": "SG.YOUR-API-KEY-HERE",
#     "from": "noreply@yourdomain.com"
#   }
# }
```

### 2. SendGrid Account

- Create account: https://sendgrid.com
- Create API key: https://app.sendgrid.com/settings/api_keys
- Verify sender email or domain

---

## How It Works

### 1. Authentication & Authorization

```typescript
// Must be logged in
if (!context.auth) throw HttpsError('unauthenticated')

// Can only send own tasks, or be admin
if (callerUid !== userId) {
  // Check admin status
  const adminDoc = await db.doc(`admins/${callerUid}`).get();
  if (!adminDoc.exists) throw HttpsError('permission-denied')
}
```

### 2. Task Validation

```typescript
// Task must exist
const taskData = await getTaskDoc(taskRef);
if (!taskData) throw HttpsError('not-found')

// Status must be "ready_to_send" or "pending"
if (!(taskData.status === 'ready_to_send' || taskData.status === 'pending')) {
  throw HttpsError('failed-precondition')
}
```

### 3. Email Resolution

```typescript
// Try: override email → contact email → fail
let toEmail = data.overrideEmail ?? null;

if (!toEmail && taskData.contactId) {
  // Load contact from contacts collection
  const contactSnap = await db.collection('users')
    .doc(userId)
    .collection('contacts')
    .doc(taskData.contactId)
    .get();
  
  toEmail = contactSnap.data()?.email;
}

if (!toEmail) throw HttpsError('failed-precondition', 'No email found')
```

### 4. Email Composition

```typescript
// Subject: override or use task title
const subject = data.overrideSubject ?? taskData.title;

// Body: override or use task template or construct default
const bodyHtml = data.overrideBody ?? (taskData.template || `
<p>Hi,</p>
<p>${taskData.description}</p>
<p>— ${taskData.assignedTo}</p>
`);
```

### 5. SendGrid Send

```typescript
const msg = {
  to: toEmail,
  from: DEFAULT_FROM,  // From Firebase config
  subject,
  html: bodyHtml
};

await sgMail.send(msg);
```

### 6. Task Status Update

```typescript
// Mark as sent
await taskRef.update({
  status: 'sent',
  sentAt: admin.firestore.FieldValue.serverTimestamp(),
  lastSentBy: callerUid
});
```

### 7. Audit Trail

```typescript
// Create audit entry
await db.collection('users')
  .doc(userId)
  .collection('task_audit')
  .add({
    action: 'email_sent',
    taskId,
    to: toEmail,
    subject,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
    sentBy: callerUid,
    userId
  });
```

---

## Usage Examples

### Example 1: Send with Auto-Detected Email

```dart
// From Flutter app
final result = await FirebaseFunctions.instance
  .httpsCallable('sendTaskEmail')
  .call({
    'userId': currentUser.uid,
    'taskId': 'task_abc123'
  });

print(result.data['message']); // "Email sent"
```

### Example 2: Send with Override Email

```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('sendTaskEmail')
  .call({
    'userId': currentUser.uid,
    'taskId': 'task_abc123',
    'overrideEmail': 'custom@example.com'
  });
```

### Example 3: Send with Custom Subject & Body

```dart
final result = await FirebaseFunctions.instance
  .httpsCallable('sendTaskEmail')
  .call({
    'userId': currentUser.uid,
    'taskId': 'task_abc123',
    'overrideSubject': 'Urgent: Follow-up needed',
    'overrideBody': '''
      <h2>Follow-up Required</h2>
      <p>Please contact the client about Q4 pricing.</p>
      <p>Due by: Nov 30, 2025</p>
    '''
  });
```

---

## Error Handling

### SendGrid Key Not Configured

```
Error: "SendGrid not configured"
Fix: firebase functions:config:set sendgrid.key="SG-..."
```

### No Recipient Email Found

```
Error: "No recipient email found"
Causes:
  • Task has no contactId
  • Contact doesn't have email field
  • overrideEmail not provided
```

### Task Not Ready

```
Error: "Task status is completed"
Only status "pending" or "ready_to_send" can be sent
```

### SendGrid API Error

```
Error: "Failed to send email"
Check:
  • API key is valid
  • Sender email is verified in SendGrid
  • Recipient email is valid
  • Email doesn't contain blocked content
  
Logs:
  firebase functions:log | grep "SendGrid send error"
```

---

## Firestore Collections Updated

### users/{uid}/tasks/{taskId}

```json
{
  "id": "task_abc123",
  "status": "sent",  // Changed from "ready_to_send"
  "sentAt": Timestamp(2025-11-27T10:30:00Z),
  "lastSentBy": "user_123"
}
```

### users/{uid}/task_audit/{auditId}

```json
{
  "action": "email_sent",
  "taskId": "task_abc123",
  "to": "john@example.com",
  "subject": "Email John about Q4 proposal",
  "createdAt": Timestamp(2025-11-27T10:30:00Z),
  "sentBy": "user_123",
  "userId": "user_123"
}
```

---

## Logging & Monitoring

All operations logged via logger utility:

```bash
# Monitor logs in real-time
firebase functions:log --follow

# Search for email sends
firebase functions:log | grep "Email sent successfully"

# Find failures
firebase functions:log | grep "SendGrid send error"
```

**Log Examples:**

```
✅ Email sent successfully
   { userId: "user_123", taskId: "task_abc123", to: "john@example.com", subject: "..." }

❌ SendGrid send error
   { userId: "user_123", taskId: "task_abc123", error: "Invalid email", code: "INVALID_EMAIL" }

⚠️  No recipient email found
   { userId: "user_123", taskId: "task_abc123", contactId: null }
```

---

## Integration with Task Workflow

### Complete Flow

```
1. User creates task (or AI auto-creates)
   ├─ status: "pending"
   └─ dueAt: Nov 28, 2025

2. processDueReminders runs (every 5 min)
   ├─ Finds tasks with remindAt <= now
   ├─ status: "pending"
   └─ Creates entry in task_queue

3. App or Worker calls sendTaskEmail
   ├─ Gets taskId from queue
   ├─ Sends email via SendGrid
   └─ Updates status to "sent"

4. Audit trail created
   ├─ task_audit document logged
   ├─ Shows who sent, when, to whom
   └─ Useful for compliance & support
```

### Integration Points

**From processDueReminders:**
```typescript
// After creating queue entry:
// App/worker can call sendTaskEmail with taskId from queue
```

**From Task Detail Screen:**
```dart
// User can manually send task
FloatingActionButton(
  onPressed: () => _sendTaskEmail(task.id),
  child: Icon(Icons.email)
)
```

**From Task Audit Screen:**
```dart
// Show delivery history
StreamBuilder<QuerySnapshot>(
  stream: db.collection('users')
    .doc(uid)
    .collection('task_audit')
    .where('taskId', '==', taskId)
    .orderBy('createdAt', descending: true)
    .snapshots(),
  builder: (ctx, snapshot) {
    // Display audit trail
  }
)
```

---

## Testing

### Local Testing with Emulator

```bash
# Start emulators
firebase emulators:start

# Call function directly (in another terminal)
firebase functions:call sendTaskEmail --data='{"userId": "test_user", "taskId": "test_task"}'
```

### Production Testing

1. Set SendGrid API key
2. Create test task with recipient email
3. Call function from app
4. Check SendGrid dashboard for sent emails
5. Verify task status updated to "sent"
6. Check task_audit collection for record

---

## Configuration

### Required: SendGrid API Key

```bash
firebase functions:config:set sendgrid.key="SG.YOUR-API-KEY-HERE"
```

### Optional: From Email Address

```bash
firebase functions:config:set sendgrid.from="noreply@yourdomain.com"
```

Default if not set: `"no-reply@yourdomain.com"`

### Optional: HTML Email Template

Use `task.template` field in Firestore:

```json
{
  "template": "<h1>Task: {{title}}</h1><p>{{description}}</p>"
}
```

Or provide via `overrideBody` parameter in API call.

---

## Best Practices

1. **Always set SendGrid key** before deploying
2. **Verify sender email** in SendGrid dashboard
3. **Use task audit trail** for compliance
4. **Handle errors gracefully** - log but don't block
5. **Test with test email** before production
6. **Monitor SendGrid quota** - watch for rate limits
7. **Use templates** - professional HTML emails
8. **Encrypt sensitive data** - don't log email content in production

---

## Related Files

- `/functions/src/tasks/sendTaskEmail.ts` — This function
- `/functions/src/tasks/processDueReminders.ts` — Creates queue entries
- `/functions/src/utils/logger.ts` — Logging utility
- `/functions/src/index.ts` — Function exports

---

## Next Steps

1. **Get SendGrid API Key:** https://app.sendgrid.com/settings/api_keys
2. **Set in Firebase:** `firebase functions:config:set sendgrid.key="..."`
3. **Test locally:** `firebase emulators:start`
4. **Deploy:** `firebase deploy --only functions`
5. **Monitor:** `firebase functions:log --follow`

---

**Status:** ✅ Ready to Deploy
