import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:provider/provider.dart';
import '../../data/models/client_model.dart';
import '../../providers/client_provider.dart';

/// CRM Details Screen - Display comprehensive client information
/// Shows metrics, contact info, timeline, and quick actions
class CRMDetailsScreen extends StatefulWidget {
  final String clientId;

  const CRMDetailsScreen({
    Key? key,
    required this.clientId,
  }) : super(key: key);

  @override
  State<CRMDetailsScreen> createState() => _CRMDetailsScreenState();
}

class _CRMDetailsScreenState extends State<CRMDetailsScreen> {
  final TextEditingController _noteController = TextEditingController();
  final db = FirebaseFirestore.instance;

  @override
  void dispose() {
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Client Details'),
        elevation: 0,
        actions: [
          // Edit client button
          IconButton(
            icon: const Icon(Icons.edit),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/crm/edit',
                arguments: widget.clientId,
              );
            },
            tooltip: 'Edit client',
          ),
          // Create invoice button
          IconButton(
            icon: const Icon(Icons.receipt),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/invoices/create',
                arguments: {'clientId': widget.clientId},
              );
            },
            tooltip: 'Create invoice',
          ),
          // More options menu
          PopupMenuButton(
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete client'),
              ),
              const PopupMenuItem(
                value: 'export',
                child: Text('Export data'),
              ),
            ],
            onSelected: (value) {
              if (value == 'delete') {
                _showDeleteConfirmation(context);
              } else if (value == 'export') {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Export feature coming soon')),
                );
              }
            },
          ),
        ],
      ),
      body: Consumer<ClientProvider>(
        builder: (context, clientProvider, _) {
          // Find client from already-loaded list
          final client = clientProvider.clients
              .cast<ClientModel?>(
            )
              .firstWhere(
                (c) => c?.id == widget.clientId,
                orElse: () => null,
              );

          // Loading state
          if (client == null) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await clientProvider.refreshClients();
            },
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // Header with name and badges
                _buildClientHeader(client),

                const SizedBox(height: 20),

                // AI Summary card
                _buildAISummaryCard(client),

                const SizedBox(height: 16),

                // Contact information
                _buildContactCard(client),

                const SizedBox(height: 16),

                // Key metrics
                _buildMetricsRow(client),

                const SizedBox(height: 16),

                // Timeline events
                _buildTimelineSection(client),

                const SizedBox(height: 16),

                // Quick actions
                _buildActionsRow(context),

                const SizedBox(height: 24),
              ],
            ),
          );
        },
      ),
    );
  }

  /// Build header with name, company, and status badges
  Widget _buildClientHeader(ClientModel client) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Avatar with AI score
        Stack(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: _getAIScoreColor(client.aiScore),
              child: Text(
                client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            // AI Score badge
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: _getAIScoreColor(client.aiScore),
                    width: 2,
                  ),
                ),
                child: Text(
                  '${client.aiScore}',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: _getAIScoreColor(client.aiScore),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        // Client info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                client.name,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
              ),
              const SizedBox(height: 4),
              Text(
                client.company.isNotEmpty ? client.company : 'No company',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
              const SizedBox(height: 8),
              // Status badges
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  // VIP badge
                  if (client.vipStatus)
                    _buildBadge(
                      label: 'VIP',
                      color: Colors.amber,
                      icon: Icons.star,
                    ),
                  // AI Tags
                  ...client.aiTags.map((tag) => _buildBadge(
                    label: tag.replaceAll('_', ' ').toUpperCase(),
                    color: _getTagColor(tag),
                  )),
                  // Status
                  _buildBadge(
                    label: client.status.toUpperCase(),
                    color: _getStatusColor(client.status),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Lifetime value
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              '\$${client.lifetimeValue.toStringAsFixed(2)}',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: Colors.green,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${client.totalInvoices} invoices',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ],
    );
  }

  /// Build AI summary card
  Widget _buildAISummaryCard(ClientModel client) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.lightbulb_outline, color: Colors.amber),
                const SizedBox(width: 8),
                const Text(
                  'AI Summary',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (client.aiSummary.isNotEmpty)
              Text(
                client.aiSummary,
                style: Theme.of(context).textTheme.bodyMedium,
              )
            else
              Text(
                'No summary available yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            const SizedBox(height: 12),
            // Sentiment
            Row(
              children: [
                Text(
                  'Sentiment: ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getSentimentColor(client.sentiment).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getSentimentColor(client.sentiment),
                    ),
                  ),
                  child: Text(
                    client.sentiment.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _getSentimentColor(client.sentiment),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                // Stability
                Text(
                  'Stability: ',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _getStabilityColor(client.stabilityLevel).withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _getStabilityColor(client.stabilityLevel),
                    ),
                  ),
                  child: Text(
                    client.stabilityLevel.toUpperCase(),
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: _getStabilityColor(client.stabilityLevel),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  /// Build contact information card
  Widget _buildContactCard(ClientModel client) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Contact Information',
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
            ),
            const SizedBox(height: 12),
            // Email
            _buildContactRow(
              icon: Icons.email,
              label: 'Email',
              value: client.email.isNotEmpty ? client.email : '—',
              onTap: client.email.isNotEmpty
                  ? () => _launchEmail(client.email)
                  : null,
            ),
            const SizedBox(height: 8),
            // Phone
            _buildContactRow(
              icon: Icons.phone,
              label: 'Phone',
              value: client.phone.isNotEmpty ? client.phone : '—',
              onTap: client.phone.isNotEmpty
                  ? () => _launchPhone(client.phone)
                  : null,
            ),
            const SizedBox(height: 8),
            // Address
            _buildContactRow(
              icon: Icons.location_on,
              label: 'Address',
              value: client.address.isNotEmpty ? client.address : '—',
            ),
            const SizedBox(height: 8),
            // Country
            _buildContactRow(
              icon: Icons.public,
              label: 'Country',
              value: client.country.isNotEmpty ? client.country : '—',
            ),
          ],
        ),
      ),
    );
  }

  /// Build contact row
  Widget _buildContactRow({
    required IconData icon,
    required String label,
    required String value,
    VoidCallback? onTap,
  }) {
    return InkWell(
      onTap: onTap,
      child: Row(
        children: [
          Icon(icon, size: 20, color: Colors.grey),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey,
                      ),
                ),
                Text(
                  value,
                  style: Theme.of(context).textTheme.bodyMedium,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          if (onTap != null)
            const Icon(Icons.chevron_right, size: 20, color: Colors.grey),
        ],
      ),
    );
  }

  /// Build key metrics row
  Widget _buildMetricsRow(ClientModel client) {
    return Row(
      children: [
        _buildMetricCard(
          title: 'Churn Risk',
          value: '${client.churnRisk}%',
          color: _getChurnRiskColor(client.churnRisk),
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          title: 'Last Invoice',
          value: client.lastInvoiceAmount > 0
              ? '\$${client.lastInvoiceAmount.toStringAsFixed(2)}'
              : '—',
          color: Colors.blue,
        ),
        const SizedBox(width: 8),
        _buildMetricCard(
          title: 'Last Activity',
          value: client.lastActivityAt != null
              ? _formatDate(client.lastActivityAt!)
              : '—',
          color: Colors.purple,
        ),
      ],
    );
  }

  /// Build single metric card
  Widget _buildMetricCard({
    required String title,
    required String value,
    required Color color,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(8),
          color: color.withOpacity(0.1),
          border: Border.all(color: color, width: 1),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 16,
                color: color,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              title,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Colors.grey,
                  ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  /// Build timeline section
  Widget _buildTimelineSection(ClientModel client) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Activity Timeline',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
        ),
        const SizedBox(height: 12),
        if (client.timeline.isEmpty)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'No activity yet',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Colors.grey,
                    ),
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: client.timeline.length,
            separatorBuilder: (_, __) => const SizedBox(height: 8),
            itemBuilder: (context, index) {
              final event = client.timeline[index];
              return _buildTimelineEvent(event);
            },
          ),
      ],
    );
  }

  /// Build single timeline event
  Widget _buildTimelineEvent(dynamic event) {
    final type = event.type ?? 'unknown';
    final message = event.message ?? '';
    final amount = event.amount ?? 0.0;
    final createdAt = event.createdAt;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(8),
        color: Colors.grey.withOpacity(0.1),
      ),
      child: Row(
        children: [
          // Event icon
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getEventTypeColor(type).withOpacity(0.2),
            ),
            child: Icon(
              _getEventTypeIcon(type),
              color: _getEventTypeColor(type),
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          // Event details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Text(
                      _formatDate(createdAt),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: Colors.grey,
                          ),
                    ),
                    if (amount > 0) ...[
                      const SizedBox(width: 8),
                      Text(
                        '\$${amount.toStringAsFixed(2)}',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build actions row
  Widget _buildActionsRow(BuildContext context) {
    return Row(
      children: [
        // Email button
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.email),
            label: const Text('Email'),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Opening email client...')),
              );
            },
          ),
        ),
        const SizedBox(width: 8),
        // Add note button
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.note_add),
            label: const Text('Add Note'),
            onPressed: () => _showAddNoteDialog(),
          ),
        ),
      ],
    );
  }

  /// Show add note dialog
  void _showAddNoteDialog() {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: _noteController,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Enter your note...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final note = _noteController.text.trim();
              if (note.isEmpty) return;

              try {
                await db
                    .collection('users')
                    .doc(context.read<ClientProvider>().currentUserId)
                    .collection('clients')
                    .doc(widget.clientId)
                    .update({
                  'timeline.events': FieldValue.arrayUnion([
                    {
                      'type': 'note',
                      'message': note,
                      'amount': 0,
                      'createdAt': Timestamp.now(),
                    }
                  ]),
                  'lastActivityAt': Timestamp.now(),
                  'updatedAt': Timestamp.now(),
                });

                _noteController.clear();
                if (mounted) {
                  Navigator.pop(ctx);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Note added')),
                  );
                  // Refresh clients
                  context.read<ClientProvider>().refreshClients();
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  /// Show delete confirmation
  void _showDeleteConfirmation(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Client'),
        content: const Text('Are you sure? This cannot be undone.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              try {
                await context.read<ClientProvider>().deleteClient(widget.clientId);
                if (mounted) {
                  Navigator.pop(ctx);
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Client deleted')),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  /// Launch email
  void _launchEmail(String email) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Compose email to $email')),
    );
  }

  /// Launch phone
  void _launchPhone(String phone) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Call $phone')),
    );
  }

  /// Format date
  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);

    if (diff.inDays == 0) {
      return 'Today';
    } else if (diff.inDays == 1) {
      return 'Yesterday';
    } else if (diff.inDays < 7) {
      return '${diff.inDays} days ago';
    } else {
      return date.toString().split(' ')[0];
    }
  }

  // ===== COLOR GETTERS =====

  Color _getAIScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  Color _getChurnRiskColor(int risk) {
    if (risk <= 20) return Colors.green;
    if (risk <= 50) return Colors.orange;
    return Colors.red;
  }

  Color _getTagColor(String tag) {
    switch (tag.toUpperCase()) {
      case 'VIP':
        return Colors.amber;
      case 'AT_RISK':
        return Colors.red;
      case 'RETURNING':
        return Colors.green;
      case 'NEW':
        return Colors.blue;
      case 'DORMANT':
        return Colors.grey;
      case 'HIGH_VALUE':
        return Colors.green;
      case 'NEGATIVE_SENTIMENT':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'lead':
        return Colors.blue;
      case 'vip':
        return Colors.amber;
      case 'lost':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  Color _getSentimentColor(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Colors.green;
      case 'negative':
        return Colors.red;
      case 'neutral':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Color _getStabilityColor(String level) {
    switch (level.toLowerCase()) {
      case 'stable':
        return Colors.green;
      case 'unstable':
        return Colors.orange;
      case 'risky':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getEventTypeIcon(String type) {
    switch (type.toLowerCase()) {
      case 'invoice_created':
      case 'invoice_paid':
        return Icons.receipt;
      case 'payment_received':
        return Icons.attach_money;
      case 'note':
        return Icons.note;
      case 'interaction':
        return Icons.message;
      default:
        return Icons.event;
    }
  }

  Color _getEventTypeColor(String type) {
    switch (type.toLowerCase()) {
      case 'invoice_created':
        return Colors.blue;
      case 'invoice_paid':
      case 'payment_received':
        return Colors.green;
      case 'note':
        return Colors.purple;
      case 'interaction':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }
}

/// Build badge widget
Widget _buildBadge({
  required String label,
  required Color color,
  IconData? icon,
}) {
  return Container(
    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
    decoration: BoxDecoration(
      color: color.withOpacity(0.2),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: color, width: 0.5),
    ),
    child: Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 4),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    ),
  );
}
