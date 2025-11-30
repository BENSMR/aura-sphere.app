# 🧪 Business Profile Integration - End-to-End Test Workflow

**Status:** ✅ **COMPLETE TEST SCENARIO**  
**Date:** November 28, 2025  
**Purpose:** Verify business profile → invoice export → Cloud Function integration  
**Duration:** 15-20 minutes

---

## 📋 Test Overview

This document provides a complete, step-by-step workflow to test:
1. ✅ Business Profile creation and persistence
2. ✅ Logo upload to Firebase Storage
3. ✅ Profile data merging with invoice
4. ✅ Cloud Function export generation
5. ✅ Signed URLs in UI
6. ✅ File storage verification

---

## 🎯 Test Scenario

### Scenario: "Acme Corp" Invoice Export with Branding

**User:** testuser@example.com  
**Company:** Acme Corporation  
**Invoice Number:** INV-2024-001  
**Goal:** Create business profile, then export invoice with full branding

---

## 🚀 Part 1: Business Profile Setup (5 minutes)

### Step 1.1: Navigate to Business Profile Screen

```dart
// In your app navigation (main.dart or routing)
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => BusinessProfileScreen(
      userId: FirebaseAuth.instance.currentUser!.uid,
    ),
  ),
);
```

**Expected UI:**
- ✅ Title: "Business Profile"
- ✅ Logo upload area (placeholder icon)
- ✅ Text fields for company details
- ✅ Color picker widget
- ✅ Save button

### Step 1.2: Fill Company Details

Enter the following information in the form:

| Field | Value | Notes |
|-------|-------|-------|
| Business Name | Acme Corporation | Required field |
| Legal Name | Acme Corp Inc. | Optional |
| Tax ID | US-12-3456789 | Optional |
| VAT Number | VAT123456 | Optional |
| Address | 123 Business Ave | Optional |
| City | New York | Optional |
| Postal Code | 10001 | Optional |
| Invoice Prefix | ACM- | Custom prefix |
| Document Footer | © 2025 Acme Corp. All Rights Reserved | Custom text |
| Watermark Text | CONFIDENTIAL | Watermark display |

### Step 1.3: Upload Logo

1. Click "Upload Logo" button
2. Select an image from gallery/camera
   - Recommended: PNG or JPG, ~500x500px
   - File size: < 5MB
3. Image preview appears
4. System uploads to Firebase Storage: `users/{userId}/business/{timestamp}.png`

**Expected:**
- ✅ Image displays in preview
- ✅ No error messages
- ✅ Upload completes in 2-5 seconds

### Step 1.4: Select Brand Color

Click on color options in the "Brand color" section:
- ✅ Blue (default)
- ✅ Green
- ✅ Purple
- ✅ Black

**Select:** Blue (#FF6600 alternative or default)

**Expected:**
- ✅ Selected color shows border/highlight
- ✅ Color selection persists

### Step 1.5: Save Profile

Click "Save Business Profile" button

**Expected UI Feedback:**
```
✅ SnackBar Message: "Business profile saved"
```

**Expected Firestore Document:**
```
Path: /users/{userId}/meta/business

Document Data:
{
  "businessName": "Acme Corporation",
  "legalName": "Acme Corp Inc.",
  "taxId": "US-12-3456789",
  "vatNumber": "VAT123456",
  "address": "123 Business Ave",
  "city": "New York",
  "postalCode": "10001",
  "logoUrl": "https://storage.googleapis.com/...",
  "invoicePrefix": "ACM-",
  "documentFooter": "© 2025 Acme Corp. All Rights Reserved",
  "brandColor": "#FF6600",
  "watermarkText": "CONFIDENTIAL",
  "updatedAt": Timestamp(2025-11-28 ...)
}
```

### Step 1.6: Verify Storage Upload

**Check Firebase Console:**
1. Go to Firebase Console → Storage
2. Navigate to: `users/{userId}/business/`
3. Verify file exists: `{timestamp}.png`
4. Note the download URL (should appear in logs or profile)

**Expected:**
- ✅ Logo file exists
- ✅ File size reasonable (~50-200 KB)
- ✅ File can be downloaded

### Step 1.7: Preview Branding

Navigate to InvoiceBrandingScreen:

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => InvoiceBrandingScreen(
      userId: FirebaseAuth.instance.currentUser!.uid,
    ),
  ),
);
```

**Expected UI:**
- ✅ Company logo displays
- ✅ Logo size: ~80x80px
- ✅ Company name "Acme Corporation" shows
- ✅ Brand color applied (accent color in UI)
- ✅ Invoice preview shows professional layout

---

## 🧾 Part 2: Create Invoice (3 minutes)

### Step 2.1: Create Invoice Model

```dart
final invoice = InvoiceModel(
  id: 'inv-acme-001',
  invoiceNumber: 'INV-2024-001',
  userId: FirebaseAuth.instance.currentUser!.uid,
  clientName: 'John Smith',
  clientEmail: 'john@example.com',
  clientAddress: '456 Client Lane, Los Angeles, CA 90001',
  
  // Items
  items: [
    InvoiceItem(
      description: 'Consulting Services',
      quantity: 10,
      unitPrice: 150.00,
      vatRate: 0.10,
    ),
    InvoiceItem(
      description: 'Development Work',
      quantity: 20,
      unitPrice: 100.00,
      vatRate: 0.10,
    ),
  ],
  
  // Amounts
  subtotal: 3500.00,
  totalVat: 350.00,
  total: 3850.00,
  currency: 'USD',
  
  // Dates
  createdAt: DateTime.now(),
  dueDate: DateTime.now().add(Duration(days: 30)),
);
```

### Step 2.2: Save Invoice to Firestore

```dart
await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .collection('invoices')
    .doc(invoice.id)
    .set(invoice.toMap());
```

**Expected:**
- ✅ Document created at: `/users/{userId}/invoices/inv-acme-001`
- ✅ All fields persisted
- ✅ No validation errors

### Step 2.3: Verify in Firestore Console

Navigate to: `users/{userId}/invoices/inv-acme-001`

**Expected Fields:**
- ✅ invoiceNumber: "INV-2024-001"
- ✅ clientName: "John Smith"
- ✅ items: Array with 2 items
- ✅ subtotal: 3500.00
- ✅ totalVat: 350.00
- ✅ total: 3850.00

---

## 📤 Part 3: Export Invoice with Branding (5 minutes)

### Step 3.1: Navigate to Invoice Export Screen

```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (_) => InvoiceExportScreen(
      userId: FirebaseAuth.instance.currentUser!.uid,
      invoice: invoice,
    ),
  ),
);
```

**Expected UI:**
- ✅ Title: "Export Invoice"
- ✅ Display: "Export invoice INV-2024-001"
- ✅ Button: "Generate PDF / DOCX / CSV"
- ✅ Status area (empty initially)

### Step 3.2: Trigger Export

Click "Generate PDF / DOCX / CSV" button

**Behind the scenes, this executes:**

```dart
final svc = PdfExportService();
final payload = await svc.buildExportPayload(userId, invoice.toMap());
final res = await svc.exportInvoice(userId, payload);
```

**Expected UI:**
- ✅ Button becomes disabled
- ✅ Loading indicator appears: `CircularProgressIndicator()`
- ✅ Status message: "Exporting..." (if implemented)

### Step 3.3: Verify Payload Building

The `buildExportPayload` method merges:

```dart
// Original invoice data
{
  "invoiceNumber": "INV-2024-001",
  "clientName": "John Smith",
  "items": [...],
  "subtotal": 3500.00,
  "total": 3850.00,
  ...
}

// + Business profile data
{
  "businessName": "Acme Corporation",
  "logoUrl": "https://storage.googleapis.com/...",
  "invoicePrefix": "ACM-",
  "watermarkText": "CONFIDENTIAL",
  "documentFooter": "© 2025 Acme Corp. All Rights Reserved",
  "brandColor": "#FF6600",
}

// = Enriched payload sent to Cloud Function
{
  "invoiceNumber": "INV-2024-001",
  "clientName": "John Smith",
  "businessName": "Acme Corporation",
  "logoUrl": "https://storage.googleapis.com/...",
  "watermarkText": "CONFIDENTIAL",
  ...
  // All 18+ fields for complete invoice generation
}
```

**Verify in Dart logs:**
```
✅ Log message: "Merging invoice with business profile"
✅ Log message: "Calling exportInvoiceFormats Cloud Function"
✅ No null values for required fields
```

### Step 3.4: Cloud Function Execution

The `exportInvoiceFormats` Cloud Function receives the enriched payload and:

1. **Validates** all required fields
2. **Generates** PDF with:
   - ✅ Company logo (from logoUrl)
   - ✅ Company name (from businessName)
   - ✅ Watermark text (from watermarkText)
   - ✅ Footer (from documentFooter)
3. **Generates** DOCX with same branding
4. **Generates** CSV with invoice data
5. **Uploads** all files to Storage:
   - `invoices/{userId}/exports/INV-2024-001_pdf_{timestamp}.pdf`
   - `invoices/{userId}/exports/INV-2024-001_docx_{timestamp}.docx`
   - `invoices/{userId}/exports/INV-2024-001_csv_{timestamp}.csv`
6. **Generates** 30-day signed URLs for each file
7. **Returns** response with URLs

### Step 3.5: Verify Cloud Function Response

**Expected Response:**
```dart
{
  "success": true,
  "urls": {
    "pdf": "https://storage.googleapis.com/...?X-Goog-Signature=...",
    "docx": "https://storage.googleapis.com/...?X-Goog-Signature=...",
    "csv": "https://storage.googleapis.com/...?X-Goog-Signature=...",
  },
  "message": "Export generated successfully"
}
```

**In InvoiceExportScreen UI:**
```
✅ Loading indicator disappears
✅ Text: "Export complete"
✅ Three download links appear:
   • PDF link
   • DOCX link
   • CSV link
```

### Step 3.6: Test Signed URLs

Click each download link to verify it works:

**PDF URL Test:**
```
1. Click PDF link
2. Expected: PDF opens in browser or downloads
3. Content: Invoice with logo, colors, watermark
4. Verify: "CONFIDENTIAL" watermark visible
5. Verify: "Acme Corporation" header visible
6. Verify: Company logo visible
```

**DOCX URL Test:**
```
1. Click DOCX link
2. Expected: Word document downloads
3. Content: Professional formatted document
4. Verify: Logo embedded
5. Verify: Branding applied
```

**CSV URL Test:**
```
1. Click CSV link
2. Expected: CSV file downloads
3. Content: Structured invoice data
4. Verify: All line items present
5. Verify: Calculations correct
```

---

## 🔍 Part 4: Verification Checklist (3 minutes)

### Firestore Verification

**Business Profile Document:**
```bash
# Check document exists and has correct data
firebase firestore:get /users/{userId}/meta/business
```

Expected output shows all fields with correct values.

**Invoice Document:**
```bash
# Check invoice persists
firebase firestore:get /users/{userId}/invoices/inv-acme-001
```

Expected: All invoice fields present and correct.

### Firebase Storage Verification

**Logo File:**
```bash
# Check logo uploaded
gsutil ls gs://{project-id}/users/{userId}/business/
```

Expected: One or more PNG files with timestamp names.

**Export Files:**
```bash
# Check export files generated
gsutil ls gs://{project-id}/invoices/{userId}/exports/
```

Expected: Three files:
- `INV-2024-001_pdf_*.pdf`
- `INV-2024-001_docx_*.docx`
- `INV-2024-001_csv_*.csv`

### File Content Verification

**PDF Content:**
```
✅ Company logo visible
✅ "Acme Corporation" in header
✅ "CONFIDENTIAL" watermark diagonal across page
✅ Invoice details correct
✅ Line items with amounts
✅ Total calculation correct
✅ Footer text present
```

**DOCX Content:**
```
✅ Professional formatting
✅ Company logo embedded
✅ All branding applied
✅ Invoice details correct
✅ Properly formatted table
```

**CSV Content:**
```
✅ Comma-separated values
✅ Headers: invoice_number, client_name, items, total, etc.
✅ All line items listed
✅ Calculations correct
✅ UTF-8 encoded
```

### Signed URL Verification

**URL Format Check:**
```
✅ Starts with: https://storage.googleapis.com/
✅ Contains: X-Goog-Signature parameter
✅ Contains: X-Goog-Expires parameter
✅ Valid for 30 days
✅ User-specific (signed with project credentials)
```

**Access Control:**
```
✅ URL works when clicked
✅ File downloads completely
✅ No authentication required (signed)
✅ Expires after 30 days
```

---

## 📊 Data Flow Verification

### Complete Flow Diagram

```
1. User Input (BusinessProfileScreen)
   ↓ Save
2. Firestore: /users/{userId}/meta/business
   ↓
3. Firebase Storage: users/{userId}/business/{logo.png}
   ↓ (when exporting invoice)
4. InvoiceExportScreen
   ↓ Click Export
5. PdfExportService.buildExportPayload()
   ├─ Load invoice from Firestore
   ├─ Load business profile from Firestore
   └─ Merge data
   ↓
6. Cloud Function: exportInvoiceFormats
   ├─ Validate enriched payload
   ├─ Generate PDF (with logo, colors, watermark)
   ├─ Generate DOCX (with branding)
   ├─ Generate CSV (with data)
   ├─ Upload to Storage: invoices/{userId}/exports/
   ├─ Generate 30-day signed URLs
   └─ Return response
   ↓
7. InvoiceExportScreen (UI Update)
   ├─ Show "Export complete"
   ├─ Display 3 download links
   └─ Each link is a signed URL
   ↓
8. User clicks link
   ├─ Signed URL authenticates
   ├─ File downloads from Storage
   └─ Browser displays/saves file
```

### Data Mapping Verification

**Business Profile → Export Payload:**

| Business Profile Field | Export Payload Field | PDF Location | DOCX Location |
|----------------------|-------------------|--------------|---------------|
| businessName | businessName | Header | Header |
| logoUrl | userLogoUrl | Logo image | Logo image |
| brandColor | brandColor | Accents | Accents |
| watermarkText | watermarkText | Diagonal overlay | Watermark |
| documentFooter | documentFooter | Footer | Footer |
| invoicePrefix | invoicePrefix | Invoice number prefix | Document name |

---

## 🧪 Test Cases

### Test Case 1: Happy Path (All Success)
**Scenario:** Normal user flow with complete data
**Expected:** All exports generated, signed URLs valid, files downloadable

**Verification:**
- [ ] Business profile saved
- [ ] Logo uploaded
- [ ] Invoice created
- [ ] Export triggered
- [ ] Cloud Function succeeds
- [ ] All 3 files in Storage
- [ ] 3 signed URLs returned
- [ ] URLs are clickable and valid
- [ ] Files contain correct branding

### Test Case 2: Missing Business Profile
**Scenario:** Export invoice without setting up business profile
**Expected:** Export uses defaults/falls back gracefully

**Verification:**
- [ ] Export still succeeds
- [ ] businessName defaults to empty or user name
- [ ] logoUrl field omitted (no logo in PDF)
- [ ] watermarkText field omitted
- [ ] Files generated with default styling

### Test Case 3: Partial Business Profile
**Scenario:** Only some business profile fields filled
**Expected:** Export uses filled fields, ignores empty ones

**Verification:**
- [ ] Export succeeds
- [ ] Filled fields appear in export
- [ ] Empty fields don't cause errors
- [ ] Files look professional

### Test Case 4: Large Logo File
**Scenario:** Upload 5MB logo file
**Expected:** File uploads, but might be slower

**Verification:**
- [ ] Upload completes (might take 5-10s)
- [ ] File stored in Storage
- [ ] URL returned correctly
- [ ] Logo displays in preview

### Test Case 5: Special Characters in Data
**Scenario:** Company name: "Acme & Co." with special chars
**Expected:** Characters escaped properly, no errors

**Verification:**
- [ ] Form accepts special characters
- [ ] Saves without errors
- [ ] Displays correctly in preview
- [ ] Exports correctly (escaped in CSV)

---

## 📋 Debugging Guide

### Issue: Profile not saving
**Solution:**
```bash
# Check Firestore rules
firebase firestore:get /users/{userId}/meta/business

# Check logs
# Look for: "saveBusinessProfile" logs
# Verify: userId matches authenticated user
```

### Issue: Logo upload fails
**Solution:**
```bash
# Check Storage rules
# Verify path: users/{userId}/business/
# Check file size: < 5MB recommended
# Check permissions: User has write access
```

### Issue: Export returns error
**Solution:**
```bash
# Check Cloud Function logs
firebase functions:log

# Look for: "exportInvoiceFormats" errors
# Verify: All required fields in payload
# Check: Cloud Function has sufficient memory (1GB)
```

### Issue: Signed URLs don't work
**Solution:**
```bash
# Verify URL format
# Should contain: X-Goog-Signature
# Should contain: X-Goog-Expires

# Check expiration
# Should be 30 days from generation
# Should not have passed

# Verify file exists in Storage
gsutil ls gs://{project-id}/invoices/{userId}/exports/
```

---

## 🎯 Success Criteria

**All of the following must be true:**

✅ Business profile saved to Firestore  
✅ Logo uploaded to Firebase Storage  
✅ Logo URL stored in business profile  
✅ Invoice created in Firestore  
✅ Export payload correctly enriched  
✅ Cloud Function called successfully  
✅ All 3 export files generated in Storage  
✅ 3 signed URLs returned in response  
✅ PDF contains logo and branding  
✅ DOCX contains logo and branding  
✅ CSV contains correct data  
✅ Signed URLs valid for 30 days  
✅ Files downloadable from UI  
✅ No console errors  
✅ No Firestore errors  
✅ No Storage errors  

---

## 📊 Performance Metrics

Expected timing for complete workflow:

| Step | Time | Status |
|------|------|--------|
| Business profile form fill | 1-2 min | ✅ UI responsive |
| Logo upload | 2-5 sec | ✅ Good |
| Save profile | <1 sec | ✅ Excellent |
| Create invoice | <1 sec | ✅ Excellent |
| Export trigger | <100ms | ✅ Instant |
| Cloud Function execution | 5-10 sec | ✅ Good |
| File generation | 3-5 sec | ✅ Good |
| UI update | <500ms | ✅ Excellent |
| **Total Workflow** | **10-20 min** | **✅ Acceptable** |

---

## 🚀 Running the Test

### Prerequisites
- ✅ Firebase project configured
- ✅ Firestore rules deployed
- ✅ Storage rules configured
- ✅ Cloud Function deployed
- ✅ User authenticated
- ✅ Network connection active

### Run Complete Test Flow

```bash
# 1. Ensure services are running
firebase emulators:start  # or use production

# 2. Run app
flutter run

# 3. Follow manual steps above
# → Business Profile Screen
# → Fill details, upload logo
# → Save
# → Invoice screen
# → Create invoice
# → Export screen
# → Trigger export
# → Verify signed URLs
# → Download files

# 4. Check logs
firebase functions:log
# Look for: "exportInvoiceFormats" execution

# 5. Verify Storage
firebase storage:browse
# Check: invoices/{userId}/exports/

# 6. Verify Firestore
firebase firestore:browse
# Check: users/{userId}/meta/business
# Check: users/{userId}/invoices/
```

---

## ✨ Expected Outcome

After completing this test workflow, you should have:

1. ✅ Business profile with:
   - Company name, address, tax ID
   - Uploaded logo
   - Brand color
   - Watermark text
   - Invoice prefix
   - Document footer

2. ✅ Professional PDF invoice with:
   - Company logo visible
   - "Acme Corporation" branding
   - "CONFIDENTIAL" watermark
   - Footer text
   - Invoice details
   - Correct calculations

3. ✅ Professional DOCX with same branding

4. ✅ Structured CSV export

5. ✅ 3 Signed URLs valid for 30 days

6. ✅ All files in Firebase Storage

7. ✅ Complete audit trail in Firestore logs

---

## 📞 Support

If any step fails:
1. Check error message in UI
2. Check console logs (Dart/JavaScript)
3. Check Firebase Function logs
4. Check Firestore rules
5. Check Storage rules
6. Verify file paths
7. Verify user authentication

See [BUSINESS_PROFILE_DEPLOYMENT_SUMMARY.md](BUSINESS_PROFILE_DEPLOYMENT_SUMMARY.md) for detailed troubleshooting.

---

## 🎉 Conclusion

This end-to-end test verifies the complete integration:
- Business profile management
- Invoice creation
- Export with automatic branding enrichment
- Cloud Function processing
- File generation and storage
- Signed URL generation
- Client-side display

**Status: ✅ Ready to Test**

---

*Test Scenario Created: November 28, 2025*  
*Expected Duration: 15-20 minutes*  
*Difficulty: Intermediate*  
*All Prerequisites: Provided*
