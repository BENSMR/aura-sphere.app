import 'dart:typed_data';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/invoice_model.dart';
import '../data/repositories/invoice_repository.dart';
import 'pdf/invoice_pdf_service.dart';
import 'pdf/invoice_pdf_handler.dart';
import 'email_service.dart';

class InvoiceService {
  final InvoiceRepository _repository;
  final FirebaseAuth _auth;
  final FirebaseFirestore _db;

  InvoiceService({
    InvoiceRepository? repository,
    FirebaseAuth? auth,
    FirebaseFirestore? firestore,
  })  : _repository = repository ?? InvoiceRepository(),
        _auth = auth ?? FirebaseAuth.instance,
        _db = firestore ?? FirebaseFirestore.instance;

  String get currentUserId {
    final user = _auth.currentUser;
    if (user == null) throw Exception('User not authenticated');
    return user.uid;
  }

  /// Create a new invoice
  Future<InvoiceModel> createInvoice({
    required String clientId,
    required String clientName,
    required String clientEmail,
    required List<InvoiceItem> items,
    required String currency,
    required double taxRate,
    String? invoiceNumber,
    DateTime? dueDate,
  }) async {
    final userId = currentUserId;
    
    // Calculate totals
    final invoice = InvoiceModel.calculateTotals(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      userId: userId,
      clientId: clientId,
      clientName: clientName,
      clientEmail: clientEmail,
      items: items,
      currency: currency,
      taxRate: taxRate,
      status: 'draft',
      createdAt: Timestamp.now(),
      invoiceNumber: invoiceNumber ?? _generateInvoiceNumber(),
      dueDate: dueDate,
    );

    return _repository.createInvoice(userId, invoice);
  }

  /// Create invoice from existing model (for templates, duplicates, etc.)
  Future<InvoiceModel> createInvoiceWithModel(InvoiceModel invoice) {
    return _repository.createInvoice(currentUserId, invoice);
  }

  /// Get invoice by ID
  Future<InvoiceModel?> getInvoice(String invoiceId) {
    return _repository.getInvoice(currentUserId, invoiceId);
  }

  /// Get all invoices
  Future<List<InvoiceModel>> getInvoices() {
    return _repository.getInvoices(currentUserId);
  }

  /// Stream invoices
  Stream<List<InvoiceModel>> streamInvoices() {
    return _repository.streamInvoices(currentUserId);
  }

  /// Get invoices by status
  Future<List<InvoiceModel>> getInvoicesByStatus(String status) {
    return _repository.getInvoicesByStatus(currentUserId, status);
  }

  /// Stream invoices by status
  Stream<List<InvoiceModel>> streamInvoicesByStatus(String status) {
    return _repository.streamInvoicesByStatus(currentUserId, status);
  }

  /// Update invoice
  Future<void> updateInvoice(InvoiceModel invoice) {
    return _repository.updateInvoice(currentUserId, invoice);
  }

  /// Update invoice status
  Future<void> updateInvoiceStatus(String invoiceId, String newStatus) {
    return _repository.updateInvoiceStatus(currentUserId, invoiceId, newStatus);
  }

  /// Mark as paid
  Future<void> markAsPaid(String invoiceId) {
    return _repository.markInvoiceAsPaid(currentUserId, invoiceId);
  }

  /// Delete invoice
  Future<void> deleteInvoice(String invoiceId) {
    return _repository.deleteInvoice(currentUserId, invoiceId);
  }

  /// Get invoice count
  Future<int> getInvoiceCount(String status) {
    return _repository.getInvoiceCount(currentUserId, status);
  }

  /// Get total revenue
  Future<double> getTotalRevenue() {
    return _repository.getTotalRevenue(currentUserId);
  }

  /// Get pending invoices
  Future<List<InvoiceModel>> getPendingInvoices() {
    return _repository.getPendingInvoices(currentUserId);
  }

  /// Generate invoice number (e.g., INV-2024-001)
  String _generateInvoiceNumber() {
    final year = DateTime.now().year;
    final timestamp = DateTime.now().millisecondsSinceEpoch % 1000;
    return 'INV-$year-${timestamp.toString().padLeft(3, '0')}';
  }

  // ═══════════════════════════════════════════════════════════════
  // PDF GENERATION
  // ═══════════════════════════════════════════════════════════════

  /// Generate PDF bytes for an invoice
  /// 
  /// Returns the invoice as a professional PDF document.
  /// 
  /// Throws: Exception if PDF generation fails
  Future<Uint8List> generatePdfBytes(InvoiceModel invoice) async {
    try {
      final document = await InvoicePdfService.generate(invoice);
      return document.save();
    } catch (e) {
      throw Exception('Failed to generate invoice PDF: $e');
    }
  }

  /// Save invoice PDF to device storage
  /// 
  /// Saves the invoice to Documents/invoices/ folder with timestamp.
  /// Returns the file path if successful.
  /// 
  /// Throws: InvoicePdfException if file operations fail
  Future<String> savePdfToDevice(InvoiceModel invoice) async {
    try {
      await InvoicePdfHandler.saveToFile(invoice);
      return 'Saved to Documents/invoices/${invoice.invoiceNumber ?? invoice.id}.pdf';
    } catch (e) {
      throw Exception('Failed to save invoice PDF: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // EMAIL INTEGRATION
  // ═══════════════════════════════════════════════════════════════

  /// Send invoice via email with optional PDF attachment
  /// 
  /// Sends an invoice email to the client with:
  /// - Professional HTML-formatted message
  /// - Optional PDF attachment (base64 encoded)
  /// - Auto-updates invoice status to 'sent'
  /// 
  /// Parameters:
  /// - invoice: InvoiceModel to send
  /// - attachPdf: Whether to include PDF (default: true)
  /// - customMessage: Custom email body (optional)
  /// 
  /// Throws: Exception if email sending fails
  Future<void> sendInvoiceByEmail(
    InvoiceModel invoice, {
    bool attachPdf = true,
    String? customMessage,
  }) async {
    try {
      // Generate PDF if needed
      Uint8List? pdfBytes;
      String? pdfBase64;
      if (attachPdf) {
        pdfBytes = await generatePdfBytes(invoice);
        pdfBase64 = _bytesToBase64(pdfBytes);
      }

      // Compose professional email
      final invoiceNumber = invoice.invoiceNumber ?? invoice.id;
      final totalFormatted = invoice.total.toStringAsFixed(2);
      
      final subject = 'Invoice $invoiceNumber - ${invoice.currency} $totalFormatted';
      final htmlMessage = customMessage ?? _buildInvoiceEmailHtml(invoice);

      // Send via EmailService
      await EmailService.sendEmail(
        to: invoice.clientEmail,
        subject: subject,
        message: htmlMessage,
      );

      // Update invoice status to 'sent' with timestamp
      final userId = currentUserId;
      await _repository.updateInvoiceStatus(userId, invoice.id, 'sent');

      // Optional: Log email sent in audit trail
      await _logInvoiceAction(
        userId: userId,
        invoiceId: invoice.id,
        action: 'email_sent',
        details: {
          'to': invoice.clientEmail,
          'attachedPdf': attachPdf,
          'timestamp': Timestamp.now(),
        },
      );
    } catch (e) {
      throw Exception('Failed to send invoice email: $e');
    }
  }

  /// Send a follow-up email for unpaid invoice
  /// 
  /// Sends a payment reminder to client.
  /// 
  /// Throws: Exception if email sending fails
  Future<void> sendPaymentReminder(InvoiceModel invoice) async {
    try {
      if (invoice.status == 'paid') {
        throw Exception('Cannot send reminder for already-paid invoice');
      }

      final invoiceNumber = invoice.invoiceNumber ?? invoice.id;
      final dueDate = invoice.dueDate != null
          ? invoice.dueDate!.toLocal().toString().split(' ')[0]
          : 'N/A';
      final total = invoice.total.toStringAsFixed(2);

      final htmlMessage = '''
<html>
  <body style="font-family: Arial, sans-serif; color: #333;">
    <p>Hello ${invoice.clientName},</p>
    
    <p>This is a friendly reminder that payment for invoice <strong>$invoiceNumber</strong> is due.</p>
    
    <div style="background: #f8f9fa; padding: 20px; border-left: 4px solid #ff9800; margin: 20px 0;">
      <strong>Invoice Details:</strong><br>
      Invoice Number: $invoiceNumber<br>
      Amount Due: ${invoice.currency} $total<br>
      Due Date: $dueDate
    </div>
    
    <p>Please arrange payment at your earliest convenience. If you have already paid, please disregard this message.</p>
    
    <p>Thank you for your business!</p>
    
    <p>Best regards,<br>
    ${_auth.currentUser?.displayName ?? 'AuraSphere Pro'}</p>
  </body>
</html>
''';

      final subject = 'Payment Reminder: Invoice $invoiceNumber';
      
      await EmailService.sendEmail(
        to: invoice.clientEmail,
        subject: subject,
        message: htmlMessage,
      );

      // Log reminder sent
      final userId = currentUserId;
      await _logInvoiceAction(
        userId: userId,
        invoiceId: invoice.id,
        action: 'reminder_sent',
        details: {
          'to': invoice.clientEmail,
          'timestamp': Timestamp.now(),
        },
      );
    } catch (e) {
      throw Exception('Failed to send payment reminder: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════════
  // HELPER METHODS
  // ═══════════════════════════════════════════════════════════════

  /// Build professional HTML email for invoice
  String _buildInvoiceEmailHtml(InvoiceModel invoice) {
    final invoiceNumber = invoice.invoiceNumber ?? invoice.id;
    final createdDate = invoice.createdAt.toDate().toString().split(' ')[0];
    final dueDate = invoice.dueDate != null
        ? invoice.dueDate!.toLocal().toString().split(' ')[0]
        : 'N/A';

    final itemsHtml = invoice.items.map((item) {
      return '''
      <tr>
        <td style="padding: 10px; border-bottom: 1px solid #ddd;">${item.description}</td>
        <td style="padding: 10px; border-bottom: 1px solid #ddd; text-align: center;">${item.quantity}</td>
        <td style="padding: 10px; border-bottom: 1px solid #ddd; text-align: right;">${invoice.currency} ${item.unitPrice.toStringAsFixed(2)}</td>
        <td style="padding: 10px; border-bottom: 1px solid #ddd; text-align: right;">${invoice.currency} ${item.total.toStringAsFixed(2)}</td>
      </tr>
      ''';
    }).join();

    return '''
<html>
  <body style="font-family: Arial, sans-serif; color: #333; line-height: 1.6;">
    <table style="width: 100%; max-width: 600px; margin: 0 auto; border-collapse: collapse;">
      <tr>
        <td style="padding: 20px; background: #1e40af; color: white;">
          <h1 style="margin: 0; font-size: 24px;">AURASPHERE PRO</h1>
          <p style="margin: 5px 0 0 0; font-size: 12px;">Professional Invoice Management</p>
        </td>
      </tr>
      <tr>
        <td style="padding: 20px;">
          <p>Hello <strong>${invoice.clientName}</strong>,</p>
          
          <p>Please find your invoice details below:</p>
          
          <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
            <tr style="background: #f8f9fa;">
              <td style="padding: 10px; font-weight: bold;">Invoice #</td>
              <td style="padding: 10px;">$invoiceNumber</td>
            </tr>
            <tr>
              <td style="padding: 10px; font-weight: bold;">Date</td>
              <td style="padding: 10px;">$createdDate</td>
            </tr>
            <tr style="background: #f8f9fa;">
              <td style="padding: 10px; font-weight: bold;">Due Date</td>
              <td style="padding: 10px;">$dueDate</td>
            </tr>
          </table>
          
          <h3 style="margin-top: 20px; margin-bottom: 10px;">Invoice Items</h3>
          <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
            <thead>
              <tr style="background: #1e40af; color: white;">
                <th style="padding: 10px; text-align: left;">Description</th>
                <th style="padding: 10px; text-align: center;">Qty</th>
                <th style="padding: 10px; text-align: right;">Unit Price</th>
                <th style="padding: 10px; text-align: right;">Total</th>
              </tr>
            </thead>
            <tbody>
              $itemsHtml
            </tbody>
          </table>
          
          <table style="width: 100%; border-collapse: collapse; margin: 20px 0;">
            <tr>
              <td style="padding: 10px; text-align: right; font-weight: bold;">Subtotal:</td>
              <td style="padding: 10px; text-align: right;">${invoice.currency} ${invoice.subtotal.toStringAsFixed(2)}</td>
            </tr>
            <tr style="background: #f8f9fa;">
              <td style="padding: 10px; text-align: right; font-weight: bold;">Tax (${(invoice.taxRate * 100).toStringAsFixed(0)}%):</td>
              <td style="padding: 10px; text-align: right;">${invoice.currency} ${invoice.tax.toStringAsFixed(2)}</td>
            </tr>
            <tr style="background: #1e40af; color: white;">
              <td style="padding: 10px; text-align: right; font-weight: bold; font-size: 16px;">Total:</td>
              <td style="padding: 10px; text-align: right; font-weight: bold; font-size: 16px;">${invoice.currency} ${invoice.total.toStringAsFixed(2)}</td>
            </tr>
          </table>
          
          <p style="margin-top: 20px; padding: 10px; background: #f8f9fa; border-left: 4px solid #1e40af;">
            <strong>Thank you for your business!</strong><br>
            If you have any questions about this invoice, please don't hesitate to contact us.
          </p>
          
          <p style="font-size: 12px; color: #666; margin-top: 30px;">
            This email was sent from AuraSphere Pro<br>
            ${_auth.currentUser?.displayName ?? 'Your Company'}<br>
            ${_auth.currentUser?.email ?? 'contact@company.com'}
          </p>
        </td>
      </tr>
    </table>
  </body>
</html>
''';
  }

  /// Convert bytes to base64 string (for PDF attachments)
  String _bytesToBase64(Uint8List bytes) {
    return base64Encode(bytes);
  }

  /// Log invoice actions for audit trail
  Future<void> _logInvoiceAction({
    required String userId,
    required String invoiceId,
    required String action,
    required Map<String, dynamic> details,
  }) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('invoice_audit_log')
          .add({
        'invoiceId': invoiceId,
        'action': action,
        'timestamp': Timestamp.now(),
        ...details,
      });
    } catch (e) {
      // Silently fail — don't interrupt invoice operations
      print('Failed to log invoice action: $e');
    }
  }

  // ===== PDF Generation =====

  /// Generate invoice PDF locally using Dart (no server required)
  Future<Uint8List> generateLocalPdf(InvoiceModel invoice) async {
    try {
      final pdf = await _pdfService.generateLocalPdf(invoice);
      await _logInvoiceAction(
        userId: currentUserId,
        invoiceId: invoice.id,
        action: 'pdf_generated_local',
        details: {'method': 'dart'},
      );
      return pdf;
    } catch (e) {
      print('Failed to generate local PDF: $e');
      rethrow;
    }
  }

  /// Generate PDF with linked expenses summary
  Future<Uint8List> generateLocalPdfWithExpenses(
    InvoiceModel invoice,
    List<dynamic> linkedExpenses,
  ) async {
    try {
      final pdf = await _pdfService.generateLocalPdfWithExpenses(
        invoice,
        linkedExpenses,
      );
      await _logInvoiceAction(
        userId: currentUserId,
        invoiceId: invoice.id,
        action: 'pdf_generated_local_with_expenses',
        details: {'expenseCount': linkedExpenses.length},
      );
      return pdf;
    } catch (e) {
      print('Failed to generate PDF with expenses: $e');
      rethrow;
    }
  }

  // ===== Expense Linking =====

  /// Link an expense to an invoice
  Future<void> linkExpenseToInvoice(
    String invoiceId,
    String expenseId,
  ) async {
    try {
      final userId = currentUserId;

      // Update invoice to add expense ID
      await _db.collection('invoices').doc(invoiceId).update({
        'linkedExpenseIds': FieldValue.arrayUnion([expenseId]),
        'updatedAt': Timestamp.now(),
      });

      // Update expense to reference invoice
      await _db.collection('expenses').doc(expenseId).update({
        'invoiceId': invoiceId,
        'updatedAt': Timestamp.now(),
      });

      await _logInvoiceAction(
        userId: userId,
        invoiceId: invoiceId,
        action: 'expense_linked',
        details: {'expenseId': expenseId},
      );
    } catch (e) {
      print('Failed to link expense to invoice: $e');
      rethrow;
    }
  }

  /// Unlink an expense from an invoice
  Future<void> unlinkExpenseFromInvoice(
    String invoiceId,
    String expenseId,
  ) async {
    try {
      final userId = currentUserId;

      // Update invoice to remove expense ID
      await _db.collection('invoices').doc(invoiceId).update({
        'linkedExpenseIds': FieldValue.arrayRemove([expenseId]),
        'updatedAt': Timestamp.now(),
      });

      // Clear invoice reference from expense
      await _db.collection('expenses').doc(expenseId).update({
        'invoiceId': null,
        'updatedAt': Timestamp.now(),
      });

      await _logInvoiceAction(
        userId: userId,
        invoiceId: invoiceId,
        action: 'expense_unlinked',
        details: {'expenseId': expenseId},
      );
    } catch (e) {
      print('Failed to unlink expense from invoice: $e');
      rethrow;
    }
  }

  /// Get all expenses linked to an invoice
  Future<List<dynamic>> getLinkedExpenses(String invoiceId) async {
    try {
      final invoiceDoc = await _db.collection('invoices').doc(invoiceId).get();
      if (!invoiceDoc.exists) return [];

      final linkedExpenseIds =
          List<String>.from(invoiceDoc.get('linkedExpenseIds') ?? []);

      if (linkedExpenseIds.isEmpty) return [];

      final expenses = <Map<String, dynamic>>[];
      for (final expenseId in linkedExpenseIds) {
        final expenseDoc =
            await _db.collection('expenses').doc(expenseId).get();
        if (expenseDoc.exists) {
          expenses.add(expenseDoc.data() as Map<String, dynamic>);
        }
      }

      return expenses;
    } catch (e) {
      print('Failed to get linked expenses: $e');
      rethrow;
    }
  }

  /// Watch linked expenses for an invoice in real-time
  Stream<List<dynamic>> watchLinkedExpenses(String invoiceId) {
    return _db
        .collection('invoices')
        .doc(invoiceId)
        .snapshots()
        .asyncExpand((invoiceSnap) {
      final linkedIds =
          List<String>.from(invoiceSnap.get('linkedExpenseIds') ?? []);

      if (linkedIds.isEmpty) {
        return Stream.value([]);
      }

      return _db
          .collection('expenses')
          .where(FieldPath.documentId, whereIn: linkedIds)
          .snapshots()
          .map((snapshot) =>
              snapshot.docs.map((doc) => doc.data()).toList());
    });
  }

  /// Calculate total from linked expenses
  Future<double> calculateTotalFromExpenses(String invoiceId) async {
    try {
      final expenses = await getLinkedExpenses(invoiceId);
      double total = 0;
      for (final expense in expenses) {
        if (expense is Map && expense.containsKey('amount')) {
          total += (expense['amount'] as num).toDouble();
        }
      }
      return total;
    } catch (e) {
      print('Failed to calculate total from expenses: $e');
      rethrow;
    }
  }

  /// Sync invoice total with linked expenses
  Future<void> syncInvoiceTotalFromExpenses(String invoiceId) async {
    try {
      final expenseTotal = await calculateTotalFromExpenses(invoiceId);

      await _db.collection('invoices').doc(invoiceId).update({
        'syncedExpenseTotal': expenseTotal,
        'syncedAt': Timestamp.now(),
      });
    } catch (e) {
      print('Failed to sync invoice total with expenses: $e');
      rethrow;
    }
  }
}
