# Notification Deduplication & Throttling Implementation - Complete

## Overview
Implemented a **production-ready deduplication and burst-throttle engine** for the AuraSphere Pro notification system.

Commit: `b91f1c2` — "feat(notifications): implement robust dedup+throttle engine with integrated push event handlers"

## Key Files Created/Modified

### 1. **dedupeThrottle.ts** ✅ (NEW)
- **Location**: `functions/src/notifications/dedupeThrottle.ts`
- **Purpose**: Core deduplication + burst-throttle logic
- **Exports**:
  - `shouldSendNotification()` — check if notification should be sent
  - `buildDedupeDocId()` — generate stable Firestore doc ID
  - `dedupeWindowMs()` — convert hours to milliseconds
  - `recordSkippedAudit()` — log skipped notifications
  - `recordSentAudit()` — log sent notifications
  - `recordFailedAudit()` — log failed notifications

**Features**:
- **Critical severity bypass** — critical notifications always sent immediately
- **Dedup window** — 6 hours (configurable) — prevent identical events within window
- **Burst throttle** — max 3 notifications/hour per user (configurable)
- **Audit trail** — all decisions logged to `notifications_audit` collection
- **TTL cleanup** — old dedupe records auto-expire via Firestore TTL

**Configuration** (defaults):
```typescript
DEFAULT_DEDUPE_HOURS = 6        // dedup window
DEFAULT_BURST_LIMIT = 3         // max sent/hour
BURST_WINDOW_MINUTES = 60       // rolling window for burst
```

### 2. **sendPushOnEvent.ts** ✅ (UPDATED)
- **Location**: `functions/src/notifications/sendPushOnEvent.ts`
- **Updated triggers**:
  - `onAnomalyCreate` — trigger when new anomaly created
  - `onInvoiceWrite` — trigger when invoice status changes

**New behavior**:
1. Extract event data (severity, entityType, entityId, uid)
2. Build **DedupeKey** (targetUid, eventType, entityType, entityId)
3. Call `shouldSendNotification()` with severity
4. **If allowed**: save notification → send push → audit as 'sent'
5. **If blocked**: audit as 'skipped' with reason

**Audit examples**:
- Skipped: `deduped_recently_1234s`, `burst_limit_reached_3`
- Sent: `{ sent: 2, failed: 0 }`
- Failed: error message

### 3. **index.ts** ✅ (UPDATED)
- **Exports added**:
  ```typescript
  export {
    shouldSendNotification,
    buildDedupeDocId,
    recordSkippedAudit,
    recordSentAudit,
    recordFailedAudit
  } from './notifications/dedupeThrottle';
  ```

### 4. **Storage Bucket Fixes** ✅ (MULTIPLE FILES)
Fixed eager bucket initialization that caused "Bucket name not specified" errors:
- `audit/exportAudit.ts` — lazy-load `getStorageBucket()`
- `invoices/exportInvoiceFormats.ts` — lazy-load `getBucket()`
- `invoices/generateInvoicePdf.ts` — lazy-load `getBucket()`
- `billing/generateInvoiceReceipt.ts` — lazy-load `getBucket()`
- `purchaseOrders/generatePOPDFUtil.ts` — lazy-load `getBucket()`
- `invoicing/emailService.ts` — removed dotenv.config() call

## Firestore Collections

### `notification_dedupe` (NEW)
Stores deduplication state per event:
```typescript
{
  targetUid: string,           // user ID
  eventType: string,           // "anomaly", "invoice_overdue", etc.
  entityType: string | null,   // "invoice", "expense", etc.
  entityId: string | null,     // specific resource ID
  lastSent: Timestamp,         // when last sent
  count: number,               // total times sent (incremented)
  // TTL-managed: auto-expires after configured days
}
```

**Index & TTL**:
- Create composite index: `(targetUid, eventType, entityType, entityId)` → Query optimized
- Set **TTL** on `lastSent` field → Auto-cleanup (Firebase Console)

### `notifications_audit` (EXISTING, ENHANCED)
Already exists; now used for dedup decisions:
```typescript
{
  targetUid: string,
  eventId: string | null,      // triggering event ID
  type: string,                // "anomaly", "invoice_overdue", etc.
  status: "sent" | "skipped" | "failed",
  reason?: string,             // "deduped_recently_X", "burst_limit_reached", etc.
  error?: string,              // failure reason
  meta?: Record<string, any>,  // additional metadata
  createdAt: Timestamp,
}
```

## Testing

### Unit Test Example
```typescript
import { shouldSendNotification, DedupeKey } from '../dedupeThrottle';

const key: DedupeKey = {
  targetUid: 'user123',
  eventType: 'anomaly',
  entityType: 'invoice',
  entityId: 'inv456',
};

// First call → should send
const result1 = await shouldSendNotification(key, 'high');
expect(result1.send).toBe(true);
expect(result1.reason).toBe('ok');

// Second call within 6 hours → should skip
const result2 = await shouldSendNotification(key, 'high');
expect(result2.send).toBe(false);
expect(result2.reason).toMatch(/deduped_recently/);

// Critical severity → always send
const result3 = await shouldSendNotification(key, 'critical');
expect(result3.send).toBe(true);
expect(result3.reason).toBe('critical_bypass');
```

### Manual Testing
```bash
# Deploy
firebase deploy --only functions

# Check function logs
firebase functions:log --follow

# Test push notification trigger in Firebase Console
# Firestore → anomalies → Create document with:
# {
#   severity: "high",
#   entityType: "invoice",
#   entityId: "test-123",
#   ownerUid: "your-user-id"
# }
```

## Deployment Status ✅

- **Build**: TypeScript compilation → ✅ PASS
- **Deploy**: `firebase deploy --only functions --force` → ✅ SUCCESS
- **Function updates**: 100+ functions deployed
- **Known issue**: `pushRiskAlert` function pre-existing error (not part of this PR)

## Best Practices Implemented

1. **Fail-safe design**
   - If dedupe check fails → allow sending (don't silence notifications)
   - Errors logged but don't block flow

2. **Audit trail**
   - Every decision (send/skip/fail) recorded
   - Reason logged for debugging

3. **Configurable defaults**
   - Change `DEFAULT_DEDUPE_HOURS`, `DEFAULT_BURST_LIMIT` in code
   - Or pass `options` to `shouldSendNotification()`

4. **TTL/cleanup**
   - Firestore TTL auto-expires old dedupe records
   - No manual cleanup needed

5. **Security**
   - Per-user dedup (no cross-user leakage)
   - No secrets in code (use Firebase config)

## Next Steps

1. **Set up Firestore TTL** (Firebase Console)
   - Firestore → `notification_dedupe` collection
   - TTL policy on `lastSent` field → 7 days

2. **Configure burst limits** (optional)
   - Adjust `DEFAULT_BURST_LIMIT` if needed
   - Pass custom options to `shouldSendNotification()`

3. **Monitor audit trail**
   - Query `notifications_audit` collection
   - Track send/skip/fail ratios

4. **Test with real data**
   - Create test anomalies/invoices
   - Verify dedup kicks in
   - Check audit logs

## Summary

✅ **Deduplication engine**: 6-hour configurable window  
✅ **Burst throttle**: 3 notifications/hour per user  
✅ **Audit trail**: All decisions logged  
✅ **Production-ready**: Error handling, TTL cleanup  
✅ **Integrated**: Push event triggers use dedup/throttle  
✅ **Deployed**: Functions live in Firebase  

---

**Commit Hash**: `b91f1c2`  
**Files Changed**: 13  
**Insertions**: 536  
**Deletions**: 49
