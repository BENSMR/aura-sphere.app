import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/timeline_event.dart';

class TimelineEventCard extends StatelessWidget {
  final TimelineEvent event;
  final VoidCallback? onTap;
  final VoidCallback? onDelete;

  const TimelineEventCard({
    Key? key,
    required this.event,
    this.onTap,
    this.onDelete,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Icon
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getTypeColor().withOpacity(0.1),
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Center(
                  child: Text(
                    event.getIcon(),
                    style: const TextStyle(fontSize: 24),
                  ),
                ),
              ),
              const SizedBox(width: 16),
              
              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title and time
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            event.title,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                        Text(
                          _formatTime(event.createdAt),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    
                    // Description
                    Text(
                      event.description,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                      ),
                    ),
                    
                    // Amount (if applicable)
                    if (event.amount != null && event.currency != null) ...[
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getTypeColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${event.currency}${event.amount!.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: _getTypeColor(),
                          ),
                        ),
                      ),
                    ],
                    
                    // AI Impact (if applicable)
                    if (event.aiImpact != null) ...[
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 4,
                        children: [
                          if (event.aiImpact!['relationshipDelta'] != 0)
                            _buildImpactChip(
                              'Relationship',
                              event.aiImpact!['relationshipDelta'] as int,
                              Colors.blue,
                            ),
                          if (event.aiImpact!['riskDelta'] != 0)
                            _buildImpactChip(
                              'Risk',
                              event.aiImpact!['riskDelta'] as int,
                              Colors.red,
                            ),
                          if (event.aiImpact!['valueDelta'] != 0)
                            _buildImpactChip(
                              'Value',
                              event.aiImpact!['valueDelta'] as int,
                              Colors.green,
                            ),
                        ],
                      ),
                    ],
                    
                    // Created by
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          _getCreatorIcon(),
                          size: 14,
                          color: Colors.grey[600],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _getCreatorLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              
              // Delete button
              if (onDelete != null)
                IconButton(
                  icon: const Icon(Icons.delete_outline, size: 20),
                  color: Colors.grey[600],
                  onPressed: onDelete,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImpactChip(String label, int delta, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            delta > 0 ? Icons.arrow_upward : Icons.arrow_downward,
            size: 12,
            color: color,
          ),
          const SizedBox(width: 2),
          Text(
            '$label ${delta.abs()}',
            style: TextStyle(
              fontSize: 11,
              color: color,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Color _getTypeColor() {
    switch (event.type) {
      case 'invoice':
        return Colors.blue;
      case 'payment':
        return Colors.green;
      case 'note':
        return Colors.orange;
      case 'task':
        return Colors.purple;
      case 'ai':
        return Colors.cyan;
      case 'system':
        return Colors.grey;
      default:
        return Colors.black;
    }
  }

  IconData _getCreatorIcon() {
    switch (event.createdBy) {
      case 'system':
        return Icons.settings;
      case 'ai':
        return Icons.smart_toy;
      default:
        return Icons.person;
    }
  }

  String _getCreatorLabel() {
    switch (event.createdBy) {
      case 'system':
        return 'System';
      case 'ai':
        return 'AI Assistant';
      default:
        return 'You';
    }
  }

  String _formatTime(DateTime time) {
    final now = DateTime.now();
    final difference = now.difference(time);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inHours < 1) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return DateFormat('MMM d, yyyy').format(time);
    }
  }
}
