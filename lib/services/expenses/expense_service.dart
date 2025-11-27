import 'dart:convert';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../models/expense_model.dart';
import '../tax_service.dart';

class ExpenseService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseStorage _storage = FirebaseStorage.instance;

  String get uid => _auth.currentUser!.uid;

  CollectionReference userExpensesRef(String userId) =>
      _db.collection('users').doc(userId).collection('expenses');

  /// Watch user's expenses in real-time, ordered by creation date (newest first)
  Stream<List<ExpenseModel>> watchExpenses({String? userId}) {
    final id = userId ?? uid;
    return userExpensesRef(id)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((d) => ExpenseModel.fromDoc(d)).toList());
  }

  /// Create a new expense draft with auto-calculated VAT
  /// 
  /// If [vatRate] is not provided, uses user's country VAT rate
  /// If [vat] is not provided, calculates from amount * vatRate
  Future<ExpenseModel> createExpenseDraft({
    required String merchant,
    DateTime? date,
    required double amount,
    double? vat,
    double? vatRate,
    String currency = 'EUR',
    String category = 'General',
    String paymentMethod = 'card',
    List<String>? photoUrls,
    Map<String, dynamic>? rawOcr,
    String? projectId,
  }) async {
    final id = userExpensesRef(uid).doc().id;
    
    // Use provided VAT rate or detect from user's country
    final effectiveVatRate = 
        vatRate ?? TaxService.detectVATRate(_auth.currentUser?.metadata.creationTime?.toString() ?? 'US');
    
    // Calculate VAT amount if not provided
    final vatAmount = vat ?? (amount * effectiveVatRate);

    final expense = ExpenseModel(
      id: id,
      userId: uid,
      projectId: projectId,
      merchant: merchant,
      date: date,
      amount: amount,
      vat: vatAmount,
      vatRate: effectiveVatRate,
      currency: currency,
      category: category,
      paymentMethod: paymentMethod,
      photoUrls: photoUrls ?? [],
      status: ExpenseStatus.pending_approval,
      rawOcr: rawOcr,
      audit: {
        'createdBy': uid,
        'createdAt': DateTime.now().toIso8601String(),
      },
    );

    await userExpensesRef(uid).doc(id).set(expense.toMap());
    return expense;
  }

  /// Upload a photo and attach it to an expense
  /// 
  /// Stores in `expenses/{userId}/{expenseId}/{timestamp}.jpg`
  /// and updates the expense's photoUrls array
  Future<void> uploadPhotoAndAttach(
    String expenseId,
    Uint8List bytes, {
    String contentType = 'image/jpeg',
  }) async {
    final path = 'expenses/$uid/$expenseId/${DateTime.now().millisecondsSinceEpoch}.jpg';
    final ref = _storage.ref().child(path);

    await ref.putData(
      bytes,
      SettableMetadata(contentType: contentType),
    );

    final url = await ref.getDownloadURL();

    await userExpensesRef(uid).doc(expenseId).update({
      'photoUrls': FieldValue.arrayUnion([url]),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Update an existing expense
  /// 
  /// Merges changes without overwriting other fields
  /// Automatically creates history entry and audit log
  Future<void> updateExpense(ExpenseModel expense) async {
    // Fetch current state for history
    final currentDoc = await userExpensesRef(expense.userId).doc(expense.id).get();
    final currentExpense = ExpenseModel.fromDoc(currentDoc);

    final map = expense.toMap();
    map['updatedAt'] = FieldValue.serverTimestamp();

    // Update document
    await userExpensesRef(expense.userId).doc(expense.id).set(
      map,
      SetOptions(merge: true),
    );

    // Create history entry if changes occurred
    await _createHistoryEntry(
      expense.id,
      currentExpense,
      expense,
      uid,
    );

    // Create audit entry for the update
    await _createDetailedAuditEntry(
      expense.id,
      action: 'updated',
      actor: uid,
      notes: 'Expense details updated',
    );
  }

  /// Change expense status with optional approval info
  /// 
  /// Automatically creates an audit trail entry and history snapshot
  Future<void> changeStatus(
    String expenseId,
    ExpenseStatus status, {
    String? approverId,
    String? note,
  }) async {
    // Fetch current expense
    final currentDoc = await userExpensesRef(uid).doc(expenseId).get();
    final currentExpense = ExpenseModel.fromDoc(currentDoc);

    final updateMap = {
      'status': status.toString().split('.').last,
      'updatedAt': FieldValue.serverTimestamp(),
    };

    if (approverId != null) updateMap['approverId'] = approverId;
    if (note != null) updateMap['approvedNote'] = note;

    // Update main expense document
    await userExpensesRef(uid).doc(expenseId).update(updateMap);

    // Fetch updated expense for history
    final updatedDoc = await userExpensesRef(uid).doc(expenseId).get();
    final updatedExpense = ExpenseModel.fromDoc(updatedDoc);

    // Create history entry
    await _createHistoryEntry(
      expenseId,
      currentExpense,
      updatedExpense,
      approverId ?? uid,
    );

    // Create detailed audit entry
    await _createDetailedAuditEntry(
      expenseId,
      action: status.toString().split('.').last,
      actor: approverId ?? uid,
      notes: note,
      metadata: {
        'previousStatus': currentExpense.status.toString().split('.').last,
        'newStatus': status.toString().split('.').last,
      },
    );
  }

  /// Link an expense to an invoice
  Future<void> linkToInvoice(String expenseId, String invoiceId) async {
    await userExpensesRef(uid).doc(expenseId).update({
      'invoiceId': invoiceId,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Import expenses from CSV content
  /// 
  /// Expected columns (case-insensitive):
  /// - merchant, date, amount, currency, category, vatrate, paymentmethod
  /// 
  /// Returns list of created ExpenseModels
  Future<List<ExpenseModel>> importCsvRows(String csvContent) async {
    final lines = LineSplitter.split(csvContent).toList();
    if (lines.length < 2) return [];

    // Parse header row
    final headers = lines.first
        .split(',')
        .map((h) => h.trim().toLowerCase())
        .toList();

    final rows = lines.sublist(1);
    final List<ExpenseModel> imported = [];

    for (final row in rows) {
      if (row.trim().isEmpty) continue;

      final cols = row.split(',');
      final map = <String, String>{};

      // Map columns to headers
      for (int i = 0; i < headers.length && i < cols.length; i++) {
        map[headers[i]] = cols[i].trim();
      }

      // Extract and parse values
      final amount = double.tryParse(
            map['amount']?.replaceAll('"', '') ?? '',
          ) ??
          0.0;
      final currency = map['currency'] ?? 'EUR';
      final merchant = map['merchant'] ?? 'Imported';
      final date = DateTime.tryParse(map['date'] ?? '');
      final category = map['category'] ?? 'General';
      final vatRate = double.tryParse(map['vatrate'] ?? '') ??
          TaxService.detectVATRate('US');

      final id = userExpensesRef(uid).doc().id;
      final expense = ExpenseModel(
        id: id,
        userId: uid,
        merchant: merchant,
        date: date,
        amount: amount,
        vat: amount * vatRate,
        vatRate: vatRate,
        currency: currency,
        category: category,
        paymentMethod: map['paymentmethod'] ?? 'unknown',
        photoUrls: [],
      );

      imported.add(expense);
    }

    // Bulk write all imported expenses
    final batch = _db.batch();
    for (final expense in imported) {
      final ref = userExpensesRef(uid).doc(expense.id);
      batch.set(ref, expense.toMap());
    }
    await batch.commit();

    return imported;
  }

  /// Generate monthly expense report
  /// 
  /// Returns: {year, month, total, totalVat, byCategory, count}
  Future<Map<String, dynamic>> generateMonthlyReport(
    int year,
    int month,
  ) async {
    final start = DateTime(year, month, 1);
    final end = DateTime(year, month + 1, 1);

    final snap = await userExpensesRef(uid)
        .where('createdAt',
            isGreaterThanOrEqualTo: Timestamp.fromDate(start))
        .where('createdAt', isLessThan: Timestamp.fromDate(end))
        .get();

    double total = 0;
    double totalVat = 0;
    final categoryMap = <String, double>{};

    for (final doc in snap.docs) {
      final expense = ExpenseModel.fromDoc(doc);
      total += expense.amount;
      totalVat += (expense.vat ?? 0);
      categoryMap[expense.category] =
          (categoryMap[expense.category] ?? 0) + expense.amount;
    }

    return {
      'year': year,
      'month': month,
      'total': total,
      'totalVat': totalVat,
      'byCategory': categoryMap,
      'count': snap.docs.length,
    };
  }

  /// Get expenses by status
  Future<List<ExpenseModel>> getExpensesByStatus(ExpenseStatus status) async {
    final snap = await userExpensesRef(uid)
        .where('status', isEqualTo: status.toString().split('.').last)
        .orderBy('createdAt', descending: true)
        .get();

    return snap.docs.map((d) => ExpenseModel.fromDoc(d)).toList();
  }

  /// Get total expenses for a category
  Future<double> getTotalByCategory(String category) async {
    final snap = await userExpensesRef(uid)
        .where('category', isEqualTo: category)
        .get();

    double total = 0;
    for (final doc in snap.docs) {
      final expense = ExpenseModel.fromDoc(doc);
      total += expense.amount;
    }
    return total;
  }

  /// Delete an expense
  Future<void> deleteExpense(String expenseId) async {
    await userExpensesRef(uid).doc(expenseId).delete();
  }

  /// Get audit trail for an expense
  /// 
  /// Returns list of audit entries ordered by timestamp (newest first)
  Future<List<Map<String, dynamic>>> getAuditTrail(String expenseId) async {
    final snap = await userExpensesRef(uid)
        .doc(expenseId)
        .collection('audit')
        .orderBy('ts', descending: true)
        .get();

    return snap.docs
        .map((doc) => {
              ...doc.data(),
              'id': doc.id,
            })
        .toList();
  }

  /// Get expense version history
  /// 
  /// Returns list of historical versions ordered by change timestamp
  /// Each version includes the previous state before the change
  Future<List<Map<String, dynamic>>> getExpenseHistory(
    String expenseId,
  ) async {
    final snap = await userExpensesRef(uid)
        .doc(expenseId)
        .collection('_history')
        .orderBy('changedAt', descending: true)
        .get();

    return snap.docs
        .map((doc) => {
              ...doc.data(),
              'id': doc.id,
            })
        .toList();
  }

  /// Watch expense history in real-time
  Stream<List<Map<String, dynamic>>> watchExpenseHistory(
    String expenseId,
  ) {
    return userExpensesRef(uid)
        .doc(expenseId)
        .collection('_history')
        .orderBy('changedAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((doc) => {
                  ...doc.data(),
                  'id': doc.id,
                })
            .toList());
  }

  /// Create a version snapshot in history
  /// 
  /// Tracks what changed and by whom
  /// Called automatically on update
  Future<void> _createHistoryEntry(
    String expenseId,
    ExpenseModel before,
    ExpenseModel after,
    String? changedBy,
  ) async {
    final changes = <String, Map<String, dynamic>>{};

    // Compare all fields
    if (before.merchant != after.merchant) {
      changes['merchant'] = {
        'before': before.merchant,
        'after': after.merchant,
      };
    }
    if (before.amount != after.amount) {
      changes['amount'] = {
        'before': before.amount,
        'after': after.amount,
      };
    }
    if (before.vat != after.vat) {
      changes['vat'] = {
        'before': before.vat,
        'after': after.vat,
      };
    }
    if (before.vatRate != after.vatRate) {
      changes['vatRate'] = {
        'before': before.vatRate,
        'after': after.vatRate,
      };
    }
    if (before.currency != after.currency) {
      changes['currency'] = {
        'before': before.currency,
        'after': after.currency,
      };
    }
    if (before.category != after.category) {
      changes['category'] = {
        'before': before.category,
        'after': after.category,
      };
    }
    if (before.status != after.status) {
      changes['status'] = {
        'before': before.status.toString().split('.').last,
        'after': after.status.toString().split('.').last,
      };
    }
    if (before.date != after.date) {
      changes['date'] = {
        'before': before.date?.toIso8601String(),
        'after': after.date?.toIso8601String(),
      };
    }
    if (before.paymentMethod != after.paymentMethod) {
      changes['paymentMethod'] = {
        'before': before.paymentMethod,
        'after': after.paymentMethod,
      };
    }
    if (before.projectId != after.projectId) {
      changes['projectId'] = {
        'before': before.projectId,
        'after': after.projectId,
      };
    }
    if (before.invoiceId != after.invoiceId) {
      changes['invoiceId'] = {
        'before': before.invoiceId,
        'after': after.invoiceId,
      };
    }

    // Only create entry if there are changes
    if (changes.isNotEmpty) {
      await userExpensesRef(uid)
          .doc(expenseId)
          .collection('_history')
          .add({
            'changes': changes,
            'changedBy': changedBy ?? uid,
            'changedAt': FieldValue.serverTimestamp(),
            'previousSnapshot': before.toMap(),
            'newSnapshot': after.toMap(),
          });
    }
  }

  /// Create detailed audit entry
  /// 
  /// Logs action, who did it, timestamp, and optional notes
  Future<void> _createDetailedAuditEntry(
    String expenseId, {
    required String action,
    required String actor,
    String? notes,
    Map<String, dynamic>? metadata,
  }) async {
    await userExpensesRef(uid)
        .doc(expenseId)
        .collection('audit')
        .add({
          'action': action,
          'actor': actor,
          'notes': notes ?? '',
          'metadata': metadata ?? {},
          'ts': FieldValue.serverTimestamp(),
          'ipAddress': 'client', // Could capture from server
          'userAgent': 'flutter_app',
        });
  }

  /// Get audit summary for an expense
  /// 
  /// Returns aggregated audit information
  Future<Map<String, dynamic>> getAuditSummary(String expenseId) async {
    final auditTrail = await getAuditTrail(expenseId);
    final expense = await userExpensesRef(uid).doc(expenseId).get();
    final data = expense.data() as Map<String, dynamic>;

    return {
      'expenseId': expenseId,
      'createdAt': data['createdAt'],
      'updatedAt': data['updatedAt'],
      'createdBy': data['userId'],
      'approverId': data['approverId'],
      'currentStatus': data['status'],
      'totalChanges': auditTrail.length,
      'lastModified': auditTrail.isNotEmpty ? auditTrail.first['ts'] : null,
      'auditTrail': auditTrail,
    };
  }

  /// Export audit trail as JSON
  Future<String> exportAuditTrail(String expenseId) async {
    final trail = await getAuditTrail(expenseId);
    return jsonEncode(trail);
  }
}
