import 'package:uuid/uuid.dart';

import '../../core/constants/seed_data.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/attendance_math.dart';
import '../local/local_store.dart';
import '../models/library_models.dart';
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
  }

  List<TimetableSlot> timetable() =>
      store.all(store.timetable).map(TimetableSlot.fromJson).toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));

  List<TimetableSlot> slotsFor(DateTime day) {
    final all = timetable();
    final entries = timetableEntries();
    if (entries.isNotEmpty) {
      final ids = entries.map((e) => e.id).toSet();
      return all.where((s) => s.weekday == day.weekday && ids.contains(s.id)).toList()
        ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    }
    return all.where((s) => s.weekday == day.weekday).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
  }

  /// Remaining scheduled classes over the next ~4 weeks, from the real timetable.
  int remainingClasses({String? subjectId}) {
    var slots = timetable();
    final entries = timetableEntries();
    if (entries.isNotEmpty) {
      final ids = entries.map((e) => e.id).toSet();
      slots = slots.where((s) => ids.contains(s.id)).toList();
    }
    if (subjectId != null) {
      slots = slots.where((s) => s.subjectId == subjectId).toList();
    }
    return slots.length * 4;
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
    final now = DateTime.now();
    final record = AttendanceRecord(
      id: id,
      subjectId: subjectId,
      date: DateTime(date.year, date.month, date.day),
      status: status,
      slotId: slotId,
      markedAt: now,
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
        'marked_at': now.toIso8601String(),
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
    await store.timetableEntries.clear();
    for (final entry in entries) {
      if (entry.subjectCode.trim().isEmpty &&
          entry.subject.trim().isEmpty &&
          entry.teacherName.trim().isEmpty) {
        continue;
      }
      await upsertTimetableEntry(entry);
    }
  }

  List<TimetableEntry> timetableEntries() {
    final list = store.all(store.timetableEntries).map(TimetableEntry.fromJson).toList();
    list.sort((a, b) {
      final d = a.weekdayNumber.compareTo(b.weekdayNumber);
      if (d != 0) return d;
      return a.startMinutes.compareTo(b.startMinutes);
    });
    return list;
  }

  Future<void> upsertTimetableEntry(TimetableEntry entry) async {
    await store.put(store.timetableEntries, entry.id, entry.toJson());
    final subject = await _matchOrCreateSubject(entry);
    final slot = TimetableSlot(
      id: entry.id,
      subjectId: subject.id,
      weekday: entry.weekdayNumber,
      startMinutes: entry.startMinutes,
      endMinutes: entry.endMinutes <= entry.startMinutes ? entry.startMinutes + 60 : entry.endMinutes,
      room: entry.room.isNotEmpty ? entry.room : entry.teacherName,
    );
    await store.put(store.timetable, slot.id, slot.toJson());
  }

  Future<void> deleteTimetableEntry(String id) async {
    await store.delete(store.timetableEntries, id);
    await store.delete(store.timetable, id);
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
      name: entry.subject.trim().isNotEmpty
          ? entry.subject.trim()
          : (code.isEmpty ? 'Class' : code),
      code: code.isEmpty ? 'SCAN' : code,
      teacher: entry.teacherName,
      colorHex: AppColors.subjectPalette[subjects().length % AppColors.subjectPalette.length].toARGB32(),
    );
    await upsertSubject(created);
    return created;
  }

  List<PdfDoc> pdfs() {
    final list = store.all(store.pdfs).map(PdfDoc.fromJson).toList();
    list.sort((a, b) => b.dateAdded.compareTo(a.dateAdded));
    return list;
  }

  Future<void> upsertPdf(PdfDoc doc) => store.put(store.pdfs, doc.id, doc.toJson());

  Future<void> deletePdf(String id) => store.delete(store.pdfs, id);

  List<FlashcardDraft> flashcards() {
    final list = store.all(store.flashcards).map(FlashcardDraft.fromJson).toList();
    list.sort((a, b) => b.updatedAt.compareTo(a.updatedAt));
    return list;
  }

  Future<void> upsertFlashcard(FlashcardDraft card) =>
      store.put(store.flashcards, card.id, card.toJson());

  Future<void> deleteFlashcard(String id) => store.delete(store.flashcards, id);

  List<AppReminder> reminders() {
    final list = store.all(store.reminders).map(AppReminder.fromJson).toList();
    list.sort((a, b) => a.when.compareTo(b.when));
    return list;
  }

  Future<void> upsertReminder(AppReminder reminder) =>
      store.put(store.reminders, reminder.id, reminder.toJson());

  Future<void> deleteReminder(String id) => store.delete(store.reminders, id);

  NotificationPrefs notificationPrefs() {
    final raw = store.settings.get('notifications');
    if (raw is Map) return NotificationPrefs.fromJson(Map<String, dynamic>.from(raw));
    return const NotificationPrefs();
  }

  Future<void> saveNotificationPrefs(NotificationPrefs prefs) =>
      store.settings.put('notifications', prefs.toJson());

  Future<void> loginLocal({required String registerNumber, required String name, String role = 'student'}) async {
    final current = profile();
    await saveProfile(
      current.copyWith(
        registerNumber: registerNumber,
        fullName: name.isEmpty ? registerNumber : name,
        role: role,
        loggedIn: true,
        onboarded: true,
        id: current.id ?? _uuid.v4(),
      ),
    );
  }

  Future<String?> loginRemote(String registerNumber, String password, {required bool signUp, required String name}) async {
    if (!remote.configured) {
      await loginLocal(registerNumber: registerNumber, name: name);
      return null;
    }
    try {
      if (signUp) {
        await remote.signUpWithRegisterNumber(name, registerNumber, password);
      } else {
        await remote.signInWithRegisterNumber(registerNumber, password);
      }
      
      String role = 'student';
      final remoteProfile = await remote.fetchProfile();
      if (remoteProfile != null && remoteProfile['role'] != null) {
        role = remoteProfile['role'] as String;
      }
      
      await loginLocal(registerNumber: registerNumber, name: name, role: role);
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
