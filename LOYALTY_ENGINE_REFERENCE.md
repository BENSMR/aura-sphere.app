# Loyalty Engine - Core Business Logic

## Overview

The `loyaltyEngine.ts` module contains the core business logic for the loyalty system. It handles:
- Daily login bonus calculations and streak tracking
- Milestone checking and awarding
- Token crediting with atomic transactions
- Streak freezing and weekly bonuses

---

## Key Functions

### `getConfig(): Promise<LoyaltyConfig>`
Fetches the current loyalty configuration from Firestore. Returns default config if not found.

**Returns:**
```typescript
{
  daily: {baseReward, streakBonus, maxStreakBonus},
  weekly: {thresholdDays, bonus},
  milestones: [{id, name, threshold, reward}],
  specialDays?: [{dateISO, bonusMultiplier, name}]
}
```

---

### `creditTokens(uid, amount, reason, meta?): Promise<{success, newBalance?}>`
Credits tokens to user's wallet and creates an immutable audit log entry.

**Parameters:**
- `uid` — User ID
- `amount` — Number of tokens to credit
- `reason` — Reason for credit (e.g., "daily_bonus", "purchase_gold_pack")
- `meta` — Optional metadata object

**Uses Transaction:** Yes (atomic update)

**Updates:**
- User's wallet balance
- Lifetime earned total in loyalty profile
- Creates token audit entry

**Returns:**
```typescript
{
  success: boolean,
  newBalance?: number
}
```

---

### `handleDailyLogin(uid): Promise<{streak, awarded, message}>`
Processes daily login and awards daily bonus if eligible.

**Eligibility Checks:**
- Not already claimed today
- Streak not frozen
- Hasn't been more than 1 day since last login

**Bonus Calculation:**
```
Base = daily.baseReward
Streak Bonus = min(streakDays × streakBonus, maxStreakBonus)
Special Day Multiplier = 1.0x to 2.0x (optional)
Total = (Base + Streak Bonus) × Multiplier
```

**Parameters:**
- `uid` — User ID

**Returns:**
```typescript
{
  streak: number,           // Current streak days
  awarded: number,          // Tokens awarded (0 if not eligible)
  message: string           // Human-readable message
}
```

**Note:** This function does NOT credit tokens. Call `creditTokens()` separately if `awarded > 0`.

---

### `checkAndAwardMilestones(uid): Promise<{awarded, message}>`
Checks if user has reached new milestones based on lifetime spent.

**Milestone Tiers (Default):**
- Bronze: $1,000 lifetime spent
- Silver: $5,000 lifetime spent
- Gold: $10,000 lifetime spent
- Platinum: $25,000 lifetime spent
- Diamond: $50,000 lifetime spent

**Parameters:**
- `uid` — User ID

**Returns:**
```typescript
{
  awarded: string[],        // Array of milestone IDs (e.g., ['silver', 'gold'])
  message: string           // Human-readable message
}
```

**Uses Transaction:** Yes (atomic update)

**Updates:**
- Milestone flags in loyalty profile
- Creates audit entries for each milestone

---

### `getUserLoyaltyStatus(uid): Promise<LoyaltyData | null>`
Gets the current loyalty profile for a user.

**Returns:**
```typescript
{
  streak?: {
    current: number,
    lastLogin: Date,
    frozenUntil?: Date | null
  },
  totals?: {
    lifetimeEarned: number,
    lifetimeSpent: number
  },
  milestones?: {
    [key: string]: boolean  // bronze, silver, gold, platinum, diamond
  },
  lastBonus?: Date
}
```

---

### `freezeStreak(uid, durationDays?): Promise<{success}>`
Freezes user's streak for specified duration (default 3 days).

**Use Cases:**
- User missing N consecutive days of login
- Admin punishment for rule violations

**Parameters:**
- `uid` — User ID
- `durationDays` — Days to freeze streak (default: 3)

**Updates:**
- Sets streak.current to 0
- Sets streak.frozenUntil to future date
- Creates audit entry

---

### `processWeeklyBonus(uid): Promise<{awarded, message}>`
Awards weekly bonus if user's streak meets threshold.

**Eligibility:**
- Streak ≥ weekly.thresholdDays (default: 7)

**Parameters:**
- `uid` — User ID

**Returns:**
```typescript
{
  awarded: number,
  message: string
}
```

**Note:** Can be called from scheduled Cloud Function (daily or weekly).

---

## Integration with Cloud Functions

### Daily Login Flow
```typescript
// In claimDailyBonus() callable function:
const { streak, awarded, message } = await handleDailyLogin(uid);

if (awarded > 0) {
  await creditTokens(uid, awarded, 'daily_bonus', { streak });
}

const { awarded: milestones } = await checkAndAwardMilestones(uid);
```

### Payment Processing Flow
```typescript
// In onPaymentSuccessUpdateLoyalty() webhook:
await recordPaymentTransaction(uid, sessionId, packId, tokenCount);
await creditTokens(uid, tokenCount, `purchase_${packId}`, {...});
const { awarded: milestones } = await checkAndAwardMilestones(uid);
```

---

## Daily Bonus Formula Examples

**Day 1 (no streak):**
```
Base: 50
Streak: min(1 × 10, 500) = 10
Total: 50 + 10 = 60 tokens
```

**Day 7 (consecutive):**
```
Base: 50
Streak: min(7 × 10, 500) = 70
Total: 50 + 70 = 120 tokens
```

**Day 50 (consecutive):**
```
Base: 50
Streak: min(50 × 10, 500) = 500 (capped)
Total: 50 + 500 = 550 tokens
```

**Christmas Special:**
```
Base: 50
Streak: min(5 × 10, 500) = 50
Special: 2.0× multiplier (Christmas)
Total: (50 + 50) × 2.0 = 200 tokens
```

---

## Streak Freeze Logic

When `freezeStreak(uid, 3)` is called:
1. Streak current is reset to 0
2. frozenUntil is set to 3 days from now
3. Audit log entry created
4. On next `handleDailyLogin()`, will check frozenUntil date
5. If still frozen, returns "Streak frozen until..." message

---

## Transaction Safety

Both `creditTokens()` and `checkAndAwardMilestones()` use Firestore transactions to ensure:
- Atomic updates (all-or-nothing)
- No race conditions
- Consistent state across wallet, loyalty, and audit logs

---

## Error Handling

All functions include try-catch blocks and:
- Log errors to Firebase console
- Return safe defaults (null, empty arrays, success: false)
- Throw detailed errors for critical issues

**Example:**
```typescript
try {
  const result = await handleDailyLogin(uid);
} catch (error) {
  console.error('Error handling daily login:', error);
  // Return error to client
  throw new functions.https.HttpsError('internal', error.message);
}
```

---

## Configuration

The engine reads from `loyalty_config/global` Firestore document.

**Default Configuration:**
```typescript
{
  daily: {
    baseReward: 50,
    streakBonus: 10,
    maxStreakBonus: 500
  },
  weekly: {
    thresholdDays: 7,
    bonus: 500
  },
  milestones: [
    {id: 'bronze', name: 'Bronze Member', threshold: 1000, reward: 100},
    {id: 'silver', name: 'Silver Member', threshold: 5000, reward: 500},
    {id: 'gold', name: 'Gold Member', threshold: 10000, reward: 1000},
    {id: 'platinum', name: 'Platinum Member', threshold: 25000, reward: 2500},
    {id: 'diamond', name: 'Diamond Member', threshold: 50000, reward: 5000}
  ],
  specialDays: [
    {dateISO: '12-25', bonusMultiplier: 2.0, name: 'Christmas'},
    {dateISO: '01-01', bonusMultiplier: 1.5, name: 'New Year'},
    {dateISO: '07-04', bonusMultiplier: 1.5, name: 'Independence Day'}
  ]
}
```

---

## Best Practices

1. **Always use transactions** — Don't update wallet and loyalty separately
2. **Separate concerns** — Daily login ≠ token crediting (let caller decide)
3. **Immutable audit trail** — All actions logged for compliance
4. **Check eligibility first** — Before expensive operations
5. **Atomic updates** — Use transaction for multiple updates
6. **Error logging** — Include context for debugging

---

## Testing

Example test cases:
```typescript
// Test daily login bonus calculation
const { awarded, streak } = await handleDailyLogin(uid);
expect(awarded).toBeGreaterThan(0);
expect(streak).toBe(1);

// Test streak increment
const secondDay = await handleDailyLogin(uid); // day 2
expect(secondDay.streak).toBe(2);

// Test milestone checking
await creditTokens(uid, 5000, 'test_credit');
const { awarded: milestones } = await checkAndAwardMilestones(uid);
expect(milestones).toContain('silver'); // 5000 ≥ silver threshold
```

