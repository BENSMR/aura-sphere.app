import 'package:cloud_functions/cloud_functions.dart';

class EmailAiService {
  static final _functions = FirebaseFunctions.instance;

  /// Generate a professional email using AI
  /// 
  /// [type] - Email type: 'follow_up', 'proposal', 'intro', 'closing', etc.
  /// [contactName] - Name of the email recipient
  /// [details] - Context about the situation
  /// [goal] - What you want to achieve with this email
  /// 
  /// Returns a map with 'subject', 'text', and 'html' keys
  static Future<Map<String, dynamic>> generate({
    required String type,
    required String contactName,
    required String details,
    required String goal,
  }) async {
    try {
      final callable = _functions.httpsCallable('generateEmail');

      final result = await callable.call({
        'type': type,
        'contactName': contactName,
        'details': details,
        'goal': goal,
      });

      return Map<String, dynamic>.from(result.data);
    } on FirebaseFunctionsException catch (e) {
      throw EmailAiException(
        message: e.message ?? 'Failed to generate email',
        code: e.code,
      );
    } catch (e) {
      throw EmailAiException(
        message: e.toString(),
        code: 'unknown',
      );
    }
  }

  /// Parse the generated email response
  static EmailGenerated parseResponse(Map<String, dynamic> data) {
    return EmailGenerated(
      subject: data['subject'] ?? '',
      text: data['text'] ?? '',
      html: data['html'] ?? data['text'] ?? '',
    );
  }
}

class EmailGenerated {
  final String subject;
  final String text;
  final String html;

  EmailGenerated({
    required this.subject,
    required this.text,
    required this.html,
  });

  factory EmailGenerated.fromJson(Map<String, dynamic> json) {
    return EmailGenerated(
      subject: json['subject'] ?? '',
      text: json['text'] ?? '',
      html: json['html'] ?? json['text'] ?? '',
    );
  }

  Map<String, dynamic> toJson() => {
    'subject': subject,
    'text': text,
    'html': html,
  };
}

class EmailAiException implements Exception {
  final String message;
  final String code;

  EmailAiException({
    required this.message,
    required this.code,
  });

  @override
  String toString() => 'EmailAiException($code): $message';
}
