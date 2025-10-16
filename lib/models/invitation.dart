// lib/models/invitation.dart

/// Represents a meeting invitation
class Invitation {
  final String id;              // Firestore document ID
  final String senderId;        // UID of person who sent invite
  final String receiverId;      // UID of person receiving invite
  final String status;          // "pending" | "accepted" | "rejected"
  final DateTime createdAt;     // When invitation was created
  final DateTime? scheduledFor; // When meeting is scheduled for

  Invitation({
    required this.id,
    required this.senderId,
    required this.receiverId,
    required this.status,
    required this.createdAt,
    this.scheduledFor,
  });

  // Convert Firestore document to Invitation object
  factory Invitation.fromJson(Map<String, dynamic> json, String id) {
    return Invitation(
      id: id,
      senderId: json['senderId'] as String,
      receiverId: json['receiverId'] as String,
      status: json['status'] as String,
      createdAt: DateTime.parse(json['createdAt'] as String),
      scheduledFor: json['scheduledFor'] != null
          ? DateTime.parse(json['scheduledFor'] as String)
          : null,
    );
  }

  // Convert Invitation object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'senderId': senderId,
      'receiverId': receiverId,
      'status': status,
      'createdAt': createdAt.toIso8601String(),
      if (scheduledFor != null) 'scheduledFor': scheduledFor!.toIso8601String(),
    };
  }

  // Check invitation status
  bool get isPending => status == 'pending';
  bool get isAccepted => status == 'accepted';
  bool get isRejected => status == 'rejected';

  @override
  String toString() => 'Invitation(id: $id, status: $status)';
}