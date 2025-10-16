// lib/features/auth/seed_users_button.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'auth_providers.dart';

/// Debug button to create test users in the emulator
class SeedUsersButton extends ConsumerStatefulWidget {
  const SeedUsersButton({super.key});

  @override
  ConsumerState<SeedUsersButton> createState() => _SeedUsersButtonState();
}

class _SeedUsersButtonState extends ConsumerState<SeedUsersButton> {
  bool _isSeeding = false;
  String? _message;

  Future<void> _seedUsers() async {
    setState(() {
      _isSeeding = true;
      _message = null;
    });

    try {
      final authService = ref.read(authServiceProvider);

      // Create 3 test users
      final testUsers = [
        {'email': 'alice@test.com', 'password': 'password123', 'name': 'Alice Johnson'},
        {'email': 'bob@test.com', 'password': 'password123', 'name': 'Bob Smith'},
        {'email': 'charlie@test.com', 'password': 'password123', 'name': 'Charlie Brown'},
      ];

      for (var userData in testUsers) {
        try {
          await authService.signUpWithEmail(
            email: userData['email']!,
            password: userData['password']!,
            displayName: userData['name']!,
          );
          debugPrint('✅ Created user: ${userData['email']}');
        } catch (e) {
          // User might already exist, that's okay
          debugPrint('⚠️ User ${userData['email']} might already exist: $e');
        }
      }

      // Sign out after creating users
      await authService.signOut();

      setState(() {
        _message = '✅ Created 3 test users!\n\n'
            'alice@test.com\n'
            'bob@test.com\n'
            'charlie@test.com\n\n'
            'Password for all: password123';
      });
    } catch (e) {
      setState(() {
        _message = '❌ Error: $e';
      });
    } finally {
      setState(() {
        _isSeeding = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        OutlinedButton.icon(
          onPressed: _isSeeding ? null : _seedUsers,
          icon: _isSeeding
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.person_add),
          label: const Text('Create Test Users'),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          ),
        ),
        if (_message != null) ...[
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade200),
            ),
            child: Text(
              _message!,
              style: TextStyle(
                color: Colors.green.shade900,
                fontSize: 12,
              ),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ],
    );
  }
}