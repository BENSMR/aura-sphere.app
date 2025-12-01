import 'package:flutter/material.dart';
import '../services/invoice_preview_service.dart';

class InvoicePreviewProvider extends ChangeNotifier {
  final InvoicePreviewService _service = InvoicePreviewService();

  String? _currentPreviewUrl;
  bool _isGenerating = false;
  String? _error;
  DateTime? _generatedAt;

  Map<String, String?> _templateVariants = {};
  bool _isGeneratingVariants = false;

  // Getters
  String? get currentPreviewUrl => _currentPreviewUrl;
  bool get isGenerating => _isGenerating;
  String? get error => _error;
  DateTime? get generatedAt => _generatedAt;
  Map<String, String?> get templateVariants => _templateVariants;
  bool get isGeneratingVariants => _isGeneratingVariants;

  bool get hasPreview => _currentPreviewUrl != null;

  /// Generate invoice preview
  Future<void> generatePreview({
    required String invoiceId,
    String templateId = 'default',
    bool includeSignature = true,
    String? watermarkText,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      _currentPreviewUrl = await _service.generateInvoicePreview(
        invoiceId: invoiceId,
        templateId: templateId,
        includeSignature: includeSignature,
        watermarkText: watermarkText,
      );

      _generatedAt = DateTime.now();
    } catch (e) {
      _error = e.toString();
      print('Error generating preview: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Generate preview with custom branding
  Future<void> generateCustomBrandingPreview({
    required String invoiceId,
    required Map<String, dynamic> customBranding,
  }) async {
    _isGenerating = true;
    _error = null;
    notifyListeners();

    try {
      _currentPreviewUrl = await _service.generateCustomBrandingPreview(
        invoiceId: invoiceId,
        customBranding: customBranding,
      );

      _generatedAt = DateTime.now();
    } catch (e) {
      _error = e.toString();
      print('Error generating custom branding preview: $e');
    } finally {
      _isGenerating = false;
      notifyListeners();
    }
  }

  /// Generate all template variants for comparison
  Future<void> generateAllTemplateVariants(String invoiceId) async {
    _isGeneratingVariants = true;
    _error = null;
    notifyListeners();

    try {
      _templateVariants =
          await _service.generateAllTemplateVariants(invoiceId);
    } catch (e) {
      _error = e.toString();
      print('Error generating template variants: $e');
    } finally {
      _isGeneratingVariants = false;
      notifyListeners();
    }
  }

  /// Clear current preview
  void clearPreview() {
    _currentPreviewUrl = null;
    _error = null;
    _generatedAt = null;
    notifyListeners();
  }

  /// Reset all state
  void reset() {
    _currentPreviewUrl = null;
    _isGenerating = false;
    _error = null;
    _generatedAt = null;
    _templateVariants = {};
    _isGeneratingVariants = false;
    notifyListeners();
  }

  /// Check if preview is expired (older than 1 hour)
  bool get isPreviewExpired {
    if (_generatedAt == null) return true;
    return DateTime.now().difference(_generatedAt!).inHours >= 1;
  }

  /// Get preview age as readable string
  String get previewAge {
    if (_generatedAt == null) return 'N/A';

    final difference = DateTime.now().difference(_generatedAt!);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes} minutes ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours} hours ago';
    } else {
      return '${difference.inDays} days ago';
    }
  }
}
