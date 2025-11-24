import 'package:flutter/foundation.dart';

class Logger {
  static void info(String message) {
    if (kDebugMode) {
      print('[INFO] $message');
    }
  }

  static void debug(String message) {
    if (kDebugMode) {
      print('[DEBUG] $message');
    }
  }

  static void warning(String message) {
    if (kDebugMode) {
      print('[WARNING] $message');
    }
  }

  static void error(String message, {Object? error, StackTrace? stackTrace}) {
    if (kDebugMode) {
      print('[ERROR] $message');
      if (error != null) print('Error: $error');
      if (stackTrace != null) print('StackTrace: $stackTrace');
    }
  }
}
