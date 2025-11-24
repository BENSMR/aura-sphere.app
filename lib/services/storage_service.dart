import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import '../core/logger.dart';

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

  Future<void> deleteFile(String path) async {
    try {
      await _storage.ref().child(path).delete();
    } catch (e) {
      Logger.error('Failed to delete file', error: e);
      rethrow;
    }
  }
}
