import 'package:flutter/material.dart';
import '../services/invoice/invoice_template_service.dart';

/// Provider for managing invoice template selection
class TemplateProvider extends ChangeNotifier {
  String _selectedTemplate = InvoiceTemplateService.classic;
  bool _isLoading = false;

  String get selectedTemplate => _selectedTemplate;
  bool get isLoading => _isLoading;

  TemplateProvider() {
    _initializeTemplate();
  }

  /// Initialize template (defaults to classic)
  Future<void> _initializeTemplate() async {
    try {
      _isLoading = true;
      notifyListeners();
      _selectedTemplate = InvoiceTemplateService.classic;
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Select a template
  void setTemplate(String templateKey) {
    _selectedTemplate = templateKey;
    notifyListeners();
  }

  /// Get list of available templates
  Map<String, String> getAvailableTemplates() {
    return InvoiceTemplateService.available;
  }
}
