/// Validator class for expense data
class ExpenseValidator {
  /// Validate expense amount
  static String? validateAmount(double amount) {
    if (amount <= 0) {
      return 'Amount must be greater than 0';
    }
    if (amount > 999999.99) {
      return 'Amount cannot exceed 999,999.99';
    }
    return null;
  }

  /// Validate vendor name
  static String? validateVendor(String vendor) {
    final trimmed = vendor.trim();
    if (trimmed.isEmpty) {
      return 'Vendor name is required';
    }
    if (trimmed.length < 2) {
      return 'Vendor name must be at least 2 characters';
    }
    if (trimmed.length > 100) {
      return 'Vendor name cannot exceed 100 characters';
    }
    return null;
  }

  /// Validate items list
  static String? validateItems(List<String> items) {
    if (items.isEmpty) {
      return 'At least one item is required';
    }
    if (items.length > 20) {
      return 'Cannot add more than 20 items';
    }

    for (final item in items) {
      final trimmed = item.trim();
      if (trimmed.isEmpty) {
        return 'Item cannot be empty';
      }
      if (trimmed.length > 50) {
        return 'Item description cannot exceed 50 characters';
      }
    }

    return null;
  }

  /// Validate description
  static String? validateDescription(String? description) {
    if (description == null || description.isEmpty) {
      return null; // Optional field
    }
    if (description.length > 500) {
      return 'Description cannot exceed 500 characters';
    }
    return null;
  }

  /// Validate category
  static String? validateCategory(String? category) {
    final validCategories = [
      'travel',
      'meals',
      'office_supplies',
      'equipment',
      'software',
      'marketing',
      'other',
    ];

    if (category == null || category.isEmpty) {
      return null; // Optional field
    }

    if (!validCategories.contains(category)) {
      return 'Invalid category';
    }

    return null;
  }

  /// Validate receipt URL
  static String? validateReceiptUrl(String? url) {
    if (url == null || url.isEmpty) {
      return null; // Optional field
    }

    if (!url.startsWith('http://') && !url.startsWith('https://')) {
      return 'Receipt URL must start with http:// or https://';
    }

    return null;
  }

  /// Validate entire expense
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
}
