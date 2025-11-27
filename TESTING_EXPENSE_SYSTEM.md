# Testing Checklist: Expense Scanner & Invoice Linking

## Pre-Testing Setup

### 1. Install Dependencies ✅

```bash
# From project root
flutter pub get

# Install iOS pods (if testing on iOS)
cd ios && pod install && cd ..

# Verify dependencies
flutter pub list
```

**Expected Output:**
```
aurasphere_pro depends on:
  cloud_firestore ^5.5.0
  cloud_functions ^5.0.4
  firebase_auth ^5.1.0
  firebase_core ^3.6.0
  firebase_storage ^12.3.1
  google_ml_kit ^0.7.2
  image_picker ^0.8.7
  permission_handler ^11.0.1
  provider ^6.0.5
  (... other dependencies)
```

**Checklist:**
- [ ] `flutter pub get` completes without errors
- [ ] No dependency conflicts reported
- [ ] iOS pods installed successfully (if iOS)
- [ ] Android gradle builds (if Android)

---

## Configuration Verification

### 2. Routes Registration ✅

**File:** `lib/config/app_routes.dart`

**Verify Route Exists:**
```dart
static const String expenseScanner = '/expense-scanner';
```

**Status:** ✅ CONFIRMED in app_routes.dart

**Next Steps:** Register route handler in `onGenerateRoute()` method.

**Checklist:**
- [ ] Route constant `expenseScanner` defined
- [ ] Route handler added to `onGenerateRoute()`
- [ ] ExpenseScannerScreen imported

---

### 3. Provider Registration ✅

**File:** `lib/app/app.dart`

**Current Providers:**
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => UserProvider(authService)),
    ChangeNotifierProvider(create: (_) => CrmProvider()),
    ChangeNotifierProvider(create: (_) => CrmInsightsProvider()),
    ChangeNotifierProvider(create: (_) => TaskProvider()),
    ChangeNotifierProvider(create: (_) => InvoiceProvider()),
    // NEED TO ADD: ExpenseProvider
  ],
  // ...
)
```

**Action Required:** Add ExpenseProvider to the providers list

**Checklist:**
- [ ] ExpenseProvider imported in app.dart
- [ ] ExpenseProvider added to MultiProvider list
- [ ] No provider initialization errors
- [ ] All providers accessible via context.read<>()

---

## Setup Actions Required

### ACTION 1: Add ExpenseProvider to app.dart

**File:** `lib/app/app.dart`

**Required Changes:**
1. Import ExpenseProvider
2. Add to MultiProvider list
3. Verify compilation

### ACTION 2: Register ExpenseScanner Route

**File:** `lib/config/app_routes.dart`

**Required Changes:**
1. Import ExpenseScannerScreen
2. Add case for `expenseScanner` route
3. Return MaterialPageRoute with screen

### ACTION 3: Verify Firebase Emulator (Optional)

For local testing without deploying to Firebase:
```bash
# Terminal 1: Start emulator
firebase emulators:start

# Terminal 2: Run app with emulator
flutter run --dart-define=USE_EMULATOR=true
```

---

## Testing Phase 1: Dependencies & Setup

### Test 1.1: Build & Run App

```bash
# Clean build
flutter clean
flutter pub get

# Run on device/emulator
flutter run -v
```

**Expected Outcome:**
- ✅ App builds without errors
- ✅ App launches successfully
- ✅ Dashboard screen appears
- ✅ No provider initialization errors in console

**Checklist:**
- [ ] `flutter run` completes with exit code 0
- [ ] App starts without crashes
- [ ] Console shows no provider errors
- [ ] Dashboard renders correctly

### Test 1.2: Verify Routes

```dart
// In app, navigate to expense scanner
Navigator.of(context).pushNamed(AppRoutes.expenseScanner);
```

**Expected Outcome:**
- ✅ ExpenseScannerScreen loads
- ✅ Camera preview visible
- ✅ UI renders without errors

**Checklist:**
- [ ] Route navigation works
- [ ] ExpenseScannerScreen displays
- [ ] No black screens or errors

---

## Testing Phase 2: Permissions

### Test 2.1: Camera Permission

**Device: Android/iOS**

**Steps:**
1. Run app: `flutter run`
2. Navigate to `/expenses/scan` (ExpenseScannerScreen)
3. App should request camera permission
4. Grant permission in system dialog

**Expected Behavior:**
```
┌─────────────────────────────────────┐
│  Allow AuraSphere to access camera? │
│                                     │
│              [Deny] [Allow]         │
└─────────────────────────────────────┘
```

**Checklist:**
- [ ] Camera permission dialog appears
- [ ] Grant permission accepted
- [ ] Camera preview starts after permission granted
- [ ] Can switch between camera and gallery

### Test 2.2: Gallery Permission

**Device: Android/iOS**

**Steps:**
1. On ExpenseScannerScreen, tap gallery icon
2. App requests photo library permission
3. Grant permission in system dialog

**Expected Behavior:**
```
┌──────────────────────────────────────┐
│  Allow AuraSphere to access photos?  │
│                                      │
│               [Deny] [Allow]         │
└──────────────────────────────────────┘
```

**Checklist:**
- [ ] Gallery permission dialog appears
- [ ] Permission granted successfully
- [ ] Photo picker opens
- [ ] Can select photo from gallery

---

## Testing Phase 3: OCR & Expense Creation

### Test 3.1: Scan Receipt with ML Kit OCR

**Setup:**
- Real receipt or test image with text
- Camera focused and clear
- Good lighting

**Steps:**
1. Launch app
2. Navigate to `/expenses/scan`
3. Grant camera permission
4. Position camera over receipt
5. Tap "Capture" button
6. Review detected text in fields

**Expected Outcome:**

```
┌────────────────────────────────────┐
│  Receipt Details (Auto-Detected)   │
├────────────────────────────────────┤
│                                    │
│ 🏪 Merchant:  [Acme Corp        ] │
│ 💰 Amount:    [$49.99           ] │
│ 💱 Currency:  [USD              ] │
│ 📅 Date:      [27.11.2025       ] │
│ 🧾 VAT:       [$4.99            ] │
│ 📝 Category:  [Supplies         ] │
│                                    │
│      [Cancel]  [Enhanced OCR]     │
│                   [Save]           │
└────────────────────────────────────┘
```

**Manually Verify Values:**

| Field | Expected | Actual | ✅ |
|-------|----------|--------|-----|
| Merchant | Store name | | [ ] |
| Amount | Price total | | [ ] |
| Currency | 3-letter code | | [ ] |
| Date | Receipt date | | [ ] |
| VAT | Tax amount | | [ ] |
| Image URL | Firebase Storage URL | | [ ] |

**Checklist:**
- [ ] Camera captures image
- [ ] Text detected and displayed
- [ ] Merchant name recognized
- [ ] Amount parsed correctly
- [ ] Currency detected (USD/EUR/etc)
- [ ] Date parsed in correct format
- [ ] VAT amount extracted
- [ ] All fields editable
- [ ] Enhanced OCR toggle visible

---

### Test 3.2: Enhanced OCR with Cloud Vision (Optional)

**Prerequisites:**
- Google Cloud Vision API configured
- `visionOcr` Cloud Function deployed
- Valid Google Cloud credentials

**Steps:**
1. Capture receipt as in Test 3.1
2. Toggle "Enhanced OCR" switch
3. Wait for Cloud Vision processing
4. Compare results with ML Kit

**Expected Behavior:**
- Cloud Vision refines OCR results
- Confidence scores higher for text blocks
- Results merged intelligently
- Fallback to ML Kit if API fails

**Checklist:**
- [ ] Enhanced OCR toggle works
- [ ] Loading spinner appears
- [ ] Cloud Vision processes image
- [ ] Results displayed without error
- [ ] Merchant/amount more accurate

---

### Test 3.3: Save Expense to Firestore

**Steps:**
1. Complete OCR (Test 3.1 or 3.2)
2. Verify all fields
3. Tap "Save" button
4. Watch for success notification

**Expected Behavior:**
```
Saving expense...
↓
Image uploaded to Storage
↓
Expense record created in Firestore
↓
✅ Expense saved! (Toast notification)
```

**Checklist:**
- [ ] "Saving..." indicator appears
- [ ] Image uploads to Firebase Storage
- [ ] No upload errors
- [ ] Firestore document created
- [ ] Success notification shown
- [ ] Screen dismisses or clears

---

## Testing Phase 4: Firestore Verification

### Test 4.1: Verify Firestore Structure

**Path:** `users/{uid}/expenses/{expenseId}`

**Steps:**
1. Open Firebase Console
2. Navigate to Firestore
3. Find your user ID (from app's UserProvider)
4. Check `/users/{uid}/expenses` collection

**Expected Structure:**
```firestore
Collection: users/{uid}/expenses

Document: exp_1234567890
├─ id: "exp_1234567890"
├─ userId: "user_5678"
├─ merchant: "Acme Corp"
├─ amount: 49.99
├─ currency: "USD"
├─ imageUrl: "gs://bucket/receipts/user_5678/exp_1234567890"
├─ vat: 4.99
├─ date: Timestamp(27.11.2025)
├─ category: "Supplies"
├─ notes: ""
├─ invoiceId: null
├─ isReceipt: true
├─ createdAt: Timestamp(now)
└─ updatedAt: Timestamp(now)
```

**Verification Checklist:**
- [ ] Document exists in correct path
- [ ] `id` matches document ID
- [ ] `userId` matches authenticated user
- [ ] `merchant` contains store name
- [ ] `amount` is positive number
- [ ] `currency` is 3 letters
- [ ] `imageUrl` is valid Storage URL
- [ ] `date` is valid timestamp
- [ ] `vat` is calculated correctly
- [ ] `invoiceId` is null (unlinked)
- [ ] `createdAt` timestamp set
- [ ] `updatedAt` timestamp set

### Test 4.2: Verify Image Upload

**Steps:**
1. Get `imageUrl` from expense document
2. Open URL in browser
3. Verify receipt image displays

**Expected Outcome:**
- ✅ Receipt photo displays
- ✅ Image is clear and readable
- ✅ No "Access Denied" errors
- ✅ Image metadata correct (size, type)

**Checklist:**
- [ ] Storage path follows pattern: `receipts/{userId}/{expenseId}`
- [ ] Image accessible without authentication
- [ ] Image format is JPG/PNG
- [ ] File size reasonable (<5MB)

### Test 4.3: Verify Multiple Expenses

**Steps:**
1. Repeat Test 3 three more times with different receipts
2. Check Firestore shows all expenses

**Expected Outcome:**
```firestore
Collection: users/{uid}/expenses
├─ exp_001 (Acme Corp, $49.99)
├─ exp_002 (Starbucks, $5.50)
├─ exp_003 (Amazon, $124.99)
└─ exp_004 (Shell Gas, $55.00)
```

**Checklist:**
- [ ] All expenses save successfully
- [ ] Document IDs unique
- [ ] No duplicate entries
- [ ] All amounts correct
- [ ] All merchants different

---

## Testing Phase 5: Provider State Management

### Test 5.1: Load Expenses in Provider

**Code Test:**
```dart
// In widget or test
final provider = context.read<ExpenseProvider>();
await provider.loadExpenses();

final expenses = provider.expenses;
final count = expenses.length;

print('Loaded $count expenses');
for (final exp in expenses) {
  print('- ${exp.merchant}: \$${exp.amount}');
}
```

**Expected Output:**
```
Loaded 4 expenses
- Acme Corp: $49.99
- Starbucks: $5.50
- Amazon: $124.99
- Shell Gas: $55.00
```

**Checklist:**
- [ ] `loadExpenses()` completes without error
- [ ] All expenses loaded from Firestore
- [ ] Expenses ordered by `createdAt` (newest first)
- [ ] All fields properly deserialized

### Test 5.2: Get Unlinked Expenses

**Code Test:**
```dart
final provider = context.read<ExpenseProvider>();
final unlinked = provider.getUnlinkedExpenses();

print('Unlinked: ${unlinked.length}');
for (final exp in unlinked) {
  print('- ${exp.merchant}: \$${exp.amount} (invoiceId: ${exp.invoiceId})');
}
```

**Expected Output:**
```
Unlinked: 4
- Acme Corp: $49.99 (invoiceId: null)
- Starbucks: $5.50 (invoiceId: null)
- Amazon: $124.99 (invoiceId: null)
- Shell Gas: $55.00 (invoiceId: null)
```

**Checklist:**
- [ ] All 4 expenses returned as unlinked
- [ ] All have `invoiceId: null`
- [ ] Total count matches expectations

### Test 5.3: Calculate Total Unlinked

**Code Test:**
```dart
final provider = context.read<ExpenseProvider>();
final total = provider.getTotalUnlinked();

print('Total unlinked: \$${total.toStringAsFixed(2)}');
// Expected: $235.48
```

**Expected Output:**
```
Total unlinked: $235.48
```

**Checklist:**
- [ ] Total calculated correctly
- [ ] Sum of all unlinked amounts
- [ ] Matches manual calculation

---

## Testing Phase 6: Invoice Linking

### Test 6.1: Create Invoice

**Steps:**
1. Navigate to invoice creation screen
2. Enter invoice details:
   - Client name: "Test Client"
   - Invoice number: "INV-001"
   - Date: today
3. Tap "Create Invoice"

**Expected Outcome:**
- ✅ Invoice created in Firestore
- ✅ Document ID returned
- ✅ Initial amount/total: 0 (no items yet)

**Firestore Path:** `users/{uid}/invoices/INV-001`

**Checklist:**
- [ ] Invoice document created
- [ ] All required fields populated
- [ ] Document accessible in Firestore

### Test 6.2: Attach Expenses to Invoice

**Steps:**
1. Open invoice details for INV-001
2. Tap "Attach Expenses" button
3. Dialog opens showing unlinked expenses

**Expected UI:**
```
┌───────────────────────────────┐
│  Attach Expenses to Invoice   │
├───────────────────────────────┤
│ [Search...]                   │
├───────────────────────────────┤
│ ☐ Acme Corp         $49.99    │
│ ☐ Starbucks          $5.50    │
│ ☐ Amazon           $124.99    │
│ ☐ Shell Gas         $55.00    │
├───────────────────────────────┤
│ 0 selected • Total: $0.00     │
├───────────────────────────────┤
│        [Cancel]  [Attach]     │
└───────────────────────────────┘
```

**Checklist:**
- [ ] Dialog shows all unlinked expenses
- [ ] Search field functional
- [ ] Checkboxes present and clickable
- [ ] Total updates as items selected

### Test 6.3: Select & Attach Multiple Expenses

**Steps:**
1. In attachment dialog, select:
   - ☑ Acme Corp ($49.99)
   - ☑ Amazon ($124.99)
2. Watch "Total" update
3. Tap "Attach" button

**Expected Behavior:**
```
Before selection:
0 selected • Total: $0.00

After selecting 2:
2 selected • Total: $174.98
↓
[Taps Attach]
↓
Loading...
↓
✅ 2 expenses attached to invoice
```

**Firestore Verification:**

Check each attached expense:
```firestore
Document: exp_acme
├─ invoiceId: "INV-001"  ← NEW!
├─ updatedAt: Timestamp(now)
└─ (other fields unchanged)

Document: exp_amazon
├─ invoiceId: "INV-001"  ← NEW!
├─ updatedAt: Timestamp(now)
└─ (other fields unchanged)
```

**Checklist:**
- [ ] Dialog closes after attachment
- [ ] Success notification appears
- [ ] Both expenses marked with invoiceId
- [ ] Firestore updated correctly
- [ ] updatedAt timestamp set

### Test 6.4: Verify Invoice Totals Updated

**Steps:**
1. Check invoice details for INV-001
2. Verify attached expenses show as line items

**Expected Structure in Firestore:**
```firestore
Document: INV-001
├─ clientName: "Test Client"
├─ invoiceNumber: "INV-001"
├─ items: [
│   {
│     description: "Acme Corp",
│     quantity: 1,
│     unitPrice: 49.99,
│     total: 49.99
│   },
│   {
│     description: "Amazon",
│     quantity: 1,
│     unitPrice: 124.99,
│     total: 124.99
│   }
│ ]
├─ subtotal: 174.98
├─ tax: 0  (or calculated based on VAT)
└─ total: 174.98
```

**Checklist:**
- [ ] Invoice shows attached expenses as items
- [ ] Subtotal = sum of expense amounts
- [ ] Total calculated correctly
- [ ] VAT included if applicable

### Test 6.5: Verify Unlinked Expenses Updated

**Steps:**
1. Reload unlinked expenses list
2. Verify only 2 remain unlinked

**Expected State:**
```dart
final unlinked = provider.getUnlinkedExpenses();
// Returns 2 items:
// - Starbucks: $5.50
// - Shell Gas: $55.00

final linked = provider.getTotalLinked();
// $174.98

final unlinkedTotal = provider.getTotalUnlinked();
// $60.50
```

**Checklist:**
- [ ] 2 unlinked expenses remain
- [ ] 2 linked expenses in invoice
- [ ] Unlinked total updated correctly
- [ ] Linked total matches attached

---

## Testing Phase 7: Advanced Operations

### Test 7.1: Detach Expense from Invoice

**Steps:**
1. View invoice INV-001 details
2. Find attached expense (e.g., Acme Corp)
3. Tap "Detach" or delete button

**Expected Behavior:**
```
Before detach:
- Expense is in invoice items
- invoiceId: "INV-001"

After detach:
- Expense removed from items
- invoiceId: null
- Expense reappears in unlinked

In Firestore:
Document: exp_acme
├─ invoiceId: null  ← RESET!
└─ updatedAt: Timestamp(now)
```

**Checklist:**
- [ ] Expense detached from invoice
- [ ] Invoice items updated
- [ ] Firestore invoiceId set to null
- [ ] Expense reappears in unlinked list

### Test 7.2: Search in Attachment Dialog

**Steps:**
1. Open attachment dialog again
2. Unlinked: Starbucks, Shell Gas, Amazon, Acme
3. Type "coffee" in search field

**Expected Behavior:**
```
Search: "coffee"
↓
Results:
☐ Starbucks (matches notes or merchant containing "coffee")
```

**Checklist:**
- [ ] Search filters by merchant name
- [ ] Search filters by notes field
- [ ] Results update in real-time
- [ ] Case-insensitive search

### Test 7.3: Filter by Category

**Steps:**
1. Test category filtering in expense list
2. Filter to "Office Supplies"

**Expected Output:**
```
Category: Office Supplies
├─ Amazon: $124.99
└─ (other supplies items)
```

**Checklist:**
- [ ] Filter narrows results
- [ ] Only selected category shown
- [ ] Can clear filter

### Test 7.4: Date Range Filter

**Steps:**
1. Filter expenses by date range
2. From: 25.11.2025, To: 27.11.2025

**Expected:**
- All expenses within range shown
- Expenses outside range hidden

**Checklist:**
- [ ] Date picker works
- [ ] Range filtering accurate
- [ ] Can clear date filters

---

## Testing Phase 8: Error Handling

### Test 8.1: Network Error During Save

**Scenario:** Turn off internet, then save expense

**Expected Behavior:**
```
Saving...
↓
❌ Error: Network unavailable
↓
[Dismiss] button shown
```

**Checklist:**
- [ ] Error message displayed clearly
- [ ] User can retry
- [ ] App doesn't crash
- [ ] State preserved for retry

### Test 8.2: Storage Upload Failure

**Scenario:** Firebase Storage permission denied

**Expected Behavior:**
```
Uploading image...
↓
❌ Error: Permission denied
↓
[Cancel] [Retry] shown
```

**Checklist:**
- [ ] Error caught and handled
- [ ] User informed of issue
- [ ] Can retry upload
- [ ] App remains responsive

### Test 8.3: Invalid Expense Data

**Scenario:** Submit expense with invalid amount

**Expected Behavior:**
```
Amount: [-100]
         ↓
❌ Validation Error:
   Amount must be > 0

[OK] button to dismiss
```

**Checklist:**
- [ ] Validation catches negative/zero amounts
- [ ] Error message clear
- [ ] Field highlighted
- [ ] Cannot save invalid data

### Test 8.4: Firestore Rules Enforcement

**Scenario:** Try to manually edit invoiceId via console

**Expected:** Firestore rules block the update if:
- `invoiceId` is not string or null
- Field count exceeds 16
- Other validation rules fail

**Expected Behavior:**
```firestore
Write attempt blocked:
❌ isValidExpenseUpdate() returned false
```

**Checklist:**
- [ ] Rules prevent invalid writes
- [ ] Only valid invoiceId values accepted
- [ ] Field limits enforced

---

## Testing Phase 9: Integration

### Test 9.1: Full End-to-End Flow

**Steps:**

**A. Scan Expenses**
1. Launch app
2. Navigate to `/expenses/scan`
3. Capture 3 different receipts
4. Verify all saved to Firestore

**B. Create Invoice**
1. Go to invoice creation
2. Create "INV-002"
3. Enter client details

**C. Attach Expenses**
1. Tap "Attach Expenses"
2. Select 2 of the 3 scanned expenses
3. Complete attachment

**D. Verify Totals**
1. Check invoice total = sum of 2 attached
2. Verify unlinked = 1 remaining

**E. Manage Invoice**
1. Detach one expense
2. Verify totals recalculate
3. Reattach it

**Expected Outcome:**
```
✅ 3 expenses scanned & saved
✅ Invoice created
✅ 2 expenses attached
✅ Totals correct
✅ 1 unlinked remaining
✅ Detach/reattach works
✅ All Firestore data consistent
```

**Checklist:**
- [ ] All sub-tasks pass
- [ ] No errors at any step
- [ ] Data consistency maintained
- [ ] UI responsive throughout

### Test 9.2: Multi-Invoice Linking

**Steps:**
1. Create 2 invoices: INV-001, INV-002
2. Have 4 unlinked expenses
3. Attach:
   - INV-001: expenses A, B
   - INV-002: expenses C, D
4. Verify separation

**Expected State:**
```firestore
users/{uid}/expenses:
├─ exp_A (invoiceId: "INV-001")
├─ exp_B (invoiceId: "INV-001")
├─ exp_C (invoiceId: "INV-002")
└─ exp_D (invoiceId: "INV-002")

users/{uid}/invoices:
├─ INV-001 (2 items, total: sum of A+B)
└─ INV-002 (2 items, total: sum of C+D)
```

**Checklist:**
- [ ] Expenses linked to correct invoices
- [ ] Each invoice shows correct items
- [ ] Totals separate and accurate
- [ ] No cross-contamination

---

## Testing Phase 10: Performance

### Test 10.1: Load 100 Expenses

**Setup:** Create/mock 100 expenses in Firestore

**Test:**
```dart
final provider = context.read<ExpenseProvider>();
final stopwatch = Stopwatch()..start();
await provider.loadExpenses();
stopwatch.stop();

print('Loaded 100 expenses in ${stopwatch.elapsedMilliseconds}ms');
```

**Expected Outcome:**
- ✅ Load time < 2 seconds
- ✅ No UI freeze
- ✅ Smooth scrolling

**Checklist:**
- [ ] Load time acceptable
- [ ] App responsive during load
- [ ] All items visible in list

### Test 10.2: Filter Large List

**Test:** Filter 100 expenses by category

**Expected:**
- ✅ Filter completes < 200ms
- ✅ Results display smoothly
- ✅ Scrolling smooth

**Checklist:**
- [ ] Filter performance acceptable
- [ ] No lag when selecting items

---

## Debugging Tips

### Enable Verbose Logging

```bash
flutter run -v
```

Shows all network calls, provider changes, Firestore operations.

### Check Firestore Rules Failures

```bash
# In Firebase Console:
1. Go to Firestore
2. Click "Rules" tab
3. Check "Validation Rules" section
4. Look for denied write operations
```

### Mock Data for Testing

```dart
// In test
final mockExpense = ExpenseModel(
  id: 'test_exp_1',
  userId: 'test_user',
  merchant: 'Test Store',
  amount: 100.0,
  currency: 'USD',
  imageUrl: 'gs://bucket/test.jpg',
  invoiceId: null,  // Unlinked
);

await provider.addExpense(mockExpense);
```

### Use Flutter DevTools

```bash
flutter pub global activate devtools
devtools
```

Inspect provider state, database queries, widget tree.

---

## Checklist Summary

### Setup Phase
- [ ] Dependencies installed
- [ ] Routes configured
- [ ] Providers registered
- [ ] App compiles without errors

### Permissions Phase
- [ ] Camera permission granted
- [ ] Gallery permission granted
- [ ] Permissions requested UI appears

### OCR Phase
- [ ] Receipt image captured
- [ ] Text detected and displayed
- [ ] Merchant, amount, date, VAT extracted
- [ ] Enhanced OCR works (optional)
- [ ] Image uploaded to Storage

### Firestore Phase
- [ ] Expense document created
- [ ] All fields populated correctly
- [ ] Image accessible via Storage URL
- [ ] Multiple expenses save successfully
- [ ] Timestamps set correctly

### Provider Phase
- [ ] Expenses load from Firestore
- [ ] Unlinked expenses filtered
- [ ] Total unlinked calculated
- [ ] All provider methods functional

### Linking Phase
- [ ] Invoice created successfully
- [ ] Attachment dialog displays
- [ ] Expenses selected and attached
- [ ] invoiceId set on expenses
- [ ] Invoice totals updated
- [ ] Unlinked count decremented

### Advanced Phase
- [ ] Expenses can be detached
- [ ] Search functionality works
- [ ] Category filtering works
- [ ] Date range filtering works
- [ ] Multiple invoices supported

### Error Handling Phase
- [ ] Network errors handled
- [ ] Storage errors handled
- [ ] Validation errors shown
- [ ] Firestore rules enforced

### Integration Phase
- [ ] Full end-to-end flow works
- [ ] Multiple invoices support
- [ ] Data consistency maintained

### Performance Phase
- [ ] Large lists load quickly
- [ ] Filtering performs well
- [ ] UI remains responsive

---

## Test Report Template

Use this when running tests:

```
TEST REPORT - Expense Scanner & Linking
========================================

Date: ___________
Device: Android / iOS
OS Version: ___________
App Version: 0.1.0

SETUP PHASE:
✅ Dependencies installed
✅ Routes configured
✅ Providers registered

FUNCTIONALITY:
✅ OCR detection (ML Kit)
✅ OCR detection (Cloud Vision)
✅ Firestore save
✅ Expense loading
✅ Invoice linking
✅ Detachment
⚠️ Multi-invoice (needs testing)

ISSUES FOUND:
[List any bugs or issues]
1. ___________
2. ___________

NOTES:
[Any observations or improvements]

APPROVED FOR RELEASE: YES / NO
```

---

## Quick Reference Commands

```bash
# Clean build
flutter clean && flutter pub get

# Run with logging
flutter run -v

# Test on specific device
flutter run -d <device_id>

# Deploy to Firebase
firebase deploy --only firestore:rules,functions,storage:rules

# Watch Firestore
firebase firestore:delete --all

# View logs
firebase functions:log
```

---

## Next Steps After Testing

1. ✅ Verify all checklist items pass
2. ✅ Fix any issues found
3. ✅ Run integration tests
4. ✅ Deploy to production
5. ✅ Monitor Firestore & Storage usage
6. ✅ Gather user feedback
7. ✅ Iterate based on findings

---

## Contact & Support

For issues or questions:
- Check `docs/` folder for detailed guides
- Review `FEATURES_IMPLEMENTATION_COMPLETE.md`
- Check `docs/cloud_vision_integration.md` for OCR setup
- Review `docs/expenses_to_invoices_integration.md` for linking details

**Status:** ✅ Ready for comprehensive testing

