import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/invoice_provider.dart';
import '../../data/models/invoice_model.dart';
import '../../config/app_routes.dart';

class InvoiceListScreen extends StatefulWidget {
  const InvoiceListScreen({super.key});

  @override
  State<InvoiceListScreen> createState() => _InvoiceListScreenState();
}

class _InvoiceListScreenState extends State<InvoiceListScreen> {
  String _filterStatus = 'all'; // all, draft, sent, paid

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoiceProvider>().loadInvoices();
    });
  }

  void _showDeleteConfirm(BuildContext context, String invoiceId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Invoice?'),
        content: const Text('This action cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final provider = context.read<InvoiceProvider>();
              final success = await provider.deleteInvoice(invoiceId);
              if (!mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(success ? 'Invoice deleted' : 'Error deleting invoice'),
                  backgroundColor: success ? Colors.green : Colors.red,
                ),
              );
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoices'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              final userId = context.read<InvoiceProvider>().invoices.isNotEmpty
                  ? context.read<InvoiceProvider>().invoices.first.userId
                  : 'unknown';
              Navigator.pushNamed(
                context,
                AppRoutes.invoiceCreate,
                arguments: {'userId': userId},
              );
            },
            tooltip: 'Create Invoice',
          ),
        ],
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          // Filter invoices
          final filteredInvoices = _filterStatus == 'all'
              ? provider.invoices
              : provider.invoices.where((inv) => inv.status == _filterStatus).toList();

          if (filteredInvoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.receipt_long_outlined,
                    size: 64,
                    color: Colors.grey[400],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _filterStatus == 'all'
                        ? 'No invoices yet'
                        : 'No $_filterStatus invoices',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      final userId = provider.invoices.isNotEmpty
                          ? provider.invoices.first.userId
                          : 'unknown';
                      Navigator.pushNamed(
                        context,
                        AppRoutes.invoiceCreate,
                        arguments: {'userId': userId},
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Invoice'),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filter tabs
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      _buildFilterChip('All', 'all'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Draft', 'draft'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Sent', 'sent'),
                      const SizedBox(width: 8),
                      _buildFilterChip('Paid', 'paid'),
                    ],
                  ),
                ),
              ),
              const Divider(height: 1),

              // Invoice list
              Expanded(
                child: ListView.builder(
                  itemCount: filteredInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = filteredInvoices[index];
                    return _buildInvoiceCard(context, invoice);
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildFilterChip(String label, String status) {
    return FilterChip(
      label: Text(label),
      selected: _filterStatus == status,
      onSelected: (selected) {
        setState(() => _filterStatus = status);
      },
    );
  }

  Widget _buildInvoiceCard(BuildContext context, InvoiceModel invoice) {
    final statusColor = _getStatusColor(invoice.status);
    final statusLabel = invoice.status.toUpperCase();

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    invoice.invoiceNumber ?? 'INV-${invoice.id.substring(0, 8)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    invoice.clientName,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[700],
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: statusColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                statusLabel,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 12),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${invoice.currency} ${invoice.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (invoice.dueDate != null)
                    Text(
                      'Due: ${invoice.dueDate!.year}-${invoice.dueDate!.month.toString().padLeft(2, '0')}-${invoice.dueDate!.day.toString().padLeft(2, '0')}',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                ],
              ),
              PopupMenuButton<String>(
                onSelected: (action) async {
                  final provider = context.read<InvoiceProvider>();
                  switch (action) {
                    case 'edit':
                      Navigator.pushNamed(
                        context,
                        AppRoutes.invoiceCreate,
                        arguments: {
                          'userId': invoice.userId,
                          'invoice': invoice,
                        },
                      );
                      break;
                    case 'send':
                      try {
                        await provider.editingInvoice ?? invoice;
                        // TODO: Implement send
                      } catch (e) {
                        if (!mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text('Error: $e')),
                        );
                      }
                      break;
                    case 'mark_paid':
                      final success = await provider.markAsPaid(invoice.id);
                      if (!mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            success
                                ? 'Invoice marked as paid'
                                : 'Error updating invoice',
                          ),
                          backgroundColor:
                              success ? Colors.green : Colors.red,
                        ),
                      );
                      break;
                    case 'delete':
                      _showDeleteConfirm(context, invoice.id);
                      break;
                  }
                },
                itemBuilder: (BuildContext context) => [
                  if (invoice.status != 'sent' && invoice.status != 'paid')
                    const PopupMenuItem(
                      value: 'edit',
                      child: Text('Edit'),
                    ),
                  if (invoice.status == 'draft')
                    const PopupMenuItem(
                      value: 'send',
                      child: Text('Send'),
                    ),
                  if (invoice.status != 'paid')
                    const PopupMenuItem(
                      value: 'mark_paid',
                      child: Text('Mark as Paid'),
                    ),
                  const PopupMenuDivider(),
                  const PopupMenuItem(
                    value: 'delete',
                    child: Text(
                      'Delete',
                      style: TextStyle(color: Colors.red),
                    ),
                  ),
                ],
                child: const Icon(Icons.more_vert),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'draft':
        return Colors.orange;
      case 'sent':
        return Colors.blue;
      case 'paid':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }
}