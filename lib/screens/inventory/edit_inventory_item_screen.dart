import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../services/inventory_service.dart';
import '../../services/storage_service.dart';

class EditInventoryItemScreen extends StatefulWidget {
  final String itemId;
  const EditInventoryItemScreen({Key? key, required this.itemId})
      : super(key: key);

  @override
  State<EditInventoryItemScreen> createState() =>
      _EditInventoryItemScreenState();
}

class _EditInventoryItemScreenState extends State<EditInventoryItemScreen> {
  final _inventory = InventoryService();
  final _storage = StorageService();
  final _imagePicker = ImagePicker();

  late TextEditingController _name;
  late TextEditingController _sku;
  late TextEditingController _cost;
  late TextEditingController _sale;
  late TextEditingController _tax;
  late TextEditingController _initialQty;
  late TextEditingController _minStock;
  late TextEditingController _category;
  late TextEditingController _brand;
  late TextEditingController _supplier;

  File? _pickedFile;
  Uint8List? _pickedBytes;
  String? _currentImageUrl;
  bool _isLoading = true;
  bool _isSaving = false;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
    _loadItemData();
  }

  void _initializeControllers() {
    _name = TextEditingController();
    _sku = TextEditingController();
    _cost = TextEditingController();
    _sale = TextEditingController();
    _tax = TextEditingController();
    _initialQty = TextEditingController();
    _minStock = TextEditingController();
    _category = TextEditingController();
    _brand = TextEditingController();
    _supplier = TextEditingController();
  }

  Future<void> _loadItemData() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      final doc = await _inventory
          .inventoryCollection(user.uid)
          .doc(widget.itemId)
          .get();

      if (!doc.exists) throw Exception('Item not found');

      final data = doc.data() as Map<String, dynamic>;

      if (mounted) {
        setState(() {
          _name.text = data['name'] ?? '';
          _sku.text = data['sku'] ?? '';
          _cost.text = data['costPrice']?.toString() ?? '';
          _sale.text = data['salePrice']?.toString() ?? '';
          _tax.text = data['taxPercentage']?.toString() ?? '';
          _initialQty.text = data['initialQuantity']?.toString() ?? '';
          _minStock.text = data['minimumStock']?.toString() ?? '';
          _category.text = data['category'] ?? '';
          _brand.text = data['brand'] ?? '';
          _supplier.text = data['supplier'] ?? '';
          _currentImageUrl = data['imageUrl'];
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading item: $e')),
        );
        Navigator.of(context).pop();
      }
    }
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
    _category.dispose();
    _brand.dispose();
    _supplier.dispose();
    super.dispose();
  }

  Future<void> _pickImage() async {
    try {
      final result = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
      );

      if (result != null) {
        if (kIsWeb) {
          final bytes = await result.readAsBytes();
          if (mounted) {
            setState(() => _pickedBytes = bytes);
          }
        } else {
          if (mounted) {
            setState(() => _pickedFile = File(result.path));
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error picking image: $e')),
        );
      }
    }
  }

  Future<void> _submit() async {
    if (_name.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an item name')),
      );
      return;
    }

    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) throw Exception('User not authenticated');

      String? newImageUrl = _currentImageUrl;

      // Handle image replacement
      if (_pickedFile != null || _pickedBytes != null) {
        setState(() => _isUploading = true);

        // Delete old image if exists
        if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
          await _storage.deleteByUrl(_currentImageUrl!);
        }

        // Upload new image
        newImageUrl = await _storage.uploadInventoryImage(
          uid: user.uid,
          itemId: widget.itemId,
          file: _pickedFile,
          bytes: _pickedBytes,
          filenameHint: _name.text.trim(),
        );

        setState(() => _isUploading = false);
      }

      // Update item in Firestore
      await _inventory
          .inventoryCollection(user.uid)
          .doc(widget.itemId)
          .update({
        'name': _name.text.trim(),
        'sku': _sku.text.trim().isEmpty ? null : _sku.text.trim(),
        'costPrice': _cost.text.trim().isEmpty
            ? null
            : double.tryParse(_cost.text.trim()),
        'salePrice': _sale.text.trim().isEmpty
            ? null
            : double.tryParse(_sale.text.trim()),
        'taxPercentage': _tax.text.trim().isEmpty
            ? null
            : double.tryParse(_tax.text.trim()),
        'initialQuantity': _initialQty.text.trim().isEmpty
            ? null
            : int.tryParse(_initialQty.text.trim()),
        'minimumStock': _minStock.text.trim().isEmpty
            ? null
            : int.tryParse(_minStock.text.trim()),
        'category': _category.text.trim().isEmpty ? null : _category.text.trim(),
        'brand': _brand.text.trim().isEmpty ? null : _brand.text.trim(),
        'supplier': _supplier.text.trim().isEmpty
            ? null
            : _supplier.text.trim(),
        if (newImageUrl != null) 'imageUrl': newImageUrl,
        'updatedAt': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Item updated successfully')),
        );
        Navigator.of(context).pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error updating item: $e')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  Widget _buildImagePreview() {
    // Show newly picked image if available
    if (_pickedFile != null) {
      return Image.file(
        _pickedFile!,
        height: 200,
        width: 200,
        fit: BoxFit.cover,
      );
    }

    if (_pickedBytes != null && kIsWeb) {
      return Image.memory(
        _pickedBytes!,
        height: 200,
        width: 200,
        fit: BoxFit.cover,
      );
    }

    // Show existing image
    if (_currentImageUrl != null && _currentImageUrl!.isNotEmpty) {
      return Image.network(
        _currentImageUrl!,
        height: 200,
        width: 200,
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          width: 200,
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image),
        ),
      );
    }

    // No image
    return Container(
      height: 200,
      width: 200,
      color: Colors.grey[200],
      child: const Icon(Icons.image, size: 80),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Inventory Item'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Image section
                  Center(
                    child: Column(
                      children: [
                        _buildImagePreview(),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _isUploading ? null : _pickImage,
                          icon: const Icon(Icons.image),
                          label: Text(_pickedFile != null || _pickedBytes != null
                              ? 'Change Image'
                              : 'Pick Image'),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Form fields
                  TextFormField(
                    controller: _name,
                    decoration: const InputDecoration(
                      labelText: 'Item Name *',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _sku,
                    decoration: const InputDecoration(
                      labelText: 'SKU',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _cost,
                          decoration: const InputDecoration(
                            labelText: 'Cost Price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _sale,
                          decoration: const InputDecoration(
                            labelText: 'Sale Price',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _tax,
                    decoration: const InputDecoration(
                      labelText: 'Tax %',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 16),

                  Row(
                    children: [
                      Expanded(
                        child: TextFormField(
                          controller: _initialQty,
                          decoration: const InputDecoration(
                            labelText: 'Initial Qty',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: TextFormField(
                          controller: _minStock,
                          decoration: const InputDecoration(
                            labelText: 'Min Stock',
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.number,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _category,
                    decoration: const InputDecoration(
                      labelText: 'Category',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _brand,
                    decoration: const InputDecoration(
                      labelText: 'Brand',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _supplier,
                    decoration: const InputDecoration(
                      labelText: 'Supplier',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: _isSaving ? null : () => Navigator.of(context).pop(),
                          child: const Text('Cancel'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _isSaving ? null : _submit,
                          child: _isSaving
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2),
                                )
                              : const Text('Save Changes'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
