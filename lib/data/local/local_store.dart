import 'package:hive_flutter/hive_flutter.dart';

class HiveBoxes {
  static const profile = 'profile';
  static const subjects = 'subjects';
  static const attendance = 'attendance';
  static const timetable = 'timetable';
  static const events = 'events';
  static const notes = 'notes';

  static Future<void> openAll() async {
    await Hive.initFlutter();
    await Future.wait([
      Hive.openBox(profile),
      Hive.openBox(subjects),
      Hive.openBox(attendance),
      Hive.openBox(timetable),
      Hive.openBox(events),
      Hive.openBox(notes),
    ]);
  }
}

class LocalStore {
  Box get _profile => Hive.box(HiveBoxes.profile);
  Box get subjects => Hive.box(HiveBoxes.subjects);
  Box get attendance => Hive.box(HiveBoxes.attendance);
  Box get timetable => Hive.box(HiveBoxes.timetable);
  Box get events => Hive.box(HiveBoxes.events);
  Box get notes => Hive.box(HiveBoxes.notes);

  Map<String, dynamic>? getProfile() {
    final raw = _profile.get('current');
    if (raw is Map) return Map<String, dynamic>.from(raw);
    return null;
  }

  Future<void> saveProfile(Map<String, dynamic> json) => _profile.put('current', json);

  Future<void> clearAll() async {
    await Future.wait([
      _profile.clear(),
      subjects.clear(),
      attendance.clear(),
      timetable.clear(),
      events.clear(),
      notes.clear(),
    ]);
  }

  List<Map<String, dynamic>> all(Box box) {
    return box.values.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
  }

  Future<void> put(Box box, String id, Map<String, dynamic> json) => box.put(id, json);

  Future<void> delete(Box box, String id) => box.delete(id);
}
