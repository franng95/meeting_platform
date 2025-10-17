// lib/features/invitations/invitations_providers.dart
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../models/invitation.dart';
import '../../services/invitations_service.dart';

/// Stream of the current user's uid (null if signed out).
final authUidProvider = StreamProvider<String?>(
  (ref) => FirebaseAuth.instance.authStateChanges().map((u) => u?.uid),
);

/// Provider for InvitationsService
final invitationsServiceProvider = Provider<InvitationsService>((ref) {
  return InvitationsService();
});

/// Provider for sent invitations (Stream), scoped to the active uid.
/// Sent = where('senderId' == uid)
final sentInvitationsProvider = StreamProvider<List<Invitation>>((ref) {
  final uidAsync = ref.watch(authUidProvider);
  final service = ref.watch(invitationsServiceProvider);

  return uidAsync.when(
    data: (uid) {
      if (uid == null) return Stream.value(const <Invitation>[]);
      return service.getSentInvitations(uid);
    },
    loading: () => Stream.value(const <Invitation>[]),
    error: (_, __) => Stream.value(const <Invitation>[]),
  );
});

/// Provider for received invitations (Stream), scoped to the active uid.
/// Received = where('receiverId' == uid)
final receivedInvitationsProvider = StreamProvider<List<Invitation>>((ref) {
  final uidAsync = ref.watch(authUidProvider);
  final service = ref.watch(invitationsServiceProvider);

  return uidAsync.when(
    data: (uid) {
      if (uid == null) return Stream.value(const <Invitation>[]);
      return service.getReceivedInvitations(uid);
    },
    loading: () => Stream.value(const <Invitation>[]),
    error: (_, __) => Stream.value(const <Invitation>[]),
  );
});
