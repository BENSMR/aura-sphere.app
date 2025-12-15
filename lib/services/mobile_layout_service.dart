import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Service to manage mobile dashboard layout preferences
class MobileLayoutService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user's mobile module preferences from Firestore
  /// Returns map of {featureName: isEnabled}
  Future<Map<String, bool>> getMobileModules() async {
    try {
      final user = _auth.currentUser;
      if (user == null) return {};

      final docSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('dashboard_layout')
          .get();

      if (!docSnapshot.exists) {
        return _getDefaultMobileModules();
      }

      final data = docSnapshot.data() ?? {};
      final mobileModules = Map<String, bool>.from(data['mobileModules'] ?? {});

      // Return only enabled features (max 8)
      return _enforceMobileLimit(mobileModules);
    } catch (e) {
      print('Error fetching mobile modules: $e');
      return _getDefaultMobileModules();
    }
  }

  /// Get default mobile layout (first 8 essential features)
  Map<String, bool> _getDefaultMobileModules() {
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

  /// Enforce max 8 features for mobile
  Map<String, bool> _enforceMobileLimit(Map<String, bool> modules) {
    final enabled = modules.entries
        .where((e) => e.value == true)
        .toList();

    // Keep only first 8 enabled features
    final limited = Map<String, bool>.fromIterable(
      enabled.take(8),
      key: (e) => (e as MapEntry).key,
      value: (e) => (e as MapEntry).value,
    );

    // Add disabled features for the rest
    modules.forEach((key, value) {
      if (!limited.containsKey(key)) {
        limited[key] = false;
      }
    });

    return limited;
  }

  /// Get enabled features to render (filtered, max 8)
  Future<List<String>> getEnabledMobileFeatures() async {
    final modules = await getMobileModules();
    return modules.entries
        .where((e) => e.value == true)
        .map((e) => e.key)
        .toList()
        .cast<String>()
        .take(8)
        .toList();
  }

  /// Save mobile layout preferences
  Future<void> saveMobileModules(Map<String, bool> modules) async {
    try {
      final user = _auth.currentUser;
      if (user == null) throw Exception('User not authenticated');

      // Enforce limit before saving
      final limited = _enforceMobileLimit(modules);

      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('settings')
          .doc('dashboard_layout')
          .set(
            {
              'mobileModules': limited,
              'tabletModules': FieldValue.serverTimestamp(),
              'updatedAt': FieldValue.serverTimestamp(),
            },
            SetOptions(merge: true),
          );
    } catch (e) {
      print('Error saving mobile modules: $e');
      rethrow;
    }
  }

  /// Check if feature is enabled
  Future<bool> isFeatureEnabled(String featureName) async {
    final modules = await getMobileModules();
    return modules[featureName] ?? false;
  }

  /// Get count of enabled features
  Future<int> getEnabledFeatureCount() async {
    final modules = await getMobileModules();
    return modules.values.where((enabled) => enabled).length;
  }
}
