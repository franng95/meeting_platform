// lib/services/users_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/app_user.dart';

/// Service that handles user-related Firestore operations
class UsersService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Get all users from Firestore
  Future<List<AppUser>> getAllUsers() async {
    try {
      // Query the 'users' collection - get ALL documents
      final snapshot = await _firestore.collection('users').get();
      
      // Convert each document to an AppUser object
      final users = snapshot.docs.map((doc) {
        return AppUser.fromJson(doc.data());
      }).toList();
      
      debugPrint('✅ Loaded ${users.length} users from Firestore');
      return users;
    } catch (e) {
      debugPrint('❌ Error loading users: $e');
      return [];
    }
  }

/// Get users except the current user (for inviting)
  Future<List<AppUser>> getUsersExceptMe(String myUid) async {
    final allUsers = await getAllUsers();
    
    debugPrint('🔍 getAllUsers returned: ${allUsers.length} users');
    debugPrint('🔍 Filtering out user with UID: $myUid');
    
    // Filter out the current user
    final filtered = allUsers.where((user) {
      final shouldInclude = user.uid != myUid;
      debugPrint('   ${user.displayName} (${user.uid}): ${shouldInclude ? "INCLUDE" : "EXCLUDE"}');
      return shouldInclude;
    }).toList();
    
    debugPrint('✅ Filtered result: ${filtered.length} users');
    return filtered;
  }

  /// Get a specific user by UID
  Future<AppUser?> getUserByUid(String uid) async {
    try {
      final doc = await _firestore.collection('users').doc(uid).get();
      if (!doc.exists) return null;
      return AppUser.fromJson(doc.data()!);
    } catch (e) {
      debugPrint('❌ Error getting user $uid: $e');
      return null;
    }
  }
}