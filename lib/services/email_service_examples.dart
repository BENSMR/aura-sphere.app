// Example: How to use EmailService in your Flutter screens

import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:aura_sphere_pro/services/email_service.dart';

// EXAMPLE 1: Send email from a task detail screen button
class TaskDetailScreenExample extends StatefulWidget {
  final String taskId;

  const TaskDetailScreenExample({Key? key, required this.taskId}) : super(key: key);

  @override
  State<TaskDetailScreenExample> createState() => _TaskDetailScreenExampleState();
}

class _TaskDetailScreenExampleState extends State<TaskDetailScreenExample> {
  bool _isSending = false;

  void _sendTaskEmail() async {
    setState(() => _isSending = true);

    try {
      final success = await EmailService.sendTaskEmail(
        taskId: widget.taskId,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('📧 Email queued for delivery'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } on FirebaseFunctionsException catch (e) {
      String errorMessage = e.message ?? 'Failed to send email';

      if (e.code == 'failed-precondition') {
        errorMessage = 'Task not ready or no recipient email found. Please add an email.';
      } else if (e.code == 'permission-denied') {
        errorMessage = 'You do not have permission to send this email';
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $errorMessage'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Task Details')),
      body: Center(
        child: ElevatedButton(
          onPressed: _isSending ? null : _sendTaskEmail,
          child: _isSending
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Text('📧 Send Email'),
        ),
      ),
    );
  }
}

// EXAMPLE 2: Send with custom email override
class SendCustomEmailExample extends StatefulWidget {
  final String taskId;

  const SendCustomEmailExample({Key? key, required this.taskId}) : super(key: key);

  @override
  State<SendCustomEmailExample> createState() => _SendCustomEmailExampleState();
}

class _SendCustomEmailExampleState extends State<SendCustomEmailExample> {
  final _emailController = TextEditingController();
  bool _isSending = false;

  void _sendWithOverride() async {
    if (_emailController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter an email address')),
      );
      return;
    }

    setState(() => _isSending = true);

    try {
      final success = await EmailService.sendTaskEmail(
        taskId: widget.taskId,
        overrideEmail: _emailController.text,
      );

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Email sent to ${_emailController.text}'),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      }
    } on FirebaseFunctionsException catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.message}'), backgroundColor: Colors.red),
      );
    } finally {
      setState(() => _isSending = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('Send email to:', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 12),
            TextField(
              controller: _emailController,
              decoration: const InputDecoration(
                hintText: 'user@example.com',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _isSending ? null : _sendWithOverride,
              child: _isSending
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }
}

// EXAMPLE 3: Integration with TaskProvider
// Add this to your existing task_provider.dart

/*
// In TaskProvider class:

import 'package:aura_sphere_pro/services/email_service.dart';

Future<void> sendTaskEmail(String taskId) async {
  try {
    final success = await EmailService.sendTaskEmail(taskId: taskId);
    
    if (success) {
      // Update local state to reflect sent status
      // You can refresh the task from Firestore or update locally
      notifyListeners();
    }
  } catch (e) {
    print('Error sending email: $e');
    rethrow;
  }
}

// Then in your widget:
Future<void> _onSendEmailPressed(String taskId) async {
  final provider = Provider.of<TaskProvider>(context, listen: false);
  
  try {
    await provider.sendTaskEmail(taskId);
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Email sent!')),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
*/

// EXAMPLE 4: Integration with TasksListScreen
// Add send email button next to each task

/*
// In tasks_list_screen.dart, in the task list item:

ListTile(
  title: Text(task.title),
  subtitle: Text(task.description),
  trailing: Row(
    mainAxisSize: MainAxisSize.min,
    children: [
      IconButton(
        icon: const Icon(Icons.email),
        onPressed: () async {
          try {
            final success = await EmailService.sendTaskEmail(taskId: task.id);
            if (success && mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Email queued')),
              );
            }
          } catch (e) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: $e')),
            );
          }
        },
      ),
      // ... other action buttons
    ],
  ),
)
*/
