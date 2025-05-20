import 'package:cloud_firestore/cloud_firestore.dart';

class TicketModel {
  final String id;
  final String eventId;
  final String userId;
  final String userEmail;
  final String userName;
  final String eventTitle;
  final DateTime eventDate;
  final String eventLocation;
  final int quantity;
  final double totalPrice;
  final DateTime purchaseDate;

  TicketModel({
    required this.id,
    required this.eventId,
    required this.userId,
    required this.userEmail,
    required this.userName,
    required this.eventTitle,
    required this.eventDate,
    required this.eventLocation,
    required this.quantity,
    required this.totalPrice,
    required this.purchaseDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'eventId': eventId,
      'userId': userId,
      'userEmail': userEmail,
      'userName': userName,
      'eventTitle': eventTitle,
      'eventDate': Timestamp.fromDate(eventDate),
      'eventLocation': eventLocation,
      'quantity': quantity,
      'totalPrice': totalPrice,
      'purchaseDate': Timestamp.fromDate(purchaseDate),
    };
  }

  factory TicketModel.fromMap(String id, Map<String, dynamic> map) {
    return TicketModel(
      id: id,
      eventId: map['eventId'] as String,
      userId: map['userId'] as String,
      userEmail: map['userEmail'] as String,
      userName: map['userName'] as String,
      eventTitle: map['eventTitle'] as String,
      eventDate: (map['eventDate'] as Timestamp).toDate(),
      eventLocation: map['eventLocation'] as String,
      quantity: map['quantity'] as int,
      totalPrice: (map['totalPrice'] as num).toDouble(),
      purchaseDate: (map['purchaseDate'] as Timestamp).toDate(),
    );
  }
}
