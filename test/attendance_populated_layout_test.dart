import 'package:chem_buddy/core/utils/attendance_math.dart';
import 'package:chem_buddy/data/local/local_store.dart';
import 'package:chem_buddy/data/models/library_models.dart';
import 'package:chem_buddy/data/models/models.dart';
import 'package:chem_buddy/data/models/timetable_entry.dart';
import 'package:chem_buddy/data/remote/notification_service.dart';
import 'package:chem_buddy/data/remote/supabase_service.dart';
import 'package:chem_buddy/data/repositories/chem_repository.dart';
import 'package:chem_buddy/presentation/providers/app_providers.dart';
import 'package:chem_buddy/presentation/screens/attendance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

const _subject = Subject(
  id: 'populated',
  name: 'Advanced Organic Spectroscopy and Molecular Structure Elucidation',
  code: 'MSc-CHEMISTRY-SEMESTER-III',
);
const _slot = TimetableSlot(
  id: 'populated-slot',
  subjectId: 'populated',
  weekday: 1,
  startMinutes: 600,
  endMinutes: 660,
  room: 'Room 312 Advanced Spectroscopy Laboratory',
);
const _entry = TimetableEntry(
  id: 'populated-slot',
  dayOfWeek: 'Monday',
  startTime: '10:00 AM',
  endTime: '11:00 AM',
  subjectCode: 'MSc-CHEMISTRY-SEMESTER-III',
  subject: 'Advanced Organic Spectroscopy and Molecular Structure Elucidation',
  teacherName: 'Professor Prajwal A Kambar and Department Faculty',
  room: 'Room 312 Advanced Spectroscopy Laboratory',
);
final _records = [
  AttendanceRecord(
    id: 'populated-record',
    subjectId: 'populated',
    slotId: 'populated-slot',
    date: DateTime.now(),
    status: AttendanceStatus.excused,
    markedAt: DateTime.now(),
  ),
];

class _PopulatedController extends AppController {
  @override
  AppState build() => AppState(
    profile: const UserProfile(isGuest: true),
    subjects: const [_subject],
    attendance: _records,
    slots: const [_slot],
    entries: const [_entry],
    events: const [],
    notes: const [],
    pdfs: const [],
    flashcards: const [],
    reminders: const [],
    notificationPrefs: const NotificationPrefs(),
  );
}

class _PopulatedRepository extends ChemRepository {
  _PopulatedRepository()
    : super(
        store: LocalStore(),
        remote: SupabaseService.instance,
        notifications: NotificationService.instance,
      );
  @override
  SubjectAttendanceStats overallStats() => const SubjectAttendanceStats(
    present: 28,
    absent: 12,
    postponed: 2,
    excused: 3,
  );
  @override
  SubjectAttendanceStats statsFor(String subjectId) => overallStats();
  @override
  List<double> lastSevenDayPercents() => [0, 50, 66.7, 75, 100, 0, 70];
  @override
  List<TimetableSlot> slotsFor(DateTime day) => [_slot];
  @override
  int remainingClasses({String? subjectId}) => 20;
  @override
  TimetableSlot? nextUpcomingSlot(DateTime now) => _slot;
  @override
  AttendanceRecord? recordFor({
    required String slotId,
    required DateTime date,
  }) => _records.first;
  @override
  List<AttendanceRecord> attendance() => _records;
  @override
  int streak() => 12;
}

void main() {
  for (final size in [const Size(360, 800), const Size(320, 900)]) {
    testWidgets('populated attendance renders data at ${size.width}px', (
      tester,
    ) async {
      await tester.binding.setSurfaceSize(size);
      final previousHandler = FlutterError.onError;
      FlutterError.onError = (details) {
        FlutterError.dumpErrorToConsole(details, forceReport: true);
        previousHandler!(details);
      };
      addTearDown(() => FlutterError.onError = previousHandler);
      addTearDown(() => tester.binding.setSurfaceSize(null));
      await tester.pumpWidget(
        ProviderScope(
          overrides: [
            appControllerProvider.overrideWith(_PopulatedController.new),
            chemRepositoryProvider.overrideWithValue(_PopulatedRepository()),
          ],
          child: MaterialApp(
            builder: (context, child) => MediaQuery(
              data: MediaQuery.of(context).copyWith(
                textScaler: TextScaler.linear(size.width == 320 ? 1.4 : 1),
              ),
              child: child!,
            ),
            home: const Scaffold(body: AttendanceScreen(embedded: true)),
          ),
        ),
      );
      await tester.pumpAndSettle();
      final simulator = find.byTooltip('What-If Simulator');
      await tester.ensureVisible(simulator);
      await tester.pumpAndSettle();
      await tester.tap(simulator);
      await tester.pumpAndSettle();
      for (var i = 0; i < 12; i++) {
        await tester.drag(find.byType(ListView).first, const Offset(0, -450));
        await tester.pumpAndSettle();
      }
    });
  }
}
