# Notification Dedup+Throttle Quick Start

## What Changed?

You now have a **robust deduplication and burst-throttle engine** for notifications:

- **Dedup Window**: 6 hours (configurable)
- **Burst Limit**: 3 notifications/hour per user (configurable)
- **Critical Override**: Critical severity notifications bypass throttle
- **Audit Trail**: Every decision logged

## How It Works

1. **Event Triggered** (e.g., anomaly created)
2. **Check Dedup** — Has this user/event been sent in last 6 hours?
   - YES → SKIP (log as skipped)
   - NO → Continue
3. **Check Burst** — Has user hit 3 notifications in last hour?
   - YES → SKIP (log as skipped)
   - NO → SEND
4. **Send Notification** → Log as sent to audit trail

## Key Functions

```typescript
// Check if notification should be sent
const result = await shouldSendNotification(
  {
    targetUid: 'user123',
    eventType: 'anomaly',
    entityType: 'invoice',
    entityId: 'inv456',
  },
  'high' // severity
);

if (result.send) {
  // Send notification
  await recordSentAudit(userId, eventId, 'anomaly', metadata);
} else {
  // Already sent recently or burst limit hit
  await recordSkippedAudit(userId, eventId, 'anomaly', result.reason);
}
```

## Configuration

### In Code (dedupeThrottle.ts)
```typescript
export const DEFAULT_DEDUPE_HOURS = 6;    // Change to 12 for 12-hour window
export const DEFAULT_BURST_LIMIT = 3;     // Change to 5 for 5/hour limit
export const BURST_WINDOW_MINUTES = 60;   // Change to 120 for 2-hour window
```

### Per-Call (pass options)
```typescript
await shouldSendNotification(key, severity, {
  dedupeHours: 12,
  burstLimit: 5,
  burstWindowMinutes: 120,
});
```

## Firestore Setup (REQUIRED)

### 1. Create TTL on notification_dedupe
```
Firebase Console
  → Firestore
    → Collections → notification_dedupe
      → Menu (⋯) → Enable TTL
        → Select "lastSent" field
          → Set to 7 days
```

### 2. Create Index (optional, for efficiency)
```
Firebase Console
  → Firestore
    → Indexes
      → Create composite index on:
        notification_dedupe (targetUid, eventType, entityType, entityId)
```

## Testing

### Test 1: Basic Dedup
```bash
# 1. Deploy
firebase deploy --only functions

# 2. Create test anomaly
firebase firestore:add anomalies << EOF
{
  "severity": "high",
  "entityType": "invoice",
  "entityId": "test-123",
  "ownerUid": "test-user"
}
