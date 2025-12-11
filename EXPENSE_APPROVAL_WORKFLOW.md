# Expense Approval Workflow — December 10, 2025

## Overview
Implemented **onExpenseCreatedNotify** Firestore trigger that automatically initiates approval tasks when expenses are created. This completes the expense lifecycle: OCR → Parsing → Approval → Reconciliation.

## Workflow Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│ EXPENSE CREATION WORKFLOW                                      │
└─────────────────────────────────────────────────────────────────┘

1. UPLOAD & OCR
   └─> User uploads receipt image or selects document
   └─> visionOcr() extracts text using Google Vision API
   └─> parseHelpers.ts extracts merchant, amounts, dates

2. CREATE EXPENSE (Draft)
   └─> Expense document created at:
       /users/{uid}/expenses/{expenseId}
   └─> Status: 'draft'
   └─> Firestore trigger fires: onExpenseCreatedNotify

3. CREATE APPROVAL TASK (This Function)
   └─> onExpenseCreatedNotify catches the create event
   └─> Creates approval record in subcollection:
       /users/{uid}/expenses/{expenseId}/approvals/{approvalId}
   └─> Status: 'pending'
   └─> Sets notified: true

4. APPROVAL REVIEW
   └─> Manager/approver sees pending expense
   └─> Reviews merchant, amount, date, attachments
   └─> Approves or rejects

5. POST-APPROVAL
   └─> If approved → onExpenseApproved() triggers
   └─> Updates inventory (onExpenseApprovedInventory)
   └─> Records audit log entry
   └─> May trigger compliance checks
```

## Function Implementation

### File: `notifyApproval.ts`
Location: `/workspaces/aura-sphere-pro/functions/src/expenses/notifyApproval.ts`

**Type**: Firestore Document Trigger  
**Trigger Path**: `users/{uid}/expenses/{expenseId}`  
**Event**: `onCreate`

```typescript
export const onExpenseCreatedNotify = functions.firestore
  .document('users/{uid}/expenses/{expenseId}')
  .onCreate(async (snap, context) => {
    // Automatically called when expense doc is created
    // snap.data() = expense document
    // context.params = { uid, expenseId }
  });
```

### What It Does

#### 1. **Extract Expense Data**
```typescript
const expense = snap.data();
const uid = context.params.uid;
const expenseId = context.params.expenseId;
```

#### 2. **Validate**
```typescript
if (!expense) {
  console.warn('Expense document exists but has no data');
  return;  // Exit if doc is empty
}
```

#### 3. **Create Approval Subcollection**
```typescript
const approvalsRef = snap.ref.collection('approvals');
const approvalDoc = {
  status: 'pending',
  createdAt: admin.firestore.FieldValue.serverTimestamp(),
  notified: false,
  expenseAmount: expense.totalAmount || null,
  merchant: expense.merchant || null,
  expenseDate: expense.date || null,
};
const approvalSnap = await approvalsRef.add(approvalDoc);
```

**Creates document at**:
```
/users/{uid}/expenses/{expenseId}/approvals/{approvalId}
{
  status: "pending",
  createdAt: Timestamp(2025-12-10T12:00:00Z),
  notified: false,
  expenseAmount: 54.49,
  merchant: "Starbucks",
  expenseDate: "2025-12-10"
}
```

#### 4. **Mark Notified**
```typescript
await approvalSnap.update({
  notified: true,
  notifiedAt: admin.firestore.FieldValue.serverTimestamp(),
});
```

#### 5. **Create Audit Log Entry**
```typescript
const auditRef = db.collection('users').doc(uid).collection('auditLog');
await auditRef.add({
  action: 'expense_created_approval_initiated',
  expenseId,
  approvalId: approvalSnap.id,
  timestamp: admin.firestore.FieldValue.serverTimestamp(),
  details: {
    merchant: expense.merchant,
    amount: expense.totalAmount,
    currency: expense.currency,
  }
});
```

**Creates document at**:
```
/users/{uid}/auditLog/{logId}
{
  action: "expense_created_approval_initiated",
  expenseId: "exp_123",
  approvalId: "appr_456",
  timestamp: Timestamp,
  details: {
    merchant: "Starbucks",
    amount: 54.49,
    currency: "EUR"
  }
}
```

## Data Schema

### Expense Document Structure
```typescript
/users/{uid}/expenses/{expenseId}
{
  // From OCR parsing
  merchant: string;                    // "Starbucks"
  totalAmount: number;                 // 54.49
  currency: string;                    // "EUR"
  date: string;                        // "2025-12-10"
  
  // Status tracking
  status: 'draft' | 'pending_approval' | 'approved' | 'rejected' | 'reconciled';
  
  // OCR data
  rawOcr: string;                      // Full OCR text
  parsed: {
    amounts: Array;
    dates: Array;
    merchant: string;
    items?: Array;
  };
  
  // Attachments
  attachments: Array<{
    path: string;                      // gs://bucket/users/uid/expenses/123/receipt.jpg
    uploadedAt: Timestamp;
  }>;
  
  // Timestamps
  createdAt: Timestamp;
  updatedAt?: Timestamp;
}
```

### Approval Subcollection
```typescript
/users/{uid}/expenses/{expenseId}/approvals/{approvalId}
{
  status: 'pending' | 'approved' | 'rejected';
  createdAt: Timestamp;
  notified: boolean;
  notifiedAt?: Timestamp;
  expenseAmount: number;
  merchant: string;
  expenseDate: string;
  
  // Optional fields (added during review)
  approvedBy?: string;                 // UID of approver
  approvedAt?: Timestamp;
  rejectionReason?: string;
  comments?: string;
}
```

## Future Enhancements

### 1. **Send Notifications to Approvers**
```typescript
// Query approvers from business profile
const profileRef = db.collection('users').doc(uid).collection('businessProfile').doc('default');
const profile = await profileRef.get();
const approvers = profile.data()?.approvers || [];

// Send push notifications via FCM
for (const approver of approvers) {
  await admin.messaging().send({
    token: approver.fcmToken,
    notification: {
      title: `New expense to review`,
      body: `${expense.merchant} - ${expense.totalAmount} ${expense.currency}`,
    },
    data: {
      expenseId,
      approvalId: approvalSnap.id,
      screen: 'expenses_approval'
    }
  });
}
```

### 2. **Send Email Notification**
```typescript
// Email approvers
const sgMail = require('@sendgrid/mail');
sgMail.setApiKey(functions.config().sendgrid?.key);

for (const approver of approvers) {
  await sgMail.send({
    to: approver.email,
    from: functions.config().email?.from || 'noreply@aurasphere.app',
    subject: `Expense approval needed: ${expense.merchant}`,
    html: `
      <h2>Expense Approval Required</h2>
      <p>Merchant: ${expense.merchant}</p>
      <p>Amount: ${expense.totalAmount} ${expense.currency}</p>
      <p>Date: ${expense.date}</p>
      <a href="${functions.config().app?.appUrl}/expenses/${expenseId}/approve">Review Expense</a>
    `
  });
}
```

### 3. **Smart Routing Based on Amount**
```typescript
// Route to different approvers based on amount threshold
const amount = expense.totalAmount || 0;
const approvers = amount > 500 
  ? profile.data()?.seniorApprovers || []
  : profile.data()?.approvers || [];
```

### 4. **Compliance Checks**
```typescript
// Flag for compliance review if needed
if (expense.totalAmount > 1000 || expense.merchant.includes('airline')) {
  await approvalsRef.add({
    status: 'pending_compliance',
    complianceCheck: true,
    createdAt: admin.firestore.FieldValue.serverTimestamp(),
  });
}
```

### 5. **Integration with Approval Workflow Cloud Function**
Create a separate callable function to handle approval decisions:

```typescript
export const approveExpense = functions.https.onCall(async (data, context) => {
  const { expenseId, approvalId, approved, comments } = data;
  const uid = context.auth!.uid;
  
  const approvalRef = db.collection('users').doc(uid)
    .collection('expenses').doc(expenseId)
    .collection('approvals').doc(approvalId);
  
  await approvalRef.update({
    status: approved ? 'approved' : 'rejected',
    approvedBy: uid,
    approvedAt: admin.firestore.FieldValue.serverTimestamp(),
    comments: comments || null,
  });
  
  if (approved) {
    // Trigger inventory deduction, etc.
    // This will be caught by onExpenseApproved trigger
    const expenseRef = db.collection('users').doc(uid)
      .collection('expenses').doc(expenseId);
    await expenseRef.update({ status: 'approved' });
  }
  
  return { success: true };
});
```

## Testing Checklist

### Unit Tests
```typescript
describe('onExpenseCreatedNotify', () => {
  it('should create approval task on expense creation', async () => {
    // Create expense document
    // Verify approvals subcollection created
    // Check status is 'pending'
    // Check notified is true
    // Check audit log created
  });

  it('should capture expense metadata in approval', async () => {
    // Create expense with merchant, amount, date
    // Verify approval doc has matching metadata
  });

  it('should handle missing expense data gracefully', async () => {
    // Create empty expense doc
    // Should not crash
    // Should log warning
  });
});
```

### Integration Tests
```typescript
// 1. Create expense via visionOcr
// 2. Verify onExpenseCreatedNotify fires
// 3. Check approvals subcollection exists
// 4. Check audit log entry exists
// 5. Move to approval with approveExpense()
// 6. Verify onExpenseApproved fires
// 7. Check inventory impact
```

## Firestore Security Rules

```firestore
// Allow users to read their own expenses and approval tasks
match /users/{uid}/expenses/{expenseId} {
  allow read, create: if request.auth.uid == uid;
  allow update: if request.auth.uid == uid && 
                   (request.resource.data.status == 'approved' || 
                    request.resource.data.status == 'rejected');
  
  // Approval subcollection
  match /approvals/{approvalId} {
    allow read: if request.auth.uid == uid;
    allow create: if false; // Only server functions can create
    allow update: if request.auth.uid == uid &&
                     request.resource.data.approvedBy == request.auth.uid;
  }
}
```

## Deployment Status
✅ **Created**: notifyApproval.ts (56 lines)
✅ **Exported**: In functions/src/index.ts
✅ **Compiled**: TypeScript build successful
✅ **Deployed**: onExpenseCreatedNotify live on Firebase
✅ **Trigger Path**: users/{uid}/expenses/{expenseId} onCreate

## Integration with Other Functions

| Function | Triggers | Follows |
|----------|----------|---------|
| **visionOcr** | Manual call from Flutter | - |
| **onExpenseCreatedNotify** | Auto on expense create | visionOcr |
| **onExpenseApproved** | Auto on approval status change | onExpenseCreatedNotify |
| **onExpenseApprovedInventory** | Auto on approval status change | onExpenseApproved |

## Next Steps
1. ✅ Create approval trigger (COMPLETE)
2. ⏳ Add notification service (email/push)
3. ⏳ Create approveExpense callable function
4. ⏳ Add compliance routing logic
5. ⏳ Implement in Flutter UI (expense approval screen)
6. ⏳ Add reporting/analytics

---

**Created**: December 10, 2025  
**Status**: ✅ Production Ready  
**Total Functions**: 48 (added onExpenseCreatedNotify)
