import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/app_user.dart';

class AuthService {
  AuthService({FirebaseAuth? auth, FirebaseFirestore? firestore})
    : _auth = auth ?? FirebaseAuth.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  User? get currentFirebaseUser => _auth.currentUser;

  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Stream<AppUser?> watchCurrentUser() =>
      _auth.authStateChanges().asyncExpand((user) {
        if (user == null) return Stream.value(null);
        return _firestore.collection('users').doc(user.uid).snapshots().map((
          doc,
        ) {
          if (!doc.exists || doc.data() == null) {
            return AppUser(
              uid: user.uid,
              displayName:
                  user.displayName ?? user.email?.split('@').first ?? 'Seer',
              email: user.email ?? '',
              createdAt: DateTime.now(),
            );
          }
          return AppUser.fromMap(user.uid, doc.data()!);
        });
      });

  Future<AppUser> signUp({
    required String email,
    required String password,
    required String displayName,
  }) async {
    final trimmedEmail = email.trim();
    final trimmedName = displayName.trim();
    final cred = await _auth.createUserWithEmailAndPassword(
      email: trimmedEmail,
      password: password,
    );
    final user = cred.user;
    if (user == null) {
      throw StateError('Registration did not return a Firebase user.');
    }

    // Roll back the Auth user if writing the Firestore profile fails so retries
    // do not get stuck behind email-already-in-use without a users/{uid} doc.
    try {
      await Future.wait([
        user.updateDisplayName(trimmedName),
        _firestore.collection('users').doc(user.uid).set({
          'displayName': trimmedName,
          'email': trimmedEmail,
          'role': UserRole.reader.firestoreValue,
          'inUniverseRole': UserRole.reader.defaultInUniverseTitle,
          'vanguardBranch': null,
          'truthPoints': 0,
          'bookmarkedArtifactIds': const <String>[],
          'createdAt': FieldValue.serverTimestamp(),
        }),
      ]);
    } catch (_) {
      try {
        await user.delete();
      } catch (_) {
        try {
          await _auth.signOut();
        } catch (_) {}
      }
      rethrow;
    }

    return AppUser(
      uid: user.uid,
      displayName: trimmedName,
      email: trimmedEmail,
      role: UserRole.reader,
      inUniverseRole: UserRole.reader.defaultInUniverseTitle,
      createdAt: DateTime.now(),
    );
  }

  /// Maps Firebase exceptions into concise user-facing error messages.
  static String formatAuthError(Object error) {
    if (error is FirebaseAuthException) {
      return switch (error.code) {
        'email-already-in-use' =>
          'An account with this email already exists. Try signing in instead.',
        'invalid-email' => 'Enter a valid email address.',
        'weak-password' =>
          'Password is too weak. Use at least 6 characters.',
        'operation-not-allowed' =>
          'Email/Password sign-up is not enabled in Firebase.',
        'network-request-failed' =>
          'Network error. Check your connection and try again.',
        'user-not-found' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Invalid email or password.',
        'too-many-requests' =>
          'Too many attempts. Please wait a moment and try again.',
        'user-disabled' => 'This account has been disabled.',
        _ => error.message ?? 'Authentication failed (${error.code}).',
      };
    }
    if (error is FirebaseException) {
      if (error.code == 'no-app') {
        return 'Firebase is not configured yet. Follow SETUP.md to link your project.';
      }
      return error.message ?? 'Firebase error (${error.code}).';
    }
    return error.toString().replaceFirst('Exception: ', '');
  }

  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _auth.signInWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
  }

  Future<void> signOut() => _auth.signOut();
}
