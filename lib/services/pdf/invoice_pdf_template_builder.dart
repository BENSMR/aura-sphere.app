import 'dart:typed_data';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:intl/intl.dart';
import '../../data/models/invoice_model.dart';
import 'invoice_pdf_template_factory.dart';

class InvoicePdfTemplateBuilder {
  /// Main factory method - returns PDF bytes based on template type
  static Future<Uint8List> buildPdf(
    String templateType,
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo, {
    Map<String, dynamic>? customization,
  }) async {
    switch (templateType.toLowerCase()) {
      case 'modern':
        return _buildModernTemplate(invoice, businessInfo, customization);

      case 'classic':
        return _buildClassicTemplate(invoice, businessInfo, customization);

      case 'dark':
        return _buildDarkTemplate(invoice, businessInfo, customization);

      case 'gradient':
        return _buildGradientTemplate(invoice, businessInfo, customization);

      case 'minimal':
        return _buildMinimalTemplate(invoice, businessInfo, customization);

      case 'business':
        return _buildBusinessTemplate(invoice, businessInfo, customization);

      default:
        return _buildModernTemplate(invoice, businessInfo, customization);
    }
  }

  /// Generate modern template PDF
  static Future<Uint8List> _buildModernTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        InvoicePdfTemplateFactory.buildPage(
          'modern',
          invoice,
          businessInfo,
          customization: customization,
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to build modern template: $e');
    }
  }

  /// Generate classic template PDF
  static Future<Uint8List> _buildClassicTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        InvoicePdfTemplateFactory.buildPage(
          'classic',
          invoice,
          businessInfo,
          customization: customization,
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to build classic template: $e');
    }
  }

  /// Generate dark template PDF
  static Future<Uint8List> _buildDarkTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        InvoicePdfTemplateFactory.buildPage(
          'dark',
          invoice,
          businessInfo,
          customization: customization,
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to build dark template: $e');
    }
  }

  /// Generate gradient template PDF
  static Future<Uint8List> _buildGradientTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        InvoicePdfTemplateFactory.buildPage(
          'gradient',
          invoice,
          businessInfo,
          customization: customization,
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to build gradient template: $e');
    }
  }

  /// Generate minimal template PDF
  static Future<Uint8List> _buildMinimalTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        InvoicePdfTemplateFactory.buildPage(
          'minimal',
          invoice,
          businessInfo,
          customization: customization,
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to build minimal template: $e');
    }
  }

  /// Generate business template PDF
  static Future<Uint8List> _buildBusinessTemplate(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    Map<String, dynamic>? customization,
  ) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        InvoicePdfTemplateFactory.buildPage(
          'business',
          invoice,
          businessInfo,
          customization: customization,
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to build business template: $e');
    }
  }

  /// Generate multi-page PDF with all available templates
  static Future<Uint8List> buildAllTemplatesPdf(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo, {
    Map<String, dynamic>? customization,
  }) async {
    try {
      final pdf = pw.Document();

      final templates = ['modern', 'classic', 'dark', 'gradient', 'minimal', 'business'];

      for (final template in templates) {
        pdf.addPage(
          InvoicePdfTemplateFactory.buildPage(
            template,
            invoice,
            businessInfo,
            customization: customization,
          ),
        );
      }

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to build all templates PDF: $e');
    }
  }

  /// Generate specific templates as multi-page PDF
  static Future<Uint8List> buildSelectedTemplatesPdf(
    List<String> templateTypes,
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo, {
    Map<String, dynamic>? customization,
  }) async {
    try {
      final pdf = pw.Document();

      for (final template in templateTypes) {
        pdf.addPage(
          InvoicePdfTemplateFactory.buildPage(
            template,
            invoice,
            businessInfo,
            customization: customization,
          ),
        );
      }

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to build selected templates PDF: $e');
    }
  }

  /// Generate PDF with multiple invoices (batch processing)
  static Future<Uint8List> buildBatchInvoicesPdf(
    List<InvoiceModel> invoices,
    String templateType,
    Map<String, dynamic>? businessInfo, {
    Map<String, dynamic>? customization,
  }) async {
    try {
      final pdf = pw.Document();

      for (final invoice in invoices) {
        pdf.addPage(
          InvoicePdfTemplateFactory.buildPage(
            templateType,
            invoice,
            businessInfo,
            customization: customization,
          ),
        );
      }

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to build batch invoices PDF: $e');
    }
  }

  /// Get PDF filename based on template and invoice
  static String getFileName(
    String templateType,
    InvoiceModel invoice, {
    bool includeTemplate = false,
  }) {
    final invoiceNum = invoice.invoiceNumber ?? invoice.id;
    final dateFormat = DateFormat('yyyyMMdd');
    final date = dateFormat.format(invoice.createdAt);

    if (includeTemplate) {
      return 'Invoice-${invoiceNum}_${templateType}_${date}.pdf';
    }
    return 'Invoice-${invoiceNum}_${date}.pdf';
  }

  /// Generate all templates and return as map with filename keys
  static Future<Map<String, Uint8List>> buildAllTemplatesAsMap(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo, {
    Map<String, dynamic>? customization,
  }) async {
    try {
      final templates = {
        'modern': await _buildModernTemplate(invoice, businessInfo, customization),
        'classic': await _buildClassicTemplate(invoice, businessInfo, customization),
        'dark': await _buildDarkTemplate(invoice, businessInfo, customization),
        'gradient': await _buildGradientTemplate(invoice, businessInfo, customization),
        'minimal': await _buildMinimalTemplate(invoice, businessInfo, customization),
        'business': await _buildBusinessTemplate(invoice, businessInfo, customization),
      };

      return templates;
    } catch (e) {
      throw Exception('Failed to build all templates as map: $e');
    }
  }

  /// Get template display names
  static String getTemplateDisplayName(String templateType) {
    switch (templateType.toLowerCase()) {
      case 'modern':
        return 'Modern Clean';
      case 'classic':
        return 'Classic Professional';
      case 'dark':
        return 'Dark Elegant';
      case 'gradient':
        return 'Gradient Neo';
      case 'minimal':
        return 'Ultra Minimal';
      case 'business':
        return 'Business Standard';
      default:
        return 'Modern';
    }
  }

  /// Get all available template types
  static List<String> getAvailableTemplates() {
    return ['modern', 'classic', 'dark', 'gradient', 'minimal', 'business'];
  }

  /// Build PDF with template metadata
  static Future<Map<String, dynamic>> buildPdfWithMetadata(
    String templateType,
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo, {
    Map<String, dynamic>? customization,
  }) async {
    try {
      final pdfBytes = await buildPdf(
        templateType,
        invoice,
        businessInfo,
        customization: customization,
      );

      return {
        'pdf': pdfBytes,
        'templateType': templateType,
        'templateName': getTemplateDisplayName(templateType),
        'fileName': getFileName(templateType, invoice, includeTemplate: true),
        'invoiceNumber': invoice.invoiceNumber ?? invoice.id,
        'invoiceDate': invoice.createdAt.toIso8601String(),
        'fileSizeKB': (pdfBytes.lengthInBytes / 1024).toStringAsFixed(2),
      };
    } catch (e) {
      throw Exception('Failed to build PDF with metadata: $e');
    }
  }

  /// Validate template type
  static bool isValidTemplate(String templateType) {
    return getAvailableTemplates().contains(templateType.toLowerCase());
  }

  /// Get template colors for UI display
  static Map<String, String> getTemplateColors(String templateType) {
    switch (templateType.toLowerCase()) {
      case 'modern':
        return {
          'primary': '#3b82f6',
          'accent': '#60a5fa',
          'background': '#f9fafb',
        };
      case 'classic':
        return {
          'primary': '#1e40af',
          'accent': '#1e3a8a',
          'background': '#ffffff',
        };
      case 'dark':
        return {
          'primary': '#1e1e1e',
          'accent': '#fbbf24',
          'background': '#0f0f0f',
        };
      case 'gradient':
        return {
          'primary': '#8b5cf6',
          'accent': '#ec4899',
          'background': '#fafafa',
        };
      case 'minimal':
        return {
          'primary': '#000000',
          'accent': '#666666',
          'background': '#ffffff',
        };
      case 'business':
        return {
          'primary': '#0f172a',
          'accent': '#0ea5e9',
          'background': '#f8fafc',
        };
      default:
        return {
          'primary': '#3b82f6',
          'accent': '#60a5fa',
          'background': '#f9fafb',
        };
    }
  }

  /// Generate preview sizes (for thumbnail generation)
  static Future<Uint8List> buildPreviewPdf(
    String templateType,
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo, {
    bool isThumb = false,
  }) async {
    try {
      final pdf = pw.Document();

      pdf.addPage(
        InvoicePdfTemplateFactory.buildPage(
          templateType,
          invoice,
          businessInfo,
        ),
      );

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to build preview PDF: $e');
    }
  }

  /// Generate compare PDF (side-by-side templates)
  static Future<Uint8List> buildComparisonPdf(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo,
    List<String> templateTypesToCompare, {
    Map<String, dynamic>? customization,
  }) async {
    try {
      final pdf = pw.Document();

      // Add comparison title page
      pdf.addPage(
        pw.Page(
          build: (context) => pw.Column(
            children: [
              pw.Text(
                'Invoice Template Comparison',
                style: pw.TextStyle(fontSize: 24, fontWeight: pw.FontWeight.bold),
              ),
              pw.SizedBox(height: 20),
              pw.Text(
                'Invoice #: ${invoice.invoiceNumber ?? invoice.id}',
                style: pw.TextStyle(fontSize: 14),
              ),
              pw.SizedBox(height: 10),
              pw.Text(
                'Templates: ${templateTypesToCompare.map((t) => getTemplateDisplayName(t)).join(", ")}',
                style: pw.TextStyle(fontSize: 12),
              ),
            ],
          ),
        ),
      );

      // Add each template
      for (final templateType in templateTypesToCompare) {
        if (isValidTemplate(templateType)) {
          pdf.addPage(
            InvoicePdfTemplateFactory.buildPage(
              templateType,
              invoice,
              businessInfo,
              customization: customization,
            ),
          );
        }
      }

      return await pdf.save();
    } catch (e) {
      throw Exception('Failed to build comparison PDF: $e');
    }
  }

  /// Get template descriptions
  static String getTemplateDescription(String templateType) {
    switch (templateType.toLowerCase()) {
      case 'modern':
        return 'Minimal, sleek, light theme with contemporary design elements';
      case 'classic':
        return 'Traditional business layout with timeless appeal';
      case 'dark':
        return 'Luxury dark theme invoice with premium feel';
      case 'gradient':
        return 'Stylish colorful gradient header with modern aesthetic';
      case 'minimal':
        return 'Stripped down design focusing on content and clarity';
      case 'business':
        return 'Corporate design perfect for enterprise invoicing';
      default:
        return 'Professional invoice template';
    }
  }

  /// Build and return all templates with full metadata
  static Future<List<Map<String, dynamic>>> buildAllTemplatesWithDetails(
    InvoiceModel invoice,
    Map<String, dynamic>? businessInfo, {
    Map<String, dynamic>? customization,
  }) async {
    try {
      final result = <Map<String, dynamic>>[];

      for (final templateType in getAvailableTemplates()) {
        final metadata = await buildPdfWithMetadata(
          templateType,
          invoice,
          businessInfo,
          customization: customization,
        );

        result.add({
          ...metadata,
          'description': getTemplateDescription(templateType),
          'colors': getTemplateColors(templateType),
        });
      }

      return result;
    } catch (e) {
      throw Exception('Failed to build all templates with details: $e');
    }
  }
}
