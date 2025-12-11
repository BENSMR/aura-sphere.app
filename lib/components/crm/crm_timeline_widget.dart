import 'package:flutter/material.dart';
import '../../services/timeline_service.dart';
import '../../models/timeline_event.dart';

class CRMTimelineWidget extends StatelessWidget {
  final String userId;
  final String clientId;

  const CRMTimelineWidget({
    super.key,
    required this.userId,
    required this.clientId,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<TimelineEvent>>(
      stream: TimelineService.streamTimelineForUser(userId, clientId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.error_outline, size: 48, color: Colors.red),
                const SizedBox(height: 16),
                Text('Error: ${snapshot.error}'),
              ],
            ),
          );
        }

        final events = snapshot.data ?? [];
        if (events.isEmpty) {
          return const Center(child: Text("No activity yet."));
        }

        return ListView.builder(
          itemCount: events.length,
          itemBuilder: (_, i) {
            final e = events[i];
            return ListTile(
              leading: Icon(
                _getIconForType(e.type),
                color: _getColorForType(e.type),
              ),
              title: Text(e.title),
              subtitle: Text(e.description),
              trailing: e.amount != null && e.currency != null
                  ? Text(
                      '${e.currency}${e.amount!.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    )
                  : null,
            );
          },
        );
      },
    );
  }

  IconData _getIconForType(String type) {
    switch (type) {
      case 'ai':
        return Icons.psychology;
      case 'payment':
        return Icons.attach_money;
      case 'invoice':
        return Icons.receipt;
      case 'note':
        return Icons.note;
      case 'task':
        return Icons.task_alt;
      case 'system':
        return Icons.settings;
      default:
        return Icons.circle;
    }
  }

  Color _getColorForType(String type) {
    switch (type) {
      case 'ai':
        return Colors.cyan;
      case 'payment':
        return Colors.green;
      case 'invoice':
        return Colors.blue;
      case 'note':
        return Colors.orange;
      case 'task':
        return Colors.purple;
      case 'system':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }
}
