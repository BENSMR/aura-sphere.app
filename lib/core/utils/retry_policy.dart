import 'package:flutter/foundation.dart';

/// Exponential backoff retry policy for API calls
class RetryPolicy {
  final int maxRetries;
  final Duration initialDelay;
  final double backoffMultiplier;
  final Duration maxDelay;

  const RetryPolicy({
    this.maxRetries = 3,
    this.initialDelay = const Duration(seconds: 1),
    this.backoffMultiplier = 2.0,
    this.maxDelay = const Duration(minutes: 1),
  });

  /// Calculate delay for attempt number
  Duration getDelayForAttempt(int attempt) {
    assert(attempt >= 0);
    final delay = initialDelay * (backoffMultiplier ^ attempt.toDouble());
    return delay > maxDelay ? maxDelay : delay;
  }
}

/// Generic retry wrapper for async operations
class RetryableOperation<T> {
  final Future<T> Function() operation;
  final bool Function(Object error)? shouldRetry;
  final void Function(int attempt, Object error)? onRetry;
  final RetryPolicy policy;

  RetryableOperation({
    required this.operation,
    this.shouldRetry,
    this.onRetry,
    RetryPolicy? policy,
  }) : policy = policy ?? const RetryPolicy();

  /// Execute operation with retries
  Future<T> execute() async {
    Object? lastError;
    
    for (int attempt = 0; attempt <= policy.maxRetries; attempt++) {
      try {
        return await operation();
      } catch (e) {
        lastError = e;
        
        // Check if we should retry
        if (attempt < policy.maxRetries) {
          final doRetry = shouldRetry?.call(e) ?? _isRetryable(e);
          if (!doRetry) {
            rethrow;
          }
          
          // Call onRetry callback
          onRetry?.call(attempt + 1, e);
          
          // Wait before retrying
          final delay = policy.getDelayForAttempt(attempt);
          debugPrint('[Retry] Attempt ${attempt + 1}/${policy.maxRetries} after ${delay.inSeconds}s');
          await Future.delayed(delay);
        }
      }
    }
    
    throw lastError ?? Exception('Operation failed after ${policy.maxRetries} retries');
  }

  /// Check if error is retryable (network errors, timeouts, etc.)
  static bool _isRetryable(Object error) {
    final message = error.toString().toLowerCase();
    return message.contains('network') ||
           message.contains('timeout') ||
           message.contains('socket') ||
           message.contains('connection') ||
           message.contains('503') ||
           message.contains('502') ||
           message.contains('429'); // Rate limit
  }
}

/// Extension for easy retry usage
extension RetryableExtension<T> on Future<T> {
  /// Retry this future with exponential backoff
  Future<T> withRetry({
    int maxRetries = 3,
    bool Function(Object)? shouldRetry,
    void Function(int, Object)? onRetry,
  }) async {
    return RetryableOperation(
      operation: () => this,
      shouldRetry: shouldRetry,
      onRetry: onRetry,
      policy: RetryPolicy(maxRetries: maxRetries),
    ).execute();
  }
}
