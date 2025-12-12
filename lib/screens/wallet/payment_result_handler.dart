import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import '../../services/deep_link_service.dart';
import '../../services/wallet_service.dart';
import '../../components/payment_status_modal.dart';

/// PaymentResultHandler: list for session_id events and manage the modal lifecycle.
/// Place this widget high in the widget tree (e.g., inside HomeScreen or WalletScreen)
class PaymentResultHandler extends StatefulWidget {
  final DeepLinkService deepLinkService;
  final WalletService walletService;
  final Widget? child;

  const PaymentResultHandler({
    Key? key,
    required this.deepLinkService,
    required this.walletService,
    this.child,
  }) : super(key: key);

  @override
  _PaymentResultHandlerState createState() => _PaymentResultHandlerState();
}

class _PaymentResultHandlerState extends State<PaymentResultHandler> {
  StreamSubscription<String?>? _sub;
  bool _isModalShowing = false;
  Timer? _processingTimer;
  DateTime? _processingStart;
  String? _currentSessionId;
  late final FirebaseFirestore _db;

  @override
  void initState() {
    super.initState();
    _db = FirebaseFirestore.instance;
    _sub = widget.deepLinkService.onSession.listen((sessionId) {
      if (sessionId != null) _handleSession(sessionId);
    });
  }

  @override
  void dispose() {
    _sub?.cancel();
    _processingTimer?.cancel();
    super.dispose();
  }

  Future<void> _handleSession(String sessionId) async {
    if (_isModalShowing) return;
    _currentSessionId = sessionId;
    _processingStart = DateTime.now();
    _showProcessingModal(sessionId);

    final processed = await widget.deepLinkService.waitForPaymentProcessed(sessionId,
        timeout: const Duration(seconds: 25), interval: const Duration(seconds: 1));

    if (!mounted) return;

    if (processed) {
      // Read token_audit to try and get info for modal (packId, tokens)
      final processedDoc = await _db.collection('payments_processed').doc(sessionId).get();
      String packId = processedDoc.data()?['packId'] ?? '';
      String uid = processedDoc.data()?['uid'] ?? '';
      int tokens = 0;
      String packTitle = '';
      // Try to read the last audit entry to get tokens credited (best-effort)
      if (uid.isNotEmpty) {
        final auditSnap = await _db
            .collection('users')
            .doc(uid)
            .collection('token_audit')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();

        for (final doc in auditSnap.docs) {
          final d = doc.data();
          if (d['sessionId'] == sessionId || d['action'] == 'purchase' && d['packId'] == packId) {
            tokens = (d['amount'] is int) ? d['amount'] : (d['amount'] is double ? (d['amount'] as double).toInt() : tokens);
            packTitle = (d['packId'] ?? packId) as String;
            break;
          }
        }
      }

      _showSuccessModal(tokens: tokens, packTitle: packTitle);
    } else {
      // not processed timely
      _showTimeoutModal();
    }
  }

  void _showProcessingModal(String sessionId) {
    _isModalShowing = true;
    _processingTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {});
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) {
        final elapsed = DateTime.now().difference(_processingStart ?? DateTime.now());
        return PaymentStatusModal(
          status: PaymentStatus.processing,
          title: 'Verifying payment',
          message: 'We are confirming your payment. This usually takes a few seconds.',
          processingElapsed: elapsed,
          onClose: () {
            // allow user to close while processing (non-blocking)
            Navigator.of(context, rootNavigator: true).pop();
            _isModalShowing = false;
            _processingTimer?.cancel();
          },
          onViewWallet: null,
        );
      },
    );
  }

  void _showSuccessModal({required int tokens, required String packTitle}) {
    _processingTimer?.cancel();
    if (!mounted) return;
    // Replace the processing dialog with success dialog
    Navigator.of(context, rootNavigator: true).pop(); // close processing
    _isModalShowing = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return PaymentStatusModal(
          status: PaymentStatus.success,
          title: 'Tokens Credited!',
          message: 'Your purchase was successful and tokens are now available in your wallet.',
          tokensAdded: tokens,
          packTitle: packTitle.isNotEmpty ? packTitle : 'Purchased Pack',
          onClose: () {
            Navigator.of(context, rootNavigator: true).pop();
            _isModalShowing = false;
          },
          onViewWallet: () {
            Navigator.of(context, rootNavigator: true).pop();
            _isModalShowing = false;
            // navigate to wallet screen if app has named route
            try {
              Navigator.of(context).pushNamed('/wallet');
            } catch (_) {}
          },
        );
      },
    );
  }

  void _showTimeoutModal() {
    _processingTimer?.cancel();
    if (!mounted) return;
    Navigator.of(context, rootNavigator: true).pop(); // close processing if open
    _isModalShowing = true;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (context) {
        return PaymentStatusModal(
          status: PaymentStatus.timeout,
          title: 'Processing — Delay',
          message: 'We received your payment but processing is delayed. Tokens should appear shortly. If not, contact support.',
          onClose: () {
            Navigator.of(context, rootNavigator: true).pop();
            _isModalShowing = false;
          },
          onViewWallet: () {
            Navigator.of(context, rootNavigator: true).pop();
            _isModalShowing = false;
            try {
              Navigator.of(context).pushNamed('/wallet');
            } catch (_) {}
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // This is an invisible handler. It renders its child (if provided).
    // Place this near top-level, e.g., return PaymentResultHandler(..., child: YourAppScaffold(...))
    return widget.child ?? const SizedBox.shrink();
  }
}
