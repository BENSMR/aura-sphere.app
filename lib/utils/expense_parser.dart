import 'dart:convert';

/// Parses OCR-extracted text into structured expense fields.
/// Handles merchant names, dates, amounts, VAT, currency, and categories.
class ExpenseParser {
  /// Parse OCR text into structured expense fields
  ///
  /// Returns a map with keys: merchant, date, total, vat, currency, category
  ///
  /// Example:
  ///   final result = ExpenseParser.parse("Acme Corp\n27.11.2025\nTotal: $50.00");
  ///   // { merchant: "Acme Corp", date: "27.11.2025", total: 50.0, ... }
  static Map<String, dynamic> parse(String text) {
    final lowerText = text.toLowerCase();

    return {
      "merchant": _extractMerchant(text),
      "date": _extractDate(text),
      "total": _extractTotal(lowerText),
      "vat": _extractVAT(lowerText),
      "currency": _extractCurrency(lowerText),
      "category": _guessCategory(lowerText),
    };
  }

  /// Extract merchant name (typically first non-numeric line)
  static String? _extractMerchant(String text) {
    final lines = text.split('\n').where((e) => e.trim().isNotEmpty).toList();
    if (lines.isEmpty) return null;

    // First non-number line is usually the merchant
    for (final line in lines) {
      final trimmed = line.trim();
      // Skip lines that are mostly numbers
      if (!RegExp(r'^[\d\s\.,$€¥£]+$').hasMatch(trimmed)) {
        return trimmed;
      }
    }
    return lines.first.trim();
  }

  /// Extract date in various formats
  /// Supports: DD/MM/YYYY, DD-MM-YYYY, YYYY-MM-DD, DD.MM.YYYY
  static String? _extractDate(String text) {
    final patterns = [
      r'(\d{2}[.\-/]\d{2}[.\-/]\d{4})',  // DD.MM.YYYY or DD-MM-YYYY or DD/MM/YYYY
      r'(\d{4}[.\-/]\d{2}[.\-/]\d{2})',  // YYYY-MM-DD
      r'(\d{1,2}\s+(?:jan|feb|mar|apr|may|jun|jul|aug|sep|oct|nov|dec)[a-z]*\s+\d{4})',  // 27 Nov 2025
    ];

    for (final pattern in patterns) {
      final match = RegExp(pattern).firstMatch(text);
      if (match != null) {
        return match.group(0);
      }
    }
    return null;
  }

  /// Extract total amount (looks for "total:", "subtotal:", amount field)
  static double? _extractTotal(String text) {
    // Try "total: $50.00" format
    var match = RegExp(r'total[:\s]+\$?([0-9]+[.,][0-9]{2}|[0-9]+)')
        .firstMatch(text);
    if (match != null) {
      return _parseAmount(match.group(1)!);
    }

    // Try "subtotal: $50.00" format
    match = RegExp(r'subtotal[:\s]+\$?([0-9]+[.,][0-9]{2}|[0-9]+)')
        .firstMatch(text);
    if (match != null) {
      return _parseAmount(match.group(1)!);
    }

    // Fallback: find the highest amount (typically the total)
    final amounts = RegExp(r'(\d+[.,]\d{2}|\d+)')
        .allMatches(text)
        .map((m) => _parseAmount(m.group(0)!))
        .whereType<double>()
        .toList();

    if (amounts.isEmpty) return null;
    amounts.sort();
    return amounts.last; // Return highest amount as likely total
  }

  /// Extract VAT/Tax amount
  /// Looks for "vat:", "tax:", "tva:", etc.
  static double? _extractVAT(String text) {
    final patterns = [
      r'(?:vat|tax|tva|tasse|moms|iva|tps|gst)[:\s]+\$?([0-9]+[.,][0-9]{2}|[0-9]+)',
    ];

    for (final pattern in patterns) {
      final match = RegExp(pattern).firstMatch(text);
      if (match != null) {
        return _parseAmount(match.group(1)!);
      }
    }
    return null;
  }

  /// Extract currency code (USD, EUR, GBP, etc.)
  static String _extractCurrency(String text) {
    // Currency symbols
    if (text.contains('\$')) return 'USD';
    if (text.contains('€')) return 'EUR';
    if (text.contains('£')) return 'GBP';
    if (text.contains('¥')) return 'JPY';
    if (text.contains('₹')) return 'INR';

    // Currency codes
    final currencyCodes = ['usd', 'eur', 'gbp', 'jpy', 'cad', 'aud', 'chf', 'inr'];
    for (final code in currencyCodes) {
      if (text.contains(code)) {
        return code.toUpperCase();
      }
    }

    // Default to USD
    return 'USD';
  }

  /// Guess expense category based on merchant name and keywords
  static String _guessCategory(String text) {
    final keywords = {
      'Supplies': ['amazon', 'staples', 'office depot', 'office supply'],
      'Food': ['restaurant', 'cafe', 'starbucks', 'pizza', 'burger', 'food', 'grocery'],
      'Transport': ['uber', 'lyft', 'taxi', 'gas', 'fuel', 'parking', 'transit'],
      'Utilities': ['electric', 'water', 'gas', 'internet', 'phone'],
      'Entertainment': ['cinema', 'movie', 'theater', 'concert', 'spotify', 'netflix'],
      'Travel': ['hotel', 'airbnb', 'airline', 'flight', 'booking'],
      'Health': ['pharmacy', 'doctor', 'hospital', 'clinic', 'health'],
      'Business': ['office', 'conference', 'meeting', 'business'],
    };

    for (final category in keywords.entries) {
      for (final keyword in category.value) {
        if (text.contains(keyword)) {
          return category.key;
        }
      }
    }

    return 'Other';
  }

  /// Parse amount string, handling both "." and "," as decimal separator
  static double? _parseAmount(String amount) {
    try {
      // Replace comma with period for decimal
      final normalized = amount.replaceAll(',', '.');
      return double.parse(normalized);
    } catch (_) {
      return null;
    }
  }

  /// Convert parsed map to JSON string
  static String toJson(Map<String, dynamic> parsed) {
    return jsonEncode(parsed);
  }

  /// Parse JSON string back to map
  static Map<String, dynamic> fromJson(String json) {
    try {
      return jsonDecode(json) as Map<String, dynamic>;
    } catch (_) {
      return {};
    }
  }
}
