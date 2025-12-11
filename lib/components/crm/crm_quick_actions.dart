import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// CRM Quick Actions Bar
/// - Usage: place inside CRM detail screen and pass client info
/// - Requires cloud_firestore & url_launcher packages
/// - Replace getCurrentUserId() with your Auth provider (FirebaseAuth)
class CRMQuickActions extends StatelessWidget {
  final String clientId;
  final String clientName;
  final String? email;
  final String? phone;
  final String? whatsappNumber; // international format e.g. +34123456789

  const CRMQuickActions({
    super.key,
    required this.clientId,
    required this.clientName,
    this.email,
    this.phone,
    this.whatsappNumber,
  });

  // TODO: replace with real auth provider / FirebaseAuth.instance.currentUser!.uid
  String getCurrentUserId() => FirebaseAuth.instance.currentUser!.uid;

  CollectionReference<Map<String, dynamic>> _clientsRef() {
    final uid = getCurrentUserId();
    return FirebaseFirestore.instance.collection('users').doc(uid).collection('clients');
  }

  Future<void> _addTimelineEvent(String userId, String clientId, Map<String, dynamic> event) async {
    final clientRef = FirebaseFirestore.instance.collection('users').doc(userId).collection('clients').doc(clientId);
    await clientRef.update({
      'timeline': FieldValue.arrayUnion([{
        ...event,
        'createdAt': FieldValue.serverTimestamp(),
      }])
    });
  }

  Future<void> _showSnack(BuildContext context, String text) async {
    if (!context.mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  // ---------------- Actions ----------------

  Future<void> _callPhone(BuildContext context) async {
    if (phone == null || phone!.trim().isEmpty) {
      await _showSnack(context, 'No phone number available.');
      return;
    }
    final uri = Uri.parse('tel:${phone!.trim()}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await _showSnack(context, 'Unable to open phone dialer.');
    }
  }

  Future<void> _sendEmail(BuildContext context) async {
    if (email == null || email!.trim().isEmpty) {
      await _showSnack(context, 'No email available.');
      return;
    }
    final subject = Uri.encodeComponent('Hello $clientName');
    final body = Uri.encodeComponent('Hi $clientName,\n\n');
    final uri = Uri.parse('mailto:${email!.trim()}?subject=$subject&body=$body');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      await _showSnack(context, 'Unable to open email client.');
    }
  }

  Future<void> _openWhatsApp(BuildContext context) async {
    final target = whatsappNumber ?? phone;
    if (target == null || target.trim().isEmpty) {
      await _showSnack(context, 'No WhatsApp number available.');
      return;
    }
    final cleaned = target.replaceAll(RegExp(r'[\s\-\(\)]'), '');
    // Launch WhatsApp (universal link)
    final uri = Uri.parse('https://wa.me/${cleaned.replaceFirst(RegExp(r'^\+'), '')}');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      await _showSnack(context, 'Unable to open WhatsApp.');
    }
  }

  Future<void> _addNoteDialog(BuildContext context) async {
    final controller = TextEditingController();
    final uid = getCurrentUserId();
    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add note'),
        content: TextField(
          controller: controller,
          maxLines: 4,
          decoration: const InputDecoration(hintText: 'Write a note about this client...'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final text = controller.text.trim();
              if (text.isEmpty) return;
              final event = {
                'type': 'note',
                'message': text,
                'author': uid,
              };
              await _addTimelineEvent(uid, clientId, event);
              Navigator.of(ctx).pop();
              await _showSnack(context, 'Note added to timeline.');
            },
            child: const Text('Save'),
          )
        ],
      ),
    );
  }

  Future<void> _addReminderDialog(BuildContext context) async {
    final titleCtrl = TextEditingController();
    DateTime? dueDate;
    final uid = getCurrentUserId();

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(builder: (ctx2, setState) {
        return AlertDialog(
          title: const Text('Add reminder'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(controller: titleCtrl, decoration: const InputDecoration(labelText: 'Reminder')),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: () async {
                      final picked = await showDatePicker(
                        context: ctx2,
                        initialDate: DateTime.now(),
                        firstDate: DateTime.now().subtract(const Duration(days: 365)),
                        lastDate: DateTime.now().add(const Duration(days: 365 * 2)),
                      );
                      if (picked != null) setState(() => dueDate = picked);
                    },
                    icon: const Icon(Icons.calendar_today),
                    label: const Text('Pick date'),
                  ),
                  const SizedBox(width: 8),
                  if (dueDate != null) Text('${dueDate!.toLocal().toString().split(' ').first}')
                ],
              )
            ],
          ),
          actions: [
            TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final t = titleCtrl.text.trim();
                if (t.isEmpty) return;
                // create reminder doc under users/{uid}/reminders
                final remRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('reminders').doc();
                await remRef.set({
                  'clientId': clientId,
                  'title': t,
                  'dueDate': dueDate != null ? Timestamp.fromDate(dueDate!) : FieldValue.serverTimestamp(),
                  'createdAt': FieldValue.serverTimestamp(),
                  'completed': false,
                });
                // also add timeline event
                await _addTimelineEvent(uid, clientId, {
                  'type': 'reminder_added',
                  'message': 'Reminder: $t',
                  'reminderId': remRef.id,
                });
                Navigator.of(ctx).pop();
                await _showSnack(context, 'Reminder created.');
              },
              child: const Text('Create'),
            )
          ],
        );
      }),
    );
  }

  Future<void> _createInvoice(BuildContext context) async {
    // Navigate to your invoice create screen and pass clientId
    // Ensure route '/invoices/create' is registered and accepts arguments
    if (!context.mounted) return;
    Navigator.of(context).pushNamed('/invoices/create', arguments: {'clientId': clientId});
  }

  Future<void> _createProject(BuildContext context) async {
    if (!context.mounted) return;
    Navigator.of(context).pushNamed('/projects/create', arguments: {'clientId': clientId});
  }

  Future<void> _quickAddPayment(BuildContext context) async {
    // Quick add payment mock: creates payment event and increments lifetimeValue
    final uid = getCurrentUserId();
    final paidAmountController = TextEditingController();

    await showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Add payment (quick)'),
        content: TextField(
          controller: paidAmountController,
          keyboardType: TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(labelText: 'Amount (€)'),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.of(ctx).pop(), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final raw = paidAmountController.text.trim();
              final a = double.tryParse(raw.replaceAll(',', '.')) ?? 0.0;
              if (a <= 0) return;
              // update client lifetimeValue & add timeline
              final clientRef = FirebaseFirestore.instance.collection('users').doc(uid).collection('clients').doc(clientId);
              await clientRef.update({
                'lifetimeValue': FieldValue.increment(a),
                'lastPaymentDate': FieldValue.serverTimestamp(),
                'lastActivityAt': FieldValue.serverTimestamp(),
                'timeline': FieldValue.arrayUnion([{
                  'type': 'manual_payment',
                  'message': 'Manual payment added: €$a',
                  'amount': a,
                  'createdAt': FieldValue.serverTimestamp()
                }])
              });
              Navigator.of(ctx).pop();
              await _showSnack(context, 'Payment added.');
            },
            child: const Text('Add'),
          )
        ],
      ),
    );
  }

  // ---------------- UI ----------------

  @override
  Widget build(BuildContext context) {
    final actions = <_ActionItem>[
      _ActionItem(icon: Icons.call, label: 'Call', onTap: () => _callPhone(context)),
      _ActionItem(icon: Icons.email, label: 'Email', onTap: () => _sendEmail(context)),
      _ActionItem(icon: Icons.chat, label: 'WhatsApp', onTap: () => _openWhatsApp(context)),
      _ActionItem(icon: Icons.note_add, label: 'Note', onTap: () => _addNoteDialog(context)),
      _ActionItem(icon: Icons.event, label: 'Reminder', onTap: () => _addReminderDialog(context)),
      _ActionItem(icon: Icons.receipt, label: 'Invoice', onTap: () => _createInvoice(context)),
      _ActionItem(icon: Icons.work, label: 'Project', onTap: () => _createProject(context)),
      _ActionItem(icon: Icons.payment, label: 'Payment', onTap: () => _quickAddPayment(context)),
    ];

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
        child: Wrap(
          spacing: 8,
          runSpacing: 6,
          children: actions.map((a) {
            return SizedBox(
              width: 120,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                  alignment: Alignment.centerLeft,
                ),
                icon: Icon(a.icon, size: 20),
                label: Flexible(child: Text(a.label, overflow: TextOverflow.ellipsis)),
                onPressed: () => a.onTap(),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ActionItem {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  _ActionItem({required this.icon, required this.label, required this.onTap});
}
