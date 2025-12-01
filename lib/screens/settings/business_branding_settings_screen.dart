import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_branding.dart';
import '../../providers/business_branding_provider.dart';

class BusinessBrandingSettingsScreen extends StatefulWidget {
  const BusinessBrandingSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BusinessBrandingSettingsScreen> createState() =>
      _BusinessBrandingSettingsScreenState();
}

class _BusinessBrandingSettingsScreenState
    extends State<BusinessBrandingSettingsScreen> {
  late TextEditingController _logoUrlController;
  late TextEditingController _primaryColorController;
  late TextEditingController _accentColorController;
  late TextEditingController _textColorController;
  late TextEditingController _footerNoteController;
  late TextEditingController _watermarkController;
  late TextEditingController _signatureUrlController;

  // Company details controllers
  late TextEditingController _companyNameController;
  late TextEditingController _companyPhoneController;
  late TextEditingController _companyEmailController;
  late TextEditingController _companyWebsiteController;
  late TextEditingController _companyAddressController;

  bool _showSignature = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadBranding();
  }

  void _initializeControllers() {
    _logoUrlController = TextEditingController();
    _primaryColorController = TextEditingController();
    _accentColorController = TextEditingController();
    _textColorController = TextEditingController();
    _footerNoteController = TextEditingController();
    _watermarkController = TextEditingController();
    _signatureUrlController = TextEditingController();
    _companyNameController = TextEditingController();
    _companyPhoneController = TextEditingController();
    _companyEmailController = TextEditingController();
    _companyWebsiteController = TextEditingController();
    _companyAddressController = TextEditingController();
  }

  void _loadBranding() {
    final branding =
        context.read<BusinessBrandingProvider>().branding;

    if (branding != null) {
      _logoUrlController.text = branding.logoUrl ?? '';
      _primaryColorController.text = branding.primaryColor ?? '#1976D2';
      _accentColorController.text = branding.accentColor ?? '#FFC107';
      _textColorController.text = branding.textColor ?? '#000000';
      _footerNoteController.text = branding.footerNote ?? '';
      _watermarkController.text = branding.watermarkText ?? '';
      _signatureUrlController.text = branding.signatureUrl ?? '';
      _showSignature = branding.showSignature;

      if (branding.companyDetails != null) {
        _companyNameController.text =
            branding.companyDetails?.name ?? '';
        _companyPhoneController.text =
            branding.companyDetails?.phone ?? '';
        _companyEmailController.text =
            branding.companyDetails?.email ?? '';
        _companyWebsiteController.text =
            branding.companyDetails?.website ?? '';
        _companyAddressController.text =
            branding.companyDetails?.address ?? '';
      }
    }
  }

  @override
  void dispose() {
    _logoUrlController.dispose();
    _primaryColorController.dispose();
    _accentColorController.dispose();
    _textColorController.dispose();
    _footerNoteController.dispose();
    _watermarkController.dispose();
    _signatureUrlController.dispose();
    _companyNameController.dispose();
    _companyPhoneController.dispose();
    _companyEmailController.dispose();
    _companyWebsiteController.dispose();
    _companyAddressController.dispose();
    super.dispose();
  }

  void _saveSettings() async {
    final provider = context.read<BusinessBrandingProvider>();

    final companyDetails = CompanyDetails(
      name: _companyNameController.text,
      phone: _companyPhoneController.text.isNotEmpty
          ? _companyPhoneController.text
          : null,
      email: _companyEmailController.text.isNotEmpty
          ? _companyEmailController.text
          : null,
      website: _companyWebsiteController.text.isNotEmpty
          ? _companyWebsiteController.text
          : null,
      address: _companyAddressController.text.isNotEmpty
          ? _companyAddressController.text
          : null,
    );

    final branding = BusinessBranding(
      logoUrl: _logoUrlController.text.isNotEmpty
          ? _logoUrlController.text
          : null,
      primaryColor: _primaryColorController.text.isNotEmpty
          ? _primaryColorController.text
          : null,
      accentColor: _accentColorController.text.isNotEmpty
          ? _accentColorController.text
          : null,
      textColor: _textColorController.text.isNotEmpty
          ? _textColorController.text
          : null,
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
      companyDetails: companyDetails,
    );

    await provider.updateBranding(branding);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business branding updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Branding'),
        elevation: 0,
      ),
      body: Consumer<BusinessBrandingProvider>(
        builder: (context, provider, _) {
          if (provider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Visual Branding Section
                _buildSectionHeader('Visual Branding'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _logoUrlController,
                  label: 'Logo URL',
                  hint: 'https://example.com/logo.png',
                ),
                const SizedBox(height: 16),
                _buildColorField(
                  controller: _primaryColorController,
                  label: 'Primary Color',
                ),
                const SizedBox(height: 16),
                _buildColorField(
                  controller: _accentColorController,
                  label: 'Accent Color',
                ),
                const SizedBox(height: 16),
                _buildColorField(
                  controller: _textColorController,
                  label: 'Text Color',
                ),
                const SizedBox(height: 32),

                // Company Details Section
                _buildSectionHeader('Company Details'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyNameController,
                  label: 'Company Name',
                  hint: 'Your Company Name',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyPhoneController,
                  label: 'Phone',
                  hint: '+1 (555) 123-4567',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyEmailController,
                  label: 'Email',
                  hint: 'contact@example.com',
                  keyboardType: TextInputType.emailAddress,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyWebsiteController,
                  label: 'Website',
                  hint: 'https://example.com',
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _companyAddressController,
                  label: 'Address',
                  hint: '123 Main St, City, State ZIP',
                  maxLines: 3,
                ),
                const SizedBox(height: 32),

                // Receipt Customization Section
                _buildSectionHeader('Receipt Customization'),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _footerNoteController,
                  label: 'Footer Note',
                  hint: 'Thank you for your business!',
                  maxLines: 2,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _watermarkController,
                  label: 'Watermark Text',
                  hint: 'PAID',
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Show Signature'),
                  value: _showSignature,
                  onChanged: (value) {
                    setState(() {
                      _showSignature = value;
                    });
                  },
                ),
                if (_showSignature) ...[
                  const SizedBox(height: 16),
                  _buildTextField(
                    controller: _signatureUrlController,
                    label: 'Signature Image URL',
                    hint: 'https://example.com/signature.png',
                  ),
                ],
                const SizedBox(height: 32),

                // Save Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _saveSettings,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.blue,
                    ),
                    child: const Text(
                      'Save Settings',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                // Error message
                if (provider.error != null) ...[
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
        },
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.bold,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.edit),
      ),
    );
  }

  Widget _buildColorField({
    required TextEditingController controller,
    required String label,
  }) {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: controller,
            decoration: InputDecoration(
              labelText: label,
              hintText: '#1976D2',
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              prefixIcon: const Icon(Icons.palette),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 60,
          height: 60,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Container(
            decoration: BoxDecoration(
              color: _getColorFromHex(controller.text),
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ],
    );
  }

  Color _getColorFromHex(String hexString) {
    try {
      final buffer = StringBuffer();
      if (!hexString.startsWith('#')) buffer.write('#');
      buffer.write(hexString);
      return Color(int.parse(buffer.toString().replaceFirst('#', '0xff')));
    } catch (e) {
      return Colors.grey;
    }
  }
}
