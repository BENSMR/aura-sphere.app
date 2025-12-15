import 'package:flutter/material.dart';
import '../services/mobile_layout_service.dart';

/// Provider for managing mobile dashboard layout
class MobileLayoutProvider extends ChangeNotifier {
  final MobileLayoutService _service = MobileLayoutService();

  Map<String, bool> _mobileModules = {};
  List<String> _enabledFeatures = [];
  bool _isLoading = false;
  String? _error;

  // Getters
  Map<String, bool> get mobileModules => _mobileModules;
  List<String> get enabledFeatures => _enabledFeatures;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get enabledFeatureCount => _enabledFeatures.length;
  int get maxFeatures => 8;

  /// Load mobile layout preferences
  Future<void> loadMobileLayout() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      _mobileModules = await _service.getMobileModules();
      _enabledFeatures = await _service.getEnabledMobileFeatures();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error loading mobile layout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Update a single feature's enabled status
  Future<void> toggleFeature(String featureName) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final updated = Map<String, bool>.from(_mobileModules);
      updated[featureName] = !(updated[featureName] ?? false);

      // Enforce limit (max 8 enabled)
      final enabledCount = updated.values.where((e) => e).length;
      if (enabledCount > maxFeatures) {
        _error = 'Maximum $maxFeatures features allowed on mobile';
        _isLoading = false;
        notifyListeners();
        return;
      }

      await _service.saveMobileModules(updated);
      _mobileModules = updated;
      _enabledFeatures = updated.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error toggling feature: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Reset to default mobile layout
  Future<void> resetToDefault() async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final defaults = _service.getDefaultMobileModules();
      await _service.saveMobileModules(defaults);
      _mobileModules = defaults;
      _enabledFeatures = defaults.entries
          .where((e) => e.value == true)
          .map((e) => e.key)
          .toList();
      _error = null;
    } catch (e) {
      _error = e.toString();
      print('Error resetting layout: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Check if feature is enabled
  bool isFeatureEnabled(String featureName) {
    return _mobileModules[featureName] ?? false;
  }

  /// Get feature count
  int getEnabledCount() {
    return _enabledFeatures.length;
  }
}

// Define getDefaultMobileModules as public method
extension on MobileLayoutService {
  Map<String, bool> getDefaultMobileModules() {
    return {
      'scanReceipts': true,
      'quickContacts': true,
      'sendInvoices': true,
      'inventoryStock': true,
      'taskBoard': true,
      'loyaltyPoints': true,
      'walletBalance': true,
      'aiAlerts': true,
      'fullReports': false,
      'teamManagement': false,
      'advancedSettings': false,
      'dashboard': false,
    };
  }
}
