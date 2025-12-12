// lib/screens/settings/locale_settings.dart
import 'package:flutter/material.dart';
import '../../services/locale_service.dart';
import '../../services/timezone_service.dart';

class LocaleSettingsScreen extends StatefulWidget {
  const LocaleSettingsScreen({Key? key}) : super(key: key);

  @override
  State<LocaleSettingsScreen> createState() => _LocaleSettingsScreenState();
}

class _LocaleSettingsScreenState extends State<LocaleSettingsScreen> {
  final _localeSvc = LocaleService();
  final _tzSvc = TimezoneService();

  bool _loading = true;
  String? _timezone;
  String? _locale;
  String? _currency;
  String? _country;
  String? _dateFormat;
  String? _invoicePrefix;

  final List<String> _currencies = ['USD', 'EUR', 'GBP', 'BRL', 'INR', 'AED', 'SAR', 'CNY'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    final tzDoc = await _tzSvc.getUserTimezone();
    final doc = await _localeSvc.getLocaleDoc();
    setState(() {
      _timezone = tzDoc?['timezone'] ?? doc?['timezone'] ?? 'UTC';
      _locale = doc?['locale'] ?? 'en-US';
      _currency = doc?['currency'] ?? 'USD';
      _country = doc?['country'];
      _dateFormat = doc?['dateFormat'];
      _invoicePrefix = doc?['invoicePrefix'] ?? 'INV-';
      _loading = false;
    });
  }

  Future<void> _autoDetectTimezone() async {
    setState(() => _loading = true);
    final detected = await _tzSvc.detectDeviceTimezone();
    setState(() {
      _timezone = detected;
      _loading = false;
    });
  }

  Future<void> _save() async {
    setState(() => _loading = true);
    await _localeSvc.setLocaleDoc(
      timezone: _timezone ?? 'UTC',
      locale: _locale,
      currency: _currency,
      country: _country,
      dateFormat: _dateFormat,
      invoicePrefix: _invoicePrefix,
    );
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Locale & Currency')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : Padding(
              padding: const EdgeInsets.all(12),
              child: ListView(
                children: [
                  ListTile(
                    title: const Text('Timezone'),
                    subtitle: Text(_timezone ?? 'Not set'),
                    trailing: ElevatedButton(
                      onPressed: _autoDetectTimezone,
                      child: const Text('Auto'),
                    ),
                  ),
                  TextFormField(
                    initialValue: _locale,
                    decoration: const InputDecoration(labelText: 'Locale (e.g. en-US)'),
                    onChanged: (v) => _locale = v,
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _currency,
                    items: _currencies.map((c) => DropdownMenuItem(value: c, child: Text(c))).toList(),
                    onChanged: (v) => _currency = v,
                    decoration: const InputDecoration(labelText: 'Default currency'),
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _country,
                    decoration: const InputDecoration(labelText: 'Country (ISO2)'),
                    onChanged: (v) => _country = v,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _dateFormat,
                    decoration: const InputDecoration(labelText: 'Date format (optional)'),
                    onChanged: (v) => _dateFormat = v,
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    initialValue: _invoicePrefix,
                    decoration: const InputDecoration(labelText: 'Invoice prefix'),
                    onChanged: (v) => _invoicePrefix = v,
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      ElevatedButton(onPressed: _save, child: const Text('Save')),
                      const SizedBox(width: 8),
                      TextButton(onPressed: _load, child: const Text('Reload')),
                    ],
                  ),
                ],
              ),
            ),
    );
  }
}
