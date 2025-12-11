import 'package:flutter/material.dart';
import '../models/contact.dart';
import '../services/contact_service.dart';

/// Provider for managing contact state
/// 
/// Handles:
/// - Loading contacts (customers, suppliers, all)
/// - Creating/updating/deleting contacts
/// - Searching contacts
/// - Real-time contact updates
class ContactProvider extends ChangeNotifier {
  final ContactService _service = ContactService();

  List<Contact> _contacts = [];
  List<Contact> _customers = [];
  List<Contact> _suppliers = [];
  Contact? _selectedContact;
  bool _isLoading = false;
  String? _error;
  Map<String, int> _stats = {'total': 0, 'customers': 0, 'suppliers': 0};

  // Getters
  List<Contact> get contacts => _contacts;
  List<Contact> get customers => _customers;
  List<Contact> get suppliers => _suppliers;
  Contact? get selectedContact => _selectedContact;
  bool get isLoading => _isLoading;
  String? get error => _error;
  Map<String, int> get stats => _stats;
  bool get hasContacts => _contacts.isNotEmpty;

  /// Initialize: Load all contacts
  Future<void> init() async {
    try {
      _setLoading(true);
      _error = null;

      _contacts = await _service.getContacts();
      _customers = await _service.getCustomers();
      _suppliers = await _service.getSuppliers();
      _stats = await _service.getContactStats();

      print('✅ ContactProvider initialized with ${_contacts.length} contacts');
      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      print('❌ Error initializing ContactProvider: $e');
    }
  }

  /// Load all contacts
  Future<void> loadContacts({String? type}) async {
    try {
      _setLoading(true);
      _error = null;

      if (type == null) {
        _contacts = await _service.getContacts();
      } else if (type == 'customer') {
        _customers = await _service.getCustomers();
      } else if (type == 'supplier') {
        _suppliers = await _service.getSuppliers();
      }

      _setLoading(false);
    } catch (e) {
      _error = e.toString();
      _setLoading(false);
      print('❌ Error loading contacts: $e');
    }
  }

  /// Load customers only
  Future<void> loadCustomers() async {
    await loadContacts(type: 'customer');
  }

  /// Load suppliers only
  Future<void> loadSuppliers() async {
    await loadContacts(type: 'supplier');
  }

  /// Select a contact
  void selectContact(Contact contact) {
    _selectedContact = contact;
    notifyListeners();
  }

  /// Get contact by ID
  Contact? getContactById(String id) {
    try {
      return _contacts.firstWhere((c) => c.id == id);
    } catch (_) {
      return null;
    }
  }

  /// Search contacts
  Future<List<Contact>> searchContacts(String query) async {
    try {
      _error = null;
      return await _service.searchContacts(query);
    } catch (e) {
      _error = e.toString();
      print('❌ Error searching contacts: $e');
      return [];
    }
  }

  /// Create new contact
  Future<String?> createContact({
    required String name,
    required String email,
    String? phone,
    required String country,
    String? currency,
    required bool isBusiness,
    String? vatNumber,
    String? taxId,
    String? companyName,
    String? address,
    String? city,
    String? postalCode,
    String? contactPerson,
    String? contactPersonEmail,
    String? contactPersonPhone,
    String type = 'customer',
  }) async {
    try {
      _error = null;
      _setLoading(true);

      // Validate email
      if (!_service.isValidEmail(email)) {
        throw Exception('Invalid email address');
      }

      // Check if email exists
      if (await _service.emailExists(email)) {
        throw Exception('Email already exists for another contact');
      }

      final id = await _service.createContact(
        name: name,
        email: email,
        phone: phone,
        country: country,
        currency: currency,
        isBusiness: isBusiness,
        vatNumber: vatNumber,
        taxId: taxId,
        companyName: companyName,
        address: address,
        city: city,
        postalCode: postalCode,
        contactPerson: contactPerson,
        contactPersonEmail: contactPersonEmail,
        contactPersonPhone: contactPersonPhone,
        type: type,
      );

      // Reload contacts
      await init();
      print('✅ Contact created: $id');
      return id;
    } catch (e) {
      _error = e.toString();
      print('❌ Error creating contact: $e');
      return null;
    } finally {
      _setLoading(false);
    }
  }

  /// Update contact
  Future<bool> updateContact(Contact contact) async {
    try {
      _error = null;
      _setLoading(true);

      await _service.updateContact(contact);

      // Update local state
      final index = _contacts.indexWhere((c) => c.id == contact.id);
      if (index >= 0) {
        _contacts[index] = contact;
      }

      // Update typed lists
      final custIndex = _customers.indexWhere((c) => c.id == contact.id);
      if (custIndex >= 0) {
        _customers[custIndex] = contact;
      }

      final suppIndex = _suppliers.indexWhere((c) => c.id == contact.id);
      if (suppIndex >= 0) {
        _suppliers[suppIndex] = contact;
      }

      // Update selected if it was the modified contact
      if (_selectedContact?.id == contact.id) {
        _selectedContact = contact;
      }

      notifyListeners();
      print('✅ Contact updated: ${contact.id}');
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error updating contact: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update contact fields
  Future<bool> updateContactFields(
    String contactId,
    Map<String, dynamic> updates,
  ) async {
    try {
      _error = null;
      await _service.updateContactFields(contactId, updates);

      // Update local state
      final contact = getContactById(contactId);
      if (contact != null) {
        final updated = contact.copyWith(
          name: updates['name'],
          email: updates['email'],
          phone: updates['phone'],
          country: updates['country'],
          currency: updates['currency'],
          isBusiness: updates['isBusiness'],
          vatNumber: updates['vatNumber'],
          taxId: updates['taxId'],
          companyName: updates['companyName'],
          address: updates['address'],
          city: updates['city'],
          postalCode: updates['postalCode'],
          contactPerson: updates['contactPerson'],
          contactPersonEmail: updates['contactPersonEmail'],
          contactPersonPhone: updates['contactPersonPhone'],
          type: updates['type'],
          isActive: updates['isActive'],
        );
        await updateContact(updated);
      }

      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error updating contact fields: $e');
      return false;
    }
  }

  /// Deactivate contact
  Future<bool> deactivateContact(String contactId) async {
    try {
      _error = null;
      _setLoading(true);

      await _service.deactivateContact(contactId);

      // Remove from all lists
      _contacts.removeWhere((c) => c.id == contactId);
      _customers.removeWhere((c) => c.id == contactId);
      _suppliers.removeWhere((c) => c.id == contactId);

      // Clear selection if deactivated
      if (_selectedContact?.id == contactId) {
        _selectedContact = null;
      }

      notifyListeners();
      print('✅ Contact deactivated: $contactId');
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error deactivating contact: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Delete contact
  Future<bool> deleteContact(String contactId) async {
    try {
      _error = null;
      _setLoading(true);

      await _service.deleteContact(contactId);

      // Remove from all lists
      _contacts.removeWhere((c) => c.id == contactId);
      _customers.removeWhere((c) => c.id == contactId);
      _suppliers.removeWhere((c) => c.id == contactId);

      // Clear selection if deleted
      if (_selectedContact?.id == contactId) {
        _selectedContact = null;
      }

      notifyListeners();
      print('✅ Contact deleted: $contactId');
      return true;
    } catch (e) {
      _error = e.toString();
      print('❌ Error deleting contact: $e');
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Refresh stats
  Future<void> refreshStats() async {
    try {
      _stats = await _service.getContactStats();
      notifyListeners();
    } catch (e) {
      print('❌ Error refreshing stats: $e');
    }
  }

  /// Clear error
  void clearError() {
    _error = null;
    notifyListeners();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  /// Get customers for dropdown
  List<Contact> getCustomersForDropdown() {
    return _customers.where((c) => c.isActive).toList();
  }

  /// Get suppliers for dropdown
  List<Contact> getSuppliersForDropdown() {
    return _suppliers.where((c) => c.isActive).toList();
  }

  /// Get contact by email
  Contact? getContactByEmail(String email) {
    try {
      return _contacts.firstWhere((c) => c.email == email);
    } catch (_) {
      return null;
    }
  }
}
