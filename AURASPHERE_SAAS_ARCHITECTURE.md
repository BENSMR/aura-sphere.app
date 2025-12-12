# AuraSphere Pro - Complete SaaS Architecture & Implementation

## 1. Project Overview

**AuraSphere Pro** is a comprehensive business management SaaS application built with:
- **Frontend**: Flutter (cross-platform: iOS, Android, Web)
- **Backend**: Firebase (Firestore, Cloud Functions, Auth, Storage)
- **Email**: Resend for transactional & digest emails
- **APIs**: OpenAI (AI chat), Vision API (OCR), Stripe (payments)

---

## 2. Project Structure

```
aura-sphere-pro/
├── lib/                              # Flutter App (Mobile + Web)
│   ├── main.dart                     # App entry point
│   ├── app/
│   │   ├── app.dart                  # MultiProvider setup, theme
│   │   ├── routes.dart               # Named routes
│   │   ├── theme.dart                # Material design theme
│   │   └── bootstrap.dart            # Firebase initialization
│   │
│   ├── config/
│   │   ├── app_routes.dart           # All route constants & onGenerateRoute
│   │   ├── constants.dart            # App-wide constants & Firestore collections
│   │   └── feature_constants.dart    # Feature flags (AI, crypto, etc)
│   │
│   ├── data/
│   │   └── models/
│   │       ├── user_model.dart       # AppUser (email, name, timezone, locale, country)
│   │       ├── business_model.dart   # Business profile data
│   │       ├── invoice_model.dart    # Invoice with items, payments
│   │       ├── expense_model.dart    # Expense records
│   │       ├── client_model.dart     # CRM clients
│   │       ├── task_model.dart       # Task/project management
│   │       └── ...
│   │
│   ├── services/
│   │   ├── firebase/
│   │   │   ├── auth_service.dart     # Firebase Auth, sign in/up
│   │   │   └── firebase_service.dart # Generic Firestore operations
│   │   │
│   │   ├── timezone_service.dart     # Device timezone detection, user prefs
│   │   ├── locale_service.dart       # Localization & currency settings
│   │   ├── device_init_service.dart  # Initialize device info on login
│   │   ├── openai_service.dart       # OpenAI Chat API
│   │   ├── invoice_service.dart      # Invoice CRUD
│   │   ├── expense_service.dart      # Expense CRUD
│   │   ├── client_service.dart       # Client/CRM operations
│   │   ├── crm_service.dart          # CRM pipeline, deals, followups
│   │   ├── notification_service.dart # Push notifications
│   │   ├── payment_service.dart      # Stripe payments
│   │   └── ...
│   │
│   ├── providers/                    # State Management (ChangeNotifier)
│   │   ├── user_provider.dart        # Current user state, auth lifecycle
│   │   ├── business_provider.dart    # Business profile state
│   │   ├── invoice_provider.dart     # Invoices list, watchers
│   │   ├── expense_provider.dart     # Expenses state
│   │   ├── client_provider.dart      # Clients list
│   │   ├── crm_provider.dart         # CRM pipeline & deals
│   │   ├── task_provider.dart        # Tasks state
│   │   ├── theme_provider.dart       # Dark/light mode
│   │   └── ...
│   │
│   ├── screens/                      # UI Layers (Stateless widgets)
│   │   ├── splash/
│   │   │   └── splash_screen.dart    # Initial loading screen
│   │   ├── auth/
│   │   │   ├── login_screen.dart
│   │   │   ├── signup_screen.dart
│   │   │   └── forgot_password_screen.dart
│   │   ├── dashboard/
│   │   │   └── dashboard_screen.dart # Main dashboard with overview
│   │   ├── invoices/
│   │   │   ├── invoice_list_screen.dart
│   │   │   ├── invoice_detail_screen.dart
│   │   │   └── invoice_create_screen.dart
│   │   ├── expenses/
│   │   │   ├── expense_list_screen.dart
│   │   │   ├── expense_scanner_screen.dart (OCR)
│   │   │   └── expense_detail_screen.dart
│   │   ├── crm/
│   │   │   ├── crm_list_screen.dart
│   │   │   ├── client_details_screen.dart
│   │   │   ├── deals_pipeline_screen.dart
│   │   │   └── crm_ai_insights_screen.dart
│   │   ├── settings/
│   │   │   ├── settings_screen.dart
│   │   │   ├── timezone_settings.dart
│   │   │   ├── locale_settings.dart
│   │   │   ├── digest_settings.dart
│   │   │   └── business_profile_settings_screen.dart
│   │   ├── finance/
│   │   │   ├── finance_dashboard_screen.dart
│   │   │   └── finance_goals_screen.dart
│   │   └── ...
│   │
│   ├── widgets/                      # Reusable components
│   │   ├── theme_toggle_widget.dart
│   │   ├── invoice_list_tile.dart
│   │   └── ...
│   │
│   ├── core/
│   │   ├── utils/
│   │   │   ├── formatters.dart       # formatCurrency(), formatDate(), etc
│   │   │   ├── validators.dart       # Email, phone, etc validation
│   │   │   └── extensions.dart       # String, DateTime extensions
│   │   └── constants/
│   │       └── config.dart           # App name, version, Firebase config
│   │
│   ├── pubspec.yaml                  # Flutter dependencies
│   └── README.md
│
├── functions/                        # Firebase Cloud Functions (TypeScript)
│   ├── src/
│   │   ├── index.ts                  # Main exports & function registrations
│   │   │
│   │   ├── auth/
│   │   │   └── onUserCreate.ts       # Triggers on Firebase Auth user creation
│   │   │
│   │   ├── timezone/
│   │   │   ├── utils.ts              # IANA timezone validation
│   │   │   ├── userTimezone.ts       # Get/set user timezone, quiet hours
│   │   │   └── setUserTimezoneCallable.ts
│   │   │
│   │   ├── locale/
│   │   │   └── localeHelpers.ts      # Locale, currency, formatting helpers
│   │   │
│   │   ├── notifications/
│   │   │   ├── businessNotification.ts # Respects timezone & quiet hours
│   │   │   ├── digestPreferences.ts  # User digest settings CRUD
│   │   │   ├── buildDigest.ts        # Aggregate invoices, expenses, tasks
│   │   │   ├── sendDigestEmail.ts    # Resend email service
│   │   │   ├── sendDigestScheduled.ts # Hourly scheduler for digests
│   │   │   └── resendWebhook.ts      # Webhook for bounces/complaints
│   │   │
│   │   ├── ai/
│   │   │   ├── aiAssistant.ts        # OpenAI API calls
│   │   │   └── ...
│   │   │
│   │   ├── ocr/
│   │   │   ├── ocrProcessor.ts       # Google Vision for receipt OCR
│   │   │   └── ...
│   │   │
│   │   ├── invoicing/
│   │   │   ├── invoiceHelpers.ts
│   │   │   ├── generateInvoicePdf.ts
│   │   │   └── ...
│   │   │
│   │   ├── crm/
│   │   │   ├── generateClientSummary.ts
│   │   │   ├── calculateAIScore.ts   # Client scoring
│   │   │   ├── onInvoiceStatusChange.ts
│   │   │   └── ...
│   │   │
│   │   ├── payments/
│   │   │   ├── stripeWebhook.ts      # Payment webhooks
│   │   │   └── ...
│   │   │
│   │   ├── utils/
│   │   │   ├── formatters.ts         # TypeScript formatters
│   │   │   ├── timestampConverters.ts # Firestore timestamp helpers
│   │   │   └── logger.ts             # Logging utilities
│   │   │
│   │   └── ...
│   │
│   ├── package.json
│   ├── tsconfig.json
│   └── .firebaserc
│
├── firebase/
│   └── firestore.rules              # Firestore security rules
│
├── docs/
│   ├── setup.md
│   ├── architecture.md
│   ├── api_reference.md
│   └── security_standards.md
│
└── README.md
```

---

## 3. Architecture Layers

### **Layer 1: Presentation (Flutter UI)**
**Purpose**: User interface, user interaction
- **Widgets**: Stateless/Stateful for UI rendering
- **Screens**: Page-level containers
- **Pattern**: Consumer<Provider> for state binding
- **Example**: `ExpenseListScreen` reads `ExpenseProvider._expenses`

### **Layer 2: State Management (ChangeNotifier Providers)**
**Purpose**: Local state, business logic orchestration
- **UserProvider**: Current user auth state, triggers device init on login
- **BusinessProvider**: Business profile with auto-sync to Firestore
- **InvoiceProvider**: Invoice list with Firestore listeners
- **Pattern**: `ChangeNotifier` + `notifyListeners()`

### **Layer 3: Services (Firebase + API Clients)**
**Purpose**: Data access & external API calls
- **FirebaseAuth**: User authentication
- **Firestore**: Document database
- **Cloud Functions**: Server-side logic
- **Resend**: Email service
- **OpenAI**: AI chat
- **Google Vision**: Receipt OCR
- **Stripe**: Payments

### **Layer 4: Cloud Functions (TypeScript Backend)**
**Purpose**: Server-side logic, security, automation
- **Callable Functions**: Called from Flutter with custom auth
- **Scheduled Functions**: Cron jobs (e.g., digest emails every hour)
- **Auth Triggers**: Respond to Firebase Auth events
- **Webhooks**: Handle external events (Stripe, Resend)

### **Layer 5: Data (Firestore)**
**Purpose**: Persistent storage
- **Collections**: users, businesses, invoices, expenses, clients, etc.
- **Subcollections**: Per-user data (settings, devices, notifications)
- **Security Rules**: UID-based access control

---

## 4. Technology Stack

| Layer | Technology | Purpose |
|-------|-----------|---------|
| **Frontend** | Flutter 3.7 | Cross-platform (iOS, Android, Web) |
| **State Mgmt** | Provider 6.0 | ChangeNotifier pattern |
| **UI** | Material 3 | Design system |
| **Backend** | Firebase | Auth, Firestore, Storage, Functions |
| **Functions** | TypeScript/Node | Server-side logic |
| **Date/Time** | Luxon 3.7.2 | Timezone handling |
| **Localization** | intl 0.19 | Multi-language support |
| **Device** | flutter_native_timezone 2.0 | Auto timezone detection |
| **Email** | Resend | Transactional emails |
| **AI** | OpenAI API | Chat, content generation |
| **OCR** | Google Vision | Receipt scanning |
| **Payments** | Stripe | Payment processing |
| **Storage** | Firebase Storage | File uploads (invoices, receipts) |

---

## 5. Key Features & Modules

### **A. User Management**
```
┌─ Flutter Auth Screen
├─ Firebase Auth (email/password, Google)
├─ onUserCreate Cloud Function
│  └─ Initialize user doc with defaults
├─ DeviceInitService (runs on login)
│  └─ Detect timezone, locale, country
└─ AppUser Model
   ├─ uid, email, firstName, lastName
   ├─ timezone (UTC), locale (en-US), country (US)
   └─ Persisted in users/{uid}
```

### **B. Timezone & Locale**
```
┌─ TimezoneService (Flutter)
│  ├─ detectDeviceTimezone() - FlutterNativeTimezone
│  ├─ streamUserTimezone() - Firestore listener
│  └─ setUserTimezone() - Cloud Function
│
├─ LocaleService (Flutter)
│  ├─ getLocaleDoc() - User's currency, date format
│  └─ setLocaleDoc() - Update preferences
│
├─ userTimezone.ts (Cloud Function)
│  ├─ convertToUserLocalTime() - UTC → User TZ
│  ├─ isWithinQuietHours() - Check notification window
│  └─ formatPrefsForAudit() - Logging
│
├─ Formatters (Dart & TypeScript)
│  ├─ formatCurrency($) - Locale-aware
│  ├─ formatDate() - User's timezone
│  ├─ formatNumber() - Decimals, separators
│  └─ formatPercentage(%)
│
└─ Settings UI
   ├─ TimezoneSetting Screen
   ├─ LocaleSettings Screen
   └─ DigestSettings Screen
```

### **C. Business Profile**
```
┌─ Business Model
│  ├─ businessName, industry, abn
│  ├─ email, phone, website
│  └─ address, logo, branding (colors, fonts)
│
├─ BusinessProvider (State)
│  ├─ Auto-fetch from Firestore
│  ├─ Watch for updates
│  └─ Expose via Consumer<BusinessProvider>
│
└─ Business Settings Screen
   ├─ Edit details
   ├─ Upload logo
   └─ Configure branding
```

### **D. Invoice Management**
```
┌─ Invoice Model
│  ├─ invoiceNumber (auto-increment per user)
│  ├─ clientId, amount, description
│  ├─ issueDate, dueDate, items[]
│  ├─ status (draft, sent, paid, overdue, cancelled)
│  └─ timezone, locale for formatting
│
├─ InvoiceProvider (State)
│  ├─ Load invoices stream (Firestore)
│  ├─ filterByStatus(), searchByClient()
│  └─ Expose filtered lists
│
├─ Invoice Service
│  ├─ createInvoice() - Callable Function
│  ├─ updateInvoice()
│  ├─ markAsPaid()
│  └─ generatePdf() - Cloud Function
│
├─ PDF Generation (Cloud Function)
│  ├─ Fetch invoice + business data
│  ├─ Format with user's locale
│  ├─ Render to PDF (puppeteer/similar)
│  └─ Store in Cloud Storage
│
└─ UI Screens
   ├─ InvoiceListScreen - All invoices
   ├─ InvoiceDetailScreen - View/edit
   ├─ InvoiceCreateScreen - New invoice
   └─ InvoicePreviewScreen - PDF preview
```

### **E. Expense Management**
```
┌─ Expense Model
│  ├─ amount, category, description
│  ├─ receiptUrl (Cloud Storage)
│  ├─ status (pending_review, approved, rejected)
│  └─ ocrData (parsed receipt text)
│
├─ OCR Pipeline
│  ├─ ExpenseScannerScreen (Take photo)
│  ├─ Upload to Storage: receipts/{userId}/{expenseId}
│  ├─ Call ocrProcessor Cloud Function
│  │  ├─ Google Vision API (extract text)
│  │  └─ OpenAI (parse to structured data)
│  └─ ExpenseReviewScreen (Confirm parsed data)
│
└─ ExpenseProvider
   ├─ Track expense status
   ├─ Sum by category
   └─ Filter pending review
```

### **F. CRM & Client Management**
```
┌─ Client Model
│  ├─ name, email, phone, company
│  ├─ status (prospect, customer, inactive)
│  ├─ aiScore (1-100 based on activity)
│  └─ lastActivityAt, needsFollowup
│
├─ CRM Provider
│  ├─ Load clients from Firestore
│  ├─ Pipeline stages (New, Qualified, Negotiation, Won, Lost)
│  └─ Sort by AI score
│
├─ AI Scoring (Cloud Function)
│  ├─ calculateClientAIScore()
│  ├─ Factors: invoices sent, payments received, engagement
│  ├─ Runs daily (scheduled)
│  └─ Triggers notifications for high-value clients
│
└─ CRM Screens
   ├─ ClientListScreen
   ├─ DealsPipelineScreen (Kanban)
   └─ CrmAiInsightsScreen (Recommendations)
```

### **G. Notification System**
```
┌─ Business Notifications
│  ├─ sendBusinessNotification(uid, payload)
│  ├─ Respects timezone
│  ├─ Checks quiet hours (startHour-endHour in user's TZ)
│  ├─ Critical severity bypasses quiet hours
│  └─ Sent via FCM + logged
│
├─ Quiet Hours Setting
│  ├─ Stored in users/{uid}/settings/notification_preferences
│  ├─ Format: { enabled: bool, startHour: 22, endHour: 7 }
│  └─ Times in user's timezone
│
└─ Notification Types
   ├─ invoice_paid
   ├─ invoice_overdue
   ├─ expense_approved
   ├─ client_high_priority
   └─ system_alerts
```

### **H. Email Digest System**
```
┌─ Digest Preferences
│  ├─ users/{uid}/settings/digest
│  ├─ digestEnabled, digestFrequency (daily/weekly)
│  ├─ preferredHour (user's local time)
│  ├─ includeInvoices, includeExpenses, includeTasks, includeStock, includeCRM
│  └─ updatedAt
│
├─ Digest Builder
│  ├─ getPendingInvoices() - unpaid, limit 10
│  ├─ getPendingExpenses() - pending_review, limit 10
│  ├─ getPendingTasks() - incomplete, limit 15
│  ├─ getLowStockItems() - qty <= 5, limit 10
│  └─ getCRMFollowups() - needsFollowup, limit 15
│
├─ Digest Scheduler
│  ├─ sendHourlyDigests (Cloud Scheduler, every hour)
│  ├─ For each user: shouldSendDigestNow(uid)
│  ├─ Convert to user's local time
│  ├─ Check hour match + frequency
│  └─ Build & send
│
├─ Email Service (Resend)
│  ├─ sendDigestEmail() - Queue email
│  ├─ Resend webhook handler
│  │  ├─ email.delivered
│  │  ├─ email.bounced - Auto-disable digest
│  │  └─ email.complained - Auto-disable digest
│  └─ Audit log in sentEmails subcollection
│
└─ Digest Settings UI
   ├─ DigestSettingsScreen
   ├─ Toggle enable/disable
   ├─ Select frequency (daily/weekly)
   ├─ Choose preferred hour (slider 0-23)
   ├─ Select categories
   └─ Save to Firestore
```

---

## 6. Data Models & Firestore Schema

### **Users Collection**
```
users/{uid}
├─ email: string
├─ firstName, lastName: string
├─ avatarUrl: string
├─ timezone: string (default: "UTC")
├─ locale: string (default: "en-US")
├─ country: string (default: "US")
├─ auraTokens: number
├─ createdAt, updatedAt: Timestamp
│
└─ Subcollections:
   ├─ settings/
   │  ├─ digest: { digestEnabled, digestFrequency, preferredHour, includeXXX }
   │  ├─ timezone: { timezone, quietHours }
   │  ├─ locale: { locale, currency, dateFormat }
   │  └─ notification_preferences: { enabled, channels }
   │
   ├─ invoices/ { invoiceNumber, amount, status, dueDate, items[] }
   ├─ expenses/ { amount, category, receiptUrl, status, ocrData }
   ├─ clients/ { name, email, status, aiScore, lastActivityAt }
   ├─ tasks/ { title, description, status, dueDate, priority }
   ├─ devices/ { fcmToken, platform, lastActive }
   ├─ sentEmails/ { type, to, subject, resendMessageId, status, sentAt }
   └─ notificationLog/ { title, body, type, sentAt, zone }
```

### **Businesses Collection**
```
businesses/{businessId}
├─ uid: string (owner)
├─ businessName, industry, abn: string
├─ email, phone, website: string
├─ address: { street, city, state, zip, country }
├─ logoUrl: string
├─ branding: { primaryColor, accentColor, fontFamily }
└─ createdAt, updatedAt: Timestamp
```

### **Firestore Security Rules**
```typescript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own document
    match /users/{userId} {
      allow read, write: if request.auth.uid == userId;
      
      // Subcollections inherit parent rules
      match /{subcollection}/{document=**} {
        allow read, write: if request.auth.uid == userId;
      }
    }
    
    // Deny all other access
    match /{document=**} {
      allow read, write: if false;
    }
  }
}
```

---

## 7. Cloud Functions Organization

### **Callable Functions** (Called from Flutter)
```typescript
// Timezone
export setUserTimezoneCallable(data, context) // Validates auth, timezone

// CRM
export generateCrmInsights(data, context) // AI insights

// Payments
export createPaymentIntent(data, context) // Stripe

// Utilities
export verifyUserTokenData(data, context) // AuraToken verification
```

### **Scheduled Functions** (Cloud Scheduler)
```typescript
// Every hour
export sendHourlyDigests // Check & send digests for users

// Daily
export dailyScoreRefresh // Recalculate client AI scores

// Monthly
export calculateMonthlyMetrics // Finance summaries
```

### **Auth Triggers**
```typescript
// When user signs up
export onUserCreate(user) // Initialize user doc with defaults
```

### **Webhooks** (External services)
```typescript
// From Stripe
export stripeWebhook(req, res) // Payment confirmations

// From Resend
export resendWebhook(req, res) // Email delivery/bounce events
```

---

## 8. State Management Flow

### **Example: Invoice Listing**

```
User Taps "Invoices" Tab
  ↓
InvoiceListScreen (Consumer<InvoiceProvider>)
  ↓
InvoiceProvider._init() runs:
  1. _invoiceService.getInvoices(uid) - Initial load
  2. _db.collection("users").doc(uid).collection("invoices").snapshots().listen(...)
  3. setState() on new data
  4. UI rebuilds via notifyListeners()
  ↓
InvoiceListScreen displays:
  - List of invoices
  - Filter by status
  - Search by client
  ↓
User taps "Create Invoice"
  ↓
InvoiceCreateScreen
  ↓
User fills form → Taps "Save"
  ↓
InvoiceProvider.createInvoice()
  1. Call Cloud Function: createInvoice(uid, invoiceData)
  2. Function validates, saves to Firestore
  3. Listener in InvoiceProvider detects change
  4. Rebuilds UI with new invoice
```

---

## 9. User Authentication Flow

```
Splash Screen (Initial)
  ↓
Check Firebase Auth state
  ├─ Logged in → Load AppUser → Dashboard
  └─ Not logged in → Auth Screen
      ↓
      [Login or Signup]
      ↓
      Firebase Auth (email/password or Google)
      ↓
      onUserCreate Cloud Function triggers
      │ └─ Initialize: timezone='detect', locale='detect'
      ↓
      UserProvider._init() detects auth change
      ├─ DeviceInitService.initializeUserDeviceInfo()
      │  ├─ Detect device timezone
      │  ├─ Detect device locale
      │  ├─ Extract country from locale
      │  └─ Save to Firestore
      │
      ├─ BusinessProvider.start(uid)
      │  └─ Load business profile
      │
      └─ Dashboard loaded
```

---

## 10. Timezone-Aware Operations

### **Example: Invoice Due Reminder**

```
Invoice created in NYC (EST -5)
  ├─ dueDate: "2024-12-20"
  └─ Stored in Firestore (UTC)

Business Notification Trigger (Daily 9 AM):
  ↓
sendBusinessNotification(uid, {
  title: "Invoice Due Tomorrow",
  body: "Invoice #001 for $5000 due Dec 20",
  severity: "high"
})
  ↓
1. Get user's timezone from users/{uid}
   → "America/New_York" (EST)

2. Convert current UTC time to user's timezone
   → "2024-12-19 08:45:00 EST"

3. Check quiet hours
   → Hours: 22:00 - 07:00
   → Current: 08:45 → Outside quiet hours ✓

4. Send notification via FCM
   → Device receives in EST timezone

5. Log with timezone info
   → "2024-12-19 08:45:00 EST, America/New_York"
```

---

## 11. Digest Email Example

```
User's Settings:
├─ digestEnabled: true
├─ digestFrequency: "daily"
├─ preferredHour: 8 (8:00 AM local time)
├─ timezone: "Australia/Sydney" (AEDT +11)
├─ includeInvoices: true
├─ includeExpenses: true
├─ includeTasks: true

Daily Scheduler (Every hour UTC):
  ↓
11:00 PM UTC = 10:00 AM Sydney time (next day)
  ↓
shouldSendDigestNow("user123")
  1. Get timezone: "Australia/Sydney"
  2. Convert current UTC to Sydney time
  3. Check if hour == 8 → NO (it's 10)
  ↓
No digest sent (yet)

...

Later, 10:00 PM UTC = 9:00 AM Sydney time (next day)
  ↓
shouldSendDigestNow("user123")
  1. Convert 10:00 PM UTC → 9:00 AM Sydney
  2. Check if hour == 8 → NO (it's 9)
  ↓
No digest sent

(Timing depends on hourly scheduler + timezone math)

When hour finally matches (8:00 AM Sydney):
  ↓
buildDigestForUser("user123", prefs)
  1. Get pending invoices (unpaid)
  2. Get pending expenses (to review)
  3. Get tasks (incomplete)
  4. Format HTML with totals
  ↓
sendDigestEmail(uid, html, subject)
  ↓
Resend API
  ├─ From: digest@aurasphere.app
  ├─ To: user@example.com
  ├─ Subject: Your Daily Digest - 3 items
  └─ HTML: Professional template with items
  ↓
Resend webhook sends event:
  └─ email.delivered → Log success

User receives email at 8:00 AM Sydney time! ✓
```

---

## 12. Deployment Checklist

### **Firebase Functions**
```bash
# 1. Set configuration
firebase functions:config:set resend.api_key="re_xxx..."
firebase functions:config:set resend.webhook_secret="whsec_xxx..."

# 2. Deploy
firebase deploy --only functions

# 3. Verify in Console
firebase functions:list
```

### **Firestore Rules**
```bash
firebase deploy --only firestore:rules
```

### **Flutter App**
```bash
# 1. Build APK/IPA
flutter build apk --release
flutter build ios --release

# 2. Deploy to stores
# Android: Upload to Google Play
# iOS: Upload to App Store
```

---

## 13. Key Design Patterns

| Pattern | Usage | Example |
|---------|-------|---------|
| **MVC** | UI, Logic, Data separation | Screen → Provider → Service |
| **Provider** | State management | ChangeNotifier pattern |
| **Service Layer** | API abstraction | `InvoiceService` wraps Firestore calls |
| **Factory Pattern** | Model creation | `Invoice.fromFirestore(doc)` |
| **Singleton** | Database access | `FirebaseFirestore.instance` |
| **Observer** | Listen to data | Firestore `.snapshots()` listeners |
| **Callable** | Secure Functions | `FunctionsService().callFunction()` |
| **Webhook** | External events | Stripe, Resend webhooks |

---

## 14. Security Architecture

### **Authentication**
- Firebase Auth (email, Google)
- JWT tokens issued by Firebase
- Token included in Callable Function calls

### **Authorization**
- Firestore rules check `request.auth.uid`
- Users can only access their own documents
- Cloud Functions verify context.auth

### **Data Protection**
- Cloud Storage limits (5 MB receipts, 10 MB uploads)
- File paths include userId: `receipts/{userId}/{expenseId}`
- All sensitive data encrypted at rest (Firebase default)

### **API Security**
- Resend webhooks signed with HMAC-SHA256
- Stripe webhooks verified before processing
- OpenAI API key stored in Cloud Functions config

---

## 15. Performance Optimizations

1. **Firestore Indexing**
   - Composite indexes for queries (status, createdAt)
   - Single-field indexes on frequently searched fields

2. **Caching**
   - Flutter Provider caches user data in memory
   - Firestore offline persistence enabled

3. **Pagination**
   - Invoice list loads 20 at a time
   - Lazy load more on scroll

4. **Cloud Function Optimization**
   - Minimal cold start (Node.js 18)
   - Reuse Firestore instance
   - Batch writes for bulk operations

5. **Image Optimization**
   - Compress logos on upload
   - Use WebP format for modern clients

---

## 16. Monitoring & Logging

### **Cloud Functions Logging**
```typescript
import * as functions from 'firebase-functions';
const logger = functions.logger;

logger.info('[functionName] Message', { data: value });
logger.warn('[functionName] Warning', { error });
logger.error('[functionName] Error', error);
```

### **Metrics**
- Function execution time
- Error rates per function
- Firestore read/write operations
- Email delivery success rate

### **Debugging**
- Firebase Console → Functions → Logs
- Firestore Console → Database → Documents
- Firebase Storage → Files
- Resend Dashboard → Emails

---

## Summary

**AuraSphere Pro** is a **production-ready SaaS** with:
- ✅ Multi-platform Flutter frontend
- ✅ Serverless Firebase backend
- ✅ Timezone-aware notifications
- ✅ Email digest scheduling
- ✅ OCR & AI integration
- ✅ CRM with AI scoring
- ✅ Invoice & expense management
- ✅ Payment processing
- ✅ Comprehensive security

All components are **loosely coupled**, **scalable**, and **maintainable**.
