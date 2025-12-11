import 'package:flutter/material.dart';
import '../../data/models/client_model.dart';

/// CRM Interactive AI Summary Widget
/// Displays AI-generated client summary with metrics and suggested actions
class CRMInteractiveAISummary extends StatelessWidget {
  final ClientModel client;
  final VoidCallback? onSendEmail;
  final VoidCallback? onTakeSuggestedAction;

  const CRMInteractiveAISummary({
    Key? key,
    required this.client,
    this.onSendEmail,
    this.onTakeSuggestedAction,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header with title and AI icon
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.amber.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.lightbulb,
                    color: Colors.amber,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text(
                    'AI Summary',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            // AI Summary text
            _buildSummarySection(context),

            const SizedBox(height: 16),

            // Key metrics row
            _buildMetricsRow(context),

            const SizedBox(height: 16),

            // Sentiment and Stability
            _buildSentimentAndStability(context),

            const SizedBox(height: 16),

            // Action buttons
            _buildActionButtons(context),
          ],
        ),
      ),
    );
  }

  /// Build summary section
  Widget _buildSummarySection(BuildContext context) {
    final hasAISummary = client.aiSummary.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: Colors.grey.withOpacity(0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!hasAISummary)
            Text(
              'AI summary is being generated...',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: Colors.grey,
                    fontStyle: FontStyle.italic,
                  ),
            )
          else
            Text(
              client.aiSummary,
              style: Theme.of(context).textTheme.bodyMedium,
            ),
        ],
      ),
    );
  }

  /// Build metrics row (AI Score, Churn Risk, Total Invoices)
  Widget _buildMetricsRow(BuildContext context) {
    return Row(
      children: [
        // AI Score metric
        Expanded(
          child: _buildMetricCard(
            label: 'AI Score',
            value: '${client.aiScore}',
            unit: '/100',
            color: _getAIScoreColor(client.aiScore),
          ),
        ),
        const SizedBox(width: 8),
        // Churn Risk metric
        Expanded(
          child: _buildMetricCard(
            label: 'Churn Risk',
            value: '${client.churnRisk}',
            unit: '%',
            color: _getChurnRiskColor(client.churnRisk),
          ),
        ),
        const SizedBox(width: 8),
        // Total Invoices metric
        Expanded(
          child: _buildMetricCard(
            label: 'Invoices',
            value: '${client.totalInvoices}',
            unit: '',
            color: Colors.blue,
          ),
        ),
      ],
    );
  }

  /// Build individual metric card
  Widget _buildMetricCard({
    required String label,
    required String value,
    required String unit,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          RichText(
            text: TextSpan(
              children: [
                TextSpan(
                  text: value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: color,
                  ),
                ),
                TextSpan(
                  text: unit,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: color.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: const TextStyle(
              fontSize: 11,
              color: Colors.grey,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  /// Build sentiment and stability row
  Widget _buildSentimentAndStability(BuildContext context) {
    return Row(
      children: [
        // Sentiment
        Expanded(
          child: _buildStatusBadge(
            label: 'Sentiment',
            value: client.sentiment.toUpperCase(),
            color: _getSentimentColor(client.sentiment),
            icon: _getSentimentIcon(client.sentiment),
          ),
        ),
        const SizedBox(width: 8),
        // Stability
        Expanded(
          child: _buildStatusBadge(
            label: 'Stability',
            value: client.stabilityLevel.toUpperCase(),
            color: _getStabilityColor(client.stabilityLevel),
            icon: _getStabilityIcon(client.stabilityLevel),
          ),
        ),
      ],
    );
  }

  /// Build status badge
  Widget _buildStatusBadge({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(fontSize: 10, color: Colors.grey),
                ),
                Text(
                  value,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: color,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build action buttons
  Widget _buildActionButtons(BuildContext context) {
    final suggestedAction = _generateSuggestedAction();

    return Row(
      children: [
        // Send Email Nudge button
        Expanded(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.email, size: 18),
            label: const Text('Send Nudge'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _showEmailDialog(context),
          ),
        ),
        const SizedBox(width: 8),
        // Suggested Action button
        Expanded(
          child: OutlinedButton.icon(
            icon: const Icon(Icons.lightbulb_outline, size: 18),
            label: const Text('Action'),
            style: OutlinedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
            onPressed: () => _showActionDialog(context, suggestedAction),
          ),
        ),
      ],
    );
  }

  /// Show email dialog
  void _showEmailDialog(BuildContext context) {
    final email = _buildSuggestedEmail();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send Email Nudge'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'To: ${client.email}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.grey.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  email,
                  style: const TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.send, size: 16),
            label: const Text('Send'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email sent successfully')),
              );
              onSendEmail?.call();
            },
          ),
        ],
      ),
    );
  }

  /// Show action dialog
  void _showActionDialog(BuildContext context, String action) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Recommended Action'),
        content: Text(action),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Dismiss'),
          ),
          ElevatedButton.icon(
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Take Action'),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Action logged')),
              );
              onTakeSuggestedAction?.call();
            },
          ),
        ],
      ),
    );
  }

  /// Build suggested email
  String _buildSuggestedEmail() {
    final name = client.name;
    final hasInvoices = client.totalInvoices > 0;
    final lastInvoiceInfo = client.lastInvoiceAmount > 0
        ? 'your recent invoice (\$${client.lastInvoiceAmount.toStringAsFixed(2)})'
        : 'your recent activity';

    if (client.churnRisk > 70) {
      // High churn risk - urgency needed
      return '''Hi $name,

I hope this message finds you well. I wanted to reach out personally regarding $lastInvoiceInfo.

We value your business and want to ensure everything is going smoothly. If you have any concerns or need any adjustments, I'm here to help.

Would you be open to a quick call this week? I'd love to discuss how we can better serve your needs.

Looking forward to hearing from you.

Best regards,
Your Team''';
    } else if (client.aiScore > 80) {
      // High engagement - upsell
      return '''Hi $name,

I hope you're having a great week! I wanted to reach out to thank you for being such a valued customer.

Given your success with us, I wanted to introduce you to our premium plan, which includes exclusive features and a 10% loyalty discount.

Would you be interested in learning more?

Best regards,
Your Team''';
    } else {
      // Standard follow-up
      return '''Hi $name,

I hope this message finds you well. I'm just checking in regarding $lastInvoiceInfo.

Please let me know if you have any questions or if you need anything from our side.

Looking forward to your response!

Best regards,
Your Team''';
    }
  }

  /// Generate suggested action
  String _generateSuggestedAction() {
    final aiScore = client.aiScore;
    final churnRisk = client.churnRisk;
    final daysSinceActivity = client.lastActivityAt != null
        ? DateTime.now().difference(client.lastActivityAt!).inDays
        : 999;
    final daysSincePayment = client.lastPaymentDate != null
        ? DateTime.now().difference(client.lastPaymentDate!).inDays
        : 999;

    // High churn risk
    if (churnRisk > 70 || daysSincePayment > 90) {
      return '🚨 URGENT: Schedule a phone call within 24-48 hours. Offer a 5-10% discount or additional payment terms to retain this client. High risk of losing revenue.';
    }

    // Medium churn risk
    if (churnRisk > 50 || daysSinceActivity > 60) {
      return '⏰ MODERATE: Send a personalized email check-in today. Follow up with a phone call in 3 days if no response. Consider offering a special promotion to re-engage.';
    }

    // High engagement and value
    if (aiScore > 85 && client.lifetimeValue > 5000) {
      return '⭐ PREMIUM: This is a VIP client! Offer annual subscription with 10-15% discount. Schedule quarterly business reviews. Prioritize their requests.';
    }

    // Good engagement
    if (aiScore > 70) {
      return '✅ GOOD: Send friendly email. Schedule next meeting in 2 weeks. Look for upsell or cross-sell opportunities.';
    }

    // New client
    if (client.totalInvoices < 3) {
      return '🌱 NEW: Follow up to ensure satisfaction. Offer onboarding support. Build relationship for long-term value.';
    }

    // Default
    return '📋 ROUTINE: Send regular check-in. Monitor engagement. Follow up in 1-2 weeks.';
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

  IconData _getSentimentIcon(String sentiment) {
    switch (sentiment.toLowerCase()) {
      case 'positive':
        return Icons.sentiment_very_satisfied;
      case 'negative':
        return Icons.sentiment_very_dissatisfied;
      case 'neutral':
        return Icons.sentiment_neutral;
      default:
        return Icons.help;
    }
  }

  IconData _getStabilityIcon(String level) {
    switch (level.toLowerCase()) {
      case 'stable':
        return Icons.trending_flat;
      case 'unstable':
        return Icons.trending_down;
      case 'risky':
        return Icons.warning;
      default:
        return Icons.help;
    }
  }
}
