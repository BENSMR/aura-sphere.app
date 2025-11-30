import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../models/business_profile.dart';
import '../../providers/business_provider.dart';

class BusinessProfileFormScreen extends StatefulWidget {
  final BusinessProfile? initialProfile;

  const BusinessProfileFormScreen({
    Key? key,
    this.initialProfile,
  }) : super(key: key);

  @override
  State<BusinessProfileFormScreen> createState() =>
      _BusinessProfileFormScreenState();
}

class _BusinessProfileFormScreenState extends State<BusinessProfileFormScreen> {
  late TextEditingController _businessNameController;
  late TextEditingController _legalNameController;
  late TextEditingController _addressController;
  late TextEditingController _cityController;
  late TextEditingController _postalCodeController;
  late TextEditingController _taxIdController;
  late TextEditingController _vatNumberController;
  late TextEditingController _invoicePrefixController;
  late TextEditingController _footerController;
  late TextEditingController _watermarkController;

  File? _selectedLogoFile;
  String _selectedBrandColor = '#0A84FF';
  String _selectedInvoiceTemplate = 'minimal';
  String _selectedCurrency = 'EUR';
  String _selectedLanguage = 'en';

  @override
  void initState() {
    super.initState();
    final profile = widget.initialProfile;

    _businessNameController =
        TextEditingController(text: profile?.businessName ?? '');
    _legalNameController =
        TextEditingController(text: profile?.legalName ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
    _cityController = TextEditingController(text: profile?.city ?? '');
    _postalCodeController =
        TextEditingController(text: profile?.postalCode ?? '');
    _taxIdController = TextEditingController(text: profile?.taxId ?? '');
    _vatNumberController =
        TextEditingController(text: profile?.vatNumber ?? '');
    _invoicePrefixController =
        TextEditingController(text: profile?.invoicePrefix ?? 'INV-');
    _footerController =
        TextEditingController(text: profile?.documentFooter ?? '');
    _watermarkController =
        TextEditingController(text: profile?.watermarkText ?? '');

    _selectedBrandColor = profile?.brandColor ?? '#0A84FF';
    _selectedInvoiceTemplate = profile?.invoiceTemplate ?? 'minimal';
    _selectedCurrency = profile?.defaultCurrency ?? 'EUR';
    _selectedLanguage = profile?.defaultLanguage ?? 'en';
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _legalNameController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _postalCodeController.dispose();
    _taxIdController.dispose();
    _vatNumberController.dispose();
    _invoicePrefixController.dispose();
    _footerController.dispose();
    _watermarkController.dispose();
    super.dispose();
  }

  Future<void> _pickLogo() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _selectedLogoFile = File(pickedFile.path);
      });
    }
  }

  Future<void> _saveProfile() async {
    final businessProvider = context.read<BusinessProvider>();

    try {
      // Upload logo if selected
      if (_selectedLogoFile != null) {
        await businessProvider.uploadLogo(_selectedLogoFile!);
      }

      // Save profile data
      await businessProvider.saveProfile({
        'businessName': _businessNameController.text,
        'legalName': _legalNameController.text,
        'address': _addressController.text,
        'city': _cityController.text,
        'postalCode': _postalCodeController.text,
        'taxId': _taxIdController.text,
        'vatNumber': _vatNumberController.text,
        'invoicePrefix': _invoicePrefixController.text,
        'documentFooter': _footerController.text,
        'watermarkText': _watermarkController.text,
        'brandColor': _selectedBrandColor,
        'invoiceTemplate': _selectedInvoiceTemplate,
        'defaultCurrency': _selectedCurrency,
        'defaultLanguage': _selectedLanguage,
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Profile saved successfully!')),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final businessProvider = context.watch<BusinessProvider>();
    final profile = businessProvider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Business Profile'),
        elevation: 0,
      ),
      body: businessProvider.isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo Section
                  Center(
                    child: GestureDetector(
                      onTap: _pickLogo,
                      child: Stack(
                        children: [
                          Container(
                            width: 120,
                            height: 120,
                            decoration: BoxDecoration(
                              color: Colors.grey[200],
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: Colors.grey[300]!,
                                width: 2,
                              ),
                            ),
                            child: _selectedLogoFile != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(16),
                                    child: Image.file(
                                      _selectedLogoFile!,
                                      fit: BoxFit.cover,
                                    ),
                                  )
                                : (profile?.logoUrl.isNotEmpty ?? false)
                                    ? ClipRRect(
                                        borderRadius:
                                            BorderRadius.circular(16),
                                        child: Image.network(
                                          profile!.logoUrl,
                                          fit: BoxFit.cover,
                                          errorBuilder: (_, __, ___) =>
                                              Icon(
                                            Icons.image_not_supported,
                                            size: 48,
                                            color: Colors.grey[400],
                                          ),
                                        ),
                                      )
                                    : Icon(
                                        Icons.camera_alt,
                                        size: 48,
                                        color: Colors.grey[600],
                                      ),
                          ),
                          Positioned(
                            bottom: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: Colors.blue,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: const Icon(
                                Icons.edit,
                                color: Colors.white,
                                size: 16,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 32),

                  // Business Information Section
                  Text(
                    'Business Information',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _businessNameController,
                    label: 'Business Name',
                    hint: 'Enter your business name',
                    icon: Icons.business,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _legalNameController,
                    label: 'Legal Name',
                    hint: 'Enter legal business name',
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _taxIdController,
                    label: 'Tax ID',
                    hint: 'e.g., 12-3456789',
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _vatNumberController,
                    label: 'VAT Number',
                    hint: 'e.g., DE123456789',
                  ),
                  const SizedBox(height: 32),

                  // Address Section
                  Text(
                    'Address',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _addressController,
                    label: 'Street Address',
                    hint: 'Enter street address',
                    icon: Icons.location_on,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _cityController,
                    label: 'City',
                    hint: 'Enter city',
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _postalCodeController,
                    label: 'Postal Code',
                    hint: 'Enter postal code',
                  ),
                  const SizedBox(height: 32),

                  // Invoice Settings Section
                  Text(
                    'Invoice Settings',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _invoicePrefixController,
                    label: 'Invoice Prefix',
                    hint: 'e.g., INV-',
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    label: 'Invoice Template',
                    value: _selectedInvoiceTemplate,
                    items: const ['minimal', 'detailed', 'professional'],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedInvoiceTemplate = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    label: 'Default Currency',
                    value: _selectedCurrency,
                    items: const ['EUR', 'USD', 'GBP', 'CHF', 'JPY'],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedCurrency = value);
                      }
                    },
                  ),
                  const SizedBox(height: 16),

                  _buildDropdown(
                    label: 'Default Language',
                    value: _selectedLanguage,
                    items: const ['en', 'de', 'fr', 'es', 'it'],
                    onChanged: (value) {
                      if (value != null) {
                        setState(() => _selectedLanguage = value);
                      }
                    },
                  ),
                  const SizedBox(height: 32),

                  // Branding Section
                  Text(
                    'Branding',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 16),

                  _buildColorPickerRow(context),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _watermarkController,
                    label: 'Watermark Text',
                    hint: 'e.g., DRAFT, CONFIDENTIAL',
                    maxLines: 2,
                  ),
                  const SizedBox(height: 16),

                  _buildTextField(
                    controller: _footerController,
                    label: 'Document Footer',
                    hint: 'Footer text for invoices',
                    maxLines: 3,
                  ),
                  const SizedBox(height: 32),

                  // Save Button & Status
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (businessProvider.isSaving)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Row(
                            children: [
                              const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Saving...',
                                style:
                                    Theme.of(context).textTheme.bodySmall,
                              ),
                            ],
                          ),
                        ),
                      if (businessProvider.hasError)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: Colors.red.shade50,
                              border: Border.all(color: Colors.red),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Row(
                              children: [
                                const Icon(Icons.error_outline,
                                    color: Colors.red, size: 20),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    businessProvider.error ?? 'Unknown error',
                                    style: Theme.of(context)
                                        .textTheme
                                        .bodySmall
                                        ?.copyWith(color: Colors.red),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton.icon(
                          onPressed: businessProvider.isSaving
                              ? null
                              : _saveProfile,
                          icon: const Icon(Icons.save),
                          label: const Text('Save Profile'),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),
                ],
              ),
            ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        prefixIcon: icon != null ? Icon(icon) : null,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
    );
  }

  Widget _buildDropdown({
    required String label,
    required String value,
    required List<String> items,
    required Function(String?) onChanged,
  }) {
    return DropdownButtonFormField<String>(
      value: value,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
      ),
      items: items
          .map((item) => DropdownMenuItem(
                value: item,
                child: Text(item),
              ))
          .toList(),
      onChanged: onChanged,
    );
  }

  Widget _buildColorPickerRow(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          'Brand Color',
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        GestureDetector(
          onTap: () => _showColorPicker(context),
          child: Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Color(
                int.parse(
                  '0xff${_selectedBrandColor.replaceAll('#', '')}',
                ),
              ),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey[300]!),
            ),
          ),
        ),
      ],
    );
  }

  void _showColorPicker(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Brand Color'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              '#0A84FF', // Blue
              '#FF3B30', // Red
              '#34C759', // Green
              '#FFB500', // Orange
              '#AF52DE', // Purple
              '#00C7BE', // Teal
              '#FF9500', // Orange
              '#A2845E', // Brown
              '#8E8E93', // Gray
              '#000000', // Black
            ]
                .map(
                  (color) => GestureDetector(
                    onTap: () {
                      setState(() => _selectedBrandColor = color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse('0xff${color.replaceAll('#', '')}'),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: _selectedBrandColor == color
                            ? Border.all(
                                color: Colors.black,
                                width: 3,
                              )
                            : null,
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
