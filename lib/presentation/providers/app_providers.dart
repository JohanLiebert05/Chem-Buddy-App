import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/seed_data.dart';
import '../../data/local/local_store.dart';
import '../../data/models/models.dart';
import '../../data/models/timetable_entry.dart';
import '../../data/remote/notification_service.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/repositories/chem_repository.dart';

final localStoreProvider = Provider<LocalStore>((ref) => LocalStore());

final chemRepositoryProvider = Provider<ChemRepository>((ref) {
  return ChemRepository(
    store: ref.watch(localStoreProvider),
    remote: SupabaseService.instance,
    notifications: NotificationService.instance,
  );
});

final appControllerProvider = NotifierProvider<AppController, AppState>(AppController.new);

final shellTabProvider = StateProvider<int>((ref) => 0);

class AppState {
  const AppState({
    required this.profile,
    required this.subjects,
    required this.attendance,
    required this.slots,
    required this.events,
    required this.notes,
  });

  final UserProfile profile;
  final List<Subject> subjects;
  final List<AttendanceRecord> attendance;
  final List<TimetableSlot> slots;
  final List<AcademicEvent> events;
  final List<NoteItem> notes;

  AppState copyWith({
    UserProfile? profile,
    List<Subject>? subjects,
    List<AttendanceRecord>? attendance,
    List<TimetableSlot>? slots,
    List<AcademicEvent>? events,
    List<NoteItem>? notes,
  }) {
    return AppState(
      profile: profile ?? this.profile,
      subjects: subjects ?? this.subjects,
      attendance: attendance ?? this.attendance,
      slots: slots ?? this.slots,
      events: events ?? this.events,
      notes: notes ?? this.notes,
    );
  }
}

class AppController extends Notifier<AppState> {
  ChemRepository get _repo => ref.read(chemRepositoryProvider);

  @override
  AppState build() => _snapshot();

  AppState _snapshot() {
    return AppState(
      profile: _repo.profile(),
      subjects: _repo.subjects(),
      attendance: _repo.attendance(),
      slots: _repo.timetable(),
      events: _repo.events(),
      notes: _repo.notes(),
    );
  }

  Future<void> reload() async {
    state = _snapshot();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _repo.saveProfile(profile);
    await reload();
  }

  Future<void> completeOnboarding({
    required String university,
    required int semester,
    required List<SeedSubject> selectedSeeds,
    String electiveName = 'Open Elective',
  }) async {
    await _repo.saveProfile(
      _repo.profile().copyWith(
            university: university,
            semester: semester,
            onboarded: true,
          ),
    );
    if (_repo.subjects().isEmpty) {
      await _repo.seedSubjects(selectedSeeds, electiveName: electiveName);
    }
    await reload();
  }

  Future<String?> authenticate({
    required String email,
    required String password,
    required String name,
    required bool signUp,
  }) async {
    if (!SupabaseService.instance.configured) {
      await _repo.loginLocal(email: email, name: name);
      await reload();
      return null;
    }
    final error = await _repo.loginRemote(email, password, signUp: signUp);
    if (error == null) {
      final p = _repo.profile();
      await _repo.saveProfile(p.copyWith(fullName: name.isEmpty ? p.fullName : name));
    }
    await reload();
    return error;
  }

  Future<void> logout() async {
    await _repo.logout();
    await reload();
  }

  Future<void> mark({
    required String subjectId,
    required DateTime date,
    required AttendanceStatus status,
    String? slotId,
  }) async {
    await _repo.markAttendance(
      subjectId: subjectId,
      date: date,
      status: status,
      slotId: slotId,
    );
    await reload();
  }

  Future<void> applyScannedTimetable(List<TimetableEntry> entries) async {
    await _repo.applyScannedTimetable(entries);
    await reload();
  }

  Future<void> saveSubject(Subject subject) async {
    await _repo.upsertSubject(subject);
    await reload();
  }

  Future<void> saveEvent(AcademicEvent event) async {
    await _repo.upsertEvent(event);
    await reload();
  }

  Future<void> deleteEvent(String id) async {
    await _repo.deleteEvent(id);
    await reload();
  }

  Future<void> saveNote(NoteItem note) async {
    await _repo.upsertNote(note);
    await reload();
  }

  Future<void> deleteNote(String id) async {
    await _repo.deleteNote(id);
    await reload();
  }
}
