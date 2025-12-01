import 'package:flutter/material.dart';
import '../models/business_branding.dart';
import '../services/business_branding_service.dart';

class BusinessBrandingProvider extends ChangeNotifier {
  final BusinessBrandingService _service = BusinessBrandingService();
  
  BusinessBranding? _branding;
  bool _isLoading = false;
  String? _error;

  // Getters
  BusinessBranding? get branding => _branding;
  bool get isLoading => _isLoading;
  String? get error => _error;
  
  bool get hasCustomBranding => _branding != null;

  /// Fetch business branding
  Future<void> fetchBranding() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _branding = await _service.getBusinessBranding();
    } catch (e) {
      _error = e.toString();
      print('Error fetching branding: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Watch business branding for real-time updates
  void watchBranding() {
    _service.watchBusinessBranding().listen((branding) {
      _branding = branding;
      notifyListeners();
    });
  }

  /// Update full branding
  Future<void> updateBranding(BusinessBranding branding) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateBusinessBranding(branding);
      _branding = branding;
    } catch (e) {
      _error = e.toString();
      print('Error updating branding: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update logo
  Future<void> updateLogo(String logoUrl) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateLogoUrl(logoUrl);
      _branding = _branding?.copyWith(logoUrl: logoUrl);
    } catch (e) {
      _error = e.toString();
      print('Error updating logo: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update colors
  Future<void> updateColors({
    required String primaryColor,
    required String accentColor,
    required String textColor,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateColors(
        primaryColor: primaryColor,
        accentColor: accentColor,
        textColor: textColor,
      );
      _branding = _branding?.copyWith(
        primaryColor: primaryColor,
        accentColor: accentColor,
        textColor: textColor,
      );
    } catch (e) {
      _error = e.toString();
      print('Error updating colors: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update company details
  Future<void> updateCompanyDetails(CompanyDetails details) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.setCompanyDetails(details);
      _branding = _branding?.copyWith(companyDetails: details);
    } catch (e) {
      _error = e.toString();
      print('Error updating company details: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update signature settings
  Future<void> updateSignature({
    required bool showSignature,
    String? signatureUrl,
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      await _service.updateSignature(
        showSignature: showSignature,
        signatureUrl: signatureUrl,
      );
      _branding = _branding?.copyWith(
        showSignature: showSignature,
        signatureUrl: signatureUrl,
      );
    } catch (e) {
      _error = e.toString();
      print('Error updating signature: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset branding to null
  void resetBranding() {
    _branding = null;
    _error = null;
    notifyListeners();
  }
}
