// lib/services/payments/stripe_service.dart
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';

class StripeService {
  static final HttpsCallable _createCheckout = FirebaseFunctions.instance.httpsCallable('createCheckoutSession');

  /// Request a checkout session for a given invoiceId
  static Future<Map<String, dynamic>> createCheckoutSession({
    required String invoiceId,
    required String successUrl,
    required String cancelUrl,
  }) async {
    final res = await _createCheckout.call({
      'invoiceId': invoiceId,
      'successUrl': successUrl,
      'cancelUrl': cancelUrl,
    });
    return Map<String, dynamic>.from(res.data as Map);
  }

  static Future<void> openCheckoutUrl(String url) async {
    final uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      throw Exception('Could not open checkout url');
    }
  }
}
