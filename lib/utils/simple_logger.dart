/// Simple logger utility for debugging
class SimpleLogger {
  static void i(String message) {
    print('[INFO] $message');
  }

  static void e(String message) {
    print('[ERROR] $message');
  }

  static void d(String message) {
    print('[DEBUG] $message');
  }

  static void w(String message) {
    print('[WARNING] $message');
  }
}

final logger = SimpleLogger();
