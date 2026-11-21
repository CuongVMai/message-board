import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'board_service.dart';

////// new file: one screen that switches between Sign in and Register.
////// Built from the "Tiny Fix Quest" _submit pattern (busy flag = no double submit).
class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});
  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _email = TextEditingController();
  final _password = TextEditingController();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _auth = AuthService();
  final _board = BoardService();

  bool _busy = false;
  bool _isRegister = false;
  String _role = 'Student';

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  // Turn Firebase error codes into friendly text (never show raw exceptions).
  String _authMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'That email address is not valid.';
      case 'weak-password':
        return 'Password must be at least 6 characters.';
      case 'email-already-in-use':
        return 'An account already exists for that email. Try signing in.';
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email or password is incorrect.';
      case 'network-request-failed':
        return 'Check your connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Wait a moment and try again.';
      default:
        return 'Something went wrong. Check your details and try again.';
    }
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _submit() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
    });
    try {
      if (_isRegister) {
        final credential = await _auth.register(
          email: _email.text,
          password: _password.text,
        );
        final user = credential.user;
        if (user == null) {
          _show('Registration failed. Please try again.');
          return;
        }
        // Write the users/{uid} record with all five fields.
        await _board.saveUserRecord(
          uid: user.uid,
          firstName: _firstName.text.trim(),
          lastName: _lastName.text.trim(),
          role: _role,
        );
      } else {
        await _auth.signIn(email: _email.text, password: _password.text);
      }
      // No Navigator.push here: AuthGate switches screens on its own.
    } on FirebaseAuthException catch (error) {
      _show(_authMessage(error.code));
    } on FirebaseException catch (_) {
      // Auth worked but the Firestore write failed. ProfileGate offers a retry.
      _show(
        'Account created, profile not saved. You can finish it on the next screen.',
      );
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  String? _validateEmail(String? v) {
    final value = (v ?? '').trim();
    if (value.isEmpty) return 'Enter your email';
    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(value)) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _validatePassword(String? v) {
    final value = v ?? '';
    if (value.isEmpty) return 'Enter your password';
    if (_isRegister && value.length < 6) return 'At least 6 characters';
    return null;
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isRegister ? 'Register' : 'Sign in')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              if (_isRegister) ...[
                TextFormField(
                  controller: _firstName,
                  decoration: const InputDecoration(labelText: 'First name'),
                  validator: _required,
                ),
                TextFormField(
                  controller: _lastName,
                  decoration: const InputDecoration(labelText: 'Last name'),
                  validator: _required,
                ),
                DropdownButtonFormField<String>(
                  value: _role,
                  decoration: const InputDecoration(labelText: 'Role'),
                  items: const [
                    DropdownMenuItem(value: 'Student', child: Text('Student')),
                    DropdownMenuItem(
                      value: 'Instructor',
                      child: Text('Instructor'),
                    ),
                  ],
                  onChanged: (v) => setState(() {
                    _role = v ?? 'Student';
                  }),
                ),
              ],
              TextFormField(
                controller: _email,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(labelText: 'Email'),
                validator: _validateEmail,
              ),
              TextFormField(
                controller: _password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Password'),
                validator: _validatePassword,
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: _busy ? null : _submit,
                child: _busy
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(_isRegister ? 'Create account' : 'Sign in'),
              ),
              TextButton(
                onPressed: _busy
                    ? null
                    : () => setState(() {
                        _isRegister = !_isRegister;
                      }),
                child: Text(
                  _isRegister
                      ? 'Already have an account? Sign in'
                      : 'New here? Register',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
