/**
 * Centralized formatting utilities for Cloud Functions
 * Mirrors Dart formatters for consistency across platforms
 */

// ==================== CURRENCY ====================

/**
 * Format amount as currency with symbol (default: $)
 * @param amount - The amount to format
 * @param symbol - Currency symbol (default: "$")
 * @returns Formatted currency string (e.g., "$1,234.50")
 */
export function formatCurrency(amount: number, symbol: string = '$'): string {
  const formatted = amount.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  return `${symbol}${formatted}`;
}

/**
 * Format amount with symbol suffix (e.g., "1,234.50 USD")
 * @param amount - The amount to format
 * @param currencyCode - Currency code (e.g., "USD")
 * @returns Formatted amount string (e.g., "1,234.50 USD")
 */
export function formatAmountWithSymbol(amount: number, currencyCode: string): string {
  const formatted = amount.toLocaleString('en-US', {
    minimumFractionDigits: 2,
    maximumFractionDigits: 2,
  });
  return `${formatted} ${currencyCode}`;
}

// ==================== DATES ====================

/**
 * Format date as readable string (e.g., "Jan 15, 2025")
 * @param date - Date to format
 * @returns Formatted date string
 */
export function formatDate(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toLocaleDateString('en-US', {
    month: 'short',
    day: '2-digit',
    year: 'numeric',
  });
}

/**
 * Format date and time (e.g., "Jan 15, 2025 2:30 PM")
 * @param dateTime - DateTime to format
 * @returns Formatted datetime string
 */
export function formatDateTime(dateTime: Date | string): string {
  const dt = typeof dateTime === 'string' ? new Date(dateTime) : dateTime;
  const date = dt.toLocaleDateString('en-US', {
    month: 'short',
    day: '2-digit',
    year: 'numeric',
  });
  const time = dt.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });
  return `${date} ${time}`;
}

/**
 * Format as ISO date (YYYY-MM-DD)
 * @param date - Date to format
 * @returns ISO date string
 */
export function formatDateISO(date: Date | string): string {
  const d = typeof date === 'string' ? new Date(date) : date;
  return d.toISOString().split('T')[0];
}

/**
 * Format as time only (e.g., "2:30 PM")
 * @param dateTime - DateTime to format
 * @returns Formatted time string
 */
export function formatTime(dateTime: Date | string): string {
  const dt = typeof dateTime === 'string' ? new Date(dateTime) : dateTime;
  return dt.toLocaleTimeString('en-US', {
    hour: 'numeric',
    minute: '2-digit',
    hour12: true,
  });
}

// ==================== NUMBERS ====================

/**
 * Format integer with thousand separators
 * @param number - Number to format
 * @returns Formatted number string (e.g., "1,234,567")
 */
export function formatNumber(number: number): string {
  return Math.floor(number).toLocaleString('en-US');
}

/**
 * Format decimal number with specified decimal places
 * @param number - Number to format
 * @param decimals - Number of decimal places (default: 2)
 * @returns Formatted decimal string
 */
export function formatDecimal(number: number, decimals: number = 2): string {
  return number.toLocaleString('en-US', {
    minimumFractionDigits: decimals,
    maximumFractionDigits: decimals,
  });
}

// ==================== PERCENTAGES ====================

/**
 * Format as percentage (0.25 → "25.0%")
 * @param value - Value as decimal (0-1)
 * @param decimals - Number of decimal places (default: 1)
 * @returns Formatted percentage string
 */
export function formatPercentage(value: number, decimals: number = 1): string {
  const percent = value * 100;
  return `${percent.toFixed(decimals)}%`;
}

// ==================== INVOICE ====================

/**
 * Format invoice number with prefix and padded number
 * @param prefix - Invoice prefix (e.g., "INV-")
 * @param number - Invoice number
 * @param padding - Number of digits to pad to (default: 4)
 * @returns Formatted invoice number (e.g., "INV-0042")
 */
export function formatInvoiceNumber(
  prefix: string,
  number: number,
  padding: number = 4
): string {
  const padded = number.toString().padStart(padding, '0');
  return `${prefix}${padded}`;
}

// ==================== PHONE ====================

/**
 * Format phone number (10-digit US format)
 * @param phone - Phone number string
 * @returns Formatted phone string (e.g., "(123) 456-7890")
 */
export function formatPhone(phone: string): string {
  const cleaned = phone.replace(/\D/g, '');
  if (cleaned.length === 10) {
    return `(${cleaned.substring(0, 3)}) ${cleaned.substring(3, 6)}-${cleaned.substring(6)}`;
  }
  return phone;
}

// ==================== UTILITY HELPERS ====================

/**
 * Check if a value is a valid number
 * @param value - Value to check
 * @returns True if valid number
 */
export function isValidNumber(value: string | number): boolean {
  return !isNaN(Number(value));
}

/**
 * Get currency symbol for a currency code
 * @param currencyCode - Currency code (e.g., "USD")
 * @returns Currency symbol
 */
export function getCurrencySymbol(currencyCode: string): string {
  const symbols: { [key: string]: string } = {
    USD: '$',
    EUR: '€',
    GBP: '£',
    JPY: '¥',
    INR: '₹',
    BRL: 'R$',
    CAD: 'C$',
    AUD: 'A$',
    CHF: 'CHF',
    CNY: '¥',
    SEK: 'kr',
    NZD: 'NZ$',
    MXN: '$',
    SGD: 'S$',
    HKD: 'HK$',
  };
  return symbols[currencyCode] || currencyCode;
}

/**
 * Format currency amount with locale awareness
 * @param amount - Amount to format
 * @param currencyCode - ISO currency code
 * @param locale - Locale string (default: "en-US")
 * @returns Formatted currency
 */
export function formatCurrencyLocale(
  amount: number,
  currencyCode: string,
  locale: string = 'en-US'
): string {
  try {
    return new Intl.NumberFormat(locale, {
      style: 'currency',
      currency: currencyCode,
    }).format(amount);
  } catch (e) {
    // Fallback if locale not supported
    return formatAmountWithSymbol(amount, currencyCode);
  }
}

/**
 * Escape HTML special characters (safe for invoice rendering)
 * @param text - Text to escape
 * @returns Escaped HTML
 */
export function escapeHtml(text: string): string {
  if (!text) return '';
  const map: { [key: string]: string } = {
    '&': '&amp;',
    '<': '&lt;',
    '>': '&gt;',
    '"': '&quot;',
    "'": '&#039;',
  };
  return text.replace(/[&<>"']/g, (char) => map[char]);
}

/**
 * Escape CSV special characters
 * @param text - Text to escape
 * @returns Escaped CSV value
 */
export function escapeCsv(text: string): string {
  if (!text) return '';
  if (text.includes(',') || text.includes('"') || text.includes('\n')) {
    return `"${text.replace(/"/g, '""')}"`;
  }
  return text;
}
