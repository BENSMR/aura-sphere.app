import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  Map<String, dynamic> prefs = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (uid == null) return;
    final snap = await FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('notifications').get();
    setState(() {
      prefs = snap.exists ? (snap.data() ?? {}) : {'anomalies': true, 'invoices': true, 'inventory': true};
      loading = false;
    });
  }

  Future<void> toggle(String key, bool val) async {
    if (uid == null) return;
    await FirebaseFirestore.instance.collection('users').doc(uid).collection('settings').doc('notifications').set({key: val}, SetOptions(merge: true));
    setState(() { prefs[key] = val; });
  }

  @override
  Widget build(BuildContext context) {
    if (loading) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Settings')),
      body: ListView(
        children: [
          SwitchListTile(
            title: const Text('Anomaly alerts'),
            value: prefs['anomalies'] ?? true,
            onChanged: (v) => toggle('anomalies', v),
          ),
          SwitchListTile(
            title: const Text('Invoice alerts'),
            value: prefs['invoices'] ?? true,
            onChanged: (v) => toggle('invoices', v),
          ),
          SwitchListTile(
            title: const Text('Inventory alerts'),
            value: prefs['inventory'] ?? true,
            onChanged: (v) => toggle('inventory', v),
          ),
        ],
      ),
    );
  }
}
