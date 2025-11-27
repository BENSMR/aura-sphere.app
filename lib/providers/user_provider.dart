import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/user_model.dart';
import '../services/firebase/auth_service.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService;
  AppUser? _appUser;
  bool _loading = true;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _userSub;

  UserProvider(this._authService) {
    _init();
  }

  AppUser? get user => _appUser;
  bool get loading => _loading;
  bool get isLoggedIn => _appUser != null;

  void _init() {
    _authSub = _authService.authStateChanges().listen((firebaseUser) {
      _userSub?.cancel();
      if (firebaseUser == null) {
        _appUser = null;
        _setLoading(false);
        return;
      }

      _userSub = _authService.appUserStream(firebaseUser.uid).listen(
        (appUser) {
          _appUser = appUser;
          _setLoading(false);
        },
        onError: (_) {
          _appUser = null;
          _setLoading(false);
        },
      );
    }, onError: (_) {
      _appUser = null;
      _setLoading(false);
    });
  }

  Future<void> signInWithEmail(String email, String password) async {
    _setLoading(true);
    await _authService.signInWithEmail(email: email, password: password);
    _setLoading(false);
  }

  Future<void> signUpWithEmail(String email, String password, String firstName, String lastName) async {
    _setLoading(true);
    await _authService.signUpWithEmail(
      email: email,
      password: password,
      firstName: firstName,
      lastName: lastName,
    );
    _setLoading(false);
  }

  Future<void> signInWithGoogle() async {
    _setLoading(true);
    await _authService.signInWithGoogle();
    _setLoading(false);
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _setLoading(false);
  }

  void _setLoading(bool value) {
    if (_loading == value) return;
    _loading = value;
    notifyListeners();
  }

  @override
  void dispose() {
    _authSub?.cancel();
    _userSub?.cancel();
    super.dispose();
  }
}
