# Invoice System - Complete Testing Checklist

**Last Updated:** November 27, 2025  
**Status:** Ready for Testing  
**Estimated Time:** 30-45 minutes

---

## 📋 Pre-Testing Setup

### Prerequisites
- [ ] Flutter SDK installed and up to date
- [ ] Firebase project configured
- [ ] Google Cloud services enabled (Storage, Firestore, Functions)
- [ ] Firebase Email Extension installed (if using email)
- [ ] Test email address available (Gmail recommended)
- [ ] Firebase CLI installed locally
- [ ] Device/Emulator ready (Android/iOS)

### Configuration Verification
```bash
# Check Flutter version
flutter --version

# Verify Firebase config
firebase projects:list

# Verify emulators (optional)
firebase emulators:start
```

---

## 🚀 Phase 1: Deployment (Before Testing App)

### 1.1 Deploy Firestore Rules
```bash
# Dry run (verify rules)
firebase deploy --only firestore:rules --dry-run

# Deploy rules
firebase deploy --only firestore:rules
```

**Verify:**
- [ ] Rules deployed without errors
- [ ] Check Firebase Console > Firestore > Rules tab shows your rules

### 1.2 Deploy Storage Rules
```bash
# Dry run
firebase deploy --only storage:rules --dry-run

# Deploy
firebase deploy --only storage:rules
```

**Verify:**
- [ ] Rules deployed without errors
- [ ] Storage paths protected under `/users/{userId}/`

### 1.3 Build and Deploy Cloud Functions
```bash
# Navigate to functions directory
cd functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Deploy functions
firebase deploy --only functions
```

**Verify:**
- [ ] Functions deployed successfully
- [ ] Check Firebase Console > Functions for:
  - `onInvoiceCreated` (should show 1 execution if testing)
  - `onInvoicePaid` (should show 0 if not tested)
  - No error logs

### 1.4 Verify Email Extension (Optional but Recommended)
```bash
# Check if extension installed
firebase ext:list

# View extension config
firebase ext:info firebase-send-email
```

**Verify:**
- [ ] Extension appears in list
- [ ] SendGrid API key configured (if using SendGrid backend)
- [ ] Collection path is `/mail`

---

## 🧪 Phase 2: App Testing

### 2.1 Start Development Server
```bash
# Navigate to project root
cd /workspaces/aura-sphere-pro

# Get dependencies
flutter pub get

# Run app
flutter run

# Or for specific device:
flutter run -d <device-id>
```

**Verify:**
- [ ] App compiles without errors
- [ ] App launches successfully
- [ ] Splash screen appears
- [ ] No red error banners

### 2.2 Authentication

**Test: Login/Sign Up**
- [ ] Navigate to login screen
- [ ] Enter valid email and password
- [ ] Successfully log in
- [ ] Dashboard loads with user data
- [ ] User profile shows correct name/email

**Verify in Firebase Console:**
```
Firebase > Authentication > Users
```
- [ ] User listed with correct UID
- [ ] Sign-in method: Email/Password
- [ ] Creation date: Today

---

## 💰 Phase 3: Invoice Creation Flow

### 3.1 Navigate to Invoice Creator

**Method A: Via Routes**
```dart
// In browser dev tools or terminal
adb shell am start -n com.example.app/.screens.invoices.InvoiceCreatorScreen
```

**Method B: Via App UI**
- [ ] Go to Dashboard
- [ ] Navigate to Invoices section
- [ ] Click "Create Invoice" or FAB button
- [ ] InvoiceCreatorScreen loads

### 3.2 Fill Invoice Form

**Step 1: Invoice Number (Optional)**
- [ ] Leave blank OR enter custom number (e.g., "INV-2024-001")
- [ ] Field accepts text input

**Step 2: Client Information**
```
Client Name: "Acme Corporation"
Client Email: "billing@acme.com" (Use a real test email)
Client ID: "client-123" (Optional)
```
- [ ] All fields editable
- [ ] Email format validated (should accept valid email)

**Step 3: Add Items**
```
Item 1:
  Description: "Web Development Services"
  Quantity: 40
  Unit Price: 150.00

Item 2:
  Description: "Monthly Hosting"
  Quantity: 1
  Unit Price: 100.00
```

**Verification:**
- [ ] Item added to list
- [ ] Item shows: Description, Qty, Unit Price, Total (qty × price)
- [ ] Can remove items (delete icon appears)
- [ ] Totals recalculate in real-time
- [ ] Expected subtotal: (40 × 150) + (1 × 100) = 6,100.00

**Step 4: Set Tax Rate**
- [ ] Drag slider to 0.10 (10%)
- [ ] Displays as "10.0%"
- [ ] Tax amount updates: 6,100 × 0.10 = 610.00
- [ ] Total updates: 6,100 + 610 = 6,710.00

**Step 5: Set Currency**
```
Currency: "USD" (default) or change to "EUR", "MAD", etc.
```
- [ ] Dropdown shows currency options
- [ ] Selected currency displays in totals

**Step 6: Set Due Date**
- [ ] Tap "Due Date" field
- [ ] Date picker appears
- [ ] Select date 30 days from now
- [ ] Date displays as: "YYYY-MM-DD"

**Step 7: Verify Totals Card**
```
Expected display:
  Subtotal: USD 6,100.00
  Tax (10%): USD 610.00
  ────────────────────
  TOTAL: USD 6,710.00
```
- [ ] All amounts correct
- [ ] Total highlighted in green
- [ ] Currency prefix correct

### 3.3 Save Invoice (First Test)

**Action: Click "Save" Button**
- [ ] Button shows "Save" label
- [ ] Button is enabled (not grayed out)
- [ ] Click button
- [ ] Loading indicator appears briefly
- [ ] Snackbar shows "Invoice saved!" in green

**Verify in Firestore:**
```
Path: users/{uid}/invoices/{invoiceId}

Expected document:
{
  "id": "1234567890",
  "userId": "{uid}",
  "clientId": "client-123",
  "clientName": "Acme Corporation",
  "clientEmail": "billing@acme.com",
  "items": [
    {
      "description": "Web Development Services",
      "quantity": 40,
      "unitPrice": 150.0,
      "total": 6000.0
    },
    {
      "description": "Monthly Hosting",
      "quantity": 1,
      "unitPrice": 100.0,
      "total": 100.0
    }
  ],
  "subtotal": 6100.0,
  "tax": 610.0,
  "total": 6710.0,
  "currency": "USD",
  "taxRate": 0.1,
  "status": "draft",
  "invoiceNumber": "INV-2024-001",
  "createdAt": Timestamp,
  "dueDate": Timestamp,
  "updatedAt": Timestamp
}
```

**Firebase Console Check:**
```
Firestore > Databases > default > users > {uid} > invoices > {invoiceId}
```
- [ ] Document exists
- [ ] All fields present and correct
- [ ] Status = "draft" (not sent yet)
- [ ] createdAt timestamp exists

**Cloud Functions Log Check:**
```
Firebase Console > Functions > Logs > onInvoiceCreated
```
- [ ] Function execution logged
- [ ] Status: "Success"
- [ ] Log shows: "Invoice created successfully"
- [ ] Log shows: "tokensAwarded: 8"
- [ ] Log shows: "newBalance: [previous + 8]"

---

## 📧 Phase 4: Email & PDF Sending

### 4.1 Send Invoice with Email & PDF

**Action: Click "Send" Button**
- [ ] Button shows "Send" label with paper-plane icon
- [ ] Button is enabled
- [ ] Click button
- [ ] Loading indicator appears
- [ ] App briefly disables buttons while sending
- [ ] Snackbar shows "Invoice sent!" in green
- [ ] Screen returns to list (or closes creator)

### 4.2 Verify Status Change

**In Firestore:**
```
Path: users/{uid}/invoices/{invoiceId}

Changes expected:
  "status": "sent" (was "draft")
  "sentAt": Timestamp (new field)
  "pdfUrl": "https://storage.googleapis.com/..." (new field)
  "updatedAt": Timestamp (updated)
```

**Firebase Console Check:**
```
Firestore > users > {uid} > invoices > {invoiceId}
```
- [ ] Status changed to "sent"
- [ ] sentAt timestamp added
- [ ] pdfUrl field present with valid URL
- [ ] updatedAt timestamp updated

### 4.3 Verify PDF in Storage

**Path Expected:**
```
invoices/{uid}/{invoiceId}.pdf
```

**Firebase Console Check:**
```
Storage > Files > invoices > {uid} > {invoiceId}.pdf
```
- [ ] File exists
- [ ] File size > 10 KB (valid PDF)
- [ ] Content-Type: "application/pdf"
- [ ] Download URL works (click to preview/download)

**Test Download URL:**
- [ ] Click download icon or view in Storage console
- [ ] PDF opens/downloads successfully
- [ ] Contains invoice details:
  - Client name
  - Invoice number
  - Line items
  - Totals with tax
  - Due date
  - Your company name

### 4.4 Check Email Delivery

**Check Test Email Inbox:**
```
Email Address: billing@acme.com (or your test email)
```

**Expected Email Arrives Within 1-5 Minutes:**
- [ ] Subject: "Invoice INV-2024-001 - USD 6,710.00"
- [ ] From: Firebase Email Extension sender (e.g., noreply@project.firebaseapp.com)
- [ ] Contains professional HTML:
  - [ ] AuraSphere Pro header
  - [ ] Client greeting
  - [ ] Invoice table with items
  - [ ] Subtotal, Tax, Total rows
  - [ ] Due date
  - [ ] Professional styling
  - [ ] Your company contact info

**Email Content Checklist:**
- [ ] Client name mentioned
- [ ] Invoice number displayed
- [ ] Line items listed with descriptions and amounts
- [ ] Correct subtotal: USD 6,100.00
- [ ] Correct tax: USD 610.00 (10%)
- [ ] Correct total: USD 6,710.00
- [ ] Due date: (30 days from creation)
- [ ] PDF attachment (if supported by extension)

### 4.5 Verify Audit Trail

**In Firestore:**
```
Path: users/{uid}/invoice_audit_log/

Expected document:
{
  "invoiceId": "{invoiceId}",
  "action": "email_sent",
  "timestamp": Timestamp,
  "to": "billing@acme.com",
  "attachedPdf": true
}
```

**Firebase Console Check:**
```
Firestore > users > {uid} > invoice_audit_log
```
- [ ] New audit entry exists
- [ ] Action = "email_sent"
- [ ] Timestamp = when email was sent
- [ ] Client email recorded

---

## 🏆 Phase 5: Invoice List & Management

### 5.1 View Invoice List

**Navigate to Invoice List Screen:**
- [ ] Click back to return to list
- [ ] OR navigate via menu/routes to Invoices section
- [ ] InvoiceListScreen loads

**Expected Display:**
- [ ] Filter chips: All, Draft, Sent, Paid
- [ ] Invoice card shows:
  - [ ] Invoice Number: "INV-2024-001"
  - [ ] Client: "Acme Corporation"
  - [ ] Amount: "USD 6,710.00" (green)
  - [ ] Status badge: "SENT" (blue)
  - [ ] Due date: "2024-12-27" (or your selected date)
  - [ ] Menu icon (3-dot)

### 5.2 Filter Invoices

**Test Filters:**
- [ ] Click "Draft" chip → Only draft invoices show (none in this test)
- [ ] Click "Sent" chip → Our test invoice appears
- [ ] Click "Paid" chip → No invoices (we haven't marked as paid)
- [ ] Click "All" chip → All invoices show

### 5.3 Mark as Paid

**Action: Long-press invoice card OR tap 3-dot menu**
- [ ] Menu appears with options
- [ ] Click "Mark as Paid"
- [ ] Snackbar: "Invoice marked as paid"
- [ ] Invoice card updates:
  - [ ] Status badge changes to "PAID" (green)
  - [ ] Status color updates

**Verify in Firestore:**
```
Path: users/{uid}/invoices/{invoiceId}

Changes:
  "status": "paid" (was "sent")
  "paidDate": Timestamp (new field)
  "updatedAt": Timestamp
```

**Cloud Functions Log Check:**
```
Firebase Console > Functions > Logs > onInvoicePaid
```
- [ ] Function execution logged
- [ ] Status: "Success"
- [ ] Log shows: "Invoice marked as paid"
- [ ] Log shows: "tokensAwarded: 15" (payment reward)
- [ ] Log shows new AuraToken balance

### 5.4 Edit Invoice (Draft Only)

**Create Another Invoice (Draft Status):**
- [ ] Go back to creator
- [ ] Add new invoice but DON'T click "Send"
- [ ] Just click "Save"
- [ ] Invoice saved with status "draft"
- [ ] Return to list

**Edit Draft Invoice:**
- [ ] Find draft invoice in list
- [ ] Tap 3-dot menu
- [ ] Click "Edit"
- [ ] Creator screen loads with pre-filled data
- [ ] Modify a field (e.g., client name)
- [ ] Click "Save"
- [ ] Changes persist in Firestore

### 5.5 Delete Invoice

**Action: Tap 3-dot menu > Delete**
- [ ] Confirmation dialog appears
- [ ] Dialog says "Delete Invoice? This action cannot be undone."
- [ ] Click "Delete"
- [ ] Snackbar: "Invoice deleted"
- [ ] Invoice removed from list

**Verify in Firestore:**
```
Path: users/{uid}/invoices/

Expected: Invoice document gone
```

---

## 🎖️ Phase 6: Token Rewards Verification

### 6.1 Check AuraToken Balance

**In Firestore:**
```
Path: users/{uid}/wallet/aura

Expected document:
{
  "balance": 23.0,  // Started at 0, +8 for create, +15 for paid
  "updatedAt": Timestamp
}
```

**Firebase Console Check:**
```
Firestore > users > {uid} > wallet > aura
```
- [ ] Document exists
- [ ] Balance = 23 (8 for creation + 15 for payment)

### 6.2 Check Audit Trail

**In Firestore:**
```
Path: users/{uid}/token_audit/

Expected entries:
1. {
     "action": "create_invoice",
     "amount": 8,
     "awardedBy": "system",
     "metadata": { invoiceId, clientName, total, ... }
   }
2. {
     "action": "invoice_paid",
     "amount": 15,
     "awardedBy": "system",
     "metadata": { invoiceId, total, ... }
   }
```

**Firebase Console Check:**
```
Firestore > users > {uid} > token_audit
```
- [ ] Two entries exist
- [ ] First: create_invoice, amount: 8
- [ ] Second: invoice_paid, amount: 15

---

## 🔐 Phase 7: Security Verification

### 7.1 Test Firestore Rule Enforcement

**Verify User Can Only Access Own Invoices:**

**In Firestore Console (Advanced Queries):**
```javascript
// Try to access another user's invoice
// Should FAIL
db.collection('users')
  .doc('ANOTHER_UID')
  .collection('invoices')
  .get()
```

**Result:**
- [ ] Access denied
- [ ] Error: "Missing or insufficient permissions"

### 7.2 Test Storage Rule Enforcement

**Verify User Cannot Access Other Users' PDFs:**

**In Storage Console:**
```
Try to access: invoices/OTHER_UID/{invoiceId}.pdf
```

**Result:**
- [ ] Access denied
- [ ] Error: "User does not have permission"

### 7.3 Test Unauthenticated Access

**Logout and Try to Access:**
- [ ] Logout from app
- [ ] Try to navigate to invoices
- [ ] Should redirect to login
- [ ] Cannot create/view invoices

---

## ⚠️ Phase 8: Error Handling Tests

### 8.1 Invalid Email Test

**Create Invoice with Invalid Email:**
- [ ] Client Email: "not-an-email"
- [ ] Try to send
- [ ] Expected: Error message or validation fail

### 8.2 Missing Required Fields

**Create Invoice Missing Required Data:**
- [ ] Client Name: "" (blank)
- [ ] Try to save
- [ ] Expected: Error or validation message

### 8.3 Network Error Simulation

**Test Error Recovery (Optional):**
- [ ] Disable network while sending invoice
- [ ] App should show error
- [ ] Retry button should work
- [ ] No orphaned data in Firestore

---

## 📊 Phase 9: Data Integrity Verification

### 9.1 Totals Accuracy

**Verify Calculations:**
```
Items:
  Item 1: 40 × $150 = $6,000
  Item 2: 1 × $100 = $100

Subtotal: $6,100 ✓
Tax (10%): $610 ✓
Total: $6,710 ✓
```

- [ ] All calculations correct in app
- [ ] All calculations correct in Firestore document
- [ ] All calculations correct in PDF
- [ ] All calculations correct in email

### 9.2 Timestamp Verification

**Check All Timestamps Exist:**
- [ ] createdAt ✓
- [ ] updatedAt ✓
- [ ] dueDate ✓
- [ ] sentAt ✓ (after sending)
- [ ] paidDate ✓ (after marking paid)

**Verify Timestamp Order:**
- [ ] createdAt < sentAt
- [ ] sentAt < paidDate

### 9.3 PDF URL Validity

**Test PDF Download:**
```
1. Get pdfUrl from Firestore
2. Open URL in browser
3. PDF should download/open
4. PDF content should match invoice details
```

- [ ] URL is valid HTTPS
- [ ] PDF opens successfully
- [ ] PDF contains correct data
- [ ] PDF is readable

---

## 🧹 Phase 10: Cleanup & Final Checks

### 10.1 Clean Up Test Data (Optional)

**Delete Test Invoices:**
- [ ] Delete all test invoices via app UI
- [ ] Verify removed from Firestore
- [ ] Verify PDF files cleaned up (optional)

### 10.2 Run Lint Check

```bash
flutter analyze
```

- [ ] No analysis errors
- [ ] No warnings

### 10.3 Check App Performance

**Monitor Performance:**
- [ ] App runs smoothly
- [ ] No jank or freezes during list operations
- [ ] Loading indicators appear appropriately
- [ ] No memory leaks (check in DevTools)

### 10.4 Verify Cloud Functions Deployment

```bash
firebase functions:list
```

- [ ] onInvoiceCreated deployed
- [ ] onInvoicePaid deployed
- [ ] No errors in logs

---

## ✅ Final Checklist

### Phase Completion Status

- [ ] Phase 1: Deployment ✓
- [ ] Phase 2: App Testing ✓
- [ ] Phase 3: Invoice Creation ✓
- [ ] Phase 4: Email & PDF ✓
- [ ] Phase 5: List & Management ✓
- [ ] Phase 6: Token Rewards ✓
- [ ] Phase 7: Security ✓
- [ ] Phase 8: Error Handling ✓
- [ ] Phase 9: Data Integrity ✓
- [ ] Phase 10: Cleanup ✓

### Deployment Readiness

- [ ] All tests passed
- [ ] No critical errors
- [ ] Firestore rules deployed
- [ ] Cloud Functions deployed
- [ ] Email extension configured
- [ ] Storage rules deployed
- [ ] App builds successfully
- [ ] No performance issues

### Ready for Production

**Status:** ✅ **PASSED - READY FOR PRODUCTION**

---

## 📞 Troubleshooting

### Email Not Arriving

**Check:**
1. Firebase Email Extension installed
2. SendGrid API key configured (if using SendGrid)
3. Cloud Functions logs for errors
4. Check spam/junk folder
5. Verify client email is correct

### PDF Not Generating

**Check:**
1. InvoicePdfService logs
2. Firebase Storage permissions
3. Device storage space
4. PDF library installation

### Tokens Not Awarded

**Check:**
1. onInvoiceCreated function deployed
2. Cloud Functions logs for errors
3. Firestore wallet document exists
4. Check token_audit collection for entries

### Firestore Rules Errors

**Check:**
1. Rules deployed correctly
2. userId field present on documents
3. User authenticated
4. Security rules syntax correct

---

## 📝 Test Results Template

**Date Tested:** ___________  
**Tester Name:** ___________  
**App Version:** ___________  
**Device:** ___________  

### Summary
- Invoices Created: ___
- Invoices Sent: ___
- Tests Passed: ___
- Tests Failed: ___

### Issues Found
1. _______________
2. _______________
3. _______________

### Notes
_________________________________________________

**Approved for Production:** [ ] Yes  [ ] No

---

**Happy Testing! 🎉**
