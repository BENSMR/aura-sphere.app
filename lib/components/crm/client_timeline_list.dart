import 'package:flutter/material.dart';
import '../../models/timeline_event.dart';
import '../../services/timeline_service.dart';
import 'timeline_event_card.dart';

class ClientTimelineList extends StatefulWidget {
  final String clientId;
  final String? filterType;
  final int? recentDays;

  const ClientTimelineList({
    Key? key,
    required this.clientId,
    this.filterType,
    this.recentDays,
  }) : super(key: key);

  @override
  State<ClientTimelineList> createState() => _ClientTimelineListState();
}

class _ClientTimelineListState extends State<ClientTimelineList> {
  final TimelineService _timelineService = TimelineService();
  String? _selectedFilter;

  @override
  void initState() {
    super.initState();
    _selectedFilter = widget.filterType;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Filter chips
        _buildFilterChips(),
        const SizedBox(height: 8),
        
        // Timeline list
        Expanded(
          child: StreamBuilder<List<TimelineEvent>>(
            stream: _getTimelineStream(),
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
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: () => setState(() {}),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                );
              }

              final events = snapshot.data ?? [];

              if (events.isEmpty) {
                return Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.timeline_outlined,
                        size: 64,
                        color: Colors.grey[400],
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No timeline events yet',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Events will appear here as you interact with this client',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: events.length,
                itemBuilder: (context, index) {
                  final event = events[index];
                  return TimelineEventCard(
                    event: event,
                    onTap: () => _handleEventTap(event),
                    onDelete: event.createdBy != 'system' && event.createdBy != 'ai'
                        ? () => _handleDeleteEvent(event)
                        : null,
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildFilterChips() {
    final filters = [
      {'label': 'All', 'value': null, 'icon': Icons.all_inclusive},
      {'label': 'Invoices', 'value': 'invoice', 'icon': Icons.description},
      {'label': 'Payments', 'value': 'payment', 'icon': Icons.payment},
      {'label': 'Notes', 'value': 'note', 'icon': Icons.note},
      {'label': 'Tasks', 'value': 'task', 'icon': Icons.task},
      {'label': 'AI', 'value': 'ai', 'icon': Icons.smart_toy},
      {'label': 'System', 'value': 'system', 'icon': Icons.settings},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: filters.map((filter) {
          final isSelected = _selectedFilter == filter['value'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    filter['icon'] as IconData,
                    size: 16,
                    color: isSelected ? Colors.white : Colors.grey[700],
                  ),
                  const SizedBox(width: 4),
                  Text(filter['label'] as String),
                ],
              ),
              selected: isSelected,
              onSelected: (selected) {
                setState(() {
                  _selectedFilter = selected ? filter['value'] as String? : null;
                });
              },
              selectedColor: Theme.of(context).primaryColor,
              labelStyle: TextStyle(
                color: isSelected ? Colors.white : Colors.grey[700],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Stream<List<TimelineEvent>> _getTimelineStream() {
    if (_selectedFilter != null) {
      return _timelineService.getTimelineEventsByType(
        widget.clientId,
        _selectedFilter!,
      );
    } else if (widget.recentDays != null) {
      return _timelineService.getRecentTimelineEvents(
        widget.clientId,
        days: widget.recentDays!,
      );
    } else {
      return _timelineService.getTimelineEvents(widget.clientId);
    }
  }

  void _handleEventTap(TimelineEvent event) {
    // Navigate to source if available
    if (event.sourceId != null) {
      switch (event.type) {
        case 'invoice':
          Navigator.pushNamed(
            context,
            '/invoice/details',
            arguments: {'invoiceId': event.sourceId},
          );
          break;
        case 'payment':
          Navigator.pushNamed(
            context,
            '/invoice/details',
            arguments: {'invoiceId': event.sourceId},
          );
          break;
        default:
          _showEventDetails(event);
      }
    } else {
      _showEventDetails(event);
    }
  }

  void _showEventDetails(TimelineEvent event) {
    showModalBottomSheet(
      context: context,
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(
                  event.getIcon(),
                  style: const TextStyle(fontSize: 32),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    event.title,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Text(
              event.description,
              style: const TextStyle(fontSize: 16),
            ),
            if (event.amount != null && event.currency != null) ...[
              const SizedBox(height: 16),
              Text(
                'Amount: ${event.currency}${event.amount!.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            Text(
              'Created: ${event.createdAt.toString().split('.')[0]}',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Close'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _handleDeleteEvent(TimelineEvent event) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Event'),
        content: Text('Are you sure you want to delete "${event.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(context);
              try {
                await _timelineService.deleteTimelineEvent(
                  widget.clientId,
                  event.id,
                );
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Event deleted')),
                  );
                }
              } catch (e) {
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error deleting event: $e')),
                  );
                }
              }
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
