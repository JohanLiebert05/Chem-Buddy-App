class Subject {
  const Subject({
    required this.id,
    required this.name,
    required this.code,
    this.teacher = '',
    this.colorHex = 0xFF8B5CF6,
    this.isElective = false,
  });

  final String id;
  final String name;
  final String code;
  final String teacher;
  final int colorHex;
  final bool isElective;

  Subject copyWith({
    String? name,
    String? code,
    String? teacher,
    int? colorHex,
    bool? isElective,
  }) {
    return Subject(
      id: id,
      name: name ?? this.name,
      code: code ?? this.code,
      teacher: teacher ?? this.teacher,
      colorHex: colorHex ?? this.colorHex,
      isElective: isElective ?? this.isElective,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'code': code,
        'teacher': teacher,
        'colorHex': colorHex,
        'isElective': isElective,
      };

  factory Subject.fromJson(Map<String, dynamic> json) => Subject(
        id: json['id'] as String,
        name: json['name'] as String,
        code: json['code'] as String,
        teacher: json['teacher'] as String? ?? '',
        colorHex: json['colorHex'] as int? ?? 0xFF8B5CF6,
        isElective: json['isElective'] as bool? ?? false,
      );
}

enum AttendanceStatus { present, absent, postponed }

class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.subjectId,
    required this.date,
    required this.status,
    this.slotId,
  });

  final String id;
  final String subjectId;
  final DateTime date;
  final AttendanceStatus status;
  final String? slotId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'date': date.toIso8601String(),
        'status': status.name,
        'slotId': slotId,
      };

  factory AttendanceRecord.fromJson(Map<String, dynamic> json) => AttendanceRecord(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        date: DateTime.parse(json['date'] as String),
        status: AttendanceStatus.values.byName(json['status'] as String),
        slotId: json['slotId'] as String?,
      );
}

class TimetableSlot {
  const TimetableSlot({
    required this.id,
    required this.subjectId,
    required this.weekday,
    required this.startMinutes,
    required this.endMinutes,
    this.room = '',
  });

  final String id;
  final String subjectId;
  final int weekday;
  final int startMinutes;
  final int endMinutes;
  final String room;

  String get timeLabel {
    String fmt(int m) {
      final h = m ~/ 60;
      final min = m % 60;
      final suffix = h >= 12 ? 'PM' : 'AM';
      final hr = h % 12 == 0 ? 12 : h % 12;
      return '$hr:${min.toString().padLeft(2, '0')} $suffix';
    }

    return '${fmt(startMinutes)} – ${fmt(endMinutes)}';
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'subjectId': subjectId,
        'weekday': weekday,
        'startMinutes': startMinutes,
        'endMinutes': endMinutes,
        'room': room,
      };

  factory TimetableSlot.fromJson(Map<String, dynamic> json) => TimetableSlot(
        id: json['id'] as String,
        subjectId: json['subjectId'] as String,
        weekday: json['weekday'] as int,
        startMinutes: json['startMinutes'] as int,
        endMinutes: json['endMinutes'] as int,
        room: json['room'] as String? ?? '',
      );
}

enum EventType { test, assignment, seminar }

class AcademicEvent {
  const AcademicEvent({
    required this.id,
    required this.title,
    required this.type,
    required this.dueDate,
    this.subjectId,
    this.description = '',
    this.completed = false,
  });

  final String id;
  final String title;
  final EventType type;
  final DateTime dueDate;
  final String? subjectId;
  final String description;
  final bool completed;

  AcademicEvent copyWith({bool? completed}) => AcademicEvent(
        id: id,
        title: title,
        type: type,
        dueDate: dueDate,
        subjectId: subjectId,
        description: description,
        completed: completed ?? this.completed,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'type': type.name,
        'dueDate': dueDate.toIso8601String(),
        'subjectId': subjectId,
        'description': description,
        'completed': completed,
      };

  factory AcademicEvent.fromJson(Map<String, dynamic> json) => AcademicEvent(
        id: json['id'] as String,
        title: json['title'] as String,
        type: EventType.values.byName(json['type'] as String),
        dueDate: DateTime.parse(json['dueDate'] as String),
        subjectId: json['subjectId'] as String?,
        description: json['description'] as String? ?? '',
        completed: json['completed'] as bool? ?? false,
      );
}

class NoteItem {
  const NoteItem({
    required this.id,
    required this.title,
    required this.body,
    required this.updatedAt,
    this.subjectId,
  });

  final String id;
  final String title;
  final String body;
  final DateTime updatedAt;
  final String? subjectId;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'updatedAt': updatedAt.toIso8601String(),
        'subjectId': subjectId,
      };

  factory NoteItem.fromJson(Map<String, dynamic> json) => NoteItem(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        subjectId: json['subjectId'] as String?,
      );
}

class UserProfile {
  const UserProfile({
    this.id,
    this.fullName = '',
    this.email = '',
    this.registerNumber = '',
    this.role = 'student',
    this.university = '',
    this.semester = 1,
    this.onboarded = false,
    this.loggedIn = false,
  });

  final String? id;
  final String fullName;
  final String email;
  final String registerNumber;
  final String role;
  final String university;
  final int semester;
  final bool onboarded;
  final bool loggedIn;

  UserProfile copyWith({
    String? id,
    String? fullName,
    String? email,
    String? registerNumber,
    String? role,
    String? university,
    int? semester,
    bool? onboarded,
    bool? loggedIn,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      email: email ?? this.email,
      registerNumber: registerNumber ?? this.registerNumber,
      role: role ?? this.role,
      university: university ?? this.university,
      semester: semester ?? this.semester,
      onboarded: onboarded ?? this.onboarded,
      loggedIn: loggedIn ?? this.loggedIn,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'fullName': fullName,
        'email': email,
        'registerNumber': registerNumber,
        'role': role,
        'university': university,
        'semester': semester,
        'onboarded': onboarded,
        'loggedIn': loggedIn,
      };

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String?,
        fullName: json['fullName'] as String? ?? '',
        email: json['email'] as String? ?? '',
        registerNumber: json['registerNumber'] as String? ?? '',
        role: json['role'] as String? ?? 'student',
        university: json['university'] as String? ?? '',
        semester: json['semester'] as int? ?? 1,
        onboarded: json['onboarded'] as bool? ?? false,
        loggedIn: json['loggedIn'] as bool? ?? false,
      );
}
