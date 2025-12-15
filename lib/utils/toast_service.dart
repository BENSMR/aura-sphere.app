import 'package:flutter/material.dart';

/// Toast notification styles and types
enum ToastType { success, error, warning, info }

class ToastConfig {
  final ToastType type;
  final String message;
  final Duration duration;
  final bool showIcon;

  ToastConfig({
    required this.type,
    required this.message,
    this.duration = const Duration(seconds: 3),
    this.showIcon = true,
  });
}

/// Toast notification service
class ToastService {
  static final ToastService _instance = ToastService._internal();

  factory ToastService() {
    return _instance;
  }

  ToastService._internal();

  /// Show success toast
  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      context,
      ToastConfig(
        type: ToastType.success,
        message: message,
        duration: duration,
      ),
    );
  }

  /// Show error toast
  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      context,
      ToastConfig(
        type: ToastType.error,
        message: message,
        duration: duration,
      ),
    );
  }

  /// Show warning toast
  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      context,
      ToastConfig(
        type: ToastType.warning,
        message: message,
        duration: duration,
      ),
    );
  }

  /// Show info toast
  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    _showToast(
      context,
      ToastConfig(
        type: ToastType.info,
        message: message,
        duration: duration,
      ),
    );
  }

  /// Internal method to show toast
  static void _showToast(BuildContext context, ToastConfig config) {
    final colors = _getToastColors(config.type);
    final icon = _getToastIcon(config.type);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (config.showIcon) ...[
              Icon(icon, color: colors['foreground']),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                config.message,
                style: TextStyle(
                  color: colors['foreground'],
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
        backgroundColor: colors['background'],
        duration: config.duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8),
          side: BorderSide(
            color: colors['border'] as Color,
            width: 1,
          ),
        ),
        elevation: 8,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),
    );
  }

  /// Get colors for toast type
  static Map<String, dynamic> _getToastColors(ToastType type) {
    switch (type) {
      case ToastType.success:
        return {
          'background': const Color(0xFFE8F5E9),
          'foreground': const Color(0xFF2E7D32),
          'border': const Color(0xFF4CAF50),
        };
      case ToastType.error:
        return {
          'background': const Color(0xFFFFEBEE),
          'foreground': const Color(0xFFD32F2F),
          'border': const Color(0xFFF44336),
        };
      case ToastType.warning:
        return {
          'background': const Color(0xFFFFF3E0),
          'foreground': const Color(0xFFF57C00),
          'border': const Color(0xFFFF9800),
        };
      case ToastType.info:
        return {
          'background': const Color(0xFFE3F2FD),
          'foreground': const Color(0xFF1565C0),
          'border': const Color(0xFF2196F3),
        };
    }
  }

  /// Get icon for toast type
  static IconData _getToastIcon(ToastType type) {
    switch (type) {
      case ToastType.success:
        return Icons.check_circle_outline;
      case ToastType.error:
        return Icons.error_outline;
      case ToastType.warning:
        return Icons.warning_amber;
      case ToastType.info:
        return Icons.info_outline;
    }
  }
}
