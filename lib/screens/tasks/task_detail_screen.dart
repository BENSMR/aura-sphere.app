import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../data/models/task_model.dart';
import '../../providers/task_provider.dart';

class TaskDetailScreen extends StatelessWidget {
  final TaskModel task;
  const TaskDetailScreen({super.key, required this.task});

  @override
  Widget build(BuildContext context) {
    final prov = context.read<TaskProvider>();
    return Scaffold(
      appBar: AppBar(
        title: Text('Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: () async {
              await prov.markDone(task.id);
              if (Navigator.canPop(context)) Navigator.of(context).pop();
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete),
            onPressed: () async {
              final ok = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  title: const Text('Delete task?'),
                  actions: [
                    TextButton(onPressed: () => Navigator.of(ctx).pop(false), child: const Text('Cancel')),
                    TextButton(onPressed: () => Navigator.of(ctx).pop(true), child: const Text('Delete')),
                  ],
                ),
              );
              if (ok == true) {
                await prov.delete(task.id);
                if (Navigator.canPop(context)) Navigator.of(context).pop();
              }
            },
          )
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(12.0),
        child: ListView(children: [
          Text(task.title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Status: ${task.status}'),
          const SizedBox(height: 8),
          Text('Channel: ${task.channel}'),
          const SizedBox(height: 8),
          if (task.template.isNotEmpty) ...[
            const Text('Template', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 6),
            Text(task.template),
          ],
          const SizedBox(height: 12),
          ElevatedButton.icon(
            icon: const Icon(Icons.check),
            label: const Text('Mark as done'),
            onPressed: () async {
              await prov.markDone(task.id);
              if (Navigator.canPop(context)) Navigator.of(context).pop();
            },
          )
        ]),
      ),
    );
  }
}