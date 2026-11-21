////// new file: typed models so widgets never touch Firestore types

/// One document in messages/{msgId}
class Message {
  final String id;
  final String text;
  final String authorUid;
  final String authorName;
  final DateTime?
  createdAt; // null while the server timestamp is pending ("Sending...")
  final DateTime? editedAt;

  const Message({
    required this.id,
    required this.text,
    required this.authorUid,
    required this.authorName,
    this.createdAt,
    this.editedAt,
  });
}

/// The private users/{uid} document (all five required fields)
class UserRecord {
  final String uid;
  final String firstName;
  final String lastName;
  final String role;
  final DateTime? registrationDateTime;

  const UserRecord({
    required this.uid,
    required this.firstName,
    required this.lastName,
    required this.role,
    this.registrationDateTime,
  });

  String get fullName => '$firstName $lastName';
}
