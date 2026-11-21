import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'board_screen.dart';
import 'board_service.dart';
import 'models.dart';

////// new file: keeps the board behind a complete users/{uid} record.
class ProfileGate extends StatefulWidget {
  const ProfileGate({super.key, required this.user});
  final User user;
  @override
  State<ProfileGate> createState() => _ProfileGateState();
}

class _ProfileGateState extends State<ProfileGate> {
  final BoardService _board = BoardService();
  // One stream, created once (not on every build).
  late final Stream<UserRecord?> _record = _board.userRecord(widget.user.uid);

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<UserRecord?>(
      stream: _record,
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Scaffold(
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Could not load your profile.'),
                  TextButton(
                    onPressed: () => AuthService().signOut(),
                    child: const Text('Sign out'),
                  ),
                ],
              ),
            ),
          );
        }
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }
        final record = snapshot.data;
        if (record == null) return _CompleteProfile(user: widget.user);
        return BoardScreen(user: widget.user, profile: record);
      },
    );
  }
}

/// Shown only if the account exists but the Firestore record is missing
/// ("Account created, profile not saved" -> retry for the same uid).
class _CompleteProfile extends StatefulWidget {
  const _CompleteProfile({required this.user});
  final User user;
  @override
  State<_CompleteProfile> createState() => _CompleteProfileState();
}

class _CompleteProfileState extends State<_CompleteProfile> {
  final _formKey = GlobalKey<FormState>();
  final _firstName = TextEditingController();
  final _lastName = TextEditingController();
  final _board = BoardService();
  String _role = 'Student';
  bool _busy = false;

  @override
  void dispose() {
    _firstName.dispose();
    _lastName.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_busy || !_formKey.currentState!.validate()) return;
    setState(() {
      _busy = true;
    });
    try {
      await _board.saveUserRecord(
        uid: widget.user.uid,
        firstName: _firstName.text.trim(),
        lastName: _lastName.text.trim(),
        role: _role,
      );
    } on FirebaseException catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Profile not saved. Check your connection and retry.',
            ),
          ),
        );
      }
    } finally {
      if (mounted)
        setState(() {
          _busy = false;
        });
    }
  }

  String? _required(String? v) => (v ?? '').trim().isEmpty ? 'Required' : null;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Finish your profile'),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => AuthService().signOut(),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            const Text(
              'Your account exists, but your profile was not saved yet.',
            ),
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
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _busy ? null : _save,
              child: const Text('Save profile'),
            ),
          ],
        ),
      ),
    );
  }
}
