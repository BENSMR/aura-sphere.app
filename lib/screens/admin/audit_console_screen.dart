/**
 * audit_console_screen.dart
 *
 * Admin console for viewing and filtering audit trails
 *
 * Features:
 * - Filter by entity type (invoice, expense, wallet, etc.)
 * - List recent audit index entries
 * - View full audit trail for any entity
 * - JSON display of audit entries
 * - Timestamp and actor tracking
 *
 * Access: Admin only (check isAdmin() in routes)
 */

import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';

class AuditConsoleScreen extends StatefulWidget {
  const AuditConsoleScreen({Key? key}) : super(key: key);

  @override
  State<AuditConsoleScreen> createState() => _AuditConsoleScreenState();
}

class _AuditConsoleScreenState extends State<AuditConsoleScreen> {
  final _firestore = FirebaseFirestore.instance;

  // Filter state
  String _filterEntityType = 'invoice';
  String _filterAction = ''; // empty = all actions
  final int _limit = 50;

  // Entity type options
  static const List<String> entityTypes = [
    'invoice',
    'expense',
    'purchase_order',
    'wallet',
    'payment',
    'company',
    'contact',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Audit Console'),
        elevation: 0,
        actions: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Center(
              child: Text(
                'Entity: $_filterEntityType',
                style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildFilterBar(),
          Expanded(child: _buildAuditIndexList()),
        ],
      ),
    );
  }

  /// Filter bar with entity type and action filters
  Widget _buildFilterBar() {
    return Container(
      color: Colors.grey[50],
      padding: const EdgeInsets.all(12.0),
      child: Column(
        children: [
          // Entity type dropdown
          Row(
            children: [
              const Text('Entity Type:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              DropdownButton<String>(
                value: _filterEntityType,
                items: entityTypes
                    .map((t) => DropdownMenuItem(value: t, child: Text(t)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) {
                    setState(() => _filterEntityType = v);
                  }
                },
              ),
              const Spacer(),
              ElevatedButton.icon(
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Refresh'),
                onPressed: () => setState(() {}),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Action filter
          Row(
            children: [
              const Text('Filter Action:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(width: 12),
              Expanded(
                child: TextField(
                  decoration: InputDecoration(
                    hintText: 'e.g., invoice.created, tax_applied',
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  onChanged: (v) => setState(() => _filterAction = v.trim()),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  /// List of recent audit index entries
  Widget _buildAuditIndexList() {
    var query = _firestore
        .collection('audit_index')
        .where('entityType', isEqualTo: _filterEntityType)
        .orderBy('latestAt', descending: true)
        .limit(_limit);

    return StreamBuilder<QuerySnapshot>(
      stream: query.snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Text('Error: ${snapshot.error}'),
          );
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text('No audit entries found'),
          );
        }

        final docs = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(8),
          itemCount: docs.length,
          itemBuilder: (context, idx) {
            final data = docs[idx].data() as Map<String, dynamic>;
            final entityType = data['entityType'] as String?;
            final entityId = data['entityId'] as String?;
            final action = data['summary']?['action'] as String? ?? 'unknown';
            final latestAt = data['latestAt'] as Timestamp?;
            final actorName = data['summary']?['actorName'] as String? ?? 'system';

            // Skip if action filter doesn't match
            if (_filterAction.isNotEmpty && !action.contains(_filterAction)) {
              return const SizedBox.shrink();
            }

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 4),
              child: ListTile(
                dense: false,
                leading: _iconForEntityType(entityType),
                title: Text(
                  '$entityType • $entityId',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 4),
                    Text(
                      'Action: $action',
                      style: const TextStyle(fontSize: 12),
                    ),
                    Text(
                      'By: $actorName',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    Text(
                      'At: ${_formatTime(latestAt)}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.open_in_new, size: 20),
                  onPressed: () => _viewAuditTrail(entityType ?? 'unknown', entityId ?? ''),
                ),
              ),
            );
          },
        );
      },
    );
  }

  /// View full audit trail for entity
  Future<void> _viewAuditTrail(String entityType, String entityId) async {
    final compositeId = '${entityType}_$entityId';

    try {
      final entriesSnap = await _firestore
          .collection('audit')
          .doc(compositeId)
          .collection('entries')
          .orderBy('timestamp', descending: true)
          .get();

      if (!mounted) return;

      final entries = entriesSnap.docs
          .map((doc) => {
                'id': doc.id,
                ...doc.data(),
              })
          .toList();

      _showAuditDetailDialog(entityType, entityId, entries);
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error loading audit trail: $e')),
      );
    }
  }

  /// Display audit trail in modal
  void _showAuditDetailDialog(
    String entityType,
    String entityId,
    List<Map<String, dynamic>> entries,
  ) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        insetPadding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.blue[50],
                border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Audit Trail',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '$entityType: $entityId',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
            ),
            // Entries list
            Expanded(
              child: entries.isEmpty
                  ? const Center(child: Text('No audit entries'))
                  : ListView.builder(
                      itemCount: entries.length,
                      itemBuilder: (context, idx) {
                        final entry = entries[idx];
                        return _buildAuditEntryTile(entry);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Single audit entry tile
  Widget _buildAuditEntryTile(Map<String, dynamic> entry) {
    final id = entry['id'] as String?;
    final action = entry['action'] as String? ?? 'unknown';
    final timestamp = entry['timestamp'] as Timestamp?;
    final actor = entry['actor'] as Map<String, dynamic>?;
    final source = entry['source'] as String? ?? 'unknown';
    final before = entry['before'] as Map<String, dynamic>?;
    final after = entry['after'] as Map<String, dynamic>?;
    final meta = entry['meta'] as Map<String, dynamic>?;
    final tags = entry['tags'] as List<dynamic>?;

    final actorName = actor?['name'] ??
        actor?['email'] ??
        actor?['uid'] ??
        'system';

    return ExpansionTile(
      title: Text(
        action,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
      subtitle: Text(
        '${_formatTime(timestamp)} • $actorName • $source',
        style: const TextStyle(fontSize: 12),
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: _colorForAction(action),
          borderRadius: BorderRadius.circular(4),
        ),
        child: Center(
          child: Text(
            action.split('.').first.substring(0, 1).toUpperCase(),
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 12,
            ),
          ),
        ),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tags
              if (tags?.isNotEmpty == true) ...[
                const Text('Tags:', style: TextStyle(fontWeight: FontWeight.w600)),
                Wrap(
                  spacing: 4,
                  children: (tags as List)
                      .map((tag) => Chip(label: Text(tag.toString())))
                      .toList(),
                ),
                const SizedBox(height: 12),
              ],
              // Before/After comparison
              if (before != null || after != null) ...[
                const Text('Changes:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                if (before != null) ...[
                  const Text('Before:', style: TextStyle(color: Colors.grey)),
                  _buildJsonDisplay(before),
                  const SizedBox(height: 8),
                ],
                if (after != null) ...[
                  const Text('After:', style: TextStyle(color: Colors.grey)),
                  _buildJsonDisplay(after),
                ],
                const SizedBox(height: 12),
              ],
              // Metadata
              if (meta?.isNotEmpty == true) ...[
                const Text('Metadata:', style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),
                _buildJsonDisplay(meta),
              ],
              // Entry ID
              const SizedBox(height: 12),
              Text(
                'ID: $id',
                style: const TextStyle(fontSize: 10, color: Colors.grey),
              ),
            ],
          ),
        ),
      ],
    );
  }

  /// Pretty JSON display
  Widget _buildJsonDisplay(Map<String, dynamic>? data) {
    if (data == null || data.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: SelectableText(
        _formatJson(data),
        style: const TextStyle(
          fontFamily: 'monospace',
          fontSize: 11,
        ),
      ),
    );
  }

  /// Format map as pretty JSON
  String _formatJson(Map<String, dynamic> data) {
    final buffer = StringBuffer();
    _buildJsonString(data, buffer, 0);
    return buffer.toString();
  }

  void _buildJsonString(
    Map<String, dynamic> data,
    StringBuffer buffer,
    int indent,
  ) {
    final nextPrefix = '  ' * (indent + 1);

    data.forEach((key, value) {
      buffer.write('$nextPrefix$key: ');
      if (value is Map) {
        buffer.write('{\n');
        _buildJsonString(value as Map<String, dynamic>, buffer, indent + 1);
        buffer.write('$nextPrefix}\n');
      } else if (value is List) {
        buffer.write('[\n');
        for (final item in value) {
          if (item is Map) {
            buffer.write('$nextPrefix  {...}\n');
          } else {
            buffer.write('$nextPrefix  $item\n');
          }
        }
        buffer.write('$nextPrefix]\n');
      } else {
        buffer.write('$value\n');
      }
    });
  }

  /// Format timestamp
  String _formatTime(Timestamp? ts) {
    if (ts == null) return 'unknown';
    try {
      return DateFormat('MMM dd, hh:mm a').format(ts.toDate());
    } catch (e) {
      return 'invalid';
    }
  }

  /// Icon for entity type
  Icon _iconForEntityType(String? type) {
    switch (type) {
      case 'invoice':
        return const Icon(Icons.description, color: Colors.blue);
      case 'expense':
        return const Icon(Icons.receipt, color: Colors.orange);
      case 'wallet':
        return const Icon(Icons.account_balance_wallet, color: Colors.green);
      case 'payment':
        return const Icon(Icons.payment, color: Colors.purple);
      case 'company':
        return const Icon(Icons.business, color: Colors.teal);
      case 'contact':
        return const Icon(Icons.person, color: Colors.indigo);
      default:
        return const Icon(Icons.info, color: Colors.grey);
    }
  }

  /// Color for action type
  Color _colorForAction(String action) {
    if (action.contains('created')) return Colors.green;
    if (action.contains('deleted')) return Colors.red;
    if (action.contains('status')) return Colors.orange;
    if (action.contains('tax')) return Colors.blue;
    if (action.contains('paid')) return Colors.green;
    return Colors.grey;
  }
}
