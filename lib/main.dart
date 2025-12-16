import 'package:flutter/material.dart';
import 'dart:async';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'app/app.dart';

void main() {
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();
    
    // Initialize Firebase Crashlytics
    await FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(true);
    // Pass all uncaught "fatal" errors from the framework to Crashlytics
    FlutterError.onError = (errorDetails) {
      FirebaseCrashlytics.instance.recordFlutterFatalError(errorDetails);
    };
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
    
    // Initialize Sentry for crash reporting
    await SentryFlutter.init(
      (options) {
        options.dsn = 'https://your-sentry-dsn@sentry.io/project-id';
        options.tracesSampleRate = 1.0; // Monitor 100% of transactions
        options.environment = const String.fromEnvironment('ENV', defaultValue: 'development');
      },
      appRunner: () async {
        try {
          await bootstrap();
          runApp(const AuraSphereApp());
        } catch (e, stackTrace) {
          debugPrint('Bootstrap/App error: $e');
          // Report to Sentry
          await Sentry.captureException(e, stackTrace: stackTrace);
          // Show error screen
          runApp(
            MaterialApp(
              home: Scaffold(
                body: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 16),
                        const Text(
                          'Initialization Error',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          e.toString(),
                          textAlign: TextAlign.center,
                          style: const TextStyle(fontSize: 14, color: Colors.grey),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        }
      },
    );
  }, (error, stack) {
    debugPrint('Uncaught error: $error');
    debugPrintStack(stackTrace: stack);
    // Report uncaught errors to both Firebase Crashlytics and Sentry
    FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
    Sentry.captureException(error, stackTrace: stack);
  });
}
