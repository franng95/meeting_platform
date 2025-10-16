// lib/models/app_user.dart

/// Represents a user in our app
/// This is our own User model (not Firebase's User class)
class AppUser {
  final String uid;           // Unique ID from Firebase Auth
  final String email;         // User's email
  final String displayName;   // Name shown in UI
  final String? photoUrl;     // Optional profile picture
  final DateTime createdAt;   // When account was created

  AppUser({
    required this.uid,
    required this.email,
    required this.displayName,
    this.photoUrl,
    required this.createdAt,
  });

  // Convert Firestore document to AppUser object
  factory AppUser.fromJson(Map<String, dynamic> json) {
    return AppUser(
      uid: json['uid'] as String,
      email: json['email'] as String,
      displayName: json['displayName'] as String,
      photoUrl: json['photoUrl'] as String?,
      createdAt: DateTime.parse(json['createdAt'] as String),
    );
  }

  // Convert AppUser object to Firestore document
  Map<String, dynamic> toJson() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'photoUrl': photoUrl,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  @override
  String toString() => 'AppUser(uid: $uid, email: $email, name: $displayName)';
}