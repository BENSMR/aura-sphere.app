import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_profile.dart';
import '../../providers/business_provider.dart';

/// Invoice Branding Screen
/// 
/// Allows customization of invoice appearance and branding:
/// - Invoice prefix (e.g., INV, AS, 2024)
/// - Watermark text
/// - Document footer
/// - Logo and signature upload
/// - Custom stamps
class InvoiceBrandingScreen extends StatefulWidget {
  const InvoiceBrandingScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceBrandingScreen> createState() => _InvoiceBrandingScreenState();
}

class _InvoiceBrandingScreenState extends State<InvoiceBrandingScreen> {
  late TextEditingController _prefixController;
  late TextEditingController _watermarkController;
  late TextEditingController _footerController;
  
  final _formKey = GlobalKey<FormState>();
  bool _isEditing = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final profile = context.read<BusinessProvider>().business;
    
    _prefixController = TextEditingController(
      text: profile?.invoicePrefix ?? 'INV',
    );
    _watermarkController = TextEditingController(
      text: profile?.watermarkText ?? '',
    );
    _footerController = TextEditingController(
      text: profile?.documentFooter ?? '',
    );
  }

  @override
  void dispose() {
    _prefixController.dispose();
    _watermarkController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _saveBranding() async {
    if (!_formKey.currentState!.validate()) return;

    final provider = context.read<BusinessProvider>();
    final currentProfile = provider.business;

    if (currentProfile == null) return;

    final updatedProfile = currentProfile.copyWith(
      invoicePrefix: _prefixController.text.trim().toUpperCase(),
      watermarkText: _watermarkController.text.trim(),
      documentFooter: _footerController.text.trim(),
    );

    try {
      await provider.updateBusinessProfile(updatedProfile.toMap());
      
      if (mounted) {
        setState(() => _isEditing = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice branding updated successfully')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  void _cancelEdit() {
    _initializeControllers();
    setState(() => _isEditing = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Branding'),
        elevation: 0,
        actions: [
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit),
              onPressed: () => setState(() => _isEditing = true),
              tooltip: 'Edit branding',
            ),
          if (_isEditing)
            IconButton(
              icon: const Icon(Icons.close),
              onPressed: _cancelEdit,
              tooltip: 'Cancel',
            ),
        ],
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          final profile = provider.business;
          if (profile == null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.document_scanner, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Business Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create a business profile first',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                ],
              ),
            );
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Preview Section
                  _buildPreviewSection(profile),
                  const SizedBox(height: 32),

                  // Invoice Number Section
                  _buildSectionHeader('Invoice Numbering'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _prefixController,
                    label: 'Invoice Prefix',
                    hint: 'e.g., INV, AS, 2024',
                    icon: Icons.tag,
                    enabled: _isEditing,
                    validator: (value) {
                      if (value?.isEmpty ?? true) return 'Prefix is required';
                      if (value!.length > 10) return 'Prefix too long (max 10 chars)';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Example: ${_prefixController.text}-0001',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Watermark Section
                  _buildSectionHeader('Watermark'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _watermarkController,
                    label: 'Watermark Text',
                    hint: 'e.g., DRAFT, CONFIDENTIAL',
                    icon: Icons.water_drop,
                    enabled: _isEditing,
                    maxLines: 1,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Appears faintly in background of invoice PDF',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Footer Section
                  _buildSectionHeader('Document Footer'),
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _footerController,
                    label: 'Footer Text',
                    hint: 'e.g., Thank you for your business!',
                    icon: Icons.text_fields,
                    enabled: _isEditing,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 8),
                  Padding(
                    padding: const EdgeInsets.only(left: 16),
                    child: Text(
                      'Appears at the bottom of invoice PDF',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
                  const SizedBox(height: 32),

                  // Signature & Stamp Section
                  _buildSectionHeader('Signature & Stamp'),
                  const SizedBox(height: 16),
                  _buildSignatureSection(provider),
                  const SizedBox(height: 32),

                  // Logo Section
                  _buildSectionHeader('Logo'),
                  const SizedBox(height: 16),
                  _buildLogoSection(provider),
                  const SizedBox(height: 32),

                  // Action Buttons
                  if (_isEditing)
                    SizedBox(
                      width: double.infinity,
                      child: Column(
                        children: [
                          ElevatedButton(
                            onPressed: _saveBranding,
                            child: const Text('Save Branding'),
                          ),
                          const SizedBox(height: 8),
                          OutlinedButton(
                            onPressed: _cancelEdit,
                            child: const Text('Cancel'),
                          ),
                        ],
                      ),
                    ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildPreviewSection(BusinessProfile profile) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Invoice Preview',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade300),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Watermark (background)
                  if (_watermarkController.text.isNotEmpty)
                    Opacity(
                      opacity: 0.1,
                      child: Text(
                        _watermarkController.text,
                        style: const TextStyle(
                          fontSize: 48,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  Text(
                    'Invoice ${_prefixController.text}-0042',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    profile.businessName,
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 24),
                  Text(
                    'Invoice items would appear here...',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                  const SizedBox(height: 24),
                  Container(height: 1, color: Colors.grey.shade300),
                  const SizedBox(height: 24),
                  if (_footerController.text.isNotEmpty) ...[
                    Text(
                      _footerController.text,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade700,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  Center(
                    child: Text(
                      'Page 1 of 1',
                      style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 16,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    String? hint,
    IconData? icon,
    bool enabled = true,
    int maxLines = 1,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      enabled: enabled,
      maxLines: maxLines,
      validator: validator,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        disabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  Widget _buildSignatureSection(BusinessProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.edit, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                const Text('Digital Signature'),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.business != null &&
                (provider.business!.signatureUrl.isNotEmpty))
              Container(
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Image.network(
                  provider.business!.signatureUrl,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                height: 80,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade100,
                ),
                child: Center(
                  child: Text(
                    'No signature uploaded',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Signature upload coming soon')),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Signature'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildLogoSection(BusinessProvider provider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.image, color: Colors.grey.shade600),
                const SizedBox(width: 8),
                const Text('Company Logo'),
              ],
            ),
            const SizedBox(height: 12),
            if (provider.business != null && 
                provider.business!.logoUrl.isNotEmpty)
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Image.network(
                  provider.business!.logoUrl,
                  fit: BoxFit.contain,
                ),
              )
            else
              Container(
                width: double.infinity,
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.shade300),
                  borderRadius: BorderRadius.circular(4),
                  color: Colors.grey.shade100,
                ),
                child: Center(
                  child: Text(
                    'No logo uploaded',
                    style: TextStyle(color: Colors.grey.shade600),
                  ),
                ),
              ),
            if (_isEditing) ...[
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Logo upload coming soon')),
                    );
                  },
                  icon: const Icon(Icons.upload_file),
                  label: const Text('Upload Logo'),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
