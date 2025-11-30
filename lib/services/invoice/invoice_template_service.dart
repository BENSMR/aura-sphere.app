import '../../data/models/invoice_model.dart';

/// Stub invoice template service - full PDF generation will be implemented later
class InvoiceTemplateService {
  /// Available template keys
  static const minimal = 'minimal';
  static const classic = 'classic';
  static const modern = 'modern';

  /// Return list of available templates
  static Map<String, String> get available => {
    minimal: 'Minimal Pro',
    classic: 'Business Classic',
    modern: 'Creative Modern',
  };

  /// Get template name
  static String getTemplateName(String key) => available[key] ?? 'Unknown';
}
