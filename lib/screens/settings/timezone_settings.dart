// lib/screens/settings/timezone_settings.dart
import 'package:flutter/material.dart';
import '../../services/timezone_service.dart';

class TimezoneSettingsScreen extends StatefulWidget {
  const TimezoneSettingsScreen({Key? key}) : super(key: key);
  @override
  State<TimezoneSettingsScreen> createState() => _TimezoneSettingsScreenState();
}

class _TimezoneSettingsScreenState extends State<TimezoneSettingsScreen> {
  final _svc = TimezoneService();
  String? _timezone;
  String? _locale;
  String? _country;
  bool _loading = true;

  // Small curated list of common IANA zones. Replace with full list if needed.
  final List<String> _sampleZones = [
    'UTC',
    'Europe/London','Europe/Paris','Europe/Berlin','Europe/Madrid',
    'America/New_York','America/Sao_Paulo','America/Los_Angeles',
    'Asia/Dubai','Asia/Kolkata','Asia/Seoul','Asia/Tokyo','Africa/Cairo'
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final doc = await _svc.getUserTimezone();
    setState(() {
      _timezone = doc?['timezone'] ?? null;
      _locale = doc?['locale'] ?? null;
      _country = doc?['country'] ?? null;
      _loading = false;
    });
  }

  Future<void> _autoDetect() async {
    setState(() => _loading = true);
    final tz = await _svc.detectDeviceTimezone();
    await _svc.setUserTimezone(tz);
    await _load();
  }

  Future<void> _save() async {
    if (_timezone == null) return;
    setState(() => _loading = true);
    await _svc.setUserTimezone(_timezone!, locale: _locale, country: _country);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Timezone & Locale')),
      body: _loading ? const Center(child: CircularProgressIndicator()) : Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          children: [
            ListTile(
              title: const Text('Detected timezone'),
              subtitle: Text(_timezone ?? 'Not set'),
              trailing: ElevatedButton(onPressed: _autoDetect, child: const Text('Auto detect')),
            ),
            const SizedBox(height: 8),
            DropdownButtonFormField<String>(
              value: _timezone,
              items: _sampleZones.map((z) => DropdownMenuItem(value: z, child: Text(z))).toList(),
              onChanged: (v) => setState(() => _timezone = v),
              decoration: const InputDecoration(labelText: 'Timezone (IANA)'),
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _locale,
              decoration: const InputDecoration(labelText: 'Locale (e.g. en-US)'),
              onChanged: (v) => _locale = v,
            ),
            const SizedBox(height: 12),
            TextFormField(
              initialValue: _country,
              decoration: const InputDecoration(labelText: 'Country (ISO2)'),
              onChanged: (v) => _country = v,
            ),
            const SizedBox(height: 20),
            Row(children: [
              ElevatedButton(onPressed: _save, child: const Text('Save')),
              const SizedBox(width: 12),
              TextButton(onPressed: _load, child: const Text('Reload'))
            ])
          ],
        ),
      ),
    );
  }
}
