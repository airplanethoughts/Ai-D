import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../main.dart';

class ScaffoldSnackbar {
  final BuildContext _context;
  ScaffoldSnackbar(this._context);
  factory ScaffoldSnackbar.of(BuildContext context) =>
      ScaffoldSnackbar(context);
  void show(String message) => ScaffoldMessenger.of(
    _context,
  ).showSnackBar(SnackBar(content: Text(message)));
}

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});
  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _form = GlobalKey<FormState>();
  bool _register = false;
  bool _busy = false;
  String? _error;
  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_busy || !_form.currentState!.validate()) return;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      if (_register) {
        final result = await auth.createUserWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
        // All public registrations are ordinary users. Only the Admin SDK grants admin claims.
        await FirebaseFirestore.instance
            .collection('JackSocialApp')
            .doc('All Users')
            .collection('Users')
            .doc(result.user!.uid)
            .set({'role': 'Users'});
      } else {
        await auth.signInWithEmailAndPassword(
          email: _email.text.trim(),
          password: _password.text,
        );
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        setState(
          () => _error = e.code == 'weak-password'
              ? 'Choose a stronger password.'
              : 'Could not sign in or create the account. Check your details and connection.',
        );
      }
    } catch (_) {
      if (mounted) {
        setState(
          () => _error =
              'Could not finish account setup. Please check your Firebase configuration.',
        );
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _reset() async {
    if (_email.text.trim().isEmpty || _busy) return;
    setState(() => _busy = true);
    try {
      await auth.sendPasswordResetEmail(email: _email.text.trim());
      if (mounted) {
        ScaffoldSnackbar.of(
          context,
        ).show('If the account exists, a reset email has been sent.');
      }
    } catch (_) {
      if (mounted) {
        setState(() => _error = 'Could not request a reset email. Try again.');
      }
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: Center(
      child: SingleChildScrollView(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 440),
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _form,
              child: Column(
                children: [
                  Text(
                    _register ? 'Create your Ai-D account' : 'Welcome to Ai-D',
                    style: Theme.of(context).textTheme.headlineSmall,
                  ),
                  const SizedBox(height: 24),
                  TextFormField(
                    controller: _email,
                    enabled: !_busy,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (v) => v != null && v.contains('@')
                        ? null
                        : 'Enter an email address',
                  ),
                  TextFormField(
                    controller: _password,
                    enabled: !_busy,
                    obscureText: true,
                    decoration: const InputDecoration(labelText: 'Password'),
                    validator: (v) => (v?.length ?? 0) >= 6
                        ? null
                        : 'Use at least 6 characters',
                  ),
                  if (_error != null) Text(_error!),
                  if (_busy) const LinearProgressIndicator(),
                  FilledButton(
                    onPressed: _busy ? null : _submit,
                    child: Text(_register ? 'Create account' : 'Sign in'),
                  ),
                  TextButton(
                    onPressed: _busy
                        ? null
                        : () => setState(() {
                            _register = !_register;
                            _error = null;
                          }),
                    child: Text(
                      _register
                          ? 'Already have an account?'
                          : 'Create an account',
                    ),
                  ),
                  TextButton(
                    onPressed: _busy ? null : _reset,
                    child: const Text('Reset password'),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    ),
  );
}
