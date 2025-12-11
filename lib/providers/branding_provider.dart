import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class BrandingProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  Map<String, dynamic>? settings;
  Map<String, dynamic>? invoiceSettings;
  bool loading = false;

  // Template constants
  static const String TEMPLATE_CLASSIC = 'TEMPLATE_CLASSIC';
  static const String TEMPLATE_MODERN = 'TEMPLATE_MODERN';
  static const String TEMPLATE_MINIMAL = 'TEMPLATE_MINIMAL';
  static const String TEMPLATE_ELEGANT = 'TEMPLATE_ELEGANT';
  static const String TEMPLATE_BUSINESS = 'TEMPLATE_BUSINESS';

  static const List<String> availableTemplates = [
    TEMPLATE_CLASSIC,
    TEMPLATE_MODERN,
    TEMPLATE_MINIMAL,
    TEMPLATE_ELEGANT,
    TEMPLATE_BUSINESS,
  ];

  // Invoice numbering reset rules
  static const String RESET_NONE = 'none';
  static const String RESET_MONTHLY = 'monthly';
  static const String RESET_YEARLY = 'yearly';

  Future<void> load(String uid) async {
    loading = true;
    notifyListeners();
    
    final brandingSnap = await _db.collection('users').doc(uid).collection('branding').doc('settings').get();
    settings = brandingSnap.exists ? brandingSnap.data() : {};
    
    final invoiceSnap = await _db.collection('users').doc(uid).collection('settings').doc('invoice_settings').get();
    invoiceSettings = invoiceSnap.exists ? invoiceSnap.data() : _defaultInvoiceSettings();
    
    loading = false;
    notifyListeners();
  }
  

  Map<String, dynamic> _defaultInvoiceSettings() {
    return {
      'prefix': 'AURA-',
      'nextNumber': 1001,
      'resetRule': RESET_YEARLY,
      'lastReset': Timestamp.now(),
    };
  }

  Future<void> save(String uid, Map<String, dynamic> newSettings) async {
    await _db.collection('users').doc(uid).collection('branding').doc('settings').set(newSettings, SetOptions(merge: true));
    settings = {...(settings ?? {}), ...newSettings};
    notifyListeners();
  }

  Future<void> saveInvoiceSettings(String uid, Map<String, dynamic> newSettings) async {
    await _db.collection('users').doc(uid).collection('settings').doc('invoice_settings').set(newSettings, SetOptions(merge: true));
    invoiceSettings = {...(invoiceSettings ?? {}), ...newSettings};
    notifyListeners();
  }

  Future<void> selectTemplate(String uid, String templateId) async {
    await _db.collection('users').doc(uid).collection('branding').doc('settings').set({'templateId': templateId}, SetOptions(merge: true));
    settings = {...(settings ?? {}), 'templateId': templateId};
    notifyListeners();
  }

  Future<String> getNextInvoiceNumber() async {
    if (invoiceSettings == null) {
      return 'AURA-1001';
    }
    
    String prefix = invoiceSettings?['prefix'] ?? 'AURA-';
    int nextNumber = invoiceSettings?['nextNumber'] ?? 1001;
    
    return '$prefix${nextNumber.toString().padLeft(4, '0')}';
  }

  int getNextInvoiceNumberValue() {
    return invoiceSettings?['nextNumber'] as int? ?? 1001;
  }

  Future<String> generateNextInvoiceNumber(String uid) async {
    final docRef = _db.collection('users').doc(uid).collection('settings').doc('invoice_settings');
    
    // Get current settings
    final snap = await docRef.get();
    final current = snap.data() ?? _defaultInvoiceSettings();
    
    String prefix = current['prefix'] ?? 'AURA-';
    int nextNumber = current['nextNumber'] ?? 1001;
    String resetRule = current['resetRule'] ?? RESET_YEARLY;
    Timestamp lastReset = current['lastReset'] ?? Timestamp.now();
    
    // Check if reset is needed
    if (resetRule != RESET_NONE) {
      if (_shouldReset(lastReset.toDate(), resetRule)) {
        nextNumber = 1001; // Reset to starting number
        lastReset = Timestamp.now();
      }
    }
    
    // Generate invoice number
    final invoiceNumber = '$prefix${nextNumber.toString().padLeft(4, '0')}';
    
    // Increment and save
    await docRef.set({
      'prefix': prefix,
      'nextNumber': nextNumber + 1,
      'resetRule': resetRule,
      'lastReset': lastReset,
    }, SetOptions(merge: true));
    
    // Update local state
    invoiceSettings = {
      'prefix': prefix,
      'nextNumber': nextNumber + 1,
      'resetRule': resetRule,
      'lastReset': lastReset,
    };
    notifyListeners();
    
    return invoiceNumber;
  }

  bool _shouldReset(DateTime lastReset, String resetRule) {
    final now = DateTime.now();
    
    if (resetRule == RESET_MONTHLY) {
      return now.year != lastReset.year || now.month != lastReset.month;
    } else if (resetRule == RESET_YEARLY) {
      return now.year != lastReset.year;
    }
    
    return false;
  }

  String? getTemplateId() {
    return settings?['templateId'] as String?;
  }

  String? getInvoiceNumberPrefix() {
    return invoiceSettings?['prefix'] as String?;
  }

  String getResetRule() {
    return invoiceSettings?['resetRule'] as String? ?? RESET_YEARLY;
  }
}
