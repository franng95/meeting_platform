// lib/features/meetings/meetings_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/meetings_service.dart';
import '../../models/meeting.dart';
import '../auth/auth_providers.dart';

/// Provider for MeetingsService
final meetingsServiceProvider = Provider<MeetingsService>((ref) {
  return MeetingsService();
});

/// Provider that streams meetings for the current user
final myMeetingsProvider = StreamProvider<List<Meeting>>((ref) {
  final meetingsService = ref.watch(meetingsServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final currentUser = authService.currentUser;
  
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  return meetingsService.getMyMeetings(currentUser.uid);
});