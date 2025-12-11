import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../../data/models/client_model.dart';

/// CRM Timeline Widget - Display client activity history
/// Shows events in chronological order with icons, amounts, and dates
class CRMTimelineWidget extends StatelessWidget {
  final List<TimelineEvent> events;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const CRMTimelineWidget({
    Key? key,
    required this.events,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Sort events by createdAt descending (most recent first)
    final sortedEvents = [...events]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));

    // Empty state
    if (sortedEvents.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Center(
          child: Column(
            children: [
              Icon(
                Icons.history,
                size: 48,
                color: Colors.grey.withOpacity(0.5),
              ),
              const SizedBox(height: 12),
              Text(
                'No activity yet',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ],
          ),
        ),
      );
    }

    return ListView.separated(
      shrinkWrap: shrinkWrap,
      physics: physics,
      itemCount: sortedEvents.length,
      separatorBuilder: (_, __) => const Divider(height: 1),
      itemBuilder: (context, index) {
        final event = sortedEvents[index];
        return _buildTimelineEventTile(context, event);
      },
    );
  }

  /// Build individual timeline event tile
  Widget _buildTimelineEventTile(BuildContext context, TimelineEvent event) {
    final eventInfo = _getEventInfo(event.type);
    final formattedDate = _formatEventDate(event.createdAt);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      leading: Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: eventInfo.color.withOpacity(0.15),
          border: Border.all(
            color: eventInfo.color.withOpacity(0.3),
            width: 1,
          ),
        ),
        child: Icon(
          eventInfo.icon,
          color: eventInfo.color,
          size: 20,
        ),
      ),
      title: Text(
        event.message,
        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.w500,
        ),
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        children: [
          // Amount (if applicable)
          if (event.amount > 0)
            Row(
              children: [
                Text(
                  '\$${event.amount.toStringAsFixed(2)}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 4,
                  height: 4,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.withOpacity(0.5),
                  ),
                ),
                const SizedBox(width: 8),
              ],
            ),
          // Date
          Text(
            formattedDate,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: Colors.grey,
            ),
          ),
          const SizedBox(width: 8),
          // Type badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: eventInfo.color.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: eventInfo.color.withOpacity(0.3),
              ),
            ),
            child: Text(
              eventInfo.label,
              style: TextStyle(
                fontSize: 10,
                fontWeight: FontWeight.bold,
                color: eventInfo.color,
              ),
            ),
          ),
        ],
      ),
      trailing: _buildTrailingIndicator(event.type),
    );
  }

  /// Build trailing indicator based on event type
  Widget? _buildTrailingIndicator(String type) {
    switch (type.toLowerCase()) {
      case 'payment_received':
      case 'invoice_paid':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.check_circle, color: Colors.green, size: 16),
        );
      case 'invoice_created':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.info, color: Colors.blue, size: 16),
        );
      case 'note':
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: const Icon(Icons.bookmark, color: Colors.purple, size: 16),
        );
      default:
        return null;
    }
  }

  /// Get event info (icon, color, label)
  _EventInfo _getEventInfo(String type) {
    switch (type.toLowerCase()) {
      case 'invoice_created':
        return _EventInfo(
          icon: Icons.receipt_long,
          color: Colors.blue,
          label: 'INVOICE CREATED',
        );
      case 'invoice_paid':
        return _EventInfo(
          icon: Icons.monetization_on,
          color: Colors.green,
          label: 'PAID',
        );
      case 'payment_received':
        return _EventInfo(
          icon: Icons.attach_money,
          color: Colors.green,
          label: 'PAYMENT',
        );
      case 'note':
        return _EventInfo(
          icon: Icons.note,
          color: Colors.purple,
          label: 'NOTE',
        );
      case 'interaction':
        return _EventInfo(
          icon: Icons.message,
          color: Colors.orange,
          label: 'INTERACTION',
        );
      default:
        return _EventInfo(
          icon: Icons.event,
          color: Colors.grey,
          label: 'EVENT',
        );
    }
  }

  /// Format event date (relative)
  String _formatEventDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays == 0) {
      if (difference.inHours == 0) {
        return '${difference.inMinutes}m ago';
      }
      return '${difference.inHours}h ago';
    } else if (difference.inDays == 1) {
      return 'Yesterday';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else if (difference.inDays < 30) {
      return '${(difference.inDays / 7).floor()}w ago';
    } else {
      return date.toString().split(' ')[0]; // YYYY-MM-DD format
    }
  }
}

/// Event info data class
class _EventInfo {
  final IconData icon;
  final Color color;
  final String label;

  _EventInfo({
    required this.icon,
    required this.color,
    required this.label,
  });
}

/// Legacy support for map-based events (for backward compatibility)
class LegacyTimelineWidget extends StatelessWidget {
  final List<Map<String, dynamic>> events;
  final bool shrinkWrap;
  final ScrollPhysics? physics;

  const LegacyTimelineWidget({
    Key? key,
    required this.events,
    this.shrinkWrap = true,
    this.physics = const NeverScrollableScrollPhysics(),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Convert map events to TimelineEvent objects
    final timelineEvents = events.map((e) {
      DateTime createdAt;
      if (e['createdAt'] is DateTime) {
        createdAt = e['createdAt'] as DateTime;
      } else if (e['createdAt'] is Timestamp) {
        createdAt = (e['createdAt'] as Timestamp).toDate();
      } else {
        createdAt = DateTime.tryParse(e['createdAt'].toString()) ?? DateTime.now();
      }

      return TimelineEvent(
        type: e['type'] ?? 'unknown',
        message: e['message'] ?? 'No message',
        amount: (e['amount'] ?? 0).toDouble(),
        createdAt: createdAt,
      );
    }).toList();

    return CRMTimelineWidget(
      events: timelineEvents,
      shrinkWrap: shrinkWrap,
      physics: physics,
    );
  }
}

/// Advanced Timeline with filtering and grouping
class AdvancedTimelineWidget extends StatefulWidget {
  final List<TimelineEvent> events;
  final List<String>? filterTypes; // If provided, only show these event types

  const AdvancedTimelineWidget({
    Key? key,
    required this.events,
    this.filterTypes,
  }) : super(key: key);

  @override
  State<AdvancedTimelineWidget> createState() => _AdvancedTimelineWidgetState();
}

class _AdvancedTimelineWidgetState extends State<AdvancedTimelineWidget> {
  late List<String> selectedFilters;

  @override
  void initState() {
    super.initState();
    selectedFilters = widget.filterTypes ?? [
      'invoice_created',
      'invoice_paid',
      'payment_received',
      'note',
      'interaction',
    ];
  }

  @override
  Widget build(BuildContext context) {
    // Filter events
    final filteredEvents = widget.events
        .where((e) => selectedFilters.contains(e.type.toLowerCase()))
        .toList();

    // Group events by date
    final groupedEvents = <String, List<TimelineEvent>>{};
    for (final event in filteredEvents) {
      final dateKey = event.createdAt.toString().split(' ')[0];
      groupedEvents.putIfAbsent(dateKey, () => []).add(event);
    }

    // Sort groups by date descending
    final sortedDates = groupedEvents.keys.toList()..sort((a, b) => b.compareTo(a));

    return Column(
      children: [
        // Filter chips
        if (widget.filterTypes == null)
          Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Wrap(
              spacing: 6,
              runSpacing: 4,
              children: [
                _buildFilterChip('Invoices', 'invoice_created'),
                _buildFilterChip('Payments', 'payment_received'),
                _buildFilterChip('Notes', 'note'),
              ],
            ),
          ),

        // Timeline grouped by date
        if (filteredEvents.isEmpty)
          const Padding(
            padding: EdgeInsets.all(24),
            child: Text('No events match the selected filters'),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: sortedDates.length,
            itemBuilder: (context, dateIndex) {
              final dateKey = sortedDates[dateIndex];
              final dateEvents = groupedEvents[dateKey]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Date header
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Text(
                      dateKey,
                      style: Theme.of(context).textTheme.labelMedium?.copyWith(
                        color: Colors.grey,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  // Events for this date
                  ...dateEvents.map((event) {
                    return _buildEventTile(context, event);
                  }),
                  const Divider(height: 16),
                ],
              );
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String type) {
    final isSelected = selectedFilters.contains(type);

    return FilterChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        setState(() {
          if (selected) {
            selectedFilters.add(type);
          } else {
            selectedFilters.remove(type);
          }
        });
      },
    );
  }

  Widget _buildEventTile(BuildContext context, TimelineEvent event) {
    final eventInfo = _getEventInfo(event.type);

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      leading: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: eventInfo.color.withOpacity(0.1),
        ),
        child: Icon(eventInfo.icon, color: eventInfo.color, size: 16),
      ),
      title: Text(
        event.message,
        style: Theme.of(context).textTheme.bodySmall,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Text(
        '${event.createdAt.hour}:${event.createdAt.minute.toString().padLeft(2, '0')}',
        style: Theme.of(context).textTheme.labelSmall,
      ),
      trailing: event.amount > 0
          ? Text(
        '\$${event.amount.toStringAsFixed(2)}',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: Colors.green,
          fontSize: 12,
        ),
      )
          : null,
    );
  }

  _EventInfo _getEventInfo(String type) {
    switch (type.toLowerCase()) {
      case 'invoice_created':
        return _EventInfo(
          icon: Icons.receipt_long,
          color: Colors.blue,
          label: 'INVOICE',
        );
      case 'invoice_paid':
      case 'payment_received':
        return _EventInfo(
          icon: Icons.attach_money,
          color: Colors.green,
          label: 'PAYMENT',
        );
      case 'note':
        return _EventInfo(
          icon: Icons.note,
          color: Colors.purple,
          label: 'NOTE',
        );
      case 'interaction':
        return _EventInfo(
          icon: Icons.message,
          color: Colors.orange,
          label: 'INTERACTION',
        );
      default:
        return _EventInfo(
          icon: Icons.event,
          color: Colors.grey,
          label: 'EVENT',
        );
    }
  }
}
