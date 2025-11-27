import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../core/constants/env.dart';
import '../../core/utils/logger.dart';

class OpenAIService {
  static const String _baseUrl = 'https://api.openai.com/v1';

  Future<String> chatCompletion(String prompt) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/chat/completions'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer ${Env.currentOpenaiKey}',
        },
        body: jsonEncode({
          'model': 'gpt-4',
          'messages': [
            {'role': 'user', 'content': prompt}
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return data['choices'][0]['message']['content'];
      } else {
        throw Exception('OpenAI API error: ${response.statusCode}');
      }
    } catch (e) {
      Logger.error('OpenAI request failed', error: e);
      rethrow;
    }
  }
}
