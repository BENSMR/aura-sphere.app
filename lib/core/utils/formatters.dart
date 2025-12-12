import 'package:intl/intl.dart';

/// Centralized formatting utility for currency, dates, numbers, and more
class Formatters {
  // ==================== CURRENCY ====================

  /// Format amount as currency with symbol (default: $)
  /// Example: formatCurrency(1234.5) → "$1,234.50"
  static String formatCurrency(double amount, {String symbol = '\$'}) {
    final formatted = NumberFormat('#,##0.00').format(amount);
    return '$symbol$formatted';
  }

  /// Format amount with symbol suffix (e.g., "1,234.50 USD")
  /// Example: formatAmountWithSymbol(1234.5, 'USD') → "1,234.50 USD"
  static String formatAmountWithSymbol(double amount, String currencyCode) {
    final formatted = NumberFormat('#,##0.00').format(amount);
    return '$formatted $currencyCode';
  }

  /// Legacy alias for currency (deprecated, use formatCurrency)
  static String currency(double amount, {String symbol = '\$'}) {
    return formatCurrency(amount, symbol: symbol);
  }

  // ==================== DATES ====================

  /// Format date as readable string (e.g., "Jan 15, 2025")
  /// Example: formatDate(DateTime(2025, 1, 15)) → "Jan 15, 2025"
  static String formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Format date and time (e.g., "Jan 15, 2025 2:30 PM")
  /// Example: formatDateTime(DateTime(2025, 1, 15, 14, 30)) → "Jan 15, 2025 2:30 PM"
  static String formatDateTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy h:mm a').format(dateTime);
  }

  /// Format as ISO date (YYYY-MM-DD)
  /// Example: formatDateISO(DateTime(2025, 1, 15)) → "2025-01-15"
  static String formatDateISO(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Format as time only (e.g., "2:30 PM")
  /// Example: formatTime(DateTime(2025, 1, 15, 14, 30)) → "2:30 PM"
  static String formatTime(DateTime dateTime) {
    return DateFormat('h:mm a').format(dateTime);
  }

  /// Legacy alias for dateTime (deprecated, use formatDateTime)
  static String date(DateTime date) {
    return formatDate(date);
  }

  /// Legacy alias for dateTime (deprecated, use formatDateTime)
  static String dateTime(DateTime dateTime) {
    return formatDateTime(dateTime);
  }

  // ==================== NUMBERS ====================

  /// Format integer with thousand separators
  /// Example: formatNumber(1234567) → "1,234,567"
  static String formatNumber(int number) {
    return NumberFormat('#,###').format(number);
  }

  /// Format decimal number with specified decimal places
  /// Example: formatDecimal(1234.5, 2) → "1,234.50"
  static String formatDecimal(double number, {int decimals = 2}) {
    final pattern = '#,##0.${'0' * decimals}';
    return NumberFormat(pattern).format(number);
  }

  // ==================== PERCENTAGES ====================

  /// Format as percentage (0.25 → "25.0%")
  /// Example: formatPercentage(0.25) → "25.0%"
  static String formatPercentage(double value, {int decimals = 1}) {
    final percent = value * 100;
    return '${percent.toStringAsFixed(decimals)}%';
  }

  /// Legacy alias (deprecated, use formatPercentage)
  static String percentage(double value) {
    return formatPercentage(value);
  }

  // ==================== INVOICE ====================

  /// Format invoice number with prefix and padded number
  /// Example: formatInvoiceNumber('INV-', 42) → "INV-0042"
  static String formatInvoiceNumber(String prefix, int number, {int padding = 4}) {
    final padded = number.toString().padLeft(padding, '0');
    return '$prefix$padded';
  }

  // ==================== PHONE ====================

  /// Format phone number (10-digit US format)
  /// Example: formatPhone('1234567890') → "(123) 456-7890"
  static String formatPhone(String phone) {
    if (phone.length == 10) {
      return '(${phone.substring(0, 3)}) ${phone.substring(3, 6)}-${phone.substring(6)}';
    }
    return phone;
  }

  /// Legacy alias (deprecated, use formatPhone)
  static String phone(String phone) {
    return formatPhone(phone);
  }

  // ==================== UTILITY HELPERS ====================

  /// Check if a value is a valid number
  static bool isValidNumber(String value) {
    return double.tryParse(value) != null;
  }

  /// Get currency symbol for a currency code
  static String getCurrencySymbol(String currencyCode) {
    final symbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'INR': '₹',
      'BRL': 'R\$',
      'CAD': 'C\$',
      'AUD': 'A\$',
      'CHF': 'CHF',
      'CNY': '¥',
      'SEK': 'kr',
      'NZD': 'NZ\$',
      'MXN': '\$',
      'SGD': 'S\$',
      'HKD': 'HK\$',
    };
    return symbols[currencyCode] ?? currencyCode;
  }
}
