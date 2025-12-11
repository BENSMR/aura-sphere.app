import 'package:flutter/material.dart';
import '../widgets/settings/currency_settings.dart';
import '../widgets/settings/tax_settings.dart';

/// Finance Settings Screen
/// 
/// Complete screen for managing finance-related settings:
/// - Default currency preference
/// - Tax country/region
/// - VAT/Tax rate display
/// 
/// This is a full-screen widget that combines both
/// CurrencySettings and TaxSettings widgets.
class FinanceSettingsScreen extends StatefulWidget {
  const FinanceSettingsScreen({Key? key}) : super(key: key);

  @override
  State<FinanceSettingsScreen> createState() => _FinanceSettingsScreenState();
}

class _FinanceSettingsScreenState extends State<FinanceSettingsScreen> {
  String? _selectedCurrency;
  String? _selectedCountry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finance Settings'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Header Card
            Container(
              width: double.infinity,
              color: Theme.of(context).primaryColor.withOpacity(0.1),
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Configure Your Finance Preferences',
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Set your default currency and tax rules',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Currency Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 8.0,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16.0),
                  const Text(
                    'Currency',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  CurrencySettings(
                    onCurrencyChanged: (currency) {
                      setState(() => _selectedCurrency = currency);
                      _showNotification(
                        'Currency changed to $currency',
                      );
                    },
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Used for displaying amounts and currency conversion',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Divider
            const Padding(
              padding: EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 24.0,
              ),
              child: Divider(),
            ),

            // Tax Settings Section
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Tax Configuration',
                    style: TextStyle(
                      fontSize: 16.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 12.0),
                  TaxSettings(
                    onCountrySelected: (country) {
                      setState(() => _selectedCountry = country);
                      _showNotification(
                        'Tax country changed to $country',
                      );
                    },
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Used for VAT and tax calculations on invoices and expenses',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),

            // Summary Section
            if (_selectedCurrency != null || _selectedCountry != null) ...[
              const SizedBox(height: 32.0),
              Container(
                margin: const EdgeInsets.symmetric(horizontal: 16.0),
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.1),
                  border: Border.all(color: Colors.green.withOpacity(0.3)),
                  borderRadius: BorderRadius.circular(8.0),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 8.0),
                        Text(
                          'Settings Configured',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12.0),
                    if (_selectedCurrency != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '✓ Default Currency: $_selectedCurrency',
                        ),
                      ),
                    if (_selectedCountry != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4.0),
                        child: Text(
                          '✓ Tax Country: $_selectedCountry',
                        ),
                      ),
                  ],
                ),
              ),
            ],

            // Bottom Spacing
            const SizedBox(height: 32.0),
          ],
        ),
      ),
    );
  }

  /// Show a snackbar notification
  void _showNotification(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
}

/// Example: How to add to your app routes
/// 
/// In lib/config/app_routes.dart:
/// ```dart
/// import 'package:aurasphere_pro/screens/finance_settings_screen.dart';
/// 
/// final appRoutes = {
///   '/finance-settings': (context) => const FinanceSettingsScreen(),
///   // ... other routes
/// };
/// ```
/// 
/// In your app:
/// ```dart
/// Navigator.pushNamed(context, '/finance-settings');
/// ```
