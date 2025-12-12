# Loyalty System Quick Reference Card

## 🎯 Collections & Documents

| Collection | Document | Purpose |
|-----------|----------|---------|
| `users/{uid}/loyalty` | `profile` | User loyalty state (streak, totals, badges, milestones) |
| `users/{uid}/token_audit` | `{txId}` | Transaction history (immutable, ordered by createdAt) |
| `payments_processed` | `{sessionId}` | Payment records (Stripe session mapping) |
| `loyalty_config` | `global` | Global configuration (read-only for users) |

---

## 📱 Provider Methods

### Initialization
```dart
await loyaltyProvider.initializeUserLoyalty(uid)
await loyaltyProvider.fetchLoyaltyConfig()
```

### Operations
```dart
final reward = await loyaltyProvider.processDailyLogin(uid)
await loyaltyProvider.recordPayment(sessionId, uid, packId, tokens)
await loyaltyProvider.awardBadge(uid, badge)
await loyaltyProvider.checkAndUpdateMilestone(uid, 'gold')
await loyaltyProvider.freezeStreak(uid)
```

### Queries
```dart
await loyaltyProvider.fetchUserLoyalty(uid)
await loyaltyProvider.fetchTokenAuditLogs(uid, limit: 50)
```

### Streams
```dart
loyaltyProvider.streamUserLoyalty(uid)
loyaltyProvider.streamLoyaltyConfig()
loyaltyProvider.streamTokenAuditLogs(uid)
```

### Computed Properties
```dart
loyaltyProvider.currentStreak
loyaltyProvider.lifetimeEarned
loyaltyProvider.lifetimeSpent
loyaltyProvider.badgeCount
loyaltyProvider.isBronze / isSilver / isGold / isPlatinum / isDiamond
loyaltyProvider.getNextMilestone()
loyaltyProvider.getProgressToNextMilestone() // 0-100%
```

---

## ☁️ Cloud Function Endpoints

### Callable Functions (from Flutter)
```dart
// Claim daily bonus
final result = await FirebaseFunctions.instance.httpsCallable('claimDailyBonus').call();
// Returns: {success, reward, streak, message}

// Get loyalty profile
final result = await FirebaseFunctions.instance.httpsCallable('getUserLoyaltyProfile').call();
// Returns: {success, data}
```

### HTTP Endpoints (from Backend)
```
POST /onPaymentSuccessUpdateLoyalty
Body: {sessionId, uid, packId, tokenCount}
Returns: {success, sessionId}
```

---

## 🔐 Security Rules Summary

| Resource | Read | Write | Notes |
|----------|------|-------|-------|
| `users/{uid}/loyalty/profile` | User only | User/Admin | Prevents total decreases |
| `users/{uid}/token_audit/*` | User/Admin | Admin only | Append-only audit trail |
| `payments_processed/*` | User/Admin | Admin/Payment | Idempotency via sessionId |
| `loyalty_config/global` | All users | Admin only | Public read config |

---

## 📊 Daily Bonus Formula

```
Base = 50 tokens
Streak = min(days × 10, 500)
Multiplier = 1.0x (normal) or 2.0x (holiday)

Total = (Base + Streak) × Multiplier

Examples:
  Day 1:  50 + 10 = 60 tokens
  Day 7:  50 + 70 = 120 tokens
  Day 50: 50 + 500 = 550 tokens (capped)
  Christmas: (50 + X) × 2.0
```

---

## 🎖️ Milestone Tiers

| Tier | Threshold | Bonus |
|------|-----------|-------|
| 🥉 Bronze | $1,000 | +100 tokens |
| 🥈 Silver | $5,000 | +500 tokens |
| 🥇 Gold | $10,000 | +1,000 tokens |
| 🔷 Platinum | $25,000 | +2,500 tokens |
| 💎 Diamond | $50,000 | +5,000 tokens |

Auto-awarded when `lifetimeSpent` exceeds threshold.

---

## 🎁 Audit Action Types

| Action | Amount | Trigger |
|--------|--------|---------|
| `daily_bonus` | Base+Streak | Daily login |
| `purchase` | Pack tokens | Stripe payment |
| `badge_awarded` | 0 | Achievement unlock |
| `milestone_achieved` | 0 | Threshold reached |
| `streak_frozen` | 0 | Missed login |
| `admin_adjustment` | Variable | Admin action |
| `referral_bonus` | Variable | Referral reward |

---

## ⏰ Important Dates

| Date | Multiplier | Holiday |
|------|-----------|---------|
| 12-25 | 2.0x | Christmas |
| 01-01 | 1.5x | New Year |
| 07-04 | 1.5x | Independence Day |

---

## 🔄 Integration Checklist

- [ ] Add `LoyaltyProvider` to MultiProvider
- [ ] Deploy Cloud Functions
- [ ] Create Firestore indexes
- [ ] Initialize loyalty config
- [ ] Call `initializeUserLoyalty()` on signup
- [ ] Hook `processDailyLogin()` to app startup
- [ ] Hook `recordPayment()` to Stripe webhook
- [ ] Create loyalty dashboard UI
- [ ] Test daily bonus flow
- [ ] Test milestone unlocking
- [ ] Monitor production logs

---

## 🐛 Quick Fixes

| Problem | Check |
|---------|-------|
| Audit logs missing | Index created? `createdAt` descending |
| Streak not updating | `lastLogin` timestamp format |
| Milestone stuck | Verify `lifetimeSpent` ≥ threshold |
| Config stale | Using `streamLoyaltyConfig()`? |
| Bonus claimed twice | 24-hour validation working? |

---

## 📁 File Locations

```
Frontend:
  lib/models/loyalty*.dart          (Dart models)
  lib/services/loyalty_service.dart (Firestore ops)
  lib/providers/loyalty_provider.dart (State)
  lib/config/loyalty_constants.dart  (Config)

Backend:
  functions/src/loyalty/loyaltyManager.ts (Logic)
  functions/src/loyalty/loyaltyFunctions.ts (APIs)

Database:
  firestore-loyalty.rules            (Security)

Docs:
  LOYALTY_SYSTEM_*.md               (Documentation)
```

---

## 💡 Pro Tips

1. **Always stream, don't fetch repeatedly** — Use `streamUserLoyalty()` for real-time UI
2. **Batch audit logs cleanup** — Run `cleanupOldAuditLogs()` monthly
3. **Cache config locally** — Streamed config can be cached for offline use
4. **Validate on client AND server** — Security + UX
5. **Monitor milestone awards** — Watch audit logs for anomalies
6. **Test with test card:** `4242 4242 4242 4242` (Stripe)

---

## 🚀 Getting Started (5 Minutes)

1. Add provider to app.dart
2. Deploy Cloud Functions
3. Create Firestore index
4. Initialize config
5. Call `initializeUserLoyalty()` on signup

✨ **Ready to go!**

