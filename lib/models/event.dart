class Event {
  final String id;
  final String title;
  final String description;
  final DateTime dateTime;
  final String location;
  final int capacity;
  final String organizerId;
  final List<String> registeredUsers;

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.dateTime,
    required this.location,
    required this.capacity,
    required this.organizerId,
    this.registeredUsers = const [],
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'dateTime': dateTime.toIso8601String(),
      'location': location,
      'capacity': capacity,
      'organizerId': organizerId,
      'registeredUsers': registeredUsers,
    };
  }

  factory Event.fromMap(Map<String, dynamic> map) {
    return Event(
      id: map['id'],
      title: map['title'],
      description: map['description'],
      dateTime: DateTime.parse(map['dateTime']),
      location: map['location'],
      capacity: map['capacity'],
      organizerId: map['organizerId'],
      registeredUsers: List<String>.from(map['registeredUsers']),
    );
  }
}
