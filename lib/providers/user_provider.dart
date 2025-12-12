import 'dart:async';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../data/models/user_model.dart';
import '../services/firebase/auth_service.dart';
import '../services/device_init_service.dart';
import 'business_provider.dart';
import 'invoice_provider.dart';

class UserProvider with ChangeNotifier {
  final AuthService _authService;
  final DeviceInitService _deviceInitService = DeviceInitService();
  AppUser? _appUser;
  bool _loading = true;
  
  // Will be injected via setters
  BusinessProvider? _businessProvider;
  InvoiceProvider? _invoiceProvider;

  StreamSubscription<User?>? _authSub;
  StreamSubscription<AppUser?>? _userSub;

  UserProvider(this._authService) {
    _init();
  }
  
  /// Set business provider reference for initialization on login
  void setBusinessProvider(BusinessProvider provider) {
    _businessProvider = provider;
  }

  /// Set invoice provider reference for lifecycle hooks
  void setInvoiceProvider(InvoiceProvider provider) {
    _invoiceProvider = provider;
  }

  AppUser? get user => _appUser;
  bool get loading => _loading;
  bool get isLoggedIn => _appUser != null;

  void _init() {
    _authSub = _authService.authStateChanges().listen((firebaseUser) {
      _userSub?.cancel();
      if (firebaseUser == null) {
        _appUser = null;
        // Stop business provider on logout
        _businessProvider?.stop();
        // Stop invoice provider on logout
        _invoiceProvider?.stopWatching();
        _setLoading(false);
        return;
      }

      // Initialize device timezone/locale/country on login
      _deviceInitService.initializeUserDeviceInfo(uid: firebaseUser.uid).ignore();

      // Start business provider on login
      _businessProvider?.start(firebaseUser.uid);
      // Start invoice provider on login
      _invoiceProvider?.startWatching(firebaseUser.uid);

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

  Future<void> sendPasswordResetEmail(String email) async {
    _setLoading(true);
    try {
      await _authService.sendPasswordResetEmail(email);
    } finally {
      _setLoading(false);
    }
  }

  /// Set user's preferred invoice template
  Future<void> setInvoiceTemplate(String templateId) async {
    if (_appUser == null) return;
    try {
      // This would be implemented in your user service/repository
      // For now, we'll store it locally
      _appUser = _appUser?.copyWith(invoiceTemplate: templateId);
      notifyListeners();
    } catch (e) {
      print('Error setting invoice template: $e');
    }
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
