import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/client_provider.dart';
import '../../data/models/client_model.dart';
import 'client_detail_screen.dart';
import 'edit_client_screen.dart';

class ClientListScreen extends StatelessWidget {
  const ClientListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final provider = Provider.of<ClientProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clients'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(12),
            child: TextField(
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search),
                hintText: 'Search clients...',
                border: OutlineInputBorder(),
              ),
              onChanged: provider.setSearchQuery,
            ),
          ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : provider.clients.isEmpty
                    ? const Center(
                        child: Text('No clients yet. Add your first client!'),
                      )
                    : ListView.builder(
                        itemCount: provider.clients.length,
                        itemBuilder: (ctx, i) {
                          final c = provider.clients[i];
                          return _ClientTile(client: c);
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => const EditClientScreen(),
            ),
          );
        },
        child: const Icon(Icons.person_add),
      ),
    );
  }
}

class _ClientTile extends StatelessWidget {
  final ClientModel client;
  const _ClientTile({required this.client});

  Color _statusColor(String status) {
    switch (status) {
      case 'vip':
        return Colors.purple;
      case 'active':
        return Colors.green;
      case 'lost':
        return Colors.red;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _statusColor(client.status);
    return ListTile(
      leading: CircleAvatar(
        child: Text(
          client.name.isNotEmpty ? client.name[0].toUpperCase() : '?',
        ),
      ),
      title: Text(client.name),
      subtitle: Text(client.company.isNotEmpty
          ? '${client.company} • ${client.email}'
          : client.email),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '€${client.totalValue.toStringAsFixed(2)}',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: color.withOpacity(0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              client.status.toUpperCase(),
              style: TextStyle(
                color: color,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      onTap: () {
        Navigator.of(context).push(
          MaterialPageRoute(
            builder: (_) => ClientDetailScreen(client: client),
          ),
        );
      },
    );
  }
}
