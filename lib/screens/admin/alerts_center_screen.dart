import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

/// Alert categories and their icon/color styling
enum AlertCategory {
  highRisk,
  finance,
  expense,
  inventory,
  security,
}

extension AlertCategoryExt on AlertCategory {
  String get label {
    switch (this) {
      case AlertCategory.highRisk:
        return 'High Risk';
      case AlertCategory.finance:
        return 'Finance';
      case AlertCategory.expense:
        return 'Expense';
      case AlertCategory.inventory:
        return 'Inventory';
      case AlertCategory.security:
        return 'Security';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertCategory.highRisk:
        return Icons.warning;
      case AlertCategory.finance:
        return Icons.trending_down;
      case AlertCategory.expense:
        return Icons.receipt;
      case AlertCategory.inventory:
        return Icons.inventory_2;
      case AlertCategory.security:
        return Icons.shield;
    }
  }

  Color get color {
    switch (this) {
      case AlertCategory.highRisk:
        return Colors.red;
      case AlertCategory.finance:
        return Colors.orange;
      case AlertCategory.expense:
        return Colors.amber;
      case AlertCategory.inventory:
        return Colors.blue;
      case AlertCategory.security:
        return Colors.purple;
    }
  }
}

class AlertsCenterScreen extends StatefulWidget {
  const AlertsCenterScreen({Key? key}) : super(key: key);

  @override
  State<AlertsCenterScreen> createState() => _AlertsCenterScreenState();
}

class _AlertsCenterScreenState extends State<AlertsCenterScreen> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  AlertCategory _selectedCategory = AlertCategory.highRisk;
  bool _showResolved = false;

  /// Query anomalies filtered by category and resolution status
  Stream<QuerySnapshot> _getAnomaliesStream() {
    var query = _db.collection('anomalies').orderBy('createdAt', descending: true);

    // Filter by category
    final categoryMap = {
      AlertCategory.highRisk: ['critical', 'high'],
      AlertCategory.finance: 'invoice',
      AlertCategory.expense: 'expense',
      AlertCategory.inventory: 'inventory',
      AlertCategory.security: 'audit',
    };

    final filterValue = categoryMap[_selectedCategory];
    if (filterValue is String) {
      query = query.where('entityType', isEqualTo: filterValue);
    } else if (filterValue is List) {
      // For high-risk, filter by severity
      query = query.where('severity', whereIn: filterValue);
    }

    // Filter by resolution status
    if (!_showResolved) {
      query = query.where('resolved', isEqualTo: false);
    }

    return query.limit(100).snapshots();
  }

  /// Get severity color
  Color _getSeverityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  /// Format timestamp
  String _formatTime(Timestamp? ts) {
    if (ts == null) return 'N/A';
    return DateFormat('MMM dd, HH:mm').format(ts.toDate());
  }

  /// Mark anomaly as resolved
  Future<void> _resolveAnomaly(String anomalyId, String resolution) async {
    try {
      await _db.collection('anomalies').doc(anomalyId).update({
        'resolved': true,
        'resolvedAt': FieldValue.serverTimestamp(),
        'resolution': resolution,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anomaly marked as resolved')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('⚠️ Alerts Center'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: FilterChip(
                label: Text(_showResolved ? 'Showing All' : 'Unresolved Only'),
                onSelected: (value) {
                  setState(() => _showResolved = !_showResolved);
                },
                backgroundColor: _showResolved ? Colors.green[100] : Colors.blue[100],
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Category tabs
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Row(
                children: AlertCategory.values
                    .map(
                      (cat) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: InputChip(
                          label: Text(cat.label),
                          avatar: Icon(cat.icon, size: 18),
                          selected: _selectedCategory == cat,
                          onSelected: (selected) {
                            setState(() => _selectedCategory = cat);
                          },
                          backgroundColor: cat.color.withOpacity(0.2),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
          ),
          // Alerts list
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: _getAnomaliesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Text('Error: ${snapshot.error}'),
                  );
                }

                final anomalies = snapshot.data?.docs ?? [];

                if (anomalies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.check_circle, size: 64, color: Colors.green[300]),
                        const SizedBox(height: 16),
                        Text(
                          _showResolved
                              ? 'No alerts in this category'
                              : 'No unresolved alerts! 🎉',
                          style: const TextStyle(fontSize: 16),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: anomalies.length,
                  itemBuilder: (context, index) {
                    final doc = anomalies[index];
                    final data = doc.data() as Map<String, dynamic>;

                    return AlertCard(
                      anomalyId: doc.id,
                      severity: data['severity'] ?? 'unknown',
                      message: data['message'] ?? '',
                      entityType: data['entityType'] ?? '',
                      entityId: data['entityId'] ?? '',
                      recommendedAction: data['recommendedAction'] ?? '',
                      createdAt: data['createdAt'] as Timestamp?,
                      resolved: data['resolved'] ?? false,
                      onResolve: (resolution) => _resolveAnomaly(doc.id, resolution),
                      severityColor: _getSeverityColor(data['severity'] ?? 'unknown'),
                      formatTime: _formatTime,
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Individual alert card
class AlertCard extends StatefulWidget {
  final String anomalyId;
  final String severity;
  final String message;
  final String entityType;
  final String entityId;
  final String recommendedAction;
  final Timestamp? createdAt;
  final bool resolved;
  final Function(String) onResolve;
  final Color severityColor;
  final String Function(Timestamp?) formatTime;

  const AlertCard({
    Key? key,
    required this.anomalyId,
    required this.severity,
    required this.message,
    required this.entityType,
    required this.entityId,
    required this.recommendedAction,
    required this.createdAt,
    required this.resolved,
    required this.onResolve,
    required this.severityColor,
    required this.formatTime,
  }) : super(key: key);

  @override
  State<AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<AlertCard> {
  bool _expanded = false;
  String? _selectedResolution;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Column(
        children: [
          ListTile(
            leading: Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: widget.severityColor.withOpacity(0.2),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                widget.severity == 'critical' || widget.severity == 'high'
                    ? Icons.priority_high
                    : Icons.info,
                color: widget.severityColor,
              ),
            ),
            title: Text(
              widget.message,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Text(
              '${widget.entityType} • ${widget.formatTime(widget.createdAt)}',
              style: TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            trailing: _buildStatusBadge(),
            onTap: () {
              setState(() => _expanded = !_expanded);
            },
          ),
          if (_expanded)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildDetailRow('Entity ID:', widget.entityId),
                  const SizedBox(height: 12),
                  _buildDetailRow('Severity:', widget.severity.toUpperCase()),
                  const SizedBox(height: 12),
                  Text(
                    'Recommended Action:',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      widget.recommendedAction,
                      style: const TextStyle(fontSize: 13),
                    ),
                  ),
                  const SizedBox(height: 16),
                  if (!widget.resolved)
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Resolution:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          children: [
                            _buildResolutionButton('Approved', Colors.green),
                            _buildResolutionButton('Reviewed', Colors.blue),
                            _buildResolutionButton('Dismissed', Colors.grey),
                          ],
                        ),
                      ],
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    if (widget.resolved) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.green[100],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          'Resolved',
          style: TextStyle(color: Colors.green[700], fontWeight: FontWeight.bold),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: widget.severityColor.withOpacity(0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        widget.severity.toUpperCase(),
        style: TextStyle(
          color: widget.severityColor,
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Row(
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(width: 8),
        Expanded(
          child: Text(value, style: TextStyle(color: Colors.grey[700])),
        ),
      ],
    );
  }

  Widget _buildResolutionButton(String label, Color color) {
    final isSelected = _selectedResolution == label;
    return ElevatedButton(
      onPressed: isSelected
          ? null
          : () {
              widget.onResolve(label);
              setState(() => _selectedResolution = label);
            },
      style: ElevatedButton.styleFrom(
        backgroundColor: isSelected ? color : color.withOpacity(0.3),
        foregroundColor: Colors.white,
      ),
      child: Text(label),
    );
  }
}
