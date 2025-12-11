// Example: How to use the Clients collection in your Flutter screens

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../providers/client_provider.dart';
import '../data/models/client_model.dart';

// ============================================================================
// EXAMPLE 1: Display List of Clients
// ============================================================================

class ClientsListExample extends StatefulWidget {
  @override
  State<ClientsListExample> createState() => _ClientsListExampleState();
}

class _ClientsListExampleState extends State<ClientsListExample> {
  @override
  void initState() {
    super.initState();
    final userId = FirebaseAuth.instance.currentUser!.uid;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClientProvider>().loadClients(userId);
    });
  }

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    
    return Scaffold(
      appBar: AppBar(title: Text('Clients')),
      body: Consumer<ClientProvider>(
        builder: (context, provider, child) {
          if (provider.isLoading) {
            return Center(child: CircularProgressIndicator());
          }

          if (provider.error != null) {
            return Center(child: Text('Error: ${provider.error}'));
          }

          if (provider.clients.isEmpty) {
            return Center(child: Text('No clients yet'));
          }

          return ListView.builder(
            itemCount: provider.clients.length,
            itemBuilder: (context, index) {
              final client = provider.clients[index];
              return ListTile(
                title: Text(client.name),
                subtitle: Text(client.email),
                trailing: Text('\$${client.value}'),
                onTap: () {
                  // Navigate to client detail screen
                  context.read<ClientProvider>().selectClient(userId, client.id);
                },
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 2: Create New Client
// ============================================================================

class AddClientExample extends StatefulWidget {
  @override
  State<AddClientExample> createState() => _AddClientExampleState();
}

class _AddClientExampleState extends State<AddClientExample> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  List<String> _selectedTags = [];

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(title: Text('Add Client')),
      body: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                label: Text('Client Name'),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _emailController,
              decoration: InputDecoration(
                label: Text('Email'),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 16),
            TextField(
              controller: _phoneController,
              decoration: InputDecoration(
                label: Text('Phone'),
                border: OutlineInputBorder(),
              ),
            ),
            SizedBox(height: 24),
            ElevatedButton(
              onPressed: () async {
                try {
                  await context.read<ClientProvider>().createClient(
                    userId: userId,
                    name: _nameController.text,
                    email: _emailController.text,
                    phone: _phoneController.text,
                    tags: _selectedTags,
                  );
                  
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Client created!')),
                  );
                  Navigator.pop(context);
                } catch (e) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('Error: $e')),
                  );
                }
              },
              child: Text('Create Client'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }
}

// ============================================================================
// EXAMPLE 3: Client Detail Screen with Timeline
// ============================================================================

class ClientDetailExample extends StatelessWidget {
  final String clientId;

  const ClientDetailExample({required this.clientId});

  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final provider = context.read<ClientProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Client Details')),
      body: Consumer<ClientProvider>(
        builder: (context, provider, _) {
          final client = provider.selectedClient;

          if (client == null) {
            return Center(child: CircularProgressIndicator());
          }

          return SingleChildScrollView(
            padding: EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Basic Info
                Card(
                  child: Padding(
                    padding: EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          client.name,
                          style: Theme.of(context).textTheme.headlineSmall,
                        ),
                        SizedBox(height: 8),
                        Text('Email: ${client.email}'),
                        Text('Phone: ${client.phone}'),
                        Text('Value: \$${client.value}'),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: 16),

                // Tags
                Text('Tags', style: Theme.of(context).textTheme.titleMedium),
                Wrap(
                  spacing: 8,
                  children: [
                    ...client.tags.map((tag) => Chip(
                      label: Text(tag),
                      onDeleted: () async {
                        await provider.removeTag(userId, clientId, tag);
                      },
                    )),
                    ActionChip(
                      label: Text('+ Add Tag'),
                      onPressed: () => _showAddTagDialog(context, userId),
                    ),
                  ],
                ),
                SizedBox(height: 16),

                // Notes
                Text('Notes', style: Theme.of(context).textTheme.titleMedium),
                if (client.notes.isNotEmpty)
                  Column(
                    children: client.notes.map((note) => ListTile(
                      title: Text(note),
                      trailing: IconButton(
                        icon: Icon(Icons.delete),
                        onPressed: () async {
                          await provider.removeNote(userId, clientId, note);
                        },
                      ),
                    )).toList(),
                  ),
                SizedBox(height: 8),
                ElevatedButton(
                  onPressed: () => _showAddNoteDialog(context, userId),
                  child: Text('Add Note'),
                ),
                SizedBox(height: 16),

                // Timeline
                Text('Activity', style: Theme.of(context).textTheme.titleMedium),
                if (client.timeline.isNotEmpty)
                  ListView.builder(
                    shrinkWrap: true,
                    physics: NeverScrollableScrollPhysics(),
                    itemCount: client.timeline.length,
                    itemBuilder: (context, index) {
                      final event = client.timeline[index];
                      final timestamp = (event['timestamp'] as dynamic)?.toDate() ?? DateTime.now();
                      
                      return ListTile(
                        title: Text(event['event'] ?? ''),
                        subtitle: Text(
                          '${event['type']} • ${timestamp.toString().split('.')[0]}',
                        ),
                      );
                    },
                  ),
                else
                  Text('No activity yet'),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddActivityDialog(context, userId),
        child: Icon(Icons.add),
      ),
    );
  }

  void _showAddTagDialog(BuildContext context, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Tag'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(label: Text('Tag name')),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ClientProvider>().addTag(
                userId,
                clientId,
                controller.text,
              );
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddNoteDialog(BuildContext context, String userId) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Note'),
        content: TextField(
          controller: controller,
          decoration: InputDecoration(label: Text('Note')),
          maxLines: 3,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ClientProvider>().addNote(
                userId,
                clientId,
                controller.text,
              );
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }

  void _showAddActivityDialog(BuildContext context, String userId) {
    final eventController = TextEditingController();
    String selectedType = 'call';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Add Activity'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: eventController,
              decoration: InputDecoration(label: Text('What happened?')),
              maxLines: 2,
            ),
            SizedBox(height: 16),
            DropdownButton<String>(
              value: selectedType,
              items: ['call', 'email', 'meeting', 'payment', 'note']
                  .map((type) => DropdownMenuItem(
                    value: type,
                    child: Text(type),
                  ))
                  .toList(),
              onChanged: (value) {
                selectedType = value ?? 'call';
              },
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text('Cancel'),
          ),
          TextButton(
            onPressed: () async {
              await context.read<ClientProvider>().addTimelineEvent(
                userId,
                clientId,
                eventController.text,
                selectedType,
              );
              Navigator.pop(context);
            },
            child: Text('Add'),
          ),
        ],
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 4: Search Clients
// ============================================================================

class SearchClientsExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;

    return Scaffold(
      appBar: AppBar(
        title: TextField(
          onChanged: (query) {
            context.read<ClientProvider>().searchClients(query);
          },
          decoration: InputDecoration(
            hintText: 'Search clients...',
            border: InputBorder.none,
            hintStyle: TextStyle(color: Colors.white70),
          ),
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: Consumer<ClientProvider>(
        builder: (context, provider, _) {
          final filtered = provider.filteredClients;

          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final client = filtered[index];
              return ListTile(
                title: Text(client.name),
                subtitle: Text(client.email),
                trailing: Chip(label: Text('\$${client.value}')),
              );
            },
          );
        },
      ),
    );
  }
}

// ============================================================================
// EXAMPLE 5: Real-time Client Updates
// ============================================================================

class ClientsStreamExample extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final userId = FirebaseAuth.instance.currentUser!.uid;
    final provider = context.read<ClientProvider>();

    return Scaffold(
      appBar: AppBar(title: Text('Live Clients')),
      body: StreamBuilder<List<Client>>(
        stream: provider.streamClients(userId),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final clients = snapshot.data ?? [];

          return ListView.builder(
            itemCount: clients.length,
            itemBuilder: (context, index) {
              final client = clients[index];
              return ListTile(
                title: Text(client.name),
                subtitle: Text(client.email),
                trailing: Text('\$${client.value}'),
              );
            },
          );
        },
      ),
    );
  }
}
