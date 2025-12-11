import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/company.dart';

/// Service for managing companies in the finance module
/// 
/// Handles CRUD operations for companies at users/{uid}/companies/{companyId}
class CompanyService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String get _currentUid => _auth.currentUser?.uid ?? '';

  /// Get a company by ID
  Future<Company?> getCompany(String companyId) async {
    try {
      final doc = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('companies')
          .doc(companyId)
          .get();

      if (!doc.exists) return null;
      return Company.fromFirestore(doc);
    } catch (e) {
      print('❌ Error getting company: $e');
      return null;
    }
  }

  /// Get all companies for current user
  Future<List<Company>> getCompanies() async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('companies')
          .orderBy('isDefault', descending: true)
          .orderBy('createdAt', descending: true)
          .get();

      return snap.docs.map((doc) => Company.fromFirestore(doc)).toList();
    } catch (e) {
      print('❌ Error getting companies: $e');
      return [];
    }
  }

  /// Get the default company
  Future<Company?> getDefaultCompany() async {
    try {
      final snap = await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('companies')
          .where('isDefault', isEqualTo: true)
          .limit(1)
          .get();

      if (snap.docs.isEmpty) return null;
      return Company.fromFirestore(snap.docs.first);
    } catch (e) {
      print('❌ Error getting default company: $e');
      return null;
    }
  }

  /// Create a new company
  Future<String> createCompany({
    required String name,
    required String country,
    required String defaultCurrency,
    required bool isBusiness,
    String? vatNumber,
    String? taxId,
    String? businessEmail,
    String? businessPhone,
    String? address,
    String? city,
    String? postalCode,
    bool isDefault = false,
  }) async {
    try {
      // If this is the first company or marked as default, set it as default
      final companies = await getCompanies();
      final shouldBeDefault = isDefault || companies.isEmpty;

      // If marking as default, unset previous default
      if (shouldBeDefault) {
        final defaultCompany = await getDefaultCompany();
        if (defaultCompany != null) {
          await _firestore
              .collection('users')
              .doc(_currentUid)
              .collection('companies')
              .doc(defaultCompany.id)
              .update({'isDefault': false});
        }
      }

      final company = Company(
        id: _firestore
            .collection('users')
            .doc(_currentUid)
            .collection('companies')
            .doc()
            .id,
        uid: _currentUid,
        name: name,
        country: country.toUpperCase(),
        defaultCurrency: defaultCurrency.toUpperCase(),
        isBusiness: isBusiness,
        vatNumber: vatNumber,
        taxId: taxId,
        businessEmail: businessEmail,
        businessPhone: businessPhone,
        address: address,
        city: city,
        postalCode: postalCode,
        isDefault: shouldBeDefault,
      );

      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('companies')
          .doc(company.id)
          .set(company.toFirestore());

      print('✅ Company created: ${company.id}');
      return company.id;
    } catch (e) {
      print('❌ Error creating company: $e');
      rethrow;
    }
  }

  /// Update a company
  Future<void> updateCompany(Company company) async {
    try {
      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('companies')
          .doc(company.id)
          .update(company.copyWith(updatedAt: DateTime.now()).toFirestore());

      print('✅ Company updated: ${company.id}');
    } catch (e) {
      print('❌ Error updating company: $e');
      rethrow;
    }
  }

  /// Update specific fields of a company
  Future<void> updateCompanyFields(String companyId, Map<String, dynamic> updates) async {
    try {
      final updateData = Map<String, dynamic>.from(updates)
        ..['updatedAt'] = FieldValue.serverTimestamp();

      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('companies')
          .doc(companyId)
          .update(updateData);

      print('✅ Company fields updated: $companyId');
    } catch (e) {
      print('❌ Error updating company fields: $e');
      rethrow;
    }
  }

  /// Set company as default
  Future<void> setAsDefault(String companyId) async {
    try {
      // Unset current default
      final defaultCompany = await getDefaultCompany();
      if (defaultCompany != null && defaultCompany.id != companyId) {
        await _firestore
            .collection('users')
            .doc(_currentUid)
            .collection('companies')
            .doc(defaultCompany.id)
            .update({'isDefault': false});
      }

      // Set new default
      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('companies')
          .doc(companyId)
          .update({'isDefault': true});

      print('✅ Company set as default: $companyId');
    } catch (e) {
      print('❌ Error setting company as default: $e');
      rethrow;
    }
  }

  /// Delete a company
  Future<void> deleteCompany(String companyId) async {
    try {
      final company = await getCompany(companyId);
      if (company == null) return;

      // Prevent deleting the only company
      final companies = await getCompanies();
      if (companies.length <= 1) {
        throw Exception('Cannot delete the only company. Create another company first.');
      }

      await _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('companies')
          .doc(companyId)
          .delete();

      // If this was the default, make the first remaining company the default
      if (company.isDefault) {
        final remaining = await getCompanies();
        if (remaining.isNotEmpty) {
          await setAsDefault(remaining.first.id);
        }
      }

      print('✅ Company deleted: $companyId');
    } catch (e) {
      print('❌ Error deleting company: $e');
      rethrow;
    }
  }

  /// Stream of all companies (real-time updates)
  Stream<List<Company>> watchCompanies() {
    return _firestore
        .collection('users')
        .doc(_currentUid)
        .collection('companies')
        .orderBy('isDefault', descending: true)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snap) => snap.docs.map((doc) => Company.fromFirestore(doc)).toList())
        .handleError((err) {
      print('❌ Error watching companies: $err');
      return <Company>[];
    });
  }

  /// Validate VAT number format (basic)
  bool isValidVatNumber(String? vat) {
    if (vat == null || vat.isEmpty) return true; // Optional field
    return vat.length >= 5; // Very basic check
  }

  /// Check if VAT number exists for another company
  Future<bool> vatNumberExists(String vatNumber, {String? excludeCompanyId}) async {
    try {
      var query = _firestore
          .collection('users')
          .doc(_currentUid)
          .collection('companies')
          .where('vatNumber', isEqualTo: vatNumber);

      if (excludeCompanyId != null) {
        // This is handled on client side for now
        final all = await query.get();
        return all.docs.any((doc) => doc.id != excludeCompanyId);
      }

      final snap = await query.limit(1).get();
      return snap.docs.isNotEmpty;
    } catch (e) {
      print('⚠️ Error checking VAT number uniqueness: $e');
      return false;
    }
  }
}
