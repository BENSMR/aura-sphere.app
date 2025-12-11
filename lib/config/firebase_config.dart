/// Firebase configuration and Cloud Functions endpoints
/// Update these with your actual Firebase project details

class FirebaseConfig {
  // Firebase project configuration
  // Replace with your actual Firebase project details
  static const String projectId = 'YOUR_PROJECT_ID'; // e.g., 'aurasphere-pro'
  static const String region = 'YOUR_REGION'; // e.g., 'us-central1', 'europe-west1'

  /// Build the Cloud Functions base URL
  static String get cloudFunctionsUrl =>
      'https://$region-$projectId.cloudfunctions.net';

  /// Finance export endpoints
  static String exportFinanceSummaryUrl(String userId) =>
      '$cloudFunctionsUrl/exportFinanceSummary?userId=$userId';

  static String exportFinanceSummaryJsonUrl(String userId) =>
      '$cloudFunctionsUrl/exportFinanceSummaryJson?userId=$userId';

  /// Finance coach AI endpoint
  static String get generateFinanceCoachAdviceUrl =>
      '$cloudFunctionsUrl/generateFinanceCoachAdvice';

  /// Initialize this before running the app
  /// Example:
  /// ```dart
  /// void main() {
  ///   FirebaseConfig.initialize(
  ///     projectId: 'aurasphere-pro',
  ///     region: 'us-central1',
  ///   );
  ///   runApp(const MyApp());
  /// }
  /// ```
  static void initialize({
    required String projectId,
    required String region,
  }) {
    // Store in shared preferences or environment config
    // For now, these are hardcoded - update manually above
  }
}
