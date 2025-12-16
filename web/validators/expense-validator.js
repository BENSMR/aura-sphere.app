/**
 * Expense Validation Service
 * 
 * Client-side validation for expense forms with consistent rules
 * across web, mobile, and desktop platforms.
 * 
 * IMPORTANT: Server-side validation in Cloud Functions is REQUIRED
 * These client-side checks are for UX only and can be bypassed.
 */

class ExpenseValidator {
  // Amount limits
  static readonly AMOUNT_MIN = 0.01;
  static readonly AMOUNT_MAX = 100000;

  // String limits
  static readonly VENDOR_MIN = 2;
  static readonly VENDOR_MAX = 100;
  static readonly ITEM_MIN = 1;
  static readonly ITEM_MAX = 50;
  static readonly ITEMS_LIMIT = 20;
  static readonly DESCRIPTION_MAX = 500;

  // Valid categories
  static readonly VALID_CATEGORIES = [
    'travel',
    'meals',
    'office_supplies',
    'equipment',
    'software',
    'marketing',
    'other',
  ];

  /**
   * Validate expense amount
   * @param {number} amount - Amount in USD
   * @returns {string|null} - Error message or null if valid
   */
  static validateAmount(amount) {
    if (typeof amount !== 'number') {
      return 'Amount must be a number';
    }

    if (amount < this.AMOUNT_MIN) {
      return `Amount must be at least $${this.AMOUNT_MIN.toFixed(2)}`;
    }

    if (amount > this.AMOUNT_MAX) {
      return `Amount cannot exceed $${this.AMOUNT_MAX.toLocaleString()}`;
    }

    if (!Number.isFinite(amount)) {
      return 'Amount must be a valid number';
    }

    // Check decimal places (max 2)
    if (!/^\d+(\.\d{1,2})?$/.test(amount.toString())) {
      return 'Amount can have at most 2 decimal places';
    }

    return null;
  }

  /**
   * Validate vendor name
   * @param {string} vendor - Vendor name
   * @returns {string|null} - Error message or null if valid
   */
  static validateVendor(vendor) {
    if (typeof vendor !== 'string') {
      return 'Vendor must be a string';
    }

    const trimmed = vendor.trim();

    if (trimmed.length === 0) {
      return 'Vendor name is required';
    }

    if (trimmed.length < this.VENDOR_MIN) {
      return `Vendor name must be at least ${this.VENDOR_MIN} characters`;
    }

    if (trimmed.length > this.VENDOR_MAX) {
      return `Vendor name cannot exceed ${this.VENDOR_MAX} characters`;
    }

    // Disallow suspicious characters
    if (!/^[a-zA-Z0-9\s\-&'.,]+$/.test(trimmed)) {
      return 'Vendor name contains invalid characters';
    }

    return null;
  }

  /**
   * Validate item description
   * @param {string} item - Item description
   * @returns {string|null} - Error message or null if valid
   */
  static validateItem(item) {
    if (typeof item !== 'string') {
      return 'Item must be a string';
    }

    const trimmed = item.trim();

    if (trimmed.length === 0) {
      return 'Item description cannot be empty';
    }

    if (trimmed.length < this.ITEM_MIN) {
      return `Item must be at least ${this.ITEM_MIN} character`;
    }

    if (trimmed.length > this.ITEM_MAX) {
      return `Item cannot exceed ${this.ITEM_MAX} characters`;
    }

    return null;
  }

  /**
   * Validate items array
   * @param {string[]} items - Array of item descriptions
   * @returns {string|null} - Error message or null if valid
   */
  static validateItems(items) {
    if (!Array.isArray(items)) {
      return 'Items must be an array';
    }

    if (items.length === 0) {
      return 'At least one item is required';
    }

    if (items.length > this.ITEMS_LIMIT) {
      return `Cannot add more than ${this.ITEMS_LIMIT} items`;
    }

    for (let i = 0; i < items.length; i++) {
      const error = this.validateItem(items[i]);
      if (error) {
        return `Item ${i + 1}: ${error}`;
      }
    }

    return null;
  }

  /**
   * Validate description (optional)
   * @param {string|null|undefined} description - Description text
   * @returns {string|null} - Error message or null if valid
   */
  static validateDescription(description) {
    if (!description || typeof description !== 'string') {
      return null; // Optional field
    }

    if (description.length > this.DESCRIPTION_MAX) {
      return `Description cannot exceed ${this.DESCRIPTION_MAX} characters`;
    }

    return null;
  }

  /**
   * Validate category
   * @param {string|null} category - Category identifier
   * @returns {string|null} - Error message or null if valid
   */
  static validateCategory(category) {
    if (!category || typeof category !== 'string') {
      return null; // Optional field
    }

    if (!this.VALID_CATEGORIES.includes(category.toLowerCase())) {
      return `Invalid category. Must be one of: ${this.VALID_CATEGORIES.join(', ')}`;
    }

    return null;
  }

  /**
   * Validate receipt URL (optional)
   * @param {string|null} url - Receipt URL
   * @returns {string|null} - Error message or null if valid
   */
  static validateReceiptUrl(url) {
    if (!url || typeof url !== 'string') {
      return null; // Optional field
    }

    try {
      new URL(url);
      return null;
    } catch {
      return 'Receipt URL must be a valid URL';
    }
  }

  /**
   * Validate entire expense object
   * @param {Object} expense - Expense object
   * @returns {Object} - Object with field errors: {amount: "error", vendor: "error", ...}
   */
  static validateExpense(expense) {
    const errors = {};

    // Required fields
    if (!expense || typeof expense !== 'object') {
      return { _root: 'Expense data must be an object' };
    }

    // Validate amount (required)
    const amountError = this.validateAmount(expense.amount);
    if (amountError) {
      errors.amount = amountError;
    }

    // Validate vendor (required)
    const vendorError = this.validateVendor(expense.vendor);
    if (vendorError) {
      errors.vendor = vendorError;
    }

    // Validate items (required)
    const itemsError = this.validateItems(expense.items || []);
    if (itemsError) {
      errors.items = itemsError;
    }

    // Validate optional fields
    const descriptionError = this.validateDescription(expense.description);
    if (descriptionError) {
      errors.description = descriptionError;
    }

    const categoryError = this.validateCategory(expense.category);
    if (categoryError) {
      errors.category = categoryError;
    }

    const receiptError = this.validateReceiptUrl(expense.receiptUrl);
    if (receiptError) {
      errors.receiptUrl = receiptError;
    }

    return errors;
  }

  /**
   * Check if expense has validation errors
   * @param {Object} expense - Expense object
   * @returns {boolean} - True if expense has errors
   */
  static hasErrors(expense) {
    const errors = this.validateExpense(expense);
    return Object.keys(errors).length > 0;
  }

  /**
   * Get first validation error message
   * @param {Object} expense - Expense object
   * @returns {string|null} - First error message or null
   */
  static getFirstError(expense) {
    const errors = this.validateExpense(expense);
    const keys = Object.keys(errors);
    return keys.length > 0 ? errors[keys[0]] : null;
  }
}

// Export to global scope for Flutter interop
if (typeof window !== 'undefined') {
  window.ExpenseValidator = ExpenseValidator;
}

// Module export for Node.js
if (typeof module !== 'undefined' && module.exports) {
  module.exports = ExpenseValidator;
}
