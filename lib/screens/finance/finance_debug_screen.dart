import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

/// Finance Debug Console
/// 
/// Real-time monitoring of:
/// - Failed tax queue items (internal/tax_queue/requests)
/// - FX rate snapshots (config/fx_rates)
/// - Invoice/Expense tax audit trails
/// 
/// Accessible to: Development/Admin only
class FinanceDebugScreen extends StatelessWidget {
  const FinanceDebugScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Finance Debug Console"),
        elevation: 1,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _sectionTitle("⏳ Tax Queue Status"),
          const SizedBox(height: 8),
          const _QueueStatusSummary(),

          const SizedBox(height: 24),
          _sectionTitle("❌ Failed Tax Queue Items"),
          const SizedBox(height: 8),
          const _FailedQueueList(),

          const SizedBox(height: 24),
          _sectionTitle("💱 Current FX Rates"),
          const SizedBox(height: 8),
          const _FxSnapshotView(),

          const SizedBox(height: 24),
          _sectionTitle("📚 Recent Invoices (Tax Status)"),
          const SizedBox(height: 8),
          const _InvoiceTaxAuditList(),
        ],
      ),
    );
  }

  Widget _sectionTitle(String text) {
    return Text(
      text,
      style: const TextStyle(
        fontSize: 18,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//   QUEUE STATUS SUMMARY
// ────────────────────────────────────────────────────────────

class _QueueStatusSummary extends StatelessWidget {
  const _QueueStatusSummary();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('internal')
          .doc('tax_queue')
          .collection('requests')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final docs = snapshot.data!.docs;
        final pending =
            docs.where((d) => d['processed'] == false).length;
        final failed =
            docs.where((d) => d['lastError'] != null).length;
        final total = docs.length;

        return Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _StatBox('Pending', pending.toString(), Colors.orange),
                    _StatBox('Failed', failed.toString(), Colors.red),
                    _StatBox('Total', total.toString(), Colors.blue),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _StatBox(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
        const SizedBox(height: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }
}

// ────────────────────────────────────────────────────────────
//   FAILED QUEUE ITEMS
// ────────────────────────────────────────────────────────────

class _FailedQueueList extends StatelessWidget {
  const _FailedQueueList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('internal')
          .doc('tax_queue')
          .collection('requests')
          .where('lastError', isNotEqualTo: null)
          .orderBy('lastError') // index workaround
          .orderBy('lastTriedAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Card(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text(
                "✅ No failed items — all good!",
                textAlign: TextAlign.center,
              ),
            ),
          );
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final attempts = data['attempts'] ?? 0;
            final error = data['lastError'] ?? 'Unknown error';
            final entityPath = data['entityPath'] ?? 'Unknown entity';

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text(
                  entityPath.split('/').last,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Error: $error'),
                    Text('Attempts: $attempts/5'),
                  ],
                ),
                trailing: IconButton(
                  icon: const Icon(Icons.refresh),
                  tooltip: 'Reset to pending',
                  onPressed: () => _resetQueueItem(doc.id),
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _QueueItemDetailView(
                        queueId: doc.id,
                        data: data,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }

  Future<void> _resetQueueItem(String queueId) async {
    try {
      await FirebaseFirestore.instance
          .collection('internal')
          .doc('tax_queue')
          .collection('requests')
          .doc(queueId)
          .update({
        'processed': false,
        'attempts': 0,
        'lastError': null,
        'lastTriedAt': null,
      });
    } catch (e) {
      debugPrint('Error resetting queue item: $e');
    }
  }
}

// ────────────────────────────────────────────────────────────
//   FX RATE SNAPSHOT VIEW
// ────────────────────────────────────────────────────────────

class _FxSnapshotView extends StatelessWidget {
  const _FxSnapshotView();

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.doc('config/fx_rates').get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.data!.exists) {
          return const Text('No FX rates configured yet.');
        }

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final base = data['base'] ?? 'USD';
        final rates = (data['rates'] as Map<String, dynamic>?) ?? {};
        final updatedAt = data['updatedAt'] as Timestamp?;
        final provider = data['provider'] ?? 'unknown';

        return Column(
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Base Currency: $base',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Provider: $provider', style: const TextStyle(fontSize: 12)),
                    if (updatedAt != null)
                      Text(
                        'Updated: ${updatedAt.toDate()}',
                        style: const TextStyle(fontSize: 12),
                      ),
                    const SizedBox(height: 8),
                    Text('${rates.length} rates cached'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 250,
              child: ListView(
                children: rates.entries.map((e) {
                  return ListTile(
                    title: Text(e.key),
                    trailing: Text(
                      e.value.toString(),
                      style: const TextStyle(fontSize: 14, fontFamily: 'monospace'),
                    ),
                    dense: true,
                  );
                }).toList(),
              ),
            ),
          ],
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────
//   INVOICE TAX AUDIT TRAIL
// ────────────────────────────────────────────────────────────

class _InvoiceTaxAuditList extends StatelessWidget {
  const _InvoiceTaxAuditList();

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collectionGroup('invoices')
          .orderBy('updatedAt', descending: true)
          .limit(20)
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.data!.docs.isEmpty) {
          return const Text('No invoices found.');
        }

        return Column(
          children: snapshot.data!.docs.map((doc) {
            final data = doc.data() as Map<String, dynamic>;
            final taxStatus = data['taxStatus'] ?? 'unknown';
            final amount = data['amount'] ?? 0;
            final taxAmount = data['taxAmount'];
            final currency = data['currency'] ?? '?';
            final calculatedBy = data['taxCalculatedBy'];

            return Card(
              margin: const EdgeInsets.symmetric(vertical: 6),
              child: ListTile(
                title: Text('Invoice: ${doc.id}'),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status: $taxStatus'),
                    Text('Amount: $amount $currency'),
                    if (taxAmount != null) Text('Tax: $taxAmount $currency'),
                    if (calculatedBy != null)
                      Text(
                        'Calculated by: $calculatedBy',
                        style: const TextStyle(fontSize: 11, color: Colors.grey),
                      ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => _InvoiceDetailView(
                        invoiceId: doc.id,
                        userId: doc.reference.parent.parent!.id,
                      ),
                    ),
                  );
                },
              ),
            );
          }).toList(),
        );
      },
    );
  }
}

// ────────────────────────────────────────────────────────────
//   DETAIL VIEWS
// ────────────────────────────────────────────────────────────

class _QueueItemDetailView extends StatelessWidget {
  final String queueId;
  final Map<String, dynamic> data;

  const _QueueItemDetailView({
    required this.queueId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final entityPath = data['entityPath'] ?? 'Unknown';
    final uid = data['uid'] ?? 'Unknown';
    final attempts = data['attempts'] ?? 0;
    final error = data['lastError'];
    final lastResult = data['lastResult'];

    return Scaffold(
      appBar: AppBar(title: const Text('Queue Item Details')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _InfoSection('Queue Item ID', queueId),
          _InfoSection('Entity Path', entityPath),
          _InfoSection('Owner UID', uid),
          _InfoSection('Attempts', attempts.toString()),
          if (error != null) _InfoSection('Last Error', error),
          if (lastResult != null) ...[
            const SizedBox(height: 16),
            const Text(
              'Last Determination Result:',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            _JsonDisplay(lastResult),
          ],
        ],
      ),
    );
  }

  Widget _InfoSection(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
        SelectableText(value),
        const SizedBox(height: 12),
      ],
    );
  }
}

class _InvoiceDetailView extends StatelessWidget {
  final String invoiceId;
  final String userId;

  const _InvoiceDetailView({
    required this.invoiceId,
    required this.userId,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Invoice Details')),
      body: FutureBuilder<DocumentSnapshot>(
        future: FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .collection('invoices')
            .doc(invoiceId)
            .get(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.data!.exists) {
            return const Center(child: Text('Invoice not found.'));
          }

          final data = snapshot.data!.data() as Map<String, dynamic>;

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _JsonDisplay(data),
            ],
          );
        },
      ),
    );
  }
}

// ────────────────────────────────────────────────────────────
//   HELPERS
// ────────────────────────────────────────────────────────────

class _JsonDisplay extends StatelessWidget {
  final dynamic json;

  const _JsonDisplay(this.json);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: SelectableText(
          json.toString(),
          style: const TextStyle(fontSize: 12, fontFamily: 'monospace'),
        ),
      ),
    );
  }
}
