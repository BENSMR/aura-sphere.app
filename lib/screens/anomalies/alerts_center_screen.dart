import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import '../../models/anomaly_model.dart';

/// Alert types across the system
enum AlertType {
  anomaly,      // From anomaly scanner
  payment,      // Invoice/payment issues
  inventory,    // Stock level issues
  system,       // System errors/warnings
  compliance;   // Compliance/audit issues

  String toDisplayString() {
    switch (this) {
      case AlertType.anomaly:
        return 'Anomaly';
      case AlertType.payment:
        return 'Payment';
      case AlertType.inventory:
        return 'Inventory';
      case AlertType.system:
        return 'System';
      case AlertType.compliance:
        return 'Compliance';
    }
  }

  IconData get icon {
    switch (this) {
      case AlertType.anomaly:
        return Icons.warning_amber;
      case AlertType.payment:
        return Icons.payment;
      case AlertType.inventory:
        return Icons.warehouse;
      case AlertType.system:
        return Icons.computer;
      case AlertType.compliance:
        return Icons.gavel;
    }
  }

  Color get color {
    switch (this) {
      case AlertType.anomaly:
        return Colors.orange;
      case AlertType.payment:
        return Colors.red;
      case AlertType.inventory:
        return Colors.blue;
      case AlertType.system:
        return Colors.purple;
      case AlertType.compliance:
        return Colors.indigo;
    }
  }
}

/// Unified alert model for all alert types
class Alert {
  final String id;
  final AlertType type;
  final String severity; // low, medium, high, critical
  final String title;
  final String message;
  final String? actionUrl;
  final String? actionLabel;
  final DateTime createdAt;
  final bool resolved;
  final String? resolvedBy;
  final DateTime? resolvedAt;

  Alert({
    required this.id,
    required this.type,
    required this.severity,
    required this.title,
    required this.message,
    this.actionUrl,
    this.actionLabel,
    required this.createdAt,
    this.resolved = false,
    this.resolvedBy,
    this.resolvedAt,
  });

  factory Alert.fromAnomaly(AnomalyModel anomaly) {
    final dateTime = anomaly.detectedAt.toDate();
    return Alert(
      id: 'anomaly_${anomaly.id}',
      type: AlertType.anomaly,
      severity: anomaly.severity,
      title: 'Anomaly Detected: ${anomaly.entityType.toUpperCase()}',
      message: anomaly.reasons.join(', '),
      actionUrl: '/anomaly/${anomaly.id}',
      actionLabel: 'Review Anomaly',
      createdAt: dateTime,
      resolved: anomaly.acknowledged,
      resolvedBy: anomaly.owner,
      resolvedAt: dateTime,
    );
  }
}

/// Alerts Center Screen
///
/// Unified dashboard for all system alerts:
/// - Anomalies from the scanner
/// - Payment alerts (overdue invoices, collection issues)
/// - Inventory alerts (low stock, suspicious movements)
/// - System alerts (errors, warnings, maintenance)
/// - Compliance alerts (audit findings, policy violations)
class AlertsCenterScreen extends StatefulWidget {
  const AlertsCenterScreen({Key? key}) : super(key: key);

  @override
  State<AlertsCenterScreen> createState() => _AlertsCenterScreenState();
}

class _AlertsCenterScreenState extends State<AlertsCenterScreen> {
  late FirebaseFirestore _firestore;
  String? _selectedSeverity;
  bool _showResolved = false;

  @override
  void initState() {
    super.initState();
    _firestore = FirebaseFirestore.instance;
  }

  /// Get alerts stream based on filters
  Stream<List<Alert>> _getAlertsStream() {
    Query query = _firestore.collection('anomalies');

    // Filter by severity
    if (_selectedSeverity != null) {
      query = query.where('severity', isEqualTo: _selectedSeverity);
    }

    // Filter by acknowledged status
    if (!_showResolved) {
      query = query.where('acknowledged', isEqualTo: false);
    }

    query = query.orderBy('detectedAt', descending: true).limit(150);

    return query.snapshots().map((snapshot) {
      return snapshot.docs.map((doc) {
        try {
          final anomaly = AnomalyModel.fromDoc(doc);
          return Alert.fromAnomaly(anomaly);
        } catch (e) {
          return null;
        }
      }).whereType<Alert>().toList();
    });
  }

  /// Count unresolved alerts by severity
  Future<Map<String, int>> _getAlertStats() async {
    final snapshot =
        await _firestore.collection('anomalies').where('acknowledged', isEqualTo: false).get();

    final stats = <String, int>{'critical': 0, 'high': 0, 'medium': 0, 'low': 0};
    for (final doc in snapshot.docs) {
      final severity = doc['severity'] as String? ?? 'low';
      stats[severity] = (stats[severity] ?? 0) + 1;
    }
    return stats;
  }

  /// Mark alert as resolved
  Future<void> _resolveAlert(String alertId) async {
    try {
      final anomalyId = alertId.replaceFirst('anomaly_', '');
      await _firestore.collection('anomalies').doc(anomalyId).update({
        'acknowledged': true,
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Alert marked as resolved')),
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

  /// Format timestamp
  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final diff = now.difference(dateTime);

    if (diff.inSeconds < 60) {
      return 'Just now';
    } else if (diff.inMinutes < 60) {
      return '${diff.inMinutes}m ago';
    } else if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else {
      return DateFormat('MMM dd, HH:mm').format(dateTime);
    }
  }

  /// Build severity badge
  Widget _buildSeverityBadge(String severity) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: _getSeverityColor(severity).withOpacity(0.15),
        border: Border.all(color: _getSeverityColor(severity)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        severity.toUpperCase(),
        style: TextStyle(
          color: _getSeverityColor(severity),
          fontWeight: FontWeight.bold,
          fontSize: 10,
        ),
      ),
    );
  }

  /// Build type badge
  Widget _buildTypeBadge(AlertType type) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: type.color.withOpacity(0.15),
        border: Border.all(color: type.color),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(type.icon, size: 12, color: type.color),
          const SizedBox(width: 4),
          Text(
            type.toDisplayString(),
            style: TextStyle(
              color: type.color,
              fontWeight: FontWeight.bold,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }

  /// Build alert card
  Widget _buildAlertCard(Alert alert) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      elevation: 1,
      child: InkWell(
        onTap: () {
          // Navigate to alert details
        },
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: badges + time
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Title
                        Text(
                          alert.title,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        // Badges
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            _buildTypeBadge(alert.type),
                            _buildSeverityBadge(alert.severity),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Time
                  Text(
                    _formatTime(alert.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),

              // Message
              Text(
                alert.message,
                style: const TextStyle(fontSize: 12),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 10),

              // Action button + resolve button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (alert.actionLabel != null)
                    TextButton(
                      onPressed: () {
                        // Navigate to action URL
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text('Navigate to: ${alert.actionLabel}'),
                          ),
                        );
                      },
                      child: Text(alert.actionLabel!),
                    ),
                  if (!alert.resolved)
                    ElevatedButton.icon(
                      onPressed: () => _resolveAlert(alert.id),
                      icon: const Icon(Icons.check, size: 14),
                      label: const Text('Resolve'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.green[100],
                        border: Border.all(color: Colors.green),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Resolved',
                        style: TextStyle(
                          color: Colors.green[900],
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Alerts Center'),
        elevation: 2,
        actions: [
          // Stats icon
          FutureBuilder<Map<String, int>>(
            future: _getAlertStats(),
            builder: (context, snapshot) {
              if (snapshot.hasData) {
                final stats = snapshot.data!;
                final total =
                    stats.values.reduce((a, b) => a + b);
                return Padding(
                  padding: const EdgeInsets.all(8),
                  child: Center(
                    child: Badge(
                      label: Text('$total'),
                      child: const Icon(Icons.notifications),
                    ),
                  ),
                );
              }
              return const SizedBox();
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Filter controls
          Container(
            padding: const EdgeInsets.all(12),
            color: Colors.grey[50],
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Filters',
                  style: Theme.of(context).textTheme.labelMedium,
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
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
                                  setState(
                                    () => _selectedSeverity = null,
                                  );
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
                          : const Text('Severity'),
                    ),

                    // Show resolved toggle
                    FilterChip(
                      onSelected: (selected) {
                        setState(
                          () => _showResolved = !_showResolved,
                        );
                      },
                      selected: _showResolved,
                      label: const Text('Resolved'),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Alerts list
          Expanded(
            child: StreamBuilder<List<Alert>>(
              stream: _getAlertsStream(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(
                    child: CircularProgressIndicator(),
                  );
                }

                if (snapshot.hasError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(
                          Icons.error,
                          color: Colors.red,
                          size: 48,
                        ),
                        const SizedBox(height: 16),
                        Text('Error: ${snapshot.error}'),
                      ],
                    ),
                  );
                }

                final alerts = snapshot.data ?? [];

                if (alerts.isEmpty) {
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
                          'All caught up!',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          _showResolved
                              ? 'No resolved alerts to display'
                              : 'No active alerts at this time',
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
                  itemCount: alerts.length,
                  itemBuilder: (context, index) {
                    return _buildAlertCard(alerts[index]);
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
