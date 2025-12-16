/// Input Validation & Sanitization Service
/// Protects against common injection attacks and validates user input
class InputValidator {
  // Regex patterns for validation
  static const String emailPattern =
      r'^[a-zA-Z0-9.]+@[a-zA-Z0-9]+\.[a-zA-Z]+';
  
  static const String phonePattern = r'^\+?[0-9\s\-\(\)]{10,}$';
  
  static const String urlPattern =
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';

  /// Validate email address
  static bool isValidEmail(String? email) {
    if (email == null || email.isEmpty) return false;
    return RegExp(emailPattern).hasMatch(email.trim());
  }

  /// Validate phone number (international format)
  static bool isValidPhone(String? phone) {
    if (phone == null || phone.isEmpty) return false;
    return RegExp(phonePattern).hasMatch(phone.trim());
  }

  /// Validate URL
  static bool isValidUrl(String? url) {
    if (url == null || url.isEmpty) return false;
    return RegExp(urlPattern).hasMatch(url.trim());
  }

  /// Validate invoice number (alphanumeric, no special chars)
  static bool isValidInvoiceNumber(String? number) {
    if (number == null || number.isEmpty) return false;
    return RegExp(r'^[A-Z0-9\-]{3,20}$').hasMatch(number.trim().toUpperCase());
  }

  /// Validate amount (positive decimal)
  static bool isValidAmount(dynamic amount) {
    if (amount == null) return false;
    final num = double.tryParse(amount.toString());
    return num != null && num > 0;
  }

  /// Sanitize string input - removes dangerous characters
  static String sanitize(String? input) {
    if (input == null) return '';
    
    // Remove null bytes
    String sanitized = input.replaceAll('\x00', '');
    
    // Remove control characters except newlines
    sanitized = sanitized.replaceAll(RegExp(r'[\x00-\x08\x0B\x0C\x0E-\x1F]'), '');
    
    // Trim whitespace
    sanitized = sanitized.trim();
    
    return sanitized;
  }

  /// Escape SQL special characters (defense in depth)
  static String escapeSql(String input) {
    return input
        .replaceAll('\\', '\\\\')
        .replaceAll("'", "''")
        .replaceAll('"', '""')
        .replaceAll('\x00', '')
        .replaceAll('\n', '\\n')
        .replaceAll('\r', '\\r')
        .replaceAll('\x1a', '\\Z');
  }

  /// Validate and sanitize client input
  static String validateAndSanitize(String? input, {
    int maxLength = 500,
    bool allowNewlines = false,
  }) {
    if (input == null) return '';
    
    String sanitized = sanitize(input);
    
    if (!allowNewlines) {
      sanitized = sanitized.replaceAll('\n', ' ').replaceAll('\r', ' ');
    }
    
    if (sanitized.length > maxLength) {
      sanitized = sanitized.substring(0, maxLength);
    }
    
    return sanitized;
  }

  /// Validate form fields for invoice creation
  static Map<String, String> validateInvoiceForm({
    required String invoiceNumber,
    required String clientId,
    required String amount,
    required String description,
  }) {
    final errors = <String, String>{};

    if (!isValidInvoiceNumber(invoiceNumber)) {
      errors['invoiceNumber'] = 'Invalid invoice number format';
    }

    if (clientId.isEmpty || clientId.length > 100) {
      errors['clientId'] = 'Invalid client ID';
    }

    if (!isValidAmount(amount)) {
      errors['amount'] = 'Amount must be greater than 0';
    }

    if (description.isEmpty || description.length > 1000) {
      errors['description'] = 'Description required (max 1000 chars)';
    }

    return errors;
  }

  /// Validate form fields for expense creation
  static Map<String, String> validateExpenseForm({
    required String category,
    required String amount,
    required String description,
  }) {
    final errors = <String, String>{};

    final validCategories = [
      'Transport', 'Food', 'Health', 'Office', 'Other'
    ];
    
    if (!validCategories.contains(category)) {
      errors['category'] = 'Invalid category';
    }

    if (!isValidAmount(amount)) {
      errors['amount'] = 'Amount must be greater than 0';
    }

    if (description.isEmpty || description.length > 500) {
      errors['description'] = 'Description required (max 500 chars)';
    }

    return errors;
  }

  /// Check if input contains suspicious patterns
  static bool isSuspicious(String input) {
    final suspiciousPatterns = [
      RegExp(r'<script[^>]*>.*?</script>', caseSensitive: false), // XSS
      RegExp(r'javascript:', caseSensitive: false), // JS injection
      RegExp(r'on\w+\s*=', caseSensitive: false), // Event handlers
      RegExp(r'union\s+select', caseSensitive: false), // SQL injection
      RegExp(r'drop\s+(table|database)', caseSensitive: false), // SQL injection
      RegExp(r'exec\s*\(', caseSensitive: false), // Code execution
    ];

    for (final pattern in suspiciousPatterns) {
      if (pattern.hasMatch(input)) {
        return true;
      }
    }

    return false;
  }
}
