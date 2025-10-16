// lib/features/invitations/invitations_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../models/invitation.dart';
import '../../models/app_user.dart';
import '../../services/users_service.dart';
import 'invitations_providers.dart';

class InvitationsScreen extends StatelessWidget {
  const InvitationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invitations'),
          backgroundColor: Theme.of(context).colorScheme.inversePrimary,
          automaticallyImplyLeading: false, // Remove back button when in bottom nav
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.send), text: 'Sent'),
              Tab(icon: Icon(Icons.inbox), text: 'Received'),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            _SentInvitationsTab(),
            _ReceivedInvitationsTab(),
          ],
        ),
      ),
    );
  }
}

/// Tab showing invitations I sent
class _SentInvitationsTab extends ConsumerWidget {
  const _SentInvitationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(sentInvitationsProvider);

    return invitationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (invitations) {
        if (invitations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No sent invitations', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: invitations.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final invitation = invitations[index];
            return _SentInvitationCard(invitation: invitation);
          },
        );
      },
    );
  }
}

/// Tab showing invitations I received
class _ReceivedInvitationsTab extends ConsumerWidget {
  const _ReceivedInvitationsTab();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsAsync = ref.watch(receivedInvitationsProvider);

    return invitationsAsync.when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('Error: $error')),
      data: (invitations) {
        if (invitations.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.inbox_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No received invitations', style: TextStyle(color: Colors.grey)),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: invitations.length,
          padding: const EdgeInsets.all(16),
          itemBuilder: (context, index) {
            final invitation = invitations[index];
            return _ReceivedInvitationCard(invitation: invitation);
          },
        );
      },
    );
  }
}

/// Card for sent invitation (shows receiver and status)
class _SentInvitationCard extends ConsumerWidget {
  final Invitation invitation;

  const _SentInvitationCard({required this.invitation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return FutureBuilder<AppUser?>(
      future: UsersService().getUserByUid(invitation.receiverId),
      builder: (context, snapshot) {
        final receiver = snapshot.data;
        final receiverName = receiver?.displayName ?? 'Loading...';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Text(
                receiverName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text('To: $receiverName'),
            subtitle: Text(_formatDate(invitation.createdAt)),
            trailing: _StatusChip(status: invitation.status),
          ),
        );
      },
    );
  }
}

/// Card for received invitation (shows sender and Accept/Reject buttons)
class _ReceivedInvitationCard extends ConsumerWidget {
  final Invitation invitation;

  const _ReceivedInvitationCard({required this.invitation});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invitationsService = ref.watch(invitationsServiceProvider);

    return FutureBuilder<AppUser?>(
      future: UsersService().getUserByUid(invitation.senderId),
      builder: (context, snapshot) {
        final sender = snapshot.data;
        final senderName = sender?.displayName ?? 'Loading...';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Text(
                senderName[0].toUpperCase(),
                style: const TextStyle(color: Colors.white),
              ),
            ),
            title: Text('From: $senderName'),
            subtitle: Text(_formatDate(invitation.createdAt)),
            trailing: invitation.isPending
                ? Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.check, color: Colors.green),
                        onPressed: () async {
                          await invitationsService.acceptInvitation(invitation.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invitation accepted!'),
                                backgroundColor: Colors.green,
                              ),
                            );
                          }
                        },
                        tooltip: 'Accept',
                      ),
                      IconButton(
                        icon: const Icon(Icons.close, color: Colors.red),
                        onPressed: () async {
                          await invitationsService.rejectInvitation(invitation.id);
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Invitation rejected'),
                                backgroundColor: Colors.red,
                              ),
                            );
                          }
                        },
                        tooltip: 'Reject',
                      ),
                    ],
                  )
                : _StatusChip(status: invitation.status),
          ),
        );
      },
    );
  }
}

/// Status chip (colored badge showing pending/accepted/rejected)
class _StatusChip extends StatelessWidget {
  final String status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    Color color;
    IconData icon;

    switch (status) {
      case 'accepted':
        color = Colors.green;
        icon = Icons.check_circle;
        break;
      case 'rejected':
        color = Colors.red;
        icon = Icons.cancel;
        break;
      default:
        color = Colors.orange;
        icon = Icons.schedule;
    }

    return Chip(
      avatar: Icon(icon, size: 16, color: color),
      label: Text(
        status.toUpperCase(),
        style: TextStyle(fontSize: 10, color: color, fontWeight: FontWeight.bold),
      ),
      backgroundColor: color.withOpacity(0.1),
      side: BorderSide(color: color),
    );
  }
}

/// Helper to format date
String _formatDate(DateTime date) {
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${date.day}/${date.month}/${date.year}';
}