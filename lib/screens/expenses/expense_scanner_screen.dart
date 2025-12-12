import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_storage/firebase_storage.dart';
import '../../services/ocr/expense_scanner_service.dart';
import '../../services/expense_ocr_service.dart';
import '../../data/models/expense_model.dart';
import '../../utils/expense_parser.dart';
import 'expense_review_screen.dart';

class ExpenseScannerScreen extends StatefulWidget {
  const ExpenseScannerScreen({super.key});

  @override
  State<ExpenseScannerScreen> createState() => _ExpenseScannerScreenState();
}

class _ExpenseScannerScreenState extends State<ExpenseScannerScreen> {
  final ImagePicker _picker = ImagePicker();
  final ExpenseScannerService _service = ExpenseScannerService();
  bool _loading = false;
  bool _useCloudVision = false;
  String? _error;
  ExpenseModel? _result;
  String? _uploadedImageUrl;
  Map<String, dynamic>? _parsedData;

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      setState(() {
        _loading = true;
        _error = null;
      });

      final XFile? photo = await _picker.pickImage(
        source: source,
        imageQuality: 80,
      );

      if (photo == null) {
        setState(() => _loading = false);
        return;
      }

      final file = File(photo.path);

      // Validate file exists and is readable
      if (!await file.exists()) {
        throw Exception('File not found or no longer accessible');
      }

      // Step 1: Upload to Firebase Storage
      setState(() => _error = null);
      _uploadedImageUrl = await _uploadToStorage(file);

      // Step 2: Call Vision OCR Cloud Function
      setState(() => _error = null);
      final ocrText = await _callVisionOCR(_uploadedImageUrl!);

      // Step 3: Parse OCR text with ExpenseParser
      _parsedData = ExpenseParser.parse(ocrText);

      if (mounted) {
        setState(() => _loading = false);

        // Step 4: Navigate to ExpenseReviewScreen
        _navigateToReviewScreen();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = e.toString().replaceAll('Exception: ', '');
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: ${_error!}'),
            backgroundColor: Colors.red,
            duration: const Duration(seconds: 4),
          ),
        );
      }
    }
  }

  Future<String> _uploadToStorage(File file) async {
    try {
      setState(() => _error = null);
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final filename = 'expenses/receipts/$timestamp.jpg';

      final ref = FirebaseStorage.instance.ref().child(filename);
      await ref.putFile(file);
      final url = await ref.getDownloadURL();

      return url;
    } catch (e) {
      throw Exception('Upload failed: ${e.toString()}');
    }
  }

  Future<String> _callVisionOCR(String imageUrl) async {
    try {
      setState(() => _error = null);
      final result = await FirebaseFunctions.instance
          .httpsCallable('visionOcr')
          .call({'imageUrl': imageUrl});

      if (result.data is Map && result.data['text'] != null) {
        return result.data['text'] as String;
      }

      throw Exception('No text extracted from image');
    } catch (e) {
      throw Exception('OCR failed: ${e.toString()}');
    }
  }

  void _navigateToReviewScreen() async {
    if (_uploadedImageUrl == null || _parsedData == null) {
      setState(() => _error = 'Missing image or parsed data');
      return;
    }

    try {
      final userId = FirebaseAuth.instance.currentUser?.uid;
      if (userId == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User not authenticated')),
        );
        return;
      }

      // Create expense from OCR data
      final expenseId = await ExpenseOCRHelper.createExpenseFromOCR(
        userId: userId,
        merchant: _parsedData!['merchant'] ?? 'Unknown Merchant',
        amount: double.tryParse(_parsedData!['amount']?.toString() ?? '0') ?? 0,
        currency: _parsedData!['currency'] ?? 'EUR',
        date: _parsedData!['date'] ?? DateTime.now().toString(),
        rawOcr: _parsedData!.toString(),
        parsed: null,
        imageStoragePath: _uploadedImageUrl,
      );

      if (!mounted) return;
      
      // Navigate to review screen with expense ID
      Navigator.pushNamed(
        context,
        '/expenses/review',
        arguments: expenseId,
      );

      // Clear state after navigation
      _clearResult();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error creating expense: $e')),
      );
    }
  }

  void _showSuccessMessage(String title, ExpenseModel expense) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${expense.merchant} • ${expense.currency} ${expense.amount.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12),
            ),
          ],
        ),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 3),
        action: SnackBarAction(
          label: 'Undo',
          onPressed: () async {
            try {
              await _service.deleteExpense(expense.id);
              if (mounted) {
                setState(() => _result = null);
              }
            } catch (e) {
              // Handle deletion error
            }
          },
        ),
      ),
    );
  }

  void _clearResult() {
    setState(() {
      _result = null;
      _error = null;
      _uploadedImageUrl = null;
      _parsedData = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        elevation: 0,
        actions: [
          if (_result != null)
            IconButton(
              icon: const Icon(Icons.clear),
              onPressed: _clearResult,
              tooltip: 'Clear result',
            ),
        ],
      ),
      body: Stack(
        children: [
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  // Error banner
                  if (_error != null) ...[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        border: Border.all(color: Colors.red.shade300),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.error_outline, color: Colors.red.shade700),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _error!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Loading indicator
                  if (_loading)
                    Column(
                      children: [
                        LinearProgressIndicator(
                          backgroundColor: Colors.grey.shade200,
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Processing receipt...',
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                    ),

                  // Result display (removed - navigate to review screen instead)
                  // Old card code moved to ExpenseReviewScreen

                  if (!_loading) ...[
                    // Empty state
                    const SizedBox(height: 60),
                    Icon(
                      Icons.receipt_long,
                      size: 80,
                      color: Colors.grey.shade300,
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Scan a Receipt',
                      style: Theme.of(context).textTheme.headlineSmall,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Take a photo or select an image from your gallery to extract expense details',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 14,
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),

          // Action buttons (floating at bottom)
          if (!_loading)
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 8,
                      offset: const Offset(0, -2),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Cloud Vision toggle
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            Icons.cloud_upload_outlined,
                            size: 18,
                            color: Colors.grey.shade600,
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Enhanced OCR',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ),
                          Switch(
                            value: _useCloudVision,
                            onChanged: (value) {
                              setState(() => _useCloudVision = value);
                            },
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.camera),
                            icon: const Icon(Icons.camera_alt),
                            label: const Text('Camera'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () => _pickImage(ImageSource.gallery),
                            icon: const Icon(Icons.photo_library),
                            label: const Text('Gallery'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}
