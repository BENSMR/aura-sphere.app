import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/invoice_model.dart';
import '../../providers/invoice_preview_provider.dart';
import '../../providers/business_branding_provider.dart';

class InvoicePreviewScreen extends StatefulWidget {
  final Invoice invoice;

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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadBrandingPreferences();
    _generateInitialPreview();
  }

  void _loadBrandingPreferences() {
    final branding =
        context.read<BusinessBrandingProvider>().branding;

    if (branding != null) {
      _selectedTemplate =
          branding.invoiceTemplateId ?? 'default';
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Preview'),
        elevation: 0,
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
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
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
      items: [
        ('default', 'Default - Professional'),
        ('minimal', 'Minimal - Clean & Simple'),
        ('detailed', 'Detailed - Complete Info'),
        ('compact', 'Compact - Single Page'),
      ].map((option) {
        return DropdownMenuItem(
          value: option.$1,
          child: Text(option.$2),
        );
      }).toList(),
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
