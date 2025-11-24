import 'package:firebase_auth/firebase_auth.dart';
import '../core/logger.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential?> signInWithEmailPassword(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      Logger.error('Sign in failed', error: e);
      rethrow;
    }
  }

  Future<UserCredential?> signUpWithEmailPassword(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(email: email, password: password);
    } catch (e) {
      Logger.error('Sign up failed', error: e);
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }
}
