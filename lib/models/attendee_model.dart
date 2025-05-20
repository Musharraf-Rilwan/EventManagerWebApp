class AttendeeModel {
  final String id;
  final String name;
  final String email;
  final String? phoneNumber;
  final DateTime registrationDate;

  AttendeeModel({
    required this.id,
    required this.name,
    required this.email,
    this.phoneNumber,
    required this.registrationDate,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'phoneNumber': phoneNumber,
      'registrationDate': registrationDate,
    };
  }

  factory AttendeeModel.fromMap(Map<String, dynamic> map) {
    return AttendeeModel(
      id: map['id'] ?? '',
      name: map['name'] ?? '',
      email: map['email'] ?? '',
      phoneNumber: map['phoneNumber'],
      registrationDate: map['registrationDate']?.toDate() ?? DateTime.now(),
    );
  }
}
