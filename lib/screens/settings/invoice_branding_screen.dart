import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_branding.dart';
import '../../providers/business_branding_provider.dart';

class InvoiceBrandingScreen extends StatefulWidget {
  const InvoiceBrandingScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceBrandingScreen> createState() => _InvoiceBrandingScreenState();
}

class _InvoiceBrandingScreenState extends State<InvoiceBrandingScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _invoiceTemplateController;
  late TextEditingController _receiptTemplateController;
  late TextEditingController _footerNoteController;
  late TextEditingController _watermarkController;
  late TextEditingController _signatureUrlController;
  bool _showSignature = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _invoiceTemplateController = TextEditingController();
    _receiptTemplateController = TextEditingController();
    _footerNoteController = TextEditingController();
    _watermarkController = TextEditingController();
    _signatureUrlController = TextEditingController();
    _loadBrandingData();
  }

  void _loadBrandingData() {
    final branding = context.read<BusinessBrandingProvider>().branding;
    if (branding != null) {
      _invoiceTemplateController.text = branding.invoiceTemplateId ?? 'default';
      _receiptTemplateController.text = branding.receiptTemplateId ?? 'default';
      _footerNoteController.text = branding.footerNote ?? '';
      _watermarkController.text = branding.watermarkText ?? '';
      _signatureUrlController.text = branding.signatureUrl ?? '';
      _showSignature = branding.showSignature;
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _invoiceTemplateController.dispose();
    _receiptTemplateController.dispose();
    _footerNoteController.dispose();
    _watermarkController.dispose();
    _signatureUrlController.dispose();
    super.dispose();
  }

  Future<void> _saveSettings() async {
    final provider = context.read<BusinessBrandingProvider>();
    final currentBranding = provider.branding ?? BusinessBranding();

    final updatedBranding = currentBranding.copyWith(
      invoiceTemplateId: _invoiceTemplateController.text,
      receiptTemplateId: _receiptTemplateController.text,
      footerNote: _footerNoteController.text.isNotEmpty
          ? _footerNoteController.text
          : null,
      watermarkText: _watermarkController.text.isNotEmpty
          ? _watermarkController.text
          : null,
      showSignature: _showSignature,
      signatureUrl: _signatureUrlController.text.isNotEmpty
          ? _signatureUrlController.text
          : null,
    );

    await provider.updateBranding(updatedBranding);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Invoice branding updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Branding'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Templates'),
            Tab(text: 'Customization'),
            Tab(text: 'Preview'),
          ],
        ),
      ),
      body: Consumer<BusinessBrandingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return TabBarView(
            controller: _tabController,
            children: [
              // Templates Tab
              _buildTemplatesTab(provider),
              // Customization Tab
              _buildCustomizationTab(provider),
              // Preview Tab
              _buildPreviewTab(provider),
            ],
          );
        },
      ),
    );
  }

  Widget _buildTemplatesTab(BusinessBrandingProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoice Template',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select which template to use for invoice generation',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildTemplateSelector(
            title: 'Invoice Template',
            controller: _invoiceTemplateController,
            options: [
              ('default', 'Default - Professional'),
              ('minimal', 'Minimal - Clean & Simple'),
              ('detailed', 'Detailed - Complete Info'),
              ('compact', 'Compact - Single Page'),
            ],
          ),
          const SizedBox(height: 32),
          const Text(
            'Receipt Template',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Select which template to use for receipt generation',
            style: TextStyle(fontSize: 14, color: Colors.grey),
          ),
          const SizedBox(height: 16),
          _buildTemplateSelector(
            title: 'Receipt Template',
            controller: _receiptTemplateController,
            options: [
              ('default', 'Default - Professional'),
              ('minimal', 'Minimal - Clean & Simple'),
              ('detailed', 'Detailed - Complete Info'),
              ('compact', 'Compact - Single Page'),
            ],
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Save Templates',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (provider.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Error: ${provider.error}',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTemplateSelector({
    required String title,
    required TextEditingController controller,
    required List<(String, String)> options,
  }) {
    return DropdownButtonFormField<String>(
      value: controller.text.isNotEmpty ? controller.text : 'default',
      decoration: InputDecoration(
        labelText: title,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        prefixIcon: const Icon(Icons.description),
      ),
      items: options.map((option) {
        return DropdownMenuItem(
          value: option.$1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(option.$2),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          controller.text = value;
        }
      },
    );
  }

  Widget _buildCustomizationTab(BusinessBrandingProvider provider) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Receipt Customization',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _footerNoteController,
            maxLines: 2,
            decoration: InputDecoration(
              labelText: 'Footer Note',
              hintText: 'E.g., "Thank you for your business!"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.note),
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _watermarkController,
            decoration: InputDecoration(
              labelText: 'Watermark Text',
              hintText: 'E.g., "PAID", "DRAFT", "ORIGINAL"',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.format_underlined),
            ),
          ),
          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 24),
          const Text(
            'Signature',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          SwitchListTile(
            title: const Text('Show Signature on Receipts'),
            subtitle: const Text('Display your digital signature'),
            value: _showSignature,
            onChanged: (value) {
              setState(() {
                _showSignature = value;
              });
            },
          ),
          if (_showSignature) ...[
            const SizedBox(height: 16),
            TextField(
              controller: _signatureUrlController,
              decoration: InputDecoration(
                labelText: 'Signature Image URL',
                hintText: 'https://example.com/signature.png',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.image),
                helperText: 'Upload your signature as an image and paste the URL',
              ),
            ),
            const SizedBox(height: 12),
            if (_signatureUrlController.text.isNotEmpty)
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Signature Preview:',
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 8),
                    Image.network(
                      _signatureUrlController.text,
                      height: 80,
                      errorBuilder: (context, error, stackTrace) {
                        return const Text(
                          'Could not load signature image',
                          style: TextStyle(color: Colors.red),
                        );
                      },
                    ),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveSettings,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Save Customization',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (provider.error != null) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.red.shade100,
                border: Border.all(color: Colors.red),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                'Error: ${provider.error}',
                style: TextStyle(color: Colors.red.shade700),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildPreviewTab(BusinessBrandingProvider provider) {
    final branding = provider.branding;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Invoice Preview',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          Container(
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey),
              borderRadius: BorderRadius.circular(8),
            ),
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                if (branding?.logoUrl != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: Image.network(
                      branding!.logoUrl!,
                      height: 60,
                      errorBuilder: (context, error, stackTrace) {
                        return const Icon(Icons.image, size: 60);
                      },
                    ),
                  ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'INVOICE',
                      style: TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (branding?.watermarkText != null)
                      Text(
                        branding!.watermarkText!,
                        style: TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.withOpacity(0.3),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 24),
                const Divider(),
                const SizedBox(height: 16),
                // Company Details
                if (branding?.companyDetails != null) ...[
                  Text(
                    branding!.companyDetails!.name,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  if (branding.companyDetails?.address != null)
                    Text(branding.companyDetails!.address!),
                  if (branding.companyDetails?.phone != null)
                    Text('Phone: ${branding.companyDetails!.phone}'),
                  if (branding.companyDetails?.email != null)
                    Text('Email: ${branding.companyDetails!.email}'),
                  const SizedBox(height: 24),
                  const Divider(),
                  const SizedBox(height: 16),
                ],
                // Invoice Details
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: const [
                        Text('Invoice #:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                        SizedBox(height: 8),
                        Text('Due Date:', style: TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: const [
                        Text('INV-001'),
                        SizedBox(height: 8),
                        Text('Dec 1, 2025'),
                        SizedBox(height: 8),
                        Text('Dec 31, 2025'),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                // Items Table
                const Text('Items', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Description')),
                      Text('Amount'),
                    ],
                  ),
                ),
                const Divider(),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(child: Text('Professional Services')),
                      Text('\$1,000.00'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: const [
                    Expanded(
                      child: Text('Total:', textAlign: TextAlign.end),
                    ),
                    SizedBox(width: 16),
                    Text(
                      '\$1,000.00',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                if (branding?.footerNote != null) ...[
                  const Divider(),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      branding!.footerNote!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        fontSize: 12,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 16),
                if (branding?.showSignature == true && branding?.signatureUrl != null) ...[
                  const Divider(),
                  const SizedBox(height: 8),
                  Image.network(
                    branding!.signatureUrl!,
                    height: 40,
                    errorBuilder: (context, error, stackTrace) {
                      return const Text('Signature');
                    },
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Settings Summary',
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          _buildSummaryItem(
            'Invoice Template',
            _invoiceTemplateController.text.isNotEmpty
                ? _invoiceTemplateController.text
                : 'default',
          ),
          _buildSummaryItem(
            'Receipt Template',
            _receiptTemplateController.text.isNotEmpty
                ? _receiptTemplateController.text
                : 'default',
          ),
          if (_footerNoteController.text.isNotEmpty)
            _buildSummaryItem('Footer Note', _footerNoteController.text),
          if (_watermarkController.text.isNotEmpty)
            _buildSummaryItem('Watermark', _watermarkController.text),
          if (_showSignature)
            _buildSummaryItem('Signature', 'Enabled'),
        ],
      ),
    );
  }

  Widget _buildSummaryItem(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: Colors.grey)),
          Text(value, style: const TextStyle(fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }
}
