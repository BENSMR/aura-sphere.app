import '../../data/models/invoice_template_model.dart';

class InvoiceTemplates {
  /// Predefined invoice templates
  static final List<InvoiceTemplateModel> available = [
    InvoiceTemplateModel(
      id: "modern",
      name: "Modern Clean",
      description: "Minimal, sleek, light theme with contemporary design elements",
      previewImage: "assets/invoices/modern_preview.png",
      templateType: "modern",
      category: "Invoice",
      tags: ['modern', 'minimal', 'clean', 'light'],
      customization: {
        'primaryColor': '#3b82f6',
        'accentColor': '#60a5fa',
        'backgroundColor': '#f9fafb',
        'textColor': '#1f2937',
        'font': 'Open Sans',
        'headerStyle': 'gradient_light',
      },
    ),
    InvoiceTemplateModel(
      id: "classic",
      name: "Classic Professional",
      description: "Traditional business layout with timeless appeal",
      previewImage: "assets/invoices/classic_preview.png",
      templateType: "classic",
      category: "Invoice",
      tags: ['classic', 'professional', 'traditional', 'business'],
      customization: {
        'primaryColor': '#1e40af',
        'accentColor': '#1e3a8a',
        'backgroundColor': '#ffffff',
        'textColor': '#111827',
        'font': 'Helvetica',
        'headerStyle': 'simple',
      },
    ),
    InvoiceTemplateModel(
      id: "dark",
      name: "Dark Elegant",
      description: "Luxury dark theme invoice with premium feel",
      previewImage: "assets/invoices/dark_preview.png",
      templateType: "dark",
      category: "Invoice",
      tags: ['dark', 'elegant', 'luxury', 'premium'],
      customization: {
        'primaryColor': '#1e1e1e',
        'accentColor': '#fbbf24',
        'backgroundColor': '#0f0f0f',
        'textColor': '#f3f4f6',
        'font': 'Georgia',
        'headerStyle': 'dark_accent',
      },
      isPremium: true,
    ),
    InvoiceTemplateModel(
      id: "gradient",
      name: "Gradient Neo",
      description: "Stylish colorful gradient header with modern aesthetic",
      previewImage: "assets/invoices/gradient_preview.png",
      templateType: "gradient",
      category: "Invoice",
      tags: ['gradient', 'colorful', 'modern', 'vibrant'],
      customization: {
        'primaryColor': '#8b5cf6',
        'accentColor': '#ec4899',
        'gradientStart': '#8b5cf6',
        'gradientEnd': '#ec4899',
        'backgroundColor': '#fafafa',
        'textColor': '#1f2937',
        'font': 'Inter',
        'headerStyle': 'gradient_vibrant',
      },
      isPremium: true,
    ),
    InvoiceTemplateModel(
      id: "minimal",
      name: "Ultra Minimal",
      description: "Stripped down design focusing on content and clarity",
      previewImage: "assets/invoices/minimal_preview.png",
      templateType: "minimal",
      category: "Invoice",
      tags: ['minimal', 'simple', 'content-focused', 'clean'],
      customization: {
        'primaryColor': '#000000',
        'accentColor': '#666666',
        'backgroundColor': '#ffffff',
        'textColor': '#111827',
        'font': 'Inter',
        'headerStyle': 'text_only',
      },
    ),
    InvoiceTemplateModel(
      id: "business",
      name: "Business Standard",
      description: "Corporate design perfect for enterprise invoicing",
      previewImage: "assets/invoices/business_preview.png",
      templateType: "business",
      category: "Invoice",
      tags: ['business', 'corporate', 'professional', 'enterprise'],
      customization: {
        'primaryColor': '#0f172a',
        'accentColor': '#0ea5e9',
        'backgroundColor': '#f8fafc',
        'textColor': '#0f172a',
        'font': 'Roboto',
        'headerStyle': 'corporate',
      },
    ),
  ];

  /// Get template by ID
  static InvoiceTemplateModel? getById(String id) {
    try {
      return available.firstWhere((template) => template.id == id);
    } catch (e) {
      return null;
    }
  }

  /// Get template by type
  static InvoiceTemplateModel? getByType(String templateType) {
    try {
      return available.firstWhere((template) => template.templateType == templateType);
    } catch (e) {
      return null;
    }
  }

  /// Get all templates of specific category
  static List<InvoiceTemplateModel> getByCategory(String category) {
    return available.where((template) => template.category == category).toList();
  }

  /// Get all templates with specific tag
  static List<InvoiceTemplateModel> getByTag(String tag) {
    return available
        .where((template) => template.tags?.contains(tag) ?? false)
        .toList();
  }

  /// Get all non-premium templates
  static List<InvoiceTemplateModel> getFree() {
    return available.where((template) => !template.isPremium).toList();
  }

  /// Get all premium templates
  static List<InvoiceTemplateModel> getPremium() {
    return available.where((template) => template.isPremium).toList();
  }

  /// Get all active templates
  static List<InvoiceTemplateModel> getActive() {
    return available.where((template) => template.isActive).toList();
  }

  /// Search templates by name or description
  static List<InvoiceTemplateModel> search(String query) {
    final lowerQuery = query.toLowerCase();
    return available.where((template) {
      return template.name.toLowerCase().contains(lowerQuery) ||
          template.description.toLowerCase().contains(lowerQuery);
    }).toList();
  }

  /// Get all unique tags from all templates
  static List<String> getAllTags() {
    final tags = <String>{};
    for (final template in available) {
      tags.addAll(template.tags ?? []);
    }
    return tags.toList()..sort();
  }

  /// Get all unique template types
  static List<String> getAllTypes() {
    final types = <String>{};
    for (final template in available) {
      types.add(template.templateType);
    }
    return types.toList()..sort();
  }

  /// Get all unique categories
  static List<String> getAllCategories() {
    final categories = <String>{};
    for (final template in available) {
      if (template.category != null) {
        categories.add(template.category!);
      }
    }
    return categories.toList()..sort();
  }

  /// Get template with most common usage
  static InvoiceTemplateModel? getMostPopular() {
    if (available.isEmpty) return null;
    return available.reduce((a, b) => (a.usageCount ?? 0) > (b.usageCount ?? 0) ? a : b);
  }

  /// Filter templates with advanced criteria
  static List<InvoiceTemplateModel> filter({
    bool? premiumOnly,
    bool? activeOnly,
    String? category,
    String? templateType,
    List<String>? tags,
  }) {
    var results = List<InvoiceTemplateModel>.from(available);

    if (premiumOnly == true) {
      results = results.where((t) => t.isPremium).toList();
    }

    if (activeOnly == true) {
      results = results.where((t) => t.isActive).toList();
    }

    if (category != null) {
      results = results.where((t) => t.category == category).toList();
    }

    if (templateType != null) {
      results = results.where((t) => t.templateType == templateType).toList();
    }

    if (tags != null && tags.isNotEmpty) {
      results = results.where((t) {
        final templateTags = t.tags ?? [];
        return tags.any((tag) => templateTags.contains(tag));
      }).toList();
    }

    return results;
  }

  /// Get recommended templates based on usage
  static List<InvoiceTemplateModel> getRecommended({int limit = 3}) {
    final sorted = List<InvoiceTemplateModel>.from(available);
    sorted.sort((a, b) => (b.usageCount ?? 0).compareTo(a.usageCount ?? 0));
    return sorted.take(limit).toList();
  }

  /// Get template count by status
  static Map<String, int> getStats() {
    return {
      'total': available.length,
      'premium': available.where((t) => t.isPremium).length,
      'free': available.where((t) => !t.isPremium).length,
      'active': available.where((t) => t.isActive).length,
      'categories': getAllCategories().length,
    };
  }

  /// Add new template (for runtime additions)
  static void addTemplate(InvoiceTemplateModel template) {
    // Check for duplicate ID
    if (available.any((t) => t.id == template.id)) {
      throw Exception('Template with ID ${template.id} already exists');
    }
    available.add(template);
  }

  /// Update existing template
  static void updateTemplate(String id, InvoiceTemplateModel template) {
    final index = available.indexWhere((t) => t.id == id);
    if (index == -1) {
      throw Exception('Template with ID $id not found');
    }
    available[index] = template.copyWith(
      id: id,
      updatedAt: DateTime.now(),
    );
  }

  /// Remove template by ID
  static bool removeTemplate(String id) {
    final index = available.indexWhere((t) => t.id == id);
    if (index == -1) return false;
    available.removeAt(index);
    return true;
  }

  /// Clone/duplicate a template with new ID
  static InvoiceTemplateModel? duplicateTemplate(
    String sourceId, {
    required String newId,
    required String newName,
  }) {
    final source = getById(sourceId);
    if (source == null) return null;

    final cloned = source.copyWith(
      id: newId,
      name: newName,
      createdAt: DateTime.now(),
      updatedAt: null,
      usageCount: 0,
    );

    addTemplate(cloned);
    return cloned;
  }

  /// Increment usage count for a template
  static void incrementUsage(String templateId) {
    try {
      final template = getById(templateId);
      if (template != null) {
        updateTemplate(
          templateId,
          template.copyWith(usageCount: (template.usageCount ?? 0) + 1),
        );
      }
    } catch (e) {
      // Silent fail for usage tracking
    }
  }

  /// Export templates to JSON (for backup/sharing)
  static List<Map<String, dynamic>> exportToJson() {
    return available.map((template) => template.toJson()).toList();
  }

  /// Reset to default templates
  static void reset() {
    available.clear();
    available.addAll([
      InvoiceTemplateModel(
        id: "modern",
        name: "Modern Clean",
        description: "Minimal, sleek, light theme with contemporary design elements",
        previewImage: "assets/invoices/modern_preview.png",
        templateType: "modern",
        category: "Invoice",
        tags: ['modern', 'minimal', 'clean', 'light'],
      ),
      InvoiceTemplateModel(
        id: "classic",
        name: "Classic Professional",
        description: "Traditional business layout with timeless appeal",
        previewImage: "assets/invoices/classic_preview.png",
        templateType: "classic",
        category: "Invoice",
        tags: ['classic', 'professional', 'traditional', 'business'],
      ),
      InvoiceTemplateModel(
        id: "dark",
        name: "Dark Elegant",
        description: "Luxury dark theme invoice with premium feel",
        previewImage: "assets/invoices/dark_preview.png",
        templateType: "dark",
        category: "Invoice",
        tags: ['dark', 'elegant', 'luxury', 'premium'],
        isPremium: true,
      ),
      InvoiceTemplateModel(
        id: "gradient",
        name: "Gradient Neo",
        description: "Stylish colorful gradient header with modern aesthetic",
        previewImage: "assets/invoices/gradient_preview.png",
        templateType: "gradient",
        category: "Invoice",
        tags: ['gradient', 'colorful', 'modern', 'vibrant'],
        isPremium: true,
      ),
    ]);
  }
}
