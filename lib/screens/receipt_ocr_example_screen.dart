import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../services/ocr_service.dart';

/// Example: Receipt OCR Integration
/// 
/// This demonstrates how to use the ReceiptOCRService for client-side
/// receipt image processing on web, with graceful fallback to server-side
/// processing on other platforms.
/// 
/// Usage:
/// 1. User selects receipt image
/// 2. If on web, process locally with Tesseract.js
/// 3. If on mobile/desktop, use Cloud Functions
/// 4. Extract structured data from OCR text
/// 5. Auto-populate expense form

class ReceiptOCRExampleScreen extends StatefulWidget {
  const ReceiptOCRExampleScreen({Key? key}) : super(key: key);

  @override
  State<ReceiptOCRExampleScreen> createState() =>
      _ReceiptOCRExampleScreenState();
}

class _ReceiptOCRExampleScreenState extends State<ReceiptOCRExampleScreen> {
  final ImagePicker _imagePicker = ImagePicker();
  final ReceiptOCRService _ocrService = ReceiptOCRService();

  bool _isProcessing = false;
  String? _extractedText;
  String? _error;
  double? _confidence;

  @override
  void initState() {
    super.initState();
    // Optional: Initialize OCR on screen load
    _initializeOCR();
  }

  Future<void> _initializeOCR() async {
    if (_ocrService.isAvailable) {
      await _ocrService.initialize();
      final status = _ocrService.getStatus();
      debugPrint('📊 OCR Status: $status');
    }
  }

  /// Pick and process receipt image
  Future<void> _pickAndProcessReceipt() async {
    try {
      // Pick image
      final XFile? pickedFile = await _imagePicker.pickImage(
        source: ImageSource.camera,
        imageQuality: 85,
      );

      if (pickedFile == null) return;

      setState(() {
        _isProcessing = true;
        _error = null;
        _extractedText = null;
      });

      // Read image bytes
      final bytes = await pickedFile.readAsBytes();

      // Try web-based OCR first
      if (_ocrService.isAvailable) {
        debugPrint('📱 Processing with client-side OCR (web)');
        final result = await _ocrService.processReceipt(bytes);

        if (mounted) {
          if (result != null && result['success'] == true) {
            setState(() {
              _extractedText = result['text'];
              _confidence = (result['confidence'] as num?)?.toDouble();
              _isProcessing = false;
            });
            _showSuccessSnackBar('Receipt processed successfully');
            _parseAndAutoFillForm(_extractedText!);
          } else {
            setState(() {
              _error = result?['error'] ?? 'Unknown OCR error';
              _isProcessing = false;
            });
            _showErrorSnackBar('OCR failed: ${result?['error']}');
          }
        }
      } else {
        // Fallback: Use Cloud Functions for non-web platforms
        debugPrint('📱 Processing with Cloud Functions (native)');
        _processWithCloudFunctions(pickedFile);
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _error = 'Failed to pick/process image: $e';
          _isProcessing = false;
        });
        _showErrorSnackBar('Error: $e');
      }
    }
  }

  /// Fallback: Process receipt using Cloud Functions
  Future<void> _processWithCloudFunctions(XFile imageFile) async {
    // TODO: Implement Cloud Functions call
    // This is the fallback for non-web platforms
    debugPrint('🔄 Uploading to Cloud Functions for OCR processing...');

    // Example: Upload to Storage and call Cloud Function
    // final storageRef = firebase_storage.FirebaseStorage.instance
    //     .ref('receipts/${userId}/${DateTime.now().millisecondsSinceEpoch}');
    // await storageRef.putFile(File(imageFile.path));
    // final result = await CloudFunctions.processReceiptOCR(storageRef.fullPath);
  }

  /// Parse OCR text and auto-fill expense form
  void _parseAndAutoFillForm(String text) {
    // TODO: Extract structured data from receipt text
    // Examples:
    // - Merchant name (store name)
    // - Amount (total price)
    // - Date (receipt date)
    // - Category (based on merchant type)
    // - Items (line items)

    debugPrint('📋 Parsing receipt text for auto-fill...');

    // Regex patterns for common receipt elements
    final amountPattern = RegExp(r'\$?(\d+\.\d{2})');
    final datePattern = RegExp(r'(\d{1,2})[/-](\d{1,2})[/-](\d{2,4})');

    final amounts = amountPattern.allMatches(text);
    final dates = datePattern.allMatches(text);

    debugPrint('💰 Found amounts: ${amounts.map((m) => m.group(1)).toList()}');
    debugPrint('📅 Found dates: ${dates.map((m) => m.group(0)).toList()}');

    // You would then auto-fill the expense form with:
    // - amount: amounts.isNotEmpty ? amounts.last.group(1) : null
    // - date: dates.isNotEmpty ? DateTime.parse(dates.first.group(0)!) : null
    // - category: determineCategory(text)
  }

  void _showSuccessSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
        duration: const Duration(seconds: 2),
      ),
    );
  }

  void _showErrorSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
        duration: const Duration(seconds: 3),
      ),
    );
  }

  @override
  void dispose() {
    // Optional: Cleanup OCR worker on app close
    _ocrService.terminate();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Receipt OCR Example')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // OCR Status
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'OCR Status',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _ocrService.isAvailable
                          ? '✅ Web OCR Available'
                          : '⚠️ Using Cloud Functions',
                      style: TextStyle(
                        color: _ocrService.isAvailable
                            ? Colors.green
                            : Colors.orange,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (_ocrService.getStatus() != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Languages: ${_ocrService.getStatus()!['supportedLanguages'].join(', ')}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Upload Button
            Center(
              child: ElevatedButton.icon(
                onPressed: _isProcessing ? null : _pickAndProcessReceipt,
                icon: const Icon(Icons.camera_alt),
                label: Text(_isProcessing
                    ? 'Processing...'
                    : 'Take Receipt Photo'),
              ),
            ),
            const SizedBox(height: 16),

            // Extracted Text
            if (_extractedText != null) ...[
              const Text(
                'Extracted Text:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.grey[300]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_extractedText!),
                    if (_confidence != null) ...[
                      const SizedBox(height: 8),
                      Text(
                        'Confidence: ${(_confidence! * 100).toStringAsFixed(1)}%',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Error Message
            if (_error != null) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Error:',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(_error!),
                  ],
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Features Info
            const Card(
              child: Padding(
                padding: EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Features:',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text('• Client-side OCR processing (web)'),
                    Text('• Offline-capable after initial load'),
                    Text('• Support for 6+ languages'),
                    Text('• Auto-fill expense forms'),
                    Text('• Cloud Functions fallback (mobile)'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
