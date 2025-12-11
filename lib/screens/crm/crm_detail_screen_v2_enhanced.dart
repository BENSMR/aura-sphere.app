import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// CRM Detail Screen V2 - Enhanced
///
/// Complete client detail view with:
/// - Client header with avatar and AI score badge
/// - Stats section (invoices, lifetime value, AI score)
/// - AI insights (churn risk, last activity, VIP status, tags)
/// - Timeline with 8 most recent events
/// - Action buttons (create invoice, add note)
/// - Edit/delete capabilities
class CRMDetailScreenV2 extends StatelessWidget {
  final String clientId;

  const CRMDetailScreenV2({super.key, required this.clientId});

  /// Get current user ID from Firebase Auth
  String getUserId() {
    return FirebaseAuth.instance.currentUser?.uid ?? 'CURRENT_USER_ID';
  }

  @override
  Widget build(BuildContext context) {
    final userId = getUserId();

    final clientRef = FirebaseFirestore.instance
        .collection("users")
        .doc(userId)
        .collection("clients")
        .doc(clientId);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Client Details"),
        elevation: 0,
        actions: [
          IconButton(
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/crm/edit',
                arguments: clientId,
              );
            },
            icon: const Icon(Icons.edit),
            tooltip: 'Edit Client',
          ),
          PopupMenuButton(
            itemBuilder: (ctx) => [
              PopupMenuItem(
                child: const Row(
                  children: [
                    Icon(Icons.delete, size: 18, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Delete', style: TextStyle(color: Colors.red)),
                  ],
                ),
                onTap: () async {
                  final confirmed = await showDialog<bool>(
                    context: context,
                    builder: (dialogCtx) => AlertDialog(
                      title: const Text('Delete Client?'),
                      content: const Text(
                        'This action cannot be undone.',
                      ),
                      actions: [
                        TextButton(
                          onPressed: () =>
                              Navigator.pop(dialogCtx, false),
                          child: const Text('Cancel'),
                        ),
                        ElevatedButton(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.red,
                          ),
                          onPressed: () =>
                              Navigator.pop(dialogCtx, true),
                          child: const Text('Delete'),
                        ),
                      ],
                    ),
                  );

                  if (confirmed == true && context.mounted) {
                    try {
                      await clientRef.delete();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Client deleted'),
                          backgroundColor: Colors.green,
                        ),
                      );
                      Navigator.pop(context);
                    } catch (e) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Error: $e'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
              ),
            ],
          ),
        ],
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: clientRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.data!.exists) {
            return const Center(child: Text("Client not found"));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _headerSection(data),
                const SizedBox(height: 20),
                _statsSection(data),
                const SizedBox(height: 20),
                _aiInsights(data),
                const SizedBox(height: 25),
                _timelineSection(data),
                const SizedBox(height: 16),
                _actionButtons(context, userId),
                const SizedBox(height: 30),
              ],
            ),
          );
        },
      ),
    );
  }

  /// ----------------------------------------------------------
  /// SECTION 1 — CLIENT HEADER
  /// ----------------------------------------------------------
  Widget _headerSection(Map<String, dynamic> data) {
    final name = data["name"] ?? "Unknown Client";
    final company = data["company"] ?? "";
    final email = data["email"] ?? "";
    final aiScore = data["aiScore"] ?? 0;
    
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 45,
              backgroundColor: _getScoreColor(aiScore),
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : "?",
                style: const TextStyle(
                  fontSize: 40,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            Positioned(
              bottom: 0,
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: _getScoreColor(aiScore), width: 2),
                ),
                child: Text(
                  '$aiScore',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                    color: _getScoreColor(aiScore),
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Text(
          name,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        if (company.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            company,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade700,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
        if (email.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.email, size: 16, color: Colors.blue),
              const SizedBox(width: 6),
              Text(
                email,
                style: const TextStyle(fontSize: 12, color: Colors.blue),
              ),
            ],
          ),
        ],
      ],
    );
  }

  /// ----------------------------------------------------------
  /// SECTION 2 — CLIENT STATS
  /// ----------------------------------------------------------
  Widget _statsSection(Map<String, dynamic> data) {
    final totalInvoices = data["totalInvoices"] ?? 0;
    final lifetimeValue = (data["lifetimeValue"] ?? 0).toDouble();
    final aiScore = data["aiScore"] ?? 0;
    
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceAround,
      children: [
        _statBox(
          "Invoices",
          totalInvoices.toString(),
          Icons.description,
          Colors.blue,
        ),
        _statBox(
          "Lifetime",
          "€${lifetimeValue.toStringAsFixed(0)}",
          Icons.euro,
          Colors.green,
        ),
        _statBox(
          "AI Score",
          aiScore.toString(),
          Icons.auto_awesome,
          _getScoreColor(aiScore),
        ),
      ],
    );
  }

  Widget _statBox(
    String title,
    dynamic value,
    IconData icon,
    Color color,
  ) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 28, color: color),
        ),
        const SizedBox(height: 8),
        Text(
          value.toString(),
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          title,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// ----------------------------------------------------------
  /// SECTION 3 — AI INSIGHTS
  /// ----------------------------------------------------------
  Widget _aiInsights(Map<String, dynamic> data) {
    final churnRisk = data["churnRisk"] ?? 0;
    final lastActivityAt = data["lastActivityAt"];
    final lastActivity = lastActivityAt != null
        ? DateFormat("dd MMM yyyy").format(
            (lastActivityAt as Timestamp).toDate(),
          )
        : "Never";
    final vipStatus = data["vipStatus"] ?? false;
    final aiTags = (data["aiTags"] as List<dynamic>? ?? [])
        .cast<String>()
        .take(3)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "AI Insights",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        // CHURN widget
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardStyle(),
          child: Row(
            children: [
              Icon(
                Icons.warning_amber_rounded,
                color: _getChurnColor(churnRisk),
                size: 28,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Churn Risk",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "$churnRisk%",
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // ACTIVITY widget
        Container(
          padding: const EdgeInsets.all(16),
          decoration: _cardStyle(),
          child: Row(
            children: [
              const Icon(Icons.timeline, color: Colors.blue, size: 28),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Last Activity",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      lastActivity,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 10),

        // VIP widget
        if (vipStatus)
          Container(
            padding: const EdgeInsets.all(16),
            decoration: _cardVIP(),
            child: const Row(
              children: [
                Icon(Icons.star, color: Colors.amber, size: 32),
                SizedBox(width: 12),
                Text(
                  "VIP Client",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.amber,
                  ),
                )
              ],
            ),
          ),

        if (aiTags.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: _cardStyle(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Tags",
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: aiTags
                      .map(
                        (tag) => Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: _getTagColor(tag).withOpacity(0.2),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: _getTagColor(tag),
                              width: 0.5,
                            ),
                          ),
                          child: Text(
                            tag,
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w500,
                              color: _getTagColor(tag),
                            ),
                          ),
                        ),
                      )
                      .toList(),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  /// ----------------------------------------------------------
  /// SECTION 4 — TIMELINE
  /// ----------------------------------------------------------
  Widget _timelineSection(Map<String, dynamic> data) {
    final timeline = (data["timeline"] as List<dynamic>? ?? [])
        .cast<Map<String, dynamic>>()
        .take(8)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          "Timeline",
          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),

        if (timeline.isEmpty)
          Container(
            padding: const EdgeInsets.all(24),
            decoration: _cardStyle(),
            child: const Center(
              child: Text(
                "No activity yet",
                style: TextStyle(color: Colors.grey, fontSize: 14),
              ),
            ),
          )
        else
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: timeline.length,
            itemBuilder: (context, index) {
              return _timelineItem(timeline[index], index == timeline.length - 1);
            },
          )
      ],
    );
  }

  Widget _timelineItem(Map<String, dynamic> item, bool isLast) {
    final createdAt = item["createdAt"];
    final formattedDate = createdAt != null
        ? DateFormat("dd MMM, HH:mm").format(
            (createdAt as Timestamp).toDate(),
          )
        : "-";

    final eventType = item["eventType"] ?? item["type"] ?? "event";
    final description = item["description"] ?? item["message"] ?? "";

    IconData icon;
    Color color;

    switch (eventType.toString().toUpperCase()) {
      case "INVOICE_CREATED":
        icon = Icons.description_outlined;
        color = Colors.blue;
        break;
      case "INVOICE_PAID":
        icon = Icons.check_circle_outline;
        color = Colors.green;
        break;
      case "INVOICE_OVERDUE":
        icon = Icons.warning_outlined;
        color = Colors.red;
        break;
      case "NOTE":
        icon = Icons.note_outlined;
        color = Colors.purple;
        break;
      case "PAYMENT_RECEIVED":
        icon = Icons.account_balance_wallet;
        color = Colors.green;
        break;
      case "EMAIL_SENT":
        icon = Icons.mail_outline;
        color = Colors.blue;
        break;
      default:
        icon = Icons.info_outline;
        color = Colors.grey;
    }

    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 10),
      padding: const EdgeInsets.all(14),
      decoration: _cardStyle(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 26),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _formatEventType(eventType),
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (description.isNotEmpty) ...[
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            formattedDate,
            style: const TextStyle(
              color: Colors.grey,
              fontSize: 11,
            ),
            textAlign: TextAlign.right,
          ),
        ],
      ),
    );
  }

  /// ----------------------------------------------------------
  /// SECTION 5 — ACTION BUTTONS
  /// ----------------------------------------------------------
  Widget _actionButtons(BuildContext context, String userId) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            icon: const Icon(Icons.add_circle),
            label: const Text('Create Invoice'),
            onPressed: () {
              Navigator.pushNamed(
                context,
                '/invoices/create',
                arguments: clientId,
              );
            },
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            icon: const Icon(Icons.note_add),
            label: const Text('Add Note'),
            onPressed: () {
              _showAddNoteDialog(context, userId);
            },
          ),
        ),
      ],
    );
  }

  /// Show add note dialog
  void _showAddNoteDialog(BuildContext context, String userId) {
    final noteController = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add Note'),
        content: TextField(
          controller: noteController,
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
              if (noteController.text.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Please enter a note')),
                );
                return;
              }

              try {
                final clientRef = FirebaseFirestore.instance
                    .collection("users")
                    .doc(userId)
                    .collection("clients")
                    .doc(clientId);

                await clientRef.update({
                  'timeline': FieldValue.arrayUnion([
                    {
                      'eventType': 'NOTE',
                      'description': noteController.text,
                      'createdAt': Timestamp.now(),
                    }
                  ]),
                });

                if (ctx.mounted) Navigator.pop(ctx);
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Note added'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('Error: $e'),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            child: const Text('Add Note'),
          ),
        ],
      ),
    );
  }

  /// ----------------------------------------------------------
  /// STYLING HELPERS
  /// ----------------------------------------------------------
  BoxDecoration _cardStyle() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.grey.withOpacity(0.2)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.05),
          blurRadius: 4,
          offset: const Offset(0, 2),
        )
      ],
    );
  }

  BoxDecoration _cardVIP() {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: [Colors.amber.shade100, Colors.orange.shade100],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: Colors.amber.shade300),
      boxShadow: [
        BoxShadow(
          color: Colors.amber.withOpacity(0.2),
          blurRadius: 6,
          offset: const Offset(0, 3),
        )
      ],
    );
  }

  /// Get score color based on AI score
  Color _getScoreColor(int score) {
    if (score >= 80) return Colors.green;
    if (score >= 60) return Colors.blue;
    if (score >= 40) return Colors.orange;
    return Colors.red;
  }

  /// Get churn color based on risk percentage
  Color _getChurnColor(int risk) {
    if (risk <= 20) return Colors.green;
    if (risk <= 50) return Colors.orange;
    return Colors.red;
  }

  /// Get tag color
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

  /// Format event type for display
  String _formatEventType(String eventType) {
    return eventType
        .replaceAll('_', ' ')
        .split(' ')
        .map((word) => word[0].toUpperCase() + word.substring(1).toLowerCase())
        .join(' ');
  }
}
