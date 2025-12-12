# Loyalty System Architecture - Three-Layer Design

## 📐 System Architecture

The loyalty system is organized in three layers for clean separation of concerns:

```
┌─────────────────────────────────────────────────────────────────┐
│ CLOUD FUNCTIONS LAYER (Callable Endpoints & Webhooks)           │
│ ─────────────────────────────────────────────────────────────── │
│ • claimDailyBonus()                                              │
│ • getUserLoyaltyProfile()                                        │
│ • onPaymentSuccessUpdateLoyalty() [HTTP webhook]                │
│ • processDailyBonusesScheduled() [Pub/Sub]                      │
├─────────────────────────────────────────────────────────────────┤
│ LOYALTY ENGINE LAYER (Core Business Logic)                      │
│ ─────────────────────────────────────────────────────────────── │
│ • handleDailyLogin()                                             │
│ • checkAndAwardMilestones()                                      │
│ • creditTokens()                                                 │
│ • freezeStreak()                                                 │
│ • processWeeklyBonus()                                           │
│ • getConfig()                                                    │
├─────────────────────────────────────────────────────────────────┤
│ LOYALTY MANAGER LAYER (Firestore CRUD)                          │
│ ─────────────────────────────────────────────────────────────── │
│ • initializeUserLoyaltyProfile()                                 │
│ • getUserLoyalty()                                               │
│ • recordPaymentTransaction()                                     │
│ • awardBadge()                                                   │
│ • getUserAuditLogs()                                             │
│ • cleanupOldAuditLogs()                                          │
└─────────────────────────────────────────────────────────────────┘
         ↓ Uses Firestore ↓
┌─────────────────────────────────────────────────────────────────┐
│ FIRESTORE COLLECTIONS                                           │
│ ─────────────────────────────────────────────────────────────── │
│ • users/{uid}/loyalty/profile                                    │
│ • users/{uid}/token_audit/{txId}                                 │
│ • payments_processed/{sessionId}                                 │
│ • loyalty_config/global                                          │
└─────────────────────────────────────────────────────────────────┘
```

---

## File Structure

```
functions/src/loyalty/
├── loyaltyFunctions.ts     (Cloud Functions endpoints)
│   ├── claimDailyBonus()
│   ├── getUserLoyaltyProfile()
│   ├── onPaymentSuccessUpdateLoyalty()
│   └── processDailyBonusesScheduled()
│
├── loyaltyEngine.ts        (Core business logic)
│   ├── handleDailyLogin()
│   ├── checkAndAwardMilestones()
│   ├── creditTokens()
│   ├── freezeStreak()
│   ├── processWeeklyBonus()
│   └── getConfig()
│
├── loyaltyManager.ts       (Firestore CRUD & initialization)
│   ├── initializeUserLoyaltyProfile()
│   ├── getUserLoyalty()
│   ├── recordPaymentTransaction()
│   ├── awardBadge()
│   └── getUserAuditLogs()
│
└── index.ts               (Exports all functions)
```

---

## Data Flow Examples

### Daily Login Flow
```
User App
    ↓ Call claimDailyBonus()
Cloud Function (loyaltyFunctions.ts)
    ↓ Call handleDailyLogin()
Loyalty Engine (loyaltyEngine.ts)
    ↓ Check eligibility, calculate streak & bonus
    ↓ Return {streak, awarded, message}
    ↓ Call creditTokens()
Loyalty Engine (loyaltyEngine.ts)
    ↓ runTransaction() to update:
    │   • users/{uid}/wallet/profile (balance)
    │   • users/{uid}/token_audit/{txId} (audit)
    │   • users/{uid}/loyalty/profile (totals)
    ↓ Return {success, newBalance}
Cloud Function
    ↓ Call checkAndAwardMilestones()
Loyalty Engine
    ↓ Check lifetime spent vs thresholds
    ↓ Return {awarded: ['silver', 'gold']}
Cloud Function
    ↓ Return to client: {success, reward, streak, milestones}
User App
    ↓ Display "+50 TOKENS" animation
    ↓ Update UI with new streak
```

### Payment Processing Flow
```
Stripe Webhook → Firebase Cloud Function
    ↓ Call onPaymentSuccessUpdateLoyalty()
Cloud Function (loyaltyFunctions.ts)
    ├─ Call recordPaymentTransaction() [Manager]
    │   ↓ Create payments_processed/{sessionId} doc
    │   ↓ Update users/{uid}/loyalty/profile totals
    │
    ├─ Call creditTokens() [Engine]
    │   ↓ Transaction:
    │   │   • Update wallet balance
    │   │   • Create token_audit entry
    │   │   • Update lifetime earned
    │   ↓ Return {success, newBalance}
    │
    └─ Call checkAndAwardMilestones() [Engine]
        ↓ Check lifetime spent >= thresholds
        ↓ Create milestone audit entries
        ↓ Return {awarded: ['bronze']}

Response to Webhook: {success, milestonesUnlocked}
```

---

## Layer Responsibilities

### **Cloud Functions Layer** (loyaltyFunctions.ts)
**Responsibilities:**
- Accept HTTP/callable requests from clients
- Validate authentication and input parameters
- Orchestrate calls to engine and manager
- Return formatted responses to clients
- Handle error responses

**Should NOT do:**
- Complex business logic
- Direct Firestore writes
- Token calculations
- Streak tracking

**Example:**
```typescript
export const claimDailyBonus = functions.https.onCall(async (data, context) => {
  // 1. Validate auth
  // 2. Call engine
  // 3. Call manager if needed
  // 4. Return response
});
```

---

### **Loyalty Engine Layer** (loyaltyEngine.ts)
**Responsibilities:**
- Core business logic (calculations, validations)
- Daily bonus formula
- Milestone checking
- Token crediting with atomic transactions
- Streak management
- Configuration handling

**Should NOT do:**
- Accept HTTP requests directly
- Return HTTP responses
- Manage user initialization
- Handle payment records
- Create badges/awards

**Example:**
```typescript
export async function handleDailyLogin(uid: string) {
  // 1. Get configuration
  // 2. Check eligibility
  // 3. Calculate streak & bonus
  // 4. Update loyalty profile
  // 5. Return calculations (no tokens credited here!)
}
```

---

### **Loyalty Manager Layer** (loyaltyManager.ts)
**Responsibilities:**
- Firestore CRUD operations
- User initialization
- Payment recording
- Audit log queries
- Badge awarding
- Data persistence

**Should NOT do:**
- Business logic calculations
- HTTP request handling
- Token crediting (delegated to engine)
- Daily login processing

**Example:**
```typescript
export async function recordPaymentTransaction(
  uid: string,
  sessionId: string,
  packId: string,
  tokens: number
) {
  // 1. Record payment doc
  // 2. Update totals
  // 3. Return success
}
```

---

## Integration Points

### From Cloud Function to Engine
```typescript
// Cloud Function calls engine for business logic
const { streak, awarded, message } = await handleDailyLogin(uid);
```

### From Engine to Manager
```typescript
// Engine sometimes calls manager for data operations
// (e.g., within transactions)
const loyalty = await getUserLoyalty(uid);
```

### From Engine to Firestore
```typescript
// Engine uses transactions for atomic updates
return await db.runTransaction(async (tx) => {
  // Read, calculate, write atomically
});
```

---

## Separation of Concerns Benefits

| Concern | Layer | Why? |
|---------|-------|------|
| Business Logic | Engine | Testable, reusable, framework-independent |
| HTTP Handling | Functions | Closer to client, error formatting |
| Database Ops | Manager | Centralized data access patterns |
| Configuration | Engine | Consistent calculations everywhere |
| Transactions | Engine | Atomic operations for consistency |

---

## Testing Strategy by Layer

### **Cloud Functions Layer Testing**
- Mock authentication context
- Verify HTTP response format
- Validate input parameters
- Test error responses

```typescript
// Test missing auth
expect(() => claimDailyBonus(data, {auth: null}))
  .toThrow('unauthenticated');
```

### **Loyalty Engine Testing**
- Mock Firestore calls
- Test business logic independently
- Test edge cases (leap years, special days, etc.)
- Verify calculations

```typescript
// Test daily bonus formula
const bonus = await handleDailyLogin('test-uid');
expect(bonus.awarded).toBe(60); // 50 base + 10 streak
```

### **Loyalty Manager Testing**
- Integration tests with real Firestore
- Verify document structure
- Test transaction consistency
- Validate audit trails

```typescript
// Test payment recording
await recordPaymentTransaction(uid, sessionId, packId, tokens);
const doc = await db.doc(`payments_processed/${sessionId}`).get();
expect(doc.data().tokens).toBe(tokens);
```

---

## Deployment Layers

### **Deploy Cloud Functions**
```bash
firebase deploy --only functions
```
Deploys all functions in `loyaltyFunctions.ts`:
- `claimDailyBonus`
- `getUserLoyaltyProfile`
- `onPaymentSuccessUpdateLoyalty`
- `processDailyBonusesScheduled`

### **No Separate Deployment for Engine/Manager**
They're imported by Cloud Functions, so they deploy together.

### **Update Configuration**
```bash
# Initialize or update loyalty_config/global doc
firebase firestore:import config.json
```

---

## Adding New Features

To add a new loyalty feature, follow this pattern:

1. **Business Logic** → Add to `loyaltyEngine.ts`
   ```typescript
   export async function myNewFeature(uid: string) {
     // Calculate, validate, transform
     return result;
   }
   ```

2. **Data Persistence** → Add to `loyaltyManager.ts` if needed
   ```typescript
   export async function storeFeatureData(uid: string, data: any) {
     // Write to Firestore
   }
   ```

3. **Cloud Function Endpoint** → Add to `loyaltyFunctions.ts`
   ```typescript
   export const myNewFeatureCallable = functions.https.onCall(async (data, context) => {
     // Validate input
     const result = await myNewFeature(context.auth.uid);
     // Return response
   });
   ```

4. **Export** → Add to `functions/src/index.ts`
   ```typescript
   export { myNewFeatureCallable } from './loyalty/loyaltyFunctions';
   ```

---

## Configuration Hierarchy

```
1. Firestore: loyalty_config/global
   ↓ (if exists)
   Used for all calculations
   
2. Default Config (in loyaltyEngine.ts)
   ↓ (if Firestore doc missing)
   Fallback configuration
   
3. Hard-coded Values
   (Edge case defaults)
```

---

## Error Handling Patterns

### **Cloud Function Level**
```typescript
try {
  const result = await handleDailyLogin(uid);
  return {success: true, data: result};
} catch (error) {
  throw new functions.https.HttpsError('internal', error.message);
}
```

### **Engine Level**
```typescript
try {
  // Business logic
} catch (error) {
  console.error('Error in handleDailyLogin:', error);
  throw error; // Let caller handle
}
```

### **Manager Level**
```typescript
try {
  // Firestore operations
} catch (error) {
  console.error('Error in getUserLoyalty:', error);
  return null; // Safe default
}
```

---

## Performance Considerations

| Operation | Layer | Complexity | Notes |
|-----------|-------|-----------|-------|
| `handleDailyLogin()` | Engine | O(1) | Single Firestore read |
| `creditTokens()` | Engine | O(1) | Transaction, not batched |
| `checkAndAwardMilestones()` | Engine | O(n) | n = # milestones (5) |
| `getUserAuditLogs()` | Manager | O(m) | m = limit (50), paginated |
| `cleanupOldAuditLogs()` | Manager | O(k) | k = # old logs, batch delete |

**Optimization Tips:**
- Cache `getConfig()` result (update rarely)
- Use Firestore indexes for audit queries
- Batch delete old logs monthly
- Use transactions for atomic multi-doc updates

---

## Summary

The three-layer architecture provides:

✅ **Clear Separation** — Each layer has distinct responsibility  
✅ **Testability** — Engine logic testable independently  
✅ **Maintainability** — Changes isolated to specific layers  
✅ **Reusability** — Engine functions callable from multiple sources  
✅ **Scalability** — Easy to add features without refactoring  
✅ **Reliability** — Transactions ensure data consistency  

