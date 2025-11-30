import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/business_profile.dart';
import '../../providers/business_provider.dart';
// import 'business_profile_form_screen.dart'; // Temporarily disabled

class BusinessProfileScreen extends StatelessWidget {
  const BusinessProfileScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Business Profile'),
        elevation: 0,
      ),
      body: Consumer<BusinessProvider>(
        builder: (context, businessProvider, _) {
          if (businessProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!businessProvider.hasBusinessProfile) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.business, size: 64, color: Colors.grey[400]),
                  const SizedBox(height: 16),
                  Text(
                    'No Business Profile',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Create your business profile to get started',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      // Navigator.push(context, MaterialPageRoute(builder: (_) => const BusinessProfileFormScreen())); // Temporarily disabled
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Profile creation coming soon')),
                      );
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Create Profile'),
                  ),
                ],
              ),
            );
          }

          final business = businessProvider.profile!;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Header with logo
              _buildHeader(context, business),
              const SizedBox(height: 24),

              // Business Info Card
              _buildBusinessInfoCard(context, business),
              const SizedBox(height: 16),

              // Address Card
              if (business.streetAddress.isNotEmpty)
                _buildAddressCard(context, business),
              const SizedBox(height: 16),

              // Contact Person Card
              if (business.contactPersonName.isNotEmpty)
                _buildContactPersonCard(context, business),
              const SizedBox(height: 16),

              // Banking Info Card (if available)
              if (business.bankAccountName.isNotEmpty)
                _buildBankingCard(context, business),
              const SizedBox(height: 16),

              // Social Media Card
              if (business.socialMedia.isNotEmpty)
                _buildSocialMediaCard(context, business),
              const SizedBox(height: 24),

              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () {
                        // Navigator.push(context, MaterialPageRoute(builder: (_) => BusinessProfileFormScreen(initialProfile: businessProvider.profile))); // Temporarily disabled
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Profile editing coming soon')),
                        );
                      },
                      icon: const Icon(Icons.edit),
                      label: const Text('Edit'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _showDeleteDialog(context),
                      icon: const Icon(Icons.delete),
                      label: const Text('Delete'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Invoice Template Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    final userId = business.userId;
                    if (userId != null && userId.isNotEmpty) {
                      Navigator.pushNamed(
                        context,
                        '/invoice/templates',
                        arguments: {'userId': userId},
                      );
                    }
                  },
                  icon: const Icon(Icons.style),
                  label: const Text('Choose Invoice Template'),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildHeader(BuildContext context, BusinessProfile business) {
    return Column(
      children: [
        if (business.logoUrl.isNotEmpty)
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Image.network(
              business.logoUrl,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.image_not_supported,
                size: 48,
                color: Colors.grey[400],
              ),
            ),
          )
        else
          Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(
              Icons.business,
              size: 48,
              color: Colors.blue[600],
            ),
          ),
        const SizedBox(height: 16),
        Text(
          business.businessName,
          style: Theme.of(context).textTheme.headlineSmall,
          textAlign: TextAlign.center,
        ),
        if (business.industry.isNotEmpty)
          Text(
            business.industry,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.grey[600],
                ),
          ),
        if (business.description.isNotEmpty) ...[
          const SizedBox(height: 12),
          Text(
            business.description,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                ),
            textAlign: TextAlign.center,
          ),
        ],
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: business.status == 'active' ? Colors.green[100] : Colors.orange[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            business.status.replaceFirst(business.status[0], business.status[0].toUpperCase()),
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: business.status == 'active' ? Colors.green[700] : Colors.orange[700],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildBusinessInfoCard(BuildContext context, BusinessProfile business) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Business Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'Business Type', business.businessType),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Tax ID', business.taxId),
            if (business.registrationNumber.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(context, 'Registration #', business.registrationNumber),
            ],
            if (business.numberOfEmployees != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Employees',
                business.numberOfEmployees.toString(),
              ),
            ],
            if (business.foundedDate != null && business.foundedDate!.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(
                context,
                'Founded',
                business.foundedDate!,
              ),
            ],
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Currency', business.currency),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Fiscal Year End', business.fiscalYearEnd),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressCard(BuildContext context, BusinessProfile business) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Address',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on_outlined, size: 20, color: Colors.blue),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${business.streetAddress}\n${business.city}, ${business.state} ${business.zipCode}\n${business.country}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContactPersonCard(BuildContext context, BusinessProfile business) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Contact Person',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'Name', business.contactPersonName),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Email', business.contactPersonEmail),
            const SizedBox(height: 12),
            _buildInfoRow(context, 'Phone', business.contactPersonPhone),
          ],
        ),
      ),
    );
  }

  Widget _buildBankingCard(BuildContext context, BusinessProfile business) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Banking Information',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 16),
            _buildInfoRow(context, 'Account Name', business.bankAccountName),
            const SizedBox(height: 12),
            _buildInfoRow(
              context,
              'Account Number',
              _maskAccountNumber(business.bankAccountNumber),
            ),
            if (business.routingNumber.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(context, 'Routing Number', business.routingNumber),
            ],
            if (business.swiftCode.isNotEmpty) ...[
              const SizedBox(height: 12),
              _buildInfoRow(context, 'SWIFT Code', business.swiftCode),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildSocialMediaCard(BuildContext context, BusinessProfile business) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Social Media',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: business.socialMedia.entries.map((entry) {
                return Chip(
                  label: Text(entry.key),
                  avatar: const Icon(Icons.link, size: 18),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(BuildContext context, String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 100,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontWeight: FontWeight.w500,
                ),
          ),
        ),
        Expanded(
          child: Text(
            value.isNotEmpty ? value : '—',
            style: Theme.of(context).textTheme.bodySmall,
          ),
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.month}/${date.day}/${date.year}';
  }

  String _maskAccountNumber(String accountNumber) {
    if (accountNumber.length < 4) return accountNumber;
    final masked = '*' * (accountNumber.length - 4);
    return '$masked${accountNumber.substring(accountNumber.length - 4)}';
  }

  void _showDeleteDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete Business Profile'),
        content: const Text(
          'Are you sure you want to delete your business profile? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await context.read<BusinessProvider>().deleteBusinessProfile();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Business profile deleted')),
                  );
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              }
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
