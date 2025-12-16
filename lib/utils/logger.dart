import 'package:flutter/foundation.dart';

/// Simple logger utility for debugging and logging
class Logger {
  static const String _prefix = '[AuraSphere]';

  /// Log info messages
  void info(String message, [dynamic data]) {
    if (kDebugMode) {
      final msg = data != null ? '$message: $data' : message;
      print('$_prefix [INFO] $msg');
    }
  }

  /// Log warning messages
  void warn(String message, [dynamic data]) {
    if (kDebugMode) {
      final msg = data != null ? '$message: $data' : message;
      print('$_prefix [WARN] $msg');
    }
  }

  /// Log error messages
  void error(String message, [dynamic data, dynamic exception, StackTrace? stackTrace]) {
    if (kDebugMode) {
      final msg = data != null ? '$message: $data' : message;
      print('$_prefix [ERROR] $msg');
      if (exception != null) {
        print('Exception: $exception');
      }
      if (stackTrace != null) {
        print('StackTrace:\n$stackTrace');
      }
    }
  }

  /// Log debug messages
  void debug(String message, [dynamic data]) {
    if (kDebugMode) {
      final msg = data != null ? '$message: $data' : message;
      print('$_prefix [DEBUG] $msg');
    }
  }
}

/// Global logger instance
final logger = Logger();
