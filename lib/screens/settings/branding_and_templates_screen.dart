import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_branding_provider.dart';
import 'business_branding_settings_screen.dart';
import 'invoice_branding_screen.dart';

class BrandingAndTemplatesScreen extends StatefulWidget {
  const BrandingAndTemplatesScreen({Key? key}) : super(key: key);

  @override
  State<BrandingAndTemplatesScreen> createState() =>
      _BrandingAndTemplatesScreenState();
}

class _BrandingAndTemplatesScreenState
    extends State<BrandingAndTemplatesScreen> {
  @override
  void initState() {
    super.initState();
    _loadBrandingData();
  }

  void _loadBrandingData() {
    Future.microtask(() {
      context.read<BusinessBrandingProvider>().fetchBranding();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Branding & Templates'),
        elevation: 0,
      ),
      body: Consumer<BusinessBrandingProvider>(
        builder: (context, provider, _) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                const Text(
                  'Customize Your Brand',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Set your company colors, logo, and document templates',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey,
                  ),
                ),
                const SizedBox(height: 32),

                // Business Branding Card
                _buildBrandingCard(
                  title: 'Business Branding',
                  description: 'Logo, colors, company details & signatures',
                  icon: Icons.palette,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const BusinessBrandingSettingsScreen(),
                      ),
                    );
                  },
                  hasCustomization: provider.hasCustomBranding,
                  customizationLabel: provider.branding?.companyDetails?.name,
                ),
                const SizedBox(height: 16),

                // Invoice Branding Card
                _buildBrandingCard(
                  title: 'Invoice & Receipt Templates',
                  description: 'Choose templates & customize appearance',
                  icon: Icons.description,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const InvoiceBrandingScreen(),
                      ),
                    );
                  },
                  hasCustomization: provider.branding?.invoiceTemplateId != null,
                  customizationLabel:
                      provider.branding?.invoiceTemplateId ?? 'default',
                ),
                const SizedBox(height: 32),

                // Quick Stats
                const Text(
                  'Brand Status',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 16),
                _buildStatusGrid(provider),
                const SizedBox(height: 32),

                // Info Section
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    border: Border.all(color: Colors.blue.shade200),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: const [
                      Text(
                        'About Branding',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Your branding will be applied to all invoices, receipts, and documents. Changes take effect immediately.',
                        style: TextStyle(fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildBrandingCard({
    required String title,
    required String description,
    required IconData icon,
    required VoidCallback onTap,
    required bool hasCustomization,
    String? customizationLabel,
  }) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.all(16),
        leading: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Colors.blue, size: 28),
        ),
        title: Text(
          title,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text(description),
            if (hasCustomization && customizationLabel != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.green.shade100,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '✓ Configured: $customizationLabel',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.green.shade700,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ],
        ),
        trailing: const Icon(Icons.chevron_right),
        onTap: onTap,
      ),
    );
  }

  Widget _buildStatusGrid(BusinessBrandingProvider provider) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      mainAxisSpacing: 12,
      crossAxisSpacing: 12,
      children: [
        _buildStatusItem(
          'Company Details',
          provider.branding?.companyDetails?.name != null ? '✓' : '—',
          provider.branding?.companyDetails?.name != null
              ? Colors.green
              : Colors.grey,
        ),
        _buildStatusItem(
          'Logo',
          provider.branding?.logoUrl != null ? '✓' : '—',
          provider.branding?.logoUrl != null ? Colors.green : Colors.grey,
        ),
        _buildStatusItem(
          'Colors',
          provider.branding?.primaryColor != null ? '✓' : '—',
          provider.branding?.primaryColor != null ? Colors.green : Colors.grey,
        ),
        _buildStatusItem(
          'Signature',
          provider.branding?.showSignature == true ? '✓' : '—',
          provider.branding?.showSignature == true ? Colors.green : Colors.grey,
        ),
      ],
    );
  }

  Widget _buildStatusItem(String label, String status, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade200),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            status,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
