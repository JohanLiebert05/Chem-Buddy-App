import 'package:flutter_test/flutter_test.dart';

import 'package:chem_buddy/core/utils/attendance_math.dart';
import 'package:chem_buddy/data/services/timetable_parser_service.dart';

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
}
