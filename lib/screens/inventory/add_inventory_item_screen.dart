import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/inventory_service.dart';
import '../../services/storage_service.dart';

class AddInventoryItemScreen extends StatefulWidget {
  const AddInventoryItemScreen({Key? key}) : super(key: key);

  @override
  State<AddInventoryItemScreen> createState() => _AddInventoryItemScreenState();
}

class _AddInventoryItemScreenState extends State<AddInventoryItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final InventoryService _service = InventoryService();
  final StorageService _storage = StorageService();

  final TextEditingController _name = TextEditingController();
  final TextEditingController _sku = TextEditingController();
  final TextEditingController _cost = TextEditingController();
  final TextEditingController _sale = TextEditingController();
  final TextEditingController _tax = TextEditingController(text: '0');
  final TextEditingController _initialQty = TextEditingController(text: '0');
  final TextEditingController _minStock = TextEditingController(text: '0');
  final TextEditingController _supplier = TextEditingController();
  final TextEditingController _category = TextEditingController();
  final TextEditingController _brand = TextEditingController();

  File? _pickedFile;
  Uint8List? _pickedBytes; // web
  String? _uploadedImageUrl;
  bool _saving = false;

  String get uid => FirebaseAuth.instance.currentUser!.uid;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    if (kIsWeb) {
      final x = await picker.pickImage(source: ImageSource.gallery);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() {
        _pickedBytes = bytes;
      });
      return;
    }

    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    setState(() {
      _pickedFile = File(x.path);
    });
  }

  Future<void> _uploadImageAndCreate() async {
    setState(() => _saving = true);
    try {
      final createPayload = {
        'name': _name.text.trim(),
        'sku': _sku.text.trim(),
        'costPrice': double.tryParse(_cost.text) ?? 0,
        'sellingPrice': double.tryParse(_sale.text) ?? 0,
        'tax': double.tryParse(_tax.text) ?? 0,
        'initialQuantity': int.tryParse(_initialQty.text) ?? 0,
        'minimumStock': int.tryParse(_minStock.text) ?? 0,
        'supplierId': _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
        'category': _category.text.trim().isEmpty ? null : _category.text.trim(),
        'brand': _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      };

      // Create item first (without image)
      final itemRef = await _service.addItem(uid, createPayload);

      // Upload image if selected
      if ((kIsWeb && _pickedBytes != null) || (!kIsWeb && _pickedFile != null)) {
        final itemId = itemRef.id;
        String imageUrl;
        if (kIsWeb) {
          imageUrl = await _storage.uploadInventoryImage(
            uid: uid,
            itemId: itemId,
            bytes: _pickedBytes!,
            filenameHint: _name.text.trim(),
          );
        } else {
          imageUrl = await _storage.uploadInventoryImage(
            uid: uid,
            itemId: itemId,
            file: _pickedFile!,
            filenameHint: _name.text.trim(),
          );
        }
        // Update item doc with imageUrl
        await itemRef.update({'imageUrl': imageUrl});
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item created successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _uploadImageAndCreate();
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _cost.dispose();
    _sale.dispose();
    _tax.dispose();
    _initialQty.dispose();
    _minStock.dispose();
    _supplier.dispose();
    _category.dispose();
    _brand.dispose();
    super.dispose();
  }

  Widget _imagePreview() {
    if (kIsWeb && _pickedBytes != null) {
      return Image.memory(_pickedBytes!, width: 140, height: 140, fit: BoxFit.cover);
    }
    if (_pickedFile != null) {
      return Image.file(_pickedFile!, width: 140, height: 140, fit: BoxFit.cover);
    }
    return const SizedBox(width: 140, height: 140, child: Icon(Icons.image, size: 56, color: Colors.grey));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add inventory item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(onTap: _pickImage, child: _imagePreview()),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sku,
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cost,
                      decoration: const InputDecoration(labelText: 'Cost price'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _sale,
                      decoration: const InputDecoration(labelText: 'Selling price'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tax,
                decoration: const InputDecoration(labelText: 'Tax (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _initialQty,
                      decoration: const InputDecoration(labelText: 'Initial qty'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _minStock,
                      decoration: const InputDecoration(labelText: 'Minimum stock'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category (optional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _brand,
                decoration: const InputDecoration(labelText: 'Brand (optional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _supplier,
                decoration: const InputDecoration(labelText: 'Supplier id (optional)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Create item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


  Future<void> _pickImage() async {
    final picker = ImagePicker();
    if (kIsWeb) {
      final x = await picker.pickImage(source: ImageSource.gallery);
      if (x == null) return;
      final bytes = await x.readAsBytes();
      setState(() {
        _pickedBytes = bytes;
      });
      return;
    }

    final x = await picker.pickImage(source: ImageSource.gallery, maxWidth: 1600, imageQuality: 85);
    if (x == null) return;
    setState(() {
      _pickedFile = File(x.path);
    });
  }

  Future<void> _uploadImageAndCreate() async {
    setState(() => _saving = true);
    try {
      final createPayload = {
        'name': _name.text.trim(),
        'sku': _sku.text.trim(),
        'costPrice': double.tryParse(_cost.text) ?? 0,
        'sellingPrice': double.tryParse(_sale.text) ?? 0,
        'tax': double.tryParse(_tax.text) ?? 0,
        'initialQuantity': int.tryParse(_initialQty.text) ?? 0,
        'minimumStock': int.tryParse(_minStock.text) ?? 0,
        'supplierId': _supplier.text.trim().isEmpty ? null : _supplier.text.trim(),
        'category': _category.text.trim().isEmpty ? null : _category.text.trim(),
        'brand': _brand.text.trim().isEmpty ? null : _brand.text.trim(),
      };

      // Create item first (without image)
      final itemRef = await _service.addItem(uid, createPayload);

      // Upload image if selected
      if ((kIsWeb && _pickedBytes != null) || (!kIsWeb && _pickedFile != null)) {
        final itemId = itemRef.id;
        String imageUrl;
        if (kIsWeb) {
          imageUrl = await _storage.uploadInventoryImage(
            uid: uid,
            itemId: itemId,
            bytes: _pickedBytes!,
            filenameHint: _name.text.trim(),
          );
        } else {
          imageUrl = await _storage.uploadInventoryImage(
            uid: uid,
            itemId: itemId,
            file: _pickedFile!,
            filenameHint: _name.text.trim(),
          );
        }
        // Update item doc with imageUrl
        await itemRef.update({'imageUrl': imageUrl});
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Item created successfully')),
      );
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Create error: $e')),
      );
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    await _uploadImageAndCreate();
  }

  @override
  void dispose() {
    _name.dispose();
    _sku.dispose();
    _cost.dispose();
    _sale.dispose();
    _tax.dispose();
    _initialQty.dispose();
    _minStock.dispose();
    _supplier.dispose();
    _category.dispose();
    _brand.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Add inventory item')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              GestureDetector(onTap: _pickImage, child: _imagePreview()),
              const SizedBox(height: 12),
              TextFormField(
                controller: _name,
                decoration: const InputDecoration(labelText: 'Name *'),
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter name' : null,
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _sku,
                decoration: const InputDecoration(labelText: 'SKU'),
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _cost,
                      decoration: const InputDecoration(labelText: 'Cost price'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _sale,
                      decoration: const InputDecoration(labelText: 'Selling price'),
                      keyboardType: TextInputType.numberWithOptions(decimal: true),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _tax,
                decoration: const InputDecoration(labelText: 'Tax (%)'),
                keyboardType: TextInputType.number,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _initialQty,
                      decoration: const InputDecoration(labelText: 'Initial qty'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: TextFormField(
                      controller: _minStock,
                      decoration: const InputDecoration(labelText: 'Minimum stock'),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _category,
                decoration: const InputDecoration(labelText: 'Category (optional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _brand,
                decoration: const InputDecoration(labelText: 'Brand (optional)'),
              ),
              const SizedBox(height: 8),
              TextFormField(
                controller: _supplier,
                decoration: const InputDecoration(labelText: 'Supplier id (optional)'),
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _saving ? null : _submit,
                icon: _saving
                    ? const SizedBox(
                        width: 16,
                        height: 16,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.save),
                label: Text(_saving ? 'Saving...' : 'Create item'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
