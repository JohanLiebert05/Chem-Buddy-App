import 'package:uuid/uuid.dart';

import '../../core/constants/seed_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/attendance_math.dart';
import '../local/local_store.dart';
import '../models/models.dart';
import '../models/timetable_entry.dart';
import '../remote/notification_service.dart';
import '../remote/supabase_service.dart';

class ChemRepository {
  ChemRepository({
    required this.store,
    required this.remote,
    required this.notifications,
  });

  final LocalStore store;
  final SupabaseService remote;
  final NotificationService notifications;
  final _uuid = const Uuid();

  UserProfile profile() {
    final json = store.getProfile();
    return json == null ? const UserProfile() : UserProfile.fromJson(json);
  }

  Future<void> saveProfile(UserProfile profile) async {
    await store.saveProfile(profile.toJson());
    final uid = remote.userId ?? profile.id;
    if (uid != null) {
      await remote.upsert('profiles', {
        'id': uid,
        'full_name': profile.fullName,
        'university': profile.university,
        'semester': profile.semester,
      });
    }
  }

  List<Subject> subjects() => store.all(store.subjects).map(Subject.fromJson).toList();

  Future<void> upsertSubject(Subject subject) async {
    await store.put(store.subjects, subject.id, subject.toJson());
    final uid = remote.userId;
    if (uid != null) {
      await remote.upsert('subjects', {
        'id': subject.id,
        'user_id': uid,
        'name': subject.name,
        'code': subject.code,
        'teacher': subject.teacher,
        'color_hex': subject.colorHex.toRadixString(16),
        'is_elective': subject.isElective,
      });
    }
  }

  Future<void> deleteSubject(String id) async {
    await store.delete(store.subjects, id);
    await remote.remove('subjects', id);
  }

  Future<void> seedSubjects(List<SeedSubject> selected, {String electiveName = 'Open Elective'}) async {
    var i = 0;
    for (final seed in selected) {
      final subject = Subject(
        id: _uuid.v4(),
        name: seed.isElective ? electiveName : seed.name,
        code: seed.code,
        isElective: seed.isElective,
        colorHex: AppColors.subjectPalette[i % AppColors.subjectPalette.length].toARGB32(),
      );
      await upsertSubject(subject);
      i++;
    }
    await _seedTimetable();
  }

  Future<void> _seedTimetable() async {
    final subs = subjects();
    if (subs.isEmpty) return;
    const starts = [9 * 60, 11 * 60, 14 * 60];
    var idx = 0;
    for (var day = DateTime.monday; day <= DateTime.friday; day++) {
      for (var slot = 0; slot < 2; slot++) {
        final subject = subs[idx % subs.length];
        final start = starts[slot];
        final item = TimetableSlot(
          id: _uuid.v4(),
          subjectId: subject.id,
          weekday: day,
          startMinutes: start,
          endMinutes: start + 60,
          room: 'Lab ${(slot + 1)}',
        );
        await store.put(store.timetable, item.id, item.toJson());
        idx++;
      }
    }
  }

  List<TimetableSlot> timetable() =>
      store.all(store.timetable).map(TimetableSlot.fromJson).toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

  List<TimetableSlot> slotsFor(DateTime day) {
    return timetable().where((s) => s.weekday == day.weekday).toList();
  }

  List<AttendanceRecord> attendance() =>
      store.all(store.attendance).map(AttendanceRecord.fromJson).toList();

  AttendanceRecord? recordFor({required String slotId, required DateTime date}) {
    final key = _dayKey(date);
    for (final r in attendance()) {
      if (r.slotId == slotId && _dayKey(r.date) == key) return r;
    }
    return null;
  }

  Future<void> markAttendance({
    required String subjectId,
    required DateTime date,
    required AttendanceStatus status,
    String? slotId,
  }) async {
    final existing = attendance().where((r) {
      return r.subjectId == subjectId &&
          _dayKey(r.date) == _dayKey(date) &&
          r.slotId == slotId;
    }).toList();
    final id = existing.isNotEmpty ? existing.first.id : _uuid.v4();
    final record = AttendanceRecord(
      id: id,
      subjectId: subjectId,
      date: DateTime(date.year, date.month, date.day),
      status: status,
      slotId: slotId,
    );
    await store.put(store.attendance, record.id, record.toJson());
    final uid = remote.userId;
    if (uid != null) {
      await remote.upsert('attendance_records', {
        'id': record.id,
        'user_id': uid,
        'subject_id': subjectId,
        'date': _dayKey(date),
        'status': status.name,
        'slot_id': slotId,
      });
    }
  }

  SubjectAttendanceStats statsFor(String subjectId) {
    final rows = attendance().where((r) => r.subjectId == subjectId);
    return SubjectAttendanceStats(
      present: rows.where((r) => r.status == AttendanceStatus.present).length,
      absent: rows.where((r) => r.status == AttendanceStatus.absent).length,
      postponed: rows.where((r) => r.status == AttendanceStatus.postponed).length,
    );
  }

  SubjectAttendanceStats overallStats() {
    final rows = attendance();
    return SubjectAttendanceStats(
      present: rows.where((r) => r.status == AttendanceStatus.present).length,
      absent: rows.where((r) => r.status == AttendanceStatus.absent).length,
      postponed: rows.where((r) => r.status == AttendanceStatus.postponed).length,
    );
  }

  int streak() {
    final presents = attendance()
        .where((r) => r.status == AttendanceStatus.present)
        .map((r) => _dayKey(r.date))
        .toSet()
        .toList()
      ..sort();
    if (presents.isEmpty) return 0;
    var count = 0;
    var cursor = DateTime.now();
    while (presents.contains(_dayKey(cursor))) {
      count++;
      cursor = cursor.subtract(const Duration(days: 1));
    }
    if (count == 0 && presents.contains(_dayKey(cursor))) {
      // yesterday start
    }
    if (count == 0) {
      cursor = DateTime.now().subtract(const Duration(days: 1));
      while (presents.contains(_dayKey(cursor))) {
        count++;
        cursor = cursor.subtract(const Duration(days: 1));
      }
    }
    return count;
  }

  List<double> lastSevenDayPercents() {
    final now = DateTime.now();
    return List.generate(7, (i) {
      final day = DateTime(now.year, now.month, now.day).subtract(Duration(days: 6 - i));
      final rows = attendance().where((r) => _dayKey(r.date) == _dayKey(day));
      final counted = rows.where((r) => r.status != AttendanceStatus.postponed);
      if (counted.isEmpty) return 0;
      final present = counted.where((r) => r.status == AttendanceStatus.present).length;
      return present / counted.length * 100;
    });
  }

  List<AcademicEvent> events() {
    final list = store.all(store.events).map(AcademicEvent.fromJson).toList();
    list.sort((a, b) => a.dueDate.compareTo(b.dueDate));
    return list;
  }

  Future<void> upsertEvent(AcademicEvent event) async {
    await store.put(store.events, event.id, event.toJson());
    await notifications.scheduleEvent(event);
    final uid = remote.userId;
    if (uid != null) {
      await remote.upsert('academic_events', {
        'id': event.id,
        'user_id': uid,
        'subject_id': event.subjectId,
        'title': event.title,
        'type': event.type.name,
        'due_date': _dayKey(event.dueDate),
        'description': event.description,
        'completed': event.completed,
      });
    }
  }

  Future<void> deleteEvent(String id) async {
    await store.delete(store.events, id);
    await notifications.cancel(id);
    await remote.remove('academic_events', id);
  }

  List<NoteItem> notes() {
    final list = store.all(store.notes).map(NoteItem.fromJson).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<void> upsertNote(NoteItem note) async {
    await store.put(store.notes, note.id, note.toJson());
    final uid = remote.userId;
    if (uid != null) {
      await remote.upsert('notes', {
        'id': note.id,
        'user_id': uid,
        'subject_id': note.subjectId,
        'title': note.title,
        'body': note.body,
        'updated_at': note.updatedAt.toIso8601String(),
      });
    }
  }

  Future<void> deleteNote(String id) async {
    await store.delete(store.notes, id);
    await remote.remove('notes', id);
  }

  Future<void> applyScannedTimetable(List<TimetableEntry> entries) async {
    await store.timetable.clear();
    for (final entry in entries) {
      if (entry.subjectCode.trim().isEmpty && entry.teacherName.trim().isEmpty) {
        continue;
      }
      final subject = await _matchOrCreateSubject(entry);
      final slot = TimetableSlot(
        id: entry.id.isEmpty ? _uuid.v4() : entry.id,
        subjectId: subject.id,
        weekday: entry.weekdayNumber,
        startMinutes: entry.startMinutes,
        endMinutes: entry.endMinutes <= entry.startMinutes
            ? entry.startMinutes + 60
            : entry.endMinutes,
        room: entry.teacherName,
      );
      await store.put(store.timetable, slot.id, slot.toJson());
    }
  }

  Future<Subject> _matchOrCreateSubject(TimetableEntry entry) async {
    final code = entry.subjectCode.trim().toUpperCase();
    for (final subject in subjects()) {
      if (subject.code.toUpperCase() == code ||
          (code.isNotEmpty && subject.name.toUpperCase().contains(code))) {
        if (entry.teacherName.isNotEmpty && subject.teacher.isEmpty) {
          await upsertSubject(subject.copyWith(teacher: entry.teacherName));
          return subject.copyWith(teacher: entry.teacherName);
        }
        return subject;
      }
    }
    final created = Subject(
      id: _uuid.v4(),
      name: code.isEmpty ? 'Class' : code,
      code: code.isEmpty ? 'SCAN' : code,
      teacher: entry.teacherName,
      colorHex: AppColors.subjectPalette[subjects().length % AppColors.subjectPalette.length].toARGB32(),
    );
    await upsertSubject(created);
    return created;
  }

  Future<void> loginLocal({required String email, required String name}) async {
    final current = profile();
    await saveProfile(
      current.copyWith(
        email: email,
        fullName: name.isEmpty ? email.split('@').first : name,
        loggedIn: true,
        onboarded: true,
        id: current.id ?? _uuid.v4(),
      ),
    );
  }

  Future<String?> loginRemote(String email, String password, {required bool signUp}) async {
    if (!remote.configured) {
      await loginLocal(email: email, name: '');
      return null;
    }
    try {
      if (signUp) {
        await remote.signUp(email, password);
      } else {
        await remote.signIn(email, password);
      }
      await loginLocal(email: email, name: '');
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<void> logout() async {
    await remote.signOut();
    final current = profile();
    await saveProfile(current.copyWith(loggedIn: false));
  }

  String newId() => _uuid.v4();

  String _dayKey(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
