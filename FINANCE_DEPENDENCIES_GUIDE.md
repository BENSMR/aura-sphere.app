# Finance Dependencies & Integration Guide

## Finance-Related Flutter Dependencies

All required dependencies for the finance module are already installed and verified.

### Core Finance Dependencies

| Dependency | Version | Purpose | Status |
|------------|---------|---------|--------|
| `firebase_functions` | ^5.0.4 | Call Cloud Functions (currency conversion, tax calculation) | ✅ Installed |
| `cloud_firestore` | ^5.6.0 | Access FX rates & tax matrix from Firestore | ✅ Installed |
| `firebase_auth` | ^5.3.0 | User authentication for function calls | ✅ Installed |
| `shared_preferences` | ^2.1.1 | Cache user finance settings | ✅ Installed |
| `intl` | ^0.19.0 | Format currencies & numbers | ✅ Installed |

### Supporting Dependencies

| Dependency | Version | Purpose | Status |
|------------|---------|---------|--------|
| `firebase_core` | ^3.6.0 | Firebase initialization | ✅ Installed |
| `firebase_storage` | ^12.4.10 | Receipt images (expenses) | ✅ Installed |
| `provider` | ^6.0.0 | State management for finance data | ✅ Installed |
| `http` | ^1.1.2 | HTTP requests if needed | ✅ Installed |
| `uuid` | ^4.0.0 | Generate unique IDs for transactions | ✅ Installed |
| `fl_chart` | ^0.66.0 | Financial charts & graphs | ✅ Installed |

## Finance Service Integration

### 1. Initialize Finance Services

In your main.dart or app initialization:

```dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

// Access Cloud Functions
final functions = FirebaseFunctions.instance;
final firestore = FirebaseFirestore.instance;
final auth = FirebaseAuth.instance;
```

### 2. Currency Conversion Example

```dart
// Call convertCurrency function
final result = await FirebaseFunctions.instance
    .httpsCallable('convertCurrency')
    .call({
      'amount': 100.0,
      'from': 'USD',
      'to': 'EUR'
    });

final converted = result.data['converted']; // 92.0
final rate = result.data['rate']; // 0.92
```

### 3. Tax Calculation Example

```dart
// Call calculateTax function
final result = await FirebaseFunctions.instance
    .httpsCallable('calculateTax')
    .call({
      'country': 'FR',
      'amount': 100.0,
      'taxType': 'vat',
      'customerIsBusiness': false
    });

final tax = result.data['tax']; // 20.0
final total = result.data['total']; // 120.0
```

### 4. Read FX Rates Directly (Optional)

```dart
// For performance, you can read cached rates directly
final doc = await FirebaseFirestore.instance
    .doc('config/fx_rates')
    .get();

final rates = doc.data()?['rates'] as Map<String, dynamic>;
final eurRate = rates['EUR']; // 0.92
```

### 5. Read Tax Rules (Optional)

```dart
// Get tax rules for a specific country
final doc = await FirebaseFirestore.instance
    .doc('config/tax_matrix/FR')
    .get();

final taxData = doc.data();
final standardVat = taxData?['vat']['standard']; // 0.20
```

## Finance Provider Example

Here's an example provider for managing finance operations:

```dart
import 'package:flutter/foundation.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FinanceProvider extends ChangeNotifier {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  bool _isLoading = false;
  String? _error;

  bool get isLoading => _isLoading;
  String? get error => _error;

  // Convert currency
  Future<Map<String, dynamic>?> convertCurrency({
    required double amount,
    required String from,
    required String to,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _functions
          .httpsCallable('convertCurrency')
          .call({
            'amount': amount,
            'from': from,
            'to': to,
          });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      _error = 'Currency conversion failed: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Calculate tax
  Future<Map<String, dynamic>?> calculateTax({
    required String country,
    required double amount,
    String taxType = 'vat',
    bool customerIsBusiness = false,
  }) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final result = await _functions
          .httpsCallable('calculateTax')
          .call({
            'country': country,
            'amount': amount,
            'taxType': taxType,
            'customerIsBusiness': customerIsBusiness,
          });

      return result.data as Map<String, dynamic>;
    } catch (e) {
      _error = 'Tax calculation failed: ${e.toString()}';
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get FX rates
  Future<Map<String, double>?> getFxRates() async {
    try {
      final doc = await _firestore.doc('config/fx_rates').get();
      return (doc.data()?['rates'] as Map<String, dynamic>?)
          ?.cast<String, double>();
    } catch (e) {
      _error = 'Failed to fetch FX rates: ${e.toString()}';
      return null;
    }
  }

  // Get tax rule for country
  Future<Map<String, dynamic>?> getTaxRule(String country) async {
    try {
      final doc = await _firestore.doc('config/tax_matrix/$country').get();
      return doc.data() as Map<String, dynamic>?;
    } catch (e) {
      _error = 'Failed to fetch tax rule: ${e.toString()}';
      return null;
    }
  }
}
```

## Usage in Screens

### In a Provider Consumer

```dart
Consumer<FinanceProvider>(
  builder: (context, financeProvider, child) {
    return Column(
      children: [
        if (financeProvider.isLoading)
          CircularProgressIndicator()
        else if (financeProvider.error != null)
          Text('Error: ${financeProvider.error}')
        else
          Text('Finance data loaded'),
      ],
    );
  },
)
```

### Direct Call (without Provider)

```dart
final financeProvider = Provider.of<FinanceProvider>(context, listen: false);
final result = await financeProvider.convertCurrency(
  amount: 100,
  from: 'USD',
  to: 'EUR',
);
```

## Configuration Checklist

Before using finance functions:

- [ ] Deploy Cloud Functions: `firebase deploy --only functions:syncFxRates,functions:convertCurrency,functions:calculateTax,functions:seedTaxMatrix`
- [ ] Seed FX rates: Follow [FX_RATES_SEED_GUIDE.md](./FX_RATES_SEED_GUIDE.md)
- [ ] Seed tax matrix: Follow [TAX_MATRIX_SEED_GUIDE.md](./TAX_MATRIX_SEED_GUIDE.md)
- [ ] Update Firestore rules: ✅ Already deployed
- [ ] Add FinanceProvider to app's provider list
- [ ] Test currency conversion in emulator
- [ ] Test tax calculation in emulator
- [ ] Deploy to production

## Error Handling

All functions return `data['success']` boolean:

```dart
// Always check success flag
final result = await functions.httpsCallable('convertCurrency').call({...});
if (result.data['success'] == true) {
  final converted = result.data['converted'];
  // Use converted value
} else {
  // Handle error from result.data['note'] or result.data['error']
}
```

## Testing

### Test Currency Conversion
```bash
curl -X POST \
  https://us-central1-aurasphere-pro.cloudfunctions.net/convertCurrency \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{"data":{"amount":100,"from":"USD","to":"EUR"}}'
```

### Test Tax Calculation
```bash
curl -X POST \
  https://us-central1-aurasphere-pro.cloudfunctions.net/calculateTax \
  -H "Content-Type: application/json" \
  -H "Authorization: Bearer YOUR_ID_TOKEN" \
  -d '{"data":{"country":"FR","amount":100,"taxType":"vat"}}'
```

## Performance Tips

1. **Cache FX rates locally** - Read `config/fx_rates` once and cache for 1-2 hours
2. **Cache tax rules** - Fetch country rules once per session
3. **Batch conversions** - Call `convertCurrency` once for multiple amounts if possible
4. **Use Firestore offline** - Read from cache if network unavailable

## Troubleshooting

### Function not found error
- Ensure deployment completed: `firebase deploy --only functions`
- Check Cloud Functions console for errors

### Authentication error
- Ensure user is logged in: `FirebaseAuth.instance.currentUser != null`
- Check Firestore rules allow authenticated users to read config documents

### FX rates not available
- Seed `config/fx_rates`: See [FX_RATES_SEED_GUIDE.md](./FX_RATES_SEED_GUIDE.md)
- Verify `syncFxRates` runs daily

### Tax rules not found
- Seed `config/tax_matrix`: See [TAX_MATRIX_SEED_GUIDE.md](./TAX_MATRIX_SEED_GUIDE.md)
- Verify country code format (ISO 2-letter code)

## Summary

✅ All finance dependencies installed  
✅ Cloud Functions deployed  
✅ Firestore rules updated  
✅ FX rates ready to seed  
✅ Tax matrix ready to seed  

Your Flutter app is ready to integrate currency conversion and tax calculations! 💰

---

**Related Files:**
- [FX_RATES_SEED_GUIDE.md](./FX_RATES_SEED_GUIDE.md) - FX rates seeding
- [TAX_MATRIX_SEED_GUIDE.md](./TAX_MATRIX_SEED_GUIDE.md) - Tax rules seeding
- [functions/src/finance/](./functions/src/finance/) - Cloud Functions source
