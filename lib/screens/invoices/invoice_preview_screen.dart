import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../../data/models/invoice_model.dart';
import '../../providers/invoice_preview_provider.dart';
import '../../providers/business_branding_provider.dart';
import '../../config/app_routes.dart';
import '../../services/pdf/invoice_export_manager.dart';
import '../../services/pdf/invoice_pdf_generator.dart';
import '../../screens/invoices/invoice_template_picker_screen.dart';
import '../../services/invoice_email_service.dart';
import '../../services/invoice_service.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoicePreviewScreen({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  State<InvoicePreviewScreen> createState() => _InvoicePreviewScreenState();
}

class _InvoicePreviewScreenState extends State<InvoicePreviewScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedTemplate = 'default';
  bool _showSignature = true;
  String? _watermarkText;
  late final InvoiceService _invoiceService;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _invoiceService = InvoiceService();
    _loadBrandingPreferences();
    _generateInitialPreview();
  }

  void _loadBrandingPreferences() {
    final branding = context.read<BusinessBrandingProvider>().branding;

    if (branding != null) {
      _selectedTemplate = branding.invoiceTemplateId ?? 'default';
      _showSignature = branding.showSignature;
      _watermarkText = branding.watermarkText;
    }
  }

  void _generateInitialPreview() {
    Future.microtask(() {
      if (mounted) {
        context.read<InvoicePreviewProvider>().generatePreview(
              invoiceId: widget.invoice.id,
              templateId: _selectedTemplate,
              includeSignature: _showSignature,
              watermarkText: _watermarkText,
            );
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _refreshPreview() async {
    await context.read<InvoicePreviewProvider>().generatePreview(
          invoiceId: widget.invoice.id,
          templateId: _selectedTemplate,
          includeSignature: _showSignature,
          watermarkText: _watermarkText,
        );
  }

  Future<void> _generateAllVariants() async {
    await context
        .read<InvoicePreviewProvider>()
        .generateAllTemplateVariants(widget.invoice.id);
  }

  Future<void> _exportInvoicePdf() async {
    try {
      // Get business info from branding provider
      final brandingProvider = context.read<BusinessBrandingProvider>();
      final businessInfo = {
        'name': brandingProvider.branding?.companyDetails?.name ?? 'Company',
        'address': brandingProvider.branding?.companyDetails?.address,
      };

      // Export invoice as PDF with preview
      await InvoiceExportManager.previewInvoice(
        context: context,
        invoiceNumber: widget.invoice.invoiceNumber ?? widget.invoice.id,
        clientName: widget.invoice.clientName,
        clientEmail: widget.invoice.clientEmail,
        amount: widget.invoice.total,
        currency: widget.invoice.currency,
        date: widget.invoice.createdAt,
        notes: widget.invoice.notes,
        items: widget.invoice.items
            .map((item) => {
                  'name': item.description,
                  'qty': item.quantity,
                  'price': item.unitPrice,
                })
            .toList(),
        business: businessInfo,
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error exporting PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _shareInvoicePdf() async {
    try {
      // Get business info from branding provider
      final brandingProvider = context.read<BusinessBrandingProvider>();
      final businessInfo = {
        'name': brandingProvider.branding?.companyDetails?.name ?? 'Company',
        'address': brandingProvider.branding?.companyDetails?.address,
      };

      // Generate PDF bytes
      final pdf = await InvoicePdfService.generateInvoicePdf(
        invoiceNumber: widget.invoice.invoiceNumber ?? widget.invoice.id,
        clientName: widget.invoice.clientName,
        clientEmail: widget.invoice.clientEmail,
        amount: widget.invoice.total,
        currency: widget.invoice.currency,
        date: widget.invoice.createdAt,
        notes: widget.invoice.notes,
        items: widget.invoice.items
            .map((item) => {
                  'name': item.description,
                  'qty': item.quantity,
                  'price': item.unitPrice,
                })
            .toList(),
        business: businessInfo,
      );

      // Share PDF
      await Printing.sharePdf(
        bytes: pdf,
        filename:
            "Invoice-${widget.invoice.invoiceNumber ?? widget.invoice.id}.pdf",
      );
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error sharing PDF: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.style),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                  builder: (_) => const InvoiceTemplatePickerScreen()),
            ),
            tooltip: 'Template Picker',
          ),
          IconButton(
            icon: const Icon(Icons.email),
            onPressed: () async {
              final ok =
                  await InvoiceEmailService.sendInvoice(widget.invoice.id);

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(ok
                      ? "Invoice successfully sent to client"
                      : "Failed to send email"),
                ),
              );
            },
            tooltip: 'Send via Email',
          ),
          IconButton(
            icon: const Icon(Icons.share),
            onPressed: () {
              _shareInvoicePdf();
            },
            tooltip: 'Share PDF',
          ),
          IconButton(
            icon: const Icon(Icons.picture_as_pdf),
            onPressed: () {
              _exportInvoicePdf();
            },
            tooltip: 'Export to PDF',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Preview'),
            Tab(text: 'Options'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Preview Tab
          _buildPreviewTab(),
          // Options Tab
          _buildOptionsTab(),
        ],
      ),
    );
  }

  Widget _buildPreviewTab() {
    return Consumer<InvoicePreviewProvider>(
      builder: (context, provider, _) {
        if (provider.isGenerating) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 16),
                Text('Generating preview...'),
              ],
            ),
          );
        }

        if (provider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 64, color: Colors.red),
                const SizedBox(height: 16),
                Text(
                  'Error: ${provider.error}',
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: Colors.red),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshPreview,
                  child: const Text('Try Again'),
                ),
              ],
            ),
          );
        }

        if (provider.currentPreviewUrl == null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.description_outlined, size: 64),
                const SizedBox(height: 16),
                const Text('No preview generated'),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _refreshPreview,
                  child: const Text('Generate Preview'),
                ),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: _refreshPreview,
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Preview info
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue.shade200),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Preview Information',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildInfoRow(
                      'Template:',
                      _selectedTemplate,
                    ),
                    _buildInfoRow(
                      'Generated:',
                      provider.previewAge,
                    ),
                    if (provider.isPreviewExpired)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.orange.shade100,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'Preview has expired (older than 1 hour)',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.orange,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // PDF Viewer placeholder
              Container(
                height: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Stack(
                  children: [
                    // Show PDF or placeholder
                    provider.currentPreviewUrl != null
                        ? Container(
                            color: Colors.grey[100],
                            child: Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(
                                    Icons.picture_as_pdf,
                                    size: 64,
                                    color: Colors.red,
                                  ),
                                  const SizedBox(height: 16),
                                  const Text(
                                    'PDF Preview Loaded',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'Tap download to open',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          )
                        : Container(
                            color: Colors.grey[100],
                            child: const Center(
                              child: CircularProgressIndicator(),
                            ),
                          ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: provider.currentPreviewUrl != null
                          ? () => _downloadPreview(provider)
                          : null,
                      icon: const Icon(Icons.download),
                      label: const Text('Download PDF'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _refreshPreview,
                      icon: const Icon(Icons.refresh),
                      label: const Text('Regenerate'),
                      style: ElevatedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        backgroundColor: Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              // Share PDF button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: _shareInvoicePdf,
                  icon: const Icon(Icons.share),
                  label: const Text('Share PDF'),
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: Colors.green,
                  ),
                ),
              ),
              const SizedBox(height: 12),

              // Template selection button
              OutlinedButton.icon(
                onPressed: () {
                  Navigator.pushNamed(context, AppRoutes.templateGallery);
                },
                icon: const Icon(Icons.photo_library),
                label: const Text('Choose Template'),
                style: OutlinedButton.styleFrom(
                  padding:
                      const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                ),
              ),
              const SizedBox(height: 16),

              // Template variants
              if (provider.templateVariants.isNotEmpty)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Template Variants',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: provider.templateVariants.entries.map((entry) {
                        final template = entry.key;
                        final url = entry.value;

                        return Chip(
                          label: Text(template),
                          avatar: url != null
                              ? const Icon(Icons.check_circle,
                                  color: Colors.green)
                              : const Icon(Icons.error, color: Colors.red),
                          onDeleted: null,
                        );
                      }).toList(),
                    ),
                  ],
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildOptionsTab() {
    return Consumer<BusinessBrandingProvider>(
      builder: (context, brandingProvider, _) {
        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice Management Section
              const Text(
                'Invoice Management',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),

              // Status badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color:
                      _getStatusColor(widget.invoice.status).withOpacity(0.1),
                  border: Border.all(
                    color: _getStatusColor(widget.invoice.status),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _getStatusIcon(widget.invoice.status),
                      color: _getStatusColor(widget.invoice.status),
                      size: 20,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Status: ${widget.invoice.status}',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: _getStatusColor(widget.invoice.status),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Reminder toggle
              SwitchListTile(
                title: const Text('Send automatic reminders'),
                subtitle: const Text('Enable payment reminder emails'),
                value: widget.invoice.paidAt == null,
                onChanged: (val) async {
                  try {
                    await _invoiceService.toggleReminder(
                        widget.invoice.id, val);
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                              val ? 'Reminders enabled' : 'Reminders disabled'),
                          backgroundColor: val ? Colors.green : Colors.orange,
                        ),
                      );
                    }
                  } catch (e) {
                    if (mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
              const SizedBox(height: 12),

              // Due date editor
              ListTile(
                title: const Text('Due date'),
                subtitle: Text(
                  widget.invoice.dueDate != null
                      ? widget.invoice.dueDate!
                          .toLocal()
                          .toString()
                          .split(' ')
                          .first
                      : 'No due date',
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.edit_calendar),
                  onPressed: () async {
                    final picked = await showDatePicker(
                      context: context,
                      firstDate:
                          DateTime.now().subtract(const Duration(days: 365)),
                      lastDate:
                          DateTime.now().add(const Duration(days: 365 * 5)),
                      initialDate: widget.invoice.dueDate ?? DateTime.now(),
                    );
                    if (picked != null) {
                      try {
                        await _invoiceService.setDueDate(
                            widget.invoice.id, picked);
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text(
                                  'Due date set to ${picked.toString().split(' ').first}'),
                              backgroundColor: Colors.green,
                            ),
                          );
                        }
                      } catch (e) {
                        if (mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Error: $e'),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    }
                  },
                ),
              ),
              const SizedBox(height: 16),

              // Payment status buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton(
                      onPressed: widget.invoice.paidAt == null
                          ? () async {
                              try {
                                await _invoiceService.markInvoicePaid(
                                  widget.invoice.id,
                                  'manual',
                                );
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Marked as paid'),
                                      backgroundColor: Colors.green,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        disabledBackgroundColor: Colors.grey,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: const Text(
                        'Mark as Paid',
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: widget.invoice.paidAt != null
                          ? () async {
                              try {
                                await _invoiceService
                                    .markInvoiceUnpaid(widget.invoice.id);
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text('Marked as unpaid'),
                                      backgroundColor: Colors.orange,
                                    ),
                                  );
                                }
                              } catch (e) {
                                if (mounted) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text('Error: $e'),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      style: OutlinedButton.styleFrom(
                        disabledForegroundColor: Colors.grey,
                      ),
                      child: const Text('Mark as Unpaid'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              const Text(
                'Template Selection',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              _buildTemplateSelector(),
              const SizedBox(height: 32),

              const Text(
                'Display Options',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                title: const Text('Show Signature'),
                value: _showSignature,
                onChanged: (value) {
                  setState(() {
                    _showSignature = value;
                  });
                },
              ),
              const SizedBox(height: 16),
              TextField(
                decoration: InputDecoration(
                  labelText: 'Watermark Text',
                  hintText: 'E.g., DRAFT, PAID, COPY',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  prefixIcon: const Icon(Icons.format_underlined),
                ),
                onChanged: (value) {
                  setState(() {
                    _watermarkText = value.isNotEmpty ? value : null;
                  });
                },
                controller: TextEditingController(text: _watermarkText),
              ),
              const SizedBox(height: 32),

              // Action buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _refreshPreview,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    backgroundColor: Colors.blue,
                  ),
                  child: const Text(
                    'Update Preview',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _generateAllVariants,
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: const Text(
                    'Generate All Variants',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),

              // Current branding info
              const Text(
                'Current Branding',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              if (brandingProvider.branding != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (brandingProvider.branding?.companyDetails != null)
                        Text(
                          'Company: ${brandingProvider.branding?.companyDetails?.name ?? "N/A"}',
                        ),
                      const SizedBox(height: 4),
                      if (brandingProvider.branding?.primaryColor != null)
                        _buildColorPreview(
                          'Primary:',
                          brandingProvider.branding!.primaryColor!,
                        ),
                      const SizedBox(height: 4),
                      if (brandingProvider.branding?.accentColor != null)
                        _buildColorPreview(
                          'Accent:',
                          brandingProvider.branding!.accentColor!,
                        ),
                    ],
                  ),
                )
              else
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Text(
                    'No custom branding set. Using default colors.',
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildTemplateSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedTemplate,
      decoration: InputDecoration(
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.description),
      ),
      items: const [
        DropdownMenuItem(
          value: 'default',
          child: Text('Default - Professional'),
        ),
        DropdownMenuItem(
          value: 'minimal',
          child: Text('Minimal - Clean & Simple'),
        ),
        DropdownMenuItem(
          value: 'detailed',
          child: Text('Detailed - Complete Info'),
        ),
        DropdownMenuItem(
          value: 'compact',
          child: Text('Compact - Single Page'),
        ),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedTemplate = value;
          });
        }
      },
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            value,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildColorPreview(String label, String color) {
    return Row(
      children: [
        Text(label),
        const SizedBox(width: 8),
        Container(
          width: 30,
          height: 30,
          decoration: BoxDecoration(
            color: _parseColor(color),
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 8),
        Text(color),
      ],
    );
  }

  Color _parseColor(String colorString) {
    try {
      final buffer = StringBuffer();
      if (!colorString.startsWith('#')) buffer.write('#');
      buffer.write(colorString);
      return Color(
        int.parse(buffer.toString().replaceFirst('#', '0xff')),
      );
    } catch (e) {
      return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Colors.green;
      case 'unpaid':
        return Colors.orange;
      case 'overdue':
        return Colors.red;
      case 'draft':
        return Colors.blue;
      case 'partial':
        return Colors.amber;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status.toLowerCase()) {
      case 'paid':
        return Icons.check_circle;
      case 'unpaid':
        return Icons.schedule;
      case 'overdue':
        return Icons.error;
      case 'draft':
        return Icons.description;
      case 'partial':
        return Icons.info;
      default:
        return Icons.help;
    }
  }

  void _downloadPreview(InvoicePreviewProvider provider) {
    if (provider.currentPreviewUrl == null) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Opening PDF download...'),
        duration: Duration(seconds: 2),
      ),
    );

    // In a real app, you'd use url_launcher or similar
    // For now, show the URL
    print('Download URL: ${provider.currentPreviewUrl}');
  }
}
