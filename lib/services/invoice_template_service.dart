import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/invoice_template_model.dart';
import '../data/repositories/invoice_templates.dart';

class InvoiceTemplateService {
  static final _db = FirebaseFirestore.instance;

  /// Set invoice template for user
  /// Updates both Firestore and local cache
  static Future<void> setInvoiceTemplate(
    String userId,
    String templateId, {
    bool incrementUsage = true,
  }) async {
    try {
      // Validate template exists
      final template = InvoiceTemplates.getById(templateId);
      if (template == null) {
        throw Exception('Template not found: $templateId');
      }

      // Track usage if specified
      if (incrementUsage) {
        InvoiceTemplates.incrementUsage(templateId);
      }

      // Update Firestore
      await _db.collection('users').doc(userId).update({
        'invoiceTemplate': templateId,
        'invoiceTemplateUpdatedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to set invoice template: $e');
    }
  }

  /// Set template by type instead of ID
  static Future<void> setInvoiceTemplateByType(
    String userId,
    String templateType, {
    bool incrementUsage = true,
  }) async {
    try {
      final template = InvoiceTemplates.getByType(templateType);
      if (template == null) {
        throw Exception('Template type not found: $templateType');
      }

      await setInvoiceTemplate(
        userId,
        template.id,
        incrementUsage: incrementUsage,
      );
    } catch (e) {
      throw Exception('Failed to set invoice template by type: $e');
    }
  }

  /// Get current user's selected template
  static Future<InvoiceTemplateModel?> getUserTemplate(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final data = doc.data();
      final templateId = data?['invoiceTemplate'] as String?;

      if (templateId == null) {
        return InvoiceTemplates.getById('modern'); // Default
      }

      return InvoiceTemplates.getById(templateId);
    } catch (e) {
      throw Exception('Failed to get user template: $e');
    }
  }

  /// Get user's template ID
  static Future<String> getUserTemplateId(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final templateId = doc.data()?['invoiceTemplate'] as String?;
      return templateId ?? 'modern';
    } catch (e) {
      throw Exception('Failed to get user template ID: $e');
    }
  }

  /// Save template customization for user
  static Future<void> saveTemplateCustomization(
    String userId,
    String templateId,
    Map<String, dynamic> customization,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('templateCustomizations')
          .doc(templateId)
          .set({
        'templateId': templateId,
        'customization': customization,
        'savedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to save template customization: $e');
    }
  }

  /// Get template customization for user
  static Future<Map<String, dynamic>?> getTemplateCustomization(
    String userId,
    String templateId,
  ) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('templateCustomizations')
          .doc(templateId)
          .get();

      if (doc.exists) {
        return doc.data()?['customization'] as Map<String, dynamic>?;
      }
      return null;
    } catch (e) {
      throw Exception('Failed to get template customization: $e');
    }
  }

  /// Get all template customizations for user
  static Future<Map<String, Map<String, dynamic>>> getAllCustomizations(
    String userId,
  ) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('templateCustomizations')
          .get();

      final customizations = <String, Map<String, dynamic>>{};
      for (final doc in snap.docs) {
        final templateId = doc.data()['templateId'] as String?;
        final customization =
            doc.data()['customization'] as Map<String, dynamic>?;
        if (templateId != null && customization != null) {
          customizations[templateId] = customization;
        }
      }
      return customizations;
    } catch (e) {
      throw Exception('Failed to get all customizations: $e');
    }
  }

  /// Delete template customization
  static Future<void> deleteTemplateCustomization(
    String userId,
    String templateId,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('templateCustomizations')
          .doc(templateId)
          .delete();
    } catch (e) {
      throw Exception('Failed to delete template customization: $e');
    }
  }

  /// Add template to user's favorites
  static Future<void> addToFavorites(
    String userId,
    String templateId,
  ) async {
    try {
      final template = InvoiceTemplates.getById(templateId);
      if (template == null) {
        throw Exception('Template not found: $templateId');
      }

      await _db
          .collection('users')
          .doc(userId)
          .collection('favoriteTemplates')
          .doc(templateId)
          .set({
        'templateId': templateId,
        'templateName': template.name,
        'templateType': template.templateType,
        'addedAt': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      throw Exception('Failed to add to favorites: $e');
    }
  }

  /// Remove template from user's favorites
  static Future<void> removeFromFavorites(
    String userId,
    String templateId,
  ) async {
    try {
      await _db
          .collection('users')
          .doc(userId)
          .collection('favoriteTemplates')
          .doc(templateId)
          .delete();
    } catch (e) {
      throw Exception('Failed to remove from favorites: $e');
    }
  }

  /// Get user's favorite templates
  static Future<List<InvoiceTemplateModel>> getFavoriteTemplates(
    String userId,
  ) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('favoriteTemplates')
          .get();

      final favorites = <InvoiceTemplateModel>[];
      for (final doc in snap.docs) {
        final templateId = doc.data()['templateId'] as String?;
        if (templateId != null) {
          final template = InvoiceTemplates.getById(templateId);
          if (template != null) {
            favorites.add(template);
          }
        }
      }
      return favorites;
    } catch (e) {
      throw Exception('Failed to get favorite templates: $e');
    }
  }

  /// Check if template is favorite
  static Future<bool> isFavorite(String userId, String templateId) async {
    try {
      final doc = await _db
          .collection('users')
          .doc(userId)
          .collection('favoriteTemplates')
          .doc(templateId)
          .get();
      return doc.exists;
    } catch (e) {
      return false;
    }
  }

  /// Get user's recently used templates
  static Future<List<InvoiceTemplateModel>> getRecentTemplates(
    String userId, {
    int limit = 5,
  }) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final recentIds = List<String>.from(
        doc.data()?['recentTemplates'] ?? [],
      );

      final recent = <InvoiceTemplateModel>[];
      for (final id in recentIds.take(limit)) {
        final template = InvoiceTemplates.getById(id);
        if (template != null) {
          recent.add(template);
        }
      }
      return recent;
    } catch (e) {
      throw Exception('Failed to get recent templates: $e');
    }
  }

  /// Add template to recent list
  static Future<void> addToRecentTemplates(
    String userId,
    String templateId, {
    int maxRecent = 5,
  }) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final recentList =
          List<String>.from(doc.data()?['recentTemplates'] ?? []);

      // Remove if already in list
      recentList.removeWhere((id) => id == templateId);

      // Add to front
      recentList.insert(0, templateId);

      // Keep only max items
      if (recentList.length > maxRecent) {
        recentList.removeRange(maxRecent, recentList.length);
      }

      await _db.collection('users').doc(userId).update({
        'recentTemplates': recentList,
      });
    } catch (e) {
      // Silent fail for tracking
    }
  }

  /// Get template usage statistics for user
  static Future<Map<String, int>> getTemplateUsageStats(
    String userId,
  ) async {
    try {
      final snap = await _db
          .collection('users')
          .doc(userId)
          .collection('invoices')
          .get();

      final stats = <String, int>{};
      for (final doc in snap.docs) {
        final templateId = doc.data()['invoiceTemplate'] as String?;
        if (templateId != null) {
          stats[templateId] = (stats[templateId] ?? 0) + 1;
        }
      }
      return stats;
    } catch (e) {
      throw Exception('Failed to get template usage stats: $e');
    }
  }

  /// Get most used template by user
  static Future<InvoiceTemplateModel?> getMostUsedTemplate(
    String userId,
  ) async {
    try {
      final stats = await getTemplateUsageStats(userId);
      if (stats.isEmpty) return null;

      final mostUsedId =
          stats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
      return InvoiceTemplates.getById(mostUsedId);
    } catch (e) {
      return null;
    }
  }

  /// Export user template preferences
  static Future<Map<String, dynamic>> exportTemplatePreferences(
    String userId,
  ) async {
    try {
      final currentTemplate = await getUserTemplate(userId);
      final favorites = await getFavoriteTemplates(userId);
      final recent = await getRecentTemplates(userId);
      final customizations = await getAllCustomizations(userId);
      final stats = await getTemplateUsageStats(userId);

      return {
        'userId': userId,
        'currentTemplate': currentTemplate?.id,
        'favoriteTemplates': favorites.map((t) => t.id).toList(),
        'recentTemplates': recent.map((t) => t.id).toList(),
        'customizations': customizations,
        'usageStats': stats,
        'exportedAt': DateTime.now().toIso8601String(),
      };
    } catch (e) {
      throw Exception('Failed to export template preferences: $e');
    }
  }

  /// Import user template preferences
  static Future<void> importTemplatePreferences(
    String userId,
    Map<String, dynamic> data,
  ) async {
    try {
      // Set current template
      if (data['currentTemplate'] != null) {
        await setInvoiceTemplate(userId, data['currentTemplate']);
      }

      // Import favorites
      if (data['favoriteTemplates'] is List) {
        for (final templateId in data['favoriteTemplates']) {
          await addToFavorites(userId, templateId);
        }
      }

      // Import customizations
      if (data['customizations'] is Map) {
        for (final entry in (data['customizations'] as Map).entries) {
          await saveTemplateCustomization(
            userId,
            entry.key,
            entry.value as Map<String, dynamic>,
          );
        }
      }
    } catch (e) {
      throw Exception('Failed to import template preferences: $e');
    }
  }

  /// Reset user template to default
  static Future<void> resetToDefault(String userId) async {
    try {
      await setInvoiceTemplate(userId, 'modern', incrementUsage: false);
    } catch (e) {
      throw Exception('Failed to reset template: $e');
    }
  }

  /// Get template recommendation based on usage
  static Future<InvoiceTemplateModel?> getRecommendedTemplate(
    String userId,
  ) async {
    try {
      final stats = await getTemplateUsageStats(userId);
      if (stats.isNotEmpty) {
        final mostUsedId =
            stats.entries.reduce((a, b) => a.value > b.value ? a : b).key;
        return InvoiceTemplates.getById(mostUsedId);
      }
      return InvoiceTemplates.getRecommended(limit: 1).firstOrNull;
    } catch (e) {
      return null;
    }
  }
}
