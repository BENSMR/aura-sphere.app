import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for calling Cloud Functions
/// 
/// Provides typed wrappers for all Cloud Functions with error handling
class FunctionsService {
  static const String _region = 'us-central1';
  
  final CloudFunctions _functions;
  final FirebaseAuth _auth;

  FunctionsService({
    CloudFunctions? functions,
    FirebaseAuth? auth,
  })  : _functions = functions ?? CloudFunctions.instanceFor(region: _region),
        _auth = auth ?? FirebaseAuth.instance;

  String get _uid {
    final user = _auth.currentUser;
    if (user == null) {
      throw Exception('User not logged in');
    }
    return user.uid;
  }

  /// Call a Cloud Function with parameters
  /// 
  /// Generic method that wraps any callable function
  Future<T> callFunction<T>(
    String functionName, {
    Map<String, dynamic>? parameters,
  }) async {
    try {
      final callable = _functions.httpsCallable(functionName);
      final result = await callable.call(parameters ?? {});
      return result.data as T;
    } on FirebaseFunctionsException catch (e) {
      throw Exception('Function error: ${e.message}');
    } catch (e) {
      throw Exception('Failed to call $functionName: $e');
    }
  }

  // ===== CRM Functions =====

  /// Calculate AI score for a single client
  Future<Map<String, dynamic>> calculateClientAIScore(String clientId) async {
    return callFunction<Map<String, dynamic>>(
      'calculateClientAIScore',
      parameters: {
        'clientId': clientId,
        'userId': _uid,
      },
    );
  }

  /// Recalculate AI scores for all clients
  /// 
  /// Returns: {success, updated, failed, total}
  Future<Map<String, dynamic>> recalculateAllClientScores() async {
    return callFunction<Map<String, dynamic>>(
      'recalculateAllClientScoresV2',
      parameters: {'userId': _uid},
    );
  }

  /// Generate AI summary for a client
  /// 
  /// Returns: {success, clientId, aiSummary}
  Future<Map<String, dynamic>> generateClientSummary(String clientId) async {
    return callFunction<Map<String, dynamic>>(
      'regenerateClientSummary',
      parameters: {
        'clientId': clientId,
        'userId': _uid,
      },
    );
  }

  /// Regenerate AI summaries for all clients
  /// 
  /// Returns: {success, generated, failed, total}
  Future<Map<String, dynamic>> regenerateAllClientSummaries() async {
    return callFunction<Map<String, dynamic>>(
      'regenerateAllClientSummariesV2',
      parameters: {'userId': _uid},
    );
  }

  // ===== Invoice Functions =====

  /// Generate invoice PDF
  /// 
  /// Returns: {success, downloadUrl}
  Future<Map<String, dynamic>> generateInvoicePdf(
    String invoiceId, {
    bool includeWatermark = false,
  }) async {
    return callFunction<Map<String, dynamic>>(
      'generateInvoicePdf',
      parameters: {
        'invoiceId': invoiceId,
        'userId': _uid,
        'includeWatermark': includeWatermark,
      },
    );
  }

  /// Send invoice email
  /// 
  /// Returns: {success, sent, recipientEmail}
  Future<Map<String, dynamic>> sendInvoiceEmail(
    String invoiceId,
    String recipientEmail, {
    String subject = 'Invoice',
    String? message,
  }) async {
    return callFunction<Map<String, dynamic>>(
      'sendInvoiceEmail',
      parameters: {
        'invoiceId': invoiceId,
        'recipientEmail': recipientEmail,
        'subject': subject,
        'message': message,
        'userId': _uid,
      },
    );
  }

  // ===== AI Functions =====

  /// Generate email using OpenAI
  /// 
  /// Returns: {success, email}
  Future<Map<String, dynamic>> generateEmail(
    String prompt, {
    int maxTokens = 500,
  }) async {
    return callFunction<Map<String, dynamic>>(
      'generateEmail',
      parameters: {
        'prompt': prompt,
        'maxTokens': maxTokens,
      },
    );
  }

  // ===== OCR Functions =====

  /// Process receipt image via Vision API
  /// 
  /// Returns: {success, data, extracted}
  Future<Map<String, dynamic>> processReceiptOCR(
    String storagePathImage, {
    String? hints,
  }) async {
    return callFunction<Map<String, dynamic>>(
      'visionOcr',
      parameters: {
        'imagePath': storagePathImage,
        'hints': hints,
        'userId': _uid,
      },
    );
  }

  // ===== Billing Functions =====

  /// Create Stripe checkout session
  /// 
  /// Returns: {success, sessionId, clientSecret}
  Future<Map<String, dynamic>> createCheckoutSession({
    required String planId,
    String? couponCode,
    required String successUrl,
    required String cancelUrl,
  }) async {
    return callFunction<Map<String, dynamic>>(
      'createCheckoutSessionBilling',
      parameters: {
        'planId': planId,
        'couponCode': couponCode,
        'successUrl': successUrl,
        'cancelUrl': cancelUrl,
        'userId': _uid,
      },
    );
  }

  /// Audit payment event
  /// 
  /// Returns: {success, auditId}
  Future<Map<String, dynamic>> auditPaymentEvent(
    String eventType, {
    required String amount,
    String? notes,
  }) async {
    return callFunction<Map<String, dynamic>>(
      'auditPaymentEvent',
      parameters: {
        'eventType': eventType,
        'amount': amount,
        'notes': notes,
        'userId': _uid,
      },
    );
  }

  /// Get payment audit trail
  /// 
  /// Returns: {success, records: [...]}
  Future<Map<String, dynamic>> getPaymentAuditTrail({
    int limit = 100,
  }) async {
    return callFunction<Map<String, dynamic>>(
      'getPaymentAuditTrail',
      parameters: {
        'limit': limit,
        'userId': _uid,
      },
    );
  }

  // ===== Task Functions =====

  /// Process due task reminders
  /// 
  /// Returns: {success, notified}
  Future<Map<String, dynamic>> processDueReminders() async {
    return callFunction<Map<String, dynamic>>(
      'processDueReminders',
      parameters: {'userId': _uid},
    );
  }

  // ===== Expense Functions =====

  /// Process approved expense
  /// 
  /// Returns: {success, expenseId}
  Future<Map<String, dynamic>> processExpenseApproved(
    String expenseId,
  ) async {
    return callFunction<Map<String, dynamic>>(
      'onExpenseApproved',
      parameters: {
        'expenseId': expenseId,
        'userId': _uid,
      },
    );
  }

  // ===== Finance Functions =====

  /// Generate AI-powered finance coach advice
  /// 
  /// Reads user's finance summary and generates personalized financial advice
  /// Returns: {advice: string}
  Future<Map<String, dynamic>> generateFinanceCoachAdvice() async {
    return callFunction<Map<String, dynamic>>(
      'generateFinanceCoachAdvice',
      parameters: {'userId': _uid},
    );
  }

  /// Fetch finance coach advice as a simple string
  /// 
  /// Convenience method that extracts just the advice string
  /// Returns: advice string or default message if unavailable
  Future<String> fetchFinanceAdvice() async {
    try {
      final result = await generateFinanceCoachAdvice();
      return result['advice'] as String? ?? 
        'Your financial summary is being analyzed. Please refresh soon.';
    } catch (e) {
      print('Error fetching finance advice: $e');
      return 'Unable to generate advice at this time. Please try again later.';
    }
  }

  // ===== Token/Reward Functions =====

  /// Reward user with AuraTokens
  /// 
  /// Returns: {success, newBalance, transactionId}
  Future<Map<String, dynamic>> rewardUser({
    required String reason,
    required int amount,
    String? metadata,
  }) async {
    return callFunction<Map<String, dynamic>>(
      'rewardUser',
      parameters: {
        'reason': reason,
        'amount': amount,
        'metadata': metadata,
        'userId': _uid,
      },
    );
  }

  /// Verify user token data integrity
  /// 
  /// Returns: {success, valid, balance}
  Future<Map<String, dynamic>> verifyUserTokenData() async {
    return callFunction<Map<String, dynamic>>(
      'verifyUserTokenData',
      parameters: {'userId': _uid},
    );
  }
}
