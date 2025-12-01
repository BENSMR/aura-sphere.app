// lib/services/invoice/invoice_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../../models/invoice_model.dart' show Invoice;

class InvoiceService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  CollectionReference _invoicesRef(String uid) =>
      _db.collection('users').doc(uid).collection('invoices');

  Future<String> createInvoiceDraft(Invoice invoice) async {
    final uid = _auth.currentUser!.uid;
    final docRef = await _invoicesRef(uid).add(invoice.toFirestore());
    return docRef.id;
  }

  Future<void> saveInvoice(String id, Invoice invoice) async {
    final uid = _auth.currentUser!.uid;
    await _invoicesRef(uid)
        .doc(id)
        .set(invoice.toFirestore(), SetOptions(merge: true));
  }

  Stream<List<Invoice>> watchInvoices() {
    final uid = _auth.currentUser!.uid;
    return _invoicesRef(uid)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs
            .map((d) => Invoice.fromJson(
                {...(d.data() as Map<String, dynamic>), 'id': d.id}))
            .toList());
  }

  Future<void> markAsPaid(String id,
      {String? paymentIntentId, double? paidAmount}) async {
    final uid = _auth.currentUser!.uid;
    final payload = {
      'paymentStatus': 'paid',
      'paymentVerified': true,
      'lastPaymentIntentId': paymentIntentId ?? '',
      'paidAmount': paidAmount ?? FieldValue.delete(),
      'paidAt': FieldValue.serverTimestamp(),
    };
    await _invoicesRef(uid).doc(id).set(payload, SetOptions(merge: true));
  }

  /// Generate invoice number (simple auto-increment stored in meta)
  Future<String> generateInvoiceNumber() async {
    final uid = _auth.currentUser!.uid;
    final counterRef =
        _db.collection('users').doc(uid).collection('meta').doc('counters');

    // atomic increment of invoice counter
    final nextNumber = await _db.runTransaction<int>((tx) async {
      final snap = await tx.get(counterRef);
      if (!snap.exists) {
        tx.set(counterRef, {'invoiceCounter': 2}, SetOptions(merge: true));
        return 1;
      } else {
        final current = (snap.data()!['invoiceCounter'] ?? 1);
        final next = (current is int) ? current : int.parse(current.toString());
        tx.update(counterRef, {'invoiceCounter': next + 1});
        return next;
      }
    });

    // read business prefix (safe read, not part of transaction)
    final businessDoc = await _db.collection('users').doc(uid).collection('meta').doc('business').get();
    String prefix = 'AURA-';
    if (businessDoc.exists) {
      final bp = businessDoc.data()!;
      if (bp.containsKey('invoicePrefix') && (bp['invoicePrefix'] as String).trim().isNotEmpty) {
        prefix = (bp['invoicePrefix'] as String).trim();
      }
    }

    final padded = nextNumber.toString().padLeft(5, '0');
    return '$prefix$padded';
  }

  /// Create a Stripe Checkout Session via callable Cloud Function and return the payment URL
  Future<String> createPaymentLink(String invoiceId, {String? successUrl, String? cancelUrl}) async {
    final functions = FirebaseFunctions.instance;
    try {
      final callable = functions.httpsCallable('createCheckoutSession');
      final result = await callable.call({
        'invoiceId': invoiceId,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
      });

      final data = result.data as Map<String, dynamic>?;
      if (data == null || data['url'] == null) {
        throw Exception('Invalid response from payment function');
      }
      return data['url'] as String;
    } catch (e) {
      rethrow;
    }
  }

  /// Request server to generate and return signed receipt URL
  Future<String?> generateReceiptAndGetUrl(String invoiceId) async {
    try {
      final functions = FirebaseFunctions.instance;
      final callable = functions.httpsCallable('generateInvoiceReceipt');
      final res = await callable.call({'invoiceId': invoiceId});
      final data = res.data as Map<String, dynamic>?;
      return data != null ? (data['url'] as String?) : null;
    } catch (e) {
      rethrow;
    }
  }
}
