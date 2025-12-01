import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_branding_provider.dart';
import '../../models/business_branding.dart';

class BusinessProfileSettingsScreen extends StatefulWidget {
  const BusinessProfileSettingsScreen({Key? key}) : super(key: key);

  @override
  State<BusinessProfileSettingsScreen> createState() =>
      _BusinessProfileSettingsScreenState();
}

class _BusinessProfileSettingsScreenState
    extends State<BusinessProfileSettingsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  late TextEditingController _nameController;
  late TextEditingController _phoneController;
  late TextEditingController _emailController;
  late TextEditingController _websiteController;
  late TextEditingController _addressController;
  late TextEditingController _registrationController;
  late TextEditingController _taxIdController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _initializeControllers();
    _loadBusinessProfile();
  }

  void _initializeControllers() {
    _nameController = TextEditingController();
    _phoneController = TextEditingController();
    _emailController = TextEditingController();
    _websiteController = TextEditingController();
    _addressController = TextEditingController();
    _registrationController = TextEditingController();
    _taxIdController = TextEditingController();
  }

  void _loadBusinessProfile() {
    final branding =
        context.read<BusinessBrandingProvider>().branding;

    if (branding?.companyDetails != null) {
      final details = branding!.companyDetails!;
      _nameController.text = details.name;
      _phoneController.text = details.phone ?? '';
      _emailController.text = details.email ?? '';
      _websiteController.text = details.website ?? '';
      _addressController.text = details.address ?? '';
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    _nameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _websiteController.dispose();
    _addressController.dispose();
    _registrationController.dispose();
    _taxIdController.dispose();
    super.dispose();
  }

  Future<void> _saveBusinessProfile() async {
    final provider = context.read<BusinessBrandingProvider>();
    final currentBranding = provider.branding ?? BusinessBranding();

    final companyDetails = CompanyDetails(
      name: _nameController.text,
      phone: _phoneController.text.isNotEmpty ? _phoneController.text : null,
      email: _emailController.text.isNotEmpty ? _emailController.text : null,
      website: _websiteController.text.isNotEmpty ? _websiteController.text : null,
      address: _addressController.text.isNotEmpty ? _addressController.text : null,
    );

    final updatedBranding = currentBranding.copyWith(
      companyDetails: companyDetails,
    );

    await provider.updateBranding(updatedBranding);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Business profile updated successfully'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'General'),
            Tab(text: 'Details'),
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
              _buildGeneralTab(),
              _buildDetailsTab(),
            ],
          );
        },
      ),
    );
  }

  Widget _buildGeneralTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Company Information',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _nameController,
            label: 'Company Name',
            hint: 'Your Company Name',
            required: true,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _emailController,
            label: 'Email',
            hint: 'contact@company.com',
            keyboardType: TextInputType.emailAddress,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _phoneController,
            label: 'Phone',
            hint: '+1 (555) 123-4567',
            keyboardType: TextInputType.phone,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _websiteController,
            label: 'Website',
            hint: 'https://company.com',
            keyboardType: TextInputType.url,
          ),
          const SizedBox(height: 16),
          _buildTextField(
            controller: _addressController,
            label: 'Business Address',
            hint: '123 Main St, City, State, ZIP',
            maxLines: 3,
          ),
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _saveBusinessProfile,
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                backgroundColor: Colors.blue,
              ),
              child: const Text(
                'Save Business Profile',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Business Details',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Optional information for compliance and documentation',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey,
            ),
          ),
          const SizedBox(height: 24),

          _buildTextField(
            controller: _registrationController,
            label: 'Business Registration Number',
            hint: 'E.g., 12-3456789',
          ),
          const SizedBox(height: 16),

          _buildTextField(
            controller: _taxIdController,
            label: 'Tax ID / VAT Number',
            hint: 'E.g., 98-7654321',
          ),
          const SizedBox(height: 32),

          // Business Type Section
          const Text(
            'Business Type',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              FilterChip(
                label: const Text('Sole Proprietor'),
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('Partnership'),
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('Corporation'),
                onSelected: (_) {},
              ),
              FilterChip(
                label: const Text('LLC'),
                onSelected: (_) {},
              ),
            ],
          ),
          const SizedBox(height: 32),

          // Industry Section
          const Text(
            'Industry',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              hintText: 'Select industry',
            ),
            items: [
              'Technology',
              'Finance',
              'Healthcare',
              'Education',
              'Retail',
              'Manufacturing',
              'Services',
              'Other',
            ]
                .map((industry) => DropdownMenuItem(
                      value: industry,
                      child: Text(industry),
                    ))
                .toList(),
            onChanged: (_) {},
          ),
          const SizedBox(height: 32),

          // Info section
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              border: Border.all(color: Colors.blue.shade200),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  'Privacy Notice',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'Your business information is securely stored and only used for generating documents and communications.',
                  style: TextStyle(fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
    bool required = false,
  }) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        labelText: required ? '$label *' : label,
        hintText: hint,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        prefixIcon: const Icon(Icons.edit),
      ),
    );
  }
}
