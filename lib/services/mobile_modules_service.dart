import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../utils/logger.dart';

/// Mobile modules configuration
class MobileModules {
  final String userId;
  final bool expenses;
  final bool contacts;
  final bool stock;
  final bool tasks;
  final bool invoices;
  final bool clients;
  final bool crm;
  final bool ai;

  MobileModules({
    required this.userId,
    this.expenses = true,
    this.contacts = true,
    this.stock = false,
    this.tasks = true,
    this.invoices = false,
    this.clients = true,
    this.crm = false,
    this.ai = false,
  });

  /// Convert to Firestore JSON
  Map<String, dynamic> toJson() => {
    'expenses': expenses,
    'contacts': contacts,
    'stock': stock,
    'tasks': tasks,
    'invoices': invoices,
    'clients': clients,
    'crm': crm,
    'ai': ai,
  };

  /// Create from Firestore JSON
  factory MobileModules.fromJson(Map<String, dynamic> json, String userId) {
    return MobileModules(
      userId: userId,
      expenses: json['expenses'] ?? true,
      contacts: json['contacts'] ?? true,
      stock: json['stock'] ?? false,
      tasks: json['tasks'] ?? true,
      invoices: json['invoices'] ?? false,
      clients: json['clients'] ?? true,
      crm: json['crm'] ?? false,
      ai: json['ai'] ?? false,
    );
  }

  /// Copy with modifications
  MobileModules copyWith({
    bool? expenses,
    bool? contacts,
    bool? stock,
    bool? tasks,
    bool? invoices,
    bool? clients,
    bool? crm,
    bool? ai,
  }) {
    return MobileModules(
      userId: userId,
      expenses: expenses ?? this.expenses,
      contacts: contacts ?? this.contacts,
      stock: stock ?? this.stock,
      tasks: tasks ?? this.tasks,
      invoices: invoices ?? this.invoices,
      clients: clients ?? this.clients,
      crm: crm ?? this.crm,
      ai: ai ?? this.ai,
    );
  }

  /// Get list of enabled modules
  List<String> getEnabledModules() {
    final enabled = <String>[];
    if (expenses) enabled.add('expenses');
    if (contacts) enabled.add('contacts');
    if (stock) enabled.add('stock');
    if (tasks) enabled.add('tasks');
    if (invoices) enabled.add('invoices');
    if (clients) enabled.add('clients');
    if (crm) enabled.add('crm');
    if (ai) enabled.add('ai');
    return enabled;
  }

  /// Check if module is enabled
  bool isModuleEnabled(String moduleName) {
    switch (moduleName.toLowerCase()) {
      case 'expenses':
        return expenses;
      case 'contacts':
        return contacts;
      case 'stock':
        return stock;
      case 'tasks':
        return tasks;
      case 'invoices':
        return invoices;
      case 'clients':
        return clients;
      case 'crm':
        return crm;
      case 'ai':
        return ai;
      default:
        return false;
    }
  }
}

/// Service for managing mobile modules configuration
class MobileModulesService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get user's mobile modules configuration
  Future<MobileModules> getUserModules() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      final doc = await _firestore.collection('mobileModules').doc(userId).get();

      if (!doc.exists) {
        // Create default configuration
        final defaultModules = MobileModules(userId: userId);
        await saveUserModules(defaultModules);
        return defaultModules;
      }

      return MobileModules.fromJson(doc.data()!, userId);
    } catch (e) {
      logger.error('Error fetching mobile modules: $e');
      // Return default on error
      return MobileModules(userId: userId);
    }
  }

  /// Save user's mobile modules configuration
  Future<void> saveUserModules(MobileModules modules) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      await _firestore
          .collection('mobileModules')
          .doc(userId)
          .set(modules.toJson(), SetOptions(merge: true));
      logger.info('Mobile modules configuration saved for user $userId');
    } catch (e) {
      logger.error('Error saving mobile modules: $e');
      rethrow;
    }
  }

  /// Update specific module
  Future<void> updateModule(String moduleName, bool enabled) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      await _firestore
          .collection('mobileModules')
          .doc(userId)
          .update({moduleName: enabled});
      logger.info('Module $moduleName updated to $enabled');
    } catch (e) {
      logger.error('Error updating module: $e');
      rethrow;
    }
  }

  /// Enable module
  Future<void> enableModule(String moduleName) async {
    await updateModule(moduleName, true);
  }

  /// Disable module
  Future<void> disableModule(String moduleName) async {
    await updateModule(moduleName, false);
  }

  /// Stream user's mobile modules configuration
  Stream<MobileModules> streamUserModules() {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    return _firestore
        .collection('mobileModules')
        .doc(userId)
        .snapshots()
        .map((snapshot) {
          if (!snapshot.exists) {
            return MobileModules(userId: userId);
          }
          return MobileModules.fromJson(snapshot.data()!, userId);
        });
  }

  /// Check if module is enabled
  Future<bool> isModuleEnabled(String moduleName) async {
    final modules = await getUserModules();
    return modules.isModuleEnabled(moduleName);
  }

  /// Get all enabled modules
  Future<List<String>> getEnabledModules() async {
    final modules = await getUserModules();
    return modules.getEnabledModules();
  }

  /// Set multiple modules at once
  Future<void> setModules(Map<String, bool> moduleStates) async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      await _firestore
          .collection('mobileModules')
          .doc(userId)
          .set(moduleStates, SetOptions(merge: true));
      logger.info('Mobile modules batch updated for user $userId');
    } catch (e) {
      logger.error('Error batch updating modules: $e');
      rethrow;
    }
  }

  /// Reset to default configuration
  Future<void> resetToDefaults() async {
    final userId = _auth.currentUser?.uid;
    if (userId == null) throw Exception('User must be authenticated');

    try {
      final defaultModules = MobileModules(userId: userId);
      await saveUserModules(defaultModules);
      logger.info('Mobile modules reset to defaults for user $userId');
    } catch (e) {
      logger.error('Error resetting modules: $e');
      rethrow;
    }
  }
}
