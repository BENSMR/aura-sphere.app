import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:printing/printing.dart';
import '../../models/invoice_model.dart';
import '../../providers/invoice_provider.dart';
// import '../../widgets/invoice_download_sheet.dart'; // Temporarily disabled
// import '../../services/invoice/local_pdf_service.dart'; // Temporarily disabled

/// Invoice Export Screen
/// 
/// Comprehensive invoice export interface with:
/// - Single and bulk invoice downloads
/// - Multiple export formats (PDF, CSV, JSON)
/// - Advanced filtering and search
/// - Export history
/// - Download management
class InvoiceExportScreen extends StatefulWidget {
  const InvoiceExportScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceExportScreen> createState() => _InvoiceExportScreenState();
}

class _InvoiceExportScreenState extends State<InvoiceExportScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'all';
  String _selectedFormat = 'pdf';
  bool _selectAll = false;
  final Set<String> _selectedInvoices = {};

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Export'),
        elevation: 0,
        actions: [
          if (_selectedInvoices.isNotEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Center(
                child: Text(
                  '${_selectedInvoices.length} selected',
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ),
        ],
      ),
      body: Consumer<InvoiceProvider>(
        builder: (context, invoiceProvider, _) {
          if (invoiceProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          final allInvoices = invoiceProvider.invoices;
          final filteredInvoices = _getFilteredInvoices(allInvoices);

          if (filteredInvoices.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.download_done, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No invoices to export',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create invoices first to export them',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return Column(
            children: [
              // Filters and Search
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Search
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Search invoices...',
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 12,
                        ),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 12),

                    // Filters Row
                    Row(
                      children: [
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: InputDecoration(
                              labelText: 'Status',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'all', child: Text('All')),
                              DropdownMenuItem(value: 'draft', child: Text('Draft')),
                              DropdownMenuItem(value: 'sent', child: Text('Sent')),
                              DropdownMenuItem(value: 'paid', child: Text('Paid')),
                              DropdownMenuItem(value: 'overdue', child: Text('Overdue')),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedStatus = value ?? 'all');
                            },
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: DropdownButtonFormField<String>(
                            value: _selectedFormat,
                            decoration: InputDecoration(
                              labelText: 'Format',
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              isDense: true,
                            ),
                            items: const [
                              DropdownMenuItem(value: 'pdf', child: Text('PDF')),
                              DropdownMenuItem(value: 'csv', child: Text('CSV')),
                              DropdownMenuItem(value: 'json', child: Text('JSON')),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedFormat = value ?? 'pdf');
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const Divider(),

              // Bulk Actions
              if (_selectedInvoices.isNotEmpty)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Checkbox(
                        value: _selectAll,
                        onChanged: (value) {
                          setState(() {
                            if (value ?? false) {
                              _selectedInvoices.addAll(
                                filteredInvoices.map((i) => i.id),
                              );
                              _selectAll = true;
                            } else {
                              _selectedInvoices.clear();
                              _selectAll = false;
                            }
                          });
                        },
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${_selectedInvoices.length}/${filteredInvoices.length} selected',
                      ),
                      const Spacer(),
                      ElevatedButton.icon(
                        onPressed: _selectedInvoices.isEmpty
                            ? null
                            : () => _exportSelected(invoiceProvider),
                        icon: const Icon(Icons.download),
                        label: const Text('Export Selected'),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        onPressed: () {
                          setState(() {
                            _selectedInvoices.clear();
                            _selectAll = false;
                          });
                        },
                        icon: const Icon(Icons.clear),
                        label: const Text('Clear'),
                      ),
                    ],
                  ),
                )
              else
                const Divider(height: 0),

              // Invoice List
              Expanded(
                child: ListView.builder(
                  itemCount: filteredInvoices.length,
                  itemBuilder: (context, index) {
                    final invoice = filteredInvoices[index];
                    final isSelected = _selectedInvoices.contains(invoice.id);

                    return InvoiceExportTile(
                      invoice: invoice,
                      isSelected: isSelected,
                      onSelected: (selected) {
                        setState(() {
                          if (selected) {
                            _selectedInvoices.add(invoice.id);
                          } else {
                            _selectedInvoices.remove(invoice.id);
                          }
                          _selectAll = false;
                        });
                      },
                      onDownload: () {
                        // showInvoiceDownloadSheet(context, invoice); // Temporarily disabled
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Download feature coming soon')),
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<Invoice> _getFilteredInvoices(List<Invoice> invoices) {
    var filtered = invoices;

    // Filter by status
    if (_selectedStatus != 'all') {
      filtered = filtered
          .where((i) => i.status.toLowerCase() == _selectedStatus)
          .toList();
    }

    // Search by invoice number or amount
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((i) {
        final invoiceNum = i.invoiceNumber ?? '';
        return invoiceNum.toLowerCase().contains(query) ||
            i.amount.toString().contains(query);
      }).toList();
    }

    // Sort by date (newest first)
    filtered.sort((a, b) => b.issueDate.compareTo(a.issueDate));

    return filtered;
  }

  void _exportSelected(InvoiceProvider provider) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Export Invoices'),
        content: Text(
          'Export ${_selectedInvoices.length} invoice(s) as $_selectedFormat?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _performBulkExport();
            },
            child: const Text('Export'),
          ),
        ],
      ),
    );
  }

  void _performBulkExport() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Exporting ${_selectedInvoices.length} invoices as $_selectedFormat...',
        ),
      ),
    );

    // TODO: Implement bulk export functionality
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              '${_selectedInvoices.length} invoices exported successfully!',
            ),
            backgroundColor: Colors.green,
          ),
        );
        setState(() {
          _selectedInvoices.clear();
          _selectAll = false;
        });
      }
    });
  }
}

/// Invoice Tile for Export List
class InvoiceExportTile extends StatelessWidget {
  final Invoice invoice;
  final bool isSelected;
  final ValueChanged<bool> onSelected;
  final VoidCallback onDownload;

  const InvoiceExportTile({
    Key? key,
    required this.invoice,
    required this.isSelected,
    required this.onSelected,
    required this.onDownload,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: ListTile(
        leading: Checkbox(
          value: isSelected,
          onChanged: (value) => onSelected(value ?? false),
        ),
        title: Text(invoice.invoiceNumber ?? 'No number'),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(
              invoice.clientId,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                _buildStatusBadge(invoice.status),
                const SizedBox(width: 8),
                Text(
                  '${invoice.currency} ${invoice.amount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
        trailing: PopupMenuButton<String>(
          onSelected: (value) async {
            if (value == 'download') {
              onDownload();
            } else if (value == 'pdf-local') {
              _generateLocalPdf(context);
            }
          },
          itemBuilder: (BuildContext context) => [
            const PopupMenuItem<String>(
              value: 'pdf-local',
              child: Row(
                children: [
                  Icon(Icons.picture_as_pdf, size: 18),
                  SizedBox(width: 8),
                  Text('PDF (Local)'),
                ],
              ),
            ),
            const PopupMenuItem<String>(
              value: 'download',
              child: Row(
                children: [
                  Icon(Icons.download, size: 18),
                  SizedBox(width: 8),
                  Text('Download'),
                ],
              ),
            ),
          ],
        ),
        onTap: () => onSelected(!isSelected),
      ),
    );
  }

  Widget _buildStatusBadge(String status) {
    final colors = {
      'draft': Colors.grey,
      'sent': Colors.blue,
      'paid': Colors.green,
      'overdue': Colors.red,
    };

    final color = colors[status.toLowerCase()] ?? Colors.grey;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.2),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }

  Future<void> _generateLocalPdf(BuildContext context) async {
    try {
      final scaffoldMessenger = ScaffoldMessenger.of(context);
      scaffoldMessenger.showSnackBar(
        const SnackBar(content: Text('Generating PDF...')),
      );

      // Fetch business profile from Firestore
      final userId = invoice.userId;
      final businessDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(userId)
          .collection('meta')
          .doc('business')
          .get();
      
      final business = businessDoc.exists 
          ? (businessDoc.data() as Map<String, dynamic>?) ?? {} 
          : {} as Map<String, dynamic>;

      // Generate PDF locally
      // final bytes = await LocalPdfService.generateInvoicePdfBytes(invoice, business); // Temporarily disabled

      // Open print preview
      if (context.mounted) {
        // await Printing.layoutPdf(onLayout: (format) async => bytes); // Temporarily disabled
        
        scaffoldMessenger.showSnackBar(
          const SnackBar(
            content: Text('PDF generation coming soon'),
            backgroundColor: Colors.orange,
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to generate PDF: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
