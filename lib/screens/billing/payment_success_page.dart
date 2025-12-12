import 'package:flutter/material.dart';
import '../../services/deep_link_service.dart';
import '../../services/wallet_service.dart';

/// Page shown after payment redirects back from Stripe.
/// Waits for webhook to credit tokens, shows loading → success/error.
class PaymentSuccessPage extends StatefulWidget {
  final String sessionId;
  final DeepLinkService deepLinkService;

  const PaymentSuccessPage({
    super.key,
    required this.sessionId,
    required this.deepLinkService,
  });

  @override
  State<PaymentSuccessPage> createState() => _PaymentSuccessPageState();
}

class _PaymentSuccessPageState extends State<PaymentSuccessPage> {
  final _walletService = WalletService();
  late Future<void> _paymentFuture;

  @override
  void initState() {
    super.initState();
    _paymentFuture = _waitAndContinue();
  }

  Future<void> _waitAndContinue() async {
    // Wait up to 25 seconds for webhook to process payment
    final processed =
        await widget.deepLinkService.waitForPaymentProcessed(widget.sessionId);

    if (!mounted) return;

    if (processed) {
      // Give a brief moment for Firestore to propagate the balance change
      await Future.delayed(const Duration(milliseconds: 500));

      // Navigate back to token shop with success indicator
      Navigator.of(context).pop(true); // true = payment successful
    } else {
      // Timeout - show error
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Payment processing is taking longer than expected. Check your balance in a few moments.',
          ),
          duration: Duration(seconds: 4),
        ),
      );
      Navigator.of(context).pop(false); // false = timeout/error
    }
  }

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async => false, // Prevent back during processing
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Processing Payment'),
          automaticallyImplyLeadingButton: false,
        ),
        body: FutureBuilder<void>(
          future: _paymentFuture,
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(),
                    const SizedBox(height: 16),
                    const Text('Processing your payment...'),
                    const SizedBox(height: 8),
                    StreamBuilder<int>(
                      stream: _walletService.streamBalance(),
                      builder: (context, balSnapshot) {
                        final balance = balSnapshot.data ?? 0;
                        return Text(
                          'Current balance: $balance tokens',
                          style: Theme.of(context).textTheme.bodySmall,
                        );
                      },
                    ),
                  ],
                ),
              );
            }

            // Completion (will navigate away immediately)
            return const SizedBox.shrink();
          },
        ),
      ),
    );
  }
}
