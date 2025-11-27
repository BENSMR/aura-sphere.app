import 'package:flutter/material.dart';
import '../../models/invoice_model.dart';
import '../../services/pdf/invoice_pdf_handler.dart';

/// Example 1: Simple Print Button
class PrintInvoiceButton extends StatefulWidget {
  final InvoiceModel invoice;

  const PrintInvoiceButton({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  State<PrintInvoiceButton> createState() => _PrintInvoiceButtonState();
}

class _PrintInvoiceButtonState extends State<PrintInvoiceButton> {
  bool _isLoading = false;

  Future<void> _handlePrint() async {
    setState(() => _isLoading = true);
    try {
      await InvoicePdfHandler.printInvoice(widget.invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Invoice sent to printer')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handlePrint,
      icon: _isLoading ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ) : Icon(Icons.print),
      label: Text(_isLoading ? 'Printing...' : 'Print Invoice'),
    );
  }
}

/// Example 2: Share Invoice Button
class ShareInvoiceButton extends StatefulWidget {
  final InvoiceModel invoice;

  const ShareInvoiceButton({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  State<ShareInvoiceButton> createState() => _ShareInvoiceButtonState();
}

class _ShareInvoiceButtonState extends State<ShareInvoiceButton> {
  bool _isLoading = false;

  Future<void> _handleShare() async {
    setState(() => _isLoading = true);
    try {
      await InvoicePdfHandler.shareInvoice(widget.invoice);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleShare,
      icon: _isLoading ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ) : Icon(Icons.share),
      label: Text(_isLoading ? 'Sharing...' : 'Share Invoice'),
    );
  }
}

/// Example 3: Save to Device Button
class SaveInvoiceButton extends StatefulWidget {
  final InvoiceModel invoice;

  const SaveInvoiceButton({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  State<SaveInvoiceButton> createState() => _SaveInvoiceButtonState();
}

class _SaveInvoiceButtonState extends State<SaveInvoiceButton> {
  bool _isLoading = false;

  Future<void> _handleSave() async {
    setState(() => _isLoading = true);
    try {
      final filePath = await InvoicePdfHandler.saveToFile(widget.invoice);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Saved to: ${widget.invoice.invoiceNumber}.pdf')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ElevatedButton.icon(
      onPressed: _isLoading ? null : _handleSave,
      icon: _isLoading ? SizedBox(
        width: 20,
        height: 20,
        child: CircularProgressIndicator(strokeWidth: 2),
      ) : Icon(Icons.download),
      label: Text(_isLoading ? 'Saving...' : 'Save to Device'),
    );
  }
}

/// Example 4: Invoice Detail Screen with PDF Actions
class InvoiceDetailWithPdf extends StatefulWidget {
  final InvoiceModel invoice;

  const InvoiceDetailWithPdf({
    Key? key,
    required this.invoice,
  }) : super(key: key);

  @override
  State<InvoiceDetailWithPdf> createState() => _InvoiceDetailWithPdfState();
}

class _InvoiceDetailWithPdfState extends State<InvoiceDetailWithPdf> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Invoice ${widget.invoice.invoiceNumber}'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Invoice details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Bill To: ${widget.invoice.clientName}',
                        style: Theme.of(context).textTheme.titleLarge,
                      ),
                      SizedBox(height: 8),
                      Text(widget.invoice.clientEmail),
                      SizedBox(height: 16),
                      Text(
                        'Total: ${widget.invoice.currency} ${widget.invoice.total.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 24),

              // PDF Action Buttons
              Text(
                'Export Invoice',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              SizedBox(height: 12),
              Wrap(
                spacing: 12,
                runSpacing: 12,
                children: [
                  PrintInvoiceButton(invoice: widget.invoice),
                  ShareInvoiceButton(invoice: widget.invoice),
                  SaveInvoiceButton(invoice: widget.invoice),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Example 5: Saved Invoices List
class SavedInvoicesList extends StatefulWidget {
  const SavedInvoicesList({Key? key}) : super(key: key);

  @override
  State<SavedInvoicesList> createState() => _SavedInvoicesListState();
}

class _SavedInvoicesListState extends State<SavedInvoicesList> {
  late Future<List<String>> _savedInvoices;

  @override
  void initState() {
    super.initState();
    _loadSavedInvoices();
  }

  Future<void> _loadSavedInvoices() async {
    setState(() {
      _savedInvoices = InvoicePdfHandler.getSavedInvoices().then(
        (files) => files.map((f) => f.path).toList(),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<String>>(
      future: _savedInvoices,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}'));
        }

        final files = snapshot.data ?? [];
        if (files.isEmpty) {
          return Center(child: Text('No saved invoices'));
        }

        return ListView.builder(
          itemCount: files.length,
          itemBuilder: (context, index) {
            final filePath = files[index];
            final fileName = filePath.split('/').last;
            return ListTile(
              title: Text(fileName),
              subtitle: FutureBuilder<double>(
                future: InvoicePdfHandler.getFileSizeInMB(filePath),
                builder: (context, snapshot) {
                  if (snapshot.hasData) {
                    return Text('${snapshot.data?.toStringAsFixed(2)} MB');
                  }
                  return Text('...');
                },
              ),
              trailing: IconButton(
                icon: Icon(Icons.delete),
                onPressed: () async {
                  await InvoicePdfHandler.deleteSavedInvoice(filePath);
                  _loadSavedInvoices();
                },
              ),
            );
          },
        );
      },
    );
  }
}

/// Example 6: Invoice Action Menu
class InvoiceActionMenu extends StatelessWidget {
  final InvoiceModel invoice;
  final VoidCallback onPrint;
  final VoidCallback onShare;
  final VoidCallback onSave;

  const InvoiceActionMenu({
    Key? key,
    required this.invoice,
    required this.onPrint,
    required this.onShare,
    required this.onSave,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      itemBuilder: (context) => [
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.print, size: 20),
              SizedBox(width: 12),
              Text('Print'),
            ],
          ),
          onTap: onPrint,
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.share, size: 20),
              SizedBox(width: 12),
              Text('Share'),
            ],
          ),
          onTap: onShare,
        ),
        PopupMenuItem(
          child: Row(
            children: [
              Icon(Icons.download, size: 20),
              SizedBox(width: 12),
              Text('Save'),
            ],
          ),
          onTap: onSave,
        ),
      ],
    );
  }
}
