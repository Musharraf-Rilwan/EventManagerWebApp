import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole {
  admin,
  organizer,
  attendee;

  String get name {
    switch (this) {
      case UserRole.admin:
        return 'admin';
      case UserRole.organizer:
        return 'organizer';
      case UserRole.attendee:
        return 'attendee';
    }
  }

  static UserRole fromString(String value) {
    switch (value.toLowerCase()) {
      case 'admin':
        return UserRole.admin;
      case 'organizer':
        return UserRole.organizer;
      default:
        return UserRole.attendee;
    }
  }
}

class UserModel {
  final String uid;
  final String email;
  final String displayName;
  final UserRole role;
  final String? phoneNumber;
  final DateTime createdAt;
  final DateTime lastLogin;
  final List<String> managedEvents;
  final List<String> attendingEvents;

  UserModel({
    required this.uid,
    required this.email,
    required this.displayName,
    required this.role,
    this.phoneNumber,
    required this.createdAt,
    required this.lastLogin,
    this.managedEvents = const [],
    this.attendingEvents = const [],
  });

  factory UserModel.fromMap(String id, Map<String, dynamic> map) {
    String roleStr = (map['role'] as String?) ?? 'attendee';
    UserRole role;
    switch (roleStr.toLowerCase()) {
      case 'admin':
        role = UserRole.admin;
        break;
      case 'organizer':
        role = UserRole.organizer;
        break;
      default:
        role = UserRole.attendee;
    }

    return UserModel(
      uid: id,
      email: map['email'] as String,
      displayName: map['displayName'] as String? ?? 'Anonymous',
      role: role,
      phoneNumber: map['phoneNumber'] as String?,
      createdAt: (map['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      lastLogin: (map['lastLogin'] as Timestamp?)?.toDate() ?? DateTime.now(),
      managedEvents: List<String>.from(map['managedEvents'] ?? []),
      attendingEvents: List<String>.from(map['attendingEvents'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'displayName': displayName,
      'role': role.toString().split('.').last,
      'phoneNumber': phoneNumber,
      'createdAt': Timestamp.fromDate(createdAt),
      'lastLogin': Timestamp.fromDate(lastLogin),
      'managedEvents': managedEvents,
      'attendingEvents': attendingEvents,
    };
  }

  UserModel copyWith({
    String? uid,
    String? email,
    String? displayName,
    UserRole? role,
    String? phoneNumber,
    DateTime? createdAt,
    DateTime? lastLogin,
    List<String>? managedEvents,
    List<String>? attendingEvents,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      role: role ?? this.role,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      createdAt: createdAt ?? this.createdAt,
      lastLogin: lastLogin ?? this.lastLogin,
      managedEvents: managedEvents ?? this.managedEvents,
      attendingEvents: attendingEvents ?? this.attendingEvents,
    );
  }
}
