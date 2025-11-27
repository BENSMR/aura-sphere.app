import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_storage/firebase_storage.dart';
import '../../core/utils/logger.dart';

class StorageService {
  final FirebaseStorage _storage = FirebaseStorage.instance;

  Future<String> uploadFile(String path, File file) async {
    try {
      final ref = _storage.ref().child(path);
      final uploadTask = await ref.putFile(file);
      return await uploadTask.ref.getDownloadURL();
    } catch (e) {
      Logger.error('Failed to upload file', error: e);
      rethrow;
    }
  }

  /// Upload file from bytes (e.g., PDF in memory)
  /// 
  /// Parameters:
  /// - path: Storage path (e.g., 'invoices/userId/invoiceId.pdf')
  /// - bytes: File bytes to upload
  /// - contentType: MIME type (optional, defaults to 'application/octet-stream')
  /// 
  /// Returns: Download URL of uploaded file
  Future<String> uploadBytes(
    String path,
    Uint8List bytes, {
    String contentType = 'application/octet-stream',
  }) async {
    try {
      final ref = _storage.ref().child(path);
      final metadata = SettableMetadata(contentType: contentType);
      await ref.putData(bytes, metadata);
      return await ref.getDownloadURL();
    } catch (e) {
      Logger.error('Failed to upload bytes', error: e);
      rethrow;
    }
  }

  /// Upload invoice PDF bytes to Firebase Storage
  /// 
  /// Path: invoices/{userId}/{invoiceId}.pdf
  Future<String> uploadInvoicePdf(String userId, String invoiceId, Uint8List bytes) async {
    return uploadBytes(
      'invoices/$userId/$invoiceId.pdf',
      bytes,
      contentType: 'application/pdf',
    );
  }

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      Logger.error('Failed to delete file', error: e);
      rethrow;
    }
  }
}
