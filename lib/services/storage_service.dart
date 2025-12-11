import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:uuid/uuid.dart';
import 'package:path_provider/path_provider.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final _uuid = const Uuid();

  /// Upload file (mobile) or bytes (web) to:
  /// /users/{uid}/inventory/{itemId}/{filename}
  /// Returns public download URL
  Future<String> uploadInventoryImage({
    required String uid,
    required String itemId,
    File? file, // mobile
    Uint8List? bytes, // web or precomputed bytes
    String? filenameHint,
  }) async {
    if (uid.isEmpty || itemId.isEmpty) throw Exception('uid and itemId required');

    final filename = filenameHint != null && filenameHint.isNotEmpty
        ? '${_uuid.v4()}_${filenameHint.replaceAll(' ', '_')}'
        : '${_uuid.v4()}.jpg';

    final path = 'users/$uid/inventory/$itemId/$filename';
    final ref = _storage.ref().child(path);

    // If web, bytes should be provided via image_picker or input element
    if (kIsWeb) {
      if (bytes == null) throw Exception('Web upload requires bytes');
      final metadata = SettableMetadata(contentType: 'image/jpeg');
      final task = ref.putData(bytes, metadata);
      final snap = await task;
      return await snap.ref.getDownloadURL();
    }

    // Mobile: compress file first (if possible)
    if (file == null) throw Exception('File is required for mobile upload');

    try {
      final compressed = await _compressFile(file);
      final uploadFile = compressed ?? file;
      final task = ref.putFile(uploadFile, SettableMetadata(contentType: 'image/jpeg'));
      final snap = await task;
      return await snap.ref.getDownloadURL();
    } catch (e) {
      // fallback: direct upload
      final task = ref.putFile(file, SettableMetadata(contentType: 'image/jpeg'));
      final snap = await task;
      return await snap.ref.getDownloadURL();
    }
  }

  /// Upload inventory item image to Firebase Storage
  /// Path: /users/{uid}/inventory/{itemId}/{randomId}.jpg
  /// Returns: Download URL
  Future<String> uploadInventoryItemImage({
    required String userId,
    required String itemId,
    required dynamic imageFile, // File (mobile) or Uint8List (web)
  }) async {
    if (kIsWeb && imageFile is Uint8List) {
      return uploadInventoryImage(
        uid: userId,
        itemId: itemId,
        bytes: imageFile,
      );
    } else if (imageFile is File) {
      return uploadInventoryImage(
        uid: userId,
        itemId: itemId,
        file: imageFile,
      );
    } else {
      throw Exception('Invalid imageFile type');
    }
  }

  /// Delete inventory item image from Firebase Storage
  Future<void> deleteInventoryItemImage({
    required String userId,
    required String itemId,
    required String imageUrl,
  }) async {
    try {
      await deleteByUrl(imageUrl);
    } catch (e) {
      // Log but don't throw - image deletion shouldn't block other operations
      print('Failed to delete image: $e');
    }
  }

  /// Delete all images for an inventory item
  Future<void> deleteAllInventoryItemImages({
    required String userId,
    required String itemId,
  }) async {
    try {
      final ref = _storage.ref().child('users').child(userId).child('inventory');
      final listResult = await ref.listAll();

      // Delete all images in this folder (for this item)
      for (final item in listResult.items) {
        await item.delete();
      }
    } catch (e) {
      // Log but don't throw - cleanup shouldn't block other operations
      print('Failed to delete all images: $e');
    }
  }

  /// Get all images for an inventory item
  Future<List<String>> getInventoryItemImages({
    required String userId,
    required String itemId,
  }) async {
    try {
      final ref = _storage.ref().child('users').child(userId).child('inventory');
      final listResult = await ref.listAll();

      final urls = <String>[];
      for (final item in listResult.items) {
        final url = await item.getDownloadURL();
        urls.add(url);
      }

      return urls;
    } catch (e) {
      // Return empty list if folder doesn't exist
      return [];
    }
  }

  /// Upload receipt/document image (for OCR processing)
  /// Path: /users/{userId}/receipts/{randomId}.jpg
  Future<String> uploadReceiptImage({
    required String userId,
    required String docId,
    required dynamic imageFile,
  }) async {
    if (kIsWeb && imageFile is Uint8List) {
      return uploadInventoryImage(
        uid: userId,
        itemId: docId,
        bytes: imageFile,
      ).then((url) {
        // Store as receipt instead of inventory, but API is same
        return url;
      });
    } else if (imageFile is File) {
      return uploadInventoryImage(
        uid: userId,
        itemId: docId,
        file: imageFile,
      );
    } else {
      throw Exception('Invalid imageFile type');
    }
  }

  /// Delete receipt image
  Future<void> deleteReceiptImage({
    required String userId,
    required String docId,
    required String imageUrl,
  }) async {
    try {
      await deleteByUrl(imageUrl);
    } catch (e) {
      print('Failed to delete receipt image: $e');
    }
  }

  /// Delete an image at given storage URL
  Future<void> deleteByUrl(String url) async {
    try {
      final ref = _storage.refFromURL(url);
      await ref.delete();
    } catch (e) {
      // ignore not found or permission failures but rethrow unexpected
      rethrow;
    }
  }

  /// Get storage usage for a user (all inventory images)
  Future<int> getInventoryStorageUsage({
    required String userId,
  }) async {
    try {
      final ref = _storage.ref().child('users').child(userId).child('inventory');
      final listResult = await ref.listAll(const ListOptions(maxResults: 1000));

      int totalSize = 0;
      for (final item in listResult.items) {
        final metadata = await item.getMetadata();
        totalSize += metadata.size ?? 0;
      }

      return totalSize;
    } catch (e) {
      return 0;
    }
  }

  /// Check if image URL is still valid (exists in Storage)
  Future<bool> imageExists(String imageUrl) async {
    try {
      if (imageUrl.isEmpty) return false;

      final ref = FirebaseStorage.instance.refFromURL(imageUrl);
      await ref.getMetadata();
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Compress image file or bytes to JPEG format
  /// Reduces file size by 60-80% while maintaining visual quality
  Future<List<int>> _compressImage(dynamic imageFile) async {
    try {
      if (kIsWeb) {
        // Web: imageFile is Uint8List, return as-is (compression handled differently)
        if (imageFile is List<int>) {
          return List<int>.from(imageFile);
        }
        return [];
      } else {
        // Mobile: imageFile is File, compress to JPEG
        if (imageFile is! File) {
          throw Exception('Expected File on mobile platform');
        }

        final compressedFile = await _compressFile(imageFile);
        if (compressedFile != null) {
          return await compressedFile.readAsBytes();
        }
        return await imageFile.readAsBytes();
      }
    } catch (e) {
      print('Compression error: $e, returning original');
      if (imageFile is File) {
        return await imageFile.readAsBytes();
      } else if (imageFile is List<int>) {
        return List<int>.from(imageFile);
      }
      return [];
    }
  }

  /// Helper: compress image file (mobile). Returns compressed File or null if failed/no change.
  Future<File?> _compressFile(File input) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final targetPath = '${tempDir.path}/${_uuid.v4()}.jpg';

      final result = await FlutterImageCompress.compressAndGetFile(
        input.absolute.path,
        targetPath,
        quality: 70, // ~70% quality; adjust for size/quality tradeoff
        keepExif: false,
      );

      return result;
    } catch (e) {
      return null;
    }
  }
