# AuraSphere Pro - Complete App Structure & Features

## 📱 CORE MODULES

### 1. **Authentication & Onboarding**
- Splash Screen (Entry point)
- Onboarding (User introduction)
- Login Screen
- Signup Screen
- Forgot Password Screen
- Google Sign-In integration

---

## 2. **Dashboard**
- Main dashboard screen
- Overview of all features
- Quick access to modules

---

## 3. **CRM (Customer Relationship Management)**
- **CRM List Screen** - View all contacts
- **CRM Contact Screen** - Add new contacts
- **CRM Contact Detail** - View contact details
- **CRM Detail Screen** - Edit contact info
- **Deals Pipeline Screen** - Sales funnel visualization
- **CRM AI Insights** - AI-powered customer analytics

### CRM Features:
- Add/Edit/Delete contacts
- Contact categorization
- Interaction tracking
- Pipeline management
- AI insights on customer behavior

---

## 4. **Clients Management**
- **Clients List Screen** - View all clients
- **Client Detail Screen** - View individual client
- **Edit Client Screen** - Modify client info
- **Add Client Screen** (Duplicate of CRM)

### Client Features:
- Full client database
- Client profile management
- Contact information
- Relationship history

---

## 5. **Invoicing System**
- **Invoice Template Select** - Choose template
- **Invoice Create** (Temporarily disabled)
- **Invoice Settings Screen** - Configure invoice defaults
- **Payment History Screen** - View past payments
- **Invoice Audit Screen** - Track invoice changes
- **Invoice Branding Screen** - Customize invoice appearance
- **Template Gallery Screen** - Browse invoice templates

### Invoice Features:
- Multiple invoice templates
- Custom branding/logo
- Payment tracking
- Invoice numbering
- Audit trail for compliance
- Template library

---

## 6. **Expenses Management**
- **Expense Scanner Screen** - OCR receipt scanning
- **Expense List Screen** - View all expenses
- **Expense Scan Screen** - Manual expense entry
- **Expense Review Screen** - Approve/edit expenses
- **Expense Detail Screen** - View expense details
- **Receipt OCR Processing** - AI-powered receipt parsing

### Expense Features:
- Receipt scanning with OCR
- Automatic merchant & amount extraction
- Manual entry option
- Expense categorization
- Image storage
- Expense history
- Audit logging

---

## 7. **Supplier Management**
- **Supplier Screen** - Full CRUD operations
  - Create supplier
  - View supplier list (real-time stream)
  - Search suppliers
  - Edit supplier info
  - Delete supplier

### Supplier Features:
- Complete supplier database
- Supplier contact info
- Search functionality
- Real-time list updates
- Delete with confirmation

---

## 8. **Purchase Orders**
- **PO PDF Preview** - View PDF before sending
- **PO Email Modal** - Send via email

### PO Features:
- Create purchase orders
- PDF generation
- Email distribution
- Attachment support

---

## 9. **Finance Management**
- **Finance Dashboard** - Financial overview
- **Finance Goals Screen** - Set & track financial goals
- **Finance Coach (AI)** - AI-powered financial advice

### Finance Features:
- Income/expense overview
- Financial goal setting
- Trend analysis
- AI coaching
- Budget planning

---

## 10. **Loyalty System** ⭐ (NEW)
- **Daily Login Bonus** - 5 tokens per day
- **Streak Tracking** - Consecutive login counter
- **Weekly Bonus** - 50 tokens for 7-day streak
- **Milestones** - Bronze/Silver/Gold/Platinum/Diamond
- **Token Audit Trail** - Complete transaction history
- **Special Day Multipliers** - Holiday bonuses

### Loyalty Features:
- Daily login rewards
- Streak bonuses (capped at 20 max)
- Milestone achievements with badges
- Token wallet balance
- Complete transaction audit log
- Real-time stream updates
- Global configuration management
- Payment record tracking

---

## 11. **Wallet & Billing**
- **Token Shop Screen** - Buy tokens
- **Token Store Screen** - Token marketplace
- **Payment Success Page** - Confirmation screen
- **Wallet Profile** - View balance & transactions

### Wallet Features:
- Token balance display
- Purchase packages
- Transaction history
- Payment processing
- Token spending tracking

---

## 12. **Tasks Management**
- **Tasks List Screen** - View all tasks
- Task creation/editing
- Task completion tracking

### Task Features:
- Task creation
- Due dates
- Priority levels
- Status tracking
- Team assignment

---

## 13. **Projects Management**
- Project creation
- Project timeline
- Team collaboration

---

## 14. **Inventory Management**
- **Inventory Screen** - View inventory items
- Stock tracking
- Reorder alerts

---

## 15. **Anomaly Detection & Alerts** 🚨
- **Anomaly Center Screen** - Detect unusual patterns
- **Alerts Center Screen** - View all alerts
- **Anomaly Dashboard** - Analytics & trends
- **Audit History** - Track system changes

### Anomaly Features:
- Automated pattern detection
- Alert system
- Suspicious activity tracking
- Compliance audit trail

---

## 16. **Settings & Preferences**
- **Timezone Settings** - User timezone configuration
- **Locale Settings** - Language & region
- **Digest Settings** - Email notification preferences
- **Invoice Branding** - Custom branding
- **Template Gallery** - Invoice templates

---

## 17. **AI Features** 🤖
- **CRM AI Insights** - Customer analytics
- **Finance Coach** - Financial advice
- **Expense OCR** - Receipt parsing
- **AI Assistant** (General purpose)

---

---

## 🏗️ TECHNICAL ARCHITECTURE

### **Frontend Stack**
- **Framework:** Flutter 3.24.3
- **Language:** Dart 3.5.3
- **State Management:** Provider, Riverpod
- **UI:** Material Design 3

### **Backend Stack**
- **Backend:** Firebase (Firestore, Auth, Storage, Functions)
- **Cloud Functions:** Node.js 20, TypeScript
- **Database:** Firestore (NoSQL)
- **Authentication:** Firebase Auth + Google Sign-In
- **File Storage:** Firebase Storage

### **Key Libraries**
| Purpose | Library | Version |
|---------|---------|---------|
| Firebase Core | firebase_core | ^3.6.0 |
| Authentication | firebase_auth | ^5.3.0 |
| Database | cloud_firestore | ^5.6.12 |
| Storage | firebase_storage | ^12.4.10 |
| Functions | cloud_functions | ^5.6.2 |
| State Mgmt | provider | ^6.0.5 |
| UI Charts | fl_chart | ^0.65.0 |
| PDF | pdf | ^3.10.4 |
| OCR | google_ml_kit | ^0.7.2 |
| Fonts | google_fonts | ^6.1.0 |

---

## 📁 FOLDER STRUCTURE

```
lib/
├── app/                 # App configuration
├── components/          # Reusable components
├── config/              # App routes, constants
├── core/                # Core utilities
├── data/                # Data models
├── localization/        # i18n strings
├── main.dart            # Entry point
├── models/              # Data models
│   ├── loyalty_model.dart
│   ├── loyalty_config_model.dart
│   ├── loyalty_transactions_model.dart
│   └── ...
├── providers/           # State management
├── screens/             # UI Screens
│   ├── auth/
│   ├── crm/
│   ├── clients/
│   ├── invoices/
│   ├── expenses/
│   ├── suppliers/
│   ├── purchase_orders/
│   ├── finance/
│   ├── billing/
│   ├── wallet/
│   ├── tasks/
│   ├── settings/
│   ├── ai/
│   ├── anomalies/
│   └── ...
├── services/            # Business logic
│   ├── loyalty_service.dart
│   ├── supplier_service.dart
│   ├── client_service.dart
│   ├── invoice_service.dart
│   ├── expense_ocr_service.dart
│   └── ...
├── utils/               # Utilities & helpers
├── widgets/             # Custom widgets
│   ├── streak_widget.dart
│   └── ...
└── config/
    └── constants.dart

functions/
├── src/
│   ├── loyalty/
│   │   └── loyaltyEngine.ts        # Core loyalty logic
│   ├── tokens/
│   │   ├── onUserLogin.ts          # Daily login trigger
│   │   ├── milestoneChecker.ts     # Milestone detection
│   │   └── dailyStreakScheduler.ts # Weekly bonus scheduler
│   ├── ai/
│   ├── ocr/
│   ├── billing/
│   ├── finance/
│   ├── crm/
│   ├── projects/
│   ├── auraToken/
│   └── utils/
└── ...
```

---

## 🔥 FIRESTORE COLLECTIONS

### User Collections
- `users/{uid}/loyalty/profile` - User loyalty data
- `users/{uid}/token_audit/{txId}` - Token transactions
- `users/{uid}/wallet/aura` - Token balance
- `users/{uid}/clients/{clientId}` - Client info
- `users/{uid}/suppliers/{supplierId}` - Supplier info
- `users/{uid}/invoices/{invoiceId}` - Invoice data
- `users/{uid}/expenses/{expenseId}` - Expense records
- `users/{uid}/notifications/{notifId}` - User notifications

### Global Collections
- `loyalty_config/global` - Global loyalty settings
- `payments_processed/{sessionId}` - Payment records
- `users/` - User profiles & metadata

---

## ⚙️ CLOUD FUNCTIONS

### Loyalty Functions
1. **onUserLogin** - Called when user logs in
   - Checks daily bonus eligibility
   - Calculates streak
   - Credits tokens
   - Creates audit entry

2. **onTokenCredit** - Triggers on token_audit creation
   - Checks milestone eligibility
   - Awards badges
   - Updates milestones

3. **dailyLoyaltyHousekeeping** - Scheduled daily (01:00 UTC)
   - Processes weekly bonuses
   - Manages streaks
   - Pagination support

### Other Functions
- AI Assistant (OpenAI integration)
- OCR Processor (Receipt parsing)
- Invoice Functions
- Payment Functions
- CRM Functions
- Project Functions

---

## 🔐 SECURITY & RULES

### Firestore Rules
- User data protected (read/write access)
- Server-only loyalty writes
- Immutable transaction logs
- Public global config (read-only)
- Payment records webhook-only

### Authentication
- Firebase Auth required
- Email + Password
- Google Sign-In
- Session management
- UID-based access control

---

## 🎯 KEY FEATURES BY PRIORITY

### ✅ Production Ready
- Authentication system
- CRM with contacts
- Client management
- Invoice creation & templates
- Expense OCR scanning
- Supplier CRUD
- Purchase orders
- Finance dashboard
- **Loyalty System (Complete)**
  - Daily bonuses
  - Streak tracking
  - Milestones
  - Token wallet
  - Audit logging

### 🟡 In Progress
- AI Insights enhancement
- Finance coach refinement
- Anomaly detection tuning

### ⚪ Future (Not Yet)
- Crypto wallet (disabled)
- Advanced reporting
- Team collaboration features

---

## 📊 DATABASE SCHEMA (Loyalty)

```
/loyalty_config/global
├── daily
│   ├── baseReward: 50
│   ├── streakBonus: 10
│   └── maxStreakBonus: 500
├── weekly
│   ├── thresholdDays: 7
│   └── bonus: 500
├── milestones: [
│   {id: "bronze", threshold: 1000, reward: 100},
│   {id: "silver", threshold: 5000, reward: 500},
│   ...
│ ]
└── specialDays: []

/users/{uid}/loyalty/profile
├── streak: {current, lastLogin, frozenUntil}
├── totals: {lifetimeEarned, lifetimeSpent}
├── badges: [{id, name, level, earnedAt}]
├── milestones: {bronze, silver, gold, platinum, diamond}
├── lastBonus: timestamp
└── updatedAt: timestamp

/users/{uid}/token_audit/{txId}
├── action: "daily_bonus" | "milestone" | "purchase" | ...
├── amount: number
├── reason: string
├── meta: {streak, multiplier, reason}
└── createdAt: timestamp

/payments_processed/{sessionId}
├── uid: string
├── packId: string
├── tokens: number
├── amount: number
├── currency: "EUR"
├── status: "completed"
└── processedAt: timestamp
```

---

## 🚀 DEPLOYMENT CHECKLIST

- ✅ Flutter app compiles (web/mobile)
- ✅ Firebase config files in place
- ✅ Cloud Functions deployed
- ✅ Firestore rules deployed
- ✅ Security rules configured
- ✅ Indexes created
- ✅ Environment variables set
- ⏳ Ready for production deployment

---

## 📈 METRICS

- **Total Screens:** 40+
- **Services:** 15+
- **Models:** 20+
- **Cloud Functions:** 10+
- **Firestore Collections:** 15+
- **Authentication Methods:** 2 (Email, Google)
- **AI Integrations:** 3 (OpenAI, Vision, Finance)

---

## 🔗 KEY INTEGRATION POINTS

1. **Firebase** ← All data operations
2. **Cloud Functions** ← Business logic
3. **OpenAI** ← AI features
4. **Google ML Kit** ← OCR/Vision
5. **Stripe** ← Payments
6. **SendGrid** ← Email
7. **Google Cloud** ← Infrastructure

---

## ✨ RECENT UPDATES

- ✅ Loyalty system fully implemented
- ✅ Supplier CRUD with real-time streams
- ✅ Expense OCR integration
- ✅ Path consistency (all `/loyalty/profile`)
- ✅ Firestore indexes optimized
- ✅ Security rules enforced
- ✅ Token audit logging complete
- ✅ Daily/weekly bonus system ready

---

## 📝 NOTES

- App runs on `http://localhost:8888` (Flutter web)
- Firebase emulators available locally
- All compilation errors resolved
- Ready for testing in running app
- Production deployment ready

