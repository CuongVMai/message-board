import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'board_service.dart';
import 'models.dart';

////// RULES TEST SWITCH: set to true ONLY to capture the cross-uid denial
////// screenshot. It shows edit/delete on EVERY message so you can try to change
////// someone else's post and watch Firestore reject it. Set back to false after.
const bool kRulesTestMode = false;

////// SPICE #4 TEST SWITCH: set to true ONLY to capture the duplicate-call
////// evidence. One tap on Send then calls postMessage TWICE at the same time
////// with the same id. Firestore should still end up with ONE document.
const bool kDuplicateTestMode = false;

////// new file: the live message board (create / read / update / delete).
class BoardScreen extends StatefulWidget {
  const BoardScreen({super.key, required this.user, required this.profile});
  final User user;
  final UserRecord profile;
  @override
  State<BoardScreen> createState() => _BoardScreenState();
}

class _BoardScreenState extends State<BoardScreen> {
  final _auth = AuthService();
  final _board = BoardService();
  // One stream for the life of this screen (not re-created on every build).
  late final Stream<List<Message>> _messages = _board.messageBoard();
  final _text = TextEditingController();
  bool _posting = false;
  ////// SPICE #4: one id per draft; a new id only after a successful post
  late String _draftId = _board.newMessageId();

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  void _show(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  void _showFirebaseError(FirebaseException e) {
    if (e.code == 'permission-denied') {
      _show('Permission denied: you can only change your own messages.');
    } else {
      _show('Something went wrong (${e.code}). Try again.');
    }
  }

  // CREATE
  Future<void> _post() async {
    final text = _text.text.trim();
    if (text.isEmpty) {
      _show('Type a message first.');
      return;
    }
    if (_posting) return; // duplicate-submit guard
    setState(() {
      _posting = true;
    });
    try {
      ////// SPICE #4: same id every time this draft is sent
      Future<void> send() => _board.postMessage(
        messageId: _draftId,
        authorUid: widget.user.uid,
        authorName: widget.profile.fullName,
        text: text,
      );
      if (kDuplicateTestMode) {
        await Future.wait([send(), send()]); // deliberate duplicate call
      } else {
        await send();
      }
      _text.clear();
      _draftId = _board.newMessageId(); ////// fresh id for the next message
    } on FirebaseException catch (e) {
      _showFirebaseError(e);
    } finally {
      if (mounted)
        setState(() {
          _posting = false;
        });
    }
  }

  // UPDATE
  Future<void> _edit(Message m) async {
    final controller = TextEditingController(text: m.text);
    final newText = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Edit message'),
        content: TextField(controller: controller, autofocus: true),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, controller.text.trim()),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    if (newText == null) return;
    if (newText.isEmpty) {
      _show('Message cannot be empty.');
      return;
    }
    if (newText == m.text) return;
    try {
      await _board.editMessage(messageId: m.id, newText: newText);
    } on FirebaseException catch (e) {
      _showFirebaseError(e);
    }
  }

  // DELETE
  Future<void> _delete(Message m) async {
    try {
      await _board.deleteMessage(messageId: m.id);
    } on FirebaseException catch (e) {
      _showFirebaseError(e);
    }
  }

  String _subtitle(Message m) {
    final d = m.createdAt?.toLocal();
    final time = d == null
        ? 'Sending...'
        : '${d.month}/${d.day} ${d.hour}:${d.minute.toString().padLeft(2, '0')}';
    return '${m.authorName} · $time${m.editedAt != null ? ' · edited' : ''}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Message Board'),
        actions: [
          Center(child: Text(widget.profile.firstName)),
          IconButton(
            tooltip: 'Sign out',
            icon: const Icon(Icons.logout),
            onPressed: () => _auth.signOut(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: StreamBuilder<List<Message>>(
              stream: _messages,
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return const Center(
                    child: Text('Could not load the board. Try again later.'),
                  );
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                final messages = snapshot.data ?? [];
                if (messages.isEmpty) {
                  return const Center(
                    child: Text('No messages yet. Be the first to post!'),
                  );
                }
                return ListView.builder(
                  itemCount: messages.length,
                  itemBuilder: (context, i) {
                    final m = messages[i];
                    final mine = m.authorUid == widget.user.uid;
                    return ListTile(
                      key: ValueKey(m.id), // use doc id, never list index
                      title: Text(m.text),
                      subtitle: Text(_subtitle(m)),
                      trailing: (mine || kRulesTestMode)
                          ? Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: const Icon(Icons.edit),
                                  onPressed: () => _edit(m),
                                ),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  onPressed: () => _delete(m),
                                ),
                              ],
                            )
                          : null,
                    );
                  },
                );
              },
            ),
          ),
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.all(8),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _text,
                      decoration: const InputDecoration(
                        hintText: 'Write a message',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    icon: _posting
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    onPressed: _posting ? null : _post,
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
