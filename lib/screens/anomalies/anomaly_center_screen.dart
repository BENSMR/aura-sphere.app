import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/anomaly_model.dart';

/// Anomaly Center Screen
///
/// Real-time dashboard for viewing and managing anomalies detected by the scanner.
/// - Filter by entity type (invoice, expense, inventory, audit)
/// - Filter by severity (critical, high, medium, low)
/// - View detailed anomaly information
/// - Mark anomalies as acknowledged
/// - Track resolution status
class AnomalyCenterScreen extends StatefulWidget {
  const AnomalyCenterScreen({Key? key}) : super(key: key);

  @override
  State<AnomalyCenterScreen> createState() => _AnomalyCenterScreenState();
}

class _AnomalyCenterScreenState extends State<AnomalyCenterScreen> {
  late FirebaseFirestore _firestore;
  String? _selectedEntityType;
  String? _selectedSeverity;
  bool _showAcknowledged = false;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
  }

  /// Get filtered Firestore stream based on selected filters
  Stream<List<AnomalyModel>> _getAnomaliesStream() {
    Query query = _firestore.collection('anomalies');

    // Filter by severity if selected
    if (_selectedSeverity != null) {
      query = query.where('severity', isEqualTo: _selectedSeverity);
    }

    // Filter by entity type if selected
    if (_selectedEntityType != null) {
      query = query.where('entityType', isEqualTo: _selectedEntityType);
    }

    // Filter by acknowledgment status
    if (!_showAcknowledged) {
      query = query.where('acknowledged', isEqualTo: false);
    }

    // Order by detected time (newest first)
    query = query.orderBy('detectedAt', descending: true).limit(200);

    return query.snapshots().map((snapshot) {
      return snapshot.docs
          .map((doc) => AnomalyModel.fromDoc(doc))
          .toList();
    });
  }

  /// Mark anomaly as acknowledged
  Future<void> _acknowledgeAnomaly(String anomalyId) async {
    try {
      await _firestore.collection('anomalies').doc(anomalyId).update({
        'acknowledged': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Anomaly marked as acknowledged')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: ${e.toString()}')),
        );
      }
    }
  }

  /// Get color for severity
  Color _getSeverityColor(String severity) {
    switch (severity.toLowerCase()) {
      case 'critical':
        return Colors.red;
      case 'high':
        return Colors.orange;
      case 'medium':
        return Colors.amber;
      case 'low':
      default:
        return Colors.blue;
    }
  }

  /// Get icon for entity type
  IconData _getEntityIcon(String? entityType) {
    switch (entityType) {
      case 'invoice':
        return Icons.receipt;
      case 'expense':
        return Icons.money;
      case 'inventory':
        return Icons.warehouse;
      case 'audit':
        return Icons.security;
      default:
        return Icons.error;
    }
  }

  /// Format timestamp to readable string
  String _formatTime(DateTime dateTime) {
    return DateFormat('MMM dd, yyyy HH:mm').format(dateTime);
  }

  /// Build severity badge
  Widget _buildSeverityBadge(String severity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getSeverityColor(severity).withOpacity(0.2),
        border: Border.all(color: _getSeverityColor(severity)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: _getSeverityColor(severity),
          fontWeight: FontWeight.bold,
          fontSize: 12,
        ),
      ),
    );
  }

  /// Build anomaly card
  Widget _buildAnomalyCard(AnomalyModel anomaly) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      elevation: 2,
      child: ExpansionTile(
        title: Row(
          children: [
            Icon(
              _getEntityIcon(anomaly.entityType),
              color: _getSeverityColor(anomaly.severity),
              size: 20,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${anomaly.entityType.toUpperCase()}: ${anomaly.entityId}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(anomaly.detectedAt.toDate()),
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            _buildSeverityBadge(anomaly.severity),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Score and reasons
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Anomaly Score: ${anomaly.score}/12',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Reasons:',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.grey[700],
                        ),
                      ),
                      const SizedBox(height: 4),
                      ...anomaly.reasons.map((reason) => Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(
                          '• $reason',
                          style: const TextStyle(fontSize: 12),
                        ),
                      )),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Recommended action
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    border: Border.all(color: Colors.blue[300]!),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Recommended Action',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 12,
                          color: Colors.blue[900],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        anomaly.recommendedAction,
                        style: TextStyle(
                          fontSize: 13,
                          color: Colors.blue[900],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),

                // Sample data if available
                if (anomaly.sample != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.grey[50],
                      border: Border.all(color: Colors.grey[300]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sample Data',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 12,
                            color: Colors.grey[700],
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...(anomaly.sample?.entries ?? []).map((entry) {
                          final value = entry.value;
                          return Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Row(
                              children: [
                                Text(
                                  '${entry.key}:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.w500,
                                    fontSize: 11,
                                    color: Colors.grey[700],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    '$value',
                                    style: const TextStyle(fontSize: 11),
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                // Additional metadata
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Entity ID',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          anomaly.entityId,
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Run ID',
                          style: TextStyle(
                            fontSize: 10,
                            color: Colors.grey[600],
                          ),
                        ),
                        Text(
                          anomaly.runId ?? 'N/A',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                            fontFamily: 'monospace',
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Action buttons
                if (!anomaly.acknowledged)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () => _acknowledgeAnomaly(anomaly.id),
                      icon: const Icon(Icons.check_circle),
                      label: const Text('Mark as Acknowledged'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.green[100],
                      border: Border.all(color: Colors.green),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Acknowledged',
                      style: TextStyle(
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomaly Center'),
        elevation: 2,
      ),
      body: Column(
        children: [
          // Filter controls
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    // Entity type filter
                    FilterChip(
                      onSelected: (selected) {
                        showDialog(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: const Text('Filter by Entity Type'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () {
                                  setState(() => _selectedEntityType = null);
                                  Navigator.pop(context);
                                },
                                child: const Text('All Types'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  setState(
                                    () => _selectedEntityType = 'invoice',
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Invoice'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  setState(
                                    () => _selectedEntityType = 'expense',
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Expense'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  setState(
                                    () => _selectedEntityType = 'inventory',
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Inventory'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  setState(
                                    () => _selectedEntityType = 'audit',
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Audit'),
                              ),
                            ],
                          ),
                        );
                      },
                      selected: _selectedEntityType != null,
                      label: _selectedEntityType != null
                          ? Text(_selectedEntityType!.toUpperCase())
                          : const Text('All Types'),
                    ),

                    // Severity filter
                    FilterChip(
                      onSelected: (selected) {
                        showDialog(
                          context: context,
                          builder: (context) => SimpleDialog(
                            title: const Text('Filter by Severity'),
                            children: [
                              SimpleDialogOption(
                                onPressed: () {
                                  setState(() => _selectedSeverity = null);
                                  Navigator.pop(context);
                                },
                                child: const Text('All Levels'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  setState(
                                    () => _selectedSeverity = 'critical',
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Critical'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  setState(
                                    () => _selectedSeverity = 'high',
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('High'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  setState(
                                    () => _selectedSeverity = 'medium',
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Medium'),
                              ),
                              SimpleDialogOption(
                                onPressed: () {
                                  setState(
                                    () => _selectedSeverity = 'low',
                                  );
                                  Navigator.pop(context);
                                },
                                child: const Text('Low'),
                              ),
                            ],
                          ),
                        );
                      },
                      selected: _selectedSeverity != null,
                      label: _selectedSeverity != null
                          ? Text(_selectedSeverity!.toUpperCase())
                          : const Text('All Levels'),
                    ),

                    // Show acknowledged toggle
                    FilterChip(
                      label: const Text('Acknowledged'),
                      onSelected: (selected) {
                        setState(() => _showAcknowledged = !_showAcknowledged);
                      },
                      selected: _showAcknowledged,
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Anomalies list
          Expanded(
            child: StreamBuilder<List<AnomalyModel>>(
              stream: _getAnomaliesStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error, color: Colors.red, size: 48),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final anomalies = snapshot.data ?? [];

                if (anomalies.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.check_circle,
                          color: Colors.green[300],
                          size: 64,
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No anomalies detected',
                          style: TextStyle(fontSize: 16),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showAcknowledged
                              ? 'No acknowledged anomalies found'
                              : 'All anomalies have been reviewed',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: anomalies.length,
                  itemBuilder: (context, index) {
                    return _buildAnomalyCard(anomalies[index]);
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
