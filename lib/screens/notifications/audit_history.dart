// lib/screens/notifications/audit_history.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';
import 'dart:convert';
import '../../services/notification_audit_service.dart';

class NotificationAuditHistoryScreen extends StatefulWidget {
  const NotificationAuditHistoryScreen({Key? key}) : super(key: key);

  @override
  State<NotificationAuditHistoryScreen> createState() => _NotificationAuditHistoryScreenState();
}

class _NotificationAuditHistoryScreenState extends State<NotificationAuditHistoryScreen> {
  final _auth = FirebaseAuth.instance;
  final _auditService = NotificationAuditService();
  final DateFormat _fmt = DateFormat('yyyy-MM-dd HH:mm');

  @override
  Widget build(BuildContext context) {
    final user = _auth.currentUser;
    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Notification Audit')),
        body: const Center(child: Text('Please sign in to view your notification audit.')),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Notification Audit')),
      body: StreamBuilder<List<Map<String, dynamic>>>(
        stream: _auditService.streamAuditForUser(user.uid),
        builder: (context, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snap.hasData || snap.data!.isEmpty) {
            return const Center(child: Text('No notification audit entries found.'));
          }

          final entries = snap.data!;
          return ListView.separated(
            padding: const EdgeInsets.all(12),
            itemCount: entries.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, i) {
              final e = entries[i];
              final status = (e['status'] ?? 'unknown').toString();
              final type = (e['type'] ?? 'event').toString();
              final eventId = e['eventId']?.toString() ?? '-';
              final reason = e['reason']?.toString() ?? e['meta']?.toString() ?? '';
              final createdAt = e['createdAtParsed'] as DateTime?;
              final createdStr = createdAt != null ? _fmt.format(createdAt) : '—';

              Color statusColor;
              switch (status) {
                case 'sent':
                  statusColor = Colors.green;
                  break;
                case 'failed':
                  statusColor = Colors.red;
                  break;
                case 'skipped':
                  statusColor = Colors.orange;
                  break;
                default:
                  statusColor = Colors.grey;
              }

              return Card(
                elevation: 2,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: statusColor,
                    child: Text(status[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                  ),
                  title: Text('$type • $eventId', style: const TextStyle(fontWeight: FontWeight.w600)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 6),
                      Text(reason.isNotEmpty ? reason : 'No extra details', maxLines: 2, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Text(createdStr, style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          const SizedBox(width: 12),
                          Text('status: $status', style: TextStyle(fontSize: 12, color: statusColor)),
                        ],
                      )
                    ],
                  ),
                  isThreeLine: true,
                  trailing: IconButton(
                    icon: const Icon(Icons.open_in_new),
                    onPressed: () => _showDetailsDialog(context, e),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _showDetailsDialog(BuildContext context, Map<String, dynamic> entry) {
    final pretty = const JsonEncoder.withIndent('  ').convert(entry);
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Audit entry details'),
        content: SingleChildScrollView(child: SelectableText(pretty)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text('Close'))
        ],
      ),
    );
  }
}
