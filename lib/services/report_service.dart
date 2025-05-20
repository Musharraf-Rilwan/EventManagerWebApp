import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/report_model.dart';
import '../models/event_model.dart';
import '../models/user_model.dart';
import 'package:intl/intl.dart';
import 'dart:convert';

class ReportService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'reports';

  Future<String> createReport(ReportModel report) async {
    try {
      final docRef = await _firestore.collection(_collection).add(report.toMap());
      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create report: $e');
    }
  }

  Future<List<ReportModel>> getAllReports() async {
    try {
      final querySnapshot = await _firestore.collection(_collection)
          .orderBy('createdAt', descending: true)
          .get();
      
      return querySnapshot.docs
          .map((doc) => ReportModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw Exception('Failed to get reports: $e');
    }
  }

  Future<void> deleteReport(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      throw Exception('Failed to delete report: $e');
    }
  }

  Future<Map<String, dynamic>> generateEventAttendanceReport(DateTime startDate, DateTime endDate) async {
    try {
      final events = await _firestore.collection('events')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      final eventsList = events.docs
          .map((doc) => EventModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      int totalEvents = eventsList.length;
      int totalAttendees = eventsList.fold(0, (sum, event) => sum + event.attendees.length);
      double averageAttendance = totalEvents > 0 ? totalAttendees / totalEvents : 0;

      Map<String, int> attendanceByDay = {};
      for (var event in eventsList) {
        String day = DateFormat('yyyy-MM-dd').format(event.date);
        attendanceByDay[day] = (attendanceByDay[day] ?? 0) + event.attendees.length;
      }

      return {
        'totalEvents': totalEvents,
        'totalAttendees': totalAttendees,
        'averageAttendance': averageAttendance,
        'attendanceByDay': attendanceByDay,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      throw Exception('Failed to generate event attendance report: $e');
    }
  }

  Future<Map<String, dynamic>> generateUserActivityReport(DateTime startDate, DateTime endDate) async {
    try {
      final users = await _firestore.collection('users')
          .where('createdAt', isGreaterThanOrEqualTo: startDate)
          .where('createdAt', isLessThanOrEqualTo: endDate)
          .get();

      final usersList = users.docs
          .map((doc) => UserModel.fromMap(doc.id, doc.data()))
          .toList();

      Map<UserRole, int> usersByRole = {};
      for (var user in usersList) {
        usersByRole[user.role] = (usersByRole[user.role] ?? 0) + 1;
      }

      Map<String, int> registrationsByDay = {};
      for (var user in usersList) {
        String day = DateFormat('yyyy-MM-dd').format(user.createdAt);
        registrationsByDay[day] = (registrationsByDay[day] ?? 0) + 1;
      }

      return {
        'totalUsers': usersList.length,
        'usersByRole': usersByRole,
        'registrationsByDay': registrationsByDay,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      throw Exception('Failed to generate user activity report: $e');
    }
  }

  Future<Map<String, dynamic>> generateEventLocationReport(DateTime startDate, DateTime endDate) async {
    try {
      final events = await _firestore.collection('events')
          .where('date', isGreaterThanOrEqualTo: startDate)
          .where('date', isLessThanOrEqualTo: endDate)
          .get();

      final eventsList = events.docs
          .map((doc) => EventModel.fromMap(doc.id, doc.data() as Map<String, dynamic>))
          .toList();

      Map<String, int> eventsByLocation = {};
      Map<String, int> attendeesByLocation = {};

      for (var event in eventsList) {
        eventsByLocation[event.location] = (eventsByLocation[event.location] ?? 0) + 1;
        attendeesByLocation[event.location] = (attendeesByLocation[event.location] ?? 0) + event.attendees.length;
      }

      return {
        'eventsByLocation': eventsByLocation,
        'attendeesByLocation': attendeesByLocation,
        'startDate': startDate,
        'endDate': endDate,
      };
    } catch (e) {
      throw Exception('Failed to generate event location report: $e');
    }
  }

  Future<String> generateReportCsv(Map<String, dynamic> data) async {
    try {
      StringBuffer csv = StringBuffer();
      
      // Add headers
      csv.writeln(data.keys.join(','));
      
      // Add values
      csv.writeln(data.values.map((value) {
        if (value is Map || value is List) {
          return '"${jsonEncode(value)}"';
        }
        return value.toString();
      }).join(','));

      return csv.toString();
    } catch (e) {
      throw Exception('Failed to generate CSV: $e');
    }
  }

  Future<void> scheduleReport(String reportId, String frequency) async {
    try {
      await _firestore.collection(_collection).doc(reportId).update({
        'isScheduled': true,
        'scheduleFrequency': frequency,
      });
    } catch (e) {
      throw Exception('Failed to schedule report: $e');
    }
  }

  Future<void> unscheduleReport(String reportId) async {
    try {
      await _firestore.collection(_collection).doc(reportId).update({
        'isScheduled': false,
        'scheduleFrequency': null,
      });
    } catch (e) {
      throw Exception('Failed to unschedule report: $e');
    }
  }
}
