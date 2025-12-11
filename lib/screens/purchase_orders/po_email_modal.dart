import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';

class POEmailModal extends StatefulWidget {
  final String poId;
  final String? defaultTo;
  final String? poNumber;

  const POEmailModal({
    Key? key,
    required this.poId,
    this.defaultTo,
    this.poNumber,
  }) : super(key: key);

  @override
  State<POEmailModal> createState() => _POEmailModalState();
}

class _POEmailModalState extends State<POEmailModal> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _toController;
  late final TextEditingController _ccController;
  late final TextEditingController _bccController;
  late final TextEditingController _subjectController;
  late final TextEditingController _messageController;

  bool _sending = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _toController = TextEditingController(text: widget.defaultTo ?? '');
    _ccController = TextEditingController();
    _bccController = TextEditingController();
    _subjectController = TextEditingController(
      text: 'Purchase Order ${widget.poNumber ?? ''}',
    );
    _messageController = TextEditingController(
      text: 'Hello,\n\n'
          'Please find attached the Purchase Order ${widget.poNumber ?? ''}.\n\n'
          'Please review and confirm receipt at your earliest convenience.\n\n'
          'Best regards',
    );
  }

  @override
  void dispose() {
    _toController.dispose();
    _ccController.dispose();
    _bccController.dispose();
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  /// Validate email format
  static bool _isValidEmail(String email) {
    final regex = RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$');
    return regex.hasMatch(email);
  }

  /// Parse comma-separated emails and validate
  static List<String>? _parseEmails(String input) {
    if (input.trim().isEmpty) return null;

    final emails = input
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    if (emails.isEmpty) return null;

    // Validate all emails
    for (final email in emails) {
      if (!_isValidEmail(email)) {
        return null;
      }
    }

    return emails;
  }

  Future<void> _send() async {
    // Clear previous error
    setState(() => _errorMessage = null);

    if (!_formKey.currentState!.validate()) return;

    final toEmails = _parseEmails(_toController.text);
    if (toEmails == null || toEmails.isEmpty) {
      setState(() => _errorMessage = 'Please enter at least one valid recipient');
      return;
    }

    final ccEmails = _parseEmails(_ccController.text);
    final bccEmails = _parseEmails(_bccController.text);

    setState(() => _sending = true);

    try {
      debugPrint('[POEmailModal] Sending email for PO: ${widget.poId}');
      debugPrint('[POEmailModal] To: ${toEmails.join(", ")}');

      final callable =
          FirebaseFunctions.instance.httpsCallable('emailPurchaseOrder');

      final response = await callable.call({
        'poId': widget.poId,
        'to': toEmails.length == 1 ? toEmails[0] : toEmails,
        if (ccEmails != null)
          'cc': ccEmails.length == 1 ? ccEmails[0] : ccEmails,
        if (bccEmails != null)
          'bcc': bccEmails.length == 1 ? bccEmails[0] : bccEmails,
        'subject': _subjectController.text.trim(),
        'message': _messageController.text.trim(),
        'saveToStorage': true,
      });

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>?;
      final successMessage = data?['message'] as String? ?? 'Email sent successfully';

      debugPrint('[POEmailModal] Email sent: $successMessage');

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(successMessage),
          backgroundColor: Colors.green,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.pop(context, true);
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[POEmailModal] FirebaseFunctions error: ${e.code} - ${e.message}');

      if (!mounted) return;

      setState(() {
        _errorMessage = e.message ?? 'Failed to send email';
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_errorMessage!),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      debugPrint('[POEmailModal] Error: $e');

      if (!mounted) return;

      setState(() {
        _errorMessage = e.toString();
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to send email: ${e.toString()}'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _sending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Email Purchase Order'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Error banner
                if (_errorMessage != null)
                  Container(
                    margin: const EdgeInsets.only(bottom: 16),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      border: Border.all(color: Colors.red.shade300),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.error_outline, color: Colors.red.shade700),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(color: Colors.red.shade700),
                          ),
                        ),
                      ],
                    ),
                  ),

                // To field
                TextFormField(
                  controller: _toController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_sending,
                  decoration: InputDecoration(
                    labelText: 'To *',
                    hintText: 'supplier@example.com or multiple emails separated by commas',
                    prefixIcon: const Icon(Icons.email),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Recipient email is required';
                    }
                    if (_parseEmails(value) == null) {
                      return 'Please enter valid email address(es)';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // CC field
                TextFormField(
                  controller: _ccController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_sending,
                  decoration: InputDecoration(
                    labelText: 'CC (optional)',
                    hintText: 'cc@example.com, another@example.com',
                    prefixIcon: const Icon(Icons.person_add),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (_parseEmails(value) == null) {
                        return 'Please enter valid email address(es) for CC';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // BCC field
                TextFormField(
                  controller: _bccController,
                  keyboardType: TextInputType.emailAddress,
                  enabled: !_sending,
                  decoration: InputDecoration(
                    labelText: 'BCC (optional)',
                    hintText: 'bcc@example.com, another@example.com',
                    prefixIcon: const Icon(Icons.privacy_tip),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value != null && value.trim().isNotEmpty) {
                      if (_parseEmails(value) == null) {
                        return 'Please enter valid email address(es) for BCC';
                      }
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Subject field
                TextFormField(
                  controller: _subjectController,
                  enabled: !_sending,
                  decoration: InputDecoration(
                    labelText: 'Subject *',
                    prefixIcon: const Icon(Icons.subject),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Subject is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),

                // Message field
                TextFormField(
                  controller: _messageController,
                  enabled: !_sending,
                  decoration: InputDecoration(
                    labelText: 'Message *',
                    prefixIcon: const Icon(Icons.message),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                    contentPadding: const EdgeInsets.all(16),
                  ),
                  maxLines: 6,
                  minLines: 4,
                  validator: (value) {
                    if (value == null || value.trim().isEmpty) {
                      return 'Message is required';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _sending ? null : () => Navigator.pop(context),
                        child: const Text('Cancel'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _sending ? null : _send,
                        child: _sending
                            ? const SizedBox(
                                height: 20,
                                width: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor:
                                      AlwaysStoppedAnimation(Colors.white),
                                ),
                              )
                            : const Text('Send Email'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),

                // Help text
                Text(
                  '* Required fields. PDF will be attached automatically.',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
