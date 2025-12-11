# Cloud Functions Integration Guide

## Overview

The `FunctionsService` provides a typed wrapper for all AuraSphere Pro Cloud Functions with error handling and authentication.

## Setup

### 1. Add Import

```dart
import 'package:aura_sphere_pro/services/functions_service.dart';
```

### 2. Instantiate Service

```dart
final functionsService = FunctionsService();
```

Or with dependency injection:

```dart
// In provider
final _functionsService = FunctionsService();

// In widget
final functionsService = Provider.of<YourProvider>(context).functionsService;
```

## Usage Examples

### CRM Functions

#### Update Single Client AI Score

```dart
final result = await functionsService.calculateClientAIScore(clientId);
// Returns: {success: bool, aiScore: int, churnRisk: int, aiTags: List<String>}
```

#### Recalculate All Client Scores

```dart
final result = await functionsService.recalculateAllClientScores();
// Returns: {success: bool, updated: int, failed: int, total: int}

print('Updated: ${result['updated']}, Failed: ${result['failed']}');
```

#### Generate Client AI Summary

```dart
final result = await functionsService.generateClientSummary(clientId);
// Returns: {success: bool, clientId: String, aiSummary: String}

final summary = result['aiSummary'] as String;
```

#### Regenerate All Summaries

```dart
final result = await functionsService.regenerateAllClientSummaries();
// Returns: {success: bool, generated: int, failed: int, total: int}
```

### Invoice Functions

#### Generate Invoice PDF

```dart
final result = await functionsService.generateInvoicePdf(
  invoiceId,
  includeWatermark: true,
);
// Returns: {success: bool, downloadUrl: String}

if (result['success'] == true) {
  final url = result['downloadUrl'] as String;
  // Download or open PDF
}
```

#### Send Invoice Email

```dart
final result = await functionsService.sendInvoiceEmail(
  invoiceId,
  'client@example.com',
  subject: 'Invoice #INV-001',
  message: 'Please find your invoice attached.',
);
// Returns: {success: bool, sent: bool, recipientEmail: String}
```

### AI Functions

#### Generate Email via OpenAI

```dart
final result = await functionsService.generateEmail(
  'Write a follow-up email to a client about an overdue invoice',
  maxTokens: 500,
);
// Returns: {success: bool, email: String}

final email = result['email'] as String;
```

### OCR Functions

#### Process Receipt Image

```dart
final result = await functionsService.processReceiptOCR(
  'receipts/user123/receipt456.jpg',
  hints: 'restaurant invoice',
);
// Returns: {success: bool, data: Map, extracted: bool}

final extractedData = result['data'] as Map<String, dynamic>;
```

### Billing Functions

#### Create Stripe Checkout

```dart
final result = await functionsService.createCheckoutSession(
  planId: 'plan_pro_monthly',
  couponCode: 'SAVE10',
  successUrl: 'https://yourapp.com/success',
  cancelUrl: 'https://yourapp.com/cancel',
);
// Returns: {success: bool, sessionId: String, clientSecret: String}
```

#### Audit Payment Event

```dart
final result = await functionsService.auditPaymentEvent(
  'invoice_paid',
  amount: '250.00',
  notes: 'Invoice #INV-001 paid via Stripe',
);
// Returns: {success: bool, auditId: String}
```

#### Get Payment Audit Trail

```dart
final result = await functionsService.getPaymentAuditTrail(limit: 50);
// Returns: {success: bool, records: List<Map>}

final records = result['records'] as List;
for (final record in records) {
  print('${record['eventType']}: €${record['amount']}');
}
```

### Token/Reward Functions

#### Reward User

```dart
final result = await functionsService.rewardUser(
  reason: 'invoice_paid',
  amount: 100,
  metadata: jsonEncode({'invoiceId': 'inv123'}),
);
// Returns: {success: bool, newBalance: int, transactionId: String}

print('New balance: ${result['newBalance']} tokens');
```

#### Verify Token Data

```dart
final result = await functionsService.verifyUserTokenData();
// Returns: {success: bool, valid: bool, balance: int}

if (result['valid'] == true) {
  print('Token balance: ${result['balance']} tokens');
} else {
  print('Token data integrity issue detected');
}
```

### Task Functions

#### Process Due Reminders

```dart
final result = await functionsService.processDueReminders();
// Returns: {success: bool, notified: int}

print('Notified ${result['notified']} users');
```

### Expense Functions

#### Process Approved Expense

```dart
final result = await functionsService.processExpenseApproved(expenseId);
// Returns: {success: bool, expenseId: String}
```

## Error Handling

All functions throw `Exception` on error. Use try/catch:

```dart
try {
  final result = await functionsService.generateClientSummary(clientId);
  print('Summary: ${result['aiSummary']}');
} on Exception catch (e) {
  print('Error: $e');
  // Show error snackbar to user
  ScaffoldMessenger.of(context).showSnackBar(
    SnackBar(content: Text('Error: $e')),
  );
}
```

## Generic Function Calling

For functions not listed above, use the generic `callFunction` method:

```dart
final result = await functionsService.callFunction<Map<String, dynamic>>(
  'myCustomFunction',
  parameters: {
    'param1': 'value1',
    'param2': 123,
  },
);
```

## Provider Integration

Create a provider for functions service:

```dart
import 'package:provider/provider.dart';

final functionsServiceProvider = Provider<FunctionsService>((ref) {
  return FunctionsService();
});
```

Use in widget:

```dart
Consumer<FunctionsService>(
  builder: (context, functionsService, _) {
    return ElevatedButton(
      onPressed: () async {
        try {
          final result = await functionsService.generateClientSummary(clientId);
          // Handle result
        } catch (e) {
          // Handle error
        }
      },
      child: const Text('Generate Summary'),
    );
  },
)
```

## Best Practices

### 1. Always Handle Errors

```dart
try {
  final result = await functionsService.calculateClientAIScore(clientId);
  // Use result
} catch (e) {
  // Show user-friendly error message
  _showError('Failed to calculate AI score');
}
```

### 2. Show Loading State

```dart
setState(() => _isLoading = true);
try {
  final result = await functionsService.recalculateAllClientScores();
} finally {
  setState(() => _isLoading = false);
}
```

### 3. Cache Results When Possible

```dart
// Store function results in local state to avoid repeated calls
final _aiScoreCache = <String, int>{};

Future<int> getAIScore(String clientId) async {
  if (_aiScoreCache.containsKey(clientId)) {
    return _aiScoreCache[clientId]!;
  }
  
  final result = await functionsService.calculateClientAIScore(clientId);
  _aiScoreCache[clientId] = result['aiScore'] as int;
  return _aiScoreCache[clientId]!;
}
```

### 4. Use Spinner/Loading Indicator

```dart
if (_isLoading) {
  return const Center(child: CircularProgressIndicator());
}

// Show result
```

### 5. Batch Operations Sparingly

Cloud Functions have execution limits. For bulk operations:

```dart
// Bad: Calls function for each client
for (final client in clients) {
  await functionsService.generateClientSummary(client.id);
}

// Good: Use batch function
final result = await functionsService.regenerateAllClientSummaries();
```

## Configuration

### Region

Default region: `us-central1`

To change:

```dart
final functionsService = FunctionsService(
  functions: CloudFunctions.instanceFor(region: 'europe-west1'),
);
```

### Timeout

Functions have default timeouts. For long-running operations, increase timeout in function configuration:

```typescript
// In Cloud Function
export const myFunction = functions
  .runWith({
    timeoutSeconds: 540, // 9 minutes
    memory: '512MB',
  })
  .https.onCall(...)
```

## Troubleshooting

### Function Not Found

```
FirebaseFunctionsException: Cloud Function not found
```

**Solution**: Ensure function is exported in `functions/src/index.ts`:

```typescript
export { myFunction } from './path/to/function';
```

### Authentication Error

```
FirebaseFunctionsException: Permission denied
```

**Solution**: Ensure user is authenticated and Firestore rules allow access.

### Timeout Error

```
FirebaseFunctionsException: Deadline exceeded
```

**Solution**: Function is taking too long. Check Cloud Function logs for details.

## Monitoring

Check Cloud Function logs:

```bash
gcloud functions logs read functionName --limit 50
```

Monitor in Firebase Console:
- Functions → Logs
- Firestore → Usage & Billing
- Cloud Functions → Monitoring

## Next Steps

- Integrate FunctionsService into providers for state management
- Add offline support with caching
- Implement retry logic for failed operations
- Monitor function performance and costs
