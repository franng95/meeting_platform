// lib/features/meetings/meetings_screen.dart
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../models/meeting.dart';
import '../../models/app_user.dart';
import '../../services/users_service.dart';
import '../auth/auth_providers.dart';
import 'meetings_providers.dart';

class MeetingsScreen extends ConsumerWidget {
  const MeetingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final meetingsAsync = ref.watch(myMeetingsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Meetings'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        automaticallyImplyLeading: false, // Remove back button when in bottom nav
      ),
      body: meetingsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error, size: 64, color: Colors.red),
              const SizedBox(height: 16),
              Text('Error: $error'),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () => ref.refresh(myMeetingsProvider),
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
        data: (meetings) {
          if (meetings.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.calendar_today_outlined, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text(
                    'No meetings scheduled',
                    style: TextStyle(fontSize: 18, color: Colors.grey),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Accept an invitation to create a meeting',
                    style: TextStyle(fontSize: 14, color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.builder(
            itemCount: meetings.length,
            padding: const EdgeInsets.all(16),
            itemBuilder: (context, index) {
              final meeting = meetings[index];
              return _MeetingCard(meeting: meeting);
            },
          );
        },
      ),
    );
  }
}

/// Individual meeting card
class _MeetingCard extends ConsumerWidget {
  final Meeting meeting;

  const _MeetingCard({required this.meeting});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authService = ref.watch(authServiceProvider);
    final currentUserId = authService.currentUser?.uid;

    // Find the other participant (not me)
    final otherUserId = meeting.participants.firstWhere(
      (uid) => uid != currentUserId,
      orElse: () => meeting.participants.first,
    );

    return FutureBuilder<AppUser?>(
      future: UsersService().getUserByUid(otherUserId),
      builder: (context, snapshot) {
        final otherUser = snapshot.data;
        final otherUserName = otherUser?.displayName ?? 'Loading...';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.deepPurple,
              child: Icon(
                Icons.videocam,
                color: Colors.white,
              ),
            ),
            title: Text(
              'Meeting with $otherUserName',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.calendar_today, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('MMM dd, yyyy').format(meeting.scheduledFor),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    const Icon(Icons.access_time, size: 14, color: Colors.grey),
                    const SizedBox(width: 4),
                    Text(
                      DateFormat('h:mm a').format(meeting.scheduledFor),
                      style: const TextStyle(fontSize: 13),
                    ),
                  ],
                ),
              ],
            ),
            trailing: IconButton(
              icon: const Icon(Icons.edit, color: Colors.blue),
              onPressed: () => _showRescheduleDialog(context, ref),
              tooltip: 'Reschedule',
            ),
          ),
        );
      },
    );
  }

  Future<void> _showRescheduleDialog(BuildContext context, WidgetRef ref) async {
    final meetingsService = ref.read(meetingsServiceProvider);
    DateTime selectedDate = meeting.scheduledFor;
    TimeOfDay selectedTime = TimeOfDay.fromDateTime(meeting.scheduledFor);

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Reschedule Meeting'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.calendar_today),
              title: Text(DateFormat('MMM dd, yyyy').format(selectedDate)),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final date = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (date != null) {
                  selectedDate = DateTime(
                    date.year,
                    date.month,
                    date.day,
                    selectedTime.hour,
                    selectedTime.minute,
                  );
                }
              },
            ),
            ListTile(
              leading: const Icon(Icons.access_time),
              title: Text(selectedTime.format(context)),
              trailing: const Icon(Icons.edit),
              onTap: () async {
                final time = await showTimePicker(
                  context: context,
                  initialTime: selectedTime,
                );
                if (time != null) {
                  selectedTime = time;
                  selectedDate = DateTime(
                    selectedDate.year,
                    selectedDate.month,
                    selectedDate.day,
                    time.hour,
                    time.minute,
                  );
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
          ElevatedButton(
            onPressed: () async {
              try {
                await meetingsService.updateScheduledTime(meeting.id, selectedDate);
                if (context.mounted) {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Meeting rescheduled!'),
                      backgroundColor: Colors.green,
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
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }
}