import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/client_model.dart';
import '../../providers/client_provider.dart';

class CRMAddClientScreen extends StatefulWidget {
  const CRMAddClientScreen({super.key});

  @override
  State<CRMAddClientScreen> createState() => _CRMAddClientScreenState();
}

class _CRMAddClientScreenState extends State<CRMAddClientScreen> {
  final _form = GlobalKey<FormState>();

  // Basic Info
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _companyController = TextEditingController();
  final _addressController = TextEditingController();
  final _countryController = TextEditingController();
  final _notesController = TextEditingController();

  // Status dropdown
  String _selectedStatus = 'active';

  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _companyController.dispose();
    _addressController.dispose();
    _countryController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_form.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final provider = Provider.of<ClientProvider>(context, listen: false);

      final newClient = ClientModel(
        id: '',
        name: _nameController.text.trim(),
        email: _emailController.text.trim(),
        phone: _phoneController.text.trim(),
        company: _companyController.text.trim(),
        address: _addressController.text.trim(),
        country: _countryController.text.trim(),
        notes: _notesController.text.trim(),
        tags: [],
        status: _selectedStatus,
        lifetimeValue: 0,
        totalInvoices: 0,
        lastInvoiceAmount: 0,
        lastActivityAt: DateTime.now(),
        lastInvoiceDate: null,
        lastPaymentDate: null,
        aiScore: 50,
        churnRisk: 50,
        vipStatus: false,
        sentiment: 'neutral',
        aiTags: [],
        aiSummary: '',
        stabilityLevel: 'stable',
        timeline: [],
        userId: '',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      await provider.addClient(
        name: newClient.name,
        email: newClient.email,
        phone: newClient.phone,
        company: newClient.company,
        address: newClient.address,
        country: newClient.country,
        notes: newClient.notes,
        status: newClient.status,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Client created successfully'),
          backgroundColor: Colors.green,
        ),
      );

      Navigator.of(context).pop();
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Add New Client'),
        elevation: 0,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _form,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Section: Basic Information
                      _buildSectionHeader('Basic Information'),
                      const SizedBox(height: 12),

                      // Name field
                      TextFormField(
                        controller: _nameController,
                        decoration: InputDecoration(
                          labelText: 'Full Name *',
                          hintText: 'John Doe',
                          prefixIcon: const Icon(Icons.person),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Name is required';
                          }
                          if (value.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Email field
                      TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email *',
                          hintText: 'john@example.com',
                          prefixIcon: const Icon(Icons.email),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        validator: (value) {
                          if (value == null || value.trim().isEmpty) {
                            return 'Email is required';
                          }
                          if (!RegExp(r'^[^@]+@[^@]+\.[^@]+$').hasMatch(value)) {
                            return 'Please enter a valid email';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 12),

                      // Phone field
                      TextFormField(
                        controller: _phoneController,
                        keyboardType: TextInputType.phone,
                        decoration: InputDecoration(
                          labelText: 'Phone',
                          hintText: '+1 (555) 123-4567',
                          prefixIcon: const Icon(Icons.phone),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Company field
                      TextFormField(
                        controller: _companyController,
                        decoration: InputDecoration(
                          labelText: 'Company',
                          hintText: 'Acme Corp',
                          prefixIcon: const Icon(Icons.business),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Address field
                      TextFormField(
                        controller: _addressController,
                        maxLines: 2,
                        decoration: InputDecoration(
                          labelText: 'Address',
                          hintText: '123 Main St',
                          prefixIcon: const Icon(Icons.location_on),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Country field
                      TextFormField(
                        controller: _countryController,
                        decoration: InputDecoration(
                          labelText: 'Country',
                          hintText: 'United States',
                          prefixIcon: const Icon(Icons.public),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Section: Client Status
                      _buildSectionHeader('Client Status'),
                      const SizedBox(height: 12),

                      // Status dropdown
                      DropdownButtonFormField<String>(
                        value: _selectedStatus,
                        decoration: InputDecoration(
                          labelText: 'Status',
                          prefixIcon: const Icon(Icons.flag),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        items: ['active', 'inactive', 'prospect', 'churned']
                            .map((status) => DropdownMenuItem(
                                  value: status,
                                  child: Text(_formatStatus(status)),
                                ))
                            .toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedStatus = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Section: Additional Notes
                      _buildSectionHeader('Additional Information'),
                      const SizedBox(height: 12),

                      // Notes field
                      TextFormField(
                        controller: _notesController,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'Notes',
                          hintText: 'Add any additional notes about this client...',
                          prefixIcon: const Icon(Icons.notes),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Info box
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.blue.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: Colors.blue.withOpacity(0.3)),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.info, color: Colors.blue.shade700),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                'AI scoring and churn risk will be calculated automatically based on activity.',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Action buttons
                      Row(
                        children: [
                          Expanded(
                            child: OutlinedButton(
                              onPressed: () => Navigator.of(context).pop(),
                              style: OutlinedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              child: const Text('Cancel'),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: ElevatedButton.icon(
                              onPressed: _isLoading ? null : _save,
                              icon: const Icon(Icons.add),
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 14),
                              ),
                              label: const Text('Create Client'),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ),
    );
  }

  /// Build section header
  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: Colors.grey,
      ),
    );
  }

  /// Format status for display
  String _formatStatus(String status) {
    switch (status) {
      case 'active':
        return '🟢 Active';
      case 'inactive':
        return '🔵 Inactive';
      case 'prospect':
        return '🟡 Prospect';
      case 'churned':
        return '🔴 Churned';
      default:
        return status;
    }
  }
}
