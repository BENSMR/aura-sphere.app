import 'package:flutter/foundation.dart';
import '../../services/firebase/invoice_numbering_service.dart';

/// State management for invoice numbering
/// Handles invoice number generation, incrementation, and validation
class InvoiceNumberingProvider extends ChangeNotifier {
  final InvoiceNumberingService _service = InvoiceNumberingService();

  String _currentInvoiceNumber = '';
  int _nextNumber = 1;
  String _prefix = 'INV-';
  bool _isLoading = false;
  String? _error;
  int _lastIssuedNumber = 0;

  // Getters
  String get currentInvoiceNumber => _currentInvoiceNumber;
  int get nextNumber => _nextNumber;
  String get prefix => _prefix;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get lastIssuedNumber => _lastIssuedNumber;

  /// Initialize the provider by loading the current invoice number
  Future<void> initialize() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _currentInvoiceNumber = await _service.generateNextInvoiceNumber();
      
      // Parse the invoice number to extract components
      final info = await _service.getNextInvoiceInfo();
      _nextNumber = info['nextNumber'] as int;
      _prefix = info['prefix'] as String;
      _lastIssuedNumber = info['lastNumber'] as int? ?? 0;
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to initialize invoice numbering: $e';
      _isLoading = false;
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Get the next invoice number to display to the user
  /// This does NOT increment the counter
  /// Call this before creating an invoice
  Future<String> getNextInvoiceNumber() async {
    try {
      _currentInvoiceNumber = await _service.generateNextInvoiceNumber();
      _error = null;
      notifyListeners();
      return _currentInvoiceNumber;
    } catch (e) {
      _error = 'Failed to get invoice number: $e';
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Increment the invoice number after successful invoice creation
  /// IMPORTANT: Call this AFTER the invoice has been saved to Firestore
  /// If invoice save fails, do NOT call this method
  Future<int> incrementInvoiceNumber() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final newNumber = await _service.incrementInvoiceNumber();
      _nextNumber = newNumber;
      
      // Update current invoice number display
      _currentInvoiceNumber = InvoiceNumberingService.getFormattedNumber(
        prefix: _prefix,
        number: newNumber,
      );
      _lastIssuedNumber = newNumber - 1;

      _isLoading = false;
      notifyListeners();
      
      return newNumber;
    } catch (e) {
      _error = 'Failed to increment invoice number: $e';
      _isLoading = false;
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Reset invoice number (use with caution)
  /// This should only be done during onboarding
  Future<void> resetInvoiceNumber(int newNumber) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.resetInvoiceNumber(newNumber);
      _nextNumber = newNumber;
      _currentInvoiceNumber = InvoiceNumberingService.getFormattedNumber(
        prefix: _prefix,
        number: newNumber,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to reset invoice number: $e';
      _isLoading = false;
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Get detailed invoice numbering information
  /// Useful for displaying in UI
  Future<Map<String, dynamic>> getInvoiceInfo() async {
    try {
      return await _service.getNextInvoiceInfo();
    } catch (e) {
      _error = 'Failed to get invoice info: $e';
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Generate multiple invoice numbers for preview (doesn't increment counter)
  Future<List<String>> previewInvoiceNumbers(int count) async {
    try {
      return await _service.generateMultipleInvoiceNumbers(count);
    } catch (e) {
      _error = 'Failed to preview invoice numbers: $e';
      notifyListeners();
      throw Exception(_error);
    }
  }

  /// Validate the current invoice sequence for audit purposes
  Future<bool> validateSequence() async {
    try {
      return await _service.validateInvoiceSequence();
    } catch (e) {
      _error = 'Failed to validate sequence: $e';
      notifyListeners();
      return false;
    }
  }

  /// Clear error message
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Get formatted invoice number with custom prefix
  String getFormattedNumber({String? customPrefix, int? customNumber}) {
    return InvoiceNumberingService.getFormattedNumber(
      prefix: customPrefix ?? _prefix,
      number: customNumber ?? _nextNumber,
    );
  }

  /// Check if invoice number format is valid
  bool isValidFormat(String invoiceNumber) {
    return InvoiceNumberingService.isValidInvoiceNumberFormat(invoiceNumber);
  }
}
