import 'firestore_service.dart';
import '../models/invoice_model.dart';
import '../config/constants.dart';

class InvoiceService {
  final FirestoreService _firestore = FirestoreService();

  Future<List<Invoice>> getInvoices(String userId) async {
    final snapshot = await _firestore.getCollection(Constants.firestoreInvoicesCollection);
    return snapshot.docs.map((doc) => Invoice.fromJson(doc.data() as Map<String, dynamic>)).toList();
  }

  Future<void> createInvoice(Invoice invoice) async {
    await _firestore.setDocument(
      Constants.firestoreInvoicesCollection,
      invoice.id,
      invoice.toJson(),
    );
  }
}
