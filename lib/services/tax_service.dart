import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';

/// Service for tax calculations and tax rule management
/// 
/// Supports:
/// - Calculating VAT and sales tax by country (via Cloud Functions)
/// - EU reverse charge rules (B2B)
/// - Reading tax rules from Firestore
/// - Multi-country tax compliance
/// - Currency conversion with daily exchange rates
/// - Intelligent tax determination based on company/contact
/// - Real-time tax status monitoring via queuing system
class TaxService {
  static const String TAX_MATRIX_PATH = 'config/tax_matrix';
  static const String FX_RATES_PATH = 'config/fx_rates';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    app: Firebase.app(),
    region: 'us-central1',
  );

  /// Determine tax and currency intelligently based on company/contact
  ///
  /// This method integrates with the finance module to:
  /// 1. Load company (seller) to get default country & currency
  /// 2. Load contact (buyer) to get country & type (B2B/B2C)
  /// 3. Determine applicable tax based on both locations
  /// 4. Handle EU B2B reverse charge (if applicable)
  /// 5. Convert currencies if needed
  ///
  /// Parameters:
  ///   - amount: Base amount before tax
  ///   - fromCurrency: Original currency (e.g., 'EUR')
  ///   - companyId: Seller/organization ID (Firestore lookup)
  ///   - contactId: Buyer/recipient ID (Firestore lookup)
  ///   - country: Optional override country code
  ///   - direction: 'sale' (invoice) or 'purchase' (expense/PO)
  ///   - customerIsBusiness: Whether buyer is a business (B2B)
  ///
  /// Returns:
  ///   {
  ///     'success': true,
  ///     'amount': 1000.0,
  ///     'fromCurrency': 'EUR',
  ///     'country': 'FR',
  ///     'currency': 'EUR',
  ///     'taxRate': 0.20,
  ///     'taxAmount': 200.0,
  ///     'total': 1200.0,
  ///     'taxBreakdown': {
  ///       'type': 'vat',
  ///       'rate': 0.20,
  ///       'standard': true,
  ///       'country': 'FR',
  ///       'reverseCharge': false,
  ///       'appliedLogic': 'Standard French VAT'
  ///     },
  ///     'conversionHint': null,
  ///     'note': 'Tax calculated by server'
  ///   }
  Future<Map<String, dynamic>> determineTaxAndCurrency({
    required double amount,
    String? fromCurrency,
    String? companyId,
    String? contactId,
    String? country,
    String direction = 'sale',
    bool customerIsBusiness = false,
  }) async {
    try {
      final callable = _functions.httpsCallable('determineTaxAndCurrency');
      final response = await callable.call({
        'amount': amount,
        'fromCurrency': fromCurrency,
        'companyId': companyId,
        'contactId': contactId,
        'country': country,
        'direction': direction,
        'customerIsBusiness': customerIsBusiness,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      return data;
    } catch (e) {
      print('❌ Error determining tax: $e');
      rethrow;
    }
  }

  /// Convert between currencies using daily exchange rates
  ///
  /// Parameters:
  ///   - amount: Amount to convert
  ///   - from: Source currency (e.g., 'EUR')
  ///   - to: Target currency (e.g., 'USD')
  ///
  /// Returns:
  ///   {
  ///     'success': true,
  ///     'amount': 1000.0,
  ///     'converted': 1080.0,
  ///     'rate': 1.08,
  ///     'from': 'EUR',
  ///     'to': 'USD',
  ///     'timestamp': '2025-12-10T14:30:00Z'
  ///   }
  Future<Map<String, dynamic>> convertCurrency({
    required double amount,
    required String from,
    required String to,
  }) async {
    try {
      final callable = _functions.httpsCallable('convertCurrency');
      final response = await callable.call({
        'amount': amount,
        'from': from,
        'to': to,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      return data;
    } catch (e) {
      print('❌ Error converting currency: $e');
      rethrow;
    }
  }

  /// Calculates tax for an amount in a specific country
  /// Supports VAT (Europe) and sales tax (US, etc.)
  /// 
  /// Parameters:
  ///   - country: ISO country code (e.g., "FR", "DE", "US")
  ///   - amount: Base amount before tax
  ///   - customerIsBusiness: true for B2B (enables reverse charge)
  ///   - direction: "sale" (invoice) or "purchase" (expense)
  ///   - vatOverride: Optional manual override for VAT rate
  /// 
  /// Returns: {
  ///   "success": true,
  ///   "tax": 20.0,           // Calculated tax amount
  ///   "total": 120.0,        // Amount + tax
  ///   "rate": 0.20,          // Applied tax rate
  ///   "note": "..."          // Optional explanation
  /// }
  Future<Map<String, dynamic>> calculateTax({
    required double amount,
    required String country,
    bool customerIsBusiness = false,
    String direction = 'sale',
    double? vatOverride,
  }) async {
    try {
      final callable = _functions.httpsCallable('calculateTax');
      final response = await callable.call({
        'country': country.toUpperCase(),
        'amount': amount,
        'direction': direction,
        'customerIsBusiness': customerIsBusiness,
        if (vatOverride != null) 'vatRate': vatOverride,
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      return data;
    } catch (e) {
      print('❌ Error calculating tax: $e');
      rethrow;
    }
  }

  /// Fetches tax rules for a specific country
  /// 
  /// Returns: {
  ///   "country": "FR",
  ///   "region": "EU",
  ///   "vat": {
  ///     "standard": 0.20,
  ///     "reduced": [0.10, 0.055],
  ///     "isEu": true,
  ///     "has_vat": true
  ///   },
  ///   "sales_tax": null
  /// }
  Future<Map<String, dynamic>?> getTaxRule(String country) async {
    try {
      final doc = await _firestore
          .doc('$TAX_MATRIX_PATH/${country.toUpperCase()}')
          .get();

      if (!doc.exists) {
        return null;
      }

      return doc.data();
    } catch (e) {
      print('❌ Error fetching tax rule for $country: $e');
      return null;
    }
  }

  /// Gets standard VAT rate for a country
  /// Returns null if country not found or doesn't use VAT
  Future<double?> getStandardVatRate(String country) async {
    try {
      final rule = await getTaxRule(country);
      if (rule == null) return null;

      final vat = rule['vat'] as Map<String, dynamic>?;
      if (vat == null) return null;

      return _toDouble(vat['standard']);
    } catch (e) {
      print('❌ Error getting VAT rate: $e');
      return null;
    }
  }

  /// Gets all reduced VAT rates for a country
  /// Returns empty list if country doesn't have reduced rates
  Future<List<double>> getReducedVatRates(String country) async {
    try {
      final rule = await getTaxRule(country);
      if (rule == null) return [];

      final vat = rule['vat'] as Map<String, dynamic>?;
      if (vat == null) return [];

      final reduced = vat['reduced'] as List?;
      if (reduced == null) return [];

      return reduced
          .map((r) => _toDouble(r))
          .whereType<double>()
          .toList();
    } catch (e) {
      print('❌ Error getting reduced VAT rates: $e');
      return [];
    }
  }

  /// Checks if country is in EU (for reverse charge rules)
  Future<bool> isEuCountry(String country) async {
    try {
      final rule = await getTaxRule(country);
      if (rule == null) return false;

      final vat = rule['vat'] as Map<String, dynamic>?;
      if (vat == null) return false;

      return vat['isEu'] as bool? ?? false;
    } catch (e) {
      print('❌ Error checking if EU country: $e');
      return false;
    }
  }

  /// Checks if country uses VAT system
  Future<bool> usesVat(String country) async {
    try {
      final rule = await getTaxRule(country);
      if (rule == null) return false;

      final vat = rule['vat'] as Map<String, dynamic>?;
      if (vat == null) return false;

      return vat['has_vat'] as bool? ?? false;
    } catch (e) {
      print('❌ Error checking VAT system: $e');
      return false;
    }
  }

  /// Gets all available countries with tax rules
  /// Useful for country selector dropdowns
  Future<List<String>> getAvailableCountries() async {
    try {
      final collection = await _firestore
          .collection(TAX_MATRIX_PATH)
          .limit(100)
          .get();

      final countries = collection.docs
          .map((doc) => (doc.data()['country'] as String?) ?? doc.id)
          .toList();

      countries.sort();
      return countries;
    } catch (e) {
      print('❌ Error fetching available countries: $e');
      return [];
    }
  }

  /// Calculates total price including tax
  /// Convenience method combining tax calculation
  /// 
  /// Returns: {
  ///   "baseAmount": 100.0,
  ///   "taxAmount": 20.0,
  ///   "totalAmount": 120.0,
  ///   "taxRate": 0.20
  /// }
  Future<Map<String, double>?> calculateTotalWithTax({
    required String country,
    required double baseAmount,
    bool customerIsBusiness = false,
  }) async {
    try {
      final result = await calculateTax(
        country: country,
        amount: baseAmount,
        customerIsBusiness: customerIsBusiness,
      );

      if (result['success'] != true) {
        return null;
      }

      return {
        'baseAmount': baseAmount,
        'taxAmount': result['tax'] as double? ?? 0.0,
        'totalAmount': result['total'] as double? ?? baseAmount,
        'taxRate': result['rate'] as double? ?? 0.0,
      };
    } catch (e) {
      print('❌ Error calculating total with tax: $e');
      return null;
    }
  }

  /// Get cached exchange rates from Firestore (config/fx_rates)
  /// 
  /// Returns: {
  ///   'EUR': 1.0,
  ///   'USD': 1.08,
  ///   'GBP': 0.86,
  ///   'CHF': 0.95,
  ///   'JPY': 162.0,
  ///   ...
  /// }
  /// 
  /// Throws if config/fx_rates document doesn't exist
  Future<Map<String, dynamic>> getCachedExchangeRates() async {
    try {
      final doc = await _firestore
          .collection('config')
          .doc('fx_rates')
          .get();

      if (!doc.exists) {
        throw Exception('Exchange rates not yet cached. Run syncFxRates first.');
      }

      return Map<String, dynamic>.from(doc.data() ?? {});
    } catch (e) {
      print('❌ Error getting cached exchange rates: $e');
      rethrow;
    }
  }

  /// Watch exchange rates in real-time from Firestore
  /// 
  /// Emits updates whenever exchange rates change (daily refresh)
  /// 
  /// Usage:
  ///   taxService.watchExchangeRates().listen((rates) {
  ///     print('Rates updated: $rates');
  ///   });
  Stream<Map<String, dynamic>> watchExchangeRates() {
    return _firestore
        .collection('config')
        .doc('fx_rates')
        .snapshots()
        .map((snapshot) => snapshot.data() ?? {});
  }

  /// Get tax matrix (rules) for a specific country from cache
  /// 
  /// Returns: {
  ///   'country': 'FR',
  ///   'type': 'vat',
  ///   'standardRate': 0.20,
  ///   'reducedRates': [0.055, 0.10],
  ///   'reverseChargeEligible': true,
  ///   'eu': true,
  ///   'lastUpdated': '2025-12-10'
  /// }
  Future<Map<String, dynamic>?> getTaxMatrixData(String country) async {
    try {
      final doc = await _firestore
          .collection('config')
          .doc('tax_matrix')
          .collection('countries')
          .doc(country.toUpperCase())
          .get();

      if (!doc.exists) {
        return null;
      }

      return Map<String, dynamic>.from(doc.data() ?? {});
    } catch (e) {
      print('❌ Error getting tax matrix for $country: $e');
      rethrow;
    }
  }

  /// Watch tax matrix (rules) for a specific country in real-time
  /// 
  /// Emits whenever tax rules change (e.g., government updates)
  /// 
  /// Usage:
  ///   taxService.watchTaxMatrix('FR').listen((rules) {
  ///     if (rules != null) print('Tax rules updated: $rules');
  ///   });
  Stream<Map<String, dynamic>?> watchTaxMatrix(String country) {
    return _firestore
        .collection('config')
        .doc('tax_matrix')
        .collection('countries')
        .doc(country.toUpperCase())
        .snapshots()
        .map((snapshot) => snapshot.exists 
            ? Map<String, dynamic>.from(snapshot.data() ?? {})
            : null);
  }

  /// Get all available tax matrices (all countries)
  /// 
  /// Returns: {
  ///   'FR': { 'standardRate': 0.20, ... },
  ///   'DE': { 'standardRate': 0.19, ... },
  ///   'IT': { 'standardRate': 0.22, ... },
  ///   ...
  /// }
  Future<Map<String, Map<String, dynamic>>> getAllTaxMatrices() async {
    try {
      final snapshot = await _firestore
          .collection('config')
          .doc('tax_matrix')
          .collection('countries')
          .get();

      final result = <String, Map<String, dynamic>>{};
      for (final doc in snapshot.docs) {
        result[doc.id] = Map<String, dynamic>.from(doc.data());
      }
      return result;
    } catch (e) {
      print('❌ Error getting all tax matrices: $e');
      rethrow;
    }
  }

  /// Watch invoice tax status from the tax queue in real-time
  /// 
  /// Monitors internal/tax_queue/requests for pending/completed calculations
  /// 
  /// Useful for showing: "Calculating tax..." or "Tax calculated: 20%"
  Stream<Map<String, dynamic>?> watchInvoiceTaxStatus({
    required String uid,
    required String invoiceId,
  }) {
    return _firestore
        .collection('internal')
        .doc('tax_queue')
        .collection('requests')
        .where('uid', isEqualTo: uid)
        .where('entityPath', isEqualTo: 'users/$uid/invoices/$invoiceId')
        .snapshots()
        .map((snapshot) {
          if (snapshot.docs.isEmpty) return null;
          return Map<String, dynamic>.from(snapshot.docs.first.data());
        });
  }

  /// Check if an invoice's tax calculation is currently pending
  /// 
  /// Returns true if there's an active queue request for this invoice
  Future<bool> isTaxCalculationPending({
    required String uid,
    required String invoiceId,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('internal')
          .doc('tax_queue')
          .collection('requests')
          .where('uid', isEqualTo: uid)
          .where('entityPath', isEqualTo: 'users/$uid/invoices/$invoiceId')
          .where('processed', isEqualTo: false)
          .limit(1)
          .get();

      return snapshot.docs.isNotEmpty;
    } catch (e) {
      print('❌ Error checking tax calculation status: $e');
      return false;
    }
  }

  /// Get detailed status of a tax queue request
  /// 
  /// Returns: {
  ///   'uid': 'user123',
  ///   'entityPath': 'users/user123/invoices/inv456',
  ///   'entityType': 'invoice',
  ///   'processed': false,
  ///   'attempts': 1,
  ///   'createdAt': '2025-12-10T14:00:00Z',
  ///   'processedAt': null,
  ///   'lastError': null,
  ///   'note': 'Queued for processing'
  /// }
  Future<Map<String, dynamic>?> getQueueRequestStatus({
    required String uid,
    required String queueRequestId,
  }) async {
    try {
      final doc = await _firestore
          .collection('internal')
          .doc('tax_queue')
          .collection('requests')
          .doc(queueRequestId)
          .get();

      if (!doc.exists || doc.data()?['uid'] != uid) {
        return null;
      }

      return Map<String, dynamic>.from(doc.data() ?? {});
    } catch (e) {
      print('❌ Error getting queue request status: $e');
      return null;
    }
  }

  /// Watch a specific tax queue request in real-time
  /// 
  /// Usage:
  ///   taxService.watchQueueRequestStatus(
  ///     uid: 'user123',
  ///     queueRequestId: 'queue456'
  ///   ).listen((status) {
  ///     if (status?['processed'] == true) {
  ///       print('Tax calculation complete!');
  ///     }
  ///   });
  Stream<Map<String, dynamic>?> watchQueueRequestStatus({
    required String uid,
    required String queueRequestId,
  }) {
    return _firestore
        .collection('internal')
        .doc('tax_queue')
        .collection('requests')
        .doc(queueRequestId)
        .snapshots()
        .where((snapshot) => snapshot.exists && snapshot.data()?['uid'] == uid)
        .map((snapshot) => Map<String, dynamic>.from(snapshot.data() ?? {}));
  }

  /// Retry a failed tax calculation by creating a new queue request
  /// 
  /// Called when a previous tax calculation failed and needs to be retried
  /// 
  /// Parameters:
  ///   - uid: Current user ID
  ///   - invoiceId: Invoice that failed tax calculation
  ///   - previousQueueRequestId: The failed queue request (for audit)
  ///
  /// Returns the new queue request ID
  Future<String?> retryFailedTaxCalculation({
    required String uid,
    required String invoiceId,
    String? previousQueueRequestId,
  }) async {
    try {
      final callable = _functions.httpsCallable('retryFailedTaxCalculation');
      final response = await callable.call({
        'uid': uid,
        'invoiceId': invoiceId,
        'previousQueueRequestId': previousQueueRequestId,
      });

      final data = response.data as Map?;
      return data?['queueRequestId'] as String?;
    } catch (e) {
      print('❌ Error retrying failed tax calculation: $e');
      return null;
    }
  }

  /// Get list of all supported countries with their tax information
  /// Useful for populating country selectors
  /// 
  /// Returns: ['FR', 'DE', 'IT', 'ES', 'GB', 'US', 'CA', 'AU', 'JP', ...]
  Future<List<String>> getSupportedCountries() async {
    try {
      final matrices = await getAllTaxMatrices();
      return matrices.keys.toList()..sort();
    } catch (e) {
      print('❌ Error getting supported countries: $e');
      return [];
    }
  }

  /// Format tax breakdown details for display
  /// 
  /// Input:
  ///   {
  ///     'type': 'vat',
  ///     'rate': 0.20,
  ///     'standard': true,
  ///     'country': 'FR',
  ///     'reverseCharge': false,
  ///     'appliedLogic': 'Standard French VAT'
  ///   }
  /// 
  /// Output: "VAT 20% (FR) - Standard French VAT"
  static String formatTaxBreakdown(Map<String, dynamic>? breakdown) {
    if (breakdown == null) return 'No tax information';

    final type = (breakdown['type'] as String?)?.toUpperCase() ?? 'TAX';
    final rate = breakdown['rate'] as double? ?? 0.0;
    final country = breakdown['country'] as String? ?? '';
    final logic = breakdown['appliedLogic'] as String? ?? '';

    final parts = [
      '$type ${formatTaxRate(rate)}',
      if (country.isNotEmpty) '($country)',
      if (logic.isNotEmpty) '- $logic',
    ];

    return parts.join(' ');
  }

  /// Format currency amount for display
  /// 
  /// Example: formatCurrency(1234.56, 'EUR') -> "€1,234.56"
  static String formatCurrency(double amount, String currency) {
    final currencySymbols = {
      'EUR': '€',
      'USD': '\$',
      'GBP': '£',
      'JPY': '¥',
      'CHF': 'CHF',
      'CAD': '\$',
      'AUD': '\$',
      'INR': '₹',
    };

    final symbol = currencySymbols[currency] ?? currency;
    final formatted = amount.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'\B(?=(\d{3})+(?!\d))'),
          (match) => ',',
        );

    return '$symbol$formatted';
  }

  /// Helper to safely convert dynamic to double
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Formats tax rate as percentage string
  /// Example: 0.20 -> "20%"
  static String formatTaxRate(double rate) {
    return '${(rate * 100).toStringAsFixed(1)}%';
  }

  /// Gets readable description of tax for UI display
  /// Example: "VAT (20%)" or "EU Reverse Charge"
  static String getTaxDescription(
    Map<String, dynamic> result, {
    String country = '',
  }) {
    if (result['note'] != null) {
      return result['note'] as String;
    }

    final rate = result['rate'] as double? ?? 0.0;
    if (rate == 0.0) {
      return 'No tax applicable';
    }

    return '${formatTaxRate(rate)} tax';
  }
}
