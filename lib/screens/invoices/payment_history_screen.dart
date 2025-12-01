import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../models/invoice_model.dart';
import '../../models/payment_record.dart';
import '../../services/payment_service.dart';
import '../../providers/user_provider.dart';

class PaymentHistoryScreen extends StatefulWidget {
  const PaymentHistoryScreen({super.key});

  @override
  State<PaymentHistoryScreen> createState() => _PaymentHistoryScreenState();
}

class _PaymentHistoryScreenState extends State<PaymentHistoryScreen> {
  late InvoiceModel invoice;
  bool loading = true;
  List<PaymentRecord> payments = [];
  String? errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final args = ModalRoute.of(context)?.settings.arguments;
    if (args != null && args is InvoiceModel) {
      invoice = args;
      _loadPayments();
    }
  }

  Future<void> _loadPayments() async {
    final user = Provider.of<UserProvider>(context, listen: false).user;
    if (user == null) {
      setState(() {
        loading = false;
        errorMessage = 'User not authenticated';
      });
      return;
    }

    try {
      final service = PaymentService();
      final result = await service.getPaymentsForInvoice(user.uid, invoice.id!);

      setState(() {
        payments = result;
        loading = false;
        errorMessage = null;
      });
    } catch (e) {
      setState(() {
        loading = false;
        errorMessage = 'Failed to load payments: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment History'),
        elevation: 0,
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (loading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    if (errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.red),
            const SizedBox(height: 16),
            Text(
              errorMessage!,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, color: Colors.grey),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPayments,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (payments.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.payment_outlined,
              size: 64,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 16),
            Text(
              'No payments recorded yet',
              style: TextStyle(
                fontSize: 18,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Payments will appear here once recorded',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[500],
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadPayments,
      child: ListView.builder(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: payments.length,
        itemBuilder: (context, index) {
          return _buildPaymentTile(payments[index]);
        },
      ),
    );
  }

  Widget _buildPaymentTile(PaymentRecord payment) {
    final formattedDate =
        DateFormat('MMM dd, yyyy • hh:mm a').format(payment.paidAt.toLocal());
    final formattedAmount =
        payment.amount.toStringAsFixed(2);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 1,
      child: ExpansionTile(
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              '${payment.currency.toUpperCase()} $formattedAmount',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
              ),
            ),
            _buildStatusBadge(payment.provider),
          ],
        ),
        subtitle: Text(
          formattedDate,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDetailRow('Provider', payment.provider),
                if (payment.cardBrand != null)
                  _buildDetailRow('Card Brand', payment.cardBrand!),
                if (payment.last4 != null)
                  _buildDetailRow('Card Last 4', payment.last4!),
                if (payment.stripePaymentIntent != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Payment Intent',
                    payment.stripePaymentIntent!,
                    monospace: true,
                  ),
                ],
                if (payment.stripeSessionId != null) ...[
                  const SizedBox(height: 12),
                  _buildDetailRow(
                    'Session ID',
                    payment.stripeSessionId!,
                    monospace: true,
                  ),
                ],
                if (payment.receiptUrl != null) ...[
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () {
                      // TODO: Implement receipt URL launcher
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Receipt: ${payment.receiptUrl}'),
                        ),
                      );
                    },
                    icon: const Icon(Icons.download),
                    label: const Text('Download Receipt'),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(
    String label,
    String value, {
    bool monospace = false,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              label,
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontFamily: monospace ? 'monospace' : null,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge(String provider) {
    final color = _getProviderColor(provider);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        provider.toUpperCase(),
        style: TextStyle(
          color: color,
          fontSize: 11,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getProviderColor(String provider) {
    switch (provider.toLowerCase()) {
      case 'stripe':
        return Colors.blue;
      case 'paypal':
        return Colors.blue[900]!;
      case 'square':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}
