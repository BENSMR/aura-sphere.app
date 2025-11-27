import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

import '../../data/models/user_model.dart';

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _fire = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

  Stream<User?> authStateChanges() => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  // Sign up with email & password and create Firestore profile
  Future<AppUser> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    // create user doc
    final userDoc = _fire.collection('users').doc(user.uid);
    final appUser = AppUser(
      uid: user.uid,
      email: email,
      firstName: firstName,
      lastName: lastName,
      avatarUrl: '',
      auraTokens: 200, // welcome bonus
    );
    await userDoc.set(appUser.toMap());
    return appUser;
  }

  // Login with email/password
  Future<AppUser> signInWithEmail({
    required String email,
    required String password,
  }) async {
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    final user = cred.user!;
    final snapshot = await _fire.collection('users').doc(user.uid).get();
    if (!snapshot.exists) {
      // If missing, create minimal profile
      final appUser = AppUser(
        uid: user.uid,
        email: email,
        firstName: '',
        lastName: '',
        avatarUrl: '',
        auraTokens: 200,
      );
      await _fire.collection('users').doc(user.uid).set(appUser.toMap());
      return appUser;
    }
    return AppUser.fromFirestore(snapshot);
  }

  // Google Sign-In
  Future<AppUser> signInWithGoogle() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) {
      throw FirebaseAuthException(
        code: 'ERROR_ABORTED_BY_USER',
        message: 'Sign in aborted by user',
      );
    }
    final googleAuth = await googleUser.authentication;
    final credential = GoogleAuthProvider.credential(
      idToken: googleAuth.idToken,
      accessToken: googleAuth.accessToken,
    );
    final userCredential = await _auth.signInWithCredential(credential);
    final user = userCredential.user!;
    final userRef = _fire.collection('users').doc(user.uid);
    final snapshot = await userRef.get();
    if (!snapshot.exists) {
      // create new profile using Google details
      final displayName = user.displayName ?? '';
      final parts = displayName.split(' ');
      final firstName = parts.isNotEmpty ? parts.first : '';
      final lastName = parts.length > 1 ? parts.sublist(1).join(' ') : '';
      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        firstName: firstName,
        lastName: lastName,
        avatarUrl: user.photoURL ?? '',
        auraTokens: 200,
      );
      await userRef.set(appUser.toMap());
      return appUser;
    }
    return AppUser.fromFirestore(snapshot);
  }

  Future<void> signOut() async {
    await _auth.signOut();
    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }

  // Read app user live
  Stream<AppUser?> appUserStream(String uid) {
    return _fire.collection('users').doc(uid).snapshots().map((snap) {
      if (!snap.exists) return null;
      return AppUser.fromFirestore(snap);
    });
  }

  // Update profile
  Future<void> updateProfile(String uid, Map<String, dynamic> updates) async {
    final ref = _fire.collection('users').doc(uid);
    await ref.update(updates);
  }
}
