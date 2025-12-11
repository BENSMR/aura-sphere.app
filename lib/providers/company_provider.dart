import 'package:flutter/material.dart';
import '../models/company.dart';
import '../services/company_service.dart';

/// Provider for managing company state
/// 
/// Handles:
/// - Loading companies
/// - Selecting active company
/// - Creating/updating/deleting companies
/// - Caching company data
class CompanyProvider extends ChangeNotifier {
  final CompanyService _service = CompanyService();

  List<Company> _companies = [];
  Company? _activeCompany;
  bool _isLoading = false;
  String? _error;

  // Getters
  List<Company> get companies => _companies;
  Company? get activeCompany => _activeCompany;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasCompanies => _companies.isNotEmpty;

  /// Initialize: Load companies and set active
  Future<void> init() async {
    try {
      _setLoading(true);
      _error = null;

      _companies = await _service.getCompanies();
      _activeCompany = await _service.getDefaultCompany();

      // If no default set, use first
      if (_activeCompany == null && _companies.isNotEmpty) {
        _activeCompany = _companies.first;
      }

      print('✅ CompanyProvider initialized with ${_companies.length} companies');
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      print('❌ Error initializing CompanyProvider: $e');
    }
  }

  /// Load companies from Firestore
  Future<void> loadCompanies() async {
    try {
      _setLoading(true);
      _error = null;

      _companies = await _service.getCompanies();

      // Ensure active company still exists
      if (_activeCompany != null &&
          !_companies.any((c) => c.id == _activeCompany!.id)) {
        _activeCompany = _companies.isNotEmpty ? _companies.first : null;
      }

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      print('❌ Error loading companies: $e');
    }
  }

  /// Set active company
  void setActiveCompany(Company company) {
    if (_companies.any((c) => c.id == company.id)) {
      _activeCompany = company;
      notifyListeners();
      print('✅ Active company changed to: ${company.name}');
    }
  }

  /// Get company by ID
  Company? getCompanyById(String id) {
    try {
      return _companies.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Create new company
  Future<String?> createCompany({
    required String name,
    required String country,
    required String defaultCurrency,
    required bool isBusiness,
    String? vatNumber,
    String? taxId,
    String? businessEmail,
    String? businessPhone,
    String? address,
    String? city,
    String? postalCode,
  }) async {
    try {
      _error = null;
      _setLoading(true);

      final id = await _service.createCompany(
        name: name,
        country: country,
        defaultCurrency: defaultCurrency,
        isBusiness: isBusiness,
        vatNumber: vatNumber,
        taxId: taxId,
        businessEmail: businessEmail,
        businessPhone: businessPhone,
        address: address,
        city: city,
        postalCode: postalCode,
      );

      // Reload companies
      await loadCompanies();
      print('✅ Company created: $id');
      return id;
    } catch (e) {
      _error = e.toString();
      print('❌ Error creating company: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update company
  Future<bool> updateCompany(Company company) async {
    try {
      _error = null;
      _setLoading(true);

      await _service.updateCompany(company);

      // Update local state
      final index = _companies.indexWhere((c) => c.id == company.id);
      if (index >= 0) {
        _companies[index] = company;
      }

      // Update active if it was the modified company
      if (_activeCompany?.id == company.id) {
        _activeCompany = company;
      }

      notifyListeners();
      print('✅ Company updated: ${company.id}');
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error updating company: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update company fields
  Future<bool> updateCompanyFields(
    String companyId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _error = null;
      await _service.updateCompanyFields(companyId, updates);

      // Update local state
      final company = getCompanyById(companyId);
      if (company != null) {
        final updated = company.copyWith(
          name: updates['name'],
          country: updates['country'],
          defaultCurrency: updates['defaultCurrency'],
          isBusiness: updates['isBusiness'],
          vatNumber: updates['vatNumber'],
          taxId: updates['taxId'],
          businessEmail: updates['businessEmail'],
          businessPhone: updates['businessPhone'],
          address: updates['address'],
          city: updates['city'],
          postalCode: updates['postalCode'],
        );
        await updateCompany(updated);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error updating company fields: $e');
      return false;
    }
  }

  /// Set company as default
  Future<bool> setAsDefault(String companyId) async {
    try {
      _error = null;
      _setLoading(true);

      await _service.setAsDefault(companyId);
      await loadCompanies();

      _activeCompany = getCompanyById(companyId);
      notifyListeners();
      print('✅ Company set as default: $companyId');
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error setting default company: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete company
  Future<bool> deleteCompany(String companyId) async {
    try {
      _error = null;
      _setLoading(true);

      await _service.deleteCompany(companyId);

      // Remove from local list
      _companies.removeWhere((c) => c.id == companyId);

      // Clear active if it was deleted
      if (_activeCompany?.id == companyId) {
        _activeCompany = _companies.isNotEmpty ? _companies.first : null;
      }

      notifyListeners();
      print('✅ Company deleted: $companyId');
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error deleting company: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Validate VAT number
  bool isValidVatNumber(String? vat) {
    return _service.isValidVatNumber(vat);
  }

  /// Check if VAT exists
  Future<bool> vatNumberExists(String vatNumber, {String? excludeCompanyId}) async {
    return _service.vatNumberExists(vatNumber, excludeCompanyId: excludeCompanyId);
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get available currencies for active company
  List<String> getAvailableCurrencies() {
    if (_activeCompany == null) return [];
    return [_activeCompany!.defaultCurrency];
  }

  /// Get available countries for active company
  String? getActiveCountry() {
    return _activeCompany?.country;
  }
}
