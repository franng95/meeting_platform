// lib/services/meetings_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/meeting.dart';

/// Service that handles meeting operations
class MeetingsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

/// Get all meetings where the user is a participant
  Stream<List<Meeting>> getMyMeetings(String userId) {
    print('🔍 Fetching meetings for user: $userId');
    
    return _firestore
        .collection('meetings')
        .where('participants', arrayContains: userId)
        .orderBy('scheduledFor')
        .snapshots()
        .map((snapshot) {
      print('📊 Found ${snapshot.docs.length} meetings');
      
      return snapshot.docs.map((doc) {
        print('   Meeting doc: ${doc.id}');
        print('   Data: ${doc.data()}');
        
        try {
          return Meeting.fromJson(doc.data(), doc.id);
        } catch (e) {
          debugPrint('❌ Error parsing meeting ${doc.id}: $e');
          debugPrint('   Data: ${doc.data()}');
          rethrow;
        }
      }).toList();
    });
  }

  /// Update meeting scheduled time
  Future<void> updateScheduledTime(String meetingId, DateTime newTime) async {
    try {
      await _firestore.collection('meetings').doc(meetingId).update({
        'scheduledFor': newTime.toIso8601String(),
      });
      debugPrint('✅ Meeting $meetingId rescheduled to $newTime');
    } catch (e) {
      debugPrint('❌ Error updating meeting: $e');
      rethrow;
    }
  }
}