import 'package:flutter/material.dart';
import '../../services/tax_service.dart';

/// Tax Settings Widget
/// 
/// Allows users to view and configure tax settings.
/// Shows tax rules for their country/region.
/// 
/// Features:
/// - Select country for tax calculations
/// - View VAT/Tax rates for selected country
/// - Display reduced rates if applicable
/// - Check B2B/reverse charge eligibility
/// 
/// Usage:
/// ```dart
/// @override
/// Widget build(BuildContext context) {
///   return TaxSettings(
///     onCountrySelected: (country) {
///       print('Selected: $country');
///     },
///   );
/// }
/// ```
class TaxSettings extends StatefulWidget {
  /// Optional callback when country is selected
  final Function(String country)? onCountrySelected;

  const TaxSettings({
    Key? key,
    this.onCountrySelected,
  }) : super(key: key);

  @override
  State<TaxSettings> createState() => _TaxSettingsState();
}

class _TaxSettingsState extends State<TaxSettings> {
  final TaxService _taxService = TaxService();
  String? _selectedCountry;
  Map<String, dynamic>? _taxRule;
  List<String> _availableCountries = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadAvailableCountries();
  }

  /// Load all available countries with tax rules
  Future<void> _loadAvailableCountries() async {
    try {
      final countries = await _taxService.getAvailableCountries();
      setState(() {
        _availableCountries = countries;
        _selectedCountry = countries.isNotEmpty ? countries.first : null;
        _isLoading = false;
      });

      // Load tax rule for first country
      if (_selectedCountry != null) {
        _loadTaxRule(_selectedCountry!);
      }
    } catch (e) {
      print('❌ Error loading countries: $e');
      setState(() => _isLoading = false);
    }
  }

  /// Load and display tax rule for selected country
  Future<void> _loadTaxRule(String country) async {
    try {
      final rule = await _taxService.getTaxRule(country);
      setState(() => _taxRule = rule);
    } catch (e) {
      print('❌ Error loading tax rule: $e');
    }
  }

  /// Handle country selection
  void _onCountrySelected(String? country) {
    if (country != null) {
      setState(() => _selectedCountry = country);
      _loadTaxRule(country);
      widget.onCountrySelected?.call(country);
    }
  }

  @override
  Widget build(BuildContext context) {
    return _isLoading
        ? const Center(child: CircularProgressIndicator())
        : Card(
            margin: const EdgeInsets.all(16.0),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Country Selector
                  const Text(
                    'Tax Country',
                    style: TextStyle(
                      fontSize: 14.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  DropdownButton<String>(
                    value: _selectedCountry,
                    isExpanded: true,
                    onChanged: _onCountrySelected,
                    items: _availableCountries
                        .map(
                          (country) => DropdownMenuItem(
                            value: country,
                            child: Text(country),
                          ),
                        )
                        .toList(),
                  ),
                  const SizedBox(height: 16.0),

                  // Tax Rule Details
                  if (_taxRule != null) ...[
                    const Divider(),
                    const SizedBox(height: 8.0),
                    const Text(
                      'Tax Rules',
                      style: TextStyle(
                        fontSize: 14.0,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8.0),
                    _buildTaxRuleInfo(),
                  ],
                ],
              ),
            ),
          );
  }

  /// Build tax rule information widget
  Widget _buildTaxRuleInfo() {
    final vat = _taxRule?['vat'] as Map<String, dynamic>?;

    if (vat == null) {
      return const Padding(
        padding: EdgeInsets.all(8.0),
        child: Text('No VAT/Tax applicable for this country'),
      );
    }

    final standard = vat['standard'] as double?;
    final reduced = vat['reduced'] as List?;
    final isEu = vat['isEu'] as bool? ?? false;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Standard Rate
        if (standard != null)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 4.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Standard Rate:'),
                Text(
                  TaxService.formatTaxRate(standard),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),

        // Reduced Rates
        if (reduced != null && reduced.isNotEmpty) ...[
          const SizedBox(height: 8.0),
          const Text('Reduced Rates:'),
          ...reduced.map((r) {
            final rate = (r is double) ? r : (r as int).toDouble();
            return Padding(
              padding: const EdgeInsets.only(left: 16.0, top: 4.0),
              child: Text(
                TaxService.formatTaxRate(rate),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            );
          }).toList(),
        ],

        // EU Status
        if (isEu) ...[
          const SizedBox(height: 8.0),
          Container(
            padding: const EdgeInsets.all(8.0),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(4.0),
            ),
            child: const Row(
              children: [
                Icon(Icons.info, size: 16.0),
                SizedBox(width: 8.0),
                Expanded(
                  child: Text(
                    'EU member - B2B reverse charge applies',
                    style: TextStyle(fontSize: 12.0),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}
