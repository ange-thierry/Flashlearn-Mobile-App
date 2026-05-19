import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

const String adminEmail = 'angethierry250@gmail.com';

class AuthService {
  static final AuthService _instance = AuthService._();
  factory AuthService() => _instance;
  AuthService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    serverClientId: '72338823868-6fa40pqk6qtv6qddk9rhgfhjp25o3c27.apps.googleusercontent.com',
  );

  User? get currentUser => _auth.currentUser;
  bool get isLoggedIn => _auth.currentUser != null;
  bool get isAdmin => _auth.currentUser?.email == adminEmail || isDemoAdmin;

  String get displayName {
    final user = _auth.currentUser;
    if (user != null) {
      return user.displayName ?? user.email?.split('@').first ?? 'Learner';
    }
    return _demoEmail?.split('@').first ?? 'Learner';
  }

  String? get photoURL => _auth.currentUser?.photoURL;
  String get firstName => displayName.split(' ').first;
  String? get userEmail => _auth.currentUser?.email ?? _demoEmail;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<AuthResult> signIn(String email, String password) async {
    try {
      await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'user-not-found':
        case 'wrong-password':
        case 'invalid-credential':
          return AuthResult.wrongPassword;
        case 'invalid-email':
          return AuthResult.invalidEmail;
        case 'user-disabled':
          return AuthResult.error;
        default:
          return AuthResult.error;
      }
    }
  }

  Future<AuthResult> signUp(String email, String password) async {
    try {
      await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password.trim(),
      );
      return AuthResult.success;
    } on FirebaseAuthException catch (e) {
      switch (e.code) {
        case 'email-already-in-use':
          return AuthResult.emailInUse;
        case 'weak-password':
          return AuthResult.weakPassword;
        case 'invalid-email':
          return AuthResult.invalidEmail;
        default:
          return AuthResult.error;
      }
    }
  }

  Future<AuthResult> signInWithGoogle() async {
    try {
      await _googleSignIn.signOut(); // clear any stale session
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return AuthResult.cancelled;

      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await _auth.signInWithCredential(credential);
      return AuthResult.success;
    } catch (e, st) {
      debugPrint('Google Sign-In error: $e\n$st');
      return AuthResult.error;
    }
  }

  Future<void> signOut() async {
    _demoMode = false;
    _demoEmail = null;
    await _googleSignIn.signOut();
    await _auth.signOut();
  }

  // Demo mode: allows bypass auth for classroom demos
  String? _demoEmail;
  bool _demoMode = false;

  void enableDemoMode(String email) {
    _demoMode = true;
    _demoEmail = email;
  }

  bool get isDemoAdmin => _demoMode && _demoEmail == adminEmail;
  String? get demoEmail => _demoEmail;
  bool get isDemoLoggedIn => _demoMode && _demoEmail != null;
}

enum AuthResult { success, wrongPassword, invalidEmail, emailInUse, weakPassword, cancelled, error }
