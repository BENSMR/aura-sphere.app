import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/client_model.dart';
import '../../providers/client_provider.dart';
import '../../services/invoice_service.dart';

/// CRM List Screen - Display all clients with metrics
/// Shows name, AI score, lifetime value, invoices, and churn risk
class CRMListScreen extends StatefulWidget {
  const CRMListScreen({Key? key}) : super(key: key);

  @override
  State<CRMListScreen> createState() => _CRMListScreenState();
}

class _CRMListScreenState extends State<CRMListScreen> {
  late InvoiceService _invoiceService;
  final Map<String, Map<String, dynamic>> _clientInvoiceMetrics = {};
  bool _showInvoiceMetrics = true;

  // Search, filter, sort state
  String _searchQuery = "";
  String _filterType = "all"; // all, vip, atRisk, active, highValue
  String _sortBy = "aiScore"; // aiScore, lifetimeValue, lastActivity, churnRisk

  @override
  void initState() {
    super.initState();
    _invoiceService = InvoiceService();
  }

  /// Load invoice metrics for all clients
  Future<void> _loadInvoiceMetrics() async {
    final clients = context.read<ClientProvider>().clients;
    for (final client in clients) {
      try {
        final invoices = await _invoiceService.getClientInvoices(client.id);
        final statusCount =
            await _invoiceService.getClientInvoiceStatusCount(client.id);
        final pending =
            await _invoiceService.getClientPendingAmount(client.id);
        final revenue = await _invoiceService.getClientRevenue(client.id);

        if (mounted) {
          setState(() {
            _clientInvoiceMetrics[client.id] = {
              'total': invoices.length,
              'paid': statusCount['paid'] ?? 0,
              'pending': statusCount['sent'] ?? 0 + statusCount['draft'] ?? 0,
              'overdue': statusCount['overdue'] ?? 0,
              'pendingAmount': pending,
              'revenue': revenue,
            };
          });
        }
      } catch (e) {
        print('Error loading invoice metrics for ${client.id}: $e');
      }
    }
  }

  /// Load invoice metrics for all clients
  Future<void> _loadInvoiceMetrics() async {
    final clients = context.read<ClientProvider>().clients;
    for (final client in clients) {
      try {
        final invoices = await _invoiceService.getClientInvoices(client.id);
        final statusCount =
            await _invoiceService.getClientInvoiceStatusCount(client.id);
        final pending =
            await _invoiceService.getClientPendingAmount(client.id);
        final revenue = await _invoiceService.getClientRevenue(client.id);

        if (mounted) {
          setState(() {
            _clientInvoiceMetrics[client.id] = {
              'total': invoices.length,
              'paid': statusCount['paid'] ?? 0,
              'pending': statusCount['sent'] ?? 0 + statusCount['draft'] ?? 0,
              'overdue': statusCount['overdue'] ?? 0,
              'pendingAmount': pending,
              'revenue': revenue,
            };
          });
        }
      } catch (e) {
        print('Error loading invoice metrics for ${client.id}: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
        elevation: 0,
        actions: [
          // Toggle invoice metrics
          Tooltip(
            message: _showInvoiceMetrics
                ? 'Hide invoice metrics'
                : 'Show invoice metrics',
            child: IconButton(
              icon: Icon(_showInvoiceMetrics ? Icons.receipt : Icons.receipt_long),
              onPressed: () {
                setState(() => _showInvoiceMetrics = !_showInvoiceMetrics);
              },
            ),
          ),
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ClientProvider>().refreshClients();
              _loadInvoiceMetrics();
            },
          ),
        ],
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, _) {
          // Loading state
          if (clientProvider.isLoading) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          // Error state
          if (clientProvider.errorMessage != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.error_outline, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text(
                    'Error: ${clientProvider.errorMessage}',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      clientProvider.refreshClients();
                      _loadInvoiceMetrics();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Empty state
          if (clientProvider.clients.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(
                    Icons.people_outline,
                    size: 64,
                    color: Colors.grey,
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'No clients yet',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () {
                      Navigator.pushNamed(context, '/crm/add');
                    },
                    icon: const Icon(Icons.add),
                    label: const Text('Add First Client'),
                  ),
                ],
              ),
            );
          }

          // Load invoice metrics on first build
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_clientInvoiceMetrics.isEmpty) {
              _loadInvoiceMetrics();
            }
          });

          // Get filtered and sorted clients
          var clients = _getFilteredAndSortedClients(clientProvider.clients);

          // Clients list
          return Column(
            children: [
              // Search bar
              _buildSearchBar(),
              // Filter chips
              _buildFilters(),
              // Sort dropdown
              _buildSorter(),
              // Clients list
              Expanded(
                child: clients.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.search_off,
                              size: 48,
                              color: Colors.grey.shade400,
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'No clients match your filters',
                              style: TextStyle(
                                color: Colors.grey,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      )
                    : RefreshIndicator(
                        onRefresh: () async {
                          await clientProvider.refreshClients();
                          await _loadInvoiceMetrics();
                        },
                        child: ListView.builder(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          itemCount: clients.length,
                          itemBuilder: (context, index) {
                            final client = clients[index];
                            final metrics = _clientInvoiceMetrics[client.id];
                            return ClientListTile(
                              client: client,
                              invoiceMetrics: metrics,
                              showInvoiceMetrics: _showInvoiceMetrics,
                            );
                          },
                        ),
                      ),
              ),
            ],
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.pushNamed(context, '/crm/add');
        },
        tooltip: 'Add Client',
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Build search bar
  Widget _buildSearchBar() {
    return Padding(
      padding: const EdgeInsets.all(12),
      child: TextField(
        decoration: InputDecoration(
          hintText: 'Search by name or company...',
          prefixIcon: const Icon(Icons.search),
          suffixIcon: _searchQuery.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.clear),
                  onPressed: () {
                    setState(() => _searchQuery = '');
                  },
                )
              : null,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        onChanged: (value) {
          setState(() => _searchQuery = value);
        },
      ),
    );
  }

  /// Build filter chips
  Widget _buildFilters() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      child: Row(
        children: [
          _buildFilterChip('all', '📋 All', Colors.grey),
          const SizedBox(width: 8),
          _buildFilterChip('vip', '👑 VIP', Colors.amber),
          const SizedBox(width: 8),
          _buildFilterChip('atRisk', '⚠️ At Risk', Colors.red),
          const SizedBox(width: 8),
          _buildFilterChip('active', '✅ Active', Colors.green),
          const SizedBox(width: 8),
          _buildFilterChip('highValue', '💰 High Value', Colors.blue),
        ],
      ),
    );
  }

  /// Build individual filter chip
  Widget _buildFilterChip(String value, String label, Color color) {
    final isSelected = _filterType == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      selectedColor: color.withOpacity(0.3),
      onSelected: (_) {
        setState(() => _filterType = value);
      },
    );
  }

  /// Build sort dropdown
  Widget _buildSorter() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: DropdownButtonFormField<String>(
        value: _sortBy,
        decoration: InputDecoration(
          labelText: 'Sort By',
          prefixIcon: const Icon(Icons.sort),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
        items: const [
          DropdownMenuItem(
            value: 'aiScore',
            child: Text('AI Score (High to Low)'),
          ),
          DropdownMenuItem(
            value: 'lifetimeValue',
            child: Text('Lifetime Value (High to Low)'),
          ),
          DropdownMenuItem(
            value: 'lastActivity',
            child: Text('Last Activity (Recent)'),
          ),
          DropdownMenuItem(
            value: 'churnRisk',
            child: Text('Churn Risk (High to Low)'),
          ),
        ],
        onChanged: (value) {
          if (value != null) {
            setState(() => _sortBy = value);
          }
        },
      ),
    );
  }

  /// Get filtered and sorted clients
  List<ClientModel> _getFilteredAndSortedClients(List<ClientModel> clients) {
    var filtered = clients;

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      filtered = filtered
          .where((client) =>
              client.name.toLowerCase().contains(query) ||
              client.company.toLowerCase().contains(query) ||
              client.email.toLowerCase().contains(query))
          .toList();
    }

    // Apply status filter
    filtered = _applyStatusFilter(filtered);

    // Apply sort
    filtered = _applySorting(filtered);

    return filtered;
  }

  /// Apply status filter
  List<ClientModel> _applyStatusFilter(List<ClientModel> clients) {
    switch (_filterType) {
      case 'vip':
        return clients.where((c) => c.vipStatus).toList();

      case 'atRisk':
        return clients.where((c) => c.churnRisk > 70).toList();

      case 'active':
        return clients.where((c) {
          if (c.lastActivityAt == null) return false;
          final days =
              DateTime.now().difference(c.lastActivityAt!).inDays;
          return days <= 30;
        }).toList();

      case 'highValue':
        return clients.where((c) => c.lifetimeValue > 10000).toList();

      case 'all':
      default:
        return clients;
    }
  }

  /// Apply sorting
  List<ClientModel> _applySorting(List<ClientModel> clients) {
    switch (_sortBy) {
      case 'aiScore':
        clients.sort((a, b) => b.aiScore.compareTo(a.aiScore));
        break;

      case 'lifetimeValue':
        clients.sort((a, b) => b.lifetimeValue.compareTo(a.lifetimeValue));
        break;

      case 'lastActivity':
        clients.sort((a, b) {
          final aTime = a.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          final bTime = b.lastActivityAt ?? DateTime.fromMillisecondsSinceEpoch(0);
          return bTime.compareTo(aTime);
        });
        break;

      case 'churnRisk':
        clients.sort((a, b) => b.churnRisk.compareTo(a.churnRisk));
        break;
    }

    return clients;
  }
}

/// Individual client list tile with metrics
class ClientListTile extends StatelessWidget {
  final ClientModel client;
  final Map<String, dynamic>? invoiceMetrics;
  final bool showInvoiceMetrics;

  const ClientListTile({
    Key? key,
    required this.client,
    this.invoiceMetrics,
    this.showInvoiceMetrics = true,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      child: Column(
        children: [
          ListTile(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            leading: _buildAvatarWithScore(),
            title: Text(
              client.name,
              style:
                  const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 4),
                Text(
                  client.company.isNotEmpty ? client.company : 'No company',
                  style: const TextStyle(color: Colors.grey, fontSize: 12),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 6),
                _buildMetricsRow(),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '€${client.lifetimeValue.toStringAsFixed(0)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(height: 4),
                _buildStatusBadge(),
              ],
            ),
            onTap: () {
              Navigator.pushNamed(
                context,
                '/crm/details',
                arguments: client.id,
              );
            },
          ),
          // Invoice metrics section
          if (showInvoiceMetrics && invoiceMetrics != null) ...[
            Divider(height: 1, color: Colors.grey.withOpacity(0.3)),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: _buildInvoiceMetrics(),
            ),
          ],
        ],
      ),
    );
  }

  /// Build invoice metrics row
  Widget _buildInvoiceMetrics() {
    final metrics = invoiceMetrics!;
    final total = metrics['total'] as int? ?? 0;
    final paid = metrics['paid'] as int? ?? 0;
    final pending = metrics['pending'] as int? ?? 0;
    final overdue = metrics['overdue'] as int? ?? 0;
    final revenue = metrics['revenue'] as double? ?? 0.0;
    final pendingAmount = metrics['pendingAmount'] as double? ?? 0.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Invoice count and revenue row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                const Icon(Icons.receipt_long, size: 16, color: Colors.blue),
                const SizedBox(width: 8),
                Text(
                  '$total invoices',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            Text(
              'Revenue: €${revenue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                color: Colors.green,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        // Status chips
        Row(
          children: [
            if (paid > 0)
              _buildInvoiceStatusChip(
                label: 'Paid',
                count: paid,
                color: Colors.green,
              )
            else
              const SizedBox.shrink(),
            if (pending > 0) ...[
              const SizedBox(width: 6),
              _buildInvoiceStatusChip(
                label: 'Pending',
                count: pending,
                color: Colors.blue,
              ),
            ],
            if (overdue > 0) ...[
              const SizedBox(width: 6),
              _buildInvoiceStatusChip(
                label: 'Overdue',
                count: overdue,
                color: Colors.red,
              ),
            ],
            if (pendingAmount > 0) ...[
              const Spacer(),
              Text(
                '€${pendingAmount.toStringAsFixed(0)} pending',
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: Colors.orange,
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }

  /// Build invoice status chip
  Widget _buildInvoiceStatusChip({
    required String label,
    required int count,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withOpacity(0.15),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
          const SizedBox(width: 4),
          Text(
            count.toString(),
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build avatar with AI score overlay
  Widget _buildAvatarWithScore() {
    return Stack(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: _getAIScoreColor(),
          child: Text(
            client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        // AI Score badge
        Positioned(
          bottom: 0,
          right: 0,
          child: Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: _getAIScoreColor(), width: 2),
            ),
            child: Text(
              '${client.aiScore}',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 10,
                color: _getAIScoreColor(),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Build metrics row (AI Score, Churn Risk, Status)
  Widget _buildMetricsRow() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // AI Score metric
        _buildMetricChip(
          label: 'Score',
          value: '${client.aiScore}',
          color: _getAIScoreColor(),
        ),
        const SizedBox(width: 8),
        // Churn Risk metric
        _buildMetricChip(
          label: 'Risk',
          value: '${client.churnRisk}',
          color: _getChurnRiskColor(),
        ),
        const SizedBox(width: 8),
        // VIP status
        if (client.vipStatus)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.amber.withOpacity(0.2),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.amber),
            ),
            child: const Text(
              'VIP',
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: Colors.amber,
              ),
            ),
          ),
      ],
    );
  }

  /// Build individual metric chip
  Widget _buildMetricChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build status badge (VIP, AT_RISK, etc)
  Widget _buildStatusBadge() {
    if (client.aiTags.isEmpty) {
      return const Text(
        'active',
        style: TextStyle(fontSize: 11, color: Colors.grey),
      );
    }

    // Show first tag
    final tag = client.aiTags[0];
    final tagColor = _getTagColor(tag);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tagColor, width: 0.5),
      ),
      child: Text(
        tag.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: tagColor,
        ),
      ),
    );
  }

  /// Get color based on AI score
  Color _getAIScoreColor() {
    if (client.aiScore >= 80) return Colors.green;
    if (client.aiScore >= 60) return Colors.blue;
    if (client.aiScore >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Get color based on churn risk
  Color _getChurnRiskColor() {
    if (client.churnRisk <= 20) return Colors.green;
    if (client.churnRisk <= 50) return Colors.orange;
    return Colors.red;
  }

  /// Get color based on AI tag
  Color _getTagColor(String tag) {
    switch (tag.toUpperCase()) {
      case 'VIP':
        return Colors.amber;
      case 'AT_RISK':
        return Colors.red;
      case 'RETURNING':
        return Colors.green;
      case 'NEW':
        return Colors.blue;
      case 'DORMANT':
        return Colors.grey;
      case 'HIGH_VALUE':
        return Colors.green;
      case 'NEGATIVE_SENTIMENT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
  Widget _buildMetricChip({
    required String label,
    required String value,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color, width: 0.5),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            style: const TextStyle(fontSize: 8, color: Colors.grey),
          ),
          Text(
            value,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 11,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  /// Build status badge (VIP, AT_RISK, etc)
  Widget _buildStatusBadge() {
    if (client.aiTags.isEmpty) {
      return const Text(
        'active',
        style: TextStyle(fontSize: 11, color: Colors.grey),
      );
    }

    // Show first tag
    final tag = client.aiTags[0];
    final tagColor = _getTagColor(tag);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: tagColor.withOpacity(0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: tagColor, width: 0.5),
      ),
      child: Text(
        tag.replaceAll('_', ' ').toUpperCase(),
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: tagColor,
        ),
      ),
    );
  }

  /// Get color based on AI score
  Color _getAIScoreColor() {
    if (client.aiScore >= 80) return Colors.green;
    if (client.aiScore >= 60) return Colors.blue;
    if (client.aiScore >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Get color based on churn risk
  Color _getChurnRiskColor() {
    if (client.churnRisk <= 20) return Colors.green;
    if (client.churnRisk <= 50) return Colors.orange;
    return Colors.red;
  }

  /// Get color based on AI tag
  Color _getTagColor(String tag) {
    switch (tag.toUpperCase()) {
      case 'VIP':
        return Colors.amber;
      case 'AT_RISK':
        return Colors.red;
      case 'RETURNING':
        return Colors.green;
      case 'NEW':
        return Colors.blue;
      case 'DORMANT':
        return Colors.grey;
      case 'HIGH_VALUE':
        return Colors.green;
      case 'NEGATIVE_SENTIMENT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }
}
