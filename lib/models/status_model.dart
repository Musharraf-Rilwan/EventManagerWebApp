import 'package:cloud_firestore/cloud_firestore.dart';

enum RAGStatus {
  pending,
  processing,
  completed,
  failed;

  String get name {
    return this.toString().split('.').last;
  }

  static RAGStatus fromString(String value) {
    return RAGStatus.values.firstWhere(
      (status) => status.name == value,
      orElse: () => RAGStatus.pending,
    );
  }
}

class StatusModel {
  final String id;
  final String userId;
  final String eventId;
  final RAGStatus status;
  final String? message;
  final DateTime createdAt;
  final DateTime? completedAt;

  StatusModel({
    required this.id,
    required this.userId,
    required this.eventId,
    required this.status,
    this.message,
    required this.createdAt,
    this.completedAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'userId': userId,
      'eventId': eventId,
      'status': status.name,
      'message': message,
      'createdAt': Timestamp.fromDate(createdAt),
      'completedAt': completedAt != null ? Timestamp.fromDate(completedAt!) : null,
    };
  }

  factory StatusModel.fromMap(String id, Map<String, dynamic> map) {
    return StatusModel(
      id: id,
      userId: map['userId'] as String,
      eventId: map['eventId'] as String,
      status: RAGStatus.fromString(map['status'] as String),
      message: map['message'] as String?,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      completedAt: map['completedAt'] != null
          ? (map['completedAt'] as Timestamp).toDate()
          : null,
    );
  }

  StatusModel copyWith({
    String? userId,
    String? eventId,
    RAGStatus? status,
    String? message,
    DateTime? createdAt,
    DateTime? completedAt,
  }) {
    return StatusModel(
      id: id,
      userId: userId ?? this.userId,
      eventId: eventId ?? this.eventId,
      status: status ?? this.status,
      message: message ?? this.message,
      createdAt: createdAt ?? this.createdAt,
      completedAt: completedAt ?? this.completedAt,
    );
  }
}
