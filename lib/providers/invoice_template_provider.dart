import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/invoice_template_model.dart';
import '../data/repositories/invoice_templates.dart';

class InvoiceTemplateProvider extends ChangeNotifier {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  String _selectedInvoiceTemplate = 'modern';
  InvoiceTemplateModel? _selectedTemplate;
  Map<String, dynamic>? _templateCustomization;
  bool _isLoading = false;
  String? _error;
  List<String> _recentTemplates = [];

  // Getters
  String get selectedInvoiceTemplate => _selectedInvoiceTemplate;
  InvoiceTemplateModel? get selectedTemplate => _selectedTemplate;
  Map<String, dynamic>? get templateCustomization => _templateCustomization;
  bool get isLoading => _isLoading;
  String? get error => _error;
  List<String> get recentTemplates => _recentTemplates;

  InvoiceTemplateProvider() {
    _initializeDefaults();
  }

  /// Initialize with default template
  void _initializeDefaults() {
    _selectedInvoiceTemplate = 'modern';
    _selectedTemplate = InvoiceTemplates.getById(_selectedInvoiceTemplate);
    _templateCustomization = _selectedTemplate?.customization ?? {};
  }

  /// Load template preferences from Firestore
  Future<void> loadTemplatePreferences(String userId) async {
    try {
      _isLoading = true;
      _error = null;
      notifyListeners();

      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('invoice_templates')
          .get();

      if (doc.exists) {
        final data = doc.data();
        _selectedInvoiceTemplate = data?['selectedTemplate'] ?? 'modern';
        _recentTemplates = List<String>.from(data?['recentTemplates'] ?? []);
        _templateCustomization =
            data?['customization'] as Map<String, dynamic>?;
      } else {
        _selectedInvoiceTemplate = 'modern';
        _recentTemplates = [];
        _templateCustomization = {};
      }

      _selectedTemplate = InvoiceTemplates.getById(_selectedInvoiceTemplate);
      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load template preferences: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Save template preferences to Firestore
  Future<void> saveTemplatePreferences(String userId) async {
    try {
      _isLoading = true;
      notifyListeners();

      await _db
          .collection('users')
          .doc(userId)
          .collection('settings')
          .doc('invoice_templates')
          .set({
        'selectedTemplate': _selectedInvoiceTemplate,
        'recentTemplates': _recentTemplates,
        'customization': _templateCustomization,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      _isLoading = false;
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to save template preferences: $e';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a template by ID
  Future<void> selectTemplate(String templateId, {String? userId}) async {
    try {
      final template = InvoiceTemplates.getById(templateId);
      if (template == null) {
        _error = 'Template not found';
        notifyListeners();
        return;
      }

      _selectedInvoiceTemplate = templateId;
      _selectedTemplate = template;
      _templateCustomization = template.customization ?? {};

      // Add to recent templates
      _addToRecentTemplates(templateId);

      // Track usage
      InvoiceTemplates.incrementUsage(templateId);

      // Save to Firestore if userId provided
      if (userId != null) {
        await saveTemplatePreferences(userId);
      }

      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to select template: $e';
      notifyListeners();
    }
  }

  /// Select by template type
  Future<void> selectByType(String templateType, {String? userId}) async {
    final template = InvoiceTemplates.getByType(templateType);
    if (template != null) {
      await selectTemplate(template.id, userId: userId);
    } else {
      _error = 'Template type not found';
      notifyListeners();
    }
  }

  /// Add template to recent list (max 5)
  void _addToRecentTemplates(String templateId) {
    _recentTemplates.removeWhere((id) => id == templateId);
    _recentTemplates.insert(0, templateId);
    if (_recentTemplates.length > 5) {
      _recentTemplates = _recentTemplates.sublist(0, 5);
    }
  }

  /// Get recent template models
  List<InvoiceTemplateModel> getRecentTemplateModels() {
    return _recentTemplates
        .map((id) => InvoiceTemplates.getById(id))
        .whereType<InvoiceTemplateModel>()
        .toList();
  }

  /// Update template customization
  void updateCustomization(Map<String, dynamic> customization) {
    _templateCustomization = {
      ..._templateCustomization ?? {},
      ...customization,
    };
    notifyListeners();
  }

  /// Update specific customization field
  void updateCustomizationField(String key, dynamic value) {
    _templateCustomization = {
      ..._templateCustomization ?? {},
      key: value,
    };
    notifyListeners();
  }

  /// Get customization field
  dynamic getCustomizationField(String key, {dynamic defaultValue}) {
    return _templateCustomization?[key] ?? defaultValue;
  }

  /// Reset customization to template defaults
  void resetCustomization() {
    _templateCustomization = _selectedTemplate?.customization ?? {};
    notifyListeners();
  }

  /// Get all available templates
  List<InvoiceTemplateModel> getAllTemplates() {
    return InvoiceTemplates.available;
  }

  /// Filter templates by criteria
  List<InvoiceTemplateModel> filterTemplates({
    bool? premiumOnly,
    bool? activeOnly,
    String? category,
    String? templateType,
    List<String>? tags,
  }) {
    return InvoiceTemplates.filter(
      premiumOnly: premiumOnly,
      activeOnly: activeOnly,
      category: category,
      templateType: templateType,
      tags: tags,
    );
  }

  /// Search templates
  List<InvoiceTemplateModel> searchTemplates(String query) {
    return InvoiceTemplates.search(query);
  }

  /// Get recommended templates
  List<InvoiceTemplateModel> getRecommendedTemplates({int limit = 3}) {
    return InvoiceTemplates.getRecommended(limit: limit);
  }

  /// Get template statistics
  Map<String, int> getTemplateStats() {
    return InvoiceTemplates.getStats();
  }

  /// Check if current template is premium
  bool isCurrentTemplatePremium() {
    return _selectedTemplate?.isPremium ?? false;
  }

  /// Export current template and customization
  Map<String, dynamic> exportCurrentTemplate() {
    return {
      'templateId': _selectedInvoiceTemplate,
      'templateName': _selectedTemplate?.name,
      'templateType': _selectedTemplate?.templateType,
      'customization': _templateCustomization,
      'exportedAt': DateTime.now().toIso8601String(),
    };
  }

  /// Import template and customization
  Future<void> importTemplate(Map<String, dynamic> data,
      {String? userId}) async {
    try {
      final templateId = data['templateId'] as String?;
      if (templateId != null) {
        await selectTemplate(templateId, userId: userId);
        if (data['customization'] is Map<String, dynamic>) {
          updateCustomization(data['customization']);
        }
      }
    } catch (e) {
      _error = 'Failed to import template: $e';
      notifyListeners();
    }
  }

  /// Reset to default template
  Future<void> resetToDefault({String? userId}) async {
    _selectedInvoiceTemplate = 'modern';
    _selectedTemplate = InvoiceTemplates.getById(_selectedInvoiceTemplate);
    _templateCustomization = _selectedTemplate?.customization ?? {};
    _recentTemplates = [];

    if (userId != null) {
      await saveTemplatePreferences(userId);
    } else {
      notifyListeners();
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  /// Clear recent templates
  void clearRecentTemplates() {
    _recentTemplates = [];
    notifyListeners();
  }

  @override
  String toString() =>
      'InvoiceTemplateProvider(selected: $_selectedInvoiceTemplate, customization: $_templateCustomization)';
}
