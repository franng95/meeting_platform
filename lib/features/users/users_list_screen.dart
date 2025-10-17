// lib/features/users/users_list_screen.dart
import 'package:characters/characters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import 'users_providers.dart';
import '../invitations/invitations_providers.dart';
import '../auth/auth_providers.dart';

/// Local auth uid stream for this screen (self-contained).
final _authUidProvider = StreamProvider<String?>(
  (ref) => FirebaseAuth.instance.authStateChanges().map((u) => u?.uid),
);

class UsersListScreen extends ConsumerStatefulWidget {
  const UsersListScreen({super.key});

  @override
  ConsumerState<UsersListScreen> createState() => _UsersListScreenState();
}

class _UsersListScreenState extends ConsumerState<UsersListScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  String _safeInitial(String name) {
    final n = name.trim();
    return n.isEmpty ? '?' : n.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final uidAsync = ref.watch(_authUidProvider);
    final uidKey = uidAsync.when<String>(
      data: (uid) => uid ?? 'nouser',
      loading: () => 'loading',
      error: (_, __) => 'error',
    );

    return KeyedSubtree(
      key: ValueKey(uidKey),
      child: uidAsync.when(
        loading: () => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
        error: (err, _) => Scaffold(
          body: Center(child: Text('Auth error: $err')),
        ),
        data: (uid) {
          if (uid == null) {
            return const Scaffold(
              body: Center(child: Text('Not signed in')),
            );
          }

          // IMPORTANT: provider is now keyed by uid → no stale cache between users
          final usersAsync = ref.watch(otherUsersProvider(uid));

          return Scaffold(
            appBar: AppBar(
              title: const Text('Users'),
              elevation: 0,
            ),
            body: Column(
              children: [
                // Search bar
                Container(
                  padding: const EdgeInsets.all(16),
                  color: Theme.of(context).colorScheme.surface,
                  child: TextField(
                    controller: _searchController,
                    decoration: InputDecoration(
                      hintText: 'Search users...',
                      prefixIcon: const Icon(Icons.search),
                      suffixIcon: _searchQuery.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear),
                              onPressed: () {
                                _searchController.clear();
                                setState(() => _searchQuery = '');
                              },
                            )
                          : null,
                    ),
                    onChanged: (value) {
                      setState(() => _searchQuery = value.toLowerCase());
                    },
                  ),
                ),

                // Users list
                Expanded(
                  child: usersAsync.when(
                    loading: () => const Center(
                      child: CircularProgressIndicator(),
                    ),
                    error: (error, stack) => Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Icon(Icons.error, size: 64, color: Colors.red),
                          const SizedBox(height: 16),
                          Text('Error: $error'),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => ref.refresh(otherUsersProvider(uid)),
                            child: const Text('Retry'),
                          ),
                        ],
                      ),
                    ),
                    data: (users) {
                      // Filter users based on search query
                      final filteredUsers = users.where((user) {
                        final name = user.displayName.toLowerCase();
                        final mail = user.email.toLowerCase();
                        return name.contains(_searchQuery) || mail.contains(_searchQuery);
                      }).toList();

                      if (filteredUsers.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(
                                _searchQuery.isEmpty
                                    ? Icons.people_outline
                                    : Icons.search_off,
                                size: 64,
                                color: Colors.grey,
                              ),
                              const SizedBox(height: 16),
                              Text(
                                _searchQuery.isEmpty
                                    ? 'No other users found'
                                    : 'No users match "$_searchQuery"',
                                style: const TextStyle(
                                  fontSize: 18,
                                  color: Colors.grey,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      return ListView.builder(
                        itemCount: filteredUsers.length,
                        padding: const EdgeInsets.all(16),
                        itemBuilder: (context, index) {
                          final user = filteredUsers[index];
                          return _UserListTile(
                            user: user,
                            initial: _safeInitial(user.displayName),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}

/// Individual user card with invite button
class _UserListTile extends ConsumerWidget {
  final AppUser user;
  final String initial;

  const _UserListTile({required this.user, required this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        // Avatar with gradient background
        leading: Container(
          width: 50,
          height: 50,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Theme.of(context).colorScheme.primary,
                Theme.of(context).colorScheme.secondary,
              ],
            ),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              initial,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),

        // User name and email
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          user.email,
          style: TextStyle(
            color: Colors.grey.shade600,
            fontSize: 13,
          ),
        ),

        // Invite button
        trailing: FilledButton.icon(
          onPressed: () => _showScheduleInviteDialog(context, ref),
          icon: const Icon(Icons.send, size: 18),
          label: const Text('Invite'),
          style: FilledButton.styleFrom(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          ),
        ),
      ),
    );
  }

  Future<void> _showScheduleInviteDialog(BuildContext context, WidgetRef ref) async {
    DateTime selectedDate = DateTime.now().add(const Duration(days: 7));
    TimeOfDay selectedTime = const TimeOfDay(hour: 14, minute: 0);

    final result = await showDialog<DateTime>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text('Invite ${user.displayName}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Choose a meeting time:',
                style: TextStyle(fontSize: 14),
              ),
              const SizedBox(height: 16),

              // Date picker
              ListTile(
                leading: const Icon(Icons.calendar_today),
                title: const Text('Date'),
                subtitle: Text(
                  '${selectedDate.day}/${selectedDate.month}/${selectedDate.year}',
                ),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final date = await showDatePicker(
                    context: context,
                    initialDate: selectedDate,
                    firstDate: DateTime.now(),
                    lastDate: DateTime.now().add(const Duration(days: 365)),
                  );
                  if (date != null) {
                    setState(() {
                      selectedDate = DateTime(
                        date.year,
                        date.month,
                        date.day,
                        selectedTime.hour,
                        selectedTime.minute,
                      );
                    });
                  }
                },
              ),

              // Time picker
              ListTile(
                leading: const Icon(Icons.access_time),
                title: const Text('Time'),
                subtitle: Text(selectedTime.format(context)),
                trailing: const Icon(Icons.edit),
                onTap: () async {
                  final time = await showTimePicker(
                    context: context,
                    initialTime: selectedTime,
                  );
                  if (time != null) {
                    setState(() {
                      selectedTime = time;
                      selectedDate = DateTime(
                        selectedDate.year,
                        selectedDate.month,
                        selectedDate.day,
                        time.hour,
                        time.minute,
                      );
                    });
                  }
                },
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancel'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, selectedDate),
              child: const Text('Send Invite'),
            ),
          ],
        ),
      ),
    );

    if (result != null && context.mounted) {
      // Send invitation with scheduled time
      try {
        final authService = ref.read(authServiceProvider);
        final invitationsService = ref.read(invitationsServiceProvider);
        final currentUser = authService.currentUser;

        if (currentUser == null) return;

        await invitationsService.sendInvitation(
          senderId: currentUser.uid,
          receiverId: user.uid,
          scheduledFor: result,
        );

        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Invitation sent to ${user.displayName}!'),
              backgroundColor: Colors.green,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Error: $e'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }
}
