import 'package:flutter/material.dart';
import '../models/invoice_model.dart';
import '../services/invoice_service.dart';

class InvoiceProvider with ChangeNotifier {
  final InvoiceService _invoiceService = InvoiceService();
  List<Invoice> _invoices = [];
  bool _isLoading = false;

  List<Invoice> get invoices => _invoices;
  bool get isLoading => _isLoading;

  Future<void> loadInvoices(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _invoices = await _invoiceService.getInvoices(userId);
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createInvoice(Invoice invoice) async {
    await _invoiceService.createInvoice(invoice);
    _invoices.add(invoice);
    notifyListeners();
  }
}
