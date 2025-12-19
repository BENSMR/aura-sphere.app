import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/invoice_model.dart';
import '../models/invoice_item.dart';

/// Service for managing invoices in Supabase
class InvoiceService {
  final _supabase = Supabase.instance.client;

  /// Get single invoice by ID
  Future<Invoice> getInvoice(String invoiceId) async {
    final data = await _supabase
        .from('invoices')
        .select()
        .eq('id', invoiceId)
        .single();

    return Invoice.fromJson(data);
  }

  /// Get all invoices for a user
  Future<List<Invoice>> getUserInvoices(String userId) async {
    final data = await _supabase
        .from('invoices')
        .select()
        .eq('user_id', userId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Watch invoices in real-time
  /// Emits entire list whenever any invoice changes
  Stream<List<Invoice>> watchInvoices(String userId) {
    return _supabase
        .from('invoices')
        .stream(primaryKey: ['id'])
        .eq('user_id', userId)
        .map((list) => list
            .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
            .toList());
  }

  /// Get invoices by client
  Future<List<Invoice>> getClientInvoices(String clientId) async {
    final data = await _supabase
        .from('invoices')
        .select()
        .eq('client_id', clientId)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get invoices by status
  Future<List<Invoice>> getInvoicesByStatus(String userId, String status) async {
    final data = await _supabase
        .from('invoices')
        .select()
        .eq('user_id', userId)
        .eq('status', status)
        .order('created_at', ascending: false);

    return (data as List)
        .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Create new invoice with items
  Future<Invoice> createInvoice({
    required String userId,
    required String invoiceNumber,
    required String clientId,
    required double amount,
    required String currency,
    required DateTime issueDate,
    required DateTime dueDate,
    required List<InvoiceItem> items,
    String status = 'draft',
  }) async {
    // Create invoice first
    final invoiceData = {
      'user_id': userId,
      'invoice_number': invoiceNumber,
      'client_id': clientId,
      'amount': amount,
      'currency': currency,
      'status': status,
      'issue_date': issueDate.toIso8601String().split('T')[0], // Date only
      'due_date': dueDate.toIso8601String().split('T')[0],
      'created_at': DateTime.now().toIso8601String(),
      'updated_at': DateTime.now().toIso8601String(),
    };

    final invoiceResult =
        await _supabase.from('invoices').insert(invoiceData).select().single();

    final invoiceId = invoiceResult['id'] as String;

    // Insert items
    for (var item in items) {
      await _supabase.from('invoice_items').insert({
        'invoice_id': invoiceId,
        'description': item.description,
        'quantity': item.quantity,
        'unit_price': item.unitPrice,
        'vat_rate': item.vatRate,
      });
    }

    return Invoice.fromJson(invoiceResult);
  }

  /// Update invoice
  Future<void> updateInvoice({
    required String invoiceId,
    String? status,
    String? paymentStatus,
    double? paidAmount,
    DateTime? paidAt,
  }) async {
    final update = <String, dynamic>{
      'updated_at': DateTime.now().toIso8601String(),
    };

    if (status != null) update['status'] = status;
    if (paymentStatus != null) update['payment_status'] = paymentStatus;
    if (paidAmount != null) update['paid_amount'] = paidAmount;
    if (paidAt != null) update['paid_at'] = paidAt.toIso8601String();

    await _supabase
        .from('invoices')
        .update(update)
        .eq('id', invoiceId);
  }

  /// Mark invoice as paid
  Future<void> markInvoiceAsPaid({
    required String invoiceId,
    required double paidAmount,
    required String paidCurrency,
  }) async {
    await updateInvoice(
      invoiceId: invoiceId,
      status: 'paid',
      paymentStatus: 'paid',
      paidAmount: paidAmount,
      paidAt: DateTime.now(),
    );
  }

  /// Delete invoice
  Future<void> deleteInvoice(String invoiceId) async {
    // Items will cascade delete via FK
    await _supabase
        .from('invoices')
        .delete()
        .eq('id', invoiceId);
  }

  /// Get invoice items
  Future<List<InvoiceItem>> getInvoiceItems(String invoiceId) async {
    final data = await _supabase
        .from('invoice_items')
        .select()
        .eq('invoice_id', invoiceId);

    return (data as List)
        .map((json) => InvoiceItem.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get overdue invoices
  Future<List<Invoice>> getOverdueInvoices(String userId) async {
    final today = DateTime.now().toIso8601String().split('T')[0];
    final data = await _supabase
        .from('invoices')
        .select()
        .eq('user_id', userId)
        .eq('payment_status', 'unpaid')
        .lt('due_date', today)
        .order('due_date', ascending: true);

    return (data as List)
        .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  /// Get paid invoices for a period
  Future<List<Invoice>> getPaidInvoicesForPeriod({
    required String userId,
    required DateTime startDate,
    required DateTime endDate,
  }) async {
    final start = startDate.toIso8601String().split('T')[0];
    final end = endDate.toIso8601String().split('T')[0];

    final data = await _supabase
        .from('invoices')
        .select()
        .eq('user_id', userId)
        .eq('payment_status', 'paid')
        .gte('paid_at', start)
        .lte('paid_at', end)
        .order('paid_at', ascending: false);

    return (data as List)
        .map((json) => Invoice.fromJson(json as Map<String, dynamic>))
        .toList();
  }
}
