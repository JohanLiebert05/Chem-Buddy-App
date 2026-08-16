/// Structured class parsed from a university timetable photo.
class TimetableEntry {
  const TimetableEntry({
    required this.id,
    required this.dayOfWeek,
    required this.startTime,
    required this.endTime,
    required this.subjectCode,
    required this.teacherName,
  });

  final String id;
  final String dayOfWeek; // e.g. "Monday"
  final String startTime; // e.g. "10:00 AM"
  final String endTime; // e.g. "11:00 AM"
  final String subjectCode; // e.g. "OCH501"
  final String teacherName; // e.g. "Dr. Sharma"

  TimetableEntry copyWith({
    String? id,
    String? dayOfWeek,
    String? startTime,
    String? endTime,
    String? subjectCode,
    String? teacherName,
  }) {
    return TimetableEntry(
      id: id ?? this.id,
      dayOfWeek: dayOfWeek ?? this.dayOfWeek,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      subjectCode: subjectCode ?? this.subjectCode,
      teacherName: teacherName ?? this.teacherName,
    );
  }

  /// Monday = 1 … Sunday = 7 (DateTime.weekday).
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
