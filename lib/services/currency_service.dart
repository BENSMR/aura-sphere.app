import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Service for currency conversion and FX rate management
/// 
/// Supports:
/// - Reading cached FX rates from Firestore
/// - Converting amounts via Cloud Functions
/// - Offline conversion using cached rates
/// - User default currency preferences
class CurrencyService {
  static const String FX_DOC = 'config/fx_rates';
  static const String DEFAULT_CURRENCY_KEY = 'default_currency';

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instanceFor(
    app: Firebase.app(),
    region: 'us-central1',
  );

  /// Fetches cached exchange rates from Firestore
  /// Returns the complete FX rates document with all currencies
  /// 
  /// Returns: {
  ///   "base": "USD",
  ///   "provider": "exchangerate.host",
  ///   "rates": { "EUR": 0.92, "GBP": 0.79, ... },
  ///   "updatedAt": <timestamp>,
  ///   "fetchedAt": "<ISO8601>"
  /// }
  Future<Map<String, dynamic>?> getCachedRates() async {
    try {
      final snap = await _firestore.doc(FX_DOC).get();
      if (!snap.exists) {
        return null;
      }
      return snap.data();
    } catch (e) {
      print('❌ Error fetching cached FX rates: $e');
      return null;
    }
  }

  /// Converts an amount from one currency to another using Cloud Function
  /// This is the authoritative method and requires network connection
  /// 
  /// Parameters:
  ///   - amount: Amount to convert (must be positive)
  ///   - from: Source currency code (e.g., "USD")
  ///   - to: Target currency code (e.g., "EUR")
  /// 
  /// Returns: {
  ///   "success": true,
  ///   "converted": 92.0,
  ///   "rate": 0.92
  /// }
  Future<Map<String, dynamic>> convertAmount({
    required double amount,
    required String from,
    required String to,
  }) async {
    try {
      final callable = _functions.httpsCallable('convertCurrency');
      final response = await callable.call({
        'amount': amount,
        'from': from.toUpperCase(),
        'to': to.toUpperCase(),
      });

      final data = Map<String, dynamic>.from(response.data as Map);
      return data;
    } catch (e) {
      print('❌ Error converting currency: $e');
      rethrow;
    }
  }

  /// Converts using cached rates (offline-friendly)
  /// This is faster but less accurate than cloud function
  /// Returns null if rates are unavailable
  /// 
  /// Parameters:
  ///   - amount: Amount to convert
  ///   - from: Source currency
  ///   - to: Target currency
  ///   - fxDoc: Optional cached FX document (if null, fetches from Firestore)
  /// 
  /// Returns: Converted amount or null if rates unavailable
  Future<double?> localConvert({
    required double amount,
    required String from,
    required String to,
    Map<String, dynamic>? fxDoc,
  }) async {
    try {
      // If rates not provided, fetch them
      final rates = fxDoc ?? await getCachedRates();
      if (rates == null) {
        return null;
      }

      // Same currency, no conversion needed
      if (from.toUpperCase() == to.toUpperCase()) {
        return amount;
      }

      final base = rates['base'] as String? ?? 'USD';
      final ratesMap =
          Map<String, dynamic>.from(rates['rates'] as Map? ?? {});

      // Get rates for both currencies
      final rateFrom = from.toUpperCase() == base
          ? 1.0
          : _toDouble(ratesMap[from.toUpperCase()]);
      final rateTo = to.toUpperCase() == base
          ? 1.0
          : _toDouble(ratesMap[to.toUpperCase()]);

      // If either rate is missing, can't convert
      if (rateFrom == null || rateTo == null) {
        return null;
      }

      // Convert: amount -> base -> target
      final amountInBase =
          from.toUpperCase() == base ? amount : (amount / rateFrom);
      final converted = amountInBase * rateTo;

      return double.parse(converted.toStringAsFixed(6));
    } catch (e) {
      print('❌ Error in local conversion: $e');
      return null;
    }
  }

  /// Helper to safely convert dynamic to double
  static double? _toDouble(dynamic value) {
    if (value == null) return null;
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value);
    return null;
  }

  /// Sets user's default currency preference
  Future<void> setDefaultCurrency(String currencyCode) async {
    try {
      final sp = await SharedPreferences.getInstance();
      await sp.setString(DEFAULT_CURRENCY_KEY, currencyCode.toUpperCase());
    } catch (e) {
      print('❌ Error saving default currency: $e');
    }
  }

  /// Gets user's default currency preference
  /// Returns null if not set
  Future<String?> getDefaultCurrency() async {
    try {
      final sp = await SharedPreferences.getInstance();
      return sp.getString(DEFAULT_CURRENCY_KEY);
    } catch (e) {
      print('❌ Error reading default currency: $e');
      return null;
    }
  }

  /// Gets available currencies from cached rates
  /// Useful for currency selector dropdowns
  Future<List<String>> getAvailableCurrencies() async {
    try {
      final rates = await getCachedRates();
      if (rates == null) return [];

      final ratesMap = rates['rates'] as Map<String, dynamic>? ?? {};
      return ratesMap.keys.toList()..sort();
    } catch (e) {
      print('❌ Error fetching available currencies: $e');
      return [];
    }
  }

  /// Gets exchange rate between two currencies (not the converted amount)
  /// Useful for displaying "1 USD = X EUR" information
  Future<double?> getExchangeRate({
    required String from,
    required String to,
  }) async {
    try {
      final result = await convertAmount(
        amount: 1.0,
        from: from,
        to: to,
      );

      if (result['success'] == true) {
        return result['converted'] as double?;
      }
      return null;
    } catch (e) {
      print('❌ Error fetching exchange rate: $e');
      return null;
    }
  }

  /// Formats a number as currency with proper symbol and locale
  /// Uses intl package for formatting
  static String formatCurrency(
    double amount,
    String currencyCode, {
    String locale = 'en_US',
  }) {
    try {
      // Simple format: could use intl.NumberFormat for more control
      final symbol = _getCurrencySymbol(currencyCode);
      return '$symbol${amount.toStringAsFixed(2)}';
    } catch (e) {
      return '$amount $currencyCode';
    }
  }

  /// Helper to get currency symbol
  static String _getCurrencySymbol(String currencyCode) {
    const symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'CHF': 'CHF',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'NZD': 'NZ\$',
      'CNY': '¥',
      'INR': '₹',
      'SEK': 'kr',
      'NOK': 'kr',
      'DKK': 'kr',
      'MXN': '\$',
      'BRL': 'R\$',
      'ZAR': 'R',
      'SGD': 'S\$',
      'HKD': 'HK\$',
      'AED': 'د.إ',
    };

    return symbols[currencyCode.toUpperCase()] ?? currencyCode;
  }
}
