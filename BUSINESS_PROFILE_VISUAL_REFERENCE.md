# 🎨 Business Profile Module - Visual Reference & Architecture

**Quick Visual Guide for Developers**

---

## 📊 Module Architecture Diagram

```
┌─────────────────────────────────────────────────────────────────┐
│                         USER APP                                 │
│                                                                   │
│  ┌────────────────────────────────────────────────────────────┐ │
│  │                    UI LAYER (Flutter)                      │ │
│  │                                                             │ │
│  │  BusinessProfileScreen         BusinessProfileFormScreen   │ │
│  │  ├─ View profile               ├─ Create profile form      │ │
│  │  ├─ Display all fields         ├─ Edit profile form        │ │
│  │  ├─ Edit button                └─ 30+ form fields          │ │
│  │  └─ Delete button                                           │ │
│  │                                                             │ │
│  └─────────────────┬──────────────────────┬──────────────────┘ │
│                    │                      │                     │
│  ┌─────────────────▼──────────────┐      │                    │
│  │   STATE MANAGEMENT LAYER       │      │                    │
│  │                                │      │                    │
│  │  BusinessProvider              │      │                    │
│  │  ├─ businessProfile (read)     │      │                    │
│  │  ├─ isLoading, isSaving        │      │                    │
│  │  ├─ error handling             │      │                    │
│  │  └─ convenience getters        │      │                    │
│  │     ├─ businessName            │      │                    │
│  │     ├─ businessEmail           │      │                    │
│  │     ├─ currency                │      │                    │
│  │     └─ ... 5+ more             │      │                    │
│  │                                │      │                    │
│  └─────────────────┬──────────────┘      │                    │
│                    │                     │                    │
│  ┌─────────────────▼──────────────┐      │                    │
│  │     SERVICE LAYER              │      │                    │
│  │                                │      │                    │
│  │  BusinessService               │      │                    │
│  │  ├─ streamBusinessProfile()    │      │                    │
│  │  ├─ getBusinessProfile()       │      │                    │
│  │  ├─ createBusinessProfile()    │      │                    │
│  │  ├─ updateBusinessProfile()    │      │                    │
│  │  ├─ updateFields()             │      │                    │
│  │  ├─ deleteBusinessProfile()    │      │                    │
│  │  ├─ isBusinessEmailUnique()    │      │                    │
│  │  └─ isTaxIdUnique()            │      │                    │
│  │                                │      │                    │
│  └─────────────────┬──────────────┘      │                    │
│                    │                     │                    │
│  ┌─────────────────▼──────────────┐      │                    │
│  │     MODEL LAYER                │      │                    │
│  │                                │      │                    │
│  │  BusinessProfile               │      │                    │
│  │  └─ 28 fields                  │      │                    │
│  │     ├─ Basic (5 fields)        │      │                    │
│  │     ├─ Contact (4 fields)      │      │                    │
│  │     ├─ Address (5 fields)      │      │                    │
│  │     ├─ Business (5 fields)     │      │                    │
│  │     ├─ Contact Person (3)      │      │                    │
│  │     ├─ Banking (4 fields)      │      │                    │
│  │     ├─ Branding (2 fields)     │      │                    │
│  │     └─ Metadata (2 fields)     │      │                    │
│  │                                │      │                    │
│  └─────────────────┬──────────────┘      │                    │
│                    │                     │                    │
│                    └─────────────────────┘                     │
│                            │                                   │
│                            │                                   │
└────────────────────────────┼───────────────────────────────────┘
                             │
                    ┌────────▼────────┐
                    │   FIRESTORE     │
                    │   DATABASE      │
                    │                 │
                    │ users/          │
                    │  └─ {userId}/   │
                    │     └─ business/│
                    │        └─ profile
                    │        (28 fields)
                    │                 │
                    │ SECURITY RULES: │
                    │ • User-scoped   │
                    │ • Owner check   │
                    │ • UID verified  │
                    └─────────────────┘
```

---

## 🔄 Data Flow Diagram

```
CREATE FLOW:
────────────────────────────────────────────────────────────

User fills form                BusinessProfileFormScreen
         │                              │
         │                              │
         └──────────────┬───────────────┘
                        │
                   [Submit]
                        │
                        ▼
                 Create BusinessProfile
                        │
                        ▼
               BusinessProvider.createBusinessProfile()
                        │
                        ▼
              BusinessService.createBusinessProfile()
                        │
                        ▼
     Firestore: POST /users/{userId}/business/profile
                        │
                        ▼
          [Document created in Firestore]
                        │
                        ▼
        Firestore stream notifies listeners
                        │
                        ▼
       BusinessProvider.streamBusinessProfile updates
                        │
                        ▼
    All Consumer<BusinessProvider> widgets rebuild
                        │
                        ▼
          BusinessProfileScreen shows data
                        │
                        ▼
               Success SnackBar shows


EDIT FLOW:
────────────────────────────────────────────────────────────

User clicks Edit               BusinessProfileScreen
         │                              │
         │                              │
         └──────────────┬───────────────┘
                        │
                 [Navigate with data]
                        │
                        ▼
            BusinessProfileFormScreen
            (initialProfile provided)
                        │
         [Form pre-fills with existing data]
                        │
            User modifies fields
                        │
                        ▼
                   [Submit]
                        │
                        ▼
              BusinessProvider.updateBusinessProfile()
                        │
                        ▼
             BusinessService.updateBusinessProfile()
                        │
                        ▼
   Firestore: UPDATE /users/{userId}/business/profile
                        │
                        ▼
        [Document updated in Firestore]
                        │
                        ▼
        Firestore stream notifies listeners
                        │
                        ▼
       BusinessProvider._business updated locally
                        │
                        ▼
        All listeners notified (notifyListeners)
                        │
                        ▼
    All Consumer<BusinessProvider> widgets rebuild
                        │
                        ▼
          Updated data displays
                        │
                        ▼
               Success SnackBar shows


REAL-TIME STREAM:
────────────────────────────────────────────────────────────

App starts
    │
    ▼
MultiProvider initializes BusinessProvider
    │
    ▼
BusinessProvider._init() called
    │
    ▼
businessService.streamBusinessProfile() starts
    │
    ▼
Firestore listener attached to:
  /users/{userId}/business/profile
    │
    ▼
[Listening for changes...]
    │
    ├─ Profile created elsewhere
    │  └─> Stream fires
    │      └─> BusinessProvider._business updated
    │         └─> Listeners notified
    │            └─> UI updates
    │
    ├─ Profile updated in another session
    │  └─> Stream fires
    │      └─> BusinessProvider._business updated
    │         └─> Listeners notified
    │            └─> UI updates
    │
    └─ Profile deleted
       └─> Stream fires
           └─> BusinessProvider._business = null
              └─> Listeners notified
                 └─> UI shows empty state
```

---

## 📋 Field Organization Map

```
BUSINESSPROFILE (28 FIELDS)
│
├─ BASIC INFORMATION (5 fields)
│  ├─ userId
│  ├─ businessName ⭐ (displayed prominently)
│  ├─ businessType (enum: sole_proprietor, llc, s_corp, etc)
│  ├─ industry
│  └─ description
│
├─ CONTACT INFORMATION (4 fields)
│  ├─ businessEmail ⭐
│  ├─ businessPhone ⭐
│  ├─ website
│  └─ currency ⭐ (used in invoices)
│
├─ ADDRESS (5 fields)
│  ├─ streetAddress
│  ├─ city
│  ├─ state
│  ├─ zipCode
│  └─ country
│
├─ BUSINESS DETAILS (5 fields)
│  ├─ taxId ⭐ (validated for uniqueness)
│  ├─ registrationNumber
│  ├─ foundedDate
│  ├─ numberOfEmployees
│  └─ fiscalYearEnd
│
├─ CONTACT PERSON (3 fields)
│  ├─ contactPersonName
│  ├─ contactPersonEmail
│  └─ contactPersonPhone
│
├─ BANKING INFORMATION (4 fields)
│  ├─ bankAccountName
│  ├─ bankAccountNumber (masked: ****5678)
│  ├─ routingNumber
│  └─ swiftCode
│
├─ BRANDING (2 fields)
│  ├─ logoUrl
│  └─ brandColor (hex: #1F97FF)
│
├─ STATUS & SOCIAL (2+ fields)
│  ├─ status (setup, active, inactive, suspended)
│  └─ socialMedia (map: {twitter: url, linkedin: url, ...})
│
└─ METADATA (2 fields)
   ├─ createdAt (server timestamp)
   └─ updatedAt (server timestamp)

⭐ = Commonly used in other features
```

---

## 🎨 UI Screen Map

```
┌──────────────────────────────────────────────────┐
│         BUSINESS PROFILE SCREENS                 │
└──────────────────────────────────────────────────┘

SCREEN 1: BusinessProfileScreen
──────────────────────────────────
Purpose: View complete business profile

Layout:
┌─────────────────────────────────┐
│  [AppBar: Business Profile]     │
├─────────────────────────────────┤
│                                 │
│  ┌─────────────────────────────┐│
│  │       [Logo Image]          ││
│  │  My Business Name           ││
│  │  Technology Industry        ││
│  │  Description here...        ││
│  │  [Active Status Badge]      ││
│  └─────────────────────────────┘│
│                                 │
│  Business Information Card:     │
│  • Business Type: LLC           │
│  • Tax ID: 12-3456789          │
│  • Registration #: C5123456    │
│  • Founded: 1/15/2020          │
│  • Employees: 50               │
│  • Currency: USD               │
│  • Fiscal Year: Dec 31         │
│                                 │
│  Address Card:                  │
│  📍 123 Business Ave            │
│     San Francisco, CA 94105     │
│     USA                         │
│                                 │
│  Contact Person Card:           │
│  • Name: John Doe              │
│  • Email: john@company.com     │
│  • Phone: +1-555-0124          │
│                                 │
│  [Edit Button] [Delete Button]  │
│                                 │
└─────────────────────────────────┘


SCREEN 2: BusinessProfileFormScreen
────────────────────────────────────
Purpose: Create or edit business profile

Layout (scrollable list):
┌─────────────────────────────────┐
│ [AppBar: Create/Edit Profile]   │
├─────────────────────────────────┤
│                                 │
│ ▼ BASIC INFORMATION             │
│  [Business Name input]          │
│  [Business Type dropdown]       │
│  [Industry input]               │
│  [Description textarea]         │
│                                 │
│ ▼ CONTACT INFORMATION           │
│  [Business Email input]         │
│  [Business Phone input]         │
│  [Website input]                │
│                                 │
│ ▼ ADDRESS                       │
│  [Street Address input]         │
│  [City input]                   │
│  [State] [ZIP Code]             │
│  [Country input]                │
│                                 │
│ ▼ BUSINESS DETAILS              │
│  [Tax ID input]                 │
│  [Registration # input]         │
│  [Founded Date picker]          │
│  [# Employees input]            │
│  [Currency dropdown]            │
│  [Fiscal Year End input]        │
│                                 │
│ ▼ CONTACT PERSON                │
│  [Name input]                   │
│  [Email input]                  │
│  [Phone input]                  │
│                                 │
│ ▼ BANKING INFORMATION            │
│  [Account Name input]           │
│  [Account Number input]         │
│  [Routing Number input]         │
│  [SWIFT Code input]             │
│                                 │
│ [CREATE/UPDATE PROFILE BUTTON]  │
│                                 │
│ [Loading indicator if saving]   │
│ [Error message if failed]       │
│                                 │
└─────────────────────────────────┘


SCREEN TRANSITIONS:
───────────────────

Home Screen
    │
    └─ Business Profile Menu Item
         │
         ├─ [First Time] → No Profile Found
         │   └─ Click "Create Profile"
         │      └─ BusinessProfileFormScreen
         │         └─ Fill & Submit
         │            └─ BusinessProfileScreen (view)
         │
         └─ [Existing] → View Profile
            └─ BusinessProfileScreen
               ├─ Click "Edit"
               │  └─ BusinessProfileFormScreen
               │     └─ Update & Submit
               │        └─ Back to View
               │
               └─ Click "Delete"
                  └─ Confirmation Dialog
                     └─ Delete & Return to empty state
```

---

## 🔌 Integration Points

```
BUSINESS PROFILE integrates with:
────────────────────────────────────

1. INVOICE CREATION
   ├─ Sender name from businessProfile.businessName
   ├─ Sender email from businessProfile.businessEmail
   ├─ Currency from businessProfile.currency
   └─ Logo from businessProfile.logoUrl

2. EXPENSE TRACKING
   ├─ Business currency for expense calculations
   └─ Tax ID for expense categorization

3. CRM MODULE
   ├─ Contact company matches businessName
   └─ Contact email validation against business email

4. REPORTS & ANALYTICS
   ├─ Business info in report headers
   ├─ Tax ID for compliance
   └─ Founded date for business age calculation

5. USER SETTINGS
   ├─ Business status affects features
   ├─ Currency affects app-wide formatting
   └─ Brand color for UI theming

6. AUTHENTICATION
   ├─ Business profile linked to user
   ├─ User ownership enforced
   └─ Multi-user isolation
```

---

## 🔒 Security Architecture

```
SECURITY LAYERS:
────────────────────────────────────

LAYER 1: FIRESTORE RULES
┌──────────────────────────────────┐
│  Cloud Firestore Rules            │
│                                   │
│  allow read: if uid == userId     │
│  allow write: if uid == userId    │
│  allow delete: if uid == userId   │
│                                   │
│  Effect: Client-side enforcement  │
│  Block: Unauthorized access       │
└──────────────────────────────────┘
         │
         ▼
LAYER 2: AUTHENTICATION CHECK
┌──────────────────────────────────┐
│  BusinessService._currentUserId   │
│                                   │
│  Check: _auth.currentUser exists  │
│  Effect: Throws if not logged in  │
│  Block: Anonymous access          │
└──────────────────────────────────┘
         │
         ▼
LAYER 3: DATA VALIDATION
┌──────────────────────────────────┐
│  Form & Service Validation        │
│                                   │
│  • Email format check             │
│  • Email uniqueness check         │
│  • Tax ID uniqueness check        │
│  • Phone format check             │
│  • Field type validation          │
│                                   │
│  Effect: Rejects invalid data     │
│  Block: Malformed data            │
└──────────────────────────────────┘
         │
         ▼
LAYER 4: SERVER-SIDE OPERATIONS
┌──────────────────────────────────┐
│  Firebase Cloud Functions         │
│  (Optional - for admin tasks)     │
│                                   │
│  • Owner verification             │
│  • Data transformation            │
│  • Audit logging                  │
│  • Complex validations            │
│                                   │
│  Effect: Server-side enforcement  │
│  Block: Client-side manipulation  │
└──────────────────────────────────┘
         │
         ▼
RESULT: Multi-layer, enterprise-grade security
        Complete isolation per user
        Audit trail available
        Compliant with best practices
```

---

## 📊 State Management Flow

```
PROVIDER PATTERN:
────────────────────────────────────

Widget Tree
    │
    ├─ Consumer<BusinessProvider>
    │   │
    │   └─ [rebuild on change]
    │       │
    │       └─ Access: businessProvider.businessName
    │
    └─ context.read<BusinessProvider>()
        │
        └─ One-time access (no rebuild)
            │
            └─ Call: businessProvider.updateLogoUrl()


LISTENER PATTERN:
────────────────────────────────────

BusinessProvider._init()
    │
    ├─ _businessSub = streamBusinessProfile()
    │   │
    │   └─ Listen to Firestore changes
    │       │
    │       ├─ Profile created
    │       │  └─> _business = profile
    │       │      └─> notifyListeners()
    │       │         └─> All Consumers rebuild
    │       │
    │       ├─ Profile updated
    │       │  └─> _business = updatedProfile
    │       │      └─> notifyListeners()
    │       │         └─> All Consumers rebuild
    │       │
    │       └─ Profile deleted
    │          └─> _business = null
    │             └─> notifyListeners()
    │                └─> All Consumers rebuild
    │
    └─ dispose()
        │
        └─ _businessSub?.cancel()
            │
            └─ [Stop listening]


GETTERS & CONVENIENCE:
────────────────────────────────────

businessProvider.business              │ Full object
businessProvider.businessName          │ Quick access
businessProvider.businessEmail         │ Quick access
businessProvider.currency              │ Quick access
businessProvider.logoUrl               │ Quick access
businessProvider.brandColor            │ Quick access
businessProvider.hasBusinessProfile    │ Boolean check
businessProvider.isLoading             │ Loading state
businessProvider.isSaving              │ Saving state
businessProvider.hasError              │ Error check
businessProvider.error                 │ Error message
```

---

## 🎯 Feature Capability Matrix

```
╔════════════════════════╦════════════╦═══════════════════════════╗
║ Feature                ║ Status     ║ Notes                     ║
╠════════════════════════╬════════════╬═══════════════════════════╣
║ Create Profile         ║ ✅ Done   ║ Full form with validation  ║
║ View Profile           ║ ✅ Done   ║ Organized into 7 sections  ║
║ Edit Profile           ║ ✅ Done   ║ Update all or specific     ║
║ Delete Profile         ║ ✅ Done   ║ Confirmation dialog        ║
║ Real-time Updates      ║ ✅ Done   ║ Stream-based               ║
║ Email Validation       ║ ✅ Done   ║ Format + uniqueness        ║
║ Tax ID Validation      ║ ✅ Done   ║ Uniqueness check           ║
║ Phone Validation       ║ ✅ Done   ║ Format check               ║
║ Logo Upload            ║ 📋 Ready  ║ Use Firebase Storage       ║
║ Logo Display           ║ ✅ Done   ║ With fallback              ║
║ Field Masking          ║ ✅ Done   ║ Bank account masked        ║
║ Error Handling         ║ ✅ Done   ║ User-friendly              ║
║ Loading States         ║ ✅ Done   ║ Buttons & indicators       ║
║ Success Feedback       ║ ✅ Done   ║ SnackBars                 ║
║ Responsive Design      ║ ✅ Done   ║ Phone & tablet             ║
║ Dark Mode Support      ║ ✅ Done   ║ Material Design            ║
║ Localization Ready     ║ ✅ Done   ║ String-based UI            ║
║ Multi-language         ║ 📋 Ready  ║ Integrate with i18n        ║
║ Cloud Functions        ║ 📋 Ready  ║ Server-side validation     ║
║ Analytics Integration  ║ 📋 Ready  ║ Track user actions         ║
╚════════════════════════╩════════════╩═══════════════════════════╝
```

---

## 🚀 Deployment Topology

```
DEVELOPMENT
────────────────────────────────────
Local Machine (Flutter Run)
    │
    ├─ App Code (lib/)
    ├─ Firestore Emulator (optional)
    └─ Firebase Local Config


STAGING
────────────────────────────────────
Firebase Project (staging)
    │
    ├─ Firestore (staging)
    │  └─ users/{userId}/business/profile
    │
    ├─ Security Rules (deployed)
    │  └─ Tested on staging data
    │
    ├─ Cloud Functions (deployed)
    │  └─ Optional validation functions
    │
    └─ Firebase Storage (staging)
       └─ Logo uploads


PRODUCTION
────────────────────────────────────
Firebase Project (production)
    │
    ├─ Firestore (production)
    │  └─ users/{userId}/business/profile
    │     └─ Real user data
    │
    ├─ Security Rules (deployed)
    │  └─ Enforced for all operations
    │
    ├─ Cloud Functions (deployed)
    │  └─ Processing real data
    │
    ├─ Firebase Storage (production)
    │  └─ User logos
    │
    ├─ Analytics
    │  └─ Profile creation tracking
    │
    └─ Monitoring
       ├─ Error rates
       ├─ Performance metrics
       └─ User adoption
```

---

## 📞 Quick Reference

```
QUICK API REFERENCE:
────────────────────────────────────

Create Profile:
  businessProvider.createBusinessProfile(profile)

View Profile:
  businessProvider.business              // Full object
  businessProvider.businessName          // String
  businessProvider.businessEmail         // String

Update Profile:
  businessProvider.updateBusinessProfile(updatedProfile)

Update Field:
  businessProvider.updateFields({'status': 'active'})

Update Logo:
  businessProvider.updateLogoUrl(url)

Check Status:
  businessProvider.hasBusinessProfile    // bool
  businessProvider.isLoading             // bool
  businessProvider.isSaving              // bool
  businessProvider.hasError              // bool

Delete Profile:
  businessProvider.deleteBusinessProfile()

Stream Updates:
  Consumer<BusinessProvider>(...)        // Auto-rebuild

Validate Email:
  businessProvider.isBusinessEmailUnique(email)

Validate Tax ID:
  businessProvider.isTaxIdUnique(taxId)


FIRESTORE PATHS:
────────────────────────────────────

Read:  /users/{userId}/business/profile
Write: /users/{userId}/business/profile
Delete: /users/{userId}/business/profile


FILE LOCATIONS:
────────────────────────────────────

Model:    lib/data/models/business_model.dart
Service:  lib/services/firebase/business_service.dart
Provider: lib/providers/business_provider.dart
Screens:  lib/screens/business/
  ├─ business_profile_screen.dart
  └─ business_profile_form_screen.dart


ROUTES:
────────────────────────────────────

businessProfile = '/business-profile'
```

---

*Visual Reference Guide - November 28, 2025*
*Status: ✅ Complete*
