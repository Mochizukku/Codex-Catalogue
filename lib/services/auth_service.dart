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
    final cred = await _auth.createUserWithEmailAndPassword(
      email: email.trim(),
      password: password,
    );
    final user = cred.user!;
    await user.updateDisplayName(displayName.trim());
    final appUser = AppUser(
      uid: user.uid,
      displayName: displayName.trim(),
      email: email.trim(),
      role: UserRole.reader,
      inUniverseRole: 'The Seeker',
      createdAt: DateTime.now(),
    );
    await _firestore
        .collection('users')
        .doc(user.uid)
        .set(appUser.toMap(), SetOptions(merge: true));
    return appUser;
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
