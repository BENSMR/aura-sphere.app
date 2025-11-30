import 'dart:io';
import 'dart:typed_data';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:aurasphere_pro/utils/simple_logger.dart';

/// Client service for calling Cloud Functions for invoice export
///
/// This service provides a clean interface to the Cloud Functions
/// for exporting invoices in multiple formats.
class InvoiceServiceClient {
  // Cloud Function references
  late final HttpsCallable _exportAllFormats =
      FirebaseFunctions.instance.httpsCallable('exportInvoiceFormats');

  late final HttpsCallable _generatePdf =
      FirebaseFunctions.instance.httpsCallable('generateInvoicePdf');

  /// Export invoice in all formats (PDF, PNG, DOCX, CSV, ZIP)
  ///
  /// Returns a map of format -> download URL
  /// ```dart
  /// final urls = await client.exportInvoiceAllFormats(invoiceData);
  /// // urls: {
  /// //   'pdf': 'https://...',
  /// //   'png': 'https://...',
  /// //   'docx': 'https://...',
  /// //   'csv': 'https://...',
  /// //   'zip': 'https://...'
  /// // }
  /// ```
  Future<Map<String, String>> exportInvoiceAllFormats(
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      SimpleLogger.i('Exporting invoice in all formats');

      final result = await _exportAllFormats.call(invoiceData);

      if (result.data == null) {
        SimpleLogger.e('Export returned null data');
        throw Exception('Export failed: no response from server');
      }

      final data = result.data as Map<dynamic, dynamic>;

      if (data['success'] != true) {
        final error = data['error'] as String? ?? 'Unknown error';
        SimpleLogger.e('Export failed: $error');
        throw Exception('Export failed: $error');
      }

      // Extract URLs from response
      final urls = Map<String, dynamic>.from(data['urls'] as Map? ?? {});

      // Convert to Map<String, String>
      final resultUrls = urls.map((k, v) => MapEntry(k as String, v as String));

      SimpleLogger.i('Export successful. Generated ${resultUrls.length} formats');
      return resultUrls;
    } on FirebaseFunctionsException catch (e) {
      SimpleLogger.e('Firebase Functions error: ${e.code} - ${e.message}');
      throw Exception('Export error: ${e.message}');
    } catch (e) {
      SimpleLogger.e('Export error: $e');
      rethrow;
    }
  }

  /// Export invoice as PDF only
  ///
  /// ```dart
  /// final url = await client.exportInvoicePdf(invoiceData);
  /// ```
  Future<String> exportInvoicePdf(
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      SimpleLogger.i('Exporting invoice as PDF');

      final result = await _generatePdf.call(invoiceData);

      if (result.data == null) {
        SimpleLogger.e('PDF export returned null data');
        throw Exception('PDF export failed: no response from server');
      }

      final data = result.data as Map<dynamic, dynamic>;

      if (data['success'] != true) {
        final error = data['error'] as String? ?? 'Unknown error';
        SimpleLogger.e('PDF export failed: $error');
        throw Exception('PDF export failed: $error');
      }

      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        SimpleLogger.e('PDF export returned empty URL');
        throw Exception('PDF export failed: invalid URL');
      }

      SimpleLogger.i('PDF export successful');
      return url;
    } on FirebaseFunctionsException catch (e) {
      SimpleLogger.e('Firebase Functions error: ${e.code} - ${e.message}');
      throw Exception('PDF export error: ${e.message}');
    } catch (e) {
      SimpleLogger.e('PDF export error: $e');
      rethrow;
    }
  }

  /// Open a URL in the external browser or app
  ///
  /// ```dart
  /// await client.openUrl(pdfUrl);
  /// ```
  Future<void> openUrl(String url) async {
    try {
      SimpleLogger.i('Opening URL: $url');

      final uri = Uri.parse(url);

      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        SimpleLogger.e('Could not open URL: $url');
        throw Exception('Could not open $url');
      }

      SimpleLogger.i('URL opened successfully');
    } catch (e) {
      SimpleLogger.e('Error opening URL: $e');
      rethrow;
    }
  }

  /// Download file from a signed URL and save to device
  ///
  /// Returns the file bytes
  /// ```dart
  /// final bytes = await client.downloadFile(url);
  /// ```
  Future<Uint8List> downloadFile(String url) async {
    try {
      SimpleLogger.i('Downloading file from URL');

      final uri = Uri.parse(url);
      final response = await HttpClient().getUrl(uri);
      final httpResponse = await response.close();

      if (httpResponse.statusCode != 200) {
        SimpleLogger.e('Download failed with status ${httpResponse.statusCode}');
        throw Exception(
          'Download failed with status ${httpResponse.statusCode}',
        );
      }

      final bytes = await httpResponse.expand((x) => x).toList();
      SimpleLogger.i('Downloaded ${bytes.length} bytes');

      return Uint8List.fromList(bytes);
    } catch (e) {
      SimpleLogger.e('Download error: $e');
      rethrow;
    }
  }

  /// Get metadata about exported files
  ///
  /// Returns file sizes and generation timestamps
  /// ```dart
  /// final metadata = await client.getExportMetadata(invoiceData);
  /// // metadata: {
  /// //   'timestamp': '2025-11-27T...',
  /// //   'sizes': {
  /// //     'pdf': 25600,
  /// //     'png': 50000,
  /// //     ...
  /// //   }
  /// // }
  /// ```
  Future<Map<String, dynamic>> getExportMetadata(
    Map<String, dynamic> invoiceData,
  ) async {
    try {
      SimpleLogger.i('Getting export metadata');

      // Call exportAllFormats which includes metadata in response
      final result = await _exportAllFormats.call(invoiceData);

      if (result.data == null) {
        SimpleLogger.e('Metadata request returned null data');
        throw Exception('Metadata request failed: no response from server');
      }

      final data = result.data as Map<dynamic, dynamic>;

      if (data['success'] != true) {
        final error = data['error'] as String? ?? 'Unknown error';
        SimpleLogger.e('Metadata request failed: $error');
        throw Exception('Metadata request failed: $error');
      }

      final metadata = Map<String, dynamic>.from(data['metadata'] as Map? ?? {});

      SimpleLogger.i('Metadata retrieved successfully');
      return metadata;
    } on FirebaseFunctionsException catch (e) {
      SimpleLogger.e('Firebase Functions error: ${e.code} - ${e.message}');
      throw Exception('Metadata error: ${e.message}');
    } catch (e) {
      SimpleLogger.e('Metadata error: $e');
      rethrow;
    }
  }
}
