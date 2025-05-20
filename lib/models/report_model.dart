import 'package:cloud_firestore/cloud_firestore.dart';

enum ReportType {
  eventAttendance,
  userActivity,
  revenue,
  feedback,
  custom
}

enum ReportFormat {
  pdf,
  excel,
  csv
}

class ReportModel {
  final String id;
  final String name;
  final String description;
  final ReportType type;
  final ReportFormat format;
  final Map<String, dynamic> parameters;
  final DateTime createdAt;
  final String createdBy;
  final String? fileUrl;
  final DateTime? lastGenerated;
  final bool isScheduled;
  final String? scheduleFrequency;

  ReportModel({
    required this.id,
    required this.name,
    required this.description,
    required this.type,
    required this.format,
    required this.parameters,
    required this.createdAt,
    required this.createdBy,
    this.fileUrl,
    this.lastGenerated,
    this.isScheduled = false,
    this.scheduleFrequency,
  });

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'description': description,
      'type': type.toString().split('.').last,
      'format': format.toString().split('.').last,
      'parameters': parameters,
      'createdAt': createdAt,
      'createdBy': createdBy,
      'fileUrl': fileUrl,
      'lastGenerated': lastGenerated,
      'isScheduled': isScheduled,
      'scheduleFrequency': scheduleFrequency,
    };
  }

  factory ReportModel.fromMap(String id, Map<String, dynamic> map) {
    return ReportModel(
      id: id,
      name: map['name'] as String,
      description: map['description'] as String,
      type: ReportType.values.firstWhere(
        (type) => type.toString().split('.').last == map['type'],
      ),
      format: ReportFormat.values.firstWhere(
        (format) => format.toString().split('.').last == map['format'],
      ),
      parameters: map['parameters'] as Map<String, dynamic>,
      createdAt: (map['createdAt'] as Timestamp).toDate(),
      createdBy: map['createdBy'] as String,
      fileUrl: map['fileUrl'] as String?,
      lastGenerated: map['lastGenerated'] != null
          ? (map['lastGenerated'] as Timestamp).toDate()
          : null,
      isScheduled: map['isScheduled'] as bool? ?? false,
      scheduleFrequency: map['scheduleFrequency'] as String?,
    );
  }
}
