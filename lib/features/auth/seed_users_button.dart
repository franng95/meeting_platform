// lib/features/users/seed_users_button.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../auth/auth_providers.dart';

class SeedUsersButton extends ConsumerStatefulWidget {
  const SeedUsersButton({super.key});

  @override
  ConsumerState<SeedUsersButton> createState() => _SeedUsersButtonState();
}

class _SeedUsersButtonState extends ConsumerState<SeedUsersButton> {
  bool _busy = false;

  final _demoUsers = const [
    _SeedUser(email: 'alice@example.com', password: 'passw0rd', displayName: 'Alice'),
    _SeedUser(email: 'bob@example.com', password: 'passw0rd', displayName: 'Bob'),
    _SeedUser(email: 'charlie@example.com', password: 'passw0rd', displayName: 'Charlie'),
    _SeedUser(email: 'diana@example.com', password: 'passw0rd', displayName: 'Diana'),
  ];

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _busy ? null : () => _seed(context),
      icon: _busy
          ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2))
          : const Icon(Icons.auto_fix_high),
      label: Text(_busy ? 'Seeding...' : 'Seed demo users'),
    );
  }

  Future<void> _seed(BuildContext context) async {
    setState(() => _busy = true);

    final authSvc = ref.read(authServiceProvider);
    final auth = FirebaseAuth.instance;
    final db = FirebaseFirestore.instance;

    // Optional: sign out to avoid seeding under a currently signed-in user
    try {
      await auth.signOut();
    } catch (_) {}

    int created = 0;
    int updated = 0;

    for (final u in _demoUsers) {
      try {
        // Try to register (preferred path)
        await authSvc.registerWithEmailAndPassword(u.email, u.password);
        final current = auth.currentUser;
        if (current != null) {
          // Set displayName if needed
          if ((current.displayName == null || current.displayName!.trim().isEmpty)) {
            await current.updateDisplayName(u.displayName);
          }
          // Ensure users/{uid} exists & has the intended displayName (merge)
          await db.collection('users').doc(current.uid).set({
            'uid': current.uid,
            'displayName': u.displayName,
            'email': current.email,
            'createdAt': FieldValue.serverTimestamp(),
          }, SetOptions(merge: true));
        }
        created++;
      } on FirebaseAuthException catch (e) {
        // If email already exists, sign in then make sure profile + doc are correct.
        if (e.code == 'email-already-in-use') {
          await authSvc.signInWithEmailAndPassword(u.email, u.password);
          final current = auth.currentUser;
          if (current != null) {
            if ((current.displayName == null || current.displayName!.trim().isEmpty)) {
              await current.updateDisplayName(u.displayName);
            }
            await db.collection('users').doc(current.uid).set({
              'uid': current.uid,
              'displayName': u.displayName,
              'email': current.email,
            }, SetOptions(merge: true));
          }
          updated++;
        } else {
          // Surface unexpected errors but keep going for the rest
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Seed error for ${u.email}: ${e.message}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Seed error for ${u.email}: $e'),
            backgroundColor: Colors.red,
          ),
        );
      } finally {
        // Sign out between users so each account is created cleanly
        try {
          await auth.signOut();
        } catch (_) {}
      }
    }

    if (mounted) {
      setState(() => _busy = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Seeding complete • Created: $created • Updated: $updated'),
          backgroundColor: Colors.green,
        ),
      );
    }
  }
}

class _SeedUser {
  final String email;
  final String password;
  final String displayName;
  const _SeedUser({
    required this.email,
    required this.password,
    required this.displayName,
  });
}
