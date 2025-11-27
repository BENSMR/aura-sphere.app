import 'package:flutter/material.dart';
import '../services/ai/openai_crm_service.dart';

class CrmInsightsProvider extends ChangeNotifier {
  final OpenAICrmService _service;
  bool loading = false;
  Map<String, dynamic>? insights;
  String? error;
  String? source; // "cache" or "openai"
  bool cached = false;
  bool cooldown = false;
  String? nextAllowedAt;

  CrmInsightsProvider({OpenAICrmService? service}) : _service = service ?? OpenAICrmService();

  Future<void> generate(String userId, {List<String>? contactIds}) async {
    loading = true;
    error = null;
    insights = null;
    source = null;
    cached = false;
    cooldown = false;
    nextAllowedAt = null;
    notifyListeners();
    
    try {
      final res = await _service.generateCrmInsights(userId: userId, contactIds: contactIds);
      
      // Handle enhanced response format
      source = res['source'] ?? 'unknown';
      cached = res['cached'] ?? false;
      cooldown = res['cooldown'] ?? false;
      nextAllowedAt = res['nextAllowedAt'];
      
      insights = res['insights'] ?? res; // fallback for old format
    } catch (e) {
      error = e.toString();
    } finally {
      loading = false;
      notifyListeners();
    }
  }
}