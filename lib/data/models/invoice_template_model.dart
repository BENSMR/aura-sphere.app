import 'package:cloud_firestore/cloud_firestore.dart';

class InvoiceTemplateModel {
  final String id;
  final String name;
  final String description;
  final String previewImage; // asset or network image URL
  final String templateType; // modern, classic, minimal, dark, elegant, business
  final bool isActive;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final Map<String, dynamic>? customization; // Font, colors, layout options
  final int? usageCount; // Track how many times template is used
  final bool isPremium; // For future monetization
  final String? category; // Invoice, Estimate, Receipt, etc.
  final List<String>? tags; // For filtering and search

  InvoiceTemplateModel({
    required this.id,
    required this.name,
    required this.description,
    required this.previewImage,
    required this.templateType,
    this.isActive = true,
    DateTime? createdAt,
    this.updatedAt,
    this.customization,
    this.usageCount = 0,
    this.isPremium = false,
    this.category,
    this.tags,
  }) : createdAt = createdAt ?? DateTime.now();

  /// Convert to JSON for Firestore
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'previewImage': previewImage,
      'templateType': templateType,
      'isActive': isActive,
      'createdAt': Timestamp.fromDate(createdAt),
      'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
      'customization': customization,
      'usageCount': usageCount ?? 0,
      'isPremium': isPremium,
      'category': category,
      'tags': tags ?? [],
    };
  }

  /// Create from Firestore JSON
  factory InvoiceTemplateModel.fromJson(Map<String, dynamic> json) {
    return InvoiceTemplateModel(
      id: json['id'] as String? ?? '',
      name: json['name'] as String? ?? 'Untitled Template',
      description: json['description'] as String? ?? '',
      previewImage: json['previewImage'] as String? ?? '',
      templateType: json['templateType'] as String? ?? 'classic',
      isActive: json['isActive'] as bool? ?? true,
      createdAt: json['createdAt'] != null
          ? (json['createdAt'] as Timestamp).toDate()
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? (json['updatedAt'] as Timestamp).toDate()
          : null,
      customization: json['customization'] as Map<String, dynamic>?,
      usageCount: json['usageCount'] as int? ?? 0,
      isPremium: json['isPremium'] as bool? ?? false,
      category: json['category'] as String?,
      tags: List<String>.from(json['tags'] as List? ?? []),
    );
  }

  /// Create from Firestore DocumentSnapshot
  factory InvoiceTemplateModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InvoiceTemplateModel.fromJson({
      ...data,
      'id': doc.id,
    });
  }

  /// Copy with updated fields
  InvoiceTemplateModel copyWith({
    String? id,
    String? name,
    String? description,
    String? previewImage,
    String? templateType,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    Map<String, dynamic>? customization,
    int? usageCount,
    bool? isPremium,
    String? category,
    List<String>? tags,
  }) {
    return InvoiceTemplateModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      previewImage: previewImage ?? this.previewImage,
      templateType: templateType ?? this.templateType,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      customization: customization ?? this.customization,
      usageCount: usageCount ?? this.usageCount,
      isPremium: isPremium ?? this.isPremium,
      category: category ?? this.category,
      tags: tags ?? this.tags,
    );
  }

  @override
  String toString() => 'InvoiceTemplateModel(id: $id, name: $name, type: $templateType)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoiceTemplateModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          name == other.name &&
          templateType == other.templateType;

  @override
  int get hashCode => id.hashCode ^ name.hashCode ^ templateType.hashCode;
}

/// Template type constants
class TemplateTypes {
  static const String CLASSIC = 'classic';
  static const String MODERN = 'modern';
  static const String MINIMAL = 'minimal';
  static const String DARK = 'dark';
  static const String ELEGANT = 'elegant';
  static const String BUSINESS = 'business';
  static const String COLORFUL = 'colorful';
  static const String PROFESSIONAL = 'professional';

  static const List<String> all = [
    CLASSIC,
    MODERN,
    MINIMAL,
    DARK,
    ELEGANT,
    BUSINESS,
    COLORFUL,
    PROFESSIONAL,
  ];

  static String getDisplayName(String type) {
    switch (type) {
      case CLASSIC:
        return 'Classic';
      case MODERN:
        return 'Modern';
      case MINIMAL:
        return 'Minimal';
      case DARK:
        return 'Dark';
      case ELEGANT:
        return 'Elegant';
      case BUSINESS:
        return 'Business';
      case COLORFUL:
        return 'Colorful';
      case PROFESSIONAL:
        return 'Professional';
      default:
        return 'Classic';
    }
  }
}

/// Default invoice templates
class DefaultInvoiceTemplates {
  static List<InvoiceTemplateModel> getDefaults() {
    return [
      InvoiceTemplateModel(
        id: 'template_classic_001',
        name: 'Professional Classic',
        description: 'Clean and professional design with traditional layout',
        previewImage: 'assets/templates/classic_preview.png',
        templateType: TemplateTypes.CLASSIC,
        category: 'Invoice',
        tags: ['professional', 'clean', 'traditional'],
        customization: {
          'primaryColor': '#1e40af',
          'font': 'Helvetica',
          'layout': 'traditional',
          'headerStyle': 'simple',
        },
      ),
      InvoiceTemplateModel(
        id: 'template_modern_001',
        name: 'Modern Minimal',
        description: 'Contemporary design with minimal elements and clean typography',
        previewImage: 'assets/templates/modern_preview.png',
        templateType: TemplateTypes.MODERN,
        category: 'Invoice',
        tags: ['modern', 'minimal', 'contemporary'],
        customization: {
          'primaryColor': '#3b82f6',
          'font': 'Open Sans',
          'layout': 'modern',
          'headerStyle': 'gradient',
        },
      ),
      InvoiceTemplateModel(
        id: 'template_minimal_001',
        name: 'Ultra Minimal',
        description: 'Stripped down design focusing on content and essential information',
        previewImage: 'assets/templates/minimal_preview.png',
        templateType: TemplateTypes.MINIMAL,
        category: 'Invoice',
        tags: ['minimal', 'simple', 'content-focused'],
        customization: {
          'primaryColor': '#000000',
          'font': 'Inter',
          'layout': 'minimal',
          'headerStyle': 'text-only',
        },
      ),
      InvoiceTemplateModel(
        id: 'template_elegant_001',
        name: 'Elegant Pro',
        description: 'Sophisticated design with elegant typography and refined styling',
        previewImage: 'assets/templates/elegant_preview.png',
        templateType: TemplateTypes.ELEGANT,
        category: 'Invoice',
        tags: ['elegant', 'sophisticated', 'premium'],
        customization: {
          'primaryColor': '#8b5cf6',
          'font': 'Georgia',
          'layout': 'elegant',
          'headerStyle': 'ornate',
        },
      ),
      InvoiceTemplateModel(
        id: 'template_business_001',
        name: 'Business Standard',
        description: 'Corporate design perfect for business invoicing',
        previewImage: 'assets/templates/business_preview.png',
        templateType: TemplateTypes.BUSINESS,
        category: 'Invoice',
        tags: ['business', 'corporate', 'professional'],
        customization: {
          'primaryColor': '#0f172a',
          'font': 'Roboto',
          'layout': 'business',
          'headerStyle': 'corporate',
        },
      ),
      InvoiceTemplateModel(
        id: 'template_dark_001',
        name: 'Dark Mode',
        description: 'Modern dark theme suitable for digital and print',
        previewImage: 'assets/templates/dark_preview.png',
        templateType: TemplateTypes.DARK,
        category: 'Invoice',
        tags: ['dark', 'modern', 'digital'],
        customization: {
          'primaryColor': '#1e1e1e',
          'accentColor': '#00d9ff',
          'font': 'Courier New',
          'layout': 'dark',
          'headerStyle': 'neon',
        },
      ),
    ];
  }

  /// Get template by type
  static InvoiceTemplateModel? getByType(String templateType) {
    try {
      return getDefaults().firstWhere((t) => t.templateType == templateType);
    } catch (e) {
      return null;
    }
  }

  /// Get all templates of a specific category
  static List<InvoiceTemplateModel> getByCategory(String category) {
    return getDefaults().where((t) => t.category == category).toList();
  }
}
