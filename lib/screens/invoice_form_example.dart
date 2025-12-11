import 'package:flutter/material.dart';
import '../../services/currency_service.dart';
import '../../services/tax_service.dart';

/// Invoice Form Example Widget
/// 
/// Demonstrates:
/// - Currency conversion (local + server)
/// - Tax calculation
/// - Real-time amount updates
/// - Multi-currency support
class InvoiceFormExample extends StatefulWidget {
  const InvoiceFormExample({Key? key}) : super(key: key);

  @override
  State<InvoiceFormExample> createState() => _InvoiceFormExampleState();
}

class _InvoiceFormExampleState extends State<InvoiceFormExample> {
  // Services
  final CurrencyService _currencyService = CurrencyService();
  final TaxService _taxService = TaxService();

  // Form state
  double _enteredAmount = 100.0;
  String _invoiceCurrency = 'EUR';
  String _userDefaultCurrency = 'USD';
  String _selectedCountry = 'FR';
  bool _customerIsBusiness = false;

  // Cached data
  Map<String, dynamic>? _fxDoc;
  Map<String, dynamic>? _taxRule;

  // Converted values
  double? _convertedAmount;
  Map<String, dynamic>? _taxResult;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCachedData();
  }

  /// Initialize cached FX rates and tax rules
  Future<void> _initializeCachedData() async {
    try {
      setState(() => _isLoading = true);

      // Prefetch FX rates
      final fxDoc = await _currencyService.getCachedRates();
      final taxRule = await _taxService.getTaxRule(_selectedCountry);

      setState(() {
        _fxDoc = fxDoc;
        _taxRule = taxRule;
      });

      // Perform initial calculations
      _recalculate();
    } catch (e) {
      print('❌ Error initializing cached data: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  /// Recalculate converted amount and tax
  Future<void> _recalculate() async {
    try {
      setState(() => _isLoading = true);

      // 1. Try local conversion first (fast, from cache)
      final localConverted = await _currencyService.localConvert(
        amount: _enteredAmount,
        from: _invoiceCurrency,
        to: _userDefaultCurrency,
        fxDoc: _fxDoc,
      );

      // 2. Call server for authoritative conversion
      final serverConverted = await _currencyService.convertAmount(
        amount: _enteredAmount,
        from: _invoiceCurrency,
        to: _userDefaultCurrency,
      );

      // 3. Calculate tax
      final taxResult = await _taxService.calculateTax(
        amount: _enteredAmount,
        country: _selectedCountry,
        customerIsBusiness: _customerIsBusiness,
      );

      setState(() {
        _convertedAmount = serverConverted['converted'] as double?;
        _taxResult = taxResult;
      });

      print('✅ Calculations complete');
      print('   Local: ${localConverted ?? "N/A"}');
      print('   Server: ${_convertedAmount}');
      print('   Tax: ${_taxResult?['tax']}');
    } catch (e) {
      print('❌ Error calculating: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Calculation error: $e')),
      );
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Invoice with Currency & Tax'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Amount Input
            const Text(
              'Invoice Amount',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            TextField(
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                hintText: 'Enter amount',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8.0),
                ),
                suffixText: _invoiceCurrency,
              ),
              onChanged: (value) {
                setState(() {
                  _enteredAmount = double.tryParse(value) ?? 0;
                });
                _recalculate();
              },
            ),
            const SizedBox(height: 16.0),

            // Invoice Currency Selector
            const Text(
              'Invoice Currency',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            DropdownButton<String>(
              value: _invoiceCurrency,
              isExpanded: true,
              onChanged: (value) {
                setState(() => _invoiceCurrency = value ?? 'EUR');
                _recalculate();
              },
              items: ['USD', 'EUR', 'GBP', 'JPY', 'CHF']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
            ),
            const SizedBox(height: 16.0),

            // Tax Country Selector
            const Text(
              'Tax Country',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            DropdownButton<String>(
              value: _selectedCountry,
              isExpanded: true,
              onChanged: (value) {
                setState(() => _selectedCountry = value ?? 'FR');
                _recalculate();
              },
              items: ['FR', 'DE', 'GB', 'ES', 'IT', 'US']
                  .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                  .toList(),
            ),
            const SizedBox(height: 16.0),

            // B2B Checkbox
            CheckboxListTile(
              value: _customerIsBusiness,
              onChanged: (value) {
                setState(() => _customerIsBusiness = value ?? false);
                _recalculate();
              },
              title: const Text('Customer is Business (B2B)'),
              subtitle: const Text('Enables EU reverse charge if applicable'),
            ),
            const SizedBox(height: 24.0),

            // Results Card
            if (_isLoading)
              const Center(child: CircularProgressIndicator())
            else if (_convertedAmount != null && _taxResult != null)
              _buildResultsCard()
            else
              const Center(
                child: Text('Enter an amount to calculate'),
              ),
          ],
        ),
      ),
    );
  }

  /// Build results card showing calculations
  Widget _buildResultsCard() {
    final invoiceTotal = _enteredAmount;
    final tax = (_taxResult?['tax'] as double?) ?? 0.0;
    final taxRate = (_taxResult?['rate'] as double?) ?? 0.0;
    final taxNote = _taxResult?['note'] as String?;

    return Card(
      elevation: 4.0,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Invoice Summary',
              style: TextStyle(
                fontSize: 18.0,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16.0),

            // Amount in Invoice Currency
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Amount ($_invoiceCurrency):'),
                Text(
                  '${CurrencyService.formatCurrency(_enteredAmount, _invoiceCurrency)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8.0),

            // Converted Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Converted ($_userDefaultCurrency):'),
                Text(
                  '${CurrencyService.formatCurrency(_convertedAmount ?? 0, _userDefaultCurrency)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16.0),
            const Divider(),
            const SizedBox(height: 16.0),

            // Tax Breakdown
            Text(
              'Tax: $_selectedCountry',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax Rate:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  TaxService.formatTaxRate(taxRate),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Tax Amount:',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                Text(
                  '${CurrencyService.formatCurrency(tax, _invoiceCurrency)}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // Tax Note (e.g., reverse charge)
            if (taxNote != null) ...[
              const SizedBox(height: 8.0),
              Container(
                padding: const EdgeInsets.all(8.0),
                decoration: BoxDecoration(
                  color: Colors.blue.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4.0),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.info, size: 16.0),
                    const SizedBox(width: 8.0),
                    Expanded(
                      child: Text(
                        taxNote,
                        style: const TextStyle(fontSize: 12.0),
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16.0),
            const Divider(),
            const SizedBox(height: 16.0),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total (with tax):',
                  style: TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text(
                  '${CurrencyService.formatCurrency(invoiceTotal + tax, _invoiceCurrency)}',
                  style: const TextStyle(
                    fontSize: 16.0,
                    fontWeight: FontWeight.bold,
                    color: Colors.green,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
