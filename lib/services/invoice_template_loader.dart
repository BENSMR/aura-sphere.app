import 'package:cloud_firestore/cloud_firestore.dart';
import '../data/models/invoice_template_model.dart';
import '../data/repositories/invoice_templates.dart';

class InvoiceTemplateLoader {
  static final _db = FirebaseFirestore.instance;

  /// Load invoice template from user data
  /// Returns template ID, defaults to 'modern' if not found
  static String loadTemplateId(Map<String, dynamic>? userData) {
    return userData?['invoiceTemplate'] as String? ?? 'modern';
  }

  /// Load full template model from user data
  static InvoiceTemplateModel? loadTemplate(Map<String, dynamic>? userData) {
    final templateId = loadTemplateId(userData);
    return InvoiceTemplates.getById(templateId);
  }

  /// Load template from Firestore by user ID
  static Future<String> loadUserTemplateId(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return loadTemplateId(doc.data());
    } catch (e) {
      return 'modern'; // Default fallback
    }
  }

  /// Load full template model from Firestore
  static Future<InvoiceTemplateModel?> loadUserTemplate(String userId) async {
    try {
      final templateId = await loadUserTemplateId(userId);
      return InvoiceTemplates.getById(templateId);
    } catch (e) {
      return InvoiceTemplates.getById('modern');
    }
  }

  /// Load template with customization from Firestore
  static Future<Map<String, dynamic>> loadTemplateWithCustomization(
    String userId,
  ) async {
    try {
      final userDoc = await _db.collection('users').doc(userId).get();
      final templateId = loadTemplateId(userDoc.data());
      final template = InvoiceTemplates.getById(templateId);

      // Try to load customization if available
      Map<String, dynamic>? customization;
      try {
        final customDoc = await _db
            .collection('users')
            .doc(userId)
            .collection('templateCustomizations')
            .doc(templateId)
            .get();
        if (customDoc.exists) {
          customization =
              customDoc.data()?['customization'] as Map<String, dynamic>?;
        }
      } catch (e) {
        // Customization load failed, use defaults
      }

      return {
        'template': template,
        'templateId': templateId,
        'customization': customization ?? template?.customization ?? {},
      };
    } catch (e) {
      // Return defaults on error
      final defaultTemplate = InvoiceTemplates.getById('modern');
      return {
        'template': defaultTemplate,
        'templateId': 'modern',
        'customization': defaultTemplate?.customization ?? {},
      };
    }
  }

  /// Load all template-related user preferences
  static Future<Map<String, dynamic>> loadAllTemplatePreferences(
    String userId,
  ) async {
    try {
      // Get user document
      final userDoc = await _db.collection('users').doc(userId).get();
      final templateId = loadTemplateId(userDoc.data());
      final template = InvoiceTemplates.getById(templateId);

      // Get customization
      Map<String, dynamic> customization = {};
      try {
        final customDoc = await _db
            .collection('users')
            .doc(userId)
            .collection('templateCustomizations')
            .doc(templateId)
            .get();
        if (customDoc.exists) {
          customization =
              customDoc.data()?['customization'] as Map<String, dynamic>? ?? {};
        }
      } catch (e) {
        // Silent fail
      }

      // Get favorites
      List<InvoiceTemplateModel> favorites = [];
      try {
        final favSnap = await _db
            .collection('users')
            .doc(userId)
            .collection('favoriteTemplates')
            .get();
        for (final doc in favSnap.docs) {
          final id = doc.data()['templateId'] as String?;
          if (id != null) {
            final fav = InvoiceTemplates.getById(id);
            if (fav != null) {
              favorites.add(fav);
            }
          }
        }
      } catch (e) {
        // Silent fail
      }

      // Get recent templates
      List<String> recentIds =
          List<String>.from(userDoc.data()?['recentTemplates'] ?? []);
      List<InvoiceTemplateModel> recent = [];
      for (final id in recentIds) {
        final t = InvoiceTemplates.getById(id);
        if (t != null) {
          recent.add(t);
        }
      }

      return {
        'selectedTemplateId': templateId,
        'selectedTemplate': template,
        'customization': customization,
        'favoriteTemplates': favorites,
        'recentTemplates': recent,
        'recentTemplateIds': recentIds,
      };
    } catch (e) {
      // Return minimal defaults on error
      final defaultTemplate = InvoiceTemplates.getById('modern');
      return {
        'selectedTemplateId': 'modern',
        'selectedTemplate': defaultTemplate,
        'customization': defaultTemplate?.customization ?? {},
        'favoriteTemplates': [],
        'recentTemplates': [],
        'recentTemplateIds': [],
      };
    }
  }

  /// Batch load templates for multiple users
  static Future<Map<String, String>> batchLoadUserTemplates(
    List<String> userIds,
  ) async {
    try {
      final results = <String, String>{};
      for (final userId in userIds) {
        results[userId] = await loadUserTemplateId(userId);
      }
      return results;
    } catch (e) {
      throw Exception('Failed to batch load templates: $e');
    }
  }

  /// Initialize template for new user
  static Future<void> initializeUserTemplate(
    String userId, {
    String templateId = 'modern',
  }) async {
    try {
      // Validate template exists
      final template = InvoiceTemplates.getById(templateId);
      if (template == null) {
        throw Exception('Template not found: $templateId');
      }

      // Set in user document
      await _db.collection('users').doc(userId).set({
        'invoiceTemplate': templateId,
        'invoiceTemplateInitializedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } catch (e) {
      throw Exception('Failed to initialize user template: $e');
    }
  }

  /// Check if user has template set
  static Future<bool> hasTemplateSet(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      return doc.data()?.containsKey('invoiceTemplate') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get template initialization status
  static Future<Map<String, dynamic>> getTemplateStatus(String userId) async {
    try {
      final doc = await _db.collection('users').doc(userId).get();
      final data = doc.data();
      final hasTemplate = data?.containsKey('invoiceTemplate') ?? false;
      final templateId = data?['invoiceTemplate'] as String?;
      final initializedAt = data?['invoiceTemplateInitializedAt'] as Timestamp?;

      return {
        'initialized': hasTemplate,
        'templateId': templateId ?? 'modern',
        'initializedAt': initializedAt?.toDate(),
        'isValid': InvoiceTemplates.getById(templateId ?? 'modern') != null,
      };
    } catch (e) {
      return {
        'initialized': false,
        'templateId': 'modern',
        'initializedAt': null,
        'isValid': true,
      };
    }
  }

  /// Validate template is available
  static bool isTemplateValid(String templateId) {
    return InvoiceTemplates.getById(templateId) != null;
  }

  /// Get list of all available template IDs
  static List<String> getAvailableTemplateIds() {
    return InvoiceTemplates.available.map((t) => t.id).toList();
  }

  /// Migrate template if invalid
  static Future<String> migrateInvalidTemplate(
    String userId,
    String currentTemplateId,
  ) async {
    if (isTemplateValid(currentTemplateId)) {
      return currentTemplateId; // Already valid
    }

    // Find alternative template
    final alternative = InvoiceTemplates.available.firstOrNull;
    if (alternative != null) {
      // Update to valid template
      await _db.collection('users').doc(userId).update({
        'invoiceTemplate': alternative.id,
        'templateMigratedAt': FieldValue.serverTimestamp(),
        'previousTemplate': currentTemplateId,
      });
      return alternative.id;
    }

    // Fallback to modern
    return 'modern';
  }

  /// Stream user's current template
  static Stream<String> watchUserTemplateId(String userId) {
    return _db.collection('users').doc(userId).snapshots().map((snap) {
      return snap.data()?['invoiceTemplate'] as String? ?? 'modern';
    });
  }

  /// Stream user's template model
  static Stream<InvoiceTemplateModel?> watchUserTemplate(String userId) {
    return watchUserTemplateId(userId).map((templateId) {
      return InvoiceTemplates.getById(templateId);
    });
  }

  /// Get template default customization
  static Map<String, dynamic> getTemplateDefaults(String templateId) {
    final template = InvoiceTemplates.getById(templateId);
    return template?.customization ?? {};
  }

  /// Merge customization with template defaults
  static Map<String, dynamic> mergeCustomization(
    String templateId,
    Map<String, dynamic>? custom,
  ) {
    final defaults = getTemplateDefaults(templateId);
    return {...defaults, ...?custom};
  }
}
