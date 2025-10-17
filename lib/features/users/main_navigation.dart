// lib/features/users/main_navigation.dart
import 'package:characters/characters.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/app_user.dart';
import '../auth/auth_providers.dart';
import 'users_providers.dart';
import 'users_list_screen.dart';
import 'home_screen.dart';
import '../invitations/invitations_screen.dart';
import '../meetings/meetings_screen.dart';

/// Local auth uid stream used to key/remount tab content on account switch.
final _authUidProvider = StreamProvider<String?>(
  (ref) => FirebaseAuth.instance.authStateChanges().map((u) => u?.uid),
);

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  // New order: Home (0), Users (1), Invitations (2), Meetings (3)
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    // Watch uid so the whole nav can remount when the account changes.
    final uidAsync = ref.watch(_authUidProvider);
    final uidKey = uidAsync.when<String>(
      data: (uid) => uid ?? 'nouser',
      loading: () => 'loading',
      error: (_, __) => 'error',
    );

    return KeyedSubtree(
      key: ValueKey(uidKey),
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Meeting Platform',
                style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              ),
              if (user != null)
                Text(
                  user.displayName ?? user.email ?? '',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.normal,
                  ),
                ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: () async {
                await authService.signOut();
              },
              tooltip: 'Sign Out',
            ),
          ],
          elevation: 0,
        ),
        body: IndexedStack(
          index: _currentIndex,
          children: const [
            HomeScreen(),          // 0
            UsersListContent(),    // 1
            InvitationsScreen(),   // 2
            MeetingsScreen(),      // 3
          ],
        ),
        bottomNavigationBar: NavigationBar(
          selectedIndex: _currentIndex,
          onDestinationSelected: (index) {
            setState(() => _currentIndex = index);
            // If returning to Users tab, proactively refresh the keyed provider.
            if (index == 1) {
              final uid = ref.read(_authUidProvider).asData?.value;
              if (uid != null) {
                ref.invalidate(otherUsersProvider(uid));
              }
            }
          },
          destinations: const [
            NavigationDestination(
              icon: Icon(Icons.home_outlined),
              selectedIcon: Icon(Icons.home),
              label: 'Home',
            ),
            NavigationDestination(
              icon: Icon(Icons.people_outline),
              selectedIcon: Icon(Icons.people),
              label: 'Users',
            ),
            NavigationDestination(
              icon: Icon(Icons.mail_outline),
              selectedIcon: Icon(Icons.mail),
              label: 'Invitations',
            ),
            NavigationDestination(
              icon: Icon(Icons.videocam_outlined),
              selectedIcon: Icon(Icons.videocam),
              label: 'Meetings',
            ),
          ],
        ),
      ),
    );
  }
}

/// Users list content (without its own app bar), keyed by uid
class UsersListContent extends ConsumerStatefulWidget {
  const UsersListContent({super.key});

  @override
  ConsumerState<UsersListContent> createState() => _UsersListContentState();
}

class _UsersListContentState extends ConsumerState<UsersListContent>
    with AutomaticKeepAliveClientMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';

  @override
  bool get wantKeepAlive => true;

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
    super.build(context); // IMPORTANT: for KeepAlive
    final uidAsync = ref.watch(_authUidProvider);

    return uidAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (err, _) => Center(child: Text('Auth error: $err')),
      data: (uid) {
        if (uid == null) {
          return const Center(child: Text('Not signed in'));
        }

        // Provider requires uid (family) — prevents stale cache between accounts.
        final usersAsync = ref.watch(otherUsersProvider(uid));

        return Column(
          children: [
            // Search bar
            Container(
              padding: const EdgeInsets.all(16),
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
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, stack) => Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.error, size: 64, color: Colors.red),
                      const SizedBox(height: 16),
                      Text('Error: $error'),
                      ElevatedButton(
                        onPressed: () => ref.refresh(otherUsersProvider(uid)),
                        child: const Text('Retry'),
                      ),
                    ],
                  ),
                ),
                data: (users) {
                  final filteredUsers = users.where((user) {
                    return user.displayName.toLowerCase().contains(_searchQuery) ||
                        user.email.toLowerCase().contains(_searchQuery);
                  }).toList();

                  if (filteredUsers.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            _searchQuery.isEmpty ? Icons.people_outline : Icons.search_off,
                            size: 64,
                            color: Colors.grey,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _searchQuery.isEmpty
                                ? 'No other users found'
                                : 'No users match "$_searchQuery"',
                            style: const TextStyle(fontSize: 18, color: Colors.grey),
                          ),
                        ],
                      ),
                    );
                  }

                  return ListView.builder(
                    itemCount: filteredUsers.length,
                    padding: const EdgeInsets.all(16),
                    itemBuilder: (context, index) {
                      final u = filteredUsers[index];
                      return _UserCard(user: u, initial: _safeInitial(u.displayName));
                    },
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }
}

/// User card with invite button (kept minimal)
class _UserCard extends ConsumerWidget {
  final AppUser user;
  final String initial;

  const _UserCard({required this.user, required this.initial});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
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
        title: Text(
          user.displayName,
          style: const TextStyle(fontWeight: FontWeight.w600),
        ),
        subtitle: Text(
          user.email,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        trailing: ElevatedButton.icon(
          onPressed: () {
            // Navigate to full users_list_screen for invite dialog (kept)
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const UsersListScreen(),
              ),
            );
          },
          icon: const Icon(Icons.send, size: 18),
          label: const Text('Invite'),
        ),
      ),
    );
  }
}
