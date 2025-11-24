import 'functions_service.dart';

class AuraTokenService {
  final FunctionsService _functions = FunctionsService();

  Future<int> getBalance(String userId) async {
    final result = await _functions.callFunction('getAuraTokenBalance', {
      'userId': userId,
    });
    return result['balance'];
  }

  Future<void> rewardTokens(String userId, int amount, String reason) async {
    await _functions.callFunction('rewardAuraTokens', {
      'userId': userId,
      'amount': amount,
      'reason': reason,
    });
  }
}
