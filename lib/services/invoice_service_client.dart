import 'dart:io';import 'package:cloud_functions/cloud_functions.dart';






























































































































































































































final invoiceServiceClient = InvoiceServiceClient();// Singleton instance}  }    }      rethrow;      logger.e('Metadata error: $e');    } catch (e) {      throw Exception('Metadata error: ${e.message}');      logger.e('Firebase Functions error: ${e.code} - ${e.message}');    } on FirebaseFunctionsException catch (e) {      return metadata;      logger.i('Metadata retrieved successfully');      final metadata = Map<String, dynamic>.from(data['metadata'] as Map? ?? {});      }        throw Exception('Metadata request failed: $error');        logger.e('Metadata request failed: $error');        final error = data['error'] as String? ?? 'Unknown error';      if (data['success'] != true) {      final data = result.data as Map<dynamic, dynamic>;      }        throw Exception('Metadata request failed: no response from server');        logger.e('Metadata request returned null data');      if (result.data == null) {      final result = await _exportAllFormats.call(invoiceData);      // Call exportAllFormats which includes metadata in response      logger.i('Getting export metadata');    try {  ) async {    Map<String, dynamic> invoiceData,  Future<Map<String, dynamic>> getExportMetadata(  /// ```  /// // }  /// //   }  /// //     ...  /// //     'png': 50000,  /// //     'pdf': 25600,  /// //   'sizes': {  /// //   'timestamp': '2025-11-27T...',  /// // metadata: {  /// final metadata = await client.getExportMetadata(invoiceData);  /// ```dart  /// Returns file sizes and generation timestamps  ///  /// Get metadata about exported files  }    }      rethrow;      logger.e('Download error: $e');    } catch (e) {      return Uint8List.fromList(bytes);      logger.i('Downloaded ${bytes.length} bytes');      final bytes = await httpResponse.expand((x) => x).toList();      }        );          'Download failed with status ${httpResponse.statusCode}',        throw Exception(        logger.e('Download failed with status ${httpResponse.statusCode}');      if (httpResponse.statusCode != 200) {      final httpResponse = await response.close();      final response = await HttpClient().getUrl(uri);      final uri = Uri.parse(url);      logger.i('Downloading file from URL');    try {  Future<Uint8List> downloadFile(String url) async {  /// ```  /// final path = await client.downloadFile(url, 'invoice.pdf');  /// ```dart  /// Returns the file path where it was saved  ///  /// Download file from a signed URL and save to device  }    }      rethrow;      logger.e('Error opening URL: $e');    } catch (e) {      logger.i('URL opened successfully');      }        throw Exception('Could not open $url');        logger.e('Could not open URL: $url');      )) {        mode: LaunchMode.externalApplication,        uri,      if (!await launchUrl(      final uri = Uri.parse(url);      logger.i('Opening URL: $url');    try {  Future<void> openUrl(String url) async {  /// ```  /// await client.openUrl(pdfUrl);  /// ```dart  ///  /// Open a URL in the external browser or app  }    }      rethrow;      logger.e('PDF export error: $e');    } catch (e) {      throw Exception('PDF export error: ${e.message}');      logger.e('Firebase Functions error: ${e.code} - ${e.message}');    } on FirebaseFunctionsException catch (e) {      return url;      logger.i('PDF export successful');      }        throw Exception('PDF export failed: invalid URL');        logger.e('PDF export returned empty URL');      if (url == null || url.isEmpty) {      final url = data['url'] as String?;      }        throw Exception('PDF export failed: $error');        logger.e('PDF export failed: $error');        final error = data['error'] as String? ?? 'Unknown error';      if (data['success'] != true) {      final data = result.data as Map<dynamic, dynamic>;      }        throw Exception('PDF export failed: no response from server');        logger.e('PDF export returned null data');      if (result.data == null) {      final result = await _generatePdf.call(invoiceData);      logger.i('Exporting invoice as PDF');    try {  ) async {    Map<String, dynamic> invoiceData,  Future<String> exportInvoicePdf(  /// ```  /// final url = await client.exportInvoicePdf(invoiceData);  /// ```dart  ///  /// Export invoice as PDF only  }    }      rethrow;      logger.e('Export error: $e');    } catch (e) {      throw Exception('Export error: ${e.message}');      logger.e('Firebase Functions error: ${e.code} - ${e.message}');    } on FirebaseFunctionsException catch (e) {      return resultUrls;      logger.i('Export successful. Generated ${resultUrls.length} formats');      final resultUrls = urls.map((k, v) => MapEntry(k as String, v as String));      // Convert to Map<String, String>      final urls = Map<String, dynamic>.from(data['urls'] as Map? ?? {});      // Extract URLs from response      }        throw Exception('Export failed: $error');        logger.e('Export failed: $error');        final error = data['error'] as String? ?? 'Unknown error';      if (data['success'] != true) {      final data = result.data as Map<dynamic, dynamic>;      }        throw Exception('Export failed: no response from server');        logger.e('Export returned null data');      if (result.data == null) {      final result = await _exportAllFormats.call(invoiceData);      logger.i('Exporting invoice in all formats');    try {  ) async {    Map<String, dynamic> invoiceData,  Future<Map<String, String>> exportInvoiceAllFormats(  /// ```  /// // }  /// //   'zip': 'https://...'  /// //   'csv': 'https://...',  /// //   'docx': 'https://...',  /// //   'png': 'https://...',  /// //   'pdf': 'https://...',  /// // urls: {  /// final urls = await client.exportInvoiceAllFormats(invoiceData);  /// ```dart  /// Returns a map of format -> download URL  ///  /// Export invoice in all formats (PDF, PNG, DOCX, CSV, ZIP)      FirebaseFunctions.instance.httpsCallable('generateInvoicePdf');  late final HttpsCallable _generatePdf =      FirebaseFunctions.instance.httpsCallable('exportInvoiceFormats');  late final HttpsCallable _exportAllFormats =  // Cloud Function referencesclass InvoiceServiceClient {/// for exporting invoices in multiple formats./// This service provides a clean interface to the Cloud Functions////// Client service for calling Cloud Functions for invoice exportimport 'package:aura_sphere_pro/utils/logger.dart';import 'package:url_launcher/url_launcher.dart';import 'package:cloud_functions/cloud_functions.dart';import 'dart:typed_data';import 'package:url_launcher/url_launcher.dart';
import 'package:aura_sphere_pro/utils/logger.dart';

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
      logger.i('Exporting invoice in all formats');

      final result = await _exportAllFormats.call(invoiceData);

      if (result.data == null) {
        logger.e('Export returned null data');
        throw Exception('Export failed: no response from server');
      }

      final data = result.data as Map<dynamic, dynamic>;

      if (data['success'] != true) {
        final error = data['error'] as String? ?? 'Unknown error';
        logger.e('Export failed: $error');
        throw Exception('Export failed: $error');
      }

      // Extract URLs from response
      final urls = Map<String, dynamic>.from(data['urls'] as Map? ?? {});

      // Convert to Map<String, String>
      final result_urls = urls.map((k, v) => MapEntry(k as String, v as String));

      logger.i('Export successful. Generated ${result_urls.length} formats');
      return result_urls;
    } on FirebaseFunctionsException catch (e) {
      logger.e('Firebase Functions error: ${e.code} - ${e.message}');
      throw Exception('Export error: ${e.message}');
    } catch (e) {
      logger.e('Export error: $e');
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
      logger.i('Exporting invoice as PDF');

      final result = await _generatePdf.call(invoiceData);

      if (result.data == null) {
        logger.e('PDF export returned null data');
        throw Exception('PDF export failed: no response from server');
      }

      final data = result.data as Map<dynamic, dynamic>;

      if (data['success'] != true) {
        final error = data['error'] as String? ?? 'Unknown error';
        logger.e('PDF export failed: $error');
        throw Exception('PDF export failed: $error');
      }

      final url = data['url'] as String?;
      if (url == null || url.isEmpty) {
        logger.e('PDF export returned empty URL');
        throw Exception('PDF export failed: invalid URL');
      }

      logger.i('PDF export successful');
      return url;
    } on FirebaseFunctionsException catch (e) {
      logger.e('Firebase Functions error: ${e.code} - ${e.message}');
      throw Exception('PDF export error: ${e.message}');
    } catch (e) {
      logger.e('PDF export error: $e');
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
      logger.i('Opening URL: $url');

      final uri = Uri.parse(url);

      if (!await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      )) {
        logger.e('Could not open URL: $url');
        throw Exception('Could not open $url');
      }

      logger.i('URL opened successfully');
    } catch (e) {
      logger.e('Error opening URL: $e');
      rethrow;
    }
  }

  /// Download file from a signed URL and save to device
  ///
  /// Returns the file path where it was saved
  /// ```dart
  /// final path = await client.downloadFile(url, 'invoice.pdf');
  /// ```
  Future<Uint8List> downloadFile(String url) async {
    try {
      logger.i('Downloading file from URL');

      final uri = Uri.parse(url);
      final response = await HttpClient().getUrl(uri);
      final httpResponse = await response.close();

      if (httpResponse.statusCode != 200) {
        logger.e('Download failed with status ${httpResponse.statusCode}');
        throw Exception(
          'Download failed with status ${httpResponse.statusCode}',
        );
      }

      final bytes = await httpResponse.expand((x) => x).toList();
      logger.i('Downloaded ${bytes.length} bytes');

      return Uint8List.fromList(bytes);
    } catch (e) {
      logger.e('Download error: $e');
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
      logger.i('Getting export metadata');

      // Call exportAllFormats which includes metadata in response
      final result = await _exportAllFormats.call(invoiceData);

      if (result.data == null) {
        logger.e('Metadata request returned null data');
        throw Exception('Metadata request failed: no response from server');
      }

      final data = result.data as Map<dynamic, dynamic>;

      if (data['success'] != true) {
        final error = data['error'] as String? ?? 'Unknown error';
        logger.e('Metadata request failed: $error');
        throw Exception('Metadata request failed: $error');
      }

      final metadata = Map<String, dynamic>.from(data['metadata'] as Map? ?? {});

      logger.i('Metadata retrieved successfully');
      return metadata;
    } on FirebaseFunctionsException catch (e) {
      logger.e('Firebase Functions error: ${e.code} - ${e.message}');
      throw Exception('Metadata error: ${e.message}');
    } catch (e) {
      logger.e('Metadata error: $e');
      rethrow;
    }
  }
}

// Singleton instance
final invoiceServiceClient = InvoiceServiceClient();
