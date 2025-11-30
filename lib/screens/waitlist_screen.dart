import 'package:flutter/material.dart';
import '../services/firebase/auth_service.dart';
import '../services/firestore_service.dart';

/// Screen for joining feature waitlists.
/// Collects user email and registers them for early access.
class WaitlistScreen extends StatefulWidget {
  final String feature;

  const WaitlistScreen({required this.feature, super.key});

  @override
  State<WaitlistScreen> createState() => _WaitlistScreenState();
}

class _WaitlistScreenState extends State<WaitlistScreen> {
  final emailCtrl = TextEditingController();
  bool loading = false;
  String? errorMessage;

  final authService = AuthService();
  final firestoreService = FirestoreService();

  @override
  void dispose() {
    emailCtrl.dispose();
    super.dispose();
  }

  /// Validate email format
  bool _isValidEmail(String email) {
    final emailRegex =
        RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    return emailRegex.hasMatch(email);
  }

  /// Join the waitlist for a feature
  Future<void> joinWaitlist() async {
    final email = emailCtrl.text.trim();

    // Validation
    if (email.isEmpty) {
      setState(() => errorMessage = "Please enter your email");
      return;
    }

    if (!_isValidEmail(email)) {
      setState(() => errorMessage = "Please enter a valid email");
      return;
    }

    setState(() {
      loading = true;
      errorMessage = null;
    });

    try {
      // Get current user ID (optional - can be anonymous)
      final userId = authService.currentUser?.uid ?? "anonymous";

      // Save to Firestore waitlist
      // Path: waitlist/{feature}/{email}
      await firestoreService.set(
        'waitlist/$widget.feature/$email',
        {
          'email': email,
          'feature': widget.feature,
          'userId': userId,
          'joinedAt': DateTime.now(),
          'notified': false,
        },
      );

      if (mounted) {
        setState(() => loading = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("✅ You're on the ${widget.feature} waitlist!"),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );

        Future.delayed(const Duration(seconds: 1), () {
          if (mounted) {
            Navigator.pop(context);
          }
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          loading = false;
          errorMessage = "Failed to join waitlist. Please try again.";
        });
        debugPrint("Waitlist error: $e");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("${widget.feature} Waitlist"),
        elevation: 0,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          children: [
            // Header
            Icon(Icons.hourglass_top, size: 64, color: Colors.deepPurple),
            const SizedBox(height: 20),

            // Title
            Text(
              "${widget.feature} is Coming",
              style: Theme.of(context).textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),

            // Subtitle
            Text(
              "Join our early access program and be the first to try it!",
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 40),

            // Email field
            TextField(
              controller: emailCtrl,
              enabled: !loading,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email Address",
                hintText: "you@example.com",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                prefixIcon: const Icon(Icons.email_outlined),
                errorText: errorMessage,
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: const BorderSide(color: Colors.red),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Join button
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: loading ? null : joinWaitlist,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.deepPurple,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(
                            Colors.white,
                          ),
                        ),
                      )
                    : const Text(
                        "Join Waitlist",
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                      ),
              ),
            ),
            const SizedBox(height: 20),

            // Info text
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.purple.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Icon(Icons.info_outline, color: Colors.deepPurple),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      "We'll notify you via email when ${widget.feature} is ready!",
                      style: TextStyle(fontSize: 13, color: Colors.grey[700]),
                    ),
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Footer
            Text(
              "We respect your privacy. No spam.",
              style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
