import 'package:flutter/material.dart';

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

  Widget _buildIcon() {
    switch (status) {
      case PaymentStatus.processing:
        return SizedBox(
          width: 72,
          height: 72,
          child: CircularProgressIndicator(strokeWidth: 6),
        );
      case PaymentStatus.success:
        return Icon(Icons.check_circle_outline, color: Colors.greenAccent, size: 72);
      case PaymentStatus.timeout:
        return Icon(Icons.hourglass_bottom, color: Colors.amber, size: 72);
      case PaymentStatus.error:
        return Icon(Icons.error_outline, color: Colors.redAccent, size: 72);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isProcessing = status == PaymentStatus.processing;

    return WillPopScope(
      onWillPop: () async => !(isProcessing), // prevent dismiss while processing
      child: Dialog(
        insetPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        backgroundColor: theme.dialogBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.all(18.0),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: 180, maxWidth: 520),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildIcon(),
                const SizedBox(height: 14),
                Text(title, style: theme.textTheme.headline6),
                const SizedBox(height: 8),
                Text(message, textAlign: TextAlign.center, style: theme.textTheme.bodyText2),
                if (status == PaymentStatus.processing) ...[
                  const SizedBox(height: 12),
                  Text('Elapsed: ${processingElapsed.inSeconds}s', style: theme.textTheme.caption),
                ],
                if (status == PaymentStatus.success) ...[
                  const SizedBox(height: 12),
                  Text('Pack: $packTitle', style: theme.textTheme.subtitle1),
                  const SizedBox(height: 6),
                  Text('+$tokensAdded tokens', style: theme.textTheme.headline6),
                ],
                const SizedBox(height: 18),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    if (status == PaymentStatus.processing)
                      TextButton(
                        onPressed: onClose,
                        child: const Text('Close'),
                      ),
                    if (status == PaymentStatus.success) ...[
                      TextButton(onPressed: onClose, child: const Text('Close')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: onViewWallet,
                        child: const Text('Go to Wallet'),
                      ),
                    ],
                    if (status == PaymentStatus.timeout) ...[
                      TextButton(onPressed: onClose, child: const Text('Close')),
                      const SizedBox(width: 12),
                      ElevatedButton(
                        onPressed: onViewWallet,
                        child: const Text('Open Wallet'),
                      ),
                    ],
                    if (status == PaymentStatus.error) ...[
                      TextButton(onPressed: onClose, child: const Text('Close')),
                    ]
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
