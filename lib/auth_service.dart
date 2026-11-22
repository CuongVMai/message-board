import 'package:firebase_auth/firebase_auth.dart';

/// Every Firebase Auth call lives here.
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  late final Stream<User?> authState = _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserCredential> register({
    required String email,
    required String password,
  }) {
    return _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) {
    return _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();

  ////// SPICE #1: point Firebase Auth at the local Auth emulator
  static Future<void> useEmulator(String host) =>
      FirebaseAuth.instance.useAuthEmulator(host, 9099);
}
