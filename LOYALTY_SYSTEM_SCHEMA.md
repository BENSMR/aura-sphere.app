# AuraSphere Pro - Loyalty System Schema & Implementation

## Overview
Complete Firestore schema design for user loyalty, badge tracking, payment records, and token auditing with real-time updates and provider integration.

---

## 📊 Data Collections

### 1. `/users/{uid}/loyalty/profile`

**User loyalty profile document**

```dart
UserLoyalty {
  uid: String,
  streak: {
    current: int,              // Current login streak (0+ days)
    lastLogin: timestamp,      // Last login date
    frozenUntil: timestamp?    // Streak frozen until date (null = not frozen)
  },
  totals: {
    lifetimeEarned: int,       // Total tokens ever earned
    lifetimeSpent: int         // Total tokens ever spent
  },
  badges: [{                   // Array of earned badges
    id: String,                // Badge identifier
    name: String,              // Display name
    level: int,                // Badge level/tier
    earnedAt: timestamp        // When earned
  }],
  milestones: {                // Milestone achievement flags
    bronze: bool,              // $1,000 lifetime spent
    silver: bool,              // $5,000 lifetime spent
    gold: bool,                // $10,000 lifetime spent
    platinum: bool,            // $25,000 lifetime spent
    diamond: bool              // $50,000 lifetime spent
  },
  lastBonus: timestamp?        // Last daily bonus claimed timestamp
}
```

**Security Rules:**
- ✅ Users can read/write their own loyalty profile
- ✅ Admin can read/write all profiles
- ✅ Prevents decreasing lifetime totals
- ✅ Validates streak, totals, badges, milestones structure

---

### 2. `/users/{uid}/token_audit/{txId}`

**Token transaction audit logs (immutable)**

```dart
TokenAuditEntry {
  txId: String,              // Transaction ID (auto-generated)
  uid: String,               // User ID
  action: String,            // Action type: daily_bonus, purchase, badge_awarded, milestone_achieved, streak_frozen
  amount: int,               // Tokens involved (0 for non-token actions)
  sessionId: String?,        // Payment session ID (if purchase-related)
  createdAt: timestamp,      // When transaction occurred
  metadata: {                // Additional context
    streak: int?
    special: bool?
    packId: String?
    badgeId: String?
    milestone: String?
    frozenUntil: String?
  }?
}
```

**Retention:**
- ✅ Immutable transaction logs (append-only)
- ✅ User can read own logs
- ✅ Admin can access all logs
- ✅ Ordered by `createdAt` descending for efficient pagination

**Action Types:**
- `daily_bonus` — Daily login bonus awarded
- `purchase` — Token pack purchased
- `badge_awarded` — Badge earned
- `milestone_achieved` — Milestone unlocked
- `streak_frozen` — Login streak frozen

---

### 3. `/payments_processed/{sessionId}`

**Payment processing records**

```dart
PaymentProcessed {
  sessionId: String,    // Unique payment session ID
  uid: String,          // User who made payment
  packId: String,       // Token pack purchased
  tokens: int,          // Tokens received
  processedAt: timestamp // When payment processed
}
```

**Security Rules:**
- ✅ User can read own payment records
- ✅ Admin can read/write all records
- ✅ Validates sessionId, uid, packId, tokens required
- ✅ Prevents zero/negative tokens

**Purpose:**
- Idempotency tracking (prevent duplicate payments)
- Reconciliation with Stripe webhooks
- Fraud detection
- User payment history

---

### 4. `/loyalty_config/global`

**Global loyalty configuration (singleton)**

```dart
LoyaltyConfig {
  daily: {
    baseReward: int,       // Base tokens for daily login (default: 50)
    streakBonus: int,      // Bonus per streak day (default: 10)
    maxStreakBonus: int    // Cap on streak bonus (default: 500)
  },
  weekly: {
    thresholdDays: int,    // Days for weekly bonus trigger (default: 7)
    bonus: int             // Weekly bonus tokens (default: 500)
  },
  milestones: [{           // Milestone definitions
    id: String,            // milestone key: bronze, silver, gold, platinum, diamond
    name: String,          // Display name
    tokensThreshold: int,  // Lifetime tokens to unlock
    reward: int            // One-time bonus tokens
  }],
  specialDays: [{          // Holiday/special event multipliers
    dateISO: String,       // YYYY-MM-DD or MM-DD format
    bonusMultiplier: double, // 1.0x = normal, 2.0x = double, etc
    name: String           // Display name (e.g., "Christmas")
  }]
}
```

**Defaults:**
```dart
LoyaltyConfig(
  daily: DailyConfig(baseReward: 50, streakBonus: 10, maxStreakBonus: 500),
  weekly: WeeklyConfig(thresholdDays: 7, bonus: 500),
  milestones: [
    MilestoneItem(id: 'bronze', name: 'Bronze Member', tokensThreshold: 1000, reward: 100),
    MilestoneItem(id: 'silver', name: 'Silver Member', tokensThreshold: 5000, reward: 500),
    MilestoneItem(id: 'gold', name: 'Gold Member', tokensThreshold: 10000, reward: 1000),
    MilestoneItem(id: 'platinum', name: 'Platinum Member', tokensThreshold: 25000, reward: 2500),
    MilestoneItem(id: 'diamond', name: 'Diamond Member', tokensThreshold: 50000, reward: 5000),
  ],
  specialDays: [
    SpecialDay(dateISO: '12-25', bonusMultiplier: 2.0, name: 'Christmas'),
    SpecialDay(dateISO: '01-01', bonusMultiplier: 1.5, name: 'New Year'),
    SpecialDay(dateISO: '07-04', bonusMultiplier: 1.5, name: 'Independence Day'),
  ],
)
```

**Security Rules:**
- ✅ All authenticated users can read config
- ✅ Only admin can write config
- ✅ Single document design for efficient global access

---

## 🔧 Implementation Files

### Data Models
- `lib/models/loyalty_model.dart` — User loyalty, streak, totals, badges, milestones
- `lib/models/loyalty_transactions_model.dart` — Payment & audit models
- `lib/models/loyalty_config_model.dart` — Configuration models

### Services
- `lib/services/loyalty_service.dart` — Firestore operations & business logic

### Providers
- `lib/providers/loyalty_provider.dart` — State management with ChangeNotifier

### Rules
- `firestore-loyalty.rules` — Security rules for all loyalty collections

---

## 📱 Usage Examples

### Initialize Loyalty on New User Signup
```dart
final loyaltyProvider = Provider.of<LoyaltyProvider>(context, listen: false);
await loyaltyProvider.initializeUserLoyalty(uid);
```

### Process Daily Login Bonus
```dart
final reward = await loyaltyProvider.processDailyLogin(uid);
print('Earned $reward tokens!');
```

### Record Payment & Update Totals
```dart
await loyaltyProvider.recordPayment(sessionId, uid, packId, tokenCount);
```

### Stream Real-Time Loyalty Data
```dart
StreamBuilder<UserLoyalty?>(
  stream: Provider.of<LoyaltyProvider>(context).streamUserLoyalty(uid),
  builder: (context, snapshot) {
    final loyalty = snapshot.data;
    return Text('Streak: ${loyalty?.streak.current ?? 0} days');
  },
)
```

### Check & Award Milestone
```dart
final success = await loyaltyProvider.checkAndUpdateMilestone(uid, 'gold');
if (success) {
  print('Gold Member achievement unlocked!');
}
```

### View Token Audit History
```dart
await loyaltyProvider.fetchTokenAuditLogs(uid);
final logs = loyaltyProvider.auditLogs;
```

### Get Progress to Next Milestone
```dart
final nextMilestone = loyaltyProvider.getNextMilestone();
final progress = loyaltyProvider.getProgressToNextMilestone(); // 0-100%
```

---

## 🔐 Security Design

### Authentication & Authorization
- ✅ Users can only read/modify their own loyalty profile
- ✅ Payment records tied to user ID
- ✅ Audit logs immutable for legal compliance
- ✅ Admin-only configuration access

### Data Validation
- ✅ Streak structure validation
- ✅ Totals monotonic increase (no decreases allowed)
- ✅ Badge array structure validation
- ✅ Milestone boolean validation
- ✅ Audit entry required fields validation
- ✅ Payment records require sessionId uniqueness

### Firestore Indexes Required
```
Collection: /users/{uid}/token_audit
Fields: createdAt (Descending)
```

---

## 📈 Computed Metrics

**In LoyaltyProvider:**
- `currentStreak` — Current login streak days
- `lifetimeEarned` — Total tokens earned (all sources)
- `lifetimeSpent` — Total tokens spent/purchased
- `badgeCount` — Number of earned badges
- `isBronze/isSilver/isGold/isPlatinum/isDiamond` — Milestone flags
- `getNextMilestone()` — Next achievable milestone
- `getProgressToNextMilestone()` — 0-100% progress bar value

---

## 🎯 Daily Bonus Calculation

```
Base Reward = 50 tokens

Streak Bonus = min(streak_days * 10, 500)
  Day 1:  50 + min(10, 500) = 60 tokens
  Day 7:  50 + min(70, 500) = 120 tokens
  Day 50: 50 + min(500, 500) = 550 tokens (capped)

Special Day Multiplier = 1.0x (normal) to 2.0x (holiday)
  Christmas: (base + streak) * 2.0
  New Year:  (base + streak) * 1.5

Total Daily = (Base + Streak) * Multiplier
```

---

## 🔄 Real-Time Updates

### Stream Patterns
All major entities have stream methods for real-time UI updates:

```dart
// Stream user loyalty for live dashboard
streamUserLoyalty(uid)

// Stream loyalty config for dynamic bonus calculations
streamLoyaltyConfig()

// Stream audit logs for transaction history
streamTokenAuditLogs(uid)
```

### Provider Integration
```dart
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
  ],
  child: MyApp(),
)
```

---

## 📋 Implementation Checklist

- ✅ Create data models (3 files)
- ✅ Create loyalty service (Firestore operations)
- ✅ Create loyalty provider (state management)
- ✅ Add Firestore rules validation
- ✅ Create Firestore index for audit logs
- ✅ Add provider to MultiProvider in app.dart
- ✅ Initialize loyalty config on first admin access
- ✅ Call `initializeLoyaltyProfile()` on user signup
- ✅ Call `processDailyLogin()` on app launch
- ✅ Hook `recordPayment()` to Stripe webhook handler
- ✅ Create UI screens for:
  - [ ] Loyalty dashboard with streak display
  - [ ] Milestone progress tracker
  - [ ] Badge showcase
  - [ ] Token audit history viewer

---

## 🚀 Deployment Steps

1. **Update Firestore Rules**
   ```bash
   firebase deploy --only firestore:rules
   ```

2. **Initialize Global Config** (admin dashboard or function)
   ```dart
   await LoyaltyService().initializeLoyaltyConfig();
   ```

3. **Create Audit Index** (if not auto-created)
   - Firestore Console → Indexes
   - Collection: `/users/{uid}/token_audit`
   - Field: `createdAt` (Descending)

4. **Add to App Initialization**
   ```dart
   // In app.dart MultiProvider
   ChangeNotifierProvider(create: (_) => LoyaltyProvider()),
   ```

5. **Hook Daily Login**
   - On app startup, call `processDailyLogin(uid)`
   - Track last login timestamp to prevent duplicates

6. **Hook Payment Processing**
   - On successful Stripe charge, call `recordPaymentProcessed()`
   - Call `checkAndUpdateMilestone()` if lifetimeSpent increased

---

## 📊 Example Data Flow

```
User Opens App
  ↓
Check daily bonus eligibility
  ↓
processDailyLogin(uid) called
  ↓
Firestore: /users/{uid}/loyalty/profile updated
  ↓
Token audit log created: token_audit/{txId}
  ↓
Provider notifies UI listeners
  ↓
Display animation: "+50 tokens earned"
  ↓
Stream updates real-time balance display
```

---

## 🔍 Troubleshooting

**Q: Audit logs not appearing?**
- Ensure index created for `createdAt` descending
- Check Firestore rules permissions
- Verify `_logTokenAudit()` called with valid uid

**Q: Streaks not updating?**
- Check `lastLogin` timestamp format (must be Firestore timestamp)
- Verify `processDailyLogin()` not called twice same day
- Check if `lastBonus` properly set

**Q: Milestones not unlocking?**
- Verify `lifetimeSpent` matches threshold
- Check `checkAndUpdateMilestone()` called at right time
- Review audit logs for milestone_achieved entries

**Q: Config changes not reflected?**
- Stream not subscribed? Use `streamLoyaltyConfig()`
- Check admin permissions in Firestore rules
- Verify global doc in `/loyalty_config/global`

---

## 📚 Related Documentation

- AuraToken System: See `docs/auratoken_system.md`
- Payment Processing: See `docs/payment_system.md`
- Firestore Schema: See `docs/firestore_schema.md`
- Provider Integration: See `docs/state_management.md`
