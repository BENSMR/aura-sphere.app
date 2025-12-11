/**
 * Test sendEmailAlert from Flutter/Client-side
 * 
 * This shows how to call the Cloud Function from the Flutter app
 */

import 'package:cloud_functions/cloud_functions.dart';

class EmailAlertTest {
  static final _functions = FirebaseFunctions.instance;

  /// Test sending email via Cloud Function callable
  static Future<void> testSendEmailAlert({
    required String to,
    required String subject,
    required String html,
  }) async {
    try {
      print('📧 Calling sendEmailAlert...');
      
      // Call the Cloud Function
      final result = await _functions
          .httpsCallable('sendEmailAlert')
          .call<Map<String, dynamic>>({
        'to': to,
        'subject': subject,
        'html': html,
        'userId': 'test-user-${DateTime.now().millisecondsSinceEpoch}',
        'type': 'test',
        'severity': 'low',
      });

      print('✅ Email sent successfully!');
      print('Response: ${result.data}');
    } on FirebaseFunctionsException catch (e) {
      print('❌ Function error: ${e.code}');
      print('Message: ${e.message}');
      print('Details: ${e.details}');
    } catch (e) {
      print('❌ Error: $e');
    }
  }

  /// Test with different configurations
  static Future<void> testVariousEmails() async {
    final testCases = [
      {
        'to': 'alert@example.com',
        'subject': 'Anomaly Detected',
        'html': '<h2>High Severity Anomaly</h2><p>Invoice INV-001 has unusual activity.</p>',
      },
      {
        'to': 'invoices@example.com',
        'subject': 'Invoice Overdue',
        'html': '<h2>Invoice Payment Due</h2><p>Invoice INV-002 is overdue by 5 days.</p>',
      },
      {
        'to': 'team@example.com',
        'subject': 'System Alert',
        'html': '<h2>System Notification</h2><p>Notification system test completed successfully.</p>',
      },
    ];

    for (final testCase in testCases) {
      print('\nTesting: ${testCase['subject']}');
      print('─────────────────────────────────────────');
      
      await testSendEmailAlert(
        to: testCase['to'] as String,
        subject: testCase['subject'] as String,
        html: testCase['html'] as String,
      );

      // Small delay between tests
      await Future.delayed(Duration(seconds: 1));
    }
  }
}

/// Usage in your Flutter screens:
/// 
/// // In a button tap handler:
/// onPressed: () async {
///   await EmailAlertTest.testSendEmailAlert(
///     to: 'user@example.com',
///     subject: 'Test Subject',
///     html: '<b>Test HTML Content</b>',
///   );
/// },
/// 
/// // Or run all test cases:
/// onPressed: () => EmailAlertTest.testVariousEmails(),
