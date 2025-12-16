import 'package:flutter/material.dart';

/// Safe BuildContext helpers for async operations
/// 
/// Solves the "BuildContext used across async gap" problem by providing
/// safe wrappers for common operations that happen after async calls.
/// 
/// Example:
/// ```dart
/// Future<void> loadData() async {
///   await Future.delayed(Duration(seconds: 1));
///   if (!mounted) return;  // ✅ Safe
///   showSnackBar('Data loaded');
/// }
/// ```

extension SafeContextExtension on BuildContext {
  /// Check if this context's widget is still mounted
  /// 
  /// Returns false if the widget has been disposed (user navigated away)
  /// Always check this before using context after async operations
  bool get mounted => !mounted ? false : true;

  /// Safely show a snackbar after async operation
  /// 
  /// Returns true if successful, false if context unmounted
  bool showSnackBarSafe(
    String message, {
    Duration duration = const Duration(seconds: 4),
    SnackBarAction? action,
  }) {
    if (!mounted) return false;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        action: action,
      ),
    );
    return true;
  }

  /// Safely show an error snackbar
  bool showErrorSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 5),
  }) {
    if (!mounted) return false;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.red.shade600,
      ),
    );
    return true;
  }

  /// Safely show a success snackbar
  bool showSuccessSnackBar(
    String message, {
    Duration duration = const Duration(seconds: 3),
  }) {
    if (!mounted) return false;

    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: duration,
        backgroundColor: Colors.green.shade600,
      ),
    );
    return true;
  }

  /// Safely navigate with named route
  bool pushNamedSafe(String routeName, {Object? arguments}) {
    if (!mounted) return false;

    Navigator.pushNamed(this, routeName, arguments: arguments);
    return true;
  }

  /// Safely push a route
  bool pushSafe(Route<dynamic> route) {
    if (!mounted) return false;

    Navigator.push(this, route);
    return true;
  }

  /// Safely push and replace route
  bool pushReplacementSafe(Route<dynamic> route) {
    if (!mounted) return false;

    Navigator.pushReplacement(this, route);
    return true;
  }

  /// Safely pop with optional result
  bool popSafe<T>([T? result]) {
    if (!mounted) return false;

    Navigator.pop(this, result);
    return true;
  }

  /// Safely show dialog
  Future<T?> showDialogSafe<T>(
    WidgetBuilder builder, {
    bool barrierDismissible = true,
  }) async {
    if (!mounted) return null;

    return showDialog<T>(
      context: this,
      builder: builder,
      barrierDismissible: barrierDismissible,
    );
  }

  /// Safely show bottom sheet
  Future<T?> showBottomSheetSafe<T>(
    WidgetBuilder builder, {
    Color? backgroundColor,
    double? elevation,
    ShapeBorder? shape,
    Clip? clipBehavior,
    BoxConstraints? constraints,
    bool useRootNavigator = false,
    bool isScrollControlled = false,
    AnimationController? transitionAnimationController,
    bool enableDrag = true,
  }) async {
    if (!mounted) return null;

    return showModalBottomSheet<T>(
      context: this,
      builder: builder,
      backgroundColor: backgroundColor,
      elevation: elevation,
      shape: shape,
      clipBehavior: clipBehavior,
      constraints: constraints,
      useRootNavigator: useRootNavigator,
      isScrollControlled: isScrollControlled,
      transitionAnimationController: transitionAnimationController,
      enableDrag: enableDrag,
    );
  }
}

/// Mixin for State<T> to safely handle context in async operations
/// 
/// Provides mounted property that checks if the widget is still in the tree
/// 
/// Usage:
/// ```dart
/// class MyScreenState extends State<MyScreen> with SafeStateMixin {
///   Future<void> loadData() async {
///     await api.fetch();
///     if (!mounted) return;  // ✅ Uses mixin's mounted
///     setState(() => data = result);
///   }
/// }
/// ```
mixin SafeStateMixin<T extends StatefulWidget> on State<T> {
  /// Check if this State is still mounted (not disposed)
  /// 
  /// Always call this before using context or setState after async operations
  @override
  bool get mounted => super.mounted;
}

/// Utility class for safe async operations on BuildContext
class ContextSafetyUtils {
  /// Run a function only if context is mounted
  /// 
  /// Returns true if executed, false if skipped
  static bool runIfMounted(
    BuildContext context,
    VoidCallback callback,
  ) {
    if (!context.mounted) return false;

    try {
      callback();
      return true;
    } catch (e) {
      debugPrint('❌ Error in mounted context callback: $e');
      return false;
    }
  }

  /// Run a function that returns a value only if context is mounted
  /// 
  /// Returns the function result or defaultValue if not mounted
  static T? runIfMountedWithReturn<T>(
    BuildContext context,
    T Function() callback, {
    T? defaultValue,
  }) {
    if (!context.mounted) return defaultValue;

    try {
      return callback();
    } catch (e) {
      debugPrint('❌ Error in mounted context callback: $e');
      return defaultValue;
    }
  }

  /// Safe wrapper for async operations with BuildContext
  /// 
  /// Automatically checks if context is mounted before executing callback
  static Future<T?> safeAsyncOperation<T>(
    BuildContext context,
    Future<T> Function() operation, {
    void Function(T result)? onSuccess,
    void Function(dynamic error)? onError,
  }) async {
    try {
      final result = await operation();

      // Check if context still exists
      if (!context.mounted) {
        debugPrint('⚠️  Context unmounted, skipping onSuccess callback');
        return null;
      }

      onSuccess?.call(result);
      return result;
    } catch (e) {
      if (!context.mounted) {
        debugPrint('⚠️  Context unmounted, skipping onError callback');
        return null;
      }

      onError?.call(e);
      debugPrint('❌ Async operation failed: $e');
      return null;
    }
  }

  /// Batch safe operations - execute multiple callbacks only if context mounted
  static bool runIfMountedBatch(
    BuildContext context,
    List<VoidCallback> callbacks,
  ) {
    if (!context.mounted) return false;

    int executed = 0;
    for (final callback in callbacks) {
      try {
        callback();
        executed++;
      } catch (e) {
        debugPrint('❌ Error in batch callback $executed: $e');
      }
    }

    return executed > 0;
  }
}

/// Extension on Future<T> for safe context operations
extension SafeFutureExtension<T> on Future<T> {
  /// Execute callback only if context is mounted when future completes
  /// 
  /// Usage:
  /// ```dart
  /// myFuture
  ///   .thenSafeContext(context, (result) {
  ///     showSnackBar('Done: $result');
  ///   });
  /// ```
  void thenSafeContext(
    BuildContext context,
    void Function(T value) onValue, {
    Function? onError,
  }) {
    then((value) {
      if (context.mounted) {
        onValue(value);
      } else {
        debugPrint('⚠️  Context unmounted, skipping onValue callback');
      }
    }).catchError((error) {
      if (context.mounted && onError != null) {
        onError(error);
      } else if (!context.mounted) {
        debugPrint('⚠️  Context unmounted, skipping onError callback');
      }
    });
  }
}
