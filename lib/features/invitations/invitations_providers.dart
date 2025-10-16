// lib/features/invitations/invitations_providers.dart
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../services/invitations_service.dart';
import '../../models/invitation.dart';
import '../auth/auth_providers.dart';

/// Provider for InvitationsService
final invitationsServiceProvider = Provider<InvitationsService>((ref) {
  return InvitationsService();
});

/// Provider for sent invitations (Stream)
final sentInvitationsProvider = StreamProvider<List<Invitation>>((ref) {
  final invitationsService = ref.watch(invitationsServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final currentUser = authService.currentUser;
  
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  return invitationsService.getSentInvitations(currentUser.uid);
});

/// Provider for received invitations (Stream)
final receivedInvitationsProvider = StreamProvider<List<Invitation>>((ref) {
  final invitationsService = ref.watch(invitationsServiceProvider);
  final authService = ref.watch(authServiceProvider);
  final currentUser = authService.currentUser;
  
  if (currentUser == null) {
    return Stream.value([]);
  }
  
  return invitationsService.getReceivedInvitations(currentUser.uid);
});