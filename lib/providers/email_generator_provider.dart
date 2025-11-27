import 'package:flutter/material.dart';
import '../../services/email/email_generator_service.dart';

class GeneratedEmail {
  final String subject;
  final String text;
  final String html;

  GeneratedEmail({
    required this.subject,
    required this.text,
    required this.html,
  });

  factory GeneratedEmail.fromJson(Map<String, dynamic> json) {
    return GeneratedEmail(
      subject: json['subject'] ?? '',
      text: json['text'] ?? '',
      html: json['html'] ?? '',
    );
  }
}

class EmailGeneratorProvider extends ChangeNotifier {
  GeneratedEmail? _lastEmail;
  bool _isLoading = false;
  String? _error;

  GeneratedEmail? get lastEmail => _lastEmail;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasEmail => _lastEmail != null;

  Future<GeneratedEmail?> generateEmail({
    required String type,
    required String contactName,
    required String goal,
    String details = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await EmailGeneratorService.generateEmail(
        type: type,
        contactName: contactName,
        goal: goal,
        details: details,
      );

      _lastEmail = GeneratedEmail.fromJson(result);
      return _lastEmail;
    } on EmailGenerationException catch (e) {
      _error = e.message;
      _lastEmail = null;
      return null;
    } catch (e) {
      _error = e.toString();
      _lastEmail = null;
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void clearEmail() {
    _lastEmail = null;
    _error = null;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }
}
