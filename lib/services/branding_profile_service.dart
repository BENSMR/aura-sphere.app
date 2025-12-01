import 'package:cloud_functions/cloud_functions.dart';
import '../models/business_branding.dart';

class BrandingProfileService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Save or update branding profile
  Future<void> saveBrandingProfile(BusinessBranding branding) async {
    try {
      final callable = _functions.httpsCallable('saveBrandingProfile');

      final response = await callable.call({
        'logoUrl': branding.logoUrl,
        'signatureUrl': branding.signatureUrl,
        'primaryColor': branding.primaryColor,
        'accentColor': branding.accentColor,
        'textColor': branding.textColor,
        'footerNote': branding.footerNote,
        'watermarkText': branding.watermarkText,
        'showSignature': branding.showSignature,
        'companyDetails': branding.companyDetails != null
            ? {
                'name': branding.companyDetails!.name,
                'email': branding.companyDetails!.email,
                'phone': branding.companyDetails!.phone,
                'website': branding.companyDetails!.website,
                'address': branding.companyDetails!.address,
              }
            : null,
      });

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to save branding profile');
      }
    } catch (e) {
      print('Error saving branding profile: $e');
      rethrow;
    }
  }

  /// Get current branding profile
  Future<BusinessBranding?> getBrandingProfile() async {
    try {
      final callable = _functions.httpsCallable('getBrandingProfile');
      final response = await callable.call({});

      if (response.data == null) return null;

      final data = response.data as Map<String, dynamic>;
      return BusinessBranding.fromJson(data);
    } catch (e) {
      print('Error fetching branding profile: $e');
      return null;
    }
  }

  /// Delete branding profile (revert to defaults)
  Future<void> deleteBrandingProfile() async {
    try {
      final callable = _functions.httpsCallable('deleteBrandingProfile');
      final response = await callable.call({});

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception(data['message'] ?? 'Failed to delete branding profile');
      }
    } catch (e) {
      print('Error deleting branding profile: $e');
      rethrow;
    }
  }

  /// Get default branding profile
  Future<BusinessBranding> getDefaultBrandingProfile() async {
    try {
      final callable =
          _functions.httpsCallable('getDefaultBrandingProfile');
      final response = await callable.call({});

      final data = response.data as Map<String, dynamic>;
      return BusinessBranding.fromJson(data);
    } catch (e) {
      print('Error fetching default branding: $e');
      // Return a hardcoded default if Cloud Function fails
      return BusinessBranding(
        primaryColor: '#1976D2',
        accentColor: '#FFC107',
        textColor: '#000000',
        showSignature: false,
        companyDetails: const CompanyDetails(name: 'Your Company'),
      );
    }
  }

  /// Create branding profile from template
  Future<BusinessBranding> createBrandingFromTemplate({
    required String templateId,
    required String companyName,
  }) async {
    try {
      final callable =
          _functions.httpsCallable('createBrandingFromTemplate');

      final response = await callable.call({
        'template': templateId,
        'companyName': companyName,
      });

      final data = response.data as Map<String, dynamic>;
      if (data['success'] != true) {
        throw Exception('Failed to create branding from template');
      }

      final branding = data['branding'] as Map<String, dynamic>;
      return BusinessBranding.fromJson(branding);
    } catch (e) {
      print('Error creating branding from template: $e');
      rethrow;
    }
  }

  /// Get available branding templates
  Future<List<BrandingTemplate>> listBrandingTemplates() async {
    try {
      final callable = _functions.httpsCallable('listBrandingTemplates');
      final response = await callable.call({});

      final templates = response.data as List;
      return templates
          .map((t) => BrandingTemplate.fromJson(t as Map<String, dynamic>))
          .toList();
    } catch (e) {
      print('Error fetching branding templates: $e');
      return _getDefaultTemplates();
    }
  }

  /// Fallback templates if Cloud Function fails
  List<BrandingTemplate> _getDefaultTemplates() {
    return [
      BrandingTemplate(
        id: 'professional',
        name: 'Professional',
        description: 'Classic blue and white professional design',
        primaryColor: '#1976D2',
        accentColor: '#1565C0',
      ),
      BrandingTemplate(
        id: 'modern',
        name: 'Modern',
        description: 'Contemporary tech-forward colors',
        primaryColor: '#0A84FF',
        accentColor: '#00FFC8',
      ),
      BrandingTemplate(
        id: 'minimal',
        name: 'Minimal',
        description: 'Clean and simple monochrome',
        primaryColor: '#000000',
        accentColor: '#666666',
      ),
      BrandingTemplate(
        id: 'vibrant',
        name: 'Vibrant',
        description: 'Bold and energetic colors',
        primaryColor: '#FF6B35',
        accentColor: '#F7931E',
      ),
      BrandingTemplate(
        id: 'elegant',
        name: 'Elegant',
        description: 'Sophisticated purple tones',
        primaryColor: '#6A4C93',
        accentColor: '#C5A3FF',
      ),
    ];
  }
}

/// Model for branding templates
class BrandingTemplate {
  final String id;
  final String name;
  final String description;
  final String primaryColor;
  final String accentColor;

  BrandingTemplate({
    required this.id,
    required this.name,
    required this.description,
    required this.primaryColor,
    required this.accentColor,
  });

  factory BrandingTemplate.fromJson(Map<String, dynamic> json) {
    return BrandingTemplate(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      primaryColor: json['primaryColor'] as String,
      accentColor: json['accentColor'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'description': description,
        'primaryColor': primaryColor,
        'accentColor': accentColor,
      };
}
