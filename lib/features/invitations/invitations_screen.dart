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
          automaticallyImplyLeading: false,
          bottom: const TabBar(
            tabs: [
              Tab(icon: Icon(Icons.send), text: 'Sent'),
              Tab(icon: Icon(Icons.inbox), text: 'Received'),
            ],
          ),
        ),
        body: const Padding(
          padding: EdgeInsets.only(top: 8),
          child: TabBarView(
            children: [
              _SentInvitationsTab(),
              _ReceivedInvitationsTab(),
            ],
          ),
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
      error: (error, stack) => _ErrorView(
        message: 'Error loading sent invitations: $error',
        onRetry: () => ref.refresh(sentInvitationsProvider),
      ),
      data: (invitations) {
        if (invitations.isEmpty) {
          return const _EmptyView(
            icon: Icons.send_outlined,
            title: 'No sent invitations',
            subtitle: 'Invite someone from the Users tab to get started.',
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
      error: (error, stack) => _ErrorView(
        message: 'Error loading received invitations: $error',
        onRetry: () => ref.refresh(receivedInvitationsProvider),
      ),
      data: (invitations) {
        if (invitations.isEmpty) {
          return const _EmptyView(
            icon: Icons.inbox_outlined,
            title: 'No received invitations',
            subtitle: 'When someone invites you, it will appear here.',
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
        final receiverName = _safeName(receiver?.displayName);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            leading: _GradientAvatar(letter: receiverName),
            title: Text(
              'To: ${receiverName.isEmpty ? "Loading..." : receiverName}',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
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
        final senderName = _safeName(sender?.displayName);

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
              leading: _GradientAvatar(letter: senderName),
              title: Text(
                'From: ${senderName.isEmpty ? "Loading..." : senderName}',
                style: const TextStyle(fontWeight: FontWeight.w600),
              ),
              subtitle: Text(_formatDate(invitation.createdAt)),
              trailing: invitation.isPending
                  ? Wrap(
                      spacing: 8,
                      children: [
                        FilledButton.icon(
                          icon: const Icon(Icons.check, size: 18),
                          label: const Text('Accept'),
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
                        ),
                        OutlinedButton.icon(
                          icon: const Icon(Icons.close, size: 18),
                          label: const Text('Reject'),
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
                        ),
                      ],
                    )
                  : _StatusChip(status: invitation.status),
            ),
          ),
        );
      },
    );
  }
}

class _GradientAvatar extends StatelessWidget {
  final String letter;
  const _GradientAvatar({required this.letter});

  @override
  Widget build(BuildContext context) {
    final safe = letter.isNotEmpty ? letter[0].toUpperCase() : '?';
    return CircleAvatar(
      backgroundColor: Colors.transparent,
      radius: 22,
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [
              Theme.of(context).colorScheme.primary,
              Theme.of(context).colorScheme.secondary,
            ],
          ),
        ),
        child: Center(
          child: Text(
            safe,
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      ),
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
      backgroundColor: color.withOpacity(0.08),
      side: BorderSide(color: color.withOpacity(0.6)),
    );
  }
}

String _safeName(String? name) {
  final trimmed = (name ?? '').trim();
  return trimmed;
}

/// Helper to format date safely
String _formatDate(DateTime? date) {
  if (date == null) return '—';
  final now = DateTime.now();
  final diff = now.difference(date);

  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return '${date.day}/${date.month}/${date.year}';
}

class _EmptyView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  const _EmptyView({
    required this.icon,
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 64, color: cs.outline),
          const SizedBox(height: 16),
          Text(title, style: TextStyle(fontSize: 18, color: cs.onSurface)),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: TextStyle(fontSize: 14, color: cs.onSurfaceVariant),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 56),
            const SizedBox(height: 12),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}
