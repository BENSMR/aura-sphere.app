import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/theme_provider.dart';

/// Theme toggle button - use in AppBar or Settings
class ThemeToggleButton extends StatelessWidget {
  final Color? activeColor;
  final Color? inactiveColor;

  const ThemeToggleButton({
    Key? key,
    this.activeColor,
    this.inactiveColor,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return IconButton(
          icon: Icon(
            themeProvider.isDarkMode ? Icons.light_mode : Icons.dark_mode,
            color: activeColor,
          ),
          onPressed: () {
            themeProvider.toggleTheme();
          },
          tooltip: themeProvider.isDarkMode ? 'Light Mode' : 'Dark Mode',
        );
      },
    );
  }
}

/// Theme toggle with label
class ThemeToggleWithLabel extends StatelessWidget {
  final MainAxisAlignment alignment;

  const ThemeToggleWithLabel({
    Key? key,
    this.alignment = MainAxisAlignment.spaceBetween,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return Row(
          mainAxisAlignment: alignment,
          children: [
            Text(
              'Dark Mode',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            Switch(
              value: themeProvider.isDarkMode,
              onChanged: (_) {
                themeProvider.toggleTheme();
              },
            ),
          ],
        );
      },
    );
  }
}

/// Theme selection dialog
class ThemeSelectionDialog extends StatelessWidget {
  const ThemeSelectionDialog({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ThemeProvider>(
      builder: (context, themeProvider, _) {
        return AlertDialog(
          title: const Text('Choose Theme'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                title: const Text('Light'),
                leading: Radio(
                  value: false,
                  groupValue: themeProvider.isDarkMode,
                  onChanged: (_) {
                    themeProvider.setLightTheme();
                    Navigator.pop(context);
                  },
                ),
              ),
              ListTile(
                title: const Text('Dark'),
                leading: Radio(
                  value: true,
                  groupValue: themeProvider.isDarkMode,
                  onChanged: (_) {
                    themeProvider.setDarkTheme();
                    Navigator.pop(context);
                  },
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
          ],
        );
      },
    );
  }
}
