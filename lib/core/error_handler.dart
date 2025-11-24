import 'package:flutter/foundation.dart';
import 'logger.dart';

class ErrorHandler {
  static void handleError(Object error, StackTrace? stackTrace) {
    if (kDebugMode) {
      Logger.error('Error occurred', error: error, stackTrace: stackTrace);
    }
    
    // TODO: Send to crash reporting service (Sentry, Firebase Crashlytics)
  }

  static String getUserFriendlyMessage(Object error) {
    // TODO: Map technical errors to user-friendly messages
    return 'An unexpected error occurred. Please try again.';
  }
}
