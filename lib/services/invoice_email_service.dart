import 'package:cloud_functions/cloud_functions.dart';

class InvoiceEmailService {
  static Future<bool> sendInvoice(String invoiceId) async {
    try {
      final callable =
          FirebaseFunctions.instance.httpsCallable('sendInvoiceEmail');

      final result = await callable.call({"invoiceId": invoiceId});

      return result.data["success"] == true;
    } catch (e) {
      print("Error sending invoice email: $e");
      return false;
    }
  }
}
