import 'package:flutter/material.dart';
import '../models/crm_model.dart';
import '../services/crm_service.dart';

class CRMProvider with ChangeNotifier {
  final CRMService _crmService = CRMService();
  List<CRMContact> _contacts = [];
  bool _isLoading = false;

  List<CRMContact> get contacts => _contacts;
  bool get isLoading => _isLoading;

  Future<void> loadContacts(String userId) async {
    _isLoading = true;
    notifyListeners();

    try {
      _contacts = await _crmService.getContacts(userId);
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addContact(CRMContact contact) async {
    await _crmService.addContact(contact);
    _contacts.add(contact);
    notifyListeners();
  }
}
