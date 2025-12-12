import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'animated_number.dart';
import 'token_floating_text.dart';

enum PaymentStatus { processing, success, timeout, error }

class PaymentStatusModal extends StatelessWidget {
  final PaymentStatus status;
  final String title;
  final String message;
  final int tokensAdded;
  final String packTitle;
  final VoidCallback? onClose;
  final VoidCallback? onViewWallet;
  final Duration processingElapsed;

  const PaymentStatusModal({
    Key? key,
    required this.status,
    required this.title,
    required this.message,
    this.tokensAdded = 0,
    this.packTitle = '',
    this.onClose,
    this.onViewWallet,
    this.processingElapsed = Duration.zero,
  }) : super(key: key);

  // Select animation path
  String _animationForStatus() {
    switch (status) {
      case PaymentStatus.processing:
        return 'assets/animations/payment_processing.json';
      case PaymentStatus.success:
        return 'assets/animations/payment_success.json';
      case PaymentStatus.timeout:
        return 'assets/animations/payment_timeout.json';
      case PaymentStatus.error:
        return 'assets/animations/payment_error.json';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Lottie animation
              SizedBox(
                height: 120,
                child: Lottie.asset(
                  _animationForStatus(),
                  repeat: status == PaymentStatus.processing,
                ),
              ),

              const SizedBox(height: 8),
              Text(title, style: theme.textTheme.headline6),
              const SizedBox(height: 6),
              Text(message, textAlign: TextAlign.center),

              if (status == PaymentStatus.processing) ...[
                const SizedBox(height: 10),
                Text(
                  "Elapsed: ${processingElapsed.inSeconds}s",
                  style: theme.textTheme.caption,
                ),
              ],

              if (status == PaymentStatus.success) ...[
                const SizedBox(height: 12),
                Text('Pack: $packTitle'),
                AnimatedNumber(
                  value: tokensAdded,
                  style: theme.textTheme.headline5?.copyWith(
                    color: Colors.greenAccent,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],

              const SizedBox(height: 14),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TextButton(
                      onPressed: onClose,
                      child: const Text("Close")
                  ),
                  if (status == PaymentStatus.success ||
                      status == PaymentStatus.timeout)
                    const SizedBox(width: 12),
                  if (status == PaymentStatus.success ||
                      status == PaymentStatus.timeout)
                    ElevatedButton(
                      onPressed: onViewWallet,
                      child: const Text("Go to Wallet"),
                    ),
                ],
              )
            ],
          ),
        ),
      ),
    );
  }
}
