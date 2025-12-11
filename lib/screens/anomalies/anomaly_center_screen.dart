import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../models/anomaly_model.dart';
import '../../services/anomaly_service.dart';
import '../../widgets/anomaly_card.dart';
import 'package:intl/intl.dart';

class AnomalyCenterScreen extends StatefulWidget {
  const AnomalyCenterScreen({Key? key}) : super(key: key);

  @override
  State<AnomalyCenterScreen> createState() => _AnomalyCenterScreenState();
}

class _AnomalyCenterScreenState extends State<AnomalyCenterScreen> {
  final AnomalyService _service = AnomalyService();
  String _severityFilter = '';
  String _entityTypeFilter = '';
  bool _unackOnly = true;
  int _limit = 200;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Anomaly Center'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () => setState(() {}),
          ),
          IconButton(
            icon: const Icon(Icons.tune),
            onPressed: _openFilters,
          )
        ],
      ),
      body: Column(
        children: [
          _buildSummaryBar(),
          Expanded(
            child: StreamBuilder<List<AnomalyModel>>(
              stream: _service.streamAnomalies(
                severity: _severityFilter.isEmpty ? null : _severityFilter,
                entityType: _entityTypeFilter.isEmpty ? null : _entityTypeFilter,
                onlyUnacknowledged: _unackOnly,
                limit: _limit,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (!snap.hasData || snap.data!.isEmpty) {
                  return Center(child: Text('No anomalies found', style: Theme.of(context).textTheme.bodyMedium));
                }
                final items = snap.data!;
                return ListView.builder(
                  itemCount: items.length,
                  itemBuilder: (context, i) {
                    final a = items[i];
                    return AnomalyCard(
                      anomaly: a,
                      onTap: () => _openDetail(a),
                      onAcknowledge: () => _acknowledge(a),
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

  Widget _buildSummaryBar() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      color: Colors.grey.shade100,
      child: Row(
        children: [
          Chip(label: Text('Unack only: ${_unackOnly ? "Yes" : "No"}')),
          const SizedBox(width: 8),
          if (_severityFilter.isNotEmpty) Chip(label: Text('Severity: $_severityFilter')),
          if (_entityTypeFilter.isNotEmpty) ...[
            const SizedBox(width: 8),
            Chip(label: Text('Type: $_entityTypeFilter')),
          ],
          const Spacer(),
          TextButton.icon(
            icon: const Icon(Icons.mark_email_read_outlined),
            label: const Text('Acknowledge All Visible'),
            onPressed: _ackAllVisible,
          )
        ],
      ),
    );
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      builder: (context) {
        String tmpSeverity = _severityFilter;
        String tmpType = _entityTypeFilter;
        bool tmpUnack = _unackOnly;
        return StatefulBuilder(builder: (context, setModalState) {
          return Padding(
            padding: const EdgeInsets.all(12.0),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              Row(children: [
                Expanded(child: DropdownButtonFormField<String>(
                  value: tmpSeverity.isEmpty ? null : tmpSeverity,
                  decoration: const InputDecoration(labelText: 'Severity'),
                  items: [
                    DropdownMenuItem(child: Text('All'), value: ''),
                    DropdownMenuItem(child: Text('critical'), value: 'critical'),
                    DropdownMenuItem(child: Text('high'), value: 'high'),
                    DropdownMenuItem(child: Text('medium'), value: 'medium'),
                    DropdownMenuItem(child: Text('low'), value: 'low'),
                  ],
                  onChanged: (v) => setModalState(() => tmpSeverity = v ?? ''),
                )),
                const SizedBox(width: 12),
                Expanded(child: TextFormField(
                  initialValue: tmpType,
                  decoration: const InputDecoration(labelText: 'Entity Type (invoice, expense, inventory, audit)'),
                  onChanged: (v) => setModalState(() => tmpType = v.trim()),
                ))
              ]),
              Row(
                children: [
                  Checkbox(value: tmpUnack, onChanged: (v) => setModalState(() => tmpUnack = v ?? true)),
                  const Text('Only unacknowledged'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        _severityFilter = tmpSeverity;
                        _entityTypeFilter = tmpType;
                        _unackOnly = tmpUnack;
                      });
                      Navigator.pop(context);
                    },
                    child: const Text('Apply'),
                  )
                ],
              )
            ]),
          );
        });
      },
    );
  }

  Future<void> _acknowledge(AnomalyModel a) async {
    try {
      // Replace with real user id retrieval from your auth provider
      final actorUid = 'system-admin'; // TODO: use Provider or FirebaseAuth.currentUser.uid
      await _service.acknowledge(a.id, actorUid: actorUid);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Anomaly acknowledged')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Failed to acknowledge: $e')));
      }
    }
  }

  Future<void> _ackAllVisible() async {
    // fetch visible anomalies and ack them
    final snap = await FirebaseFirestore.instance.collection('anomalies')
      .orderBy('detectedAt', descending: true)
      .limit(_limit)
      .get();
    final actorUid = 'system-admin'; // TODO: replace
    final batch = FirebaseFirestore.instance.batch();
    for (final d in snap.docs) {
      if (d.data()['acknowledged'] == true) continue;
      batch.update(d.reference, {'acknowledged': true, 'acknowledgedBy': actorUid, 'acknowledgedAt': FieldValue.serverTimestamp()});
    }
    await batch.commit();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('All visible anomalies acknowledged')));
    }
  }

  void _openDetail(AnomalyModel a) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.7,
        builder: (context, sc) {
          return SingleChildScrollView(
            controller: sc,
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Text('${a.entityType.toUpperCase()} • ${a.entityId}', style: Theme.of(context).textTheme.headlineSmall),
                  const Spacer(),
                  Chip(label: Text(a.severity, style: const TextStyle(color: Colors.white)), backgroundColor: _severityColor(a.severity)),
                ]),
                const SizedBox(height: 12),
                Text('Score: ${a.score}', style: Theme.of(context).textTheme.bodyMedium),
                const SizedBox(height: 8),
                Text('Detected: ${DateFormat.yMd().add_jm().format(a.detectedAt.toDate())}', style: TextStyle(color: Colors.grey.shade600)),
                const SizedBox(height: 12),
                Text('Reasons:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                ...a.reasons.map((r) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Text('• $r'),
                )),
                const SizedBox(height: 12),
                Text('Recommended Action:', style: Theme.of(context).textTheme.bodySmall),
                const SizedBox(height: 6),
                Text(a.recommendedAction),
                const SizedBox(height: 12),
                if (a.sample != null) ...[
                  Text('Sample Data:', style: Theme.of(context).textTheme.bodySmall),
                  const SizedBox(height: 6),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(8)),
                    child: Text(a.sample!.entries.map((e) => '${e.key}: ${e.value}').join('\n')),
                  ),
                  const SizedBox(height: 12),
                ],
                Row(children: [
                  ElevatedButton.icon(
                    onPressed: () => _acknowledge(a),
                    icon: const Icon(Icons.check),
                    label: const Text('Acknowledge'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton.icon(
                    onPressed: () async {
                      // navigate to linked entity if you have routes e.g. /invoices/:id
                      Navigator.pop(context);
                      // TODO: implement navigation to entity detail screen
                    },
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Open Entity'),
                    style: ElevatedButton.styleFrom(backgroundColor: Colors.grey.shade200, foregroundColor: Colors.black),
                  )
                ])
              ],
            ),
          );
        },
      ),
    );
  }

  Color _severityColor(String severity) {
    switch (severity) {
      case 'critical':
        return Colors.red.shade700;
      case 'high':
        return Colors.orange.shade700;
      case 'medium':
        return Colors.amber.shade700;
      default:
        return Colors.green.shade600;
    }
  }
}
