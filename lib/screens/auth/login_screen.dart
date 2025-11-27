import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';
import 'signup_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  bool _busy = false;
  String? _error;

  void _submitEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<UserProvider>().signInWithEmail(_email.trim(), _password);
      // Navigation happens via provider listener; or push to dashboard
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  void _googleSignIn() async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<UserProvider>().signInWithGoogle();
    } catch (e) {
      _error = e.toString();
    } finally {
      setState(() {
        _busy = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    if (userProvider.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (userProvider.isLoggedIn) {
      // Replace with your dashboard route
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Login')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            if (_error != null)
              Text(_error!, style: const TextStyle(color: Colors.red)),
            Form(
              key: _formKey,
              child: Column(children: [
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Email'),
                  keyboardType: TextInputType.emailAddress,
                  validator: (v) => v == null || v.isEmpty ? 'Enter email' : null,
                  onSaved: (v) => _email = v ?? '',
                ),
                TextFormField(
                  decoration: const InputDecoration(labelText: 'Password'),
                  obscureText: true,
                  validator: (v) => v == null || v.length < 6 ? 'Min 6 chars' : null,
                  onSaved: (v) => _password = v ?? '',
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: _busy ? null : _submitEmailSignIn,
                  child: _busy
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Text('Sign in'),
                ),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _busy ? null : _googleSignIn,
                  icon: const Icon(Icons.login),
                  label: const Text('Sign in with Google'),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () => Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const SignupScreen()),
                  ),
                  child: const Text('Create account'),
                )
              ]),
            )
          ],
        ),
      ),
    );
  }
}
