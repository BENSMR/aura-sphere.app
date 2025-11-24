import 'functions_service.dart';

class SubscriptionService {
  final FunctionsService _functions = FunctionsService();

  Future<void> createSubscription(String userId, String plan) async {
    await _functions.callFunction('createSubscription', {
      'userId': userId,
      'plan': plan,
    });
  }

  Future<Map<String, dynamic>> getSubscriptionStatus(String userId) async {
    return await _functions.callFunction('getSubscriptionStatus', {
      'userId': userId,
    });
  }
}
