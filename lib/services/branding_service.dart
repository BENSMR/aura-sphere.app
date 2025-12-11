import 'dart:io';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrandingService {
  final FirebaseStorage _storage = FirebaseStorage.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Future<String> uploadFile(String uid, File file, String destPath) async {
    final ref = _storage.ref().child('$destPath/${DateTime.now().millisecondsSinceEpoch}_${file.path.split('/').last}');
    final task = await ref.putFile(file);
    final url = await ref.getDownloadURL();
    return url;
  }

  Future<void> saveBranding(String uid, Map<String, dynamic> settings) async {
    await _db.collection('users').doc(uid).collection('branding').doc('settings').set(settings, SetOptions(merge: true));
  }
}
