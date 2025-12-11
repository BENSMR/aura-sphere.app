import 'package:flutter/material.dart';
import '../models/company.dart';
import '../models/contact.dart';
import '../services/invoice_service.dart';
import '../services/company_service.dart';
import '../services/contact_service.dart';

/// Finance-focused Invoice Provider
/// 
/// Integrates with:
/// - InvoiceService (base CRUD)
/// - CompanyService (company details)
/// - ContactService (contact details)
/// - Tax/Currency calculations
class FinanceInvoiceProvider extends ChangeNotifier {
  final InvoiceService _invoiceService = InvoiceService();
  final CompanyService _companyService = CompanyService();
  final ContactService _contactService = ContactService();

  List<Map<String, dynamic>> _invoices = [];
  Map<String, dynamic>? _selectedInvoice;
  Company? _selectedCompany;
  Contact? _selectedContact;
  bool _isLoading = false;
  String? _error;
  Map<String, dynamic> _stats = {};

  // Getters
  List<Map<String, dynamic>> get invoices => _invoices;
  Map<String, dynamic>? get selectedInvoice => _selectedInvoice;
  Company? get selectedCompany => _selectedCompany;
  Contact? get selectedContact => _selectedContact;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, dynamic> get stats => _stats;
  bool get hasInvoices => _invoices.isNotEmpty;
  bool get isReadyToCreateInvoice =>
      _selectedCompany != null && _selectedContact != null;

  /// Initialize: Load invoices summary
  Future<void> init() async {
    try {
      _setLoading(true);
      _error = null;

      // Load summary to get stats
      _stats = await _invoiceService.getInvoiceSummary('user');
      _invoices = [];

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
    }
  }

  /// Select an invoice
  Future<void> selectInvoice(String invoiceId) async {
    try {
      _selectedInvoice = await _invoiceService.getInvoiceById(invoiceId);

      if (_selectedInvoice != null) {
        // Load associated company and contact if IDs available
        final companyId = _selectedInvoice!['companyId'];
        final contactId = _selectedInvoice!['contactId'];

        if (companyId != null) {
          _selectedCompany = await _companyService.getCompany(companyId);
        }
        if (contactId != null) {
          _selectedContact = await _contactService.getContact(contactId);
        }
      }

      notifyListeners();
    } catch (e) {
      _error = e.toString();
    }
  }

  /// Select company for new invoice
  Future<void> selectCompany(Company company) async {
    _selectedCompany = company;
    notifyListeners();
  }

  /// Select contact for new invoice
  Future<void> selectContact(Contact contact) async {
    _selectedContact = contact;
    notifyListeners();
  }

  /// Mark invoice as paid
  Future<bool> markAsPaid(String invoiceId) async {
    try {
      _error = null;
      _setLoading(true);

      await _invoiceService.markInvoicePaid(invoiceId);

      // Reload summary
      _stats = await _invoiceService.getInvoiceSummary('user');

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Mark invoice as unpaid
  Future<bool> markAsUnpaid(String invoiceId) async {
    try {
      _error = null;
      _setLoading(true);

      await _invoiceService.markInvoiceUnpaid(invoiceId);

      // Reload summary
      _stats = await _invoiceService.getInvoiceSummary('user');

      notifyListeners();
      _setLoading(false);
      return true;
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      return false;
    }
  }

  /// Get total unpaid
  Future<double> getTotalUnpaid() async {
    try {
      return await _invoiceService.getTotalUnpaid('user');
    } catch (e) {
      return 0.0;
    }
  }

  /// Get total overdue
  Future<double> getTotalOverdue() async {
    try {
      return await _invoiceService.getTotalOverdue('user');
    } catch (e) {
      return 0.0;
    }
  }

  /// Get unpaid count
  Future<int> getUnpaidCount() async {
    try {
      return await _invoiceService.getUnpaidCount('user');
    } catch (e) {
      return 0;
    }
  }

  /// Get overdue count
  Future<int> getOverdueCount() async {
    try {
      return await _invoiceService.getOverdueCount('user');
    } catch (e) {
      return 0;
    }
  }

  /// Get invoice by ID
  Future<Map<String, dynamic>?> getInvoiceById(String invoiceId) async {
    try {
      return await _invoiceService.getInvoiceById(invoiceId);
    } catch (e) {
      return null;
    }
  }

  /// Set invoice due date
  Future<bool> setDueDate(String invoiceId, DateTime dueDate) async {
    try {
      _error = null;
      await _invoiceService.setDueDate(invoiceId, dueDate);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Update invoice status
  Future<bool> updateInvoiceStatus(String invoiceId, String status) async {
    try {
      _error = null;
      await _invoiceService.updateInvoiceStatus(invoiceId, status);
      notifyListeners();
      return true;
    } catch (e) {
      _error = e.toString();
      return false;
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear selection
  void clearSelection() {
    _selectedInvoice = null;
    _selectedCompany = null;
    _selectedContact = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Check if tax calculation is still pending
  bool isTaxCalculationPending(Map<String, dynamic> invoice) {
    final taxStatus = invoice['taxStatus'] as String?;
    return taxStatus == 'queued';
  }

  /// Get next invoice number
  Future<String?> getNextInvoiceNumber() async {
    try {
      return await _invoiceService.getNextInvoiceNumber();
    } catch (e) {
      return null;
    }
  }
}
