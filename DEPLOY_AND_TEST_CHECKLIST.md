# Expense System: Deploy & Test Checklist

**Last Updated:** November 27, 2025  
**Status:** Ready for Production Deployment

---

## Phase 1: File Structure Setup ✅

### 1.1 Create Directory Structure

```bash
# Create model directories
mkdir -p lib/data/models
mkdir -p lib/services/expenses
mkdir -p lib/screens/expenses
mkdir -p lib/services/reports

# Verify structure
tree -L 3 lib/
```

**Expected Output:**
```
lib/
├── data/
│   └── models/
│       └── expense_model.dart          ← Place here
├── services/
│   ├── expenses/
│   │   ├── expense_service.dart        ← Place here
│   │   ├── csv_importer.dart           ← Place here
│   │   └── tax_service.dart            ← Place here
│   └── reports/
│       └── report_service.dart         ← Place here
├── screens/
│   └── expenses/
│       ├── expense_scanner_screen.dart ← Place here
│       ├── expense_review_screen.dart  ← Place here
│       └── expense_list_screen.dart    ← Place here
```

**Checklist:**
- [ ] `lib/data/models/` directory created
- [ ] `lib/services/expenses/` directory created
- [ ] `lib/screens/expenses/` directory created
- [ ] `lib/services/reports/` directory created
- [ ] All files placed in correct directories

---

## Phase 2: Dependencies Setup ✅

### 2.1 Update pubspec.yaml

Add required packages to `pubspec.yaml` under `dependencies:` section:

```yaml
dependencies:
  flutter:
    sdk: flutter
  
  # Firebase packages (add/update versions)
  firebase_core: ^2.25.0
  cloud_firestore: ^4.15.0
  firebase_auth: ^4.17.0
  firebase_storage: ^11.7.0
  cloud_functions: ^4.7.0
  
  # UI & File handling
  image_picker: ^1.1.0
  file_picker: ^6.1.0
  
  # CSV handling
  csv: ^6.0.0
  
  # Additional utilities
  provider: ^6.1.0
  intl: ^0.19.0
  uuid: ^4.1.0
```

**Versions to verify:**
- firebase_core: `^2.25.0` or later
- cloud_firestore: `^4.15.0` or later
- firebase_auth: `^4.17.0` or later
- firebase_storage: `^11.7.0` or later
- cloud_functions: `^4.7.0` or later
- image_picker: `^1.1.0` or later
- file_picker: `^6.1.0` or later
- csv: `^6.0.0` or later

### 2.2 Run Pub Get

```bash
flutter clean
flutter pub get
```

**Expected Output:**
```
Running "flutter pub get" in /workspaces/aura-sphere-pro...
...
Running "flutter pub get" in /workspaces/aura-sphere-pro/functions...
...
✓ Fetched X packages
```

**Checklist:**
- [ ] `flutter clean` completed
- [ ] `flutter pub get` completed without errors
- [ ] All packages resolved
- [ ] pubspec.lock updated

---

## Phase 3: Firebase Configuration ✅

### 3.1 Verify Firebase Setup

```bash
# Check Firebase initialization
firebase list

# Expected: Project listed with status ACTIVE
```

**Checklist:**
- [ ] Firebase project active
- [ ] Firebase CLI authenticated (`firebase login` if needed)
- [ ] Emulator running (optional): `firebase emulators:start`

### 3.2 Verify Firestore & Storage

```bash
# Check Firestore enabled
firebase firestore:list-indexes

# Check Storage bucket
firebase storage:list
```

**Checklist:**
- [ ] Firestore database exists
- [ ] Storage bucket exists
- [ ] Rules files present:
  - [ ] `firestore.rules`
  - [ ] `storage.rules`

---

## Phase 4: Cloud Functions Deployment ✅

### 4.1 Verify Functions Structure

```bash
# List functions
ls -la functions/src/

# Expected files:
# - index.ts
# - expenses/
#   - onExpenseApproved.ts
#   - onExpenseApprovedInventory.ts
# - ai/
# - ocr/
# - billing/
# - etc.
```

**Checklist:**
- [ ] `functions/src/expenses/onExpenseApproved.ts` exists (130+ lines)
- [ ] `functions/src/expenses/onExpenseApprovedInventory.ts` exists (190+ lines)
- [ ] Both functions exported in `functions/src/index.ts`

### 4.2 Build Functions

```bash
cd /workspaces/aura-sphere-pro/functions

# Install dependencies
npm install

# Build TypeScript
npm run build

# Verify build
ls -la lib/
```

**Expected Output:**
```
lib/
├── index.js
├── expenses/
│   ├── onExpenseApproved.js
│   └── onExpenseApprovedInventory.js
└── (other domains)
```

**Checklist:**
- [ ] `npm install` completed
- [ ] `npm run build` succeeded
- [ ] `functions/lib/` directory created
- [ ] `functions/lib/index.js` exists
- [ ] No TypeScript errors

### 4.3 Deploy Cloud Functions

```bash
cd /workspaces/aura-sphere-pro

# Deploy all functions
firebase deploy --only functions

# Or specific function
firebase deploy --only functions:onExpenseApproved
firebase deploy --only functions:onExpenseApprovedInventory
```

**Expected Output:**
```
✔ functions[onExpenseApproved(us-central1)] Successful update operation.
✔ functions[onExpenseApprovedInventory(us-central1)] Successful update operation.
✔ functions[...other functions...] Successful update operation.

✨ Deploy complete!
```

**Checklist:**
- [ ] Functions deployed successfully
- [ ] No build errors
- [ ] Both expense functions listed in output
- [ ] Status shows "Successful update operation"

### 4.4 Verify Functions in Console

```bash
# Check deployed functions
gcloud functions list --filter="runtime=nodejs*"

# Get function details
gcloud functions describe onExpenseApproved --region=us-central1
```

**Checklist:**
- [ ] Functions appear in `gcloud functions list`
- [ ] Status: ACTIVE
- [ ] Trigger: Firestore or HTTPS
- [ ] Region: us-central1

---

## Phase 5: Firestore Rules Deployment ✅

### 5.1 Verify Firestore Rules

Check `firestore.rules` includes:

```firestore
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    
    // User ownership validation
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      // Expense access control
      match /expenses/{expenseId} {
        allow read: if request.auth.uid == userId || 
                       isAdmin() ||
                       resource.data.approverId == request.auth.uid;
        allow create: if request.auth.uid == userId && 
                        isValidExpenseCreate();
        allow update: if (request.auth.uid == userId || isAdmin()) && 
                        isValidExpenseUpdate();
        
        // Immutable audit trail
        match /audit/{auditId} {
          allow read: if request.auth.uid == userId;
          allow create: if request.auth.uid == userId || isAdmin();
        }
        
        // Immutable history
        match /_history/{historyId} {
          allow read: if request.auth.uid == userId;
          allow create: if request.auth.uid == userId || isAdmin();
        }
      }
    }
  }
}
```

**Checklist:**
- [ ] `firestore.rules` file present
- [ ] Expense rules included
- [ ] Audit subcollection rules included
- [ ] History subcollection rules included

### 5.2 Deploy Firestore Rules

```bash
firebase deploy --only firestore:rules
```

**Expected Output:**
```
✔ firestore: Rules updated successfully

✨ Deploy complete!
```

**Checklist:**
- [ ] Rules deployed successfully
- [ ] No validation errors
- [ ] Status shows "Rules updated successfully"

---

## Phase 6: Storage Rules Deployment ✅

### 6.1 Verify Storage Rules

Check `storage.rules` includes:

```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    // User files in their own directory
    match /users/{userId}/{allPaths=**} {
      allow read, write: if request.auth.uid == userId;
    }
    
    // Expense receipts
    match /expenses/receipts/{userId}/{fileName} {
      allow read, write: if request.auth.uid == userId;
      allow read: if isAdmin();
    }
  }
}
```

**Checklist:**
- [ ] `storage.rules` file present
- [ ] User path rules included
- [ ] Expense receipt rules included
- [ ] File size limits set (5-10 MB)

### 6.2 Deploy Storage Rules

```bash
firebase deploy --only storage:rules
```

**Expected Output:**
```
✔ storage: Rules updated successfully

✨ Deploy complete!
```

**Checklist:**
- [ ] Storage rules deployed
- [ ] No validation errors

---

## Phase 7: Flutter App Compilation ✅

### 7.1 Code Analysis

```bash
flutter analyze
```

**Expected Output:**
```
✓ No issues found!
```

**Checklist:**
- [ ] No linting errors
- [ ] No warnings
- [ ] Code formatting valid

### 7.2 Test Compilation

```bash
# Test Android
flutter build apk --debug 2>&1 | head -50

# Or test iOS
flutter build ios --debug 2>&1 | head -50

# Or web
flutter build web --debug 2>&1 | head -50
```

**Checklist:**
- [ ] Build succeeds
- [ ] No compilation errors
- [ ] All dependencies resolved

### 7.3 Run App

```bash
flutter run
```

**Expected Output:**
```
✓ Built build/app/outputs/flutter-apk/app-debug.apk (XX MB).
...
Launching lib/main.dart on [Device]...
```

**Checklist:**
- [ ] App launches successfully
- [ ] No runtime errors in console
- [ ] UI displays without crashes

---

## Phase 8: Manual Test Flow

### Test 1: Create Expense via Scanner ✅

**Steps:**
1. Launch app on device/emulator
2. Navigate to Expenses section
3. Tap "Scan Receipt" button (camera icon)
4. Take/select photo of receipt
5. Wait for upload and OCR processing
6. Review parsed data:
   - [ ] Merchant extracted
   - [ ] Amount detected
   - [ ] Date parsed
   - [ ] VAT calculated (if applicable)
7. Tap "Confirm & Save"
8. Verify expense appears in list with "draft" status

**Expected Result:**
- Expense created in Firestore: `users/{uid}/expenses/{id}`
- Status: "draft"
- Photo URL in photoUrls array
- All fields populated

**Verification Query:**
```dart
// In Firestore Console
Collection: users/{your-uid}/expenses
Filter: status == "draft"
// Should see your new expense
```

---

### Test 2: Manual Expense Creation ✅

**Steps:**
1. In ExpenseListScreen, tap "Add Manual" button
2. Enter:
   - [ ] Merchant: "Test Corp"
   - [ ] Amount: 100.00
   - [ ] Currency: EUR
   - [ ] Category: "Supplies"
   - [ ] Payment Method: "Card"
3. Tap "Save"
4. Verify expense appears in list

**Expected Result:**
- Expense created with "draft" status
- No photos attached
- VAT calculated (20% for EUR)

---

### Test 3: Review & Submit for Approval ✅

**Steps:**
1. In ExpenseListScreen, find your draft expense
2. Tap the expense card to open details
3. Edit if needed (merchant, amount, etc.)
4. Tap "Submit for Approval"
5. Status changes to "pending_approval"
6. Verify audit entry created

**Expected Result:**
- Status changed: draft → pending_approval
- Audit entry in `users/{uid}/expenses/{id}/audit/{auditId}`:
  ```json
  {
    "action": "submitted",
    "actor": "{your-uid}",
    "ts": "2025-11-27T...",
    "notes": "Submitted for approval"
  }
  ```

**Verification Query:**
```dart
// In Firestore Console
Path: users/{your-uid}/expenses/{expense-id}/audit
// Should see entry with action="submitted"
```

---

### Test 4: Approver Account Reviews & Approves ✅

**Steps:**
1. Sign out from current account
2. Sign in with **manager/approver account** (different user)
3. Navigate to Expenses section
4. Filter by "Pending Approval"
5. Find the expense from Test 3
6. Tap to open details
7. Tap "Approve" button
8. Enter approval note: "Looks good"
9. Confirm approval

**Expected Results:**

**A. Status Updated:**
- Status: pending_approval → approved
- approverId: set to approver's UID
- approvedNote: "Looks good"

**B. Cloud Function Triggered (onExpenseApproved):**
- FCM notification sent to submitter (if configured)
- AuraTokens awarded (10 tokens)
- Audit entry created in auraTokenTransactions

**C. Audit Trail:**
```
users/{submitter-uid}/expenses/{id}/audit/
{
  "action": "approved",
  "actor": "{approver-uid}",
  "notes": "Looks good",
  "ts": "2025-11-27T..."
}
```

**D. Reward Transaction:**
```
users/{submitter-uid}/auraTokenTransactions/{txId}
{
  "type": "reward",
  "action": "expense_approved",
  "amount": 10,
  "expenseId": "{expense-id}",
  "merchant": "Test Corp",
  "transactionAmount": 100.0,
  "createdAt": "2025-11-27T..."
}
```

**E. User Balance Updated:**
```
users/{submitter-uid}
{
  "auraTokens": <previous> + 10
}
```

**Verification Queries:**
```bash
# Check notification (if Firebase Messaging configured)
firebase functions:log --follow | grep "Sending FCM"

# Check auraTokenTransactions
Firestore Console → users/{submitter-uid}/auraTokenTransactions
// Should see entry with type="reward"

# Check user balance
Firestore Console → users/{submitter-uid}
// auraTokens field should be incremented
```

---

### Test 5: Test Rejection Flow ✅

**Steps:**
1. Create another draft expense
2. Submit for approval
3. As approver, tap "Reject"
4. Enter rejection reason: "Missing receipt"
5. Confirm rejection

**Expected Results:**
- Status: pending_approval → rejected
- approverId: set to approver's UID
- approvedNote: "Missing receipt"
- Audit entry created

**Verification:**
```
users/{uid}/expenses/{id}/audit/
// Should have entry with action="rejected"
```

---

### Test 6: CSV Import ✅

**Steps:**
1. Create CSV file with content:
   ```csv
   merchant,date,amount,currency,category,vatrate,paymentmethod
   Acme Corp,2025-11-27,100.00,EUR,Supplies,0.20,card
   Coffee Shop,2025-11-26,5.50,USD,Food,0.00,cash
   Taxi Service,2025-11-25,25.00,EUR,Transport,0.20,card
   ```

2. In ExpenseListScreen, tap "Import CSV" button
3. Select the CSV file
4. Review preview (should show 3 rows)
5. Confirm import
6. Verify 3 new expenses created

**Expected Results:**
- 3 expenses created with "draft" status
- All fields parsed from CSV
- VAT calculated for each row
- Audit entry for each expense

**Verification:**
```
Firestore Console → users/{uid}/expenses
// Filter by createdAt > [import-time]
// Should see 3 new expenses
```

---

### Test 7: Monthly CSV Export ✅

**Steps:**
1. In ExpenseListScreen, tap "Reports" or navigate to Reports section
2. Select "Export Monthly" for November 2025
3. Choose format: CSV
4. Download file

**Expected Results:**
- CSV file downloads with name: `expenses_2025_11.csv`
- Contains header row: `merchant,date,amount,currency,vat,category,status,paymentMethod`
- Contains all your November expenses
- Summary section at bottom with totals

**File Structure:**
```csv
merchant,date,amount,currency,vat,category,status,paymentMethod
Test Corp,2025-11-27,100.00,EUR,20.00,Supplies,draft,card
...
SUMMARY
Total Expenses: 3
Total VAT: 25.50
Total Amount: 130.50
Average Expense: 43.50
```

---

### Test 8: Link Expense to Invoice ✅

**Steps:**
1. In ExpenseListScreen, find an approved expense
2. Tap the expense card
3. Tap "Link to Invoice" button
4. Enter/select invoice ID: "INV-001"
5. Confirm

**Expected Results:**
- invoiceId field updated: "INV-001"
- Audit entry created: action="linked_to_invoice"

**Verification:**
```
Firestore Console → users/{uid}/expenses/{id}
// invoiceId field should equal "INV-001"
```

---

### Test 9: Inventory Expense Workflow ✅

**Steps:**
1. Create new expense:
   - Merchant: "Supplier Inc"
   - Amount: 500.00
   - Category: "Inventory" (important!)
   - projectId: "warehouse_project" (if exists)

2. Submit for approval
3. As approver, approve the expense
4. Wait 3-5 seconds for Cloud Function

**Expected Results:**

**A. Expense Status:**
- Status: approved
- approverId: set

**B. Stock Movement Created:**
```
users/{uid}/inventory_movements/{movementId}
{
  "type": "purchase",
  "merchant": "Supplier Inc",
  "amount": 500.0,
  "vat": 100.0,
  "currency": "EUR",
  "date": "2025-11-27",
  "projectId": "warehouse_project",
  "expenseId": "{expense-id}",
  "status": "completed",
  "createdAt": "2025-11-27T..."
}
```

**C. Project Inventory Updated:**
```
users/{uid}/projects/warehouse_project
{
  "inventory": {
    "totalSpent": 500.0,  // ← incremented
    "totalVAT": 100.0,    // ← incremented
    "lastUpdated": "2025-11-27T..."
  }
}
```

**D. Audit Entry:**
```
users/{uid}/expenses/{id}/audit/
{
  "action": "inventory_movement_created",
  "movementId": "{movementId}",
  "ts": "2025-11-27T..."
}
```

**Verification Queries:**
```bash
# Check inventory movements
Firestore Console → users/{uid}/inventory_movements
// Should see entry with type="purchase"

# Check project totals
Firestore Console → users/{uid}/projects/{projectId}
// inventory.totalSpent should be 500.0
```

---

### Test 10: Audit Trail & History Inspection ✅

**Steps:**
1. Find an expense that's been through multiple changes
2. Tap "View Audit Trail" (if available in UI)
3. Review all entries showing:
   - Created
   - Submitted
   - Approved
   - Any other changes

**Expected Results:**
- Chronologically ordered audit entries
- Each entry shows: action, actor, timestamp, notes
- Field changes captured in _history subcollection

**Sample Audit Trail:**
```
2025-11-27 10:00:00 - CREATED by user_123
  Initial creation, Status: draft

2025-11-27 10:05:00 - SUBMITTED by user_123
  Status changed: draft → pending_approval

2025-11-27 10:10:00 - APPROVED by manager_456
  Status changed: pending_approval → approved
  Note: "Looks good"

2025-11-27 10:10:01 - REWARD_AWARDED by system
  10 AuraTokens awarded
  Expense: Test Corp (EUR 100.00)
```

---

## Phase 9: Firebase Logs Verification ✅

### 9.1 Check Cloud Function Logs

```bash
# View real-time logs
firebase functions:log --follow

# Or use gcloud
gcloud functions logs read onExpenseApproved --limit 50

# Expected output:
# Sending FCM notification to user_123...
# Awarded 10 AuraTokens to user_123
# Expense approved audit entry created
```

### 9.2 Check Firestore Activity

```bash
# View write statistics
firebase firestore:usage 2025-11

# Expected output:
# Entities written: X
# Entities read: Y
```

**Checklist:**
- [ ] Cloud Functions executing
- [ ] No error logs
- [ ] Expected operations logged
- [ ] Audit entries created

---

## Phase 10: Performance & Edge Cases ✅

### 10.1 Large File Upload
- [ ] Upload 5MB receipt image → succeeds
- [ ] Storage quota not exceeded
- [ ] OCR completes within 30 seconds

### 10.2 Concurrent Updates
- [ ] Two managers open same expense → no conflicts
- [ ] One approves → other sees updated status
- [ ] No duplicate audit entries

### 10.3 CSV Import Edge Cases
- [ ] Import 100+ rows → completes
- [ ] Duplicate merchants → all imported
- [ ] Invalid dates → skipped with error message
- [ ] Missing amount column → import fails with clear error

### 10.4 VAT Calculation
- [ ] EUR (20%) → VAT correct
- [ ] USD (0%) → VAT = 0
- [ ] GBP (20%) → VAT correct
- [ ] Manual VAT override → respected

---

## Phase 11: Security Verification ✅

### 11.1 Cross-User Isolation
- [ ] User A cannot read User B's expenses
- [ ] User A cannot approve User B's expenses
- [ ] Only managers/admins can see others' expenses

**Test:**
```bash
# As User A, query Firestore
db.collection('users').doc(userB_uid).collection('expenses').get()
# Should fail with permission denied
```

### 11.2 Audit Immutability
- [ ] Audit entries cannot be modified
- [ ] Audit entries cannot be deleted
- [ ] History is permanent

**Test:**
```bash
# Try to update audit entry
db.collection('users').doc(uid)
  .collection('expenses').doc(expId)
  .collection('audit').doc(auditId)
  .update({...})
# Should fail: document is immutable
```

### 11.3 Approver Authorization
- [ ] Only assigned approver can approve
- [ ] Only users with role="manager" can approve
- [ ] Approver must be within approval limit

---

## Phase 12: Deployment Checklist ✅

**Pre-Production:**
- [ ] All tests passed
- [ ] No console errors
- [ ] Firestore rules deployed
- [ ] Cloud Functions deployed
- [ ] Storage rules deployed
- [ ] Security verified

**Production:**
- [ ] firebase deploy --only firestore:rules
- [ ] firebase deploy --only storage:rules
- [ ] firebase deploy --only functions
- [ ] flutter build apk --release (Android)
- [ ] flutter build ios --release (iOS)
- [ ] Upload to app stores

---

## Summary: Complete Test Workflow

```
┌─────────────────────────────────────────────────────────────┐
│ 1. Setup Dependencies & Files (15 min)                      │
│    ✓ pubspec.yaml updated                                   │
│    ✓ flutter pub get                                         │
│    ✓ Directories created                                     │
└─────────────┬───────────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────────────────────────────┐
│ 2. Deploy Backend (10 min)                                  │
│    ✓ firebase deploy --only functions                       │
│    ✓ firebase deploy --only firestore:rules                 │
│    ✓ firebase deploy --only storage:rules                   │
└─────────────┬───────────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────────────────────────────┐
│ 3. Run App (5 min)                                          │
│    ✓ flutter run                                             │
│    ✓ No compilation errors                                  │
│    ✓ App launches                                           │
└─────────────┬───────────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────────────────────────────┐
│ 4. Manual Testing (45 min)                                  │
│                                                              │
│ Test 1: Scan Receipt → OCR → Parse ✓                        │
│ Test 2: Manual Entry ✓                                      │
│ Test 3: Submit for Approval ✓                               │
│ Test 4: Approve (check FCM + AuraToken) ✓                   │
│ Test 5: Reject ✓                                            │
│ Test 6: CSV Import ✓                                        │
│ Test 7: Monthly Export ✓                                    │
│ Test 8: Link to Invoice ✓                                   │
│ Test 9: Inventory Workflow ✓                                │
│ Test 10: Audit Trail ✓                                      │
└─────────────┬───────────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────────────────────────────┐
│ 5. Verification (10 min)                                    │
│    ✓ Firestore rules enforced                              │
│    ✓ Cloud Functions logged                                 │
│    ✓ Security verified                                      │
└─────────────┬───────────────────────────────────────────────┘
              │
┌─────────────▼───────────────────────────────────────────────┐
│ ✅ READY FOR PRODUCTION                                     │
└─────────────────────────────────────────────────────────────┘

Total Time: ~75 minutes
```

---

## Troubleshooting

### Issue: "visionOcr function not found"
**Solution:**
1. Verify function deployed: `firebase deploy --only functions:visionOcr`
2. Check Cloud Function logs for errors
3. Verify `functions/src/index.ts` exports the function

### Issue: "Permission denied" when reading expense
**Solution:**
1. Verify user is logged in: `firebase.auth().currentUser`
2. Check Firestore rules allow read
3. Verify expense belongs to current user

### Issue: CSV import fails
**Solution:**
1. Check CSV headers match expected format
2. Verify amount and merchant columns present
3. Check file size < 10MB
4. Review error message in app

### Issue: Cloud Function not triggering
**Solution:**
1. Check function is deployed and active
2. Verify Firestore rules allow write
3. Review Cloud Function logs: `firebase functions:log`
4. Check trigger path matches `users/{userId}/expenses/{expenseId}`

### Issue: FCM notifications not showing
**Solution:**
1. Verify FCM tokens sent from app
2. Check FCM configured in Firebase Console
3. Ensure user has notification permission
4. Review Cloud Function logs for notification errors

---

## Reference Documentation

- [Expense System Integration Guide](./docs/expense_system_integration.md)
- [Architecture Overview](./docs/architecture.md)
- [API Reference](./docs/api_reference.md)
- [Security Standards](./docs/security_standards.md)
- [Cloud Functions Reference](./docs/invoice_cloud_functions_guide.md)

---

**✅ CHECKLIST COMPLETE** — Ready for production deployment!
