import 'package:flutter/material.dart';
import '../config/app_routes.dart';

/// Dialog shown when user taps on "Coming Soon" features.
/// Allows users to join early access waitlist with rewards.
class ComingSoon {
  /// Show coming soon dialog for a feature
  ///
  /// Parameters:
  ///   - context: BuildContext for showing the dialog
  ///   - featureName: Name of the feature (e.g., "Inventory Management")
  ///
  /// Example:
  ///   ComingSoon.show(context, "Crypto Wallet")
  static void show(BuildContext context, String featureName) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text("🔜 $featureName"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              "$featureName is coming soon!",
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
            ),
            const SizedBox(height: 12),
            Text(
              "Join the early access waitlist and get rewards.",
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Close"),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              Navigator.pushNamed(
                context,
                AppRoutes.waitlist,
                arguments: {'feature': featureName},
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepPurple,
              shape: const StadiumBorder(),
            ),
            child: const Text("Join Waitlist"),
          )
        ],
      ),
    );
  }
}
