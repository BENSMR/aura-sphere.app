import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';
import '../providers/user_provider.dart';
import '../widgets/theme_toggle_widget.dart';

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Settings'),
        elevation: 0,
      ),
      body: ListView(
        children: [
          /// Theme Settings Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Appearance',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: ThemeToggleWithLabel(
                      alignment: MainAxisAlignment.spaceBetween,
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const Divider(height: 32, indent: 16, endIndent: 16),

          /// User Account Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Account',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Consumer<UserProvider>(
                  builder: (context, userProvider, _) {
                    return Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Email',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userProvider.user?.email ?? 'Not signed in',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Display Name',
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                            const SizedBox(height: 8),
                            Text(
                              userProvider.user?.displayName ?? 'Not set',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          /// Notification Preferences Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Notifications',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        _NotificationPreferenceRow(
                          title: 'Email Alerts',
                          subtitle: 'Receive email notifications for anomalies',
                          enabled: true,
                          onChanged: (value) {},
                        ),
                        const SizedBox(height: 16),
                        _NotificationPreferenceRow(
                          title: 'Push Notifications',
                          subtitle: 'Receive push notifications on your device',
                          enabled: true,
                          onChanged: (value) {},
                        ),
                        const SizedBox(height: 16),
                        _NotificationPreferenceRow(
                          title: 'Invoice Reminders',
                          subtitle: 'Get reminded when invoices are due',
                          enabled: true,
                          onChanged: (value) {},
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const Divider(height: 32, indent: 16, endIndent: 16),

          /// App Version Section
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'About',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'App Version',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              '1.0.0',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Build',
                              style: Theme.of(context).textTheme.bodyLarge,
                            ),
                            Text(
                              '2025.12.11',
                              style: Theme.of(context).textTheme.bodyMedium,
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 32),

          /// Logout Button
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Consumer<UserProvider>(
              builder: (context, userProvider, _) {
                return ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () async {
                    final confirm = await showDialog<bool>(
                      context: context,
                      builder: (context) => AlertDialog(
                        title: const Text('Logout'),
                        content: const Text('Are you sure you want to logout?'),
                        actions: [
                          TextButton(
                            onPressed: () => Navigator.pop(context, false),
                            child: const Text('Cancel'),
                          ),
                          TextButton(
                            onPressed: () => Navigator.pop(context, true),
                            child: const Text('Logout'),
                          ),
                        ],
                      ),
                    );

                    if (confirm == true) {
                      await userProvider.logout();
                      if (context.mounted) {
                        Navigator.of(context).pushNamedAndRemoveUntil(
                          '/login',
                          (route) => false,
                        );
                      }
                    }
                  },
                  child: const Text('Logout'),
                );
              },
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }
}

/// Notification Preference Row Widget
class _NotificationPreferenceRow extends StatefulWidget {
  final String title;
  final String subtitle;
  final bool enabled;
  final Function(bool) onChanged;

  const _NotificationPreferenceRow({
    required this.title,
    required this.subtitle,
    required this.enabled,
    required this.onChanged,
  });

  @override
  State<_NotificationPreferenceRow> createState() =>
      _NotificationPreferenceRowState();
}

class _NotificationPreferenceRowState extends State<_NotificationPreferenceRow> {
  late bool _isEnabled;

  @override
  void initState() {
    super.initState();
    _isEnabled = widget.enabled;
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.title,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 4),
              Text(
                widget.subtitle,
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          ),
        ),
        Switch(
          value: _isEnabled,
          onChanged: (value) {
            setState(() {
              _isEnabled = value;
            });
            widget.onChanged(value);
          },
        ),
      ],
    );
  }
}
