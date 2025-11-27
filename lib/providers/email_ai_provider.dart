import 'package:flutter/material.dart';
import '../../services/ai/email_ai_service.dart';

class EmailAiProvider extends ChangeNotifier {
  EmailGenerated? _lastEmail;
  bool _isLoading = false;
  String? _error;

  EmailGenerated? get lastEmail => _lastEmail;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get hasEmail => _lastEmail != null;

  /// Generate an email using AI
  Future<EmailGenerated?> generateEmail({
    required String type,
    required String contactName,
    required String goal,
    String details = '',
  }) async {
    _isLoading = true;
    _error = null;
    notifyListeners();

    try {
      final result = await EmailAiService.generate(
        type: type,
        contactName: contactName,
        details: details,
        goal: goal,
      );

      _lastEmail = EmailGenerated.fromJson(result);
      notifyListeners();
      return _lastEmail;
    } on EmailAiException catch (e) {
      _error = e.message;
      _lastEmail = null;
      notifyListeners();
      return null;
    } catch (e) {
      _error = e.toString();
      _lastEmail = null;
      notifyListeners();
      return null;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Clear the last generated email
  void clearEmail() {
    _lastEmail = null;
    _error = null;
    notifyListeners();
  }

  /// Clear the error message
  void clearError() {
    _error = null;
    notifyListeners();
  }
}
