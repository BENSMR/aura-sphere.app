import 'package:cloud_functions/cloud_functions.dart';
import 'package:firebase_auth/firebase_auth.dart';

class EmailService {
  static final _functions = FirebaseFunctions.instance;
  static final _auth = FirebaseAuth.instance;

  /// Send a task reminder email via Cloud Function
  /// 
  /// Parameters:
  /// - userId: User who owns the task
  /// - taskId: Task document ID to send email for
  /// - overrideEmail: (Optional) Custom recipient email
  /// - overrideSubject: (Optional) Custom email subject
  /// - overrideBody: (Optional) Custom HTML email body
  /// 
  /// Returns: true if email was queued successfully
  /// 
  /// Throws: FirebaseFunctionsException if something goes wrong
  static Future<bool> sendTaskEmail({
    required String taskId,
    String? overrideEmail,
    String? overrideSubject,
    String? overrideBody,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'User must be logged in to send emails',
        );
      }

      final callable = _functions.httpsCallable('sendTaskEmail');

      final params = {
        'userId': currentUser.uid,
        'taskId': taskId,
      };

      // Add optional parameters if provided
      if (overrideEmail != null) {
        params['overrideEmail'] = overrideEmail;
      }
      if (overrideSubject != null) {
        params['overrideSubject'] = overrideSubject;
      }
      if (overrideBody != null) {
        params['overrideBody'] = overrideBody;
      }

      final result = await callable.call(params);

      return result.data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      print('EmailService error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('EmailService unexpected error: $e');
      rethrow;
    }
  }

  /// Send a custom email (for direct email sending)
  /// 
  /// This is a simplified wrapper for basic email sending.
  /// For task emails, use sendTaskEmail() instead.
  static Future<bool> sendCustomEmail({
    required String to,
    required String subject,
    required String message,
  }) async {
    try {
      final currentUser = _auth.currentUser;
      if (currentUser == null) {
        throw FirebaseFunctionsException(
          code: 'unauthenticated',
          message: 'User must be logged in',
        );
      }

      final callable = _functions.httpsCallable('sendTaskEmail');

      // For custom emails, we create a temporary task or use override parameters
      final result = await callable.call({
        'userId': currentUser.uid,
        'taskId': '', // Empty for custom emails
        'overrideEmail': to,
        'overrideSubject': subject,
        'overrideBody': message,
      });

      return result.data['success'] == true;
    } on FirebaseFunctionsException catch (e) {
      print('EmailService error: ${e.code} - ${e.message}');
      rethrow;
    } catch (e) {
      print('EmailService unexpected error: $e');
      rethrow;
    }
  }

  /// Simple email sending wrapper
  /// 
  /// Sends an email directly without a task.
  /// Parameters:
  /// - to: Recipient email address
  /// - subject: Email subject
  /// - message: Email body (plain text or HTML)
  /// 
  /// Returns: true if email was queued successfully
  /// 
  /// Example:
  /// ```dart
  /// final success = await EmailService.sendEmail(
  ///   to: "user@example.com",
  ///   subject: "Hello",
  ///   message: "This is a test email",
  /// );
  /// print("Email sent? $success");
  /// ```
  static Future<bool> sendEmail({
    required String to,
    required String subject,
    required String message,
  }) async {
    return sendCustomEmail(
      to: to,
      subject: subject,
      message: message,
    );
  }
}
