# Formatter Utilities — Complete Reference

**Status: ✅ READY TO USE**

Comprehensive formatting utilities for currency, dates, numbers, percentages, invoices, and more.

---

## Flutter Formatters

**Location:** [lib/core/utils/formatters.dart](lib/core/utils/formatters.dart)

```dart
import 'package:aurasphere_pro/core/utils/formatters.dart';
```

### Currency Formatting

```dart
// Format with symbol (default: $)
Formatters.formatCurrency(1234.5)  // "$1,234.50"
Formatters.formatCurrency(1234.5, symbol: '€')  // "€1,234.50"

// Format with currency code suffix
Formatters.formatAmountWithSymbol(1234.5, 'USD')  // "1,234.50 USD"
```

### Date Formatting

```dart
// Readable date format
Formatters.formatDate(DateTime.now())  // "Jan 15, 2025"

// Date with time
Formatters.formatDateTime(DateTime.now())  // "Jan 15, 2025 2:30 PM"

// ISO format (for APIs)
Formatters.formatDateISO(DateTime.now())  // "2025-01-15"

// Time only
Formatters.formatTime(DateTime.now())  // "2:30 PM"
```

### Number Formatting

```dart
// Integer with separators
Formatters.formatNumber(1234567)  // "1,234,567"

// Decimal with specific places
Formatters.formatDecimal(1234.5, decimals: 2)  // "1,234.50"
```

### Percentage Formatting

```dart
// Convert decimal to percentage
Formatters.formatPercentage(0.25)  // "25.0%"
Formatters.formatPercentage(0.125, decimals: 2)  // "12.50%"
```

### Invoice Number Formatting

```dart
// Format with prefix and padding
Formatters.formatInvoiceNumber('INV-', 42)  // "INV-0042"
Formatters.formatInvoiceNumber('2024-', 1001, padding: 5)  // "2024-01001"
```

### Phone Formatting

```dart
// US phone format (10 digits)
Formatters.formatPhone('1234567890')  // "(123) 456-7890"
```

### Currency Symbols

```dart
// Get symbol for currency code
Formatters.getCurrencySymbol('USD')  // "$"
Formatters.getCurrencySymbol('EUR')  // "€"
Formatters.getCurrencySymbol('GBP')  // "£"
```

---

## TypeScript Cloud Functions

**Location:** [functions/src/utils/formatters.ts](functions/src/utils/formatters.ts)

```typescript
import {
  formatCurrency,
  formatDate,
  formatNumber,
  formatPercentage,
  formatInvoiceNumber,
  formatAmountWithSymbol,
  getCurrencySymbol,
  escapeCsv,
  escapeHtml,
} from './utils/formatters';
```

### Currency Formatting

```typescript
// Format with symbol (default: $)
formatCurrency(1234.5)  // "$1,234.50"
formatCurrency(1234.5, '€')  // "€1,234.50"

// Format with currency code suffix
formatAmountWithSymbol(1234.5, 'USD')  // "1,234.50 USD"

// Locale-aware formatting
formatCurrencyLocale(1234.5, 'EUR', 'de-DE')  // "1.234,50 €"
```

### Date Formatting

```typescript
// Readable date format
formatDate(new Date())  // "Jan 15, 2025"
formatDate('2025-01-15T10:30:00Z')  // "Jan 15, 2025"

// Date with time
formatDateTime(new Date())  // "Jan 15, 2025 2:30 PM"

// ISO format (for APIs)
formatDateISO(new Date())  // "2025-01-15"

// Time only
formatTime(new Date())  // "2:30 PM"
```

### Number Formatting

```typescript
// Integer with separators
formatNumber(1234567)  // "1,234,567"

// Decimal with specific places
formatDecimal(1234.5, 2)  // "1,234.50"
```

### Percentage Formatting

```typescript
// Convert decimal to percentage
formatPercentage(0.25)  // "25.0%"
formatPercentage(0.125, 2)  // "12.50%"
```

### Invoice Number Formatting

```typescript
// Format with prefix and padding
formatInvoiceNumber('INV-', 42)  // "INV-0042"
formatInvoiceNumber('2024-', 1001, 5)  // "2024-01001"
```

### Phone Formatting

```typescript
// US phone format (10 digits)
formatPhone('1234567890')  // "(123) 456-7890"
```

### HTML/CSV Escaping

```typescript
// Escape for HTML rendering (invoices, reports)
escapeHtml('<script>alert("XSS")</script>')  // "&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;"

// Escape for CSV export
escapeCsv('Smith, John')  // '"Smith, John"'
escapeCsv('Quote: "Hello"')  // '"Quote: ""Hello"""'
```

---

## Usage Examples

### Invoice Export (TypeScript)

```typescript
import {
  formatCurrency,
  formatDate,
  formatNumber,
  formatPercentage,
  escapeHtml,
} from './utils/formatters';

function buildInvoiceHtml(invoice: any) {
  return `
    <h1>INVOICE</h1>
    <p><strong>Date:</strong> ${formatDate(invoice.createdAt)}</p>
    <p><strong>Due:</strong> ${formatDate(invoice.dueDate)}</p>
    <table>
      <tr>
        <td>${escapeHtml(invoice.items[0].name)}</td>
        <td>${formatNumber(invoice.items[0].quantity)}</td>
        <td>${formatCurrency(invoice.items[0].unitPrice)}</td>
        <td>${formatPercentage(invoice.items[0].vatRate)}</td>
      </tr>
    </table>
    <p><strong>Total:</strong> ${formatCurrency(invoice.total)}</p>
  `;
}
```

### Finance Dashboard (Flutter)

```dart
import 'package:aurasphere_pro/core/utils/formatters.dart';

class DashboardCard extends StatelessWidget {
  final double totalRevenue;
  final double profitMargin;
  final DateTime lastUpdated;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          Formatters.formatCurrency(totalRevenue, symbol: '\$'),
          style: Theme.of(context).textTheme.headlineMedium,
        ),
        Text(
          'Profit: ${Formatters.formatPercentage(profitMargin)}',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        Text(
          'Updated: ${Formatters.formatDateTime(lastUpdated)}',
          style: Theme.of(context).textTheme.bodySmall,
        ),
      ],
    );
  }
}
```

### Invoice List (Flutter)

```dart
ListTile(
  title: Text('Invoice ${Formatters.formatInvoiceNumber("INV-", invoice.number)}'),
  subtitle: Text('${Formatters.formatCurrency(invoice.amount)} • Due ${Formatters.formatDate(invoice.dueDate)}'),
)
```

---

## Supported Currencies

| Code | Symbol | Code | Symbol | Code | Symbol |
|------|--------|------|--------|------|--------|
| USD  | $      | EUR  | €      | GBP  | £      |
| JPY  | ¥      | INR  | ₹      | BRL  | R$     |
| CAD  | C$     | AUD  | A$     | CHF  | CHF    |
| CNY  | ¥      | SEK  | kr     | NZD  | NZ$    |
| MXN  | $      | SGD  | S$     | HKD  | HK$    |

---

## Migration Guide

### From Old API to New API

```dart
// ❌ Old
Formatters.currency(amount)

// ✅ New
Formatters.formatCurrency(amount)
```

```dart
// ❌ Old
Formatters.date(date)

// ✅ New
Formatters.formatDate(date)
Formatters.formatDateTime(dateTime)
```

**Old methods still work** for backward compatibility, but use the new `format*()` methods for consistency.

---

## Testing

```dart
// Flutter test example
test('formatCurrency formats correctly', () {
  expect(Formatters.formatCurrency(1234.5), '\$1,234.50');
  expect(Formatters.formatCurrency(1234.5, symbol: '€'), '€1,234.50');
});

test('formatPercentage formats correctly', () {
  expect(Formatters.formatPercentage(0.25), '25.0%');
  expect(Formatters.formatPercentage(0.333, decimals: 2), '33.30%');
});
```

---

## Performance Notes

- All formatters are **pure functions** (no side effects)
- Suitable for **high-frequency rendering** (lists, dashboards)
- Use `const` for static formatters when possible
- Locale operations are cached by system

---

## Next Steps

1. **Update existing code** to use new `format*()` methods
2. **Import from centralized location** to ensure consistency
3. **Use in invoice generation**, financial reports, and UI
4. **Add timezone-aware formatting** for global audiences (coming soon)

---
