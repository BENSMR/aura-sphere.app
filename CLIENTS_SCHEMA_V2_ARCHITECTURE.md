# Clients Schema V2 - Architecture & Data Flow

## System Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│                         Flutter App                             │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  ┌────────────────────────────────────────────────────────┐    │
│  │            UI Screens                                   │    │
│  │  - ClientListScreen                                    │    │
│  │  - ClientDetailScreen                                 │    │
│  │  - EditClientScreen                                   │    │
│  └────────────┬───────────────────────────────────────────┘    │
│               │                                                 │
│  ┌────────────▼───────────────────────────────────────────┐    │
│  │         ClientProvider (State Management)              │    │
│  │  - Real-time streams                                  │    │
│  │  - Multi-filter support                              │    │
│  │  - 30+ state methods                                 │    │
│  └────────────┬───────────────────────────────────────────┘    │
│               │                                                 │
│  ┌────────────▼───────────────────────────────────────────┐    │
│  │         ClientService (Business Logic)                 │    │
│  │  - CRUD operations                                    │    │
│  │  - AI scoring methods                                │    │
│  │  - Financial tracking                                │    │
│  │  - Timeline management                               │    │
│  └────────────┬───────────────────────────────────────────┘    │
│               │                                                 │
└───────────────┼─────────────────────────────────────────────────┘
                │
                │ Serialization
                │
        ┌───────▼────────┐
        │  ClientModel   │
        │   + Fields     │
        │   + Methods    │
        │   + Serializer │
        └───────┬────────┘
                │
                │ Firestore SDK
                │
┌───────────────▼─────────────────────────────────────────────────┐
│                    Firebase/Firestore                           │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  /users/{userId}                                               │
│    └── /clients/{clientId}                                     │
│         ├─ name, email, phone, company                        │
│         ├─ address, country                                   │
│         ├─ tags, status, notes                                │
│         ├─ aiScore, aiTags, aiSummary, sentiment             │
│         ├─ lifetimeValue, totalInvoices, lastInvoiceAmount  │
│         ├─ churnRisk, vipStatus, stabilityLevel             │
│         ├─ timeline { events[] }                             │
│         ├─ lastActivityAt, lastInvoiceDate, lastPaymentDate │
│         ├─ createdAt, updatedAt                             │
│         └─ userId (ownership)                               │
│                                                                 │
│  Firestore Rules (Security)                                    │
│  ├─ isValidClientCreate()     (30 field validation)          │
│  └─ isValidClientUpdate()      (immutability + validation)    │
│                                                                 │
└─────────────────────────────────────────────────────────────────┘
```

---

## Data Flow Diagrams

### Creating a Client (Flow)

```
User Input
    │
    ├─ name (required)
    ├─ email (required)
    ├─ phone, company, address, country (optional)
    └─ notes, tags, status (optional)
         │
         ▼
    EditClientScreen
         │
         ▼
    ClientProvider.addClient()
         │
         ▼
    ClientService.createClient()
         │
         ├─ Sets defaults:
         │  ├─ aiScore = 0
         │  ├─ churnRisk = 0
         │  ├─ vipStatus = false
         │  ├─ lifetimeValue = 0
         │  ├─ totalInvoices = 0
         │  ├─ timeline = []
         │  └─ sentiment = "neutral"
         │
         ▼
    Firestore Rules Validation
         │
         ├─ Check: isValidClientCreate()
         ├─ Type check all 30 fields
         ├─ Enum validation (status, sentiment, stability)
         ├─ Range validation (aiScore, churnRisk 0-100)
         └─ Field count <= 30
         │
         ▼
    /users/{userId}/clients/{clientId}
         │
         ▼
    ✅ Document Created
```

### Recording Invoice Payment (Flow)

```
Invoice Paid Event
    │
    ▼
ClientProvider.recordInvoicePayment(clientId, amount, date)
    │
    ▼
ClientService.recordInvoicePayment()
    │
    ├─ Update fields (atomic):
    │  ├─ lastPaymentDate = date
    │  ├─ lifetimeValue += amount
    │  └─ lastActivityAt = date
    │
    ▼
Firestore Update
    │
    ├─ Validation: isValidClientUpdate()
    ├─ Check: userId immutable ✓
    ├─ Check: createdAt immutable ✓
    └─ Check: All fields valid ✓
    │
    ▼
ClientProvider receives update via stream
    │
    ▼
UI refreshes with new data
    │
    ▼
✅ Payment recorded
```

### Updating AI Intelligence (Flow)

```
AI Analysis Engine
    │
    ├─ Calculates: aiScore (0-100)
    ├─ Generates: aiSummary (text)
    ├─ Determines: sentiment (positive|neutral|negative)
    ├─ Creates: aiTags (["VIP", "growth", ...])
    └─ Estimates: churnRisk (0-100)
         │
         ▼
    Cloud Function (or Server)
         │
         ▼
    ClientService.updateAiSummary(
        clientId,
        summary: "...",
        sentiment: "positive",
        aiTags: [...]
    )
         │
         ▼
    Also calls:
    ├─ updateAiScore(id, 87)
    └─ updateChurnRisk(id, 15)
         │
         ▼
    Firestore Rules Validation
         │
         ├─ Check: aiScore 0-100 ✓
         ├─ Check: sentiment in ['positive','neutral','negative'] ✓
         ├─ Check: churnRisk 0-100 ✓
         └─ Check: aiTags is list ✓
         │
         ▼
    Update Document
    /users/{userId}/clients/{clientId}
    {
        aiScore: 87,
        aiSummary: "...",
        sentiment: "positive",
        aiTags: [...],
        churnRisk: 15,
        updatedAt: now
    }
         │
         ▼
    ✅ AI Data Updated
         │
         ▼
    ClientProvider streams update
         │
         ▼
    UI displays updated scores
```

### Adding Timeline Event (Flow)

```
Client Activity Event
    │
    ├─ type: "invoice_paid"
    ├─ message: "Invoice #INV-001 paid"
    └─ amount: 2000.0
         │
         ▼
    ClientService.addTimelineEvent(
        clientId,
        type, message, amount
    )
         │
         ▼
    Create TimelineEvent object
    {
        type: "invoice_paid",
        message: "Invoice #INV-001 paid",
        amount: 2000.0,
        createdAt: DateTime.now()
    }
         │
         ▼
    Serialize to Map
    {
        type: "invoice_paid",
        message: "Invoice #INV-001 paid",
        amount: 2000.0,
        createdAt: Timestamp
    }
         │
         ▼
    Append to timeline.events array
    │
    │ Using FieldValue.arrayUnion()
    │
    ▼
Firestore Update
    {
        timeline.events: FieldValue.arrayUnion([newEvent])
        updatedAt: now
    }
         │
         ▼
    Validation: timeline is map ✓
         │
         ▼
    /users/{userId}/clients/{clientId}
         │
         ├─ timeline.events now contains 1+ objects
         └─ updatedAt = current timestamp
         │
         ▼
    ✅ Timeline Event Added
         │
         ▼
    ClientProvider receives stream update
         │
         ▼
    ClientModel.fromDoc() parses events
         │
         ├─ Iterates timeline.events
         ├─ Creates TimelineEvent objects
         └─ Converts Timestamps to DateTime
         │
         ▼
    UI displays timeline history
```

### Querying High-Risk Clients (Flow)

```
User clicks: "Show at-risk clients"
    │
    ▼
ClientProvider.getClientsByChurnRisk(70)
    │
    ▼
ClientService.getClientsByChurnRisk(70)
    │
    ├─ Query: WHERE churnRisk >= 70
    ├─ Order: BY churnRisk DESC
    └─ Requires: Firestore Index
         │
         ▼
    Firestore Index Lookup
    {
        Collection: clients
        Fields: churnRisk (Desc) + lastActivityAt (Desc)
    }
         │
         ▼
    Matching documents:
    ├─ Client A: churnRisk = 85
    ├─ Client B: churnRisk = 78
    ├─ Client C: churnRisk = 75
    └─ ... etc
         │
         ▼
    Deserialize to ClientModel objects
         │
         ├─ ClientModel.fromDoc(docA)
         ├─ ClientModel.fromDoc(docB)
         └─ etc.
         │
         ▼
    Return List<ClientModel>
         │
         ▼
    ClientProvider updates state
    {
        riskyClients = [ClientA, ClientB, ClientC, ...]
    }
         │
         ▼
    UI displays list
    ├─ ClientA: Risk 85 (Red)
    ├─ ClientB: Risk 78 (Orange)
    ├─ ClientC: Risk 75 (Orange)
    └─ ... etc
         │
         ▼
    ✅ Query results displayed
```

---

## Field Dependency Map

```
┌─ Timeline Management
│  └─ timeline: List<TimelineEvent>
│     ├─ type: String
│     ├─ message: String
│     ├─ amount: double
│     └─ createdAt: DateTime
│        (updated by: recordInvoicePayment, recordInvoiceCreation, addTimelineEvent)

├─ AI Intelligence
│  ├─ aiScore: int (0-100)
│  │  └─ updated by: updateAiScore()
│  ├─ aiTags: List<String>
│  │  └─ updated by: updateAiSummary()
│  ├─ aiSummary: String
│  │  └─ updated by: updateAiSummary()
│  └─ sentiment: String (positive|neutral|negative)
│     └─ updated by: updateAiSummary()

├─ Financial Tracking
│  ├─ lifetimeValue: double
│  │  ├─ updated by: recordInvoicePayment()
│  │  └─ updated by: addLifetimeValue()
│  ├─ totalInvoices: int
│  │  └─ updated by: recordInvoiceCreation()
│  └─ lastInvoiceAmount: double
│     └─ updated by: recordInvoiceCreation()

├─ Engagement Tracking
│  ├─ lastActivityAt: DateTime
│  │  ├─ updated by: recordActivity()
│  │  ├─ updated by: recordInvoicePayment()
│  │  └─ updated by: recordInvoiceCreation()
│  ├─ lastInvoiceDate: DateTime
│  │  └─ updated by: recordInvoiceCreation()
│  └─ lastPaymentDate: DateTime
│     └─ updated by: recordInvoicePayment()

├─ Risk Analysis
│  ├─ churnRisk: int (0-100)
│  │  └─ updated by: updateChurnRisk()
│  ├─ stabilityLevel: String
│  │  └─ updated by: updateStabilityLevel()
│  └─ vipStatus: bool
│     └─ updated by: toggleVipStatus()

└─ Status & Classification
   ├─ status: String (lead|active|vip|lost)
   │  └─ updated by: updateStatus()
   ├─ tags: List<String>
   │  ├─ updated by: addTag()
   │  └─ updated by: removeTag()
   ├─ notes: String
   │  └─ updated by: addNote()
   ├─ address: String
   ├─ country: String
   └─ Immutable:
      ├─ userId
      ├─ createdAt
      └─ (updated by updatedAt timestamp)
```

---

## Query Performance Indexes

Recommended Firestore Indexes for optimal performance:

```
Index 1: Churn Risk Query
  Collection: users/{userId}/clients
  Fields:
    - churnRisk (Descending)
    - lastActivityAt (Descending)
  Use: getClientsByChurnRisk()

Index 2: AI Score Query
  Collection: users/{userId}/clients
  Fields:
    - aiScore (Descending)
    - lastActivityAt (Descending)
  Use: getClientsByAiScore()

Index 3: VIP Clients Query
  Collection: users/{userId}/clients
  Fields:
    - vipStatus (Ascending)
    - lastActivityAt (Descending)
  Use: getVipClients()

Index 4: Status & Value Query
  Collection: users/{userId}/clients
  Fields:
    - status (Ascending)
    - lifetimeValue (Descending)
  Use: getClientsByStatus() with financial sorting

Index 5: Stability Query
  Collection: users/{userId}/clients
  Fields:
    - stabilityLevel (Ascending)
    - createdAt (Descending)
  Use: Segment by stability
```

---

## Serialization Pathways

### Firestore → Dart
```
DocumentSnapshot (Firestore)
    │
    │ FieldPath: data['fieldName']
    │
    ▼
Map<String, dynamic>
    │
    │ Type conversions:
    │ ├─ Timestamp → DateTime (via .toDate())
    │ ├─ List → List<TimelineEvent> (via .map(fromMap))
    │ └─ int/double preserved
    │
    ▼
ClientModel (Dart object)
    └─ All 30 fields properly typed
    └─ DateTime instead of Timestamp
    └─ TimelineEvent objects instead of Maps
```

### Dart → Firestore
```
ClientModel (Dart object)
    │
    │ client.toMap()
    │
    ▼
Map<String, dynamic>
    │
    │ Type conversions:
    │ ├─ DateTime → Timestamp (via Timestamp.fromDate())
    │ ├─ List<TimelineEvent> → List<Map> (via .toMap())
    │ └─ int/double preserved
    │
    ▼
Firestore Document (stored in database)
    └─ All 30 fields Firestore-compatible
    └─ Timestamp objects (not DateTime)
    └─ Maps instead of objects
```

### Dart ↔ JSON
```
ClientModel ←→ Map<String, dynamic>

toJson():
  DateTime → ISO8601 string
  TimelineEvent → Map<String, dynamic>
  Preserves all 30 fields

fromJson():
  ISO8601 string → DateTime
  Map → TimelineEvent object
  All fields properly typed
```

---

## Error Handling

### Validation Errors (Firestore Rules)

```
User tries to create client with invalid data:
  ├─ Invalid status (not in enum)
  │  → Error: "status must be one of [lead, active, vip, lost]"
  │
  ├─ Invalid aiScore (> 100)
  │  → Error: "aiScore must be 0-100"
  │
  ├─ Invalid sentiment (not recognized)
  │  → Error: "sentiment must be positive|neutral|negative"
  │
  ├─ Too many fields (> 30)
  │  → Error: "Document size exceeds limit"
  │
  └─ Missing userId
     → Error: "userId is required"
```

### Service Errors

```
ClientService method throws:
  ├─ ArgumentError if:
  │  ├─ score < 0 or score > 100
  │  ├─ risk < 0 or risk > 100
  │  └─ stability level not in enum
  │
  ├─ Exception if:
  │  ├─ User not authenticated
  │  ├─ Document not found
  │  └─ Firestore operation fails
  │
  └─ Handled in:
     ├─ try/catch in Service
     └─ try/catch in Provider
        └─ Logged with print() and notifyListeners()
```

### UI Error Handling

```
Provider handles errors:
  ├─ Sets _isLoading = false
  ├─ Calls notifyListeners()
  └─ Logs error to console

UI should:
  ├─ Check provider.isLoading before showing spinner
  ├─ Catch exceptions from async operations
  └─ Show error snackbars to user
```

---

## Security Model

```
Authentication & Authorization
    │
    ├─ User logs in via Firebase Auth
    │  └─ request.auth.uid = unique identifier
    │
    ├─ User can only access their own data
    │  └─ /users/{userId}/clients
    │     └─ request.auth.uid must == userId
    │
    └─ All operations validated at Firestore level
       ├─ Create: isValidClientCreate()
       ├─ Update: isValidClientUpdate()
       ├─ Read: ownership check
       └─ Delete: ownership check

Data Validation at Rule Level
    │
    ├─ Type checking (all 30 fields)
    ├─ Enum validation (status, sentiment, stability)
    ├─ Range validation (aiScore, churnRisk 0-100)
    ├─ Immutability (userId, createdAt)
    └─ Field count limit (≤ 30)

No special security concerns with V2:
    ├─ Same ownership model as V1
    ├─ More comprehensive validation
    ├─ Better data integrity
    └─ No exposure of sensitive data
```

---

## Scalability Considerations

```
Single User (100 clients)
  ├─ Storage: ~300-400 KB
  ├─ Queries: < 100 ms
  └─ Writes: < 50 ms

Medium User (1,000 clients)
  ├─ Storage: ~3-4 MB
  ├─ Queries: 100-500 ms
  ├─ Writes: 50-100 ms
  └─ Requires: Firestore Indexes

Large User (10,000+ clients)
  ├─ Storage: ~30-40 MB
  ├─ Queries: 500+ ms
  ├─ Writes: 100+ ms
  │
  ├─ Optimization strategies:
  │  ├─ Use pagination (limit: 100)
  │  ├─ Add Firestore Indexes
  │  ├─ Move timeline to subcollection if > 100 events
  │  └─ Implement caching layer
  │
  └─ Consider splitting into shards:
     ├─ /users/{userId}/clients_a-f
     ├─ /users/{userId}/clients_g-m
     └─ /users/{userId}/clients_n-z
```

---

## Version History & Roadmap

```
V1.0 (Original)
  ├─ Basic fields: name, email, phone, company, notes
  ├─ Status & tags
  ├─ totalValue tracking
  └─ Timestamps: createdAt, updatedAt, lastActivityAt

V2.0 (Current) ✅ COMPLETE
  ├─ NEW: Address, country
  ├─ NEW: AI intelligence (score, tags, summary, sentiment)
  ├─ NEW: Value metrics (lifetime, count, last amount)
  ├─ NEW: Engagement dates (invoice, payment)
  ├─ NEW: Insights (churn risk, VIP, stability)
  ├─ NEW: Timeline events
  ├─ Enhanced serialization
  ├─ 12 new service methods
  └─ Firestore rule improvements

V3.0 (Planned)
  ├─ Client segmentation (custom segments)
  ├─ Advanced dashboard
  ├─ Predictive analytics
  ├─ Custom fields
  ├─ Related clients linking
  └─ Activity webhooks

V4.0+ (Future)
  ├─ Machine learning integration
  ├─ Automated insights
  ├─ Email campaign history
  ├─ Customer portal
  └─ Advanced reporting
```

---

**Version**: 2.0  
**Last Updated**: December 3, 2025  
**Status**: ✅ Production Ready
