# Loyalty System Firestore Schema

Complete Firestore structure for the AuraSphere Pro loyalty system.

## Collections Overview

### 1. `/users/{uid}/loyalty`
User loyalty profile and streak data.

**Document Fields:**
```javascript
{
  // Streak tracking
  streak: {
    current: number,           // Current consecutive days
    lastLogin: timestamp,      // Last login date
    frozenUntil: timestamp|null // Frozen streak end date
  },
  
  // Lifetime statistics
  totals: {
    lifetimeEarned: number,    // Total tokens earned
    lifetimeSpent: number      // Total tokens spent
  },
  
  // Achievement badges
  badges: [
    {
      id: string,              // Unique badge ID
      name: string,            // Display name
      level: number,           // Badge level/tier
      earnedAt: timestamp      // When earned
    }
  ],
  
  // Milestone achievement flags
  milestones: {
    bronze: boolean,           // 100 tokens earned
    silver: boolean,           // 250 tokens earned
    gold: boolean,             // 500 tokens earned
    platinum: boolean,         // 1000 tokens earned
    diamond: boolean           // 2000 tokens earned
  },
  
  // Last daily bonus claim
  lastBonus: timestamp|null,   // Timestamp of last bonus
  
  // Metadata
  createdAt: timestamp,        // Account creation date
  updatedAt: timestamp         // Last update timestamp
}
```

**Security Rules:**
- Users can read their own loyalty data
- Only server (Cloud Functions) can write
- No deletion allowed

---

### 2. `/payments_processed/{sessionId}`
Token purchase transaction records.

**Document Fields:**
```javascript
{
  // Payment identifiers
  sessionId: string,           // Unique payment session
  uid: string,                 // User ID
  
  // Package information
  packId: string,              // Token package purchased
  tokens: number,              // Tokens received
  
  // Payment details
  amount: number,              // Amount paid (EUR)
  currency: string,            // "EUR"
  
  // Status tracking
  status: string,              // "completed", "pending", "failed"
  
  // Timestamps
  processedAt: timestamp,      // Payment completion time
  createdAt: timestamp         // Payment initiation
}
```

**Security Rules:**
- Users can only read their own payments (filtered by uid)
- Only Cloud Functions can write
- Financial records are sensitive - restrict access

---

### 3. `/users/{uid}/token_audit/{txId}`
Complete token transaction audit trail.

**Document Fields:**
```javascript
{
  // Transaction identifiers
  txId: string,                // Unique transaction ID
  uid: string,                 // User ID
  
  // Transaction details
  action: string,              // "daily_bonus", "streak_bonus", "milestone", 
                               // "purchase", "spend", "adjustment"
  amount: number,              // Tokens added/removed
  
  // Reference data
  sessionId: string|null,      // Payment session (if applicable)
  invoiceId: string|null,      // Invoice ID (if applicable)
  
  // Metadata
  metadata: {
    streak: number|null,       // Streak length at time
    multiplier: number|null,   // Bonus multiplier applied
    reason: string|null        // Human-readable reason
  },
  
  // Timestamps
  createdAt: timestamp         // Transaction time
}
```

**Security Rules:**
- Users can read all their own transactions
- Only Cloud Functions can write
- Immutable (no updates/deletes)

---

### 4. `/loyalty_config/global`
System-wide loyalty configuration (single document).

**Document Fields:**
```javascript
{
  // Daily bonus configuration
  daily: {
    baseReward: number,        // Base tokens per login (default: 5)
    streakBonus: number,       // Tokens per streak day (default: 1)
    maxStreakBonus: number     // Maximum streak bonus cap (default: 20)
  },
  
  // Weekly bonus configuration
  weekly: {
    thresholdDays: number,     // Days to qualify (default: 7)
    bonus: number              // Bonus tokens (default: 50)
  },
  
  // Milestone rewards
  milestones: [
    {
      id: string,              // "bronze", "silver", "gold", "platinum", "diamond"
      name: string,            // Display name
      tokensThreshold: number, // Required tokens earned
      reward: number           // Bonus tokens for reaching
    }
  ],
  
  // Special day bonuses
  specialDays: [
    {
      dateISO: string,         // Date in ISO format (YYYY-MM-DD)
      bonusMultiplier: number, // Multiplier (e.g., 2.0 for double)
      name: string             // Holiday/event name
    }
  ],
  
  // Metadata
  updatedAt: timestamp,        // Last configuration update
  updatedBy: string            // Admin who made changes
}
```

**Security Rules:**
- Public read (non-authenticated users can read)
- Only admins can write

---

## Collection Structure Summary

```
firestore/
├── users/
│   └── {uid}/
│       ├── loyalty/                    ← User loyalty profile
│       │   └── streak, totals, badges, milestones, lastBonus
│       └── token_audit/
│           └── {txId}/                 ← Individual transaction records
│               └── action, amount, sessionId, metadata, createdAt
├── payments_processed/
│   └── {sessionId}/                    ← Payment records
│       └── processedAt, uid, packId, tokens, status
└── loyalty_config/
    └── global/                         ← Global configuration
        └── daily, weekly, milestones, specialDays
```

---

## Indexes Required

### Compound Indexes

**For efficient querying:**

1. **User Token Audit**
   - Collection: `users/{uid}/token_audit`
   - Fields: `createdAt (Descending)`, `action (Ascending)`
   - Purpose: Query recent transactions by type

2. **Payments by User**
   - Collection: `payments_processed`
   - Fields: `uid (Ascending)`, `processedAt (Descending)`
   - Purpose: Query user's payment history

3. **Loyalty Milestones**
   - Collection: `loyalty_config`
   - Fields: `milestones.tokensThreshold (Ascending)`
   - Purpose: Find next milestone for user

---

## Data Initialization

### Initial Global Config

```javascript
// /loyalty_config/global
{
  daily: {
    baseReward: 5,
    streakBonus: 1,
    maxStreakBonus: 20
  },
  weekly: {
    thresholdDays: 7,
    bonus: 50
  },
  milestones: [
    { id: "bronze", name: "Bronze", tokensThreshold: 100, reward: 10 },
    { id: "silver", name: "Silver", tokensThreshold: 250, reward: 25 },
    { id: "gold", name: "Gold", tokensThreshold: 500, reward: 50 },
    { id: "platinum", name: "Platinum", tokensThreshold: 1000, reward: 100 },
    { id: "diamond", name: "Diamond", tokensThreshold: 2000, reward: 200 }
  ],
  specialDays: [
    // Add holidays, promotional days, etc.
    { dateISO: "2024-12-25", bonusMultiplier: 2.0, name: "Christmas" },
    { dateISO: "2024-01-01", bonusMultiplier: 1.5, name: "New Year" }
  ],
  updatedAt: <current_timestamp>,
  updatedBy: "system"
}
```

### Initial User Loyalty

```javascript
// /users/{uid}/loyalty
{
  streak: {
    current: 0,
    lastLogin: null,
    frozenUntil: null
  },
  totals: {
    lifetimeEarned: 0,
    lifetimeSpent: 0
  },
  badges: [],
  milestones: {
    bronze: false,
    silver: false,
    gold: false,
    platinum: false,
    diamond: false
  },
  lastBonus: null,
  createdAt: <current_timestamp>,
  updatedAt: <current_timestamp>
}
```

---

## Access Patterns

### Read Patterns

1. **Get User Loyalty Status**
   - Path: `/users/{uid}/loyalty`
   - Purpose: Display user profile, badges, streaks
   - Frequency: High (on every screen)

2. **Get User Token Transactions**
   - Path: `/users/{uid}/token_audit?orderBy=createdAt&limit=50`
   - Purpose: Show transaction history
   - Frequency: Medium (on history view)

3. **Get Payment Records**
   - Path: `/payments_processed?uid={uid}&orderBy=processedAt`
   - Purpose: Show purchase history
   - Frequency: Low (on wallet/billing)

4. **Get Global Config**
   - Path: `/loyalty_config/global`
   - Purpose: Calculate bonuses, display milestones
   - Frequency: High (cached on client)

### Write Patterns

1. **Daily Bonus Claim**
   - Writes: `/users/{uid}/loyalty` (lastBonus, streak, totals)
   - Writes: `/users/{uid}/token_audit/{txId}` (new transaction)
   - Trigger: User claims daily bonus
   - Cloud Function: `onUserClaimBonus`

2. **Milestone Achievement**
   - Writes: `/users/{uid}/loyalty` (milestones object)
   - Writes: `/users/{uid}/token_audit/{txId}` (milestone transaction)
   - Trigger: User reaches token threshold
   - Cloud Function: `checkAndAwardMilestones`

3. **Token Purchase**
   - Writes: `/payments_processed/{sessionId}` (new payment)
   - Writes: `/users/{uid}/token_audit/{txId}` (purchase transaction)
   - Writes: `/users/{uid}/loyalty` (totals.lifetimeEarned)
   - Trigger: Successful Stripe payment
   - Cloud Function: `onTokenPurchase`

4. **Token Spend**
   - Writes: `/users/{uid}/token_audit/{txId}` (spend transaction)
   - Writes: `/users/{uid}/loyalty` (totals.lifetimeSpent)
   - Trigger: User spends tokens
   - Cloud Function: `onTokenSpend`

---

## Firestore Rules

See `firestore.rules` for complete security implementation.

Key principles:
- User data only readable by that user
- Transaction records immutable
- Payment records immutable
- Only Cloud Functions can write loyalty data
- Global config publicly readable
- Transactions cannot be deleted
