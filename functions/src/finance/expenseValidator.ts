import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';
import { logger } from './utils/logger';

/**
 * Validate Expense Data
 * 
 * Server-side validation for expense submissions.
 * This is REQUIRED and cannot be bypassed (unlike client-side validation).
 * 
 * Rules enforced:
 * - Amount: $0.01 - $100,000.00, max 2 decimal places
 * - Vendor: 2-100 characters, alphanumeric + punctuation
 * - Items: 1-20 items, each 1-50 characters
 * - Description: 0-500 characters (optional)
 * - Category: from predefined list (optional)
 * 
 * Called by: addExpense Cloud Function
 */

const AMOUNT_MIN = 0.01;
const AMOUNT_MAX = 100000;

const VENDOR_MIN = 2;
const VENDOR_MAX = 100;

const ITEM_MIN = 1;
const ITEM_MAX = 50;
const ITEMS_LIMIT = 20;

const DESCRIPTION_MAX = 500;

const VALID_CATEGORIES = [
  'travel',
  'meals',
  'office_supplies',
  'equipment',
  'software',
  'marketing',
  'other',
];

interface ExpenseData {
  amount: number;
  vendor: string;
  items: string[];
  description?: string;
  category?: string;
  receiptUrl?: string;
}

interface ValidationErrors {
  [key: string]: string;
}

/**
 * Validate expense amount
 */
function validateAmount(amount: number): string | null {
  if (typeof amount !== 'number' || !isFinite(amount)) {
    return 'Amount must be a valid number';
  }

  if (amount < AMOUNT_MIN) {
    return `Amount must be at least $${AMOUNT_MIN.toFixed(2)}`;
  }

  if (amount > AMOUNT_MAX) {
    return `Amount cannot exceed $${AMOUNT_MAX.toLocaleString()}`;
  }

  // Check decimal places (max 2)
  const rounded = Math.round(amount * 100) / 100;
  if (Math.abs(amount - rounded) > 0.001) {
    return 'Amount can have at most 2 decimal places';
  }

  return null;
}

/**
 * Validate vendor name
 */
function validateVendor(vendor: string): string | null {
  if (typeof vendor !== 'string') {
    return 'Vendor must be a string';
  }

  const trimmed = vendor.trim();

  if (trimmed.length === 0) {
    return 'Vendor name is required';
  }

  if (trimmed.length < VENDOR_MIN) {
    return `Vendor name must be at least ${VENDOR_MIN} characters`;
  }

  if (trimmed.length > VENDOR_MAX) {
    return `Vendor name cannot exceed ${VENDOR_MAX} characters`;
  }

  // Disallow suspicious characters
  const validPattern = /^[a-zA-Z0-9\s\-&'.,]+$/;
  if (!validPattern.test(trimmed)) {
    return 'Vendor name contains invalid characters';
  }

  return null;
}

/**
 * Validate individual item
 */
function validateItem(item: string, index: number): string | null {
  if (typeof item !== 'string') {
    return `Item ${index + 1} must be a string`;
  }

  const trimmed = item.trim();

  if (trimmed.length === 0) {
    return `Item ${index + 1} description cannot be empty`;
  }

  if (trimmed.length > ITEM_MAX) {
    return `Item ${index + 1} cannot exceed ${ITEM_MAX} characters`;
  }

  return null;
}

/**
 * Validate items array
 */
function validateItems(items: any): string | null {
  if (!Array.isArray(items)) {
    return 'Items must be an array';
  }

  if (items.length === 0) {
    return 'At least one item is required';
  }

  if (items.length > ITEMS_LIMIT) {
    return `Cannot add more than ${ITEMS_LIMIT} items`;
  }

  for (let i = 0; i < items.length; i++) {
    const error = validateItem(items[i], i);
    if (error) {
      return error;
    }
  }

  return null;
}

/**
 * Validate description (optional)
 */
function validateDescription(description: any): string | null {
  if (!description || typeof description !== 'string') {
    return null; // Optional
  }

  if (description.length > DESCRIPTION_MAX) {
    return `Description cannot exceed ${DESCRIPTION_MAX} characters`;
  }

  return null;
}

/**
 * Validate category (optional)
 */
function validateCategory(category: any): string | null {
  if (!category || typeof category !== 'string') {
    return null; // Optional
  }

  if (!VALID_CATEGORIES.includes(category.toLowerCase())) {
    return `Invalid category. Must be one of: ${VALID_CATEGORIES.join(', ')}`;
  }

  return null;
}

/**
 * Validate receipt URL (optional)
 */
function validateReceiptUrl(url: any): string | null {
  if (!url || typeof url !== 'string') {
    return null; // Optional
  }

  try {
    new URL(url);
    return null;
  } catch {
    return 'Receipt URL must be a valid URL';
  }
}

/**
 * Validate entire expense
 * @returns {ValidationErrors} - Object with field -> error message
 */
export function validateExpense(expense: any): ValidationErrors {
  const errors: ValidationErrors = {};

  if (!expense || typeof expense !== 'object') {
    return { _root: 'Expense data must be an object' };
  }

  // Validate required fields
  const amountError = validateAmount(expense.amount);
  if (amountError) {
    errors.amount = amountError;
  }

  const vendorError = validateVendor(expense.vendor);
  if (vendorError) {
    errors.vendor = vendorError;
  }

  const itemsError = validateItems(expense.items);
  if (itemsError) {
    errors.items = itemsError;
  }

  // Validate optional fields
  const descriptionError = validateDescription(expense.description);
  if (descriptionError) {
    errors.description = descriptionError;
  }

  const categoryError = validateCategory(expense.category);
  if (categoryError) {
    errors.category = categoryError;
  }

  const receiptError = validateReceiptUrl(expense.receiptUrl);
  if (receiptError) {
    errors.receiptUrl = receiptError;
  }

  return errors;
}

/**
 * Check if expense passes validation
 */
export function isValidExpense(expense: any): boolean {
  const errors = validateExpense(expense);
  return Object.keys(errors).length === 0;
}

/**
 * Get first validation error
 */
export function getFirstValidationError(expense: any): string | null {
  const errors = validateExpense(expense);
  const keys = Object.keys(errors);
  return keys.length > 0 ? errors[keys[0]] : null;
}

/**
 * Cloud Function: Validate Expense (Public)
 * 
 * Can be called from client to get detailed validation errors.
 * Used for form validation feedback before submission.
 * 
 * Request body: { expense: {...} }
 * Response: { valid: boolean, errors?: {...}, message?: string }
 */
export const validateExpenseData = functions
  .https.onCall(async (data, context) => {
    try {
      // Check authentication
      if (!context.auth?.uid) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const { expense } = data;

      if (!expense) {
        throw new functions.https.HttpsError(
          'invalid-argument',
          'Expense data is required'
        );
      }

      // Validate
      const errors = validateExpense(expense);
      const isValid = Object.keys(errors).length === 0;

      logger.info(`Expense validation: ${isValid ? 'PASS' : 'FAIL'}`, {
        userId: context.auth.uid,
        errors: !isValid ? errors : undefined,
      });

      return {
        valid: isValid,
        errors: !isValid ? errors : undefined,
        message: isValid ? 'Expense is valid' : 'Expense has validation errors',
      };
    } catch (error: any) {
      logger.error('Expense validation error', {
        error: error.message,
        userId: context.auth?.uid,
      });

      throw new functions.https.HttpsError(
        'internal',
        'Expense validation failed'
      );
    }
  });

/**
 * Cloud Function: Add Expense (Internal)
 * 
 * Adds expense to Firestore after VALIDATING server-side.
 * Client-side validation is for UX; server validation is enforced here.
 * 
 * Called by: Flutter app, web app
 */
export const addExpense = functions
  .https.onCall(async (data, context) => {
    try {
      // Check authentication
      if (!context.auth?.uid) {
        throw new functions.https.HttpsError(
          'unauthenticated',
          'User must be authenticated'
        );
      }

      const userId = context.auth.uid;
      const { amount, vendor, items, description, category, receiptUrl } = data;

      // Build expense object
      const expense = {
        amount,
        vendor,
        items: Array.isArray(items) ? items : [],
        description,
        category,
        receiptUrl,
      };

      // VALIDATE (Required - cannot bypass)
      const validationErrors = validateExpense(expense);
      if (Object.keys(validationErrors).length > 0) {
        logger.warn('Expense validation failed', {
          userId,
          errors: validationErrors,
          expense: {
            amount,
            vendor,
            itemsCount: items?.length,
          },
        });

        throw new functions.https.HttpsError(
          'invalid-argument',
          `Expense validation failed: ${Object.values(validationErrors)[0]}`
        );
      }

      // Create expense document
      const expenseData = {
        ...expense,
        userId,
        status: 'pending',
        createdAt: admin.firestore.FieldValue.serverTimestamp(),
        updatedAt: admin.firestore.FieldValue.serverTimestamp(),
      };

      // Add to Firestore
      const docRef = await admin
        .firestore()
        .collection('expenses')
        .add(expenseData);

      logger.info('Expense created', {
        userId,
        expenseId: docRef.id,
        amount,
        vendor,
      });

      return {
        success: true,
        expenseId: docRef.id,
        message: 'Expense added successfully',
      };
    } catch (error: any) {
      logger.error('Add expense error', {
        error: error.message,
        userId: context.auth?.uid,
      });

      if (error instanceof functions.https.HttpsError) {
        throw error;
      }

      throw new functions.https.HttpsError(
        'internal',
        'Failed to add expense'
      );
    }
  });
