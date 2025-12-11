import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:printing/printing.dart';
import 'package:path_provider/path_provider.dart';
import 'package:intl/intl.dart';

class POPDFPreviewScreen extends StatefulWidget {
  final String poId;
  final String? poNumber;
  final bool autoSaveToDevice;

  const POPDFPreviewScreen({
    Key? key,
    required this.poId,
    this.poNumber,
    this.autoSaveToDevice = false,
  }) : super(key: key);

  @override
  State<POPDFPreviewScreen> createState() => _POPDFPreviewScreenState();
}

class _POPDFPreviewScreenState extends State<POPDFPreviewScreen> {
  bool _loading = true;
  Uint8List? _pdfBytes;
  String? _errorMessage;
  String? _localFilePath;

  @override
  void initState() {
    super.initState();
    _loadPDF();
  }

  /// Fetch PDF from Cloud Function
  Future<void> _loadPDF() async {
    if (!mounted) return;
    setState(() {
      _loading = true;
      _errorMessage = null;
    });

    try {
      debugPrint('[POPDFPreview] Loading PDF for PO: ${widget.poId}');

      final callable =
          FirebaseFunctions.instance.httpsCallable('generatePOPDF');
      final response = await callable.call({
        'poId': widget.poId,
        'saveToStorage': false, // Optional: set true to save to Firebase Storage
      });

      if (!mounted) return;

      final data = response.data as Map<String, dynamic>?;
      if (data == null) {
        throw Exception('Invalid response from server');
      }

      final base64String = data['base64'] as String?;
      if (base64String == null || base64String.isEmpty) {
        throw Exception('No PDF data received');
      }

      final bytes = base64Decode(base64String);
      if (bytes.isEmpty) {
        throw Exception('PDF is empty');
      }

      debugPrint('[POPDFPreview] PDF loaded successfully (${bytes.length} bytes)');

      // Optionally save to device
      if (widget.autoSaveToDevice) {
        await _saveToDevice(bytes);
      }

      if (mounted) {
        setState(() {
          _pdfBytes = bytes;
          _loading = false;
        });
      }
    } on FirebaseFunctionsException catch (e) {
      debugPrint('[POPDFPreview] FirebaseFunctions error: ${e.code} - ${e.message}');
      if (mounted) {
        setState(() {
          _errorMessage = 'Server error: ${e.message}';
          _loading = false;
        });
      }
    } catch (e) {
      debugPrint('[POPDFPreview] Error loading PDF: $e');
      if (mounted) {
        setState(() {
          _errorMessage = 'Failed to load PDF: ${e.toString()}';
          _loading = false;
        });
      }
    }
  }

  /// Save PDF to device local storage
  Future<void> _saveToDevice(Uint8List bytes) async {
    try {
      final directory = await getApplicationDocumentsDirectory();
      final timestamp = DateFormat('yyyyMMdd_HHmmss').format(DateTime.now());
      final filename =
          'PO-${widget.poNumber ?? widget.poId}-$timestamp.pdf';
      final file = File('${directory.path}/$filename');

      await file.writeAsBytes(bytes);
      debugPrint('[POPDFPreview] PDF saved to: ${file.path}');

      if (mounted) {
        setState(() => _localFilePath = file.path);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF saved to: $filename')),
        );
      }
    } catch (e) {
      debugPrint('[POPDFPreview] Error saving PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to save PDF: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Share PDF via system share dialog
  Future<void> _sharePDF() async {
    if (_pdfBytes == null) return;

    try {
      debugPrint('[POPDFPreview] Sharing PDF');
      await Printing.sharePdf(
        bytes: _pdfBytes!,
        filename: 'PO-${widget.poNumber ?? widget.poId}.pdf',
      );
    } catch (e) {
      debugPrint('[POPDFPreview] Error sharing PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to share: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Print PDF via system print dialog
  Future<void> _printPDF() async {
    if (_pdfBytes == null) return;

    try {
      debugPrint('[POPDFPreview] Printing PDF');
      await Printing.layoutPdf(
        onLayout: (_) => _pdfBytes!,
        name: 'PO-${widget.poNumber ?? widget.poId}',
        format: PdfPageFormat.a4,
      );
    } catch (e) {
      debugPrint('[POPDFPreview] Error printing PDF: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to print: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  /// Download PDF to device
  Future<void> _downloadPDF() async {
    if (_pdfBytes == null) return;
    await _saveToDevice(_pdfBytes!);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Purchase Order ${widget.poNumber ?? widget.poId}'),
        elevation: 0,
        actions: [
          if (_pdfBytes != null) ...[
            IconButton(
              icon: const Icon(Icons.download),
              tooltip: 'Download',
              onPressed: _downloadPDF,
            ),
            IconButton(
              icon: const Icon(Icons.share),
              tooltip: 'Share',
              onPressed: _sharePDF,
            ),
            IconButton(
              icon: const Icon(Icons.print),
              tooltip: 'Print',
              onPressed: _printPDF,
            ),
          ],
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    // Loading state
    if (_loading) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            Text(
              'Loading PDF...',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
          ],
        ),
      );
    }

    // Error state
    if (_errorMessage != null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage!,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                    color: Colors.red,
                  ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPDF,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      );
    }

    // No PDF state
    if (_pdfBytes == null) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.description_outlined,
              size: 48,
              color: Colors.grey,
            ),
            const SizedBox(height: 16),
            Text(
              'No PDF generated',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: _loadPDF,
              icon: const Icon(Icons.refresh),
              label: const Text('Try Again'),
            ),
          ],
        ),
      );
    }

    // PDF Preview state
    return Column(
      children: [
        // Info bar
        Container(
          color: Colors.blue.shade50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.info_outline, size: 18, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'PDF Size: ${(_pdfBytes!.length / 1024).toStringAsFixed(1)} KB',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.blue.shade700,
                      ),
                ),
              ),
              if (_localFilePath != null)
                Icon(
                  Icons.check_circle,
                  size: 18,
                  color: Colors.green.shade700,
                ),
            ],
          ),
        ),
        // PDF Preview
        Expanded(
          child: PdfPreview(
            build: (format) => _pdfBytes!,
            allowPrinting: true,
            allowSharing: true,
            pdfFileName: 'PO-${widget.poNumber ?? widget.poId}.pdf',
            canChangeOrientation: true,
            canChangePageFormat: false,
            initialPageFormat: PdfPageFormat.a4,
            actions: [
              // Custom action button: Download
              if (_pdfBytes != null)
                PdfPreviewAction(
                  icon: Icons.download,
                  onPressed: (context) => _downloadPDF(),
                ),
            ],
          ),
        ),
      ],
    );
  }
}
