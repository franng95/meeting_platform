// lib/features/users/users_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../../services/users_service.dart';
import '../../models/app_user.dart';
import '../auth/auth_providers.dart';

/// Provider for UsersService
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService();
});

/// Provider that fetches all users except the current user
final otherUsersProvider = FutureProvider<List<AppUser>>((ref) async {
  final usersService = ref.watch(usersServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final currentUser = authService.currentUser;
  
  if (currentUser == null) {
    debugPrint('❌ No current user, returning empty list');
    return [];
  }
  
  debugPrint('🔍 Current user UID: ${currentUser.uid}');
  debugPrint('🔍 Current user email: ${currentUser.email}');
  
  // Get all users except me
  final users = await usersService.getUsersExceptMe(currentUser.uid);
  
  debugPrint('✅ Filtered users (excluding me): ${users.length}');
  for (var user in users) {
    debugPrint('   - ${user.displayName} (${user.uid})');
  }
  
  return users;
});