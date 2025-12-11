import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class ExpenseScanScreen extends StatefulWidget {
  const ExpenseScanScreen({Key? key}) : super(key: key);
  
  @override
  State<ExpenseScanScreen> createState() => _ExpenseScanScreenState();
}

class _ExpenseScanScreenState extends State<ExpenseScanScreen> {
  bool uploading = false;
  String? statusMessage;
  final picker = ImagePicker();
  XFile? picked;

  Future<void> _pickFromCamera() async {
    final x = await picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 80,
    );
    if (x != null) {
      setState(() => picked = x);
    }
  }

  Future<void> _pickFromGallery() async {
    final x = await picker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 80,
    );
    if (x != null) {
      setState(() => picked = x);
    }
  }

  Future<void> _uploadAndOcr({bool useOpenAI = false}) async {
    if (picked == null) return;

    setState(() {
      uploading = true;
      statusMessage = 'Processing receipt...';
    });

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        throw 'Not authenticated. Please log in first.';
      }

      final uid = user.uid;
      final bytes = await picked!.readAsBytes();
      const uuid = Uuid();
      final tempId = uuid.v4();

      // Step 1: Upload image to Cloud Storage
      _updateStatus('Uploading image...');
      final storagePath = 'users/$uid/expenses/$tempId/receipt.jpg';
      final ref = FirebaseStorage.instance.ref().child(storagePath);
      await ref.putData(
        bytes,
        SettableMetadata(contentType: 'image/jpeg'),
      );

      // Step 2: Call ocrProcessor Cloud Function
      _updateStatus('Extracting receipt data (OCR)...');
      final callable = FirebaseFunctions.instance.httpsCallable('ocrProcessor');
      final res = await callable.call({
        'storagePath': storagePath,
        'useOpenAI': useOpenAI,
      });

      final data = Map<String, dynamic>.from(res.data);

      if (!data.containsKey('parsed')) {
        throw 'OCR failed: No parsed data returned';
      }

      final parsed = Map<String, dynamic>.from(data['parsed']);
      final rawText = data['rawText'] as String? ?? '';
      final amounts = data['amounts'] as List? ?? [];
      final dates = data['dates'] as List? ?? [];
      final merchant = data['merchant'] as String? ?? 'Unknown';
      final currency = data['currency'] as String?;

      // Step 3: Create expense document in Firestore
      _updateStatus('Creating expense record...');
      final expenseId = uuid.v4();
      final db = FirebaseFirestore.instance;
      final now = FieldValue.serverTimestamp();

      final expenseDoc = {
        'expenseId': expenseId,
        'merchant': parsed['merchant'] ?? merchant,
        'totalAmount': parsed['total'] ?? (amounts.isNotEmpty ? amounts[0]['value'] : null),
        'currency': parsed['currency'] ?? currency,
        'date': parsed['date'] ?? (dates.isNotEmpty ? dates[0] : null),
        'status': 'draft',
        'parsed': parsed,
        'rawOcr': rawText,
        'amounts': amounts,
        'dates': dates,
        'createdAt': now,
        'attachments': [
          {
            'path': storagePath,
            'uploadedAt': now,
            'name': 'receipt.jpg',
          }
        ],
        'audit': [
          {
            'action': 'created',
            'at': now,
            'by': uid,
          }
        ]
      };

      await db
          .collection('users')
          .doc(uid)
          .collection('expenses')
          .doc(expenseId)
          .set(expenseDoc);

      // Step 4: Navigate to review screen
      _updateStatus('Opening expense review...');
      if (mounted) {
        Navigator.pushReplacementNamed(
          context,
          '/expenses/review',
          arguments: {'expenseId': expenseId},
        );
      }
    } catch (e) {
      _showError('OCR failed: $e');
      debugPrint('OCR error: $e');
    } finally {
      if (mounted) {
        setState(() => uploading = false);
      }
    }
  }

  void _updateStatus(String message) {
    if (mounted) {
      setState(() => statusMessage = message);
    }
  }

  void _showError(String message) {
    if (mounted) {
      setState(() => statusMessage = null);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Receipt'),
        elevation: 0,
      ),
      body: Stack(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                // Image preview area
                Expanded(
                  flex: 3,
                  child: Container(
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                      color: Colors.grey[50],
                    ),
                    child: picked != null
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(8),
                            child: Image.file(
                              File(picked!.path),
                              fit: BoxFit.cover,
                            ),
                          )
                        : Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.image_not_supported,
                                  size: 64,
                                  color: Colors.grey[400],
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No image selected',
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleMedium
                                      ?.copyWith(color: Colors.grey[600]),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
                const SizedBox(height: 24),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: uploading ? null : _pickFromCamera,
                        icon: const Icon(Icons.camera_alt),
                        label: const Text('Camera'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton.icon(
                        onPressed: uploading ? null : _pickFromGallery,
                        icon: const Icon(Icons.photo_library),
                        label: const Text('Gallery'),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Main OCR button
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: ElevatedButton(
                    onPressed:
                        uploading || picked == null
                            ? null
                            : () => _uploadAndOcr(useOpenAI: false),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      disabledBackgroundColor: Colors.grey[300],
                    ),
                    child: uploading
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
                        : const Text(
                            'Upload & OCR',
                            style: TextStyle(fontSize: 16),
                          ),
                  ),
                ),
                const SizedBox(height: 12),

                // Optional: Enhanced OCR with OpenAI
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: TextButton(
                    onPressed:
                        uploading || picked == null
                            ? null
                            : () => _uploadAndOcr(useOpenAI: true),
                    child: const Text(
                      'Upload & OCR (AI Enhanced)',
                      style: TextStyle(fontSize: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Status message overlay
          if (statusMessage != null)
            Container(
              color: Colors.black54,
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      statusMessage!,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      textAlign: TextAlign.center,
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
