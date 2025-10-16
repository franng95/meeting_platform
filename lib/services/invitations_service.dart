// lib/services/invitations_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/invitation.dart';

/// Service that handles invitation operations
class InvitationsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Send an invitation (create a new invitation document)
  Future<void> sendInvitation({
    required String senderId,
    required String receiverId,
    DateTime? scheduledFor,
  }) async {
    try {
      // Create new invitation document with scheduled time
      final invitationData = {
        'senderId': senderId,
        'receiverId': receiverId,
        'status': 'pending',
        'createdAt': DateTime.now().toIso8601String(),
      };
      
      // Add scheduledFor if provided
      if (scheduledFor != null) {
        invitationData['scheduledFor'] = scheduledFor.toIso8601String();
      }
      
      await _firestore.collection('invitations').add(invitationData);
      
      debugPrint('✅ Invitation sent from $senderId to $receiverId');
      if (scheduledFor != null) {
        debugPrint('   Scheduled for: $scheduledFor');
      }
    } catch (e) {
      debugPrint('❌ Error sending invitation: $e');
      rethrow;
    }
  }

  /// Get invitations sent by a user
  Stream<List<Invitation>> getSentInvitations(String userId) {
    return _firestore
        .collection('invitations')
        .where('senderId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Invitation.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Get invitations received by a user
  Stream<List<Invitation>> getReceivedInvitations(String userId) {
    return _firestore
        .collection('invitations')
        .where('receiverId', isEqualTo: userId)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      return snapshot.docs.map((doc) {
        return Invitation.fromJson(doc.data(), doc.id);
      }).toList();
    });
  }

  /// Accept an invitation
  Future<void> acceptInvitation(String invitationId) async {
    try {
      print('🔄 Attempting to accept invitation: $invitationId');
      
      await _firestore.collection('invitations').doc(invitationId).update({
        'status': 'accepted',
      });
      
      print('✅ Invitation $invitationId accepted in Firestore');
      debugPrint('✅ Invitation $invitationId accepted');
    } catch (e) {
      print('❌ Error accepting invitation: $e');
      debugPrint('❌ Error accepting invitation: $e');
      rethrow;
    }
  }

  /// Reject an invitation
  Future<void> rejectInvitation(String invitationId) async {
    try {
      await _firestore.collection('invitations').doc(invitationId).update({
        'status': 'rejected',
      });
      
      debugPrint('✅ Invitation $invitationId rejected');
    } catch (e) {
      debugPrint('❌ Error rejecting invitation: $e');
      rethrow;
    }
  }
}