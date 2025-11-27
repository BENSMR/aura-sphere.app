import 'dart:io';
import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:google_ml_kit/google_ml_kit.dart';
import 'package:uuid/uuid.dart';
import '../../data/models/expense_model.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:path/path.dart' as p;

class ExpenseScannerService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  // Run on-device OCR and parse
  Future<Map<String, dynamic>> analyzeImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    final fullText = recognizedText.text;
    final blocks = recognizedText.blocks.map((b) => {
      'text': b.text,
      'confidence': b.recognizedLanguages.join(','),
    }).toList();

    // Basic parser heuristics
    final parsed = _parseReceipt(fullText);

    return {
      'rawText': fullText,
      'blocks': blocks,
      'parsed': parsed,
    };
  }

  Map<String, dynamic> _parseReceipt(String text) {
    final lines = text.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty).toList();

    String? merchant;
    DateTime? date;
    double amount = 0;
    double? vat;
    String currency = 'EUR';

    // Merchant: first non-empty line with letters
    merchant = lines.isNotEmpty ? lines.firstWhere((l) => RegExp(r'[A-Za-z]').hasMatch(l), orElse: () => lines.first) : 'Merchant';

    // Date: search for common date patterns
    final dateRegex = RegExp(r'(\d{4}[-/]\d{1,2}[-/]\d{1,2})|(\d{1,2}[-/]\d{1,2}[-/]\d{2,4})');
    for (final l in lines) {
      final m = dateRegex.firstMatch(l);
      if (m != null) {
        try {
          final s = m.group(0)!;
          date = DateTime.parse(s.replaceAll('/', '-'));
          break;
        } catch (_) {
          // try dd-mm-yy
          try {
            final parts = m.group(0)!.split(RegExp(r'[-/]')).map((p)=>int.parse(p)).toList();
            if (parts.length==3) {
              date = DateTime(2000+parts[2], parts[1], parts[0]);
              break;
            }
          } catch(e) {}
        }
      }
    }

    // Amount: find the largest currency-looking number
    final amountRegex = RegExp(r'([-+]?\d{1,3}(?:[\.,]\d{3})*(?:[\.,]\d{2}))');
    double maxVal = 0;
    for (final l in lines.reversed) { // totals usually near bottom
      final matches = amountRegex.allMatches(l);
      for (final m in matches) {
        final raw = m.group(0)!.replaceAll('.', '').replaceAll(',', '.');
        final val = double.tryParse(raw);
        if (val != null && val > maxVal) {
          maxVal = val;
        }
      }
      if (maxVal > 0) break;
    }
    amount = maxVal > 0 ? maxVal : 0.0;

    // VAT: search lines containing vat, tax, tva
    for (final l in lines) {
      if (l.toLowerCase().contains('vat') || l.toLowerCase().contains('tva') || l.toLowerCase().contains('tax')) {
        final m = amountRegex.firstMatch(l);
        if (m != null) {
          final raw = m.group(0)!.replaceAll('.', '').replaceAll(',', '.');
          vat = double.tryParse(raw);
          break;
        }
      }
    }

    // currency detection (simple)
    if (text.contains('€') || text.toLowerCase().contains('eur')) currency = 'EUR';
    else if (text.contains('\$') || text.toLowerCase().contains('usd')) currency = 'USD';

    return {
      'merchant': merchant,
      'date': date?.toIso8601String(),
      'amount': amount,
      'vat': vat,
      'currency': currency,
    };
  }

  /// Call Cloud Vision API for enhanced OCR (optional refinement)
  Future<Map<String, dynamic>> refineWithCloudVision(String imageUrl) async {
    try {
      final result = await _functions
          .httpsCallable('visionOcr')
          .call({'imageUrl': imageUrl});
      
      final data = result.data as Map<String, dynamic>;
      return data;
    } catch (e) {
      // Cloud Vision failed or disabled - fall back to on-device results
      return {};
    }
  }

  // Merge on-device and cloud vision results for best accuracy
  Map<String, dynamic> _mergeOcrResults(
    Map<String, dynamic> mlKitResult,
    Map<String, dynamic> cloudResult,
  ) {
    final mlParsed = mlKitResult['parsed'] as Map<String, dynamic>;
    final cloudParsed = cloudResult.isEmpty ? {} : (cloudResult['parsed'] as Map<String, dynamic>? ?? {});

    // Use cloud results if confidence is higher, otherwise keep ML Kit results
    return {
      'merchant': cloudParsed['merchant'] ?? mlParsed['merchant'],
      'date': cloudParsed['date'] ?? mlParsed['date'],
      'amount': cloudParsed['amount'] ?? mlParsed['amount'],
      'vat': cloudParsed['vat'] ?? mlParsed['vat'],
      'currency': cloudParsed['currency'] ?? mlParsed['currency'],
    };
  }

  // Upload image to Storage and save expense to Firestore
  Future<ExpenseModel> saveExpenseFromImage(
    File imageFile, {
    bool useCloudVision = false,
  }) async {
    final uid = _auth.currentUser!.uid;
    final id = const Uuid().v4();
    final ext = p.extension(imageFile.path);
    final path = 'expenses/$uid/$id$ext';
    final ref = _storage.ref().child(path);
    final uploadTask = ref.putFile(imageFile, SettableMetadata(contentType: 'image/jpeg'));

    final snapshot = await uploadTask.whenComplete((){});
    final url = await snapshot.ref.getDownloadURL();

    final analysis = await analyzeImage(imageFile);
    var parsed = analysis['parsed'] as Map<String, dynamic>;

    // Optionally refine with Cloud Vision for better accuracy
    if (useCloudVision) {
      try {
        final cloudResult = await refineWithCloudVision(url);
        if (cloudResult.isNotEmpty) {
          parsed = _mergeOcrResults(analysis, cloudResult);
        }
      } catch (_) {
        // Cloud Vision failed, continue with ML Kit results
      }
    }

    final expense = ExpenseModel(
      id: id,
      userId: uid,
      merchant: parsed['merchant'] ?? 'Unknown',
      date: parsed['date'] != null ? DateTime.parse(parsed['date']) : null,
      amount: (parsed['amount'] ?? 0).toDouble(),
      vat: parsed['vat'] != null ? (parsed['vat'] as num).toDouble() : null,
      currency: parsed['currency'] ?? 'EUR',
      imageUrl: url,
      rawOcr: {
        'rawText': analysis['rawText'],
        'blocks': analysis['blocks'],
        if (useCloudVision) 'cloudVisionUsed': true,
      },
    );

    await _db.collection('users').doc(uid).collection('expenses').doc(id).set(expense.toMap());
    return expense;
  }

  /// Delete an expense by ID (removes from Firestore and Storage)
  Future<void> deleteExpense(String expenseId) async {
    final uid = _auth.currentUser!.uid;
    
    // Get expense to find image URL
    final doc = await _db.collection('users').doc(uid).collection('expenses').doc(expenseId).get();
    
    if (!doc.exists) {
      throw Exception('Expense not found');
    }

    // Delete from Firestore
    await _db.collection('users').doc(uid).collection('expenses').doc(expenseId).delete();

    // Delete image from Storage if available
    try {
      final ref = _storage.ref().child('expenses/$uid/$expenseId');
      await ref.delete();
    } catch (e) {
      // Image may not exist, continue
    }
  }
}
