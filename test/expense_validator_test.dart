import 'package:flutter_test/flutter_test.dart';
import 'package:aura_sphere_pro/models/expense.dart';
import 'package:aura_sphere_pro/utils/expense_validator.dart';

void main() {
  group('ExpenseValidator Tests', () {
    group('validateAmount', () {
      test('accepts valid amounts', () {
        expect(ExpenseValidator.validateAmount(45.99), isNull);
        expect(ExpenseValidator.validateAmount(1000.00), isNull);
        expect(ExpenseValidator.validateAmount(0.01), isNull);
      });

      test('rejects zero or negative amounts', () {
        expect(ExpenseValidator.validateAmount(0), isNotNull);
        expect(ExpenseValidator.validateAmount(-10.50), isNotNull);
      });

      test('rejects amounts exceeding limit', () {
        expect(
          ExpenseValidator.validateAmount(1000000.00),
          isNotNull,
        );
      });
    });

    group('validateVendor', () {
      test('accepts valid vendors', () {
        expect(ExpenseValidator.validateVendor('Office Supplies Co'), isNull);
        expect(ExpenseValidator.validateVendor('AB'), isNull);
      });

      test('rejects empty vendor', () {
        expect(ExpenseValidator.validateVendor(''), isNotNull);
        expect(ExpenseValidator.validateVendor('   '), isNotNull);
      });

      test('rejects vendors that are too short or long', () {
        expect(ExpenseValidator.validateVendor('A'), isNotNull);
        expect(
          ExpenseValidator.validateVendor('A' * 101),
          isNotNull,
        );
      });
    });

    group('validateItems', () {
      test('accepts valid items list', () {
        expect(
          ExpenseValidator.validateItems(['Printer Ink', 'Notebooks']),
          isNull,
        );
        expect(
          ExpenseValidator.validateItems(['Item 1']),
          isNull,
        );
      });

      test('rejects empty items list', () {
        expect(ExpenseValidator.validateItems([]), isNotNull);
      });

      test('rejects too many items', () {
        final items = List.generate(21, (i) => 'Item $i');
        expect(ExpenseValidator.validateItems(items), isNotNull);
      });

      test('rejects empty item strings', () {
        expect(
          ExpenseValidator.validateItems(['Valid', '', 'Also Valid']),
          isNotNull,
        );
      });

      test('rejects items that are too long', () {
        expect(
          ExpenseValidator.validateItems(['A' * 51]),
          isNotNull,
        );
      });
    });

    group('validateCategory', () {
      test('accepts valid categories', () {
        expect(ExpenseValidator.validateCategory('travel'), isNull);
        expect(ExpenseValidator.validateCategory('meals'), isNull);
        expect(ExpenseValidator.validateCategory('office_supplies'), isNull);
      });

      test('accepts null category', () {
        expect(ExpenseValidator.validateCategory(null), isNull);
        expect(ExpenseValidator.validateCategory(''), isNull);
      });

      test('rejects invalid categories', () {
        expect(ExpenseValidator.validateCategory('invalid_cat'), isNotNull);
      });
    });

    group('validateDescription', () {
      test('accepts valid descriptions', () {
        expect(
          ExpenseValidator.validateDescription('Valid description'),
          isNull,
        );
      });

      test('accepts null description', () {
        expect(ExpenseValidator.validateDescription(null), isNull);
      });

      test('rejects too long descriptions', () {
        expect(
          ExpenseValidator.validateDescription('A' * 501),
          isNotNull,
        );
      });
    });

    group('validateReceiptUrl', () {
      test('accepts valid URLs', () {
        expect(
          ExpenseValidator.validateReceiptUrl(
            'https://example.com/receipt.pdf',
          ),
          isNull,
        );
        expect(
          ExpenseValidator.validateReceiptUrl('http://example.com'),
          isNull,
        );
      });

      test('accepts null URL', () {
        expect(ExpenseValidator.validateReceiptUrl(null), isNull);
      });

      test('rejects invalid URLs', () {
        expect(
          ExpenseValidator.validateReceiptUrl('example.com'),
          isNotNull,
        );
        expect(
          ExpenseValidator.validateReceiptUrl('ftp://example.com'),
          isNotNull,
        );
      });
    });

    group('validateExpense', () {
      test('accepts valid complete expense', () {
        final errors = ExpenseValidator.validateExpense(
          amount: 45.99,
          vendor: 'Office Supplies Co',
          items: ['Printer Ink', 'Notebooks'],
          description: 'Monthly office supplies',
          category: 'office_supplies',
        );
        expect(errors, isEmpty);
      });

      test('returns all errors', () {
        final errors = ExpenseValidator.validateExpense(
          amount: -10,
          vendor: 'A',
          items: [],
          category: 'invalid',
        );
        expect(errors.length, greaterThan(1));
      });
    });
  });

  group('Expense Model Tests', () {
    test('creates expense from JSON', () {
      final data = {
        'userId': 'user123',
        'amount': 45.99,
        'vendor': 'Office Supplies Co',
        'items': ['Printer Ink', 'Notebooks'],
        'status': 'pending_review',
      };

      final expense = Expense.fromJson(data, 'expense123');

      expect(expense.id, 'expense123');
      expect(expense.userId, 'user123');
      expect(expense.amount, 45.99);
      expect(expense.vendor, 'Office Supplies Co');
      expect(expense.items, ['Printer Ink', 'Notebooks']);
    });

    test('converts expense to JSON', () {
      final expense = Expense(
        id: 'expense123',
        userId: 'user123',
        amount: 45.99,
        vendor: 'Office Supplies Co',
        items: ['Printer Ink', 'Notebooks'],
        createdAt: DateTime(2025, 12, 15),
        status: 'pending_review',
      );

      final json = expense.toJson();

      expect(json['userId'], 'user123');
      expect(json['amount'], 45.99);
      expect(json['vendor'], 'Office Supplies Co');
      expect(json['status'], 'pending_review');
    });

    test('copyWith creates new instance with updated fields', () {
      final expense = Expense(
        id: 'expense123',
        userId: 'user123',
        amount: 45.99,
        vendor: 'Office Supplies Co',
        items: ['Printer Ink'],
        createdAt: DateTime(2025, 12, 15),
        status: 'pending_review',
      );

      final updated = expense.copyWith(
        status: 'approved',
        amount: 50.00,
      );

      expect(updated.status, 'approved');
      expect(updated.amount, 50.00);
      expect(updated.vendor, 'Office Supplies Co'); // Unchanged
      expect(updated.id, expense.id); // Same ID
    });
  });
}
