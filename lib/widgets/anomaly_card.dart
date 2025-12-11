// lib/widgets/anomaly_card.dart
import 'package:flutter/material.dart';
import '../models/anomaly_model.dart';
import 'package:intl/intl.dart';

Color severityColor(String severity) {
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

String severityEmoji(String severity) {
  switch (severity) {
    case 'critical':
      return '⛔';
    case 'high':
      return '⚠️';
    case 'medium':
      return '🔔';
    default:
      return 'ℹ️';
  }
}

class AnomalyCard extends StatelessWidget {
  final AnomalyModel anomaly;
  final VoidCallback? onTap;
  final VoidCallback? onAcknowledge;

  const AnomalyCard({
    Key? key,
    required this.anomaly,
    this.onTap,
    this.onAcknowledge,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final detected = DateFormat.yMd().add_jm().format(anomaly.detectedAt.toDate());
    final color = severityColor(anomaly.severity);

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 12),
      elevation: 2,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        onTap: onTap,
        leading: CircleAvatar(
          backgroundColor: color,
          child: Text(
            severityEmoji(anomaly.severity),
            style: const TextStyle(fontSize: 18),
          ),
        ),
        title: Text('${anomaly.entityType.toUpperCase()} • ${anomaly.entityId}', maxLines: 1, overflow: TextOverflow.ellipsis),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Text('Severity: ${anomaly.severity} • Score: ${anomaly.score}'),
            const SizedBox(height: 4),
            Text(anomaly.reasons.isNotEmpty ? '${anomaly.reasons.first}' : anomaly.recommendedAction, maxLines: 2, overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text('Detected: $detected', style: TextStyle(fontSize: 12, color: Colors.grey.shade600)),
          ],
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!anomaly.acknowledged)
              ElevatedButton(
                style: ElevatedButton.styleFrom(minimumSize: const Size(90, 36)),
                onPressed: onAcknowledge,
                child: const Text('Acknowledge'),
              )
            else
              Column(
                children: [
                  const Icon(Icons.check_circle, color: Colors.green, size: 22),
                  const SizedBox(height: 4),
                  Text('Ack', style: TextStyle(fontSize: 12, color: Colors.grey.shade700)),
                ],
              )
          ],
        ),
      ),
    );
  }
}
