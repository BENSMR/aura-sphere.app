import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class DigestSettingsScreen extends StatefulWidget {
  const DigestSettingsScreen({super.key});

  @override
  State<DigestSettingsScreen> createState() => _DigestSettingsScreenState();
}

class _DigestSettingsScreenState extends State<DigestSettingsScreen> {
  bool _enabled = true;
  String _frequency = "daily";
  int _hour = 8;
  bool _includeInvoices = true;
  bool _includeExpenses = true;
  bool _includeTasks = true;
  bool _includeStock = true;
  bool _includeCRM = true;
  bool _loading = true;
  bool _saving = false;

  late String uid;

  @override
  void initState() {
    super.initState();
    uid = FirebaseAuth.instance.currentUser!.uid;
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('digest')
          .get();

      if (mounted) {
        setState(() {
          if (doc.exists) {
            final d = doc.data()!;
            _enabled = d["digestEnabled"] ?? true;
            _frequency = d["digestFrequency"] ?? "daily";
            _hour = d["preferredHour"] ?? 8;
            _includeInvoices = d["includeInvoices"] ?? true;
            _includeExpenses = d["includeExpenses"] ?? true;
            _includeTasks = d["includeTasks"] ?? true;
            _includeStock = d["includeStock"] ?? true;
            _includeCRM = d["includeCRM"] ?? true;
          }
          _loading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error loading settings: $e")),
        );
      }
    }
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('settings')
          .doc('digest')
          .set({
        "digestEnabled": _enabled,
        "digestFrequency": _frequency,
        "preferredHour": _hour,
        "includeInvoices": _includeInvoices,
        "includeExpenses": _includeExpenses,
        "includeTasks": _includeTasks,
        "includeStock": _includeStock,
        "includeCRM": _includeCRM,
        "updatedAt": FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));

      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Digest settings saved!"),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Error saving settings: $e")),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        appBar: AppBar(title: const Text("Digest Settings")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Digest Settings")),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Enable/Disable
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: SwitchListTile(
                title: const Text("Enable Digest"),
                subtitle: const Text(
                  "Receive periodic email digests of your activity",
                ),
                value: _enabled,
                onChanged: (v) => setState(() => _enabled = v),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Frequency & Hour
          if (_enabled) ...[
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Digest Frequency",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    DropdownButtonFormField<String>(
                      value: _frequency,
                      items: const [
                        DropdownMenuItem(
                          value: "daily",
                          child: Text("Daily"),
                        ),
                        DropdownMenuItem(
                          value: "weekly",
                          child: Text("Weekly (Mondays)"),
                        ),
                      ],
                      onChanged: (v) => setState(() => _frequency = v!),
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 8,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Preferred Hour
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Preferred Time",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          "$_hour:00",
                          style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Slider(
                            value: _hour.toDouble(),
                            min: 0,
                            max: 23,
                            divisions: 23,
                            label: "$_hour:00",
                            onChanged: (v) =>
                                setState(() => _hour = v.toInt()),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      "Digest will be sent in your local timezone",
                      style: TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Categories
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      "Include in Digest",
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    CheckboxListTile(
                      title: const Text("Invoices"),
                      value: _includeInvoices,
                      onChanged: (v) =>
                          setState(() => _includeInvoices = v ?? true),
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text("Expenses"),
                      value: _includeExpenses,
                      onChanged: (v) =>
                          setState(() => _includeExpenses = v ?? true),
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text("Tasks"),
                      value: _includeTasks,
                      onChanged: (v) =>
                          setState(() => _includeTasks = v ?? true),
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text("Stock/Inventory"),
                      value: _includeStock,
                      onChanged: (v) =>
                          setState(() => _includeStock = v ?? true),
                      dense: true,
                    ),
                    CheckboxListTile(
                      title: const Text("CRM"),
                      value: _includeCRM,
                      onChanged: (v) => setState(() => _includeCRM = v ?? true),
                      dense: true,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 30),
          ],

          // Save Button
          ElevatedButton.icon(
            onPressed: _saving ? null : _save,
            icon: _saving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.save),
            label: Text(_saving ? "Saving..." : "Save Settings"),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 12),
            ),
          ),
        ],
      ),
    );
  }
}
