import 'dart:io';
import 'package:file_picker/file_picker.dart';
import '../../models/expense_model.dart';
import 'expense_service.dart';

/// CSV Importer for bulk expense uploads
/// 
/// Expected CSV format (header row required):
/// merchant, date, amount, currency, category, vatrate, paymentmethod
/// 
/// Example:
/// ```
/// merchant,date,amount,currency,category,vatrate,paymentmethod
/// Acme Corp,2025-11-27,100.00,EUR,Supplies,0.20,card
/// Coffee Shop,2025-11-26,5.50,USD,Food,0.00,cash
/// ```
class CsvImporter {
  final ExpenseService _svc = ExpenseService();

  /// Pick a CSV file and import expenses
  /// 
  /// Returns list of imported ExpenseModel objects
  /// Throws on file read or parse errors
  Future<List<ExpenseModel>> pickAndImport() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv'],
      dialogTitle: 'Select CSV File',
    );

    if (result == null || result.files.isEmpty) {
      throw Exception('No file selected');
    }

    final file = File(result.files.single.path!);

    if (!await file.exists()) {
      throw Exception('File not found: ${file.path}');
    }

    try {
      final csvContent = await file.readAsString();
      
      if (csvContent.trim().isEmpty) {
        throw Exception('CSV file is empty');
      }

      return await _svc.importCsvRows(csvContent);
    } catch (e) {
      throw Exception('Failed to read CSV: $e');
    }
  }

  /// Parse CSV content and validate format
  /// 
  /// Returns list of row maps with validated data
  static List<Map<String, String>> parseCSV(String csvContent) {
    final lines = csvContent.split('\n').where((l) => l.trim().isNotEmpty).toList();
    
    if (lines.isEmpty) {
      throw Exception('CSV is empty');
    }

    // Parse headers
    final headers = lines.first
        .split(',')
        .map((h) => h.trim().toLowerCase())
        .toList();

    final expectedHeaders = ['merchant', 'amount'];
    final missingHeaders = expectedHeaders
        .where((h) => !headers.contains(h))
        .toList();

    if (missingHeaders.isNotEmpty) {
      throw Exception(
        'Missing required columns: ${missingHeaders.join(", ")}',
      );
    }

    // Parse rows
    final List<Map<String, String>> rows = [];
    for (int i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final values = line.split(',');
      if (values.length != headers.length) {
        throw Exception('Row $i has ${values.length} columns, expected ${headers.length}');
      }

      final row = <String, String>{};
      for (int j = 0; j < headers.length; j++) {
        row[headers[j]] = values[j].trim().replaceAll('"', '');
      }

      rows.add(row);
    }

    if (rows.isEmpty) {
      throw Exception('No data rows found in CSV');
    }

    return rows;
  }

  /// Validate a single row before import
  static Map<String, dynamic> validateRow(Map<String, String> row) {
    final errors = <String>[];

    // Validate merchant
    if (row['merchant']?.isEmpty ?? true) {
      errors.add('merchant is required');
    }

    // Validate amount
    final amount = double.tryParse(row['amount'] ?? '');
    if (amount == null || amount <= 0) {
      errors.add('amount must be a positive number');
    }

    // Validate currency
    if ((row['currency'] ?? '').isEmpty) {
      errors.add('currency is required');
    }

    // Validate optional fields
    if (row['date'] != null && row['date']!.isNotEmpty) {
      try {
        DateTime.parse(row['date']!);
      } catch (_) {
        errors.add('date format invalid (use YYYY-MM-DD)');
      }
    }

    if (row['vatrate'] != null && row['vatrate']!.isNotEmpty) {
      final vatRate = double.tryParse(row['vatrate']!);
      if (vatRate == null || vatRate < 0 || vatRate > 1) {
        errors.add('vatrate must be between 0 and 1');
      }
    }

    if (errors.isNotEmpty) {
      return {
        'valid': false,
        'errors': errors,
      };
    }

    return {
      'valid': true,
      'data': {
        'merchant': row['merchant'] ?? '',
        'amount': amount!,
        'currency': row['currency'] ?? 'EUR',
        'category': row['category'] ?? 'General',
        'paymentmethod': row['paymentmethod'] ?? 'unknown',
        'date': row['date'],
        'vatrate': double.tryParse(row['vatrate'] ?? '0'),
      },
    };
  }

  /// Preview CSV content before importing
  /// 
  /// Returns summary with row count and first few rows
  static Map<String, dynamic> previewCSV(String csvContent) {
    try {
      final rows = parseCSV(csvContent);
      final preview = rows.take(3).map((row) {
        final validated = validateRow(row);
        return {
          'merchant': row['merchant'],
          'amount': row['amount'],
          'currency': row['currency'] ?? 'EUR',
          'valid': validated['valid'],
          'errors': validated['errors'] ?? [],
        };
      }).toList();

      return {
        'totalRows': rows.length,
        'previewRows': preview,
        'hasErrors': preview.any((r) => r['valid'] == false),
      };
    } catch (e) {
      return {
        'error': e.toString(),
        'totalRows': 0,
        'previewRows': [],
        'hasErrors': true,
      };
    }
  }
}

/// Example CSV format helper
/// 
/// Copy this template to create a valid CSV file:
/// ```
/// merchant,date,amount,currency,category,vatrate,paymentmethod
/// Acme Corp,2025-11-27,100.00,EUR,Supplies,0.20,card
/// Coffee Shop,2025-11-26,5.50,USD,Food,0.00,cash
/// Taxi Service,2025-11-25,25.00,EUR,Transport,0.20,card
/// ```
const csvTemplate = '''merchant,date,amount,currency,category,vatrate,paymentmethod
Acme Corp,2025-11-27,100.00,EUR,Supplies,0.20,card
Coffee Shop,2025-11-26,5.50,USD,Food,0.00,cash
Taxi Service,2025-11-25,25.00,EUR,Transport,0.20,card
Hotel Booking,2025-11-24,250.00,EUR,Travel,0.20,card
Internet Bill,2025-11-23,50.00,EUR,Utilities,0.20,bank''';
