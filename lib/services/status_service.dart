import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/status_model.dart';

class StatusService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'rag_status';

  // Create a new status entry
  Future<String> createStatus({
    required String userId,
    required String eventId,
    RAGStatus status = RAGStatus.pending,
    String? message,
  }) async {
    try {
      final docRef = await _firestore.collection(_collection).add({
        'userId': userId,
        'eventId': eventId,
        'status': status.name,
        'message': message,
        'createdAt': FieldValue.serverTimestamp(),
      });
      return docRef.id;
    } catch (e) {
      print('Error creating status: $e');
      rethrow;
    }
  }

  // Update status
  Future<void> updateStatus({
    required String id,
    required RAGStatus status,
    String? message,
    bool? completed,
  }) async {
    try {
      final updates = <String, dynamic>{
        'status': status.name,
        'message': message,
      };

      if (completed == true) {
        updates['completedAt'] = FieldValue.serverTimestamp();
      }

      await _firestore.collection(_collection).doc(id).update(updates);
    } catch (e) {
      print('Error updating status: $e');
      rethrow;
    }
  }

  // Get status by ID
  Future<StatusModel?> getStatusById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists) {
        return StatusModel.fromMap(id, doc.data()!);
      }
      return null;
    } catch (e) {
      print('Error getting status: $e');
      return null;
    }
  }

  // Get all statuses for an event
  Future<List<StatusModel>> getStatusesByEvent(String eventId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('eventId', isEqualTo: eventId)
          .get();

      return querySnapshot.docs
          .map((doc) => StatusModel.fromMap(doc.id, doc.data()!))
          .toList();
    } catch (e) {
      print('Error getting event statuses: $e');
      return [];
    }
  }

  // Get all statuses for a user
  Future<List<StatusModel>> getStatusesByUser(String userId) async {
    try {
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('userId', isEqualTo: userId)
          .get();

      return querySnapshot.docs
          .map((doc) => StatusModel.fromMap(doc.id, doc.data()!))
          .toList();
    } catch (e) {
      print('Error getting user statuses: $e');
      return [];
    }
  }
}
