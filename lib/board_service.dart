import 'package:cloud_firestore/cloud_firestore.dart';

import 'models.dart';

/// Every Firestore call in the app lives here. Widgets never import cloud_firestore.
class BoardService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  ////// SPICE #1: point Firestore at the local Firestore emulator
  static void useEmulator(String host) =>
      FirebaseFirestore.instance.useFirestoreEmulator(host, 8080);

  // ---------------- USER RECORD (users/{uid}) ----------------

  /// Saves the user record. Called ONCE, at registration (or from the
  /// "finish your profile" retry screen). Never on login.
  Future<void> saveUserRecord({
    required String uid,
    required String firstName,
    required String lastName,
    required String role,
  }) async {
    await _db.collection('users').doc(uid).set({
      'uid': uid,
      'firstName': firstName,
      'lastName': lastName,
      'role': role,
      'registrationDateTime': FieldValue.serverTimestamp(),
    });
  }

  ////// added: live view of the user's record. Emits null if the doc is
  ////// missing or is missing any of the five required fields.
  Stream<UserRecord?> userRecord(String uid) {
    const fields = [
      'uid',
      'firstName',
      'lastName',
      'role',
      'registrationDateTime',
    ];
    return _db.collection('users').doc(uid).snapshots().map((doc) {
      final data = doc.data();
      if (data == null || !fields.every(data.containsKey)) return null;
      return UserRecord(
        uid: data['uid'] as String,
        firstName: data['firstName'] as String,
        lastName: data['lastName'] as String,
        role: data['role'] as String,
        registrationDateTime: (data['registrationDateTime'] as Timestamp?)
            ?.toDate(),
      );
    });
  }

  // ---------------- MESSAGES (messages/{msgId}) ----------------

  ////// SPICE #4: make a new document id up front (one id per draft message).
  String newMessageId() => _db.collection('messages').doc().id;

  /// CREATE — uid-owned, server-timestamped.
  ////// SPICE #4 (idempotent): the id is decided before the write, and a
  ////// transaction only creates the doc if it does not exist yet. So calling
  ////// this twice with the same id (double-tap, retry) still leaves ONE doc.
  Future<void> postMessage({
    required String messageId,
    required String authorUid,
    required String authorName,
    required String text,
  }) async {
    final ref = _db.collection('messages').doc(messageId);
    await _db.runTransaction((tx) async {
      final snap = await tx.get(ref);
      if (snap.exists) return; // already created -> do nothing
      tx.set(ref, {
        'authorUid': authorUid,
        'authorName': authorName,
        'text': text,
        'createdAt': FieldValue.serverTimestamp(),
      });
    });
  }

  /// READ (live) — the board renders from this stream.
  ////// changed: maps documents to typed Message objects inside the service
  Stream<List<Message>> messageBoard() {
    return _db
        .collection('messages')
        .orderBy('createdAt')
        .snapshots()
        .map(
          (snap) => snap.docs.map((doc) {
            final d = doc.data();
            return Message(
              id: doc.id,
              text: (d['text'] ?? '') as String,
              authorUid: (d['authorUid'] ?? '') as String,
              authorName: (d['authorName'] ?? 'Unknown') as String,
              createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
              editedAt: (d['editedAt'] as Timestamp?)?.toDate(),
            );
          }).toList(),
        );
  }

  /// UPDATE — own message only (rules enforce it)
  Future<void> editMessage({
    required String messageId,
    required String newText,
  }) async {
    await _db.collection('messages').doc(messageId).update({
      'text': newText,
      'editedAt': FieldValue.serverTimestamp(),
    });
  }

  /// DELETE — own message only (rules enforce it)
  Future<void> deleteMessage({required String messageId}) async {
    await _db.collection('messages').doc(messageId).delete();
  }
}
