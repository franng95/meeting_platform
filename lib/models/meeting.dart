// lib/models/meeting.dart

/// Represents a scheduled meeting between two users
class Meeting {
  final String id;                    // Firestore document ID
  final List<String> participants;    // UIDs of both users
  final DateTime scheduledFor;        // When the meeting is scheduled
  final DateTime createdAt;           // When meeting was created
  final String? createdFromInvitation; // Optional: which invitation created this

  Meeting({
    required this.id,
    required this.participants,
    required this.scheduledFor,
    required this.createdAt,
    this.createdFromInvitation,
  });

  // Convert Firestore document to Meeting object
  factory Meeting.fromJson(Map<String, dynamic> json, String id) {
    return Meeting(
      id: id,
      participants: List<String>.from(json['participants'] as List),
      scheduledFor: DateTime.parse(json['scheduledFor'] is String 
          ? json['scheduledFor'] 
          : (json['scheduledFor'] as Map)['_seconds'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  (json['scheduledFor'] as Map)['_seconds'] * 1000)
                  .toIso8601String()
              : DateTime.now().toIso8601String()),
      createdAt: json['createdAt'] is String
          ? DateTime.parse(json['createdAt'])
          : DateTime.now(),
      createdFromInvitation: json['createdFromInvitation'] as String?,
    );
  }

  // Convert Meeting object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'participants': participants,
      'scheduledFor': scheduledFor.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      if (createdFromInvitation != null) 
        'createdFromInvitation': createdFromInvitation,
    };
  }

  @override
  String toString() => 'Meeting(id: $id, scheduledFor: $scheduledFor)';
}