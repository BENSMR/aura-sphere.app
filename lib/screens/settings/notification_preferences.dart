// lib/screens/settings/notification_preferences.dart
import 'package:flutter/material.dart';
import '../../services/notification_preferences_service.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({Key? key}) : super(key: key);

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  final _svc = NotificationPreferencesService();
  Map<String, dynamic> prefs = {};
  bool loading = true;

  @override
  void initState() {
    super.initState();
    _svc.getPrefs().then((p) => setState(() { prefs = p; loading = false; })).catchError((e){
      setState((){loading=false;});
    });
  }

  void _savePatch(Map<String, dynamic> patch) async {
    setState(() => loading = true);
    try {
      await _svc.updatePrefs(patch);
      final newPrefs = await _svc.getPrefs();
      setState(() { prefs = newPrefs; });
    } finally {
      setState(() => loading = false);
    }
  }

  bool _getEnabled(String cat) => (prefs['enabled'] != null && prefs['enabled'][cat] == true);

  String _getSeverity(String cat) => (prefs['minSeverity'] != null && prefs['minSeverity'][cat] != null) ? prefs['minSeverity'][cat] as String : 'info';

  @override
  Widget build(BuildContext context) {
    final categories = ['anomaly','invoice','inventory','crm','promotions'];
    return Scaffold(
      appBar: AppBar(title: const Text('Notification Preferences')),
      body: loading ? const Center(child: CircularProgressIndicator()) : ListView(
        padding: const EdgeInsets.all(12),
        children: [
          SwitchListTile(
            title: const Text('Do Not Disturb (Global)'),
            subtitle: const Text('Pause all notifications'),
            value: prefs['globalDnd'] == true,
            onChanged: (v) => _savePatch({'globalDnd': v})
          ),
          const Divider(),
          const Padding(padding: EdgeInsets.symmetric(vertical: 6), child: Text('Categories', style: TextStyle(fontWeight: FontWeight.bold))),
          ...categories.map((cat) {
            final enabled = _getEnabled(cat);
            final currentSeverity = _getSeverity(cat);
            return Card(
              child: ListTile(
                title: Text(cat[0].toUpperCase() + cat.substring(1)),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(children: [
                      const Text('Enabled: '),
                      Switch(value: enabled, onChanged: (v) => _savePatch({'enabled': {cat: v}})),
                      const SizedBox(width: 12),
                      const Text('Min severity: ')
                    ]),
                    DropdownButton<String>(
                      value: currentSeverity,
                      items: ['info','warning','high','critical'].map((s) => DropdownMenuItem(value: s, child: Text(s.toUpperCase()))).toList(),
                      onChanged: (v) => _savePatch({'minSeverity': {cat: v}})
                    )
                  ],
                ),
                isThreeLine: true,
              ),
            );
          }).toList(),
          const Divider(),
          Card(
            child: ListTile(
              title: const Text('Quiet hours'),
              subtitle: Text(prefs['quietHours'] != null && prefs['quietHours']['enabled'] == true
                  ? 'From ${prefs['quietHours']['startHour']} to ${prefs['quietHours']['endHour']}'
                  : 'Disabled'),
              trailing: ElevatedButton(
                onPressed: () => _openQuietHoursDialog(),
                child: const Text('Edit')
              ),
            ),
          ),
          const SizedBox(height: 24),
          ElevatedButton.icon(
            icon: const Icon(Icons.save),
            label: const Text('Save & Apply'),
            onPressed: () => _savePatch({}), // no-op -> already saved per-control
          )
        ],
      ),
    );
  }

  void _openQuietHoursDialog() {
    int start = prefs['quietHours'] != null ? (prefs['quietHours']['startHour'] as int) : 22;
    int end = prefs['quietHours'] != null ? (prefs['quietHours']['endHour'] as int) : 7;
    bool enabled = prefs['quietHours'] != null ? (prefs['quietHours']['enabled'] == true) : false;

    showDialog(context: context, builder: (ctx) {
      return AlertDialog(
        title: const Text('Quiet hours'),
        content: StatefulBuilder(
          builder: (context, setState) => Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              SwitchListTile(
                value: enabled,
                title: const Text('Enabled'),
                onChanged: (v) => setState(() => enabled = v)
              ),
              Row(children: [
                const Text('Start hour: '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: start,
                  items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text(i.toString()))),
                  onChanged: (v) => setState(() => start = v ?? start)
                )
              ]),
              Row(children: [
                const Text('End hour: '),
                const SizedBox(width: 8),
                DropdownButton<int>(
                  value: end,
                  items: List.generate(24, (i) => DropdownMenuItem(value: i, child: Text(i.toString()))),
                  onChanged: (v) => setState(() => end = v ?? end)
                )
              ])
            ],
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
          ElevatedButton(onPressed: () {
            _savePatch({'quietHours': {'enabled': enabled, 'startHour': start, 'endHour': end}});
            Navigator.pop(ctx);
          }, child: const Text('Save'))
        ],
      );
    });
  }
}
