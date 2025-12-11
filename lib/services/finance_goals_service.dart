import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import '../models/finance_goals_model.dart';
import '../models/finance_alerts_model.dart';

class FinanceGoalsService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // TODO: Plug with your auth provider
  String getCurrentUserId() => 'CURRENT_USER_ID';

  Stream<FinanceGoals?> streamGoals() {
    final uid = getCurrentUserId();
    return _db
        .collection('users')
        .doc(uid)
        .collection('analytics')
        .doc('financeGoals')
        .snapshots()
        .map((doc) => doc.exists ? FinanceGoals.fromDoc(doc) : null);
  }

  Stream<FinanceAlerts?> streamAlerts() {
    final uid = getCurrentUserId();
    return _db
        .collection('users')
        .doc(uid)
        .collection('analytics')
        .doc('financeAlerts')
        .snapshots()
        .map((doc) => doc.exists ? FinanceAlerts.fromDoc(doc) : null);
  }

  Future<void> saveGoals({
    required double monthlyRevenueTarget,
    required double profitMarginTarget,
    required double maxExpensesThisMonth,
    required double cashRunwayTargetDays,
  }) async {
    final callable =
        FirebaseFunctions.instance.httpsCallable('setFinanceGoals');

    await callable.call({
      'monthlyRevenueTarget': monthlyRevenueTarget,
      'profitMarginTarget': profitMarginTarget,
      'maxExpensesThisMonth': maxExpensesThisMonth,
      'cashRunwayTargetDays': cashRunwayTargetDays,
    });
  }
}
