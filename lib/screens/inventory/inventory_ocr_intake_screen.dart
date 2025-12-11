import 'dart:convert';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_functions/firebase_functions.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/inventory_service.dart';
import 'inventory_parsed_review_screen.dart';

class InventoryOCRIntakeScreen extends StatefulWidget {
  const InventoryOCRIntakeScreen({Key? key}) : super(key: key);

  @override
  State<InventoryOCRIntakeScreen> createState() => _InventoryOCRIntakeScreenState();
}

class _InventoryOCRIntakeScreenState extends State<InventoryOCRIntakeScreen> {
  final InventoryService _inventory = InventoryService();
  final functions = FirebaseFunctions.instance;
  Uint8List? _pickedBytes;
  bool _parsing = false;
  Map<String, dynamic>? _parsedResult;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _pickPhoto() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.camera, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedBytes = bytes;
      _parsedResult = null;
    });
    await _parseImageWithFunctions(bytes);
  }

  Future<void> _pickFromGallery() async {
    final picker = ImagePicker();
    final XFile? file = await picker.pickImage(source: ImageSource.gallery, imageQuality: 80);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    setState(() {
      _pickedBytes = bytes;
      _parsedResult = null;
    });
    await _parseImageWithFunctions(bytes);
  }

  Future<void> _parseImageWithFunctions(Uint8List bytes) async {
    setState(() { _parsing = true; });
    try {
      final callable = functions.httpsCallable('parseInventoryOCR');
      final res = await callable.call(<String, dynamic>{ 'b64': base64Encode(bytes) });
      final data = res.data as Map<String, dynamic>;
      setState(() {
        _parsedResult = data['parsed'] as Map<String, dynamic>?;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Parse error: $e')));
    } finally {
      setState(() { _parsing = false; });
    }
  }

  // commit parsed items to inventory (calls your intakeStockFromOCR)
  Future<void> _commitParsed() async {
    if (_parsedResult == null) return;
    final items = _parsedResult!['items'] as List<dynamic>? ?? [];
    try {
      final callable = functions.httpsCallable('intakeStockFromOCR');
      final res = await callable.call(<String, dynamic>{
        'items': items,
        'referenceId': null,
        'note': 'Imported via OCR intake'
      });
      if (res.data['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Inventory updated')));
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Import failed')));
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Commit error: $e')));
    }
  }

  Widget _previewParsed() {
    if (_parsing) return const Center(child: CircularProgressIndicator());
    if (_parsedResult == null) return const SizedBox();
    final items = _parsedResult!['items'] as List<dynamic>? ?? [];
    final supplier = _parsedResult!['supplier'];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (supplier != null) Text('Supplier: $supplier', style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          itemBuilder: (_, i) {
            final item = items[i] as Map<String, dynamic>;
            return Card(
              child: ListTile(
                title: Text(item['name'] ?? ''),
                subtitle: Text('SKU: ${item['sku'] ?? '-'}'),
                trailing: Text('x${item['quantity'] ?? 0}'),
                onTap: () {
                  // optional: open an edit dialog for this parsed item
                },
              ),
            );
          },
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => InventoryParsedReviewScreen(parsed: _parsedResult!, note: 'OCR import'),
                    ),
                  );
                },
                icon: const Icon(Icons.edit),
                label: const Text('Review & Edit'),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: ElevatedButton.icon(
                onPressed: _commitParsed,
                icon: const Icon(Icons.check),
                label: const Text('Add to inventory'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    Widget preview;
    if (_pickedBytes != null) preview = Image.memory(_pickedBytes!, width: double.infinity, height: 200, fit: BoxFit.cover);
    else preview = const SizedBox(height: 200, child: Center(child: Icon(Icons.camera_alt, size: 48)));

    return Scaffold(
      appBar: AppBar(title: const Text('OCR Intake')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(12),
        child: Column(children: [
          preview,
          const SizedBox(height: 12),
          Row(
            children: [
              ElevatedButton.icon(onPressed: _pickPhoto, icon: const Icon(Icons.camera), label: const Text('Camera')),
              const SizedBox(width: 8),
              ElevatedButton.icon(onPressed: _pickFromGallery, icon: const Icon(Icons.photo), label: const Text('Gallery')),
            ],
          ),
          const SizedBox(height: 12),
          _previewParsed(),
        ]),
      ),
    );
  }
}
