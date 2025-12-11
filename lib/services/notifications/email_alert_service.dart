import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

enum AlertType { anomaly, invoice, expense, payment, system }

enum AlertSeverity { critical, high, medium, low }

class EmailAlertPayload {
  final String userId;
  final String recipientEmail;
  final AlertType alertType;
  final AlertSeverity severity;
  final String subject;
  final String title;
  final String description;
  final String? actionUrl;
  final Map<String, dynamic>? metadata;

  EmailAlertPayload({
    required this.userId,
    required this.recipientEmail,
    required this.alertType,
    required this.severity,
    required this.subject,
    required this.title,
    required this.description,
    this.actionUrl,
    this.metadata,
  });

  Map<String, dynamic> toMap() => {
    'userId': userId,
    'recipientEmail': recipientEmail,
    'alertType': alertType.name,
    'severity': severity.name,
    'subject': subject,
    'title': title,
    'description': description,
    'actionUrl': actionUrl,
    'metadata': metadata,
  };
}

class EmailAlertRecord {
  final String messageId;
  final AlertType alertType;
  final AlertSeverity severity;
  final String subject;
  final DateTime sentAt;
  final String status;

  EmailAlertRecord({
    required this.messageId,
    required this.alertType,
    required this.severity,
    required this.subject,
    required this.sentAt,
    required this.status,
  });

  factory EmailAlertRecord.fromMap(Map<String, dynamic> map) => EmailAlertRecord(
    messageId: map['messageId'] ?? '',
    alertType: AlertType.values.byName(map['alertType'] ?? 'system'),
    severity: AlertSeverity.values.byName(map['severity'] ?? 'low'),
    subject: map['subject'] ?? '',
    sentAt: (map['sentAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    status: map['status'] ?? 'sent',
  );
}

class EmailAlertService {
  final FirebaseFirestore _firestore;

  EmailAlertService({
    FirebaseFirestore? firestore,
  })  : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Send email alert via Cloud Function
  /// Returns true if alert was accepted for sending
  Future<bool> sendAlert({
    required String userId,
    required String recipientEmail,
    required AlertType alertType,
    required AlertSeverity severity,
    required String subject,
    required String title,
    required String description,
    String? actionUrl,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      final payload = EmailAlertPayload(
        userId: userId,
        recipientEmail: recipientEmail,
        alertType: alertType,
        severity: severity,
        subject: subject,
        title: title,
        description: description,
        actionUrl: actionUrl,
        metadata: metadata,
      );

      // Store alert in Firestore - Cloud Function will process via Firestore trigger
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('emailAlerts')
          .add({
        ...payload.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'processed': false,
      });

      debugPrint('✅ Email alert queued: $subject');
      return true;
    } catch (e) {
      debugPrint('❌ Email alert error: $e');
      return false;
    }
  }

  /// Send anomaly alert email
  Future<bool> sendAnomalyAlert({
    required String userId,
    required String email,
    required String entityType,
    required String description,
    required double amount,
    required AlertSeverity severity,
    String? actionUrl,
  }) async {
    return sendAlert(
      userId: userId,
      recipientEmail: email,
      alertType: AlertType.anomaly,
      severity: severity,
      subject: '${severity.name.toUpperCase()} - $entityType Anomaly Detected',
      title: 'Anomaly Detected',
      description: description,
      actionUrl: actionUrl ?? '/anomalies',
      metadata: {
        'entityType': entityType,
        'amount': amount,
      },
    );
  }

  /// Send invoice reminder email
  Future<bool> sendInvoiceReminder({
    required String userId,
    required String email,
    required String invoiceNumber,
    required double amount,
    required String currency,
    required DateTime dueDate,
    String? invoiceId,
  }) async {
    final daysUntilDue = dueDate.difference(DateTime.now()).inDays;
    
    return sendAlert(
      userId: userId,
      recipientEmail: email,
      alertType: AlertType.invoice,
      severity: daysUntilDue <= 1 ? AlertSeverity.high : AlertSeverity.medium,
      subject: 'Invoice #$invoiceNumber Due in $daysUntilDue Days',
      title: 'Invoice Payment Reminder',
      description: 'Invoice #$invoiceNumber for $currency$amount is due on ${dueDate.toString().split(' ')[0]}',
      actionUrl: invoiceId != null ? '/invoices/$invoiceId' : '/invoices',
      metadata: {
        'invoiceNumber': invoiceNumber,
        'amount': amount,
        'currency': currency,
        'daysUntilDue': daysUntilDue,
      },
    );
  }

  /// Send payment alert
  Future<bool> sendPaymentAlert({
    required String userId,
    required String email,
    required String invoiceNumber,
    required double amount,
    required String currency,
    String? invoiceId,
  }) async {
    return sendAlert(
      userId: userId,
      recipientEmail: email,
      alertType: AlertType.payment,
      severity: AlertSeverity.medium,
      subject: 'Payment Received for Invoice #$invoiceNumber',
      title: 'Payment Confirmed',
      description: 'Payment of $currency$amount for invoice #$invoiceNumber has been received.',
      actionUrl: invoiceId != null ? '/invoices/$invoiceId' : '/invoices',
      metadata: {
        'invoiceNumber': invoiceNumber,
        'amount': amount,
        'currency': currency,
      },
    );
  }

  /// Send expense notification
  Future<bool> sendExpenseNotification({
    required String userId,
    required String email,
    required String expenseName,
    required double amount,
    required String currency,
    required AlertSeverity severity,
    String? expenseId,
  }) async {
    return sendAlert(
      userId: userId,
      recipientEmail: email,
      alertType: AlertType.expense,
      severity: severity,
      subject: '$severity.name.toUpperCase() - Expense: $expenseName',
      title: 'Expense Alert',
      description: 'New expense recorded: $expenseName ($currency$amount)',
      actionUrl: expenseId != null ? '/expenses/$expenseId' : '/expenses',
      metadata: {
        'expenseName': expenseName,
        'amount': amount,
        'currency': currency,
      },
    );
  }

  /// Get email alert history for user
  Future<List<EmailAlertRecord>> getAlertHistory({
    required String userId,
    int limit = 50,
  }) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('emailAlerts')
          .orderBy('sentAt', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => EmailAlertRecord.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('❌ Failed to fetch alert history: $e');
      return [];
    }
  }

  /// Disable alert type for user
  Future<bool> disableAlertType({
    required String userId,
    required AlertType alertType,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .update({
            'disabledAlerts': FieldValue.arrayUnion([alertType.name]),
          });
      return true;
    } catch (e) {
      debugPrint('❌ Failed to disable alert type: $e');
      return false;
    }
  }

  /// Enable alert type for user
  Future<bool> enableAlertType({
    required String userId,
    required AlertType alertType,
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .update({
            'disabledAlerts': FieldValue.arrayRemove([alertType.name]),
          });
      return true;
    } catch (e) {
      debugPrint('❌ Failed to enable alert type: $e');
      return false;
    }
  }

  /// Set quiet hours (no non-critical alerts)
  Future<bool> setQuietHours({
    required String userId,
    required int startHour, // 0-23
    required int endHour,   // 0-23
  }) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .set({
            'quietHoursEnabled': true,
            'quietHoursStart': startHour,
            'quietHoursEnd': endHour,
          }, SetOptions(merge: true));
      return true;
    } catch (e) {
      debugPrint('❌ Failed to set quiet hours: $e');
      return false;
    }
  }

  /// Disable quiet hours
  Future<bool> disableQuietHours(String userId) async {
    try {
      await _firestore
          .collection('users')
          .doc(userId)
          .collection('preferences')
          .doc('notifications')
          .update({
            'quietHoursEnabled': false,
          });
      return true;
    } catch (e) {
      debugPrint('❌ Failed to disable quiet hours: $e');
      return false;
    }
  }

  /// Stream alert preferences
  Stream<Map<String, dynamic>> streamAlertPreferences(String userId) {
    return _firestore
        .collection('users')
        .doc(userId)
        .collection('preferences')
        .doc('notifications')
        .snapshots()
        .map((snap) => snap.data() ?? {});
  }
}
