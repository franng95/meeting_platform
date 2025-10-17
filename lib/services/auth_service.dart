// lib/services/auth_service.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

/// Service that handles all authentication logic
class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream of auth state changes (logged in/out)
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user
  User? get currentUser => _auth.currentUser;

  /// --- NEW: ensure users/{uid} exists (idempotent) ---
  Future<void> _ensureUserDoc(User u) async {
    final ref = _firestore.collection('users').doc(u.uid);
    final snap = await ref.get();

    if (!snap.exists) {
      await ref.set({
        'uid': u.uid,
        'email': u.email,
        'displayName': u.displayName,
        'createdAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
    } else {
      // Keep fields aligned (don’t overwrite createdAt if present)
      await ref.set({
        'uid': u.uid,
        'email': u.email,
        'displayName': u.displayName,
      }, SetOptions(merge: true));
    }
  }

  /// Sign in with email and password (original API)
  Future<User?> signInWithEmail(String email, String password) async {
    try {
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
      final user = credential.user;
      if (user != null) {
        await _ensureUserDoc(user); // ensure users/{uid} exists on sign-in too
      }
      debugPrint('✅ Signed in: ${credential.user?.email}');
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign in error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// Create new account with email and password (original API)
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String displayName,
  }) async {
    try {
      // Create auth account
      final credential = await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = credential.user;
      if (user == null) return null;

      // Update display name
      await user.updateDisplayName(displayName);

      // Create/merge user document in Firestore
      final appUser = AppUser(
        uid: user.uid,
        email: email,
        displayName: displayName,
        createdAt: DateTime.now(),
      );
      await _firestore.collection('users').doc(user.uid).set(appUser.toJson(), SetOptions(merge: true));

      debugPrint('✅ Created account: $email');
      return user;
    } on FirebaseAuthException catch (e) {
      debugPrint('❌ Sign up error: ${e.code} - ${e.message}');
      rethrow;
    }
  }

  /// --- NEW: compatibility wrappers (match callers in login screen + seeder) ---

  /// Alias for callers expecting Firebase-style naming.
  Future<User?> signInWithEmailAndPassword(String email, String password) {
    return signInWithEmail(email, password);
  }

  /// Alias for callers expecting Firebase-style naming (no displayName param).
  /// Uses the local-part of the email as a friendly default displayName.
  Future<User?> registerWithEmailAndPassword(String email, String password) {
    final suggested =
        email.contains('@') ? email.split('@').first.trim() : 'User';
    return signUpWithEmail(
      email: email,
      password: password,
      displayName: suggested.isEmpty ? 'User' : suggested,
    );
  }

  /// Optional alt aliases some screens might use.
  Future<User?> login(String email, String password) =>
      signInWithEmail(email, password);

  Future<User?> register(String email, String password) =>
      registerWithEmailAndPassword(email, password);

  /// Sign out
  Future<void> signOut() async {
    await _auth.signOut();
    debugPrint('✅ Signed out');
  }

  /// Get user document from Firestore
  Future<AppUser?> getUserDoc(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('❌ Error getting user doc: $e');
      return null;
    }
  }
}
