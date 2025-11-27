import 'package:cloud_functions/cloud_functions.dart';
import '../../core/utils/logger.dart';

class AuraTokenService {
  static final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Reward a user with AuraTokens for specific actions
  static Future<Map<String, dynamic>?> rewardUser({
    required String userId,
    required String action,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('rewardUser');
      
      final result = await callable.call({
        'userId': userId,
        'action': action,
        'metadata': metadata ?? {},
      });

      Logger.info('AuraToken reward successful: ${result.data}');
      return result.data as Map<String, dynamic>?;
    } catch (e) {
      Logger.error('Failed to reward user with AuraTokens', error: e);
      return null;
    }
  }

  /// Get user's current AuraToken balance
  static Future<int> getTokenBalance(String userId) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getTokenBalance');
      
      final result = await callable.call({
        'userId': userId,
      });

      return result.data['balance'] as int? ?? 0;
    } catch (e) {
      Logger.error('Failed to get token balance', error: e);
      return 0;
    }
  }

  /// Get user's token transaction history
  static Future<List<Map<String, dynamic>>> getTokenHistory(String userId) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('getTokenHistory');
      
      final result = await callable.call({
        'userId': userId,
      });

      return List<Map<String, dynamic>>.from(result.data['transactions'] ?? []);
    } catch (e) {
      Logger.error('Failed to get token history', error: e);
      return [];
    }
  }

  /// Reward user for common actions
  static Future<void> rewardWelcomeBonus(String userId) async {
    await rewardUser(
      userId: userId,
      action: 'welcome_bonus',
      metadata: {'source': 'signup'},
    );
  }

  static Future<void> rewardDailyLogin(String userId) async {
    await rewardUser(
      userId: userId,
      action: 'daily_login',
      metadata: {'date': DateTime.now().toIso8601String()},
    );
  }

  static Future<void> rewardProjectCreation(String userId, String projectId) async {
    await rewardUser(
      userId: userId,
      action: 'create_project',
      metadata: {'projectId': projectId},
    );
  }

  static Future<void> rewardInvoiceCreation(String userId, String invoiceId) async {
    await rewardUser(
      userId: userId,
      action: 'create_invoice',
      metadata: {'invoiceId': invoiceId},
    );
  }

  /// Verify user's token data in Firestore (for debugging)
  static Future<Map<String, dynamic>?> verifyTokenData(String userId) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('verifyUserTokenData');
      
      final result = await callable.call({
        'userId': userId,
      });

      Logger.info('Token verification result: ${result.data}');
      return result.data as Map<String, dynamic>?;
    } catch (e) {
      Logger.error('Failed to verify token data', error: e);
      return null;
    }
  }

  /// Print verification results for debugging
  static Future<void> printTokenVerification(String userId) async {
    final verification = await verifyTokenData(userId);
    
    if (verification != null) {
      print('=== AURATOKEN VERIFICATION ===');
      print('Wallet Path: ${verification['walletPath']}');
      print('Audit Path: ${verification['auditPath']}');
      print('Wallet Data: ${verification['wallet']}');
      print('Recent Audit Records:');
      
      final auditRecords = verification['auditRecords'] as List<dynamic>? ?? [];
      for (var i = 0; i < auditRecords.length; i++) {
        final record = auditRecords[i];
        print('  ${i + 1}. Action: ${record['action']}, Amount: ${record['amount']}, Date: ${record['createdAt']}');
      }
      print('==============================');
    }
  }
}
