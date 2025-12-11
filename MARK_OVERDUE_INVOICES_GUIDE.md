# Mark Overdue Invoices - Scheduled Cloud Function

## Overview
Automated scheduled function that runs every 24 hours (or 6 hours for batch variant) to mark invoices as overdue when their due date has passed.

## Functions

### 1. `markOverdueInvoices` (Recommended)
**Trigger:** Pub/Sub schedule - every 24 hours (UTC midnight)
**Type:** Scheduled Cloud Function

**What it does:**
- Queries all invoices with status "unpaid" or "partial"
- Filters for invoices with due dates in the past
- Batch updates all matching invoices to status "overdue"
- Adds `updatedAt` server timestamp

**Example Flow:**
```
1. Query: status IN ["unpaid", "partial"] AND dueDate < now
2. Result: [invoice1, invoice2, invoice3]
3. Update: status → "overdue" for all 3
4. Log: "Successfully marked 3 invoices as overdue"
```

**Firestore Impact:**
- Before: `{ status: "unpaid", dueDate: 2025-11-30 }`
- After: `{ status: "overdue", dueDate: 2025-11-30, updatedAt: 2025-12-02T00:00:00Z }`

### 2. `markOverdueInvoicesBatch` (High Volume)
**Trigger:** Pub/Sub schedule - every 6 hours
**Type:** Scheduled Cloud Function

**Features:**
- Processes invoices in pages of 100 (Firestore batch write limit is 500)
- Better for high-volume collections
- Returns success stats: `{ success: true, updatedCount: 1247 }`
- Safer for collections with thousands of invoices

### 3. `checkOverdueInvoices` (Manual Trigger)
**Trigger:** HTTP POST request
**Type:** Callable HTTP function

**Endpoint:** `POST /checkOverdueInvoices`

**Usage (for testing or manual triggers):**
```bash
curl -X POST https://region-project.cloudfunctions.net/checkOverdueInvoices
```

**Response:**
```json
{
  "success": true,
  "message": "Marked 5 invoices as overdue",
  "timestamp": "2025-12-02T15:30:00Z"
}
```

## Deployment

### Deploy to Firebase
```bash
firebase deploy --only functions:markOverdueInvoices,functions:markOverdueInvoicesBatch,functions:checkOverdueInvoices
```

### Verify Deployment
```bash
firebase functions:list
```

Should show:
```
Function         Trigger
markOverdueInvoices         pubsub
markOverdueInvoicesBatch    pubsub
checkOverdueInvoices        http
```

## Database Schema Requirements

The invoices collection must have:
- `status`: String field ("unpaid" | "partial" | "overdue" | "paid")
- `dueDate`: Timestamp field

### Recommended Firestore Index
**Collection:** `invoices`
**Fields:**
1. `status` (Ascending)
2. `dueDate` (Ascending)

**Create index:**
```bash
firebase firestore:indexes
```

## Monitoring

### View Logs
```bash
firebase functions:log --limit 50
```

### Set Alerts
In Google Cloud Console:
1. Go to Cloud Logging
2. Create alert for function errors
3. Filter: `resource.type="cloud_function" AND function_name="markOverdueInvoices" AND severity="ERROR"`

## Cost Considerations

**Daily (markOverdueInvoices):**
- 1 read operation per invoice queried
- 1 write operation per invoice updated
- Free tier: 50,000 reads/writes per day

**Example:**
- 100 invoices queried
- 20 updates
- Cost: ~120 operations (~1% of daily free tier)

## Error Handling

All functions include try-catch blocks:
- Logs errors to Cloud Logging
- Scheduled functions throw errors (retried by Cloud Functions)
- HTTP function returns 500 status on error

**Example Error Log:**
```
Error in markOverdueInvoices: FirebaseError: 9 FAILED_PRECONDITION: ...
```

## Testing

### Local Testing
```typescript
// Use Firebase emulator
firebase emulators:start

// Call from app
const callable = firebase.functions().httpsCallable('checkOverdueInvoices');
const result = await callable({});
console.log(result.data);
```

### Production Testing
1. Create test invoice with:
   - `status: "unpaid"`
   - `dueDate: <yesterday>`
2. Call `checkOverdueInvoices` endpoint
3. Verify status changed to `"overdue"`

## Troubleshooting

### Function doesn't run
- Check Cloud Scheduler job is enabled
- Verify service account has Firestore permissions
- Check function logs in Cloud Console

### Query returns 0 results but invoices exist
- Verify index is built (see Database Schema Requirements)
- Check invoice `dueDate` format is Timestamp
- Ensure status is exactly "unpaid" or "partial"

### Batch function runs slowly
- Increase page size (change `pageSize = 100` to 200-500)
- Check Firestore write throughput
- Monitor read/write latency in Cloud Console

## Next Steps

1. ✅ Deploy to Firebase
2. ✅ Create Firestore index
3. ✅ Monitor logs for 24 hours
4. ✅ Set up Cloud Alerting
5. ✅ Test with manual HTTP trigger
6. ✅ Integrate with invoice creation workflow

## Integration Points

### Invoice Creation
When creating invoice, ensure `dueDate` is set:
```dart
// Flutter code
final invoice = InvoiceModel(
  ...
  dueDate: DateTime.now().add(Duration(days: 30)),
  ...
);
```

### Payment Recording
When marking invoice as paid, status updates to "paid" (bypasses overdue check):
```dart
await invoiceService.markInvoicePaid(invoiceId, paymentMethod);
// status: "paid" → never marked as overdue again
```

### Dashboard Display
Show overdue count:
```dart
// Query overdue invoices
final overdueQuery = db
  .collection('invoices')
  .where('status', isEqualTo: 'overdue');
```
