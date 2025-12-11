import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/user_provider.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _busy = false;
  String? _error;
  String? _success;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetEmail() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _error = 'Please enter your email');
      return;
    }

    if (!email.contains('@')) {
      setState(() => _error = 'Please enter a valid email');
      return;
    }

    setState(() {
      _busy = true;
      _error = null;
      _success = null;
    });

    try {
      await context.read<UserProvider>().sendPasswordResetEmail(email);
      setState(() {
        _success = 'Password reset email sent! Check your inbox.';
        _error = null;
      });
      // Auto-navigate back after 3 seconds
      await Future.delayed(const Duration(seconds: 3));
      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      setState(() {
        _error = 'Failed to send reset email: ${e.toString()}';
        _success = null;
      });
    } finally {
      setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reset Password'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              // Icon
              Icon(
                Icons.lock_reset,
                size: 80,
                color: Theme.of(context).primaryColor,
              ),
              const SizedBox(height: 32),
              // Title
              Text(
                'Reset Your Password',
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              // Description
              Text(
                'Enter your email address and we\'ll send you a link to reset your password.',
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              // Error message
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.red.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.red.shade300),
                  ),
                  child: Text(
                    _error!,
                    style: TextStyle(color: Colors.red.shade800),
                  ),
                ),
              // Success message
              if (_success != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade100,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade300),
                  ),
                  child: Text(
                    _success!,
                    style: TextStyle(color: Colors.green.shade800),
                  ),
                ),
              if (_error != null || _success != null)
                const SizedBox(height: 16),
              // Email input
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'Email Address',
                  hintText: 'example@gmail.com',
                  prefixIcon: const Icon(Icons.email),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  enabled: !_busy && !userProvider.loading,
                ),
                keyboardType: TextInputType.emailAddress,
                enabled: !_busy && !userProvider.loading,
              ),
              const SizedBox(height: 24),
              // Send reset email button
              ElevatedButton(
                onPressed: (_busy || userProvider.loading) ? null : _sendResetEmail,
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  child: _busy || userProvider.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Send Reset Email'),
                ),
              ),
              const SizedBox(height: 16),
              // Back to login button
              TextButton(
                onPressed: _busy ? null : () => Navigator.pop(context),
                child: const Text('Back to Login'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
