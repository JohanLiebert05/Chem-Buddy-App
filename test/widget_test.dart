import 'package:flutter_test/flutter_test.dart';

import 'package:chem_buddy/core/utils/attendance_math.dart';
import 'package:chem_buddy/data/models/library_models.dart';
import 'package:chem_buddy/data/models/models.dart';
import 'package:chem_buddy/data/models/timetable_entry.dart';
import 'package:chem_buddy/data/services/global_search.dart';
import 'package:chem_buddy/data/services/timetable_parser_service.dart';
import 'package:chem_buddy/presentation/providers/app_providers.dart';

void main() {
  test('postponed classes are excluded from percentage', () {
    const stats = SubjectAttendanceStats(present: 3, absent: 1, postponed: 10);
    expect(stats.counted, 4);
    expect(stats.percent, 75);
  });

  test('attend-more formula reaches 75 percent', () {
    const stats = SubjectAttendanceStats(present: 2, absent: 2, postponed: 0);
    expect(stats.percent, 50);
    expect(stats.attendToReach75, 4);
  });

  test('timetable parser extracts day, time, code, and teacher', () {
    final entries = TimetableParserService().parse('''
Monday
OCH501 10:00 AM - 11:00 AM Dr Sharma
Tuesday
CH 301 OC 2:00 PM - 3:00 PM Prof Rao
''');
    expect(entries.length, 2);
    expect(entries[0].dayOfWeek, 'Monday');
    expect(entries[0].subjectCode.contains('OCH501'), true);
    expect(entries[0].teacherName.contains('Sharma'), true);
    expect(entries[1].dayOfWeek, 'Tuesday');
  });

  test('timetable parser extracts room and lab type', () {
    final entries = TimetableParserService().parse('''
Monday
OCH501 10:00 AM - 12:00 PM Lab Room B2
''');
    expect(entries.length, 1);
    expect(entries[0].type, 'lab');
    expect(entries[0].room.toLowerCase().contains('room'), true);
  });

  test('global search matches pdfs, notes, and timetable', () {
    final state = AppState(
      profile: const UserProfile(),
      subjects: const [Subject(id: '1', name: 'Organic Chemistry', code: 'OCH')],
      attendance: const [],
      slots: const [],
      entries: const [
        TimetableEntry(
          id: 't1',
          dayOfWeek: 'Monday',
          startTime: '9:00 AM',
          endTime: '10:00 AM',
          subjectCode: 'OCH',
          subject: 'Organic Chemistry',
        ),
      ],
      events: const [],
      notes: [
        NoteItem(id: 'n1', title: 'SN1 mechanism', body: 'carbocation', updatedAt: DateTime(2026, 1, 1)),
      ],
      pdfs: [
        PdfDoc(
          id: 'p1',
          filename: 'sn1.pdf',
          displayName: 'Reaction Mechanisms',
          subjectId: '1',
          localPath: '/tmp/x.pdf',
          dateAdded: DateTime(2026, 1, 1),
        ),
      ],
      flashcards: const [],
      reminders: const [],
      notificationPrefs: const NotificationPrefs(),
    );
    expect(GlobalSearch.query(state, 'SN1').any((h) => h.kind == 'Note'), true);
    expect(GlobalSearch.query(state, 'Organic').any((h) => h.kind == 'Timetable' || h.kind == 'Subject'), true);
    expect(GlobalSearch.query(state, 'Mechanisms').any((h) => h.kind == 'PDF'), true);
  });
}
