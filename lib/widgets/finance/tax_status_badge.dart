import 'package:flutter/material.dart';
import 'package:aura_sphere_pro/services/tax_service.dart';

/// Tax Status Badge Widget
/// 
/// Shows real-time tax calculation status with different visual states:
/// - ⏳ Calculating... (queue is processing)
/// - ✅ Calculated (tax successfully applied)
/// - ❌ Error (tax calculation failed - with retry button)
/// - — No status (invoice not yet queued or already calculated)
class TaxStatusBadge extends StatefulWidget {
  final String userId;
  final String invoiceId;
  final TaxService taxService;
  final VoidCallback? onRetry;
  final bool compact;

  const TaxStatusBadge({
    Key? key,
    required this.userId,
    required this.invoiceId,
    TaxService? taxService,
    this.onRetry,
    this.compact = false,
  })  : taxService = taxService ?? const _DefaultTaxService(),
        super(key: key);

  @override
  State<TaxStatusBadge> createState() => _TaxStatusBadgeState();
}

class _TaxStatusBadgeState extends State<TaxStatusBadge> {
  late Stream<Map<String, dynamic>?> _statusStream;

  @override
  void initState() {
    super.initState();
    _statusStream = widget.taxService.watchInvoiceTaxStatus(
      uid: widget.userId,
      invoiceId: widget.invoiceId,
    );
  }

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<Map<String, dynamic>?>(
      stream: _statusStream,
      builder: (context, snapshot) {
        final queueStatus = snapshot.data;

        // No queue request found
        if (!snapshot.hasData || queueStatus == null) {
          return _buildBadge(
            label: 'Tax: Ready',
            color: Colors.grey,
            icon: Icons.schedule,
            compact: widget.compact,
          );
        }

        // Tax calculation completed successfully
        if (queueStatus['processed'] == true) {
          final processedAt = queueStatus['processedAt'] as String?;
          final timestamp = processedAt != null ? _formatTime(processedAt) : '';
          
          return _buildBadge(
            label: 'Tax: ✅',
            color: Colors.green,
            icon: Icons.check_circle,
            subtitle: widget.compact ? null : 'Calculated $timestamp',
            compact: widget.compact,
          );
        }

        // Tax calculation failed
        if (queueStatus['lastError'] != null) {
          final error = queueStatus['lastError'] as String?;
          final attempts = queueStatus['attempts'] as int? ?? 0;

          return _buildBadge(
            label: 'Tax: ❌',
            color: Colors.red,
            icon: Icons.error,
            subtitle: widget.compact ? null : 'Error (Attempt $attempts)',
            action: widget.onRetry != null
                ? _buildRetryButton(context, error)
                : null,
            compact: widget.compact,
          );
        }

        // Tax calculation in progress
        final attempts = queueStatus['attempts'] as int? ?? 1;
        return _buildBadge(
          label: 'Tax: ⏳',
          color: Colors.orange,
          icon: null,
          subtitle: widget.compact ? null : 'Calculating... (Attempt $attempts)',
          action: _buildLoadingSpinner(),
          compact: widget.compact,
        );
      },
    );
  }

  /// Build the badge widget
  Widget _buildBadge({
    required String label,
    required Color color,
    required IconData? icon,
    String? subtitle,
    Widget? action,
    required bool compact,
  }) {
    if (compact) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withOpacity(0.1),
          border: Border.all(color: color),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: Icon(icon, size: 14, color: color),
              )
            else if (action != null)
              Padding(
                padding: const EdgeInsets.only(right: 4),
                child: SizedBox(width: 14, height: 14, child: action),
              ),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: color,
              ),
            ),
          ],
        ),
      );
    }

    // Full badge
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.05),
        border: Border.all(color: color.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          if (icon != null)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: Icon(icon, color: color, size: 20),
            )
          else if (action != null && action is! ElevatedButton)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: SizedBox(width: 20, height: 20, child: action),
            ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: color,
                  ),
                ),
                if (subtitle != null)
                  Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12,
                        color: color.withOpacity(0.7),
                      ),
                    ),
                  ),
              ],
            ),
          ),
          if (action is ElevatedButton)
            Padding(
              padding: const EdgeInsets.only(left: 8),
              child: action,
            ),
        ],
      ),
    );
  }

  /// Build loading spinner
  Widget _buildLoadingSpinner() {
    return const SizedBox(
      width: 16,
      height: 16,
      child: CircularProgressIndicator(strokeWidth: 2),
    );
  }

  /// Build retry button
  Widget _buildRetryButton(BuildContext context, String? error) {
    return ElevatedButton.icon(
      onPressed: widget.onRetry,
      icon: const Icon(Icons.refresh, size: 16),
      label: const Text('Retry'),
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
    );
  }

  /// Format timestamp for display
  String _formatTime(String timestamp) {
    try {
      final dt = DateTime.parse(timestamp);
      final now = DateTime.now();
      final diff = now.difference(dt);

      if (diff.inSeconds < 60) {
        return 'just now';
      } else if (diff.inMinutes < 60) {
        return '${diff.inMinutes}m ago';
      } else if (diff.inHours < 24) {
        return '${diff.inHours}h ago';
      } else {
        return '${diff.inDays}d ago';
      }
    } catch (e) {
      return '';
    }
  }
}

/// Default TaxService for widget initialization
class _DefaultTaxService extends TaxService {
  const _DefaultTaxService();
}

/// Example usage in invoice list
class InvoiceListItem extends StatelessWidget {
  final String userId;
  final String invoiceId;
  final String invoiceNumber;
  final double amount;
  final String currency;

  const InvoiceListItem({
    Key? key,
    required this.userId,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amount,
    required this.currency,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoiceNumber,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  Text(
                    '${currency == 'EUR' ? '€' : '\$'}${amount.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.bodyLarge,
                  ),
                ],
              ),
            ),
            TaxStatusBadge(
              userId: userId,
              invoiceId: invoiceId,
              compact: true,
            ),
          ],
        ),
      ),
    );
  }
}

/// Example usage in invoice detail
class InvoiceDetailHeader extends StatefulWidget {
  final String userId;
  final String invoiceId;
  final String invoiceNumber;
  final double amount;
  final String currency;
  final TaxService? taxService;

  const InvoiceDetailHeader({
    Key? key,
    required this.userId,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.amount,
    required this.currency,
    this.taxService,
  }) : super(key: key);

  @override
  State<InvoiceDetailHeader> createState() => _InvoiceDetailHeaderState();
}

class _InvoiceDetailHeaderState extends State<InvoiceDetailHeader> {
  late TaxService _taxService;

  @override
  void initState() {
    super.initState();
    _taxService = widget.taxService ?? TaxService();
  }
    try {
      final newQueueId = await _taxService.retryFailedTaxCalculation(
        uid: widget.userId,
        invoiceId: widget.invoiceId,
      );

      if (newQueueId != null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry queued: $newQueueId'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Retry failed: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          widget.invoiceNumber,
          style: Theme.of(context).textTheme.headlineSmall,
        ),
        const SizedBox(height: 8),
        Text(
          '${widget.currency == 'EUR' ? '€' : '\$'}${widget.amount.toStringAsFixed(2)}',
          style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: 16),
        TaxStatusBadge(
          userId: widget.userId,
          invoiceId: widget.invoiceId,
          taxService: _taxService,
          onRetry: _handleRetry,
          compact: false,
        ),
      ],
    );
  }
}
