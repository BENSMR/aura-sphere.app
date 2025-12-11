import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/supplier_provider.dart';
import 'supplier_form_screen.dart';
import 'supplier_detail_screen.dart';

class SupplierListScreen extends StatefulWidget {
  const SupplierListScreen({Key? key}) : super(key: key);

  @override
  State<SupplierListScreen> createState() => _SupplierListScreenState();
}

class _SupplierListScreenState extends State<SupplierListScreen> {
  @override
  void initState() {
    super.initState();
    final prov = Provider.of<SupplierProvider>(context, listen: false);
    prov.startListening();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SupplierProvider>(builder: (context, prov, _) {
      return Scaffold(
        appBar: AppBar(
          title: const Text('Suppliers'),
          actions: [
            IconButton(
              icon: const Icon(Icons.search),
              onPressed: () async {
                final q = await showSearch<String>(context: context, delegate: _SupplierSearchDelegate(prov));
                if (q != null && q.isNotEmpty) {
                  // optional: open supplier form prefilled
                }
              },
            )
          ],
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const SupplierFormScreen())),
          child: const Icon(Icons.add),
        ),
        body: prov.loading
            ? const Center(child: CircularProgressIndicator())
            : prov.suppliers.isEmpty
                ? const Center(child: Text('No suppliers yet. Tap + to add one.'))
                : ListView.builder(
                    itemCount: prov.suppliers.length,
                    itemBuilder: (_, i) {
                      final s = prov.suppliers[i];
                      return ListTile(
                        title: Text(s.name),
                        subtitle: Text('${s.contact ?? s.email ?? ''}'),
                        trailing: s.preferred ? const Icon(Icons.star, color: Colors.amber) : null,
                        onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => SupplierDetailScreen(supplier: s))),
                      );
                    },
                  ),
      );
    });
  }
}

class _SupplierSearchDelegate extends SearchDelegate<String> {
  final SupplierProvider provider;
  _SupplierSearchDelegate(this.provider);

  @override
  List<Widget>? buildActions(BuildContext context) => [IconButton(onPressed: () => query = '', icon: const Icon(Icons.clear))];

  @override
  Widget? buildLeading(BuildContext context) => IconButton(onPressed: () => close(context, ''), icon: const Icon(Icons.arrow_back));

  @override
  Widget buildResults(BuildContext context) {
    return FutureBuilder<List<dynamic>>(
      future: provider.search(query),
      builder: (context, snap) {
        if (!snap.hasData) return const Center(child: CircularProgressIndicator());
        final list = snap.data!;
        if (list.isEmpty) return const Center(child: Text('No suppliers found'));
        return ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) {
            final s = list[i];
            return ListTile(
              title: Text(s.name),
              subtitle: Text(s.email ?? ''),
              onTap: () => close(context, s.name),
            );
          },
        );
      },
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    return const SizedBox.shrink();
  }
}
