import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class ExpenseReviewScreen extends StatefulWidget {
  final String expenseId;

  const ExpenseReviewScreen({
    Key? key,
    required this.expenseId,
  }) : super(key: key);

  @override
  State<ExpenseReviewScreen> createState() => _ExpenseReviewScreenState();
}

class _ExpenseReviewScreenState extends State<ExpenseReviewScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _merchantCtrl;
  late TextEditingController _totalCtrl;
  late TextEditingController _currencyCtrl;
  late TextEditingController _dateCtrl;
  late TextEditingController _notesCtrl;

  bool loading = true;
  bool saving = false;
  Map<String, dynamic>? expenseData;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _merchantCtrl = TextEditingController();
    _totalCtrl = TextEditingController();
    _currencyCtrl = TextEditingController();
    _dateCtrl = TextEditingController();
    _notesCtrl = TextEditingController();
    _loadExpense();
  }

  Future<void> _loadExpense() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw Exception('User not authenticated');
      }

      final uid = user.uid;
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(widget.expenseId)
          .get();

      if (!doc.exists) {
        throw Exception('Expense not found');
      }

      final data = doc.data() ?? {};
      
      setState(() {
        expenseData = data;
        _merchantCtrl.text = data['merchant'] ?? data['parsed']?['merchant'] ?? '';
        _totalCtrl.text = (data['totalAmount'] ?? data['parsed']?['total'] ?? '').toString();
        _currencyCtrl.text = data['currency'] ?? data['parsed']?['currency'] ?? 'EUR';
        _dateCtrl.text = data['date'] ?? data['parsed']?['date'] ?? '';
        _notesCtrl.text = data['notes'] ?? '';
        loading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = 'Failed to load expense: $e';
        loading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
        Future.delayed(const Duration(seconds: 2), () {
          if (mounted) Navigator.pop(context);
        });
      }
    }
  }

  Future<void> _saveExpense() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => saving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final uid = user.uid;
      final amount = double.tryParse(_totalCtrl.text.trim());
      
      if (amount == null || amount <= 0) {
        throw Exception('Please enter a valid amount');
      }

      final docRef = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(widget.expenseId);

      await docRef.update({
        'merchant': _merchantCtrl.text.trim(),
        'totalAmount': amount,
        'currency': _currencyCtrl.text.trim(),
        'date': _dateCtrl.text.trim(),
        'notes': _notesCtrl.text.trim(),
        'status': 'pending_approval',
        'updatedAt': FieldValue.serverTimestamp(),
        'audit': FieldValue.arrayUnion([
          {
            'action': 'reviewed_and_submitted',
            'at': FieldValue.serverTimestamp(),
            'by': uid,
          }
        ]),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Expense submitted for approval'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.pop(context, true);
      }
    } catch (e) {
      setState(() => errorMessage = 'Failed to save: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(errorMessage!),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => saving = false);
      }
    }
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dateCtrl.text = picked.toIso8601String().split('T')[0];
    }
  }

  @override
  void dispose() {
    _merchantCtrl.dispose();
    _totalCtrl.dispose();
    _currencyCtrl.dispose();
    _dateCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (loading) {
      return Scaffold(
        appBar: AppBar(title: const Text('Review Expense')),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Review Expense'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Error message
              if (errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red[50],
                      border: Border.all(color: Colors.red[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      errorMessage!,
                      style: TextStyle(color: Colors.red[900]),
                    ),
                  ),
                ),

              // Merchant field
              TextFormField(
                controller: _merchantCtrl,
                decoration: InputDecoration(
                  labelText: 'Merchant',
                  hintText: 'e.g., Starbucks',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Please enter merchant name';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Amount & Currency
              Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextFormField(
                      controller: _totalCtrl,
                      decoration: InputDecoration(
                        labelText: 'Amount',
                        hintText: '0.00',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter amount';
                        }
                        final amount = double.tryParse(value);
                        if (amount == null || amount <= 0) {
                          return 'Valid amount';
                        }
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: _currencyCtrl,
                      decoration: InputDecoration(
                        labelText: 'Currency',
                        hintText: 'EUR',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      maxLength: 3,
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Currency';
                        }
                        return null;
                      },
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Date field
              TextFormField(
                controller: _dateCtrl,
                readOnly: true,
                onTap: _selectDate,
                decoration: InputDecoration(
                  labelText: 'Date',
                  hintText: 'YYYY-MM-DD',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  suffixIcon: const Icon(Icons.calendar_today),
                ),
                validator: (value) {
                  if (value == null || value.trim().isEmpty) {
                    return 'Select date';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Notes field
              TextFormField(
                controller: _notesCtrl,
                decoration: InputDecoration(
                  labelText: 'Notes (optional)',
                  hintText: 'Add any notes about this expense',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                maxLines: 3,
              ),
              const SizedBox(height: 16),

              // OCR Data Preview
              if (expenseData?['parsed'] != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ExpansionTile(
                    title: const Text('OCR Extracted Data'),
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.grey[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildDataRow(
                              'Merchant',
                              expenseData?['parsed']['merchant'] ?? 'N/A',
                            ),
                            _buildDataRow(
                              'Total',
                              expenseData?['parsed']['total']?.toString() ??
                                  'N/A',
                            ),
                            _buildDataRow(
                              'Currency',
                              expenseData?['parsed']['currency'] ?? 'N/A',
                            ),
                            _buildDataRow(
                              'Date',
                              expenseData?['parsed']['date'] ?? 'N/A',
                            ),
                            if ((expenseData?['amounts'] as List?)
                                    ?.isNotEmpty == true)
                              _buildDataRow(
                                'Amounts Found',
                                ((expenseData?['amounts'] as List?) ?? [])
                                        .map((a) =>
                                            '${a['value']?.toStringAsFixed(2)}')
                                        .join(', '),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

              // Action buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: saving ? null : () => Navigator.pop(context),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: saving ? null : _saveExpense,
                      child: saving
                          ? const SizedBox(
                              height: 20,
                              width: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Colors.white,
                                ),
                              ),
                            )
                          : const Text('Save & Submit'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDataRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '$label: ',
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              fontSize: 13,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
