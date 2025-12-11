import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../services/invoice_audit_service.dart';

class InvoiceAuditScreen extends StatefulWidget {
  const InvoiceAuditScreen({Key? key}) : super(key: key);

  @override
  State<InvoiceAuditScreen> createState() => _InvoiceAuditScreenState();
}

class _InvoiceAuditScreenState extends State<InvoiceAuditScreen> {
  final InvoiceAuditService _service = InvoiceAuditService();
  final TextEditingController _searchController = TextEditingController();
  String _search = '';

  String _formatDate(DateTime dt) {
    try {
      return DateFormat('yyyy-MM-dd HH:mm').format(dt.toLocal());
    } catch (_) {
      return dt.toLocal().toString().split('.').first;
    }
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      setState(() {
        _search = _searchController.text.trim().toLowerCase();
      });
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice Audit Log'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                labelText: 'Search by invoice number or invoice ID',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
            ),
          ),
          Expanded(
            child: StreamBuilder<List<InvoiceAuditEntry>>(
              stream: _service.streamAuditEntries(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                final entries = snapshot.data ?? [];
                final filtered = _search.isEmpty
                    ? entries
                    : entries.where((e) {
                        final inv = e.invoiceNumber.toLowerCase();
                        final id = (e.invoiceId ?? '').toLowerCase();
                        return inv.contains(_search) || id.contains(_search);
                      }).toList();

                if (filtered.isEmpty) {
                  return const Center(
                    child: Text(
                      'No audit records yet.\nCreate some invoices to see history here.',
                      textAlign: TextAlign.center,
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final e = filtered[index];
                    final contextSource = e.context?['source'] ?? '';
                    final hasInvoice = (e.invoiceId ?? '').isNotEmpty;
                    return Card(
                      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      child: ListTile(
                        leading: const Icon(Icons.history),
                        title: Text(
                          e.invoiceNumber,
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Allocated: ${_formatDate(e.allocatedAt)}'),
                            Text('Number: ${e.number} • By: ${e.allocatedBy}'),
                            if (contextSource is String && contextSource.isNotEmpty)
                              Text('Source: $contextSource'),
                            if ((e.invoiceId ?? '').isNotEmpty)
                              Text('Linked invoice: ${e.invoiceId}'),
                          ],
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            if (hasInvoice)
                              Chip(
                                label: const Text('Linked'),
                                backgroundColor: Colors.green.shade100,
                              )
                            else
                              Chip(
                                label: const Text('Unlinked'),
                                backgroundColor: Colors.grey.shade200,
                              ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
