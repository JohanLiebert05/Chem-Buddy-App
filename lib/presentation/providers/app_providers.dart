import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/constants/seed_data.dart';
import '../../data/local/local_store.dart';
import '../../data/models/library_models.dart';
import '../../data/models/models.dart';
import '../../data/models/timetable_entry.dart';
import '../../data/remote/notification_service.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/repositories/chem_repository.dart';
import '../../data/services/pdf_library_service.dart';

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
    required this.entries,
    required this.events,
    required this.notes,
    required this.pdfs,
    required this.flashcards,
    required this.reminders,
    required this.notificationPrefs,
  });

  final UserProfile profile;
  final List<Subject> subjects;
  final List<AttendanceRecord> attendance;
  final List<TimetableSlot> slots;
  final List<TimetableEntry> entries;
  final List<AcademicEvent> events;
  final List<NoteItem> notes;
  final List<PdfDoc> pdfs;
  final List<FlashcardDraft> flashcards;
  final List<AppReminder> reminders;
  final NotificationPrefs notificationPrefs;
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
      entries: _repo.timetableEntries(),
      events: _repo.events(),
      notes: _repo.notes(),
      pdfs: _repo.pdfs(),
      flashcards: _repo.flashcards(),
      reminders: _repo.reminders(),
      notificationPrefs: _repo.notificationPrefs(),
    );
  }

  Future<void> reload() async {
    state = _snapshot();
    await NotificationService.instance.resync(
      prefs: state.notificationPrefs,
      entries: state.entries,
      events: state.events,
      reminders: state.reminders,
    );
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
      _repo.profile().copyWith(university: university, semester: semester, onboarded: true),
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
    await _repo.markAttendance(subjectId: subjectId, date: date, status: status, slotId: slotId);
    await reload();
  }

  Future<void> applyScannedTimetable(List<TimetableEntry> entries) async {
    await _repo.applyScannedTimetable(entries);
    await reload();
  }

  Future<void> saveTimetableEntry(TimetableEntry entry) async {
    await _repo.upsertTimetableEntry(entry);
    await reload();
  }

  Future<void> deleteTimetableEntry(String id) async {
    await _repo.deleteTimetableEntry(id);
    await reload();
  }

  Future<void> saveSubject(Subject subject) async {
    await _repo.upsertSubject(subject);
    await reload();
  }

  Future<void> deleteSubject(String id) async {
    await _repo.deleteSubject(id);
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

  Future<void> savePdf(PdfDoc doc) async {
    await _repo.upsertPdf(doc);
    await reload();
  }

  Future<void> deletePdf(String id) async {
    final match = state.pdfs.where((d) => d.id == id);
    if (match.isNotEmpty) {
      await PdfLibraryService.instance.deleteFile(match.first.localPath);
    }
    await _repo.deletePdf(id);
    await reload();
  }

  Future<void> saveFlashcard(FlashcardDraft card) async {
    await _repo.upsertFlashcard(card);
    await reload();
  }

  Future<void> deleteFlashcard(String id) async {
    await _repo.deleteFlashcard(id);
    await reload();
  }

  Future<void> saveReminder(AppReminder reminder) async {
    await _repo.upsertReminder(reminder);
    await reload();
  }

  Future<void> deleteReminder(String id) async {
    await _repo.deleteReminder(id);
    await NotificationService.instance.cancel(id);
    await reload();
  }

  Future<void> saveNotificationPrefs(NotificationPrefs prefs) async {
    await _repo.saveNotificationPrefs(prefs);
    await reload();
  }
}
