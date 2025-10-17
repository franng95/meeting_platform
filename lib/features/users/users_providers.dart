// lib/features/users/users_providers.dart
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../../services/users_service.dart';

/// Provider for UsersService
final usersServiceProvider = Provider<UsersService>((ref) {
  return UsersService();
});

/// Users list EXCEPT the given uid, keyed by uid so caches don't bleed across accounts.
/// Using autoDispose to free old user caches when uid changes.
final otherUsersProvider =
    FutureProvider.family.autoDispose<List<AppUser>, String>((ref, uid) async {
  final usersService = ref.watch(usersServiceProvider);

  if (uid.isEmpty) {
    debugPrint('❌ Empty uid, returning empty list');
    return const [];
  }

  debugPrint('🔍 Fetching users excluding uid: $uid');
  final users = await usersService.getUsersExceptMe(uid);
  debugPrint('✅ Filtered users (excluding $uid): ${users.length}');
  for (var user in users) {
    debugPrint('   - ${user.displayName} (${user.uid})');
  }

  return users;
});
