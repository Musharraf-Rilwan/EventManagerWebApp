import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/ticket_model.dart';
import '../models/event_model.dart';

class TicketService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  Future<TicketModel> purchaseTickets(
    EventModel event,
    String userId,
    String userEmail,
    String userName,
    int quantity,
  ) async {
    try {
      // Get user's display name from profile first
      final userDoc = await _firestore.collection('users').doc(userId).get();
      final displayName = userDoc.exists 
          ? userDoc.data()!['displayName'] ?? userName
          : userName;

      // Create a batch
      final batch = _firestore.batch();
      final eventRef = _firestore.collection('events').doc(event.id);

      // Update ticket quantity
      if (event.ticketInfo != null) {
        final ticketInfo = event.ticketInfo!;
        if (ticketInfo.availableQuantity < quantity) {
          throw Exception('Not enough tickets available');
        }

        batch.update(eventRef, {
          'ticketInfo.availableQuantity': ticketInfo.availableQuantity - quantity,
          'lastUpdated': FieldValue.serverTimestamp(),
        });
      }

      // Calculate total price
      final pricePerTicket = event.ticketInfo?.price ?? 0.0;
      final totalPrice = pricePerTicket * quantity;

      // Create ticket document
      final ticketRef = _firestore.collection('tickets').doc();
      final ticketModel = TicketModel(
        id: ticketRef.id,
        eventId: event.id,
        userId: userId,
        userEmail: userEmail,
        userName: displayName,
        quantity: quantity,
        totalPrice: totalPrice,
        purchaseDate: DateTime.now().toUtc(),
        eventTitle: event.title,
        eventDate: event.date,
        eventLocation: event.location,
      );

      batch.set(ticketRef, ticketModel.toMap());

      // Commit the batch
      await batch.commit();

      return ticketModel;
    } catch (e) {
      print('Error purchasing tickets: $e');
      rethrow;
    }
  }

  Future<List<TicketModel>> getUserTickets(String userId) async {
    final querySnapshot = await _firestore
        .collection('tickets')
        .where('userId', isEqualTo: userId)
        .orderBy('purchaseDate', descending: true)
        .get();

    return querySnapshot.docs
        .map((doc) => TicketModel.fromMap(doc.id, doc.data()))
        .toList();
  }

  Future<TicketModel?> getTicket(String ticketId) async {
    final doc = await _firestore.collection('tickets').doc(ticketId).get();
    if (!doc.exists) return null;
    return TicketModel.fromMap(doc.id, doc.data()!);
  }
}
