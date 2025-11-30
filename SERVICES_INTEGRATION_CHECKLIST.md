# Services Integration Checklist

**Date:** 2024  
**Status:** ✅ Services Complete & Ready for Integration  
**Target:** Complete feature integration within next session

---

## Phase 1: Service Files Creation ✅

- [x] **business_profile_service.dart** (195 lines)
  - [x] CRUD operations
  - [x] Validation
  - [x] Stream support
  - [x] Helper methods
  - [x] Compiles: No errors

- [x] **invoice_branding_service.dart** (205 lines)
  - [x] Branding settings management
  - [x] Invoice prefix & numbering
  - [x] Watermark & footer
  - [x] Signature & stamp management
  - [x] Compiles: No errors

- [x] **pdf_export_service.dart** (536 lines)
  - [x] Basic PDF generation
  - [x] PDF with expenses
  - [x] Simple PDF variant
  - [x] Professional formatting
  - [x] Compiles: No errors

- [x] **docx_export_service.dart** (475 lines)
  - [x] DOCX generation
  - [x] DOCX with expenses
  - [x] HTML generation
  - [x] Professional styling
  - [x] Compiles: No errors

---

## Phase 2: Screen Integration (To Do) ⏭️

### InvoiceBrandingScreen Integration
**Location:** [lib/screens/invoice/invoice_branding_screen.dart](lib/screens/invoice/invoice_branding_screen.dart)

**Actions Required:**
- [ ] Add InvoiceBrandingService injection
- [ ] Implement "Update Prefix" button action
- [ ] Implement "Update Watermark" button action
- [ ] Implement "Update Footer" button action
- [ ] Implement "Upload Signature" button action
- [ ] Implement "Upload Stamp" button action
- [ ] Add stream listener for real-time preview
- [ ] Connect form to service methods
- [ ] Add loading states
- [ ] Add success/error feedback

### InvoiceExportScreen Integration
**Location:** [lib/screens/invoice/invoice_export_screen.dart](lib/screens/invoice/invoice_export_screen.dart)

**Actions Required:**
- [ ] Add PdfExportService injection
- [ ] Add DocxExportService injection
- [ ] Implement "Export as PDF" button
- [ ] Implement "Export as DOCX" button
- [ ] Implement "Export as HTML" button
- [ ] Implement file download/sharing
- [ ] Add loading states during generation
- [ ] Add success notifications
- [ ] Add error handling
- [ ] Connect to Firebase Storage (optional)

### Business Profile Screen (New or Existing)
**Location:** TBD

**Actions Required:**
- [ ] Create or update business profile screen
- [ ] Add BusinessProfileService injection
- [ ] Implement form for profile data entry
- [ ] Implement validation display
- [ ] Add create/update button actions
- [ ] Add stream listener for profile updates
- [ ] Connect to existing profile data

---

## Phase 3: Provider/State Management (To Do) ⏭️

### Option A: Provider Pattern
**Files to Create:**
- [ ] `lib/providers/business_profile_provider.dart`
  - [ ] Inject BusinessProfileService
  - [ ] Add CRUD methods
  - [ ] Add validation
  - [ ] Implement change notification
  - [ ] Handle loading/error states

- [ ] `lib/providers/invoice_branding_provider.dart`
  - [ ] Inject InvoiceBrandingService
  - [ ] Add update methods
  - [ ] Implement stream listening
  - [ ] Handle real-time updates

- [ ] `lib/providers/invoice_export_provider.dart`
  - [ ] Inject PdfExportService
  - [ ] Inject DocxExportService
  - [ ] Add export methods
  - [ ] Handle loading states
  - [ ] Manage file downloads

### Option B: GetIt Service Locator
**File to Update:** `lib/config/service_locator.dart` (or create if missing)

```dart
final getIt = GetIt.instance;

void setupServiceLocator() {
  // Services
  getIt.registerSingleton(BusinessProfileService());
  getIt.registerSingleton(InvoiceBrandingService());
  getIt.registerSingleton(PdfExportService());
  getIt.registerSingleton(DocxExportService());
  
  // Providers (if using Provider)
  getIt.registerSingleton(BusinessProfileProvider());
  getIt.registerSingleton(InvoiceBrandingProvider());
  getIt.registerSingleton(InvoiceExportProvider());
}
```

---

## Phase 4: Route Registration (To Do) ⏭️

**File to Update:** [lib/config/app_routes.dart](lib/config/app_routes.dart)

**Current Routes (Already Added):**
- ✅ `/business-profile` - Business profile screen
- ✅ `/invoice-branding` - Invoice branding screen
- ✅ `/invoice-export` - Invoice export screen

**Routes to Verify:**
- [ ] Routes are correctly registered
- [ ] Routes have proper arguments
- [ ] Navigation works end-to-end
- [ ] Deep links work (if applicable)

---

## Phase 5: Testing (To Do) ⏭️

### Unit Tests
**File to Create:** `test/services/business_profile_service_test.dart`

```dart
void main() {
  group('BusinessProfileService', () {
    // Mock FirebaseAuth, FirebaseFirestore
    // Test each method
    // Test validation
    // Test error handling
  });
}
```

### Integration Tests
**File to Create:** `integration_test/invoice_export_test.dart`

```dart
void main() {
  // Test full flow: create profile → update branding → export invoice
  // Test real Firestore interaction
  // Test file generation
}
```

### Manual Testing Checklist
- [ ] Create business profile
- [ ] Update invoice prefix
- [ ] Update watermark & footer
- [ ] Upload signature image
- [ ] Upload stamp image
- [ ] Export invoice as PDF
- [ ] Export invoice as DOCX
- [ ] Export invoice as HTML
- [ ] Verify file content
- [ ] Test real-time updates
- [ ] Test error scenarios

---

## Phase 6: Documentation Updates (To Do) ⏭️

**Files to Update/Create:**

- [ ] [docs/api_reference.md](docs/api_reference.md)
  - [ ] Add BusinessProfileService documentation
  - [ ] Add InvoiceBrandingService documentation
  - [ ] Add PdfExportService documentation
  - [ ] Add DocxExportService documentation

- [ ] [docs/architecture.md](docs/architecture.md)
  - [ ] Update service layer diagram
  - [ ] Add service interaction flows
  - [ ] Document new Firestore collections

- [ ] [docs/setup.md](docs/setup.md)
  - [ ] Add firebase config requirements for new services
  - [ ] Update dependency list (pdf package, etc.)

- [ ] [README.md](README.md)
  - [ ] Add invoice export features to feature list
  - [ ] Update quick start guide

---

## Phase 7: Firebase Setup (To Do) ⏭️

### Firestore Collections
- [ ] Verify `users/{userId}/business` collection exists
- [ ] Set appropriate security rules

### Firebase Storage (for branding images)
- [ ] Create `branding/{userId}/` folder
- [ ] Set upload size limits (5-10MB)
- [ ] Set security rules for authenticated users

### Cloud Functions (Optional)
- [ ] Create function for batch PDF generation
- [ ] Create function for email delivery
- [ ] Create function for scheduled exports

### Security Rules
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      match /business/{profileId} {
        allow read, write: if request.auth.uid == userId;
      }
    }
  }
}
```

---

## Phase 8: Deployment (To Do) ⏭️

### Pre-deployment Checklist
- [ ] All tests passing
- [ ] Code review completed
- [ ] Performance tested
- [ ] Error handling verified
- [ ] Logging configured
- [ ] Security audit passed

### Deployment Steps
- [ ] Merge to main branch
- [ ] Update version number
- [ ] Deploy Firebase rules
- [ ] Deploy Firebase functions
- [ ] Deploy Flutter app
- [ ] Monitor logs for errors
- [ ] Rollback plan prepared

---

## Dependencies Check

### Current (Verified as Present)
- ✅ cloud_firestore
- ✅ firebase_auth
- ✅ firebase_storage
- ✅ provider (assumed)

### Required for Services
- ✅ pdf: ^3.10.0 (for PdfExportService)

### Optional (for enhanced DOCX support)
- ⏭️ docx: ^0.11.0+ (if upgrading DOCX generation)
- ⏭️ excel: ^2.0.0 (if adding Excel export)

### To Add if Not Present
```yaml
dependencies:
  flutter:
    sdk: flutter
  cloud_firestore: ^4.0.0
  firebase_auth: ^4.0.0
  firebase_storage: ^11.0.0
  provider: ^6.0.0
  pdf: ^3.10.0  # For PDF generation
```

---

## File Structure Summary

### Current Files (Complete ✅)
```
lib/services/
├── business_profile_service.dart        ✅ 195 lines
├── invoice_branding_service.dart        ✅ 205 lines
├── pdf_export_service.dart              ✅ 536 lines
└── docx_export_service.dart             ✅ 475 lines

lib/screens/invoice/
├── invoice_branding_screen.dart         ✅ 523 lines (needs integration)
└── invoice_export_screen.dart           ✅ 441 lines (needs integration)

lib/data/models/
├── business_model.dart                  ✅ (already complete)
└── invoice_model.dart                   ✅ (already complete)
```

### Files to Create
```
lib/providers/
├── business_profile_provider.dart       ⏭️ (optional)
├── invoice_branding_provider.dart       ⏭️ (optional)
└── invoice_export_provider.dart         ⏭️ (optional)

lib/config/
└── service_locator.dart                 ⏭️ (if using GetIt)

test/services/
├── business_profile_service_test.dart   ⏭️
├── invoice_branding_service_test.dart   ⏭️
├── pdf_export_service_test.dart         ⏭️
└── docx_export_service_test.dart        ⏭️

integration_test/
└── invoice_export_test.dart             ⏭️

docs/
└── (updates to existing files)          ⏭️
```

---

## Next Actions (Priority Order)

### High Priority (Do Next)
1. [ ] Create providers (if using Provider pattern)
2. [ ] Integrate services into InvoiceBrandingScreen
3. [ ] Integrate services into InvoiceExportScreen
4. [ ] Test end-to-end flow
5. [ ] Update routes if needed

### Medium Priority (Within 1 week)
6. [ ] Write unit tests
7. [ ] Update documentation
8. [ ] Performance optimization
9. [ ] Security review

### Low Priority (Nice to have)
10. [ ] Write integration tests
11. [ ] Create Cloud Functions
12. [ ] Add batch export feature
13. [ ] Add email delivery

---

## Success Criteria

### ✅ Services Complete
- [x] All 4 services created
- [x] All services compile without errors
- [x] All services follow architecture patterns
- [x] All services have proper logging

### ⏭️ Integration Complete (Next Phase)
- [ ] Services integrated into screens
- [ ] End-to-end flow works
- [ ] All features functional
- [ ] All tests passing

### ⏭️ Deployment Ready (Final Phase)
- [ ] Code reviewed
- [ ] Security verified
- [ ] Performance tested
- [ ] Documentation complete
- [ ] Production deployment checklist passed

---

## Quick Reference

### Service Locations
| Service | File | Methods |
|---------|------|---------|
| BusinessProfile | `lib/services/business_profile_service.dart` | create, get, update, delete, validate, stream, getAll |
| InvoiceBranding | `lib/services/invoice_branding_service.dart` | getSettings, updatePrefix, updateWatermark, updateFooter, etc. |
| PdfExport | `lib/services/pdf_export_service.dart` | generateInvoicePdf, generateWithExpenses, generateSimple |
| DocxExport | `lib/services/docx_export_service.dart` | generateInvoiceDocx, generateWithExpenses, generateHtml |

### Key Files to Update
- `lib/config/app_routes.dart` - If routes need adjustment
- `lib/providers/` - If using Provider pattern
- `test/` - Add unit tests
- `integration_test/` - Add integration tests
- `docs/` - Update documentation

### Key Models Used
- `BusinessProfile` - Business profile data
- `InvoiceModel` - Invoice data
- `Uint8List` - PDF/DOCX bytes

---

## Support References

- **Service Implementation Guide:** [NEW_SERVICES_IMPLEMENTATION.md](NEW_SERVICES_IMPLEMENTATION.md)
- **Business Model:** [lib/data/models/business_model.dart](lib/data/models/business_model.dart)
- **Invoice Model:** [lib/data/models/invoice_model.dart](lib/data/models/invoice_model.dart)
- **Logger Utility:** [lib/core/utils/logger.dart](lib/core/utils/logger.dart)
- **Firestore Rules:** [firestore.rules](firestore.rules)

---

**Last Updated:** 2024  
**Status:** Services Complete & Ready ✅  
**Next Phase:** Integration into screens ⏭️  
**Expected Duration:** 30-60 minutes  
