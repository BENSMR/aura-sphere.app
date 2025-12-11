import 'package:flutter/foundation.dart';
import '../data/models/client_model.dart';
import '../services/client_service.dart';

class ClientProvider with ChangeNotifier {
  final ClientService _service;
  List<ClientModel> _clients = [];
  List<ClientModel> _filteredClients = [];
  bool _isLoading = false;
  String _searchQuery = '';
  String? _selectedStatus;
  String? _selectedTag;

  ClientProvider({ClientService? service})
      : _service = service ?? ClientService() {
    _init();
  }

  // Getters
  List<ClientModel> get clients {
    if (_searchQuery.isEmpty &&
        _selectedStatus == null &&
        _selectedTag == null) {
      return _clients;
    }
    return _getFilteredClients();
  }

  bool get isLoading => _isLoading;
  String get searchQuery => _searchQuery;
  String? get selectedStatus => _selectedStatus;
  String? get selectedTag => _selectedTag;
  int get clientCount => _clients.length;

  Map<String, int> get clientsByStatus {
    final counts = <String, int>{'lead': 0, 'active': 0, 'vip': 0, 'lost': 0};
    for (var client in _clients) {
      counts[client.status] = (counts[client.status] ?? 0) + 1;
    }
    return counts;
  }

  double get totalClientValue =>
      _clients.fold(0.0, (sum, client) => sum + client.totalValue);

  List<String> get allTags {
    final tags = <String>{};
    for (var client in _clients) {
      tags.addAll(client.tags);
    }
    return tags.toList()..sort();
  }

  /// Initialize by listening to client stream
  void _init() {
    _setLoading(true);
    _service.streamClients().listen(
      (list) {
        _clients = list;
        _setLoading(false);
        notifyListeners();
      },
      onError: (e) {
        print('Error streaming clients: $e');
        _setLoading(false);
        notifyListeners();
      },
    );
  }

  /// Filter clients based on search query, status, and tag
  List<ClientModel> _getFilteredClients() {
    List<ClientModel> filtered = _clients;

    // Apply search query
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      filtered = filtered.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q) ||
            c.company.toLowerCase().contains(q) ||
            c.phone.toLowerCase().contains(q);
      }).toList();
    }

    // Apply status filter
    if (_selectedStatus != null) {
      filtered = filtered.where((c) => c.status == _selectedStatus).toList();
    }

    // Apply tag filter
    if (_selectedTag != null) {
      filtered =
          filtered.where((c) => c.tags.contains(_selectedTag)).toList();
    }

    return filtered;
  }

  /// Set loading state
  void _setLoading(bool value) {
    _isLoading = value;
  }

  /// Update search query and filter
  void setSearchQuery(String value) {
    _searchQuery = value;
    notifyListeners();
  }

  /// Clear search query
  void clearSearch() {
    _searchQuery = '';
    notifyListeners();
  }

  /// Filter by status
  void filterByStatus(String? status) {
    _selectedStatus = status;
    notifyListeners();
  }

  /// Filter by tag
  void filterByTag(String? tag) {
    _selectedTag = tag;
    notifyListeners();
  }

  /// Clear all filters
  void clearFilters() {
    _searchQuery = '';
    _selectedStatus = null;
    _selectedTag = null;
    notifyListeners();
  }

  /// Create new client
  Future<String> addClient({
    required String name,
    required String email,
    String phone = '',
    String company = '',
    String address = '',
    String country = '',
    String notes = '',
    List<String> tags = const [],
    String status = 'lead',
  }) async {
    try {
      _setLoading(true);
      notifyListeners();
      final id = await _service.createClient(
        name: name,
        email: email,
        phone: phone,
        company: company,
        address: address,
        country: country,
        notes: notes,
        tags: tags,
        status: status,
      );
      _setLoading(false);
      notifyListeners();
      return id;
    } catch (e) {
      print('Error adding client: $e');
      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  /// Update existing client
  Future<void> updateClient(ClientModel client) async {
    try {
      _setLoading(true);
      notifyListeners();
      await _service.updateClient(client);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('Error updating client: $e');
      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  /// Delete client
  Future<void> deleteClient(String id) async {
    try {
      _setLoading(true);
      notifyListeners();
      await _service.deleteClient(id);
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('Error deleting client: $e');
      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }

  /// Get single client
  Future<ClientModel?> getClient(String id) async {
    return _service.getClientById(id);
  }

  /// Update client status
  Future<void> updateClientStatus(String clientId, String status) async {
    try {
      await _service.updateClientStatus(clientId, status);
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }

  /// Add tag to client
  Future<void> addTagToClient(String clientId, String tag) async {
    try {
      await _service.addTagToClient(clientId, tag);
    } catch (e) {
      print('Error adding tag: $e');
      rethrow;
    }
  }

  /// Remove tag from client
  Future<void> removeTagFromClient(String clientId, String tag) async {
    try {
      await _service.removeTagFromClient(clientId, tag);
    } catch (e) {
      print('Error removing tag: $e');
      rethrow;
    }
  }

  /// Add note to client
  Future<void> addNoteToClient(String clientId, String note) async {
    try {
      await _service.addNoteToClient(clientId, note);
    } catch (e) {
      print('Error adding note: $e');
      rethrow;
    }
  }

  /// Record activity on client
  Future<void> recordActivity(String clientId) async {
    try {
      await _service.recordActivity(clientId);
    } catch (e) {
      print('Error recording activity: $e');
      rethrow;
    }
  }

  /// Add value to client (when invoice created/paid)
  Future<void> addClientValue(String clientId, double amount) async {
    try {
      await _service.addClientValue(clientId: clientId, amount: amount);
    } catch (e) {
      print('Error adding client value: $e');
      rethrow;
    }
  }

  /// Get clients by status
  Future<List<ClientModel>> getClientsByStatus(String status) async {
    try {
      return await _service.getClientsByStatus(status);
    } catch (e) {
      print('Error fetching clients by status: $e');
      rethrow;
    }
  }

  /// Get clients by tag
  Future<List<ClientModel>> getClientsByTag(String tag) async {
    try {
      return await _service.getClientsByTag(tag);
    } catch (e) {
      print('Error fetching clients by tag: $e');
      rethrow;
    }
  }

  /// Search clients
  Future<List<ClientModel>> searchClients(String query) async {
    try {
      return await _service.searchClients(query);
    } catch (e) {
      print('Error searching clients: $e');
      rethrow;
    }
  }

  /// Get total client value
  Future<double> getTotalClientValue() async {
    try {
      return await _service.getTotalClientValue();
    } catch (e) {
      print('Error getting total client value: $e');
      rethrow;
    }
  }

  /// Get client count by status
  Future<Map<String, int>> getClientCountByStatus() async {
    try {
      return await _service.getClientCountByStatus();
    } catch (e) {
      print('Error getting client count by status: $e');
      rethrow;
    }
  }

  /// Refresh clients list
  Future<void> refreshClients() async {
    try {
      _setLoading(true);
      notifyListeners();
      final clients = await _service.getClientsOnce();
      _clients = clients;
      _setLoading(false);
      notifyListeners();
    } catch (e) {
      print('Error refreshing clients: $e');
      _setLoading(false);
      notifyListeners();
      rethrow;
    }
  }
}
