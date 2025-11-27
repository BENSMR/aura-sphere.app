import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:provider/provider.dart';

import '../../providers/user_provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});
  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _firstName = '';
  String _lastName = '';
  bool _busy = false;
  String? _error;

  void _submit() async {
    if (!_formKey.currentState!.validate()) return;
    _formKey.currentState!.save();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await context.read<UserProvider>().signUpWithEmail(
            _email.trim(),
            _password,
            _firstName.trim(),
            _lastName.trim(),
          );
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
    final prov = context.watch<UserProvider>();
    if (prov.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (prov.isLoggedIn) {
      SchedulerBinding.instance.addPostFrameCallback((_) {
        Navigator.of(context).pushReplacementNamed('/dashboard');
      });
    }

    return Scaffold(
      appBar: AppBar(title: const Text('Create Account')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(children: [
          if (_error != null) Text(_error!, style: const TextStyle(color: Colors.red)),
          Form(
            key: _formKey,
            child: Column(children: [
              TextFormField(
                decoration: const InputDecoration(labelText: 'First name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter first name' : null,
                onSaved: (v) => _firstName = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last name'),
                validator: (v) => v == null || v.isEmpty ? 'Enter last name' : null,
                onSaved: (v) => _lastName = v ?? '',
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Email'),
                keyboardType: TextInputType.emailAddress,
                validator: (v) => v == null || !v.contains('@') ? 'Enter valid email' : null,
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
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Create Account'),
              ),
            ]),
          )
        ]),
      ),
    );
  }
}
