import 'package:uuid/uuid.dart';

const _uuid = Uuid();

enum AttendanceStatus { present, absent, halfDay, leave }

class Attendance {
  final String id;
  final String personId; // Can be Employee ID or Intern ID
  final DateTime date;
  final AttendanceStatus status;
  final String? notes;

  Attendance({
    String? id,
    required this.personId,
    required this.date,
    required this.status,
    this.notes,
  }) : id = id ?? _uuid.v4();

  Map<String, dynamic> toMap() => {
        'id': id,
        'personId': personId,
        'date': DateTime(date.year, date.month, date.day).toIso8601String(),
        'status': status.name,
        'notes': notes,
      };

  factory Attendance.fromMap(Map<String, dynamic> map) => Attendance(
        id: map['id'],
        personId: map['personId'] ?? '',
        date: DateTime.tryParse(map['date'] ?? '') ?? DateTime.now(),
        status: AttendanceStatus.values.firstWhere(
          (e) => e.name == map['status'],
          orElse: () => AttendanceStatus.present,
        ),
        notes: map['notes'],
      );
}
