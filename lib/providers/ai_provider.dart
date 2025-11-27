import 'package:flutter/material.dart';
import '../services/ai/openai_service.dart';

class AIProvider with ChangeNotifier {
  final OpenAIService _openAI = OpenAIService();
  List<Map<String, String>> _messages = [];
  bool _isLoading = false;

  List<Map<String, String>> get messages => _messages;
  bool get isLoading => _isLoading;

  Future<void> sendMessage(String message) async {
    _messages.add({'role': 'user', 'content': message});
    notifyListeners();

    _isLoading = true;
    notifyListeners();

    try {
      final response = await _openAI.chatCompletion(message);
      _messages.add({'role': 'assistant', 'content': response});
    } catch (e) {
      // Handle error
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
