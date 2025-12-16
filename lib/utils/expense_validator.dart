/// Validator class for expense data
/// 
/// Provides client-side validation for expense forms.
/// Server-side validation in Cloud Functions is REQUIRED - these checks
/// are for UX only and can be bypassed.
/// 
/// Amount limits: $0.01 - $100,000.00
/// Vendor: 2-100 characters
/// Items: 1-20 items, each 1-50 characters
/// Description: 0-500 characters (optional)
class ExpenseValidator {
  // Amount limits
  static const double amountMin = 0.01;
  static const double amountMax = 100000.0;

  // String limits
  static const int vendorMin = 2;
  static const int vendorMax = 100;
  static const int itemMin = 1;
  static const int itemMax = 50;
  static const int itemsLimit = 20;
  static const int descriptionMax = 500;

  // Valid categories
  static const List<String> validCategories = [
    'travel',
    'meals',
    'office_supplies',
    'equipment',
    'software',
    'marketing',
    'other',
  ];

  /// Validate expense amount
  /// 
  /// Rules:
  /// - Must be a number between $0.01 and $100,000.00
  /// - Maximum 2 decimal places
  static String? validateAmount(double amount) {
    if (amount < amountMin) {
      return 'Amount must be at least \$${amountMin.toStringAsFixed(2)}';
    }
    if (amount > amountMax) {
      return 'Amount cannot exceed \$${amountMax.toStringAsFixed(2)}';
    }

    // Check decimal places (max 2)
    final rounded = double.parse(amount.toStringAsFixed(2));
    if (amount != rounded) {
      return 'Amount can have at most 2 decimal places';
    }

    return null;
  }

  /// Validate vendor name
  /// 
  /// Rules:
  /// - Required field
  /// - 2-100 characters
  /// - Alphanumeric, spaces, and basic punctuation only
  static String? validateVendor(String vendor) {
    final trimmed = vendor.trim();
    if (trimmed.isEmpty) {
      return 'Vendor name is required';
    }
    if (trimmed.length < vendorMin) {
      return 'Vendor name must be at least $vendorMin characters';
    }
    if (trimmed.length > vendorMax) {
      return 'Vendor name cannot exceed $vendorMax characters';
    }

    // Disallow suspicious characters
    final validPattern = RegExp(r"^[a-zA-Z0-9\s\-&'.,]+$");
    if (!validPattern.hasMatch(trimmed)) {
      return 'Vendor name contains invalid characters';
    }

    return null;
  }

  /// Validate individual item description
  /// 
  /// Rules:
  /// - 1-50 characters
  /// - Non-empty
  static String? validateItem(String item) {
    final trimmed = item.trim();
    if (trimmed.isEmpty) {
      return 'Item description cannot be empty';
    }
    if (trimmed.length > itemMax) {
      return 'Item cannot exceed $itemMax characters';
    }
    return null;
  }

  /// Validate items array
  /// 
  /// Rules:
  /// - At least 1 item required
  /// - Maximum 20 items
  /// - Each item validated individually
  static String? validateItems(List<String> items) {
    if (items.isEmpty) {
      return 'At least one item is required';
    }
    if (items.length > itemsLimit) {
      return 'Cannot add more than $itemsLimit items';
    }

    for (int i = 0; i < items.length; i++) {
      final error = validateItem(items[i]);
      if (error != null) {
        return 'Item ${i + 1}: $error';
      }
    }

    return null;
  }

  /// Validate description (optional)
  /// 
  /// Rules:
  /// - Optional field (0-500 characters if provided)
  static String? validateDescription(String? description) {
    if (description == null || description.isEmpty) {
      return null; // Optional field
    }
    if (description.length > descriptionMax) {
      return 'Description cannot exceed $descriptionMax characters';
    }
    return null;
  }

  /// Validate category (optional)
  /// 
  /// Rules:
  /// - Optional field
  /// - Must be from valid category list if provided
  static String? validateCategory(String? category) {
    if (category == null || category.isEmpty) {
      return null; // Optional field
    }

    if (!validCategories.contains(category)) {
      return 'Invalid category. Must be one of: ${validCategories.join(', ')}';
    }

    return null;
  }

  /// Validate receipt URL (optional)
  /// 
  /// Rules:
  /// - Optional field
  /// - Must be valid HTTP(S) URL if provided
  static String? validateReceiptUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null; // Optional field
    }

    try {
      Uri.parse(url);
      if (!url.startsWith('http://') && !url.startsWith('https://')) {
        return 'Receipt URL must start with http:// or https://';
      }
      return null;
    } catch (e) {
      return 'Receipt URL must be a valid URL';
    }
  }

  /// Validate entire expense
  /// 
  /// Returns a map of field -> error message for any invalid fields.
  /// Empty map means all fields are valid.
  static Map<String, String> validateExpense({
    required double amount,
    required String vendor,
    required List<String> items,
    String? description,
    String? category,
    String? receiptUrl,
  }) {
    final errors = <String, String>{};

    final amountError = validateAmount(amount);
    if (amountError != null) {
      errors['amount'] = amountError;
    }

    final vendorError = validateVendor(vendor);
    if (vendorError != null) {
      errors['vendor'] = vendorError;
    }

    final itemsError = validateItems(items);
    if (itemsError != null) {
      errors['items'] = itemsError;
    }

    final descriptionError = validateDescription(description);
    if (descriptionError != null) {
      errors['description'] = descriptionError;
    }

    final categoryError = validateCategory(category);
    if (categoryError != null) {
      errors['category'] = categoryError;
    }

    final receiptError = validateReceiptUrl(receiptUrl);
    if (receiptError != null) {
      errors['receiptUrl'] = receiptError;
    }

    return errors;
  }

  /// Check if expense has validation errors
  /// 
  /// Returns true if any field has validation errors.
  static bool hasErrors({
    required double amount,
    required String vendor,
    required List<String> items,
    String? description,
    String? category,
    String? receiptUrl,
  }) {
    final errors = validateExpense(
      amount: amount,
      vendor: vendor,
      items: items,
      description: description,
      category: category,
      receiptUrl: receiptUrl,
    );
    return errors.isNotEmpty;
  }

  /// Get first validation error message
  /// 
  /// Returns the first error found, useful for displaying a single
  /// error message to the user instead of all validation errors.
  static String? getFirstError({
    required double amount,
    required String vendor,
    required List<String> items,
    String? description,
    String? category,
    String? receiptUrl,
  }) {
    final errors = validateExpense(
      amount: amount,
      vendor: vendor,
      items: items,
      description: description,
      category: category,
      receiptUrl: receiptUrl,
    );
    if (errors.isEmpty) return null;
    return errors.values.first;
  }
}
