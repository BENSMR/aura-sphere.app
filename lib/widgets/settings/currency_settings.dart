import 'package:flutter/material.dart';
import '../../services/currency_service.dart';

/// Currency Settings Widget
/// 
/// Allows users to view and select their default currency preference.
/// 
/// Features:
/// - Displays current default currency
/// - Shows dialog with all available currencies
/// - Saves selection to SharedPreferences via CurrencyService
/// - Populates currencies from cached FX rates
/// 
/// Usage:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return CurrencySettings();
/// }
/// ```
class CurrencySettings extends StatefulWidget {
  /// Optional callback when currency is changed
  final Function(String currency)? onCurrencyChanged;

  const CurrencySettings({
    Key? key,
    this.onCurrencyChanged,
  }) : super(key: key);

  @override
  State<CurrencySettings> createState() => _CurrencySettingsState();
}

class _CurrencySettingsState extends State<CurrencySettings> {
  final CurrencyService _currencyService = CurrencyService();
  String? _selectedCurrency;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadDefaultCurrency();
  }

  /// Load user's saved default currency from SharedPreferences
  Future<void> _loadDefaultCurrency() async {
    try {
      final currency = await _currencyService.getDefaultCurrency();
      setState(() {
        _selectedCurrency = currency ?? 'USD';
        _isLoading = false;
      });
    } catch (e) {
      print('❌ Error loading default currency: $e');
      setState(() {
        _selectedCurrency = 'USD';
        _isLoading = false;
      });
    }
  }

  /// Show currency selection dialog
  /// Populates list from cached FX rates
  Future<void> _showCurrencySelector() async {
    try {
      // Get cached FX rates to populate currency list
      final fxDoc = await _currencyService.getCachedRates();
      final ratesMap =
          fxDoc?['rates'] as Map<String, dynamic>? ?? {'USD': 1.0};
      final currencies = ratesMap.keys.toList()..sort();

      if (!mounted) return;

      // Show dialog with currency options
      final choice = await showDialog<String>(
        context: context,
        builder: (dialogContext) => SimpleDialog(
          title: const Text('Select Default Currency'),
          contentPadding: const EdgeInsets.all(12.0),
          children: currencies
              .map(
                (currency) => SimpleDialogOption(
                  onPressed: () => Navigator.pop(dialogContext, currency),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8.0),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 40,
                          child: Text(
                            currency,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            CurrencyService.formatCurrency(1.0, currency),
                            textAlign: TextAlign.right,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              )
              .toList(),
        ),
      );

      // Save selection if user picked a currency
      if (choice != null) {
        await _currencyService.setDefaultCurrency(choice);
        setState(() => _selectedCurrency = choice);
        widget.onCurrencyChanged?.call(choice);

        // Show success message
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Default currency changed to $choice'),
              duration: const Duration(seconds: 2),
            ),
          );
        }
      }
    } catch (e) {
      print('❌ Error showing currency selector: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Error loading currencies. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: const Icon(Icons.currency_exchange),
      title: const Text('Default Currency'),
      subtitle: Text(
        _isLoading ? 'Loading...' : (_selectedCurrency ?? 'USD'),
      ),
      trailing: const Icon(Icons.chevron_right),
      enabled: !_isLoading,
      onTap: _isLoading ? null : _showCurrencySelector,
    );
  }
}
