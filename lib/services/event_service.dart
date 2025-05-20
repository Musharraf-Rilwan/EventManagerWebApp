import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/event_model.dart';
import '../models/attendee_model.dart';

class EventService extends ChangeNotifier {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'events';

  // Create a new event
  Future<void> createEvent(EventModel event) async {
    try {
      print('Creating event with date: ${event.date}');
      final docRef = await _firestore.collection(_collection).add({
        'title': event.title,
        'description': event.description,
        'location': event.location,
        'date': Timestamp.fromDate(event.date),
        'time': '${event.time.hour}:${event.time.minute}',
        'type': event.type,
        'createdBy': event.createdBy,
        'attendees': event.attendees ?? [],
        if (event.ticketInfo != null) 'ticketInfo': event.ticketInfo!.toMap(),
      });
      print('Created event with ID: ${docRef.id}');
    } catch (e) {
      print('Error creating event: $e');
      throw Exception('Failed to create event: $e');
    }
  }

  // Get event by ID
  Future<EventModel?> getEventById(String id) async {
    try {
      final doc = await _firestore.collection(_collection).doc(id).get();
      if (doc.exists && doc.data() != null) {
        return EventModel.fromMap(doc.id, doc.data()!);
      }
      return null;
    } catch (e) {
      debugPrint('Error getting event: $e');
      throw Exception('Failed to get event. Please try again.');
    }
  }

  // Get all events
  Future<List<EventModel>> getAllEvents() async {
    try {
      print('Getting all events');
      final querySnapshot = await _firestore.collection(_collection).get();
      print('Found ${querySnapshot.docs.length} events');
      
      final events = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('Event data: $data');
        return EventModel.fromMap(doc.id, data);
      }).toList();

      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    } catch (e) {
      print('Error getting all events: $e');
      throw Exception('Failed to get events: $e');
    }
  }

  // Get events by creator
  Future<List<EventModel>> getEventsByCreator(String creatorId) async {
    try {
      print('Getting events for creator: $creatorId');
      final querySnapshot = await _firestore
          .collection(_collection)
          .where('createdBy', isEqualTo: creatorId)
          .get();
      
      print('Found ${querySnapshot.docs.length} events for creator');
      final events = querySnapshot.docs.map((doc) {
        final data = doc.data();
        print('Event data: $data');
        return EventModel.fromMap(doc.id, data);
      }).toList();

      events.sort((a, b) => a.date.compareTo(b.date));
      return events;
    } catch (e) {
      print('Error getting events by creator: $e');
      throw Exception('Failed to get events: $e');
    }
  }

  // Get upcoming events
  Future<List<EventModel>> getUpcomingEvents() async {
    try {
      final now = DateTime.now();
      final events = await getAllEvents();
      
      return events.where((e) => e.date.isAfter(now)).toList();
    } catch (e) {
      debugPrint('Error getting upcoming events: $e');
      throw Exception('Failed to get upcoming events. Please try again.');
    }
  }

  // Update event
  Future<void> updateEvent(String eventId, EventModel event) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'title': event.title,
        'description': event.description,
        'location': event.location,
        'date': Timestamp.fromDate(event.date),
        'time': '${event.time.hour}:${event.time.minute}',
        'type': event.type,
        if (event.ticketInfo != null) 'ticketInfo': event.ticketInfo!.toMap(),
      });
    } catch (e) {
      print('Error updating event: $e');
      throw Exception('Failed to update event: $e');
    }
  }

  // Delete event
  Future<void> deleteEvent(String eventId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).delete();
    } catch (e) {
      print('Error deleting event: $e');
      throw Exception('Failed to delete event: $e');
    }
  }

  // Add attendee to event
  Future<void> addAttendee(String eventId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'attendees': FieldValue.arrayUnion([userId]),
      });
    } catch (e) {
      debugPrint('Error adding attendee: $e');
      throw Exception('Failed to add attendee. Please try again.');
    }
  }

  // Remove attendee from event
  Future<void> removeAttendee(String eventId, String userId) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'attendees': FieldValue.arrayRemove([userId]),
      });
    } catch (e) {
      debugPrint('Error removing attendee: $e');
      throw Exception('Failed to remove attendee. Please try again.');
    }
  }

  // Register attendee for event
  Future<void> registerAttendee(String eventId, AttendeeModel attendee) async {
    try {
      // Get user's display name from profile first
      final userDoc = await _firestore.collection('users').doc(attendee.id).get();
      final displayName = userDoc.exists 
          ? userDoc.data()!['displayName'] ?? 'Anonymous'
          : 'Anonymous';

      // Get the event document
      final eventDoc = await _firestore.collection(_collection).doc(eventId).get();
      if (!eventDoc.exists) {
        throw Exception('Event not found');
      }

      final eventData = eventDoc.data() as Map<String, dynamic>;
      final List<dynamic> attendees = eventData['attendees'] ?? [];
      final List<dynamic> attendeeDetails = eventData['attendeeDetails'] ?? [];

      if (attendees.contains(attendee.id)) {
        throw Exception('Already registered for this event');
      }

      // Create a batch
      final batch = _firestore.batch();
      final eventRef = _firestore.collection(_collection).doc(eventId);

      // Update ticket quantity if this is a ticketed event
      if (eventData.containsKey('ticketInfo')) {
        final ticketInfo = eventData['ticketInfo'] as Map<String, dynamic>;
        if (ticketInfo['isEnabled'] == true) {
          final availableQuantity = ticketInfo['availableQuantity'] as int;
          if (availableQuantity <= 0) {
            throw Exception('No tickets available');
          }
          ticketInfo['availableQuantity'] = availableQuantity - 1;
          batch.update(eventRef, {'ticketInfo': ticketInfo});
        }
      }

      // Add attendee details
      final attendeeDetail = {
        'id': attendee.id,
        'name': displayName,
        'email': attendee.email,
        'phoneNumber': attendee.phoneNumber,
        'registrationDate': DateTime.now().toUtc().toIso8601String(),
      };

      batch.update(eventRef, {
        'attendees': [...attendees, attendee.id],
        'attendeeDetails': [...attendeeDetails, attendeeDetail],
        'lastUpdated': FieldValue.serverTimestamp(),
      });

      // Commit the batch
      await batch.commit();
    } catch (e) {
      print('Error registering attendee: $e');
      rethrow;
    }
  }

  // Unregister attendee from event
  Future<void> unregisterAttendee(String eventId, String userId) async {
    try {
      await _firestore.runTransaction((transaction) async {
        final eventDoc = await transaction.get(_firestore.collection(_collection).doc(eventId));
        
        if (!eventDoc.exists) {
          throw Exception('Event not found');
        }

        final eventData = eventDoc.data() as Map<String, dynamic>;
        final List<dynamic> attendees = eventData['attendees'] ?? [];
        final List<dynamic> attendeeDetails = eventData['attendeeDetails'] ?? [];
        
        // Check if user is registered
        if (!attendees.contains(userId)) {
          throw Exception('You are not registered for this event');
        }

        // Find and remove attendee details
        final attendeeToRemove = attendeeDetails.firstWhere(
          (details) => details['id'] == userId,
          orElse: () => null,
        );

        // Update ticket quantity if it's a ticketed event
        if (eventData.containsKey('ticketInfo')) {
          final ticketInfo = eventData['ticketInfo'] as Map<String, dynamic>;
          if (ticketInfo['isEnabled'] == true) {
            final availableQuantity = ticketInfo['availableQuantity'] as int;
            transaction.update(
              eventDoc.reference,
              {
                'ticketInfo.availableQuantity': availableQuantity + 1,
                'attendees': FieldValue.arrayRemove([userId]),
                if (attendeeToRemove != null)
                  'attendeeDetails': FieldValue.arrayRemove([attendeeToRemove]),
              },
            );
          }
        } else {
          // For non-ticketed events
          transaction.update(
            eventDoc.reference,
            {
              'attendees': FieldValue.arrayRemove([userId]),
              if (attendeeToRemove != null)
                'attendeeDetails': FieldValue.arrayRemove([attendeeToRemove]),
            },
          );
        }
      });
    } catch (e) {
      print('Error unregistering attendee: $e');
      throw Exception('Failed to unregister from event: $e');
    }
  }

  // Update ticket info
  Future<void> updateTicketInfo(String eventId, TicketInfo ticketInfo) async {
    try {
      await _firestore.collection(_collection).doc(eventId).update({
        'ticketInfo': ticketInfo.toMap(),
      });
    } catch (e) {
      print('Error updating ticket info: $e');
      throw Exception('Failed to update ticket information: $e');
    }
  }

  // Get events statistics
  Future<Map<String, dynamic>> getEventsStatistics() async {
    try {
      final now = DateTime.now();
      final events = await getAllEvents();
      
      return {
        'totalEvents': events.length,
        'upcomingEvents': events.where((e) => e.date.isAfter(now)).length,
        'todayEvents': events.where((e) => 
          e.date.year == now.year && 
          e.date.month == now.month && 
          e.date.day == now.day
        ).length,
        'totalAttendees': events.fold(0, (sum, e) => sum + e.attendees.length),
      };
    } catch (e) {
      debugPrint('Error getting event statistics: $e');
      throw Exception('Failed to get event statistics. Please try again.');
    }
  }
}
