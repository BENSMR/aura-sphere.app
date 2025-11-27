import 'package:cloud_functions/cloud_functions.dart';

class EmailGeneratorService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Generate a professional email using AI
  /// 
  /// [type] - Email type: 'follow_up', 'proposal', 'intro', 'closing', etc.
  /// [contactName] - Name of the email recipient
  /// [details] - Context about the situation (optional)
  /// [goal] - What you want to achieve with this email
  /// 
  /// Returns a map with 'subject', 'text', and 'html' keys
  static Future<Map<String, dynamic>> generateEmail({
    required String type,
    required String contactName,
    required String goal,
    String details = '',
  }) async {
    try {
      final result = await _functions.httpsCallable('generateEmail').call({
        'type': type,
        'contactName': contactName,
        'goal': goal,
        'details': details,
      });

      return Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      throw EmailGenerationException(
        message: e.message ?? 'Failed to generate email',
        code: e.code,
      );
    } catch (e) {
      throw EmailGenerationException(
        message: e.toString(),
        code: 'unknown',
      );
    }
  }
}

class EmailGenerationException implements Exception {
  final String message;
  final String code;

  EmailGenerationException({
    required this.message,
    required this.code,
  });

  @override
  String toString() => 'EmailGenerationException($code): $message';
}
