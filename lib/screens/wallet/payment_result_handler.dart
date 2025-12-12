import 'package:flutter/material.dart';
import '../../services/deep_link_service.dart';
import '../../services/wallet_service.dart';

/// Invisible widget that listens for payment session callbacks.
/// Shows snackbar on success/failure without blocking navigation.
/// Add to your app root (e.g., MaterialApp) to handle payments globally.
class PaymentResultHandler extends StatefulWidget {
  final DeepLinkService deepLinkService;
  final WalletService walletService;
  final Widget child;

  const PaymentResultHandler({
    super.key,
    required this.deepLinkService,
    required this.walletService,
    required this.child,
  });

  @override
  State<PaymentResultHandler> createState() => _PaymentResultHandlerState();
}

class _PaymentResultHandlerState extends State<PaymentResultHandler> {
  late StreamSubscription<String?> _subscription;
  bool _isProcessing = false;

  @override
  void initState() {
    super.initState();
    _subscription = widget.deepLinkService.onSession.listen((sessionId) {
      if (sessionId != null && !_isProcessing) {
        _handleSession(sessionId);
      }
    });
  }

  @override
  void dispose() {
    _subscription.cancel();
    super.dispose();
  }

  Future<void> _handleSession(String sessionId) async {
    setState(() => _isProcessing = true);
    
    try {
      final processed = await widget.deepLinkService.waitForPaymentProcessed(sessionId);
      
      if (!mounted) return;
      
      if (processed) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✅ Payment confirmed — tokens credited!'),
            duration: Duration(seconds: 3),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Payment received — tokens will appear shortly.'),
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Payment error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
    
    if (mounted) setState(() => _isProcessing = false);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
