import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../core/constants/app_constants.dart';
import '../models/user_model.dart';

/// Thrown with a user-friendly message so the UI layer never has to know
/// about FirebaseAuthException codes directly.
class AuthException implements Exception {
  final String message;
  AuthException(this.message);
  @override
  String toString() => message;
}

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
      : _auth = auth ?? FirebaseAuth.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  /// Emits whenever auth state changes (sign in / sign out / token refresh
  /// on app start). Splash screen and router both listen to this.
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  User? get currentUser => _auth.currentUser;

  Future<UserModel> register({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;
      await credential.user!.updateDisplayName(name.trim());

      final user = UserModel(
        uid: uid,
        name: name.trim(),
        email: email.trim(),
        isOnline: true,
        lastSeen: DateTime.now(),
      );

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .set(user.toMap());

      return user;
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (_) {
      throw AuthException(
          'Could not create account. Check your connection and try again.');
    }
  }

  Future<UserModel> signIn({
    required String email,
    required String password,
  }) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
      final uid = credential.user!.uid;

      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get();

      if (!doc.exists) {
        // Edge case: auth account exists but Firestore doc got lost
        // (e.g. registration was interrupted). Recreate it minimally
        // rather than crashing the login flow.
        final fallback = UserModel(
          uid: uid,
          name: credential.user!.displayName ?? 'User',
          email: email.trim(),
          isOnline: true,
          lastSeen: DateTime.now(),
        );
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .set(fallback.toMap());
        return fallback;
      }

      await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .update({'isOnline': true, 'lastSeen': Timestamp.now()});

      return UserModel.fromMap(uid, doc.data()!);
    } on FirebaseAuthException catch (e) {
      throw AuthException(_mapAuthError(e));
    } catch (_) {
      throw AuthException(
          'Could not log in. Check your connection and try again.');
    }
  }

  Future<void> signOut() async {
    final uid = _auth.currentUser?.uid;
    if (uid != null) {
      // Best-effort presence update; don't block logout if this fails.
      try {
        await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .update({'isOnline': false, 'lastSeen': Timestamp.now()});
      } catch (_) {
        // Ignored on purpose — logout must still proceed offline.
      }
    }
    await _auth.signOut();
  }

  String _mapAuthError(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-email':
        return 'That email address looks invalid.';
      case 'user-disabled':
        return 'This account has been disabled.';
      case 'user-not-found':
      case 'wrong-password':
      case 'invalid-credential':
        return 'Incorrect email or password.';
      case 'email-already-in-use':
        return 'An account already exists with this email.';
      case 'weak-password':
        return 'Password is too weak. Use at least 6 characters.';
      case 'network-request-failed':
        return 'No internet connection. Please try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait and try again.';
      default:
        return 'Something went wrong. Please try again.';
    }
  }
}
