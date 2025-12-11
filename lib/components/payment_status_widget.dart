import 'package:flutter/material.dart';

/// Payment status badge colors and icons
class PaymentStatusConfig {
  final String status; // "unpaid" | "paid" | "overdue" | "partial"
  final Color color;
  final IconData icon;
  final String label;

  const PaymentStatusConfig({
    required this.status,
    required this.color,
    required this.icon,
    required this.label,
  });

  static PaymentStatusConfig fromStatus(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return const PaymentStatusConfig(
          status: 'paid',
          color: Colors.green,
          icon: Icons.check_circle,
          label: 'PAID',
        );
      case 'overdue':
        return const PaymentStatusConfig(
          status: 'overdue',
          color: Colors.red,
          icon: Icons.dangerous,
          label: 'OVERDUE',
        );
      case 'partial':
        return const PaymentStatusConfig(
          status: 'partial',
          color: Colors.orange,
          icon: Icons.pending_actions,
          label: 'PARTIAL',
        );
      case 'unpaid':
      default:
        return const PaymentStatusConfig(
          status: 'unpaid',
          color: Colors.orange,
          icon: Icons.pending,
          label: 'UNPAID',
        );
    }
  }
}

/// Displays invoice with amount and payment status badge
class InvoicePaymentStatusTile extends StatelessWidget {
  final String invoiceNumber;
  final double amount;
  final String currency;
  final String paymentStatus;
  final int? overdaysDays; // Number of days overdue
  final VoidCallback? onTap;

  const InvoicePaymentStatusTile({
    Key? key,
    required this.invoiceNumber,
    required this.amount,
    this.currency = '€',
    required this.paymentStatus,
    this.overdaysDays,
    this.onTap,
  }) : super(key: key);

  String _formatAmount(double amount) {
    return amount.toStringAsFixed(2);
  }

  @override
  Widget build(BuildContext context) {
    final config = PaymentStatusConfig.fromStatus(paymentStatus);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Card(
        elevation: 2,
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Left: Invoice number
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoiceNumber,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                  ),
                  if (paymentStatus.toLowerCase() == 'overdue' &&
                      overdaysDays != null)
                    Text(
                      '${overdaysDays} days overdue',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: config.color,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                ],
              ),
              // Center: Amount
              Expanded(
                child: Center(
                  child: Text(
                    '$currency${_formatAmount(amount)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          fontFamily: 'monospace',
                        ),
                  ),
                ),
              ),
              // Right: Status badge
              Chip(
                avatar: Icon(
                  config.icon,
                  size: 18,
                  color: Colors.white,
                ),
                label: Text(
                  config.label,
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
                backgroundColor: config.color,
                side: BorderSide.none,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Compact horizontal status widget
class PaymentStatusBadge extends StatelessWidget {
  final String status;
  final int? overdaysDays;
  final bool showIcon;

  const PaymentStatusBadge({
    Key? key,
    required this.status,
    this.overdaysDays,
    this.showIcon = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final config = PaymentStatusConfig.fromStatus(status);
    final label = status.toLowerCase() == 'overdue' && overdaysDays != null
        ? '${config.label} (${overdaysDays}d)'
        : config.label;

    return Chip(
      avatar: showIcon
          ? Icon(
              config.icon,
              size: 16,
              color: Colors.white,
            )
          : null,
      label: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: 11,
        ),
      ),
      backgroundColor: config.color,
      side: BorderSide.none,
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    );
  }
}

/// Status summary widget showing payment stats
class PaymentStatusSummary extends StatelessWidget {
  final int totalInvoices;
  final int paidCount;
  final int unpaidCount;
  final int overdueCount;
  final int partialCount;

  const PaymentStatusSummary({
    Key? key,
    required this.totalInvoices,
    required this.paidCount,
    required this.unpaidCount,
    required this.overdueCount,
    this.partialCount = 0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatCard(
          context,
          'Total',
          totalInvoices.toString(),
          Colors.blue,
          Icons.receipt,
        ),
        _buildStatCard(
          context,
          'Paid',
          paidCount.toString(),
          Colors.green,
          Icons.check_circle,
        ),
        _buildStatCard(
          context,
          'Unpaid',
          unpaidCount.toString(),
          Colors.orange,
          Icons.pending,
        ),
        _buildStatCard(
          context,
          'Overdue',
          overdueCount.toString(),
          Colors.red,
          Icons.dangerous,
        ),
      ],
    );
  }

  Widget _buildStatCard(
    BuildContext context,
    String label,
    String value,
    Color color,
    IconData icon,
  ) {
    return Card(
      elevation: 2,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color, size: 32),
          const SizedBox(height: 8),
          Text(
            value,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: Theme.of(context).textTheme.labelSmall,
          ),
        ],
      ),
    );
  }
}
