/// Structured class parsed from a university timetable photo.
class TimetableEntry {
  const TimetableEntry({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subjectCode,
    this.subject = '',
    this.teacherName = '',
    this.room = '',
    this.type = 'lecture',
    this.notes = '',
    this.colorHex = 0xFFA78BFA,
  });

  final String id;
  final String dayOfWeek;
  final String startTime;
  final String endTime;
  final String subjectCode;
  final String subject;
  final String teacherName;
  final String room;
  final String type; // lecture | lab | tutorial | other
  final String notes;
  final int colorHex;

  String get displayName => subject.trim().isNotEmpty ? subject : subjectCode;

  TimetableEntry copyWith({
    String? id,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? subjectCode,
    String? subject,
    String? teacherName,
    String? room,
    String? type,
    String? notes,
    int? colorHex,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subjectCode: subjectCode ?? this.subjectCode,
      subject: subject ?? this.subject,
      teacherName: teacherName ?? this.teacherName,
      room: room ?? this.room,
      type: type ?? this.type,
      notes: notes ?? this.notes,
      colorHex: colorHex ?? this.colorHex,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'dayOfWeek': dayOfWeek,
        'startTime': startTime,
        'endTime': endTime,
        'subjectCode': subjectCode,
        'subject': subject,
        'teacherName': teacherName,
        'room': room,
        'type': type,
        'notes': notes,
        'colorHex': colorHex,
      };

  factory TimetableEntry.fromJson(Map<String, dynamic> json) => TimetableEntry(
        id: json['id'] as String,
        dayOfWeek: json['dayOfWeek'] as String? ?? 'Monday',
        startTime: json['startTime'] as String? ?? '09:00 AM',
        endTime: json['endTime'] as String? ?? '10:00 AM',
        subjectCode: json['subjectCode'] as String? ?? '',
        subject: json['subject'] as String? ?? '',
        teacherName: json['teacherName'] as String? ?? '',
        room: json['room'] as String? ?? '',
        type: json['type'] as String? ?? 'lecture',
        notes: json['notes'] as String? ?? '',
        colorHex: json['colorHex'] as int? ?? 0xFFA78BFA,
      );

  int get weekdayNumber {
    const map = {
      'monday': DateTime.monday,
      'tuesday': DateTime.tuesday,
      'wednesday': DateTime.wednesday,
      'thursday': DateTime.thursday,
      'friday': DateTime.friday,
      'saturday': DateTime.saturday,
      'sunday': DateTime.sunday,
      'mon': DateTime.monday,
      'tue': DateTime.tuesday,
      'wed': DateTime.wednesday,
      'thu': DateTime.thursday,
      'fri': DateTime.friday,
      'sat': DateTime.saturday,
      'sun': DateTime.sunday,
    };
    return map[dayOfWeek.trim().toLowerCase()] ?? DateTime.monday;
  }

  int get startMinutes => parseClock(startTime);
  int get endMinutes => parseClock(endTime);

  static int parseClock(String raw) {
    final text = raw.trim().toUpperCase().replaceAll('.', ':');
    final match = RegExp(r'(\d{1,2}):?(\d{2})?\s*(AM|PM)?').firstMatch(text);
    if (match == null) return 9 * 60;
    var hour = int.tryParse(match.group(1) ?? '9') ?? 9;
    final minute = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3);
    if (period == 'PM' && hour < 12) hour += 12;
    if (period == 'AM' && hour == 12) hour = 0;
    return hour * 60 + minute;
  }
}
