import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InvoiceAuditEntry {
  final String id;
  final String invoiceNumber;
  final int number;
  final DateTime allocatedAt;
  final String allocatedBy;
  final String? invoiceId;
  final Map<String, dynamic>? context;

  InvoiceAuditEntry({
    required this.id,
    required this.invoiceNumber,
    required this.number,
    required this.allocatedAt,
    required this.allocatedBy,
    this.invoiceId,
    this.context,
  });

  factory InvoiceAuditEntry.fromDoc(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>? ?? {};
    return InvoiceAuditEntry(
      id: doc.id,
      invoiceNumber: data['invoiceNumber'] ?? '',
      number: (data['number'] ?? 0) is int
          ? data['number'] as int
          : int.tryParse('${data['number']}') ?? 0,
      allocatedAt: (data['allocatedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      allocatedBy: data['allocatedBy'] ?? '',
      invoiceId: data['invoiceId'] as String?,
      context: (data['context'] as Map?)?.cast<String, dynamic>(),
    );
  }
}

class InvoiceAuditService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Stream<List<InvoiceAuditEntry>> streamAuditEntries({int limit = 200}) {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      // Return empty stream if not logged in
      return const Stream<List<InvoiceAuditEntry>>.empty();
    }
    return _db
        .collection('users')
        .doc(uid)
        .collection('invoice_sequence')
        .orderBy('allocatedAt', descending: true)
        .limit(limit)
        .snapshots()
        .map((snap) => snap.docs.map(InvoiceAuditEntry.fromDoc).toList());
  }

  /// Retrieves invoice audit history for a user
  /// Returns list of audit records from invoice_sequence collection
  Future<List<Map<String, dynamic>>> getAuditHistory(String uid) async {
    try {
      final query = await _db
          .collection('users')
          .doc(uid)
          .collection('invoice_sequence')
          .orderBy('allocatedAt', descending: true)
          .limit(100)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'invoiceNumber': data['invoiceNumber'] as String? ?? 'N/A',
          'number': data['number'] as int? ?? 0,
          'allocatedAt': data['allocatedAt'] as Timestamp?,
          'allocatedBy': data['allocatedBy'] as String?,
          'context': data['context'] as Map<String, dynamic>?,
          'invoiceId': data['invoiceId'] as String?,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load audit history: ${e.toString()}');
    }
  }

  /// Retrieves audit history filtered by date range
  Future<List<Map<String, dynamic>>> getAuditHistoryByDateRange(
    String uid,
    DateTime startDate,
    DateTime endDate,
  ) async {
    try {
      final query = await _db
          .collection('users')
          .doc(uid)
          .collection('invoice_sequence')
          .where('allocatedAt',
              isGreaterThanOrEqualTo: Timestamp.fromDate(startDate))
          .where('allocatedAt', isLessThanOrEqualTo: Timestamp.fromDate(endDate))
          .orderBy('allocatedAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'invoiceNumber': data['invoiceNumber'] as String? ?? 'N/A',
          'number': data['number'] as int? ?? 0,
          'allocatedAt': data['allocatedAt'] as Timestamp?,
          'allocatedBy': data['allocatedBy'] as String?,
          'context': data['context'] as Map<String, dynamic>?,
          'invoiceId': data['invoiceId'] as String?,
        };
      }).toList();
    } catch (e) {
      throw Exception(
          'Failed to load audit history for date range: ${e.toString()}');
    }
  }

  /// Retrieves a specific audit record by invoice number
  Future<Map<String, dynamic>?> getAuditByInvoiceNumber(
    String uid,
    String invoiceNumber,
  ) async {
    try {
      final query = await _db
          .collection('users')
          .doc(uid)
          .collection('invoice_sequence')
          .where('invoiceNumber', isEqualTo: invoiceNumber)
          .limit(1)
          .get();

      if (query.docs.isEmpty) {
        return null;
      }

      final doc = query.docs.first;
      final data = doc.data();
      return {
        'id': doc.id,
        'invoiceNumber': data['invoiceNumber'] as String? ?? 'N/A',
        'number': data['number'] as int? ?? 0,
        'allocatedAt': data['allocatedAt'] as Timestamp?,
        'allocatedBy': data['allocatedBy'] as String?,
        'context': data['context'] as Map<String, dynamic>?,
        'invoiceId': data['invoiceId'] as String?,
      };
    } catch (e) {
      throw Exception('Failed to load audit record: ${e.toString()}');
    }
  }

  /// Retrieves audit records by invoice ID
  Future<List<Map<String, dynamic>>> getAuditByInvoiceId(
    String uid,
    String invoiceId,
  ) async {
    try {
      final query = await _db
          .collection('users')
          .doc(uid)
          .collection('invoice_sequence')
          .where('invoiceId', isEqualTo: invoiceId)
          .orderBy('allocatedAt', descending: true)
          .get();

      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'invoiceNumber': data['invoiceNumber'] as String? ?? 'N/A',
          'number': data['number'] as int? ?? 0,
          'allocatedAt': data['allocatedAt'] as Timestamp?,
          'allocatedBy': data['allocatedBy'] as String?,
          'context': data['context'] as Map<String, dynamic>?,
          'invoiceId': data['invoiceId'] as String?,
        };
      }).toList();
    } catch (e) {
      throw Exception('Failed to load audit records for invoice: ${e.toString()}');
    }
  }

  /// Retrieves total count of audit records for a user
  Future<int> getAuditCount(String uid) async {
    try {
      final query = await _db
          .collection('users')
          .doc(uid)
          .collection('invoice_sequence')
          .count()
          .get();

      return query.count ?? 0;
    } catch (e) {
      throw Exception('Failed to get audit count: ${e.toString()}');
    }
  }

  /// Streams audit history for real-time updates
  Stream<List<Map<String, dynamic>>> watchAuditHistory(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('invoice_sequence')
        .orderBy('allocatedAt', descending: true)
        .limit(100)
        .snapshots()
        .map((query) {
      return query.docs.map((doc) {
        final data = doc.data();
        return {
          'id': doc.id,
          'invoiceNumber': data['invoiceNumber'] as String? ?? 'N/A',
          'number': data['number'] as int? ?? 0,
          'allocatedAt': data['allocatedAt'] as Timestamp?,
          'allocatedBy': data['allocatedBy'] as String?,
          'context': data['context'] as Map<String, dynamic>?,
          'invoiceId': data['invoiceId'] as String?,
        };
      }).toList();
    }).handleError((e) {
      throw Exception('Failed to watch audit history: ${e.toString()}');
    });
  }
}
