import 'package:flutter/material.dart';
import 'dart:async';
import '../models/invoice_model.dart' show Invoice;
import '../services/invoice/invoice_service.dart';
import '../models/invoice_item.dart' show InvoiceItem;

class InvoiceProvider extends ChangeNotifier {
  final InvoiceService _svc = InvoiceService();
  List<Invoice> invoices = [];
  bool loading = false;
  StreamSubscription<List<Invoice>>? _watchSub;
  
  bool _isWatching = false;
  bool get isWatching => _isWatching;

  /// Start watching invoices for the current user
  void startWatching(String userId) {
    if (_isWatching) return; // avoid duplicate listeners
    _isWatching = true;
    
    // Stop any existing subscription
    _watchSub?.cancel();
    
    loading = true;
    notifyListeners();
    _watchSub = _svc.watchInvoices().listen((list) {
      invoices = list;
      loading = false;
      notifyListeners();
    });
  }

  /// Stop watching invoices (e.g., on logout)
  void stopWatching() {
    _watchSub?.cancel();
    _watchSub = null;
    _isWatching = false;
    invoices = [];
    loading = false;
    notifyListeners();
  }

  Future<Invoice> newDraft(String currency, String invoiceNumber) async {
    final id = DateTime.now().millisecondsSinceEpoch.toString();
    // TODO: Replace with actual Invoice.empty() constructor
    throw UnimplementedError('Use InvoiceService instead');
  }

  double computeSubtotal(List<InvoiceItem> items) =>
      items.fold(0.0, (p, e) => p + (e.unitPrice * e.quantity));

  double computeTotalVat(List<InvoiceItem> items) =>
      items.fold(0.0, (p, e) => p + (e.unitPrice * e.quantity * (e.vatRate / 100)));

  double computeTotal(List<InvoiceItem> items) =>
      computeSubtotal(items) + computeTotalVat(items);

  @override
  void dispose() {
    _watchSub?.cancel();
    super.dispose();
  }
}
