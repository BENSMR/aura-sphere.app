# Invoice Numbering Schema - AuraSphere Pro

## Firestore Document Structure

**Location:** `/users/{uid}/settings/invoice_settings`

### Schema Definition

```json
{
  "prefix": "AURA-",
  "nextNumber": 1001,
  "resetRule": "yearly",
  "lastReset": "<Timestamp>"
}
```

### Field Descriptions

| Field | Type | Description | Example |
|-------|------|-------------|---------|
| `prefix` | String | Invoice number prefix | `"AURA-"`, `"INV-"`, `"2025-"` |
| `nextNumber` | Integer | Next sequential number to allocate | `1001`, `1002`, `1003` |
| `resetRule` | String | Auto-reset frequency | `"none"`, `"monthly"`, `"yearly"` |
| `lastReset` | Timestamp | Last reset date/time | Firestore Timestamp |

## Reset Rules

### `"none"`
- No automatic reset
- Counter increments indefinitely
- Example: `AURA-1001`, `AURA-1002`, `AURA-1003`, ...

### `"monthly"`
- Resets to 1 on first invoice of each month
- Counter includes month/year in formatted number
- Example: `AURA-202512-001`, `AURA-202512-002`, ... (December 2025)
- Next month: `AURA-202501-001` (January 2025)
- Formatting: `{prefix}{YYYY}{MM}-{0000}`

### `"yearly"`
- Resets to 1 on first invoice of each year
- Counter includes year in formatted number
- Example: `AURA-2025-1001`, `AURA-2025-1002`, ... (2025)
- Next year: `AURA-2026-1001` (2026)
- Formatting: `{prefix}{YYYY}-{0000}`

## Cloud Function Usage

### Call generateNextInvoiceNumber()

**Request:**
```dart
final callable = FirebaseFunctions.instance
  .httpsCallable('generateNextInvoiceNumber');
final result = await callable.call();
```

**Response:**
```json
{
  "invoiceNumber": "AURA-2025-1001",
  "number": 1001,
  "nextNumber": 1002
}
```

## Flutter Integration

### Via BrandingProvider

```dart
// Load settings
await brandingProvider.load(uid);

// Get formatted preview (no increment)
final preview = await brandingProvider.getNextInvoiceNumber();
print(preview); // "AURA-1001"

// Get next number value
final value = brandingProvider.getNextInvoiceNumberValue(); // 1001

// Generate and increment
final generated = await brandingProvider.generateNextInvoiceNumber(uid);
print(generated); // "AURA-1001" (nextNumber now 1002)

// Get settings
final prefix = brandingProvider.getInvoiceNumberPrefix(); // "AURA-"
final rule = brandingProvider.getResetRule(); // "yearly"
```

### Via InvoiceService

```dart
final invoiceService = InvoiceService();

// Call Cloud Function
final invoiceNumber = await invoiceService.getNextInvoiceNumber();
print(invoiceNumber); // "AURA-2025-1001"
```

### Via InvoiceSettingsScreen

Navigate to `/settings/invoice-settings` to:
- Configure prefix (e.g., "INV-", "2025-")
- Set next number starting point
- Choose reset rule (none, monthly, yearly)
- Preview formatted number

## Transaction Safety

The Cloud Function uses Firestore transactions to ensure:
- **Atomic operations**: Read, check reset, increment, write all happen together
- **No race conditions**: Two simultaneous calls won't allocate the same number
- **Consistency**: `lastReset` timestamp updated atomically with reset

## Example Workflows

### Setup (First Time)
```
User navigates to Invoice Settings
Enters: prefix = "INV-", nextNumber = 1, resetRule = "yearly"
First invoice generated: "INV-2025-0001"
nextNumber increments to 2
```

### Monthly Reset
```
December 2025, Invoice 1: "AURA-202512-001"
December 2025, Invoice 2: "AURA-202512-002"
January 2026 (new month), Invoice 1: "AURA-202501-001"
  (counter resets to 1, lastReset updated to Jan 1, 2026)
January 2026, Invoice 2: "AURA-202501-002"
```

### Yearly Reset
```
2025, Invoice 1: "AURA-2025-1001"
2025, Invoice 2: "AURA-2025-1002"
2026 (new year), Invoice 1: "AURA-2026-1001"
  (counter resets to 1, lastReset updated to Jan 1, 2026)
2026, Invoice 2: "AURA-2026-1002"
```

## Security & Firestore Rules

Typical security rule for invoice settings (read/write):
```
match /users/{uid}/settings/invoice_settings {
  allow read, write: if request.auth.uid == uid;
}
```

Users can only access their own invoice settings.

## API Reference

### Cloud Functions

#### `generateNextInvoiceNumber()`
- **Type**: Callable
- **Auth**: Required
- **Params**: None
- **Returns**: `{ invoiceNumber: string, number: int, nextNumber: int }`
- **Behavior**: Transactional increment with auto-reset support

#### `getInvoiceSettings()`
- **Type**: Callable
- **Auth**: Required
- **Params**: None
- **Returns**: `{ settings: { prefix, nextNumber, resetRule, lastReset } }`
- **Behavior**: Read-only, no modifications

#### `updateInvoiceSettings()`
- **Type**: Callable
- **Auth**: Required
- **Params**: `{ prefix?, resetRule?, nextNumber? }`
- **Returns**: `{ success: bool, message: string }`
- **Behavior**: Update one or more settings fields

## Implementation Checklist

- ✅ BrandingProvider with invoice numbering state
- ✅ Cloud Functions (v1: billing/generateNextInvoiceNumber.ts, v2: invoice/generateNextInvoiceNumber.ts)
- ✅ InvoiceService wrapper for Cloud Function calls
- ✅ InvoiceSettingsScreen UI for configuration
- ✅ Routes registered (`/settings/invoice-settings`)
- ✅ Firestore schema documented
- ✅ Transaction safety implemented

## Troubleshooting

| Issue | Cause | Solution |
|-------|-------|----------|
| Number not incrementing | Using `getNextInvoiceNumber()` | Use `generateNextInvoiceNumber()` |
| Wrong format | Reset rule mismatch | Check reset rule in settings |
| Same number twice | Client-side generation | Use Cloud Function (atomic) |
| Reset not working | `lastReset` not set | Initialize via Cloud Function |
