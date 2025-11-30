import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import '../models/business_profile.dart';
import '../services/business/business_profile_service.dart';

class BusinessProvider with ChangeNotifier {
  final BusinessProfileService _service = BusinessProfileService();
  String? _userId;
  
  BusinessProfile? _profile;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _error;
  Timer? _debounce;

  BusinessProvider() {
    // Initialize without userId - start() must be called with userId
  }

  // Getters
  BusinessProfile? get profile => _profile;
  BusinessProfile? get business => _profile; // Alias for backwards compatibility
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  bool get hasError => _error != null;
  String? get error => _error;
  bool get hasProfile => _profile != null;

  // Convenience getters from profile
  String get businessName => _profile?.businessName ?? 'My Business';
  String get legalName => _profile?.legalName ?? '';
  String get taxId => _profile?.taxId ?? '';
  String get logoUrl => _profile?.logoUrl ?? '';
  String get brandColor => _profile?.brandColor ?? '#0A84FF';
  String get defaultCurrency => _profile?.defaultCurrency ?? 'EUR';
  String get defaultLanguage => _profile?.defaultLanguage ?? 'en';
  String get invoiceTemplate => _profile?.invoiceTemplate ?? 'minimal';

  /// Start managing business profile for a specific user
  Future<void> start(String userId) async {
    _userId = userId;
    _setLoading(true);
    try {
      final profile = await _service.loadProfile(userId);
      _profile = profile;
      _clearError();
    } catch (e) {
      _setError('Failed to load business profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Stop and reset provider
  void stop() {
    _userId = null;
    _profile = null;
    _clearError();
    notifyListeners();
  }

  /// Save/update the entire profile (merge-safe)
  Future<void> saveProfile(Map<String, dynamic> data) async {
    if (_userId == null) {
      _setError('No user ID set. Call start(userId) first.');
      return;
    }
    
    _setSaving(true);
    try {
      await _service.saveProfile(_userId!, data);
      // Reload to get server-applied defaults and timestamps
      final updated = await _service.loadProfile(_userId!);
      _profile = updated;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to save profile: $e');
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  /// Upload a new logo and update profile
  Future<String?> uploadLogo(File file) async {
    if (_userId == null) {
      _setError('No user ID set. Call start(userId) first.');
      return null;
    }

    _setSaving(true);
    try {
      final logoUrl = await _service.uploadLogo(_userId!, file);
      if (_profile != null) {
        // Update local profile with new logo URL
        await saveProfile({'logoUrl': logoUrl});
      }
      _clearError();
      return logoUrl;
    } catch (e) {
      _setError('Failed to upload logo: $e');
      rethrow;
    } finally {
      _setSaving(false);
    }
  }

  /// Refresh profile from Firestore
  Future<void> reload() async {
    if (_userId == null) {
      _setError('No user ID set. Call start(userId) first.');
      return;
    }

    _setLoading(true);
    try {
      final profile = await _service.loadProfile(_userId!);
      _profile = profile;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to reload profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Delete business profile
  Future<void> deleteBusinessProfile() async {
    if (_userId == null) {
      _setError('No user ID set.');
      return;
    }

    _setLoading(true);
    try {
      // Delete from Firestore
      await _service.deleteProfile(_userId!);
      _profile = null;
      _clearError();
      notifyListeners();
    } catch (e) {
      _setError('Failed to delete profile: $e');
    } finally {
      _setLoading(false);
    }
  }

  /// Update a single field with debounce (for real-time forms)
  /// Changes are queued and saved after 600ms of inactivity
  void updateFieldDebounced(String key, dynamic value, {Duration delay = const Duration(milliseconds: 600)}) {
    if (_profile == null) return;

    // Update local state immediately for responsive UI
    _profile = _profile!.copyWith(
      businessName: key == 'businessName' ? value : _profile!.businessName,
      legalName: key == 'legalName' ? value : _profile!.legalName,
      taxId: key == 'taxId' ? value : _profile!.taxId,
      vatNumber: key == 'vatNumber' ? value : _profile!.vatNumber,
      address: key == 'address' ? value : _profile!.address,
      city: key == 'city' ? value : _profile!.city,
      postalCode: key == 'postalCode' ? value : _profile!.postalCode,
      invoicePrefix: key == 'invoicePrefix' ? value : _profile!.invoicePrefix,
      documentFooter: key == 'documentFooter' ? value : _profile!.documentFooter,
      brandColor: key == 'brandColor' ? value : _profile!.brandColor,
      watermarkText: key == 'watermarkText' ? value : _profile!.watermarkText,
      invoiceTemplate: key == 'invoiceTemplate' ? value : _profile!.invoiceTemplate,
      defaultCurrency: key == 'defaultCurrency' ? value : _profile!.defaultCurrency,
      defaultLanguage: key == 'defaultLanguage' ? value : _profile!.defaultLanguage,
    );
    notifyListeners();

    // Cancel previous save
    _debounce?.cancel();

    // Queue new save after delay
    _setSaving(true);
    _debounce = Timer(delay, () async {
      try {
        await saveProfile({key: value});
        _clearError();
      } catch (e) {
        _setError('Auto-save failed: $e');
      } finally {
        _setSaving(false);
        notifyListeners();
      }
    });
  }

  /// Update business profile with new data
  Future<void> updateBusinessProfile(Map<String, dynamic> data) async {
    await saveProfile(data);
  }

  /// Check if profile exists
  bool get hasBusinessProfile => _profile != null;

  // Private helpers
  void _setLoading(bool value) {
    if (_isLoading == value) return;
    _isLoading = value;
    notifyListeners();
  }

  void _setSaving(bool value) {
    if (_isSaving == value) return;
    _isSaving = value;
    notifyListeners();
  }

  void _setError(String error) {
    _error = error;
    notifyListeners();
  }

  void _clearError() {
    _error = null;
  }

  @override
  void dispose() {
    _debounce?.cancel();
    stop();
    super.dispose();
  }
}
