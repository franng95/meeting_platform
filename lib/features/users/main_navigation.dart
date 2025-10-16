// lib/features/users/main_navigation.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/app_user.dart';
import '../auth/auth_providers.dart';
import 'users_providers.dart';
import 'users_list_screen.dart';
import '../invitations/invitations_screen.dart';
import '../meetings/meetings_screen.dart';

class MainNavigation extends ConsumerStatefulWidget {
  const MainNavigation({super.key});

  @override
  ConsumerState<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends ConsumerState<MainNavigation> {
  int _currentIndex = 0;

  @override
  Widget build(BuildContext context) {
    final authService = ref.watch(authServiceProvider);
    final user = authService.currentUser;

    return Scaffold(
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
          UsersListContent(),
          InvitationsScreen(),
          MeetingsScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() => _currentIndex = index);
          // Refresh the users list when switching to Users tab
          if (index == 0) {
            ref.invalidate(otherUsersProvider);
          }
        },
        destinations: const [
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
    );
  }
}

/// Users list content (without app bar)
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

  @override
  Widget build(BuildContext context) {
    super.build(context); // IMPORTANT: Call super for KeepAlive to work
    final usersAsync = ref.watch(otherUsersProvider);

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
                    onPressed: () => ref.refresh(otherUsersProvider),
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
                  return _UserCard(user: filteredUsers[index]);
                },
              );
            },
          ),
        ),
      ],
    );
  }
}

/// User card with invite button
class _UserCard extends ConsumerWidget {
  final AppUser user;

  const _UserCard({required this.user});

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
              user.displayName[0].toUpperCase(),
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
            // Navigate to full users_list_screen for invite dialog
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