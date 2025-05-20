import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class TicketInfo {
  final double price;
  final int totalQuantity;
  final int availableQuantity;
  final bool isEnabled;

  TicketInfo({
    required this.price,
    required this.totalQuantity,
    required this.availableQuantity,
    this.isEnabled = true,
  });

  factory TicketInfo.fromMap(Map<String, dynamic> map) {
    return TicketInfo(
      price: (map['price'] as num).toDouble(),
      totalQuantity: map['totalQuantity'] as int,
      availableQuantity: map['availableQuantity'] as int,
      isEnabled: map['isEnabled'] as bool? ?? true,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'price': price,
      'totalQuantity': totalQuantity,
      'availableQuantity': availableQuantity,
      'isEnabled': isEnabled,
    };
  }

  TicketInfo copyWith({
    double? price,
    int? totalQuantity,
    int? availableQuantity,
    bool? isEnabled,
  }) {
    return TicketInfo(
      price: price ?? this.price,
      totalQuantity: totalQuantity ?? this.totalQuantity,
      availableQuantity: availableQuantity ?? this.availableQuantity,
      isEnabled: isEnabled ?? this.isEnabled,
    );
  }
}

class EventModel {
  final String id;
  final String title;
  final String description;
  final String location;
  final DateTime date;
  final TimeOfDay time;
  final String type;
  final String createdBy;
  final List<String> attendees;
  final TicketInfo? ticketInfo;

  EventModel({
    required this.id,
    required this.title,
    required this.description,
    required this.location,
    required this.date,
    required this.time,
    required this.type,
    required this.createdBy,
    List<String>? attendees,
    this.ticketInfo,
  }) : attendees = attendees ?? [];

  factory EventModel.fromMap(String id, Map<String, dynamic> map) {
    // Handle date
    DateTime date;
    if (map['date'] is Timestamp) {
      date = (map['date'] as Timestamp).toDate();
    } else if (map['date'] is DateTime) {
      date = map['date'] as DateTime;
    } else {
      print('Invalid date format in Firestore: ${map['date']}');
      date = DateTime.now(); // Fallback
    }

    // Handle time
    TimeOfDay time;
    try {
      if (map['time'] is String) {
        final timeStr = map['time'] as String;
        final timeParts = timeStr.split(':');
        time = TimeOfDay(
          hour: int.parse(timeParts[0]),
          minute: int.parse(timeParts[1]),
        );
      } else if (map['time'] is Map) {
        final timeMap = map['time'] as Map<String, dynamic>;
        time = TimeOfDay(
          hour: timeMap['hour'] as int,
          minute: timeMap['minute'] as int,
        );
      } else {
        print('Invalid time format in Firestore: ${map['time']}');
        time = TimeOfDay.now(); // Fallback
      }
    } catch (e) {
      print('Error parsing time: $e');
      time = TimeOfDay.now(); // Fallback
    }

    // Handle attendees
    List<String> attendees = [];
    if (map['attendees'] != null) {
      if (map['attendees'] is List) {
        attendees = List<String>.from(map['attendees']);
      } else {
        print('Invalid attendees format in Firestore: ${map['attendees']}');
      }
    }

    // Handle ticket info
    TicketInfo? ticketInfo;
    if (map['ticketInfo'] != null) {
      try {
        ticketInfo = TicketInfo.fromMap(Map<String, dynamic>.from(map['ticketInfo']));
      } catch (e) {
        print('Error parsing ticket info: $e');
      }
    }

    return EventModel(
      id: id,
      title: map['title'] ?? '',
      description: map['description'] ?? '',
      location: map['location'] ?? '',
      date: date,
      time: time,
      type: map['type'] ?? 'Other',
      createdBy: map['createdBy'] ?? '',
      attendees: attendees,
      ticketInfo: ticketInfo,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'description': description,
      'location': location,
      'date': Timestamp.fromDate(date),
      'time': '${time.hour}:${time.minute}',
      'type': type,
      'createdBy': createdBy,
      'attendees': attendees,
      if (ticketInfo != null) 'ticketInfo': ticketInfo!.toMap(),
    };
  }

  EventModel copyWith({
    String? id,
    String? title,
    String? description,
    String? location,
    DateTime? date,
    TimeOfDay? time,
    String? type,
    String? createdBy,
    List<String>? attendees,
    TicketInfo? ticketInfo,
  }) {
    return EventModel(
      id: id ?? this.id,
      title: title ?? this.title,
      description: description ?? this.description,
      location: location ?? this.location,
      date: date ?? this.date,
      time: time ?? this.time,
      type: type ?? this.type,
      createdBy: createdBy ?? this.createdBy,
      attendees: attendees ?? this.attendees,
      ticketInfo: ticketInfo ?? this.ticketInfo,
    );
  }
}
