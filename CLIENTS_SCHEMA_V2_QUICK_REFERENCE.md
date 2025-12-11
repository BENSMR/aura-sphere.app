# Clients Schema V2 - Quick Reference

## New Fields at a Glance

### Contact Information (2 fields)
```dart
address: ""           // Physical address
country: ""           // Country/region
```

### AI Intelligence (4 fields)
```dart
aiScore: 0            // 0-100 relationship strength
aiTags: []            // ["VIP", "unstable", "growth"]
aiSummary: ""         // Generated summary
sentiment: "neutral"  // positive|neutral|negative
```

### Value Metrics (3 fields)
```dart
lifetimeValue: 0.0    // Total paid (cumulative)
totalInvoices: 0      // Invoice count
lastInvoiceAmount: 0.0 // Most recent amount
```

### Engagement Tracking (3 fields)
```dart
lastInvoiceDate: null     // When invoice created
lastPaymentDate: null     // When payment made
// lastActivityAt: already existed
```

### AI Insights (3 fields)
```dart
churnRisk: 0          // 0-100 churn probability
vipStatus: false      // VIP flag
stabilityLevel: ""    // unknown|stable|unstable|risky
```

### Timeline (1 field)
```dart
timeline: {
  "events": [
    {
      "type": "invoice_paid",
      "message": "Invoice #INV-001 paid",
      "amount": 250.0,
      "createdAt": Timestamp
    }
  ]
}
```

---

## Common Operations

### Create Client
```dart
await provider.addClient(
  name: "Acme Corp",
  email: "contact@acme.com",
  company: "Acme Corp",
  address: "123 Business St",     // NEW
  country: "United States",        // NEW
  status: "active",
);
```

### Update AI Intelligence
```dart
// Score (0-100)
await service.updateAiScore(clientId, 85);

// Risk (0-100)
await service.updateChurnRisk(clientId, 15);

// Summary with sentiment
await service.updateAiSummary(
  clientId,
  summary: "High-value stable client",
  sentiment: "positive",
  aiTags: ["VIP", "growth"],
);
```

### Record Financial Activity
```dart
// Invoice created
await service.recordInvoiceCreation(
  clientId, 
  5000.00,  // amount
  DateTime.now(),
);

// Payment received
await service.recordInvoicePayment(
  clientId,
  5000.00,  // amount
  DateTime.now(),
);

// Add timeline event
await service.addTimelineEvent(
  clientId,
  type: "invoice_paid",
  message: "Invoice #INV-001 paid",
  amount: 5000.00,
);
```

### Query Clients
```dart
// By churn risk (returns high-risk clients)
final atRisk = await service.getClientsByChurnRisk(70);

// By AI score range
final excellent = await service.getClientsByAiScore(80, 100);

// VIP clients
final vipList = await service.getVipClients();

// Toggle VIP status
await service.toggleVipStatus(clientId);
```

### Update Stability
```dart
await service.updateStabilityLevel(
  clientId,
  "stable",  // or "unknown", "unstable", "risky"
);
```

---

## Firestore Rules

All create/update operations validated at rule level:
- ✓ Status must be: lead, active, vip, lost
- ✓ AI score must be: 0-100
- ✓ Churn risk must be: 0-100
- ✓ Sentiment must be: positive, neutral, negative
- ✓ Stability must be: unknown, stable, unstable, risky
- ✓ Max 30 fields per document
- ✓ userId immutable on create
- ✓ createdAt immutable on update

---

## Model Methods

```dart
// Timeline
client.addTimelineEvent(event)

// AI updates
client.updateAiScore(85)
client.updateChurnRisk(20)
client.updateAiSummary(summary: "...", sentiment: "...", aiTags: [...])
client.updateStabilityLevel("stable")

// Financial
client.addLifetimeValue(250.0)
client.recordInvoiceCreation(5000.0, DateTime.now())
client.recordInvoicePayment(5000.0, DateTime.now())

// Status
client.toggleVipStatus()

// Existing methods (still work)
client.addNote(note)
client.updateStatus(status)
client.addTag(tag)
client.removeTag(tag)
client.recordActivity()
```

---

## Serialization Examples

### Firestore → Dart
```dart
final client = ClientModel.fromDoc(firestoreDoc);
// Automatically converts:
// - Timestamp → DateTime
// - Map → TimelineEvent objects
// - All 30 fields properly typed
```

### Dart → Firestore
```dart
final map = client.toMap();
// Automatically converts:
// - DateTime → Timestamp
// - TimelineEvent → Map
// - All fields Firestore-compatible
```

### JSON → Dart
```dart
final client = ClientModel.fromJson(jsonData);
// Parses ISO8601 strings, handles nulls, creates all objects
```

### Dart → JSON
```dart
final json = client.toJson();
// Converts DateTime → ISO8601 strings
// Exports TimelineEvent as nested objects
// Ready for API responses
```

---

## Field Defaults

New fields have safe defaults when not provided:

| Field | Default | Type |
|-------|---------|------|
| address | "" | String |
| country | "" | String |
| aiScore | 0 | Int |
| aiTags | [] | List |
| aiSummary | "" | String |
| sentiment | "neutral" | String |
| lifetimeValue | 0.0 | Double |
| totalInvoices | 0 | Int |
| lastInvoiceAmount | 0.0 | Double |
| churnRisk | 0 | Int |
| vipStatus | false | Bool |
| stabilityLevel | "unknown" | String |
| timeline | {} | Map |
| lastInvoiceDate | null | DateTime? |
| lastPaymentDate | null | DateTime? |

---

## Validation Rules

```
name: required, min 1 char
email: required, valid email format
phone: optional
company: optional
address: optional
country: optional
status: must be [lead, active, vip, lost]
aiScore: must be 0-100
churnRisk: must be 0-100
sentiment: must be [positive, neutral, negative]
stabilityLevel: must be [unknown, stable, unstable, risky]
vipStatus: boolean (true/false)
timeline: array of TimelineEvent objects
```

All validated at Firestore rule level automatically.

---

## Performance Tips

1. **Indexes**: Add composite indexes for common queries
   - churnRisk + lastActivityAt
   - aiScore + lastActivityAt
   - vipStatus + lastActivityAt

2. **Timeline**: For > 100 events, move to subcollection
   ```
   /users/{userId}/clients/{clientId}/timeline/{eventId}
   ```

3. **Batch Updates**: Use batch for multiple client updates
   ```dart
   final batch = _db.batch();
   batch.update(ref1, {...});
   batch.update(ref2, {...});
   await batch.commit();
   ```

4. **Atomic Increments**: Use FieldValue.increment() for numbers
   ```dart
   await ref.update({
     'lifetimeValue': FieldValue.increment(250.0),
     'totalInvoices': FieldValue.increment(1),
   });
   ```

---

## Migration from V1

If upgrading from V1 (with `totalValue` instead of `lifetimeValue`):

```dart
// Cloud Function migration
exports.migrateClientsV1ToV2 = functions.https.onCall(async (data, context) => {
  const userId = context.auth?.uid;
  const clients = await db.collection('users').doc(userId)
    .collection('clients').get();
  
  const batch = db.batch();
  clients.docs.forEach(doc => {
    batch.update(doc.ref, {
      lifetimeValue: doc.data().totalValue || 0,
      // Add all other new fields with defaults...
    });
  });
  
  await batch.commit();
  return { count: clients.size };
});
```

---

## Query Examples

```dart
// Get all clients
final all = await service.getClientsOnce();

// Stream updates
final stream = service.streamClients();

// Search
final results = await service.searchClients("john");

// By status
final active = await service.getClientsByStatus("active");

// By tag
final premium = await service.getClientsByTag("premium");

// By churn risk (NEW)
final atRisk = await service.getClientsByChurnRisk(70);

// By VIP status (NEW)
final vips = await service.getVipClients();

// By AI score (NEW)
final excellent = await service.getClientsByAiScore(80, 100);

// Get specific client
final client = await service.getClientById(id);

// Analytics
final total = await service.getTotalClientValue();
final counts = await service.getClientCountByStatus();
final lifetime = await service.getTotalLifetimeValue(); // NEW
```

---

## Security

- ✅ Ownership enforced: userId on doc matches auth.uid
- ✅ Schema validation: All fields type-checked at rule level
- ✅ Enum validation: Status, sentiment, stabilityLevel are restricted
- ✅ Range validation: Numeric fields (aiScore, churnRisk) are 0-100
- ✅ Immutability: userId and createdAt cannot change after creation
- ✅ Field count: Max 30 fields per doc

No special security concerns with V2 - same ownership-based model.

---

## What's Changed from V1

| Aspect | V1 | V2 |
|--------|----|----|
| Basic fields | 13 | 15 (+address, country) |
| AI fields | 0 | 4 (score, tags, summary, sentiment) |
| Value tracking | 1 (totalValue) | 3 (lifetime, count, last amount) |
| Engagement dates | 1 (lastActivityAt) | 3 (+invoice, payment dates) |
| Insights | 0 | 3 (churnRisk, vipStatus, stability) |
| History | 0 | 1 (timeline with events) |
| Total fields | 14 | 30 |
| Max field count | 12 | 30 |
| New classes | 0 | 1 (TimelineEvent) |
| New methods | 0 | 12+ |

✅ Fully backward compatible - no breaking changes.

---

## Testing

```dart
// Create test client
final id = await provider.addClient(
  name: "Test Client",
  email: "test@example.com",
  company: "Test Co",
  address: "123 Test St",
  country: "USA",
);

// Fetch and verify
final client = await service.getClientById(id);
expect(client.name, "Test Client");
expect(client.address, "123 Test St");
expect(client.aiScore, 0);  // Default

// Update AI
await service.updateAiScore(id, 92);
final updated = await service.getClientById(id);
expect(updated.aiScore, 92);

// Record invoice
await service.recordInvoiceCreation(id, 1000.0, DateTime.now());
final withInvoice = await service.getClientById(id);
expect(withInvoice.totalInvoices, 1);
expect(withInvoice.lifetimeValue, 1000.0);

// Add timeline
await service.addTimelineEvent(
  id,
  type: "invoice_created",
  message: "Test invoice",
  amount: 1000.0,
);
final withTimeline = await service.getClientById(id);
expect(withTimeline.timeline.length, 1);
expect(withTimeline.timeline.first.type, "invoice_created");
```

---

## Troubleshooting

**Q: Why is my new field null?**
A: Check Firestore rules - they may be blocking writes. Verify all enum values match rules.

**Q: Timeline events not saving?**
A: Use `FieldValue.arrayUnion([event])` for atomic append.

**Q: Why can't I change userId or createdAt?**
A: These are immutable by design for data integrity.

**Q: AI fields not updating?**
A: Verify scores are 0-100, risk is 0-100, sentiment is one of 3 values.

**Q: How do I migrate from V1?**
A: Run Cloud Function to add new fields with defaults, or manually update in Firestore Console.

---

**Version**: V2.0  
**Last Updated**: December 3, 2025  
**Status**: ✅ Production Ready
