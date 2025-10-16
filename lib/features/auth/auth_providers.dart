// lib/features/auth/auth_providers.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/auth_service.dart';

/// Provider for AuthService (single instance shared across app)
final authServiceProvider = Provider<AuthService>((ref) {
  return AuthService();
});

/// Provider that streams the current Firebase User (logged in/out state)
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});