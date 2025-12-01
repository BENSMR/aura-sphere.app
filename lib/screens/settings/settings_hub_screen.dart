import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/business_branding_provider.dart';
import 'branding_and_templates_screen.dart';
import 'business_profile_settings_screen.dart';
import 'documents_settings_screen.dart';

class SettingsHubScreen extends StatefulWidget {
  const SettingsHubScreen({Key? key}) : super(key: key);

  @override
  State<SettingsHubScreen> createState() => _SettingsHubScreenState();
}

class _SettingsHubScreenState extends State<SettingsHubScreen> {
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    Future.microtask(() {
      context.read<BusinessBrandingProvider>().fetchBranding();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              color: Colors.blue.shade50,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Settings',
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Manage your business profile and preferences',
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                ],
              ),
            ),

            // Business Settings Section
            _buildSection(
              title: 'Business',
              children: [
                _buildSettingsTile(
                  title: 'Business Profile',
                  subtitle: 'Company details and information',
                  icon: Icons.business,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const BusinessProfileSettingsScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  title: 'Branding & Templates',
                  subtitle: 'Logo, colors, and document templates',
                  icon: Icons.palette,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const BrandingAndTemplatesScreen(),
                      ),
                    );
                  },
                ),
                _buildSettingsTile(
                  title: 'Documents',
                  subtitle: 'Manage invoices, receipts, and storage',
                  icon: Icons.description,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) =>
                            const DocumentsSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),

            // Account Settings Section
            _buildSection(
              title: 'Account',
              children: [
                _buildSettingsTile(
                  title: 'Account Settings',
                  subtitle: 'Email, password, and security',
                  icon: Icons.person,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  title: 'Notifications',
                  subtitle: 'Emails and push notifications',
                  icon: Icons.notifications,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  title: 'Privacy & Security',
                  subtitle: 'Data protection and privacy settings',
                  icon: Icons.security,
                  onTap: () {},
                ),
              ],
            ),

            // Integrations Section
            _buildSection(
              title: 'Integrations',
              children: [
                _buildSettingsTile(
                  title: 'Payment Methods',
                  subtitle: 'Stripe and payment configuration',
                  icon: Icons.payment,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  title: 'Email Service',
                  subtitle: 'SendGrid and email settings',
                  icon: Icons.mail,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  title: 'API & Webhooks',
                  subtitle: 'API keys and webhook configuration',
                  icon: Icons.api,
                  onTap: () {},
                ),
              ],
            ),

            // Support Section
            _buildSection(
              title: 'Support',
              children: [
                _buildSettingsTile(
                  title: 'Help & Documentation',
                  subtitle: 'Guides, FAQs, and support articles',
                  icon: Icons.help,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  title: 'Contact Support',
                  subtitle: 'Get help from our support team',
                  icon: Icons.contact_support,
                  onTap: () {},
                ),
                _buildSettingsTile(
                  title: 'About',
                  subtitle: 'Version info and acknowledgments',
                  icon: Icons.info,
                  onTap: () {},
                ),
              ],
            ),

            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
  }) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.grey,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Card(
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: Colors.grey.shade200),
            ),
            child: Column(
              children: [
                for (int i = 0; i < children.length; i++) ...[
                  children[i],
                  if (i < children.length - 1)
                    Divider(height: 1, color: Colors.grey.shade100),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingsTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(icon, color: Colors.blue, size: 24),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.chevron_right),
      onTap: onTap,
    );
  }
}
