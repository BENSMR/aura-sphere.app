/// Stripe Payment Integration Examples
/// 
/// This file demonstrates how to integrate Stripe payment processing
/// with your invoice application using the createPaymentLink() method.

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../models/invoice_model.dart' show Invoice;
import '../../services/invoice/invoice_service.dart';

/// Example 1: Basic Payment Button
/// Add this to an invoice detail screen
class PayNowButtonExample extends StatefulWidget {
  final String invoiceId;
  final Invoice invoice;

  const PayNowButtonExample({
    Key? key,
    required this.invoiceId,
    required this.invoice,
  }) : super(key: key);

  @override
  State<PayNowButtonExample> createState() => _PayNowButtonExampleState();
}

class _PayNowButtonExampleState extends State<PayNowButtonExample> {
  final InvoiceService _invoiceService = InvoiceService();
  bool _isProcessing = false;

  /// Handle payment button tap
  /// Creates Stripe checkout session and opens payment link
  Future<void> _handlePayNow() async {
    if (_isProcessing) return;

    setState(() => _isProcessing = true);

    try {
      // Show loading dialog
      if (!mounted) return;
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: const Text('Creating Payment Link'),
          content: const SizedBox(
            height: 50,
            child: Center(child: CircularProgressIndicator()),
          ),
        ),
      );

      // Create payment link via Cloud Function
      final paymentUrl = await _invoiceService.createPaymentLink(
        widget.invoiceId,
        successUrl: 'https://yourdomain.com/invoice/success?id=${widget.invoiceId}',
        cancelUrl: 'https://yourdomain.com/invoice/cancel?id=${widget.invoiceId}',
      );

      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog

      if (paymentUrl != null && paymentUrl.isNotEmpty) {
        // Open Stripe checkout in browser
        await launchUrl(
          Uri.parse(paymentUrl),
          mode: LaunchMode.externalApplication,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Opening payment page in browser...'),
              duration: Duration(seconds: 2),
            ),
          );
        }
      } else {
        throw Exception('Failed to create payment link');
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context); // Close loading dialog if still open

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: ${e.toString()}'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isProcessing = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isProcessing ? null : _handlePayNow,
      icon: _isProcessing
          ? const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.credit_card),
      label: Text(_isProcessing ? 'Processing...' : 'Pay Now'),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 24),
      ),
    );
  }
}

/// Example 2: Minimal Payment Integration
/// Use this pattern in any widget - matches your exact code snippet
class MinimalPaymentExample {
  static Future<void> createPaymentAndOpen({
    required String invoiceId,
    required String? successUrl,
    required String? cancelUrl,
  }) async {
    // This is your exact code pattern:
    final svc = InvoiceService();
    final paymentUrl = await svc.createPaymentLink(
      invoiceId,
      successUrl: successUrl ?? 'https://yourdomain.com/success',
      cancelUrl: cancelUrl ?? 'https://yourdomain.com/cancel',
    );
    
    // Open in browser if URL is valid
    if (paymentUrl != null && paymentUrl.isNotEmpty) {
      try {
        if (await canLaunchUrl(Uri.parse(paymentUrl))) {
          await launchUrl(
            Uri.parse(paymentUrl),
            mode: LaunchMode.externalApplication,
          );
        } else {
          print('Could not launch payment URL: $paymentUrl');
        }
      } catch (e) {
        print('Error launching URL: $e');
      }
    } else {
      print('Payment URL is null or empty');
    }
  }
}

/// Example 3: Payment with Custom Error Handling
/// More robust error handling for production use
class RobustPaymentExample {
  static Future<String?> createPaymentLinkWithRetry({
    required String invoiceId,
    String? successUrl,
    String? cancelUrl,
    int maxRetries = 3,
  }) async {
    final svc = InvoiceService();
    
    for (int i = 0; i < maxRetries; i++) {
      try {
        final url = await svc.createPaymentLink(
          invoiceId,
          successUrl: successUrl,
          cancelUrl: cancelUrl,
        );
        
        if (url != null && url.isNotEmpty) {
          return url;
        }
      } catch (e) {
        print('Attempt ${i + 1} failed: $e');
        if (i < maxRetries - 1) {
          // Wait before retry
          await Future.delayed(const Duration(seconds: 1));
        }
      }
    }
    
    return null;
  }
}

/// Example 4: Invoice Listing with Payment Option
/// Show payment buttons next to invoices
class InvoiceListWithPaymentExample extends StatelessWidget {
  final List<Invoice> invoices;

  const InvoiceListWithPaymentExample({
    Key? key,
    required this.invoices,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      itemCount: invoices.length,
      itemBuilder: (context, index) {
        final invoice = invoices[index];
        final isPaid = invoice.paymentStatus == 'paid';

        return Card(
          margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          child: ListTile(
            title: Text(invoice.invoiceNumber),
            subtitle: Text(
              '${invoice.amount.toStringAsFixed(2)} ${invoice.currency}',
            ),
            trailing: isPaid
                ? const Icon(Icons.check_circle, color: Colors.green)
                : SizedBox(
                    width: 100,
                    child: PayNowButtonExample(
                      invoiceId: invoice.id,
                      invoice: invoice,
                    ),
                  ),
          ),
        );
      },
    );
  }
}

/// Example 5: Complete Usage Pattern for Widgets
/// 
/// ```dart
/// class MyInvoiceScreen extends StatelessWidget {
///   final String invoiceId;
///   final Invoice invoice;
/// 
///   const MyInvoiceScreen({
///     required this.invoiceId,
///     required this.invoice,
///   });
/// 
///   @override
///   Widget build(BuildContext context) {
///     return Scaffold(
///       appBar: AppBar(title: const Text('Invoice Details')),
///       body: Column(
///         children: [
///           // Invoice details here
///           Text('Invoice: ${invoice.invoiceNumber}'),
///           Text('Amount: ${invoice.amount} ${invoice.currency}'),
///           
///           // Payment button
///           if (invoice.paymentStatus != 'paid')
///             PayNowButtonExample(
///               invoiceId: invoiceId,
///               invoice: invoice,
///             ),
///         ],
///       ),
///     );
///   }
/// }
/// ```

// END OF EXAMPLES
