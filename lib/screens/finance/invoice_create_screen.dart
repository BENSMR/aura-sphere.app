import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:aura_sphere_pro/models/invoice.dart';
import 'package:aura_sphere_pro/models/company.dart';
import 'package:aura_sphere_pro/models/contact.dart';
import 'package:aura_sphere_pro/providers/company_provider.dart';
import 'package:aura_sphere_pro/providers/contact_provider.dart';
import 'package:aura_sphere_pro/providers/finance_invoice_provider.dart';
import 'package:aura_sphere_pro/services/tax_service.dart';
import 'package:aura_sphere_pro/services/invoice_service.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Invoice Creation Screen
/// 
/// Allows users to create new invoices with:
/// - Amount and currency input
/// - Company and contact selection
/// - Auto-fill tax using TaxService
/// - Preview before save
/// - Real-time tax status monitoring
class InvoiceCreateScreen extends StatefulWidget {
  final String? initialCompanyId;
  final String? initialContactId;

  const InvoiceCreateScreen({
    Key? key,
    this.initialCompanyId,
    this.initialContactId,
  }) : super(key: key);

  @override
  State<InvoiceCreateScreen> createState() => _InvoiceCreateScreenState();
}

class _InvoiceCreateScreenState extends State<InvoiceCreateScreen> {
  // Services
  late TaxService _taxService;
  late InvoiceService _invoiceService;

  // Form state
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _amountController;
  late TextEditingController _descriptionController;
  String? _selectedCompanyId;
  String? _selectedContactId;
  String _selectedCurrency = 'EUR';
  String _selectedDirection = 'sale';

  // Tax preview state
  Map<String, dynamic>? _taxPreview;
  bool _isLoadingTaxPreview = false;
  String? _taxPreviewError;

  // Submit state
  bool _isSubmitting = false;
  String? _submitError;

  @override
  void initState() {
    super.initState();
    _taxService = TaxService();
    _invoiceService = InvoiceService();
    _amountController = TextEditingController();
    _descriptionController = TextEditingController();
    _selectedCompanyId = widget.initialCompanyId;
    _selectedContactId = widget.initialContactId;
  }

  @override
  void dispose() {
    _amountController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  /// Validate form before any operations
  bool _validateForm() {
    if (!_formKey.currentState!.validate()) {
      return false;
    }

    if (_selectedCompanyId == null || _selectedCompanyId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a company')),
      );
      return false;
    }

    if (_selectedContactId == null || _selectedContactId!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a contact')),
      );
      return false;
    }

    return true;
  }

  /// Get amount from form
  double _getAmount() {
    return double.tryParse(_amountController.text) ?? 0.0;
  }

  /// Auto-fill tax by calling determineTaxAndCurrency
  Future<void> _onAutoFillTax() async {
    if (!_validateForm()) {
      return;
    }

    final amount = _getAmount();
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Amount must be greater than 0')),
      );
      return;
    }

    setState(() {
      _isLoadingTaxPreview = true;
      _taxPreviewError = null;
    });

    try {
      print('🔄 Requesting tax preview for €$amount...');
      
      final preview = await _taxService.determineTaxAndCurrency(
        amount: amount,
        fromCurrency: _selectedCurrency,
        companyId: _selectedCompanyId,
        contactId: _selectedContactId,
        direction: _selectedDirection,
      );

      print('✅ Tax preview received: $preview');

      if (!mounted) return;

      setState(() {
        _taxPreview = preview;
        _isLoadingTaxPreview = false;
      });

      // Show confirmation dialog
      if (preview['success'] == true) {
        _showTaxPreviewDialog(preview);
      } else {
        setState(() {
          _taxPreviewError = preview['error'] ?? 'Failed to calculate tax';
        });
      }
    } catch (e) {
      print('❌ Tax preview error: $e');
      if (!mounted) return;

      setState(() {
        _isLoadingTaxPreview = false;
        _taxPreviewError = 'Tax calculation failed: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $_taxPreviewError'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Show preview dialog before saving
  void _showTaxPreviewDialog(Map<String, dynamic> preview) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tax Preview'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildPreviewRow('Base Amount', _formatCurrency(preview['amount'] ?? 0, _selectedCurrency)),
              _buildPreviewRow('Country', preview['country'] ?? '-'),
              _buildPreviewRow('Currency', preview['currency'] ?? _selectedCurrency),
              _buildPreviewRow('Tax Rate', TaxService.formatTaxRate(preview['taxRate'] ?? 0)),
              const Divider(height: 20),
              _buildPreviewRow(
                'Tax Amount',
                _formatCurrency(preview['taxAmount'] ?? 0, preview['currency'] ?? _selectedCurrency),
                isBold: true,
              ),
              _buildPreviewRow(
                'Total',
                _formatCurrency(preview['total'] ?? 0, preview['currency'] ?? _selectedCurrency),
                isBold: true,
              ),
              const SizedBox(height: 12),
              if (preview['taxBreakdown'] != null)
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    TaxService.formatTaxBreakdown(preview['taxBreakdown']),
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ),
              if (preview['conversionHint'] != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'ℹ️ ${preview['conversionHint']}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                    ),
                  ),
                ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Adjust'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveInvoice();
            },
            child: const Text('Confirm & Save'),
          ),
        ],
      ),
    );
  }

  /// Save invoice to Firestore
  Future<void> _saveInvoice() async {
    if (!_validateForm()) {
      return;
    }

    final amount = _getAmount();
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not authenticated')),
      );
      return;
    }

    setState(() {
      _isSubmitting = true;
      _submitError = null;
    });

    try {
      print('💾 Saving invoice...');

      // Create invoice model
      final invoice = Invoice(
        id: '', // Will be set by service
        uid: user.uid,
        invoiceNumber: '', // Will be generated by service
        companyId: _selectedCompanyId!,
        contactId: _selectedContactId!,
        amount: amount,
        currency: _taxPreview?['currency'] ?? _selectedCurrency,
        taxRate: _taxPreview?['taxRate'] ?? 0.0,
        taxAmount: _taxPreview?['taxAmount'] ?? 0.0,
        total: _taxPreview?['total'] ?? amount,
        taxStatus: 'queued', // Server will calculate authoritative tax
        taxCalculatedBy: 'server', // Set by Cloud Function
        taxCountry: _taxPreview?['country'],
        taxBreakdown: _taxPreview?['taxBreakdown'],
        taxNote: _taxPreview?['note'],
        description: _descriptionController.text.isNotEmpty
            ? _descriptionController.text
            : null,
        status: 'draft',
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      // Save to Firestore
      final savedInvoice = await _invoiceService.createInvoice(invoice);
      print('✅ Invoice saved: ${savedInvoice.id}');

      if (!mounted) return;

      // Update providers
      if (mounted) {
        context.read<FinanceInvoiceProvider>().loadInvoices();
      }

      // Show success and navigate back
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Invoice created: ${savedInvoice.invoiceNumber}'),
          backgroundColor: Colors.green,
        ),
      );

      if (mounted) {
        Navigator.pop(context, savedInvoice);
      }
    } catch (e) {
      print('❌ Save error: $e');
      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
        _submitError = 'Failed to save invoice: $e';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $_submitError'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  /// Format currency helper
  String _formatCurrency(double amount, String currency) {
    return TaxService.formatCurrency(amount, currency);
  }

  /// Build preview row helper
  Widget _buildPreviewRow(String label, String value, {bool isBold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 13)),
          Text(
            value,
            style: TextStyle(
              fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create Invoice'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Company Selection
              _buildSectionTitle('Company'),
              _buildCompanySelector(),
              const SizedBox(height: 20),

              // Contact Selection
              _buildSectionTitle('Contact'),
              _buildContactSelector(),
              const SizedBox(height: 20),

              // Amount & Currency
              _buildSectionTitle('Amount'),
              _buildAmountInput(),
              const SizedBox(height: 12),
              _buildCurrencySelector(),
              const SizedBox(height: 20),

              // Direction
              _buildSectionTitle('Direction'),
              _buildDirectionSelector(),
              const SizedBox(height: 20),

              // Description (Optional)
              _buildSectionTitle('Description (Optional)'),
              _buildDescriptionInput(),
              const SizedBox(height: 20),

              // Tax Preview Section
              if (_taxPreview != null) _buildTaxPreviewSection(),

              // Error Message
              if (_taxPreviewError != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red[50],
                    border: Border.all(color: Colors.red[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.error_outline, color: Colors.red[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _taxPreviewError!,
                          style: TextStyle(color: Colors.red[700]),
                        ),
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 24),

              // Action Buttons
              _buildActionButtons(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        title,
        style: Theme.of(context).textTheme.titleMedium,
      ),
    );
  }

  Widget _buildCompanySelector() {
    return Consumer<CompanyProvider>(
      builder: (context, companyProvider, _) {
        return DropdownButtonFormField<String>(
          value: _selectedCompanyId,
          hint: const Text('Select a company'),
          isExpanded: true,
          items: companyProvider.companies.map((company) {
            return DropdownMenuItem(
              value: company.id,
              child: Text(company.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedCompanyId = value;
              _taxPreview = null; // Reset preview on change
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a company';
            }
            return null;
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        );
      },
    );
  }

  Widget _buildContactSelector() {
    return Consumer<ContactProvider>(
      builder: (context, contactProvider, _) {
        return DropdownButtonFormField<String>(
          value: _selectedContactId,
          hint: const Text('Select a contact'),
          isExpanded: true,
          items: contactProvider.contacts.map((contact) {
            return DropdownMenuItem(
              value: contact.id,
              child: Text(contact.name),
            );
          }).toList(),
          onChanged: (value) {
            setState(() {
              _selectedContactId = value;
              _taxPreview = null; // Reset preview on change
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
              return 'Please select a contact';
            }
            return null;
          },
          decoration: InputDecoration(
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
        );
      },
    );
  }

  Widget _buildAmountInput() {
    return TextFormField(
      controller: _amountController,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: 'Amount',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        suffixIcon: Padding(
          padding: const EdgeInsets.all(12),
          child: Text(_selectedCurrency),
        ),
      ),
      validator: (value) {
        if (value == null || value.isEmpty) {
          return 'Please enter an amount';
        }
        final amount = double.tryParse(value);
        if (amount == null || amount <= 0) {
          return 'Please enter a valid amount';
        }
        return null;
      },
      onChanged: (_) {
        setState(() {
          _taxPreview = null; // Reset preview on change
        });
      },
    );
  }

  Widget _buildCurrencySelector() {
    return DropdownButtonFormField<String>(
      value: _selectedCurrency,
      items: ['EUR', 'USD', 'GBP', 'CHF', 'JPY', 'CAD', 'AUD'].map((curr) {
        return DropdownMenuItem(
          value: curr,
          child: Text(curr),
        );
      }).toList(),
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedCurrency = value;
            _taxPreview = null; // Reset preview on change
          });
        }
      },
      decoration: InputDecoration(
        labelText: 'Currency',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDirectionSelector() {
    return DropdownButtonFormField<String>(
      value: _selectedDirection,
      items: [
        const DropdownMenuItem(value: 'sale', child: Text('Sale (Invoice)')),
        const DropdownMenuItem(value: 'purchase', child: Text('Purchase (Expense)')),
      ],
      onChanged: (value) {
        if (value != null) {
          setState(() {
            _selectedDirection = value;
            _taxPreview = null; // Reset preview on change
          });
        }
      },
      decoration: InputDecoration(
        labelText: 'Direction',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildDescriptionInput() {
    return TextFormField(
      controller: _descriptionController,
      maxLines: 3,
      decoration: InputDecoration(
        labelText: 'Description',
        hintText: 'Add invoice details...',
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      ),
    );
  }

  Widget _buildTaxPreviewSection() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.check_circle, color: Colors.green[600], size: 20),
              const SizedBox(width: 8),
              const Text(
                'Tax Preview',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPreviewRow(
            'Tax Amount',
            _formatCurrency(_taxPreview?['taxAmount'] ?? 0, _taxPreview?['currency'] ?? _selectedCurrency),
          ),
          _buildPreviewRow(
            'Total',
            _formatCurrency(_taxPreview?['total'] ?? 0, _taxPreview?['currency'] ?? _selectedCurrency),
          ),
          const SizedBox(height: 8),
          if (_taxPreview?['taxBreakdown'] != null)
            Text(
              TaxService.formatTaxBreakdown(_taxPreview?['taxBreakdown']),
              style: Theme.of(context).textTheme.bodySmall,
            ),
        ],
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton(
            onPressed: _isSubmitting || _isLoadingTaxPreview
                ? null
                : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton.icon(
            onPressed: _isSubmitting || _isLoadingTaxPreview
                ? null
                : _onAutoFillTax,
            icon: _isLoadingTaxPreview
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.auto_awesome),
            label: Text(_isLoadingTaxPreview ? 'Calculating...' : 'Auto Fill Tax'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: ElevatedButton(
            onPressed: _taxPreview == null || _isSubmitting
                ? null
                : _saveInvoice,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.green,
            ),
            child: Text(_isSubmitting ? 'Saving...' : 'Save Invoice'),
          ),
        ),
      ],
    );
  }
}
