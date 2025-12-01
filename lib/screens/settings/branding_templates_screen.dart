import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_branding.dart';
import '../../providers/business_branding_provider.dart';
import '../../services/branding_profile_service.dart';

class BrandingTemplatesScreen extends StatefulWidget {
  final String? companyName;

  const BrandingTemplatesScreen({
    Key? key,
    this.companyName,
  }) : super(key: key);

  @override
  State<BrandingTemplatesScreen> createState() =>
      _BrandingTemplatesScreenState();
}

class _BrandingTemplatesScreenState extends State<BrandingTemplatesScreen> {
  final BrandingProfileService _service = BrandingProfileService();
  late TextEditingController _companyNameController;
  List<BrandingTemplate> _templates = [];
  bool _isLoading = true;
  String? _selectedTemplateId;

  @override
  void initState() {
    super.initState();
    _companyNameController =
        TextEditingController(text: widget.companyName ?? '');
    _loadTemplates();
  }

  Future<void> _loadTemplates() async {
    try {
      final templates = await _service.listBrandingTemplates();
      setState(() {
        _templates = templates;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading templates: $e')),
        );
      }
    }
  }

  Future<void> _applyTemplate(String templateId) async {
    if (_companyNameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter company name')),
      );
      return;
    }

    setState(() {
      _selectedTemplateId = templateId;
    });

    try {
      final branding = await _service.createBrandingFromTemplate(
        templateId: templateId,
        companyName: _companyNameController.text,
      );

      // Update provider with new branding
      if (mounted) {
        await context.read<BusinessBrandingProvider>().updateBranding(branding);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Branding template applied successfully'),
            backgroundColor: Colors.green,
          ),
        );

        // Pop back to previous screen
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error applying template: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _selectedTemplateId = null;
        });
      }
    }
  }

  @override
  void dispose() {
    _companyNameController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Choose Branding Template'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Select a template that matches your brand style',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Company name input
            TextField(
              controller: _companyNameController,
              decoration: InputDecoration(
                labelText: 'Company Name',
                hintText: 'Enter your company name',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                prefixIcon: const Icon(Icons.business),
              ),
            ),
            const SizedBox(height: 32),

            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_templates.isEmpty)
              const Center(
                child: Text('No templates available'),
              )
            else
              Column(
                children: [
                  for (final template in _templates)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 16),
                      child: _buildTemplateCard(template),
                    ),
                ],
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTemplateCard(BrandingTemplate template) {
    final isSelected = _selectedTemplateId == template.id;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: isSelected ? Colors.blue : Colors.grey.shade200,
          width: isSelected ? 2 : 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        template.name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        template.description,
                        style: const TextStyle(
                          fontSize: 13,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade100,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.check_circle,
                      color: Colors.blue,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Color preview
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Primary Color',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _parseColor(template.primaryColor),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            template.primaryColor,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Accent Color',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        height: 40,
                        decoration: BoxDecoration(
                          color: _parseColor(template.accentColor),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.grey.shade300),
                        ),
                        child: Center(
                          child: Text(
                            template.accentColor,
                            style: TextStyle(
                              color: _getContrastColor(
                                _parseColor(template.accentColor),
                              ),
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Apply button
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _selectedTemplateId == template.id
                    ? null
                    : () => _applyTemplate(template.id),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  backgroundColor: Colors.blue,
                  disabledBackgroundColor: Colors.grey.shade300,
                ),
                child: Text(
                  _selectedTemplateId == template.id
                      ? 'Applying...'
                      : 'Apply Template',
                  style: TextStyle(
                    color: _selectedTemplateId == template.id
                        ? Colors.grey
                        : Colors.white,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
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

  Color _getContrastColor(Color color) {
    // Calculate luminance and return black or white for contrast
    final luminance = color.computeLuminance();
    return luminance > 0.5 ? Colors.black : Colors.white;
  }
}

class BrandingTemplate {
  final String id;
  final String name;
  final String description;
  final String primaryColor;
  final String accentColor;

  BrandingTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
  });

  factory BrandingTemplate.fromJson(Map<String, dynamic> json) {
    return BrandingTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      primaryColor: json['primaryColor'] as String,
      accentColor: json['accentColor'] as String,
    );
  }
}
