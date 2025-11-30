import 'package:flutter/material.dart';
import '../data/models/crm_model.dart';
import '../services/firebase/crm_service.dart';
import 'dart:async';

class CrmProvider extends ChangeNotifier {
  final CrmService _service;
  List<Contact> _contacts = [];
  bool _loading = false;
  String _search = '';
  String? _ownerId;

  CrmProvider({CrmService? service}) : _service = service ?? CrmService() {
    _subscribe();
  }

  List<Contact> get contacts => _contacts;
  bool get loading => _loading;
  String get search => _search;
  String? get ownerId => _ownerId;

  StreamSubscription<List<Contact>>? _streamSub;

  /// Set owner ID for the CRM (used on login)
  void setOwner(String userId) {
    _ownerId = userId;
    _subscribe();
  }

  void _subscribe() {
    try {
      _streamSub = _service.streamContacts().listen((list) {
        _contacts = list;
        notifyListeners();
      });
    } catch (e) {
      // ignore if not authenticated
    }
  }

  void setSearch(String s) {
    _search = s;
    // re-subscribe with search; simple approach: cancel and listen
    _streamSub?.cancel();
    try {
      _streamSub = _service.streamContacts(search: s).listen((list) {
        _contacts = list;
        notifyListeners();
      });
    } catch (e) {
      // ignore if not authenticated
    }
    notifyListeners();
  }

  Future<void> createContact({
    required String name,
    String email = '',
    String phone = '',
    String company = '',
    String jobTitle = '',
    String notes = '',
    String status = 'lead',
    List<String> tags = const [],
  }) async {
    _loading = true;
    notifyListeners();
    try {
      await _service.createContact(
        name: name,
        email: email,
        phone: phone,
        company: company,
        jobTitle: jobTitle,
        notes: notes,
        status: status,
        tags: tags,
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> updateContact(Contact contact) async {
    _loading = true;
    notifyListeners();
    try {
      await _service.updateContact(contact);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> deleteContact(String contactId) async {
    _loading = true;
    notifyListeners();
    try {
      await _service.deleteContact(contactId);
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<Contact?> getContact(String id) async {
    return await _service.getContact(id);
  }

  @override
  void dispose() {
    _streamSub?.cancel();
    super.dispose();
  }
}
