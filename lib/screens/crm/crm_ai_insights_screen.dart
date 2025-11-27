import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/crm_insights_provider.dart';
import '../../providers/crm_provider.dart';
import '../../providers/user_provider.dart';

class CrmAiInsightsScreen extends StatefulWidget {
  const CrmAiInsightsScreen({super.key});

  @override
  State<CrmAiInsightsScreen> createState() => _CrmAiInsightsScreenState();
}

class _CrmAiInsightsScreenState extends State<CrmAiInsightsScreen> {
  @override
  Widget build(BuildContext context) {
    final crmProv = context.watch<CrmProvider>();
    final insightsProv = context.watch<CrmInsightsProvider>();
    final userProv = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('CRM AI Insights'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: insightsProv.loading ? null : () async {
              // generate using current user's contacts
              final uid = userProv.user?.uid;
              if (uid == null || uid.isEmpty) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Not authenticated')));
                return;
              }
              await insightsProv.generate(uid);
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Cache status banner
          if (insightsProv.cached || insightsProv.cooldown)
            Container(
              width: double.infinity,
              color: insightsProv.cached ? Colors.blue[50] : Colors.orange[50],
              padding: const EdgeInsets.all(8.0),
              child: Row(
                children: [
                  Icon(
                    insightsProv.cached ? Icons.cached : Icons.timer,
                    color: insightsProv.cached ? Colors.blue : Colors.orange,
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insightsProv.cached 
                        ? 'Showing cached insights (${insightsProv.source})'
                        : insightsProv.cooldown 
                          ? 'Rate limit active. Next allowed: ${insightsProv.nextAllowedAt ?? 'unknown'}'
                          : 'Fresh insights generated',
                      style: TextStyle(
                        fontSize: 12,
                        color: insightsProv.cached ? Colors.blue[700] : Colors.orange[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          // Main content
          Expanded(
            child: insightsProv.loading
                ? const Center(child: CircularProgressIndicator())
                : insightsProv.error != null
                    ? Center(child: Text('Error: ${insightsProv.error}'))
                    : insightsProv.insights == null
                        ? _emptyState(context)
                        : _insightsView(context, insightsProv.insights!),
          ),
        ],
      ),
    );
  }

  Widget _emptyState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.auto_mode, size: 80, color: Colors.grey),
          const SizedBox(height: 12),
          const Text('No insights yet'),
          const SizedBox(height: 12),
          const Text('Tap refresh to generate insights for your contacts.')
        ]),
      ),
    );
  }

  Widget _insightsView(BuildContext context, Map<String, dynamic> data) {
    final segments = List.from(data['segments'] ?? []);
    final topContacts = List.from(data['topContacts'] ?? []);
    final actions = List.from(data['actions'] ?? []);
    final emailTemplate = data['emailTemplate'] ?? {};
    final smsTemplate = data['smsTemplate'] ?? {};

    return ListView(padding: const EdgeInsets.all(12), children: [
      const Text('Segments', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...segments.map((s) => ListTile(title: Text(s['name'] ?? ''), subtitle: Text(s['reason'] ?? ''))),

      const SizedBox(height: 12),
      const Text('Top Contacts', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...topContacts.map((t) => ListTile(
            title: Text(t['name'] ?? ''),
            subtitle: Text('Score: ${t['score'] ?? '?'} — ${t['reason'] ?? ''}'),
          )),

      const SizedBox(height: 12),
      const Text('Suggested Actions', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      const SizedBox(height: 8),
      ...actions.map((a) => ListTile(
            title: Text(a['suggestion'] ?? ''),
            subtitle: Text('Channel: ${a['channel'] ?? 'email'}'),
          )),

      const SizedBox(height: 12),
      const Text('Email Template', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ListTile(title: Text(emailTemplate['subject'] ?? ''), subtitle: Text(emailTemplate['body'] ?? '')),

      const SizedBox(height: 12),
      const Text('SMS Template', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
      ListTile(title: Text(smsTemplate['body'] ?? '')),

      const SizedBox(height: 20),
      Card(
        color: Colors.grey[50],
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Text('Confidence: ${data['confidence'] ?? 'unknown'}\n\nExplain: ${data['explain'] ?? ''}'),
        ),
      )
    ]);
  }
}