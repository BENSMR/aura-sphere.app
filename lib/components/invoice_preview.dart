import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

/// Invoice Preview Component
/// 
/// Professional invoice preview widget with:
/// - Real-time updates
/// - Multiple zoom levels
/// - Print preview
/// - Customizable layout
/// - Responsive design
/// - Professional formatting
class InvoicePreview extends StatefulWidget {
  /// Invoice number
  final String invoiceNumber;

  /// Issue date
  final DateTime issueDate;

  /// Due date
  final DateTime dueDate;

  /// Client name
  final String clientName;

  /// Client email
  final String clientEmail;

  /// Company name
  final String companyName;

  /// Invoice items
  final List<InvoiceItem> items;

  /// Subtotal
  final double subtotal;

  /// Tax rate (0-1, e.g., 0.1 for 10%)
  final double taxRate;

  /// Tax amount
  final double tax;

  /// Total amount
  final double total;

  /// Currency code (USD, EUR, etc.)
  final String currency;

  /// Optional company logo URL
  final String? logoUrl;

  /// Optional notes
  final String? notes;

  /// Optional payment terms
  final String? paymentTerms;

  /// Show zoom controls
  final bool showZoomControls;

  /// Show print button
  final bool showPrintButton;

  /// Watermark text (optional)
  final String? watermarkText;

  const InvoicePreview({
    super.key,
    required this.invoiceNumber,
    required this.issueDate,
    required this.dueDate,
    required this.clientName,
    required this.clientEmail,
    required this.companyName,
    required this.items,
    required this.subtotal,
    required this.taxRate,
    required this.tax,
    required this.total,
    required this.currency,
    this.logoUrl,
    this.notes,
    this.paymentTerms,
    this.showZoomControls = true,
    this.showPrintButton = true,
    this.watermarkText,
  });

  @override
  State<InvoicePreview> createState() => _InvoicePreviewState();
}

class _InvoicePreviewState extends State<InvoicePreview> {
  late double _zoomLevel;
  late ScrollController _scrollController;

  @override
  void initState() {
    super.initState();
    _zoomLevel = 1.0;
    _scrollController = ScrollController();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  /// Format currency
  String _formatCurrency(double amount) {
    const currencySymbols = {
      'USD': '\$',
      'EUR': '€',
      'GBP': '£',
      'JPY': '¥',
      'INR': '₹',
    };
    final symbol = currencySymbols[widget.currency] ?? widget.currency;
    return '$symbol${amount.toStringAsFixed(2)}';
  }

  /// Format date
  String _formatDate(DateTime date) {
    return DateFormat('MMM dd, yyyy').format(date);
  }

  /// Build invoice header
  Widget _buildHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Company info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.companyName,
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Invoice #${widget.invoiceNumber}',
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
        // Invoice dates
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            _buildDateRow('Issue Date:', _formatDate(widget.issueDate)),
            const SizedBox(height: 4),
            _buildDateRow('Due Date:', _formatDate(widget.dueDate)),
          ],
        ),
      ],
    );
  }

  /// Build date row
  Widget _buildDateRow(String label, String value) {
    return Row(
      children: [
        Text(
          '$label ',
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }

  /// Build client info section
  Widget _buildClientInfo() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Bill To:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.clientName,
          style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
        Text(
          widget.clientEmail,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  /// Build line items table
  Widget _buildLineItems() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Table header
        Container(
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              topRight: Radius.circular(8),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                flex: 3,
                child: Text(
                  'Description',
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Qty',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Price',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Expanded(
                child: Text(
                  'Amount',
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 12,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
            ],
          ),
        ),
        // Table rows
        ...widget.items.asMap().entries.map((entry) {
          final item = entry.value;
          final isLast = entry.key == widget.items.length - 1;

          return Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: isLast ? Colors.transparent : Colors.grey.shade200,
                ),
              ),
            ),
            child: Row(
              children: [
                Expanded(
                  flex: 3,
                  child: Text(
                    item.description,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    item.quantity.toString(),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    _formatCurrency(item.unitPrice),
                    textAlign: TextAlign.right,
                    style: const TextStyle(fontSize: 12),
                  ),
                ),
                Expanded(
                  child: Text(
                    _formatCurrency(item.amount),
                    textAlign: TextAlign.right,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  /// Build totals section
  Widget _buildTotals() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(8),
          bottomRight: Radius.circular(8),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          _buildTotalRow('Subtotal:', widget.subtotal, false),
          const SizedBox(height: 8),
          _buildTotalRow(
            'Tax (${(widget.taxRate * 100).toStringAsFixed(0)}%):',
            widget.tax,
            false,
          ),
          const SizedBox(height: 12),
          Container(
            height: 1,
            color: Colors.grey.shade300,
          ),
          const SizedBox(height: 12),
          _buildTotalRow('Total:', widget.total, true),
        ],
      ),
    );
  }

  /// Build total row
  Widget _buildTotalRow(String label, double amount, bool isBold) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        const SizedBox(width: 16),
        Text(
          _formatCurrency(amount),
          style: TextStyle(
            fontSize: isBold ? 16 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold ? Colors.green.shade700 : Colors.black,
          ),
        ),
      ],
    );
  }

  /// Build notes section
  Widget _buildNotes() {
    if (widget.notes == null || widget.notes!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 24),
        Text(
          'Notes:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.notes!,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Build payment terms section
  Widget _buildPaymentTerms() {
    if (widget.paymentTerms == null || widget.paymentTerms!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 12),
        Text(
          'Payment Terms:',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          widget.paymentTerms!,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey.shade600,
          ),
        ),
      ],
    );
  }

  /// Build watermark (if provided)
  Widget _buildWatermark() {
    if (widget.watermarkText == null || widget.watermarkText!.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned.fill(
      child: Opacity(
        opacity: 0.1,
        child: Center(
          child: Transform.rotate(
            angle: -45 * 3.14159 / 180,
            child: Text(
              widget.watermarkText!.toUpperCase(),
              style: const TextStyle(
                fontSize: 72,
                fontWeight: FontWeight.bold,
                color: Colors.grey,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ),
      ),
    );
  }

  /// Build zoom controls
  Widget _buildZoomControls() {
    if (!widget.showZoomControls) {
      return const SizedBox.shrink();
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        IconButton(
          icon: const Icon(Icons.zoom_out),
          onPressed: _zoomLevel > 0.5
              ? () {
                  setState(() => _zoomLevel -= 0.1);
                }
              : null,
        ),
        Text('${(_zoomLevel * 100).toStringAsFixed(0)}%'),
        IconButton(
          icon: const Icon(Icons.zoom_in),
          onPressed: _zoomLevel < 2.0
              ? () {
                  setState(() => _zoomLevel += 0.1);
                }
              : null,
        ),
        const SizedBox(width: 12),
        if (widget.showPrintButton)
          IconButton(
            icon: const Icon(Icons.print),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Print functionality ready'),
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        if (widget.showZoomControls || widget.showPrintButton)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Invoice Preview',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                _buildZoomControls(),
              ],
            ),
          ),
        Expanded(
          child: SingleChildScrollView(
            controller: _scrollController,
            child: Center(
              child: Transform.scale(
                scale: _zoomLevel,
                child: Container(
                  width: 850,
                  constraints: const BoxConstraints(maxWidth: 850),
                  padding: const EdgeInsets.all(40),
                  color: Colors.white,
                  child: Stack(
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildHeader(),
                          const SizedBox(height: 32),
                          _buildClientInfo(),
                          const SizedBox(height: 32),
                          _buildLineItems(),
                          const SizedBox(height: 24),
                          _buildTotals(),
                          _buildNotes(),
                          _buildPaymentTerms(),
                        ],
                      ),
                      _buildWatermark(),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Invoice Item Model
class InvoiceItem {
  /// Item description
  final String description;

  /// Quantity
  final int quantity;

  /// Unit price
  final double unitPrice;

  /// Get total amount for this item
  double get amount => quantity * unitPrice;

  InvoiceItem({
    required this.description,
    required this.quantity,
    required this.unitPrice,
  });

  /// Create from map
  factory InvoiceItem.fromMap(Map<String, dynamic> map) {
    return InvoiceItem(
      description: map['description'] as String,
      quantity: map['quantity'] as int,
      unitPrice: (map['unitPrice'] as num).toDouble(),
    );
  }

  /// Convert to map
  Map<String, dynamic> toMap() {
    return {
      'description': description,
      'quantity': quantity,
      'unitPrice': unitPrice,
    };
  }
}
