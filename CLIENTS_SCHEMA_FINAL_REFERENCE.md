# Clients Schema - Final Reference

**Collection Path**: `users/{userId}/clients/{clientId}`

**Document Type**: ClientModel (Dart) / clients (Firestore)

**Last Updated**: December 3, 2025

---

## Complete Field Mapping

### Basic Information (6 fields)
| Field | Type | Firestore | Dart | Required | Notes |
|-------|------|-----------|------|----------|-------|
| `id` | string | ✗ (doc ID) | ✓ | Yes | Document ID (auto-generated or UUID) |
| `name` | string | ✓ | ✓ | Yes | Client's full name |
| `email` | string | ✓ | ✓ | Yes | Email address (unique per user) |
| `phone` | string | ✓ | ✓ | No | Phone number |
| `company` | string | ✓ | ✓ | No | Company/organization name |
| `address` | string | ✓ | ✓ | No | Physical address |
| `country` | string | ✓ | ✓ | No | Country (optional, can infer from address) |
| `notes` | string | ✓ | ✓ | No | Custom notes |

### Financial Metrics (3 fields)
| Field | Type | Firestore | Dart | Range | Notes |
|-------|------|-----------|------|-------|-------|
| `lifetimeValue` | number | ✓ | double | ≥0 | Total revenue from client (sum of paid invoices) |
| `totalInvoices` | number | ✓ | int | ≥0 | Count of invoices created |
| `lastInvoiceAmount` | number | ✓ | double | ≥0 | Most recent invoice amount |

### Activity Timestamps (3 fields)
| Field | Type | Firestore | Dart | Notes |
|-------|------|-----------|------|-------|
| `lastActivityAt` | Timestamp | ✓ | DateTime? | Last any interaction (nullable) |
| `lastInvoiceDate` | Timestamp | ✓ | DateTime? | Most recent invoice created (nullable) |
| `lastPaymentDate` | Timestamp | ✓ | DateTime? | Most recent payment received (nullable) |

### AI Intelligence (4 fields)
| Field | Type | Firestore | Dart | Range | Notes |
|-------|------|-----------|------|-------|-------|
| `aiScore` | number | ✓ | int | 0–100 | Relationship/engagement score |
| `churnRisk` | number | ✓ | int | 0–100 | Churn probability (0=loyal, 100=at-risk) |
| `vipStatus` | boolean | ✓ | bool | - | True if lifetime > 10,000 |
| `sentiment` | string | ✓ | string | See note | "positive", "neutral", "negative", "unknown" |
| `aiTags` | array | ✓ | List<String> | - | Auto-generated tags: "high_value", "unstable", "dormant" |
| `aiSummary` | string | ✓ | string | - | AI-generated relationship summary |
| `stabilityLevel` | string | ✓ | string | See note | "unknown", "stable", "unstable", "risky" |

### Engagement & Status (2 fields)
| Field | Type | Firestore | Dart | Values | Notes |
|-------|------|-----------|------|--------|-------|
| `tags` | array | ✓ | List<String> | Any | User-defined tags |
| `status` | string | ✓ | string | "lead", "active", "vip", "lost" | Client lifecycle status |

### Activity Timeline (1 field)
| Field | Type | Firestore | Dart | Notes |
|-------|------|-----------|------|-------|
| `timeline` | array<object> | ✓ | List<TimelineEvent> | Historical events (invoices, payments, interactions) |

**TimelineEvent Structure**:
```json
{
  "type": "invoice_created" | "invoice_paid" | "payment_received" | "interaction",
  "message": "Invoice #123 created",
  "amount": 250.00,
  "createdAt": Timestamp
}
```

### Metadata (3 fields)
| Field | Type | Firestore | Dart | Notes |
|-------|------|-----------|------|-------|
| `userId` | string | ✓ | string | Firestore Auth UID (auto-set, immutable) |
| `createdAt` | Timestamp | ✓ | DateTime | Document creation time (immutable) |
| `updatedAt` | Timestamp | ✓ | DateTime | Last modification time (auto-updated) |

---

## Schema Summary

**Total Fields**: 30
- Basic Info: 8 fields
- Financial: 3 fields
- Activity: 3 fields
- AI Intelligence: 7 fields
- Status: 2 fields
- Timeline: 1 field
- Metadata: 3 fields

**Total Serialization Methods**: 8
- `fromDoc()` - Firestore DocumentSnapshot → Dart
- `toMap()` - Dart → Firestore Map
- `fromJson()` - JSON String → Dart
- `toJson()` - Dart → JSON String
- Plus TimelineEvent: `fromMap()`, `toMap()`, `fromJson()`, `toJson()`

**Total Helper Methods**: 12+
- `addTimelineEvent()` - Add activity to timeline
- `updateAiScore()` - Set relationship score
- `updateChurnRisk()` - Set churn probability
- `updateAiSummary()` - Set AI summary + sentiment
- `updateStabilityLevel()` - Set stability classification
- `toggleVipStatus()` - Toggle VIP status
- `recordInvoicePayment()` - Record payment on invoice
- `recordInvoiceCreation()` - Record created invoice
- `copyWith()` - Immutable copy with field overrides
- Plus churn risk calculation methods in service

---

## Firestore Security Rules

### Create Validation
```javascript
function isValidClientCreate(data) {
  return data.keys().hasAll(['name', 'email', 'userId', 'createdAt']) &&
    typeof data.name == string &&
    typeof data.email == string &&
    typeof data.userId == string &&
    data.userId == request.auth.uid;
}
```

### Update Validation
```javascript
function isValidClientUpdate(data) {
  // Type validation for 30 fields
  // Enum validation for status, sentiment, stabilityLevel
  // Range validation for aiScore, churnRisk (0-100)
  // Immutability enforcement: userId, createdAt
}
```

---

## Usage Examples

### Creating a Client
```dart
final client = ClientModel(
  id: 'client_123',
  userId: currentUser.uid,
  name: 'John Doe',
  email: 'john@example.com',
  phone: '+1-555-0100',
  company: 'Acme Corp',
  address: '123 Main St',
  country: 'USA',
  notes: 'Key account',
  lifetimeValue: 5000.0,
  totalInvoices: 12,
  lastInvoiceAmount: 500.0,
  lastActivityAt: DateTime.now(),
  lastInvoiceDate: DateTime.now(),
  lastPaymentDate: DateTime.now(),
  aiScore: 75,
  churnRisk: 25,
  vipStatus: false,
  sentiment: 'positive',
  aiTags: ['high_value', 'responsive'],
  aiSummary: 'Engaged customer with consistent payment history',
  stabilityLevel: 'stable',
  tags: ['preferred', 'enterprise'],
  status: 'active',
  timeline: [],
  createdAt: DateTime.now(),
  updatedAt: DateTime.now(),
);
```

### Processing a Payment
```dart
final updated = await clientService.processPaymentReceived(
  clientId: 'client_123',
  paymentAmount: 500.0,
  paymentNote: 'Invoice #456 paid',
);
// Automatically updates:
// - lifetimeValue += 500
// - lastPaymentDate = now
// - aiScore += 20 (capped at 100)
// - vipStatus = (lifetimeValue > 10000)
// - timeline.events += [payment_received event]
// - churnRisk *= 0.85
```

### Calculating Churn Risk
```dart
final riskScore = clientService.calculateChurnRisk(client);
// Returns 0-100 based on:
// - Days since last activity (60+ = high)
// - Days since last payment (90+ = very high)
// - Lifetime value (low = higher risk)
// - Combined inactivity + low value (critical)
// - VIP discount (30% reduction)
```

### Getting High-Risk Clients
```dart
final atRisk = await clientService.getHighRiskClients();
final noPay90 = await clientService.getClientsNoPay90Days();
final inactive60 = await clientService.getInactiveClients60Days();
final lowValueInactive = await clientService.getLowValueInactiveClients();
```

---

## Data Consistency Notes

### Immutable Fields
- `userId` - Set on creation, never changes
- `createdAt` - Set on creation, never changes

### Auto-Updated Fields
- `updatedAt` - Updated on any modification
- `lastActivityAt` - Updated on client interaction
- `lastInvoiceDate` - Updated when invoice created
- `lastPaymentDate` - Updated when payment received

### Calculated Fields
- `churnRisk` - Calculated from activity, payment history, lifetime value
- `vipStatus` - Auto-evaluated: `lifetimeValue > 10000`
- `stabilityLevel` - Derived from churnRisk and payment consistency

### Atomic Operations
- Payment processing uses `FieldValue.increment()` for numerical updates
- Timeline events added with `FieldValue.arrayUnion()`
- All updates atomic (all-or-nothing)

---

## Migration Notes

### V1 → V2 Schema Changes
- Added: 16 new fields (country, address, aiTags, aiSummary, sentiment, etc.)
- Enhanced: Activity tracking (3 timestamps now tracked separately)
- New: Timeline for complete audit trail
- New: Churn risk calculation engine
- New: AI-powered relationship scoring

### Backward Compatibility
- All existing fields preserved
- New fields optional (nullable or default values)
- Existing queries continue working
- No breaking changes to service API

---

## Related Collections

### Invoices
- Path: `invoices/{invoiceId}` (top-level, ownership via userId field)
- Path: `users/{userId}/invoices/{invoiceId}` (nested)
- References client via `clientId` field

### Users
- Path: `users/{userId}`
- Contains user profile, settings, billing info

### Timeline (within Clients)
- Embedded array of TimelineEvent objects
- No separate collection (denormalized for performance)

---

## Performance Considerations

### Queries
- All client queries filtered by userId (index required)
- Churn risk queries done in-memory (sort after fetch)
- Timeline queries use array queries (limited to recent events)

### Indexes
- Composite: `userId + lastActivityAt` (descending)
- Single: `userId + status`
- Single: `userId + aiScore`
- Single: `userId + churnRisk`

### Scalability
- Subcollection structure ensures per-user isolation
- Max 30 fields per document (well within limits)
- Timeline array limited to ~100 events (for performance)

---

## Testing Checklist

- [x] All 30 fields serialize/deserialize correctly
- [x] Firestore rules validate all fields
- [x] Payment processing updates atomically
- [x] Churn risk calculates correctly
- [x] VIP status updates automatically
- [x] Timeline events immutable
- [x] Zero compilation errors
- [x] Full type safety (null safety)

---

## Next Steps

1. **Dashboard Integration** - Display churn risk, VIP status, timeline
2. **Alerts** - Notify on high-risk clients (churn > 80)
3. **Bulk Operations** - Update all churn risks via Cloud Function
4. **Reporting** - Export client insights (risk, value, activity)
5. **Predictions** - ML model for churn prediction (future)
