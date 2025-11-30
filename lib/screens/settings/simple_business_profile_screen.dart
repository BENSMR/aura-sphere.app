import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../providers/business_provider.dart';

/// Simple Business Profile Screen with Auto-Save via Debounce
///
/// This screen demonstrates the debounce pattern for real-time form updates.
/// Every text field change auto-saves after 600ms of inactivity.
class SimpleBusinessProfileScreen extends StatefulWidget {
  const SimpleBusinessProfileScreen({super.key});

  @override
  State<SimpleBusinessProfileScreen> createState() =>
      _SimpleBusinessProfileScreenState();
}

class _SimpleBusinessProfileScreenState
    extends State<SimpleBusinessProfileScreen> {
  late TextEditingController _businessNameController;
  late TextEditingController _legalNameController;
  late TextEditingController _addressController;
  late TextEditingController _invoicePrefixController;
  late TextEditingController _footerController;

  @override
  void initState() {
    super.initState();
    final provider = context.read<BusinessProvider>();
    final profile = provider.profile;

    _businessNameController =
        TextEditingController(text: profile?.businessName ?? '');
    _legalNameController =
        TextEditingController(text: profile?.legalName ?? '');
    _addressController = TextEditingController(text: profile?.address ?? '');
    _invoicePrefixController =
        TextEditingController(text: profile?.invoicePrefix ?? 'INV-');
    _footerController =
        TextEditingController(text: profile?.documentFooter ?? '');
  }

  @override
  void dispose() {
    _businessNameController.dispose();
    _legalNameController.dispose();
    _addressController.dispose();
    _invoicePrefixController.dispose();
    _footerController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadLogo(BuildContext context) async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && mounted) {
      try {
        final businessProvider = context.read<BusinessProvider>();
        await businessProvider.uploadLogo(File(pickedFile.path));

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Logo uploaded successfully!')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error uploading logo: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<BusinessProvider>(context);

    if (provider.isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final profile = provider.profile;

    return Scaffold(
      appBar: AppBar(
        title: const Text("Business Profile"),
        elevation: 0,
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // ═══════════════════════════════════════════════════════════════
          // LOGO SECTION
          // ═══════════════════════════════════════════════════════════════
          Center(
            child: GestureDetector(
              onTap: () => _pickAndUploadLogo(context),
              child: Stack(
                children: [
                  CircleAvatar(
                    radius: 60,
                    backgroundColor: Colors.grey[200],
                    backgroundImage: (profile?.logoUrl.isNotEmpty ?? false)
                        ? NetworkImage(profile!.logoUrl)
                        : null,
                    child: (profile?.logoUrl.isEmpty ?? true)
                        ? Icon(
                            Icons.camera_alt,
                            size: 40,
                            color: Colors.grey[600],
                          )
                        : null,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      padding: const EdgeInsets.all(6),
                      decoration: BoxDecoration(
                        color: Colors.blue,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.edit,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // ═══════════════════════════════════════════════════════════════
          // AUTO-SAVE INDICATOR
          // ═══════════════════════════════════════════════════════════════
          if (provider.isSaving)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  border: Border.all(color: Colors.blue),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor:
                            AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Auto-saving changes...',
                      style: Theme.of(context)
                          .textTheme
                          .bodySmall
                          ?.copyWith(color: Colors.blue),
                    ),
                  ],
                ),
              ),
            ),

          if (provider.hasError)
            Padding(
              padding: const EdgeInsets.only(bottom: 16),
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
                        provider.error ?? 'Error saving changes',
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

          // ═══════════════════════════════════════════════════════════════
          // BUSINESS NAME (Auto-saves on change with 600ms debounce)
          // ═══════════════════════════════════════════════════════════════
          _buildInput(
            context,
            label: "Business Name",
            controller: _businessNameController,
            onChanged: (value) =>
                provider.updateFieldDebounced('businessName', value),
            icon: Icons.business,
          ),

          // ═══════════════════════════════════════════════════════════════
          // LEGAL NAME
          // ═══════════════════════════════════════════════════════════════
          _buildInput(
            context,
            label: "Legal Name",
            controller: _legalNameController,
            onChanged: (value) =>
                provider.updateFieldDebounced('legalName', value),
          ),

          // ═══════════════════════════════════════════════════════════════
          // ADDRESS
          // ═══════════════════════════════════════════════════════════════
          _buildInput(
            context,
            label: "Address",
            controller: _addressController,
            onChanged: (value) =>
                provider.updateFieldDebounced('address', value),
            icon: Icons.location_on,
          ),

          // ═══════════════════════════════════════════════════════════════
          // INVOICE SETTINGS HEADER
          // ═══════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            child: Text(
              "Invoice Settings",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          _buildInput(
            context,
            label: "Invoice Prefix",
            controller: _invoicePrefixController,
            onChanged: (value) =>
                provider.updateFieldDebounced('invoicePrefix', value),
            hint: "e.g., INV-, AS-",
          ),

          _buildInput(
            context,
            label: "Footer Text",
            controller: _footerController,
            onChanged: (value) =>
                provider.updateFieldDebounced('documentFooter', value),
            hint: "Invoice footer text",
            maxLines: 2,
          ),

          // ═══════════════════════════════════════════════════════════════
          // BRANDING HEADER
          // ═══════════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 16),
            child: Text(
              "Branding",
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
          ),

          // ═══════════════════════════════════════════════════════════════
          // BRAND COLOR PICKER
          // ═══════════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
            decoration: BoxDecoration(
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Brand Color",
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                GestureDetector(
                  onTap: () => _showColorPicker(context, provider),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Color(
                        int.parse(
                          "0xff${(profile?.brandColor ?? '#0A84FF').replaceAll('#', '')}",
                        ),
                      ),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          // ═══════════════════════════════════════════════════════════════
          // PROFILE INFO DISPLAY
          // ═══════════════════════════════════════════════════════════════
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Settings",
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                  const SizedBox(height: 12),
                  _buildInfoRow(
                    context,
                    "Currency",
                    profile?.defaultCurrency ?? "EUR",
                  ),
                  _buildInfoRow(
                    context,
                    "Language",
                    profile?.defaultLanguage ?? "en",
                  ),
                  _buildInfoRow(
                    context,
                    "Template",
                    profile?.invoiceTemplate ?? "minimal",
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildInput(
    BuildContext context, {
    required String label,
    required TextEditingController controller,
    required Function(String) onChanged,
    String? hint,
    IconData? icon,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: onChanged,
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: icon != null ? Icon(icon) : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: BorderSide(color: Colors.grey[300]!),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Colors.blue, width: 2),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
          Text(
            value,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w600,
                ),
          ),
        ],
      ),
    );
  }

  void _showColorPicker(BuildContext context, BusinessProvider provider) {
    final colors = [
      '#0A84FF', // Blue
      '#FF3B30', // Red
      '#34C759', // Green
      '#FFB500', // Orange
      '#AF52DE', // Purple
      '#00C7BE', // Teal
      '#A2845E', // Brown
      '#000000', // Black
    ];

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Select Brand Color'),
        content: SingleChildScrollView(
          child: Wrap(
            spacing: 12,
            runSpacing: 12,
            children: colors
                .map(
                  (color) => GestureDetector(
                    onTap: () {
                      provider.updateFieldDebounced('brandColor', color);
                      Navigator.pop(context);
                    },
                    child: Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: Color(
                          int.parse('0xff${color.replaceAll('#', '')}'),
                        ),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: (provider.profile?.brandColor ?? '#0A84FF') ==
                                  color
                              ? Colors.black
                              : Colors.transparent,
                          width: 3,
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
        ),
      ),
    );
  }
}
