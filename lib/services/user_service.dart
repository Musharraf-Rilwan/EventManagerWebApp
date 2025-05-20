import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/user_model.dart';

class UserService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'users';

  UserService() {
    _initializeFirestore();
  }

  Future<void> _initializeFirestore() async {
    try {
      await _firestore.enableNetwork();
    } catch (e) {
      debugPrint('Error enabling network: $e');
      // If network enable fails, try to use cached data
      try {
        await _firestore.disableNetwork();
      } catch (e) {
        debugPrint('Error disabling network: $e');
      }
    }
  }

  // Get user by ID
  Future<UserModel?> getUser(String userId) async {
    try {
      final doc = await _firestore.collection(_collection).doc(userId).get();
      if (!doc.exists) return null;
      return UserModel.fromMap(doc.id, doc.data()!);
    } catch (e) {
      debugPrint('Error getting user: $e');
      return null;
    }
  }

  // Create a new user document in Firestore
  Future<void> createUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.uid).set(user.toMap());
    } catch (e) {
      debugPrint('Error creating user: $e');
      rethrow;
    }
  }

  // Update last login
  Future<void> updateLastLogin(String userId) async {
    try {
      await _firestore.collection(_collection).doc(userId).update({
        'lastLogin': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating last login: $e');
    }
  }

  // Get all users
  Future<List<UserModel>> getAllUsers() async {
    try {
      final querySnapshot = await _firestore.collection(_collection).get();
      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting all users: $e');
      rethrow;
    }
  }

  // Delete user
  Future<void> deleteUser(String userId) async {
    try {
      // Delete user document
      await _firestore.collection(_collection).doc(userId).delete();
      
      // Delete user's events
      final eventDocs = await _firestore.collection('events')
          .where('createdBy', isEqualTo: userId)
          .get();
      
      for (var doc in eventDocs.docs) {
        await doc.reference.delete();
      }
      
      // Remove user from event attendees
      final allEvents = await _firestore.collection('events').get();
      for (var doc in allEvents.docs) {
        final attendees = List<String>.from(doc.data()['attendees'] ?? []);
        if (attendees.contains(userId)) {
          await doc.reference.update({
            'attendees': FieldValue.arrayRemove([userId]),
          });
        }
      }
    } catch (e) {
      debugPrint('Error deleting user: $e');
      rethrow;
    }
  }

  // Update user
  Future<void> updateUser(UserModel user) async {
    try {
      await _firestore.collection(_collection).doc(user.uid).update(user.toMap());
    } catch (e) {
      debugPrint('Error updating user: $e');
      rethrow;
    }
  }

  // Update user role
  Future<void> updateUserRole(String uid, UserRole newRole, {String? requestedByUid}) async {
    try {
      debugPrint('Attempting to update user $uid to role: ${newRole.name}');
      
      // First check if the requesting user has permission
      if (requestedByUid != null) {
        final requestingUser = await getUser(requestedByUid);
        if (requestingUser == null || requestingUser.role != UserRole.admin) {
          debugPrint('Permission denied: User ${requestedByUid} is not admin');
          throw Exception('Only admins can change user roles');
        }
        debugPrint('Permission granted: User ${requestedByUid} is admin');
      } else {
        throw Exception('Role changes must be authorized by an admin');
      }

      // Get current user data
      final userDoc = await _firestore.collection(_collection).doc(uid).get();
      if (!userDoc.exists) {
        debugPrint('User document not found: $uid');
        throw Exception('User not found');
      }

      // Update the role
      await _firestore.collection(_collection).doc(uid).update({
        'role': newRole.name, // Use name property instead of enum toString()
        'lastUpdated': FieldValue.serverTimestamp(),
      });
      
      debugPrint('Successfully updated user $uid role to: ${newRole.name}');
    } catch (e) {
      debugPrint('Error updating user role: $e');
      throw Exception('Failed to update user role. Please check your permissions and try again.');
    }
  }

  // Update user profile
  Future<void> updateUserProfile(String uid, Map<String, dynamic> updates) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        ...updates,
        'lastUpdated': FieldValue.serverTimestamp(),
      });
    } catch (e) {
      debugPrint('Error updating user profile: $e');
      throw Exception('Failed to update user profile. Please try again.');
    }
  }

  // Add event to user's managed events
  Future<void> addManagedEvent(String uid, String eventId) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'managedEvents': FieldValue.arrayUnion([eventId]),
      });
    } catch (e) {
      debugPrint('Error adding managed event: $e');
      throw Exception('Failed to add managed event. Please check your internet connection and try again.');
    }
  }

  // Add event to user's attending events
  Future<void> addAttendingEvent(String uid, String eventId) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'attendingEvents': FieldValue.arrayUnion([eventId]),
      });
    } catch (e) {
      debugPrint('Error adding attending event: $e');
      throw Exception('Failed to add attending event. Please check your internet connection and try again.');
    }
  }

  // Remove event from user's managed events
  Future<void> removeManagedEvent(String uid, String eventId) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'managedEvents': FieldValue.arrayRemove([eventId]),
      });
    } catch (e) {
      debugPrint('Error removing managed event: $e');
      throw Exception('Failed to remove managed event. Please check your internet connection and try again.');
    }
  }

  // Remove event from user's attending events
  Future<void> removeAttendingEvent(String uid, String eventId) async {
    try {
      await _firestore.collection(_collection).doc(uid).update({
        'attendingEvents': FieldValue.arrayRemove([eventId]),
      });
    } catch (e) {
      debugPrint('Error removing attending event: $e');
      throw Exception('Failed to remove attending event. Please check your internet connection and try again.');
    }
  }

  // Get all organizers
  Future<List<UserModel>> getAllOrganizers() async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('role', isEqualTo: UserRole.organizer.toString().split('.').last)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting organizers: $e');
      return []; // Return empty list if offline
    }
  }

  // Get all attendees for an event
  Future<List<UserModel>> getEventAttendees(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('attendingEvents', arrayContains: eventId)
          .get();

      return querySnapshot.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList();
    } catch (e) {
      debugPrint('Error getting event attendees: $e');
      return []; // Return empty list if offline
    }
  }
}
