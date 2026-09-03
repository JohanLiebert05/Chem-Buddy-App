import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/timetable_parser_service.dart';

void main() {
  group('University 2D Grid Timetable Parser Tests', () {
    const rawUniversityTimetable = '''
BANGALORE UNIVERSITY
CENTRAL COLLEGE CAMPUS, BENGALURU - 560001
DEPARTMENT OF CHEMISTRY
M.Sc. Chemistry III Semester Timetable 2024-25
Effective from: 01-08-2024

DAY       | 10:00 - 11:00 | 11:00 - 12:00 | 12:00 - 01:00 | 02:00 - 05:00 (PRACTICAL)
---------------------------------------------------------------------------------------
MONDAY    | 301           | 302           | 303           | CH-305 (KSS + RK)
          | KSS           | HP            | RK            | Inorganic Chemistry Lab
TUESDAY   | 302           | 301           | 303           | CH-306 (HP + KSS)
          | HP            | KSS           | RK            | Organic Chemistry Lab
WEDNESDAY | 303           | 302           | 301           | CH-305 (RK + HP)
          | RK            | HP            | KSS           | Physical Chemistry Lab
THURSDAY  | 301           | 303           | 302           | CH-306 (KSS + HP)
          | KSS           | RK            | HP            | Practical Session
FRIDAY    | 302           | 301           | 303           | SEMINAR / LIBRARY
          | HP            | KSS           | RK            | Literature Review
SATURDAY  | CH-3040E OPEN ELECTIVE FULL DAY               |

Legend / Faculty Details:
KSS – Prof. Dr. K. Shivashankar
HP – Dr. Hari Prasad
RK – Dr. R. Kundu
SMR – Dr. S. M. Roopa
''';

    test('Extracts 15-20+ valid slots from university schedule', () {
      final parser = TimetableParserService();
      final result = parser.parseStructured(rawUniversityTimetable);

      // Expected: Monday-Friday (3 theory + 1 lab = 4 per day * 5 = 20) + Saturday (1 full day elective) = 21 slots!
      expect(result.entries.length, greaterThanOrEqualTo(15));
      expect(result.entries.length, lessThanOrEqualTo(24));
    });

    test('Extracts institutional header metadata', () {
      final parser = TimetableParserService();
      final result = parser.parseStructured(rawUniversityTimetable);

      expect(result.metadata.institution.toUpperCase().contains('BANGALORE UNIVERSITY'), isTrue);
      expect(result.metadata.department.toUpperCase().contains('CHEMISTRY'), isTrue);
      expect(result.metadata.semester.contains('III Semester'), isTrue);
      expect(result.metadata.effectiveDate, equals('01-08-2024'));
    });

    test('Parses faculty legend and auto-fills Teacher names', () {
      final parser = TimetableParserService();
      final result = parser.parseStructured(rawUniversityTimetable);

      expect(result.metadata.facultyLegend['KSS'], equals('Prof. Dr. K. Shivashankar'));
      expect(result.metadata.facultyLegend['HP'], equals('Dr. Hari Prasad'));
      expect(result.metadata.facultyLegend['RK'], equals('Dr. R. Kundu'));

      // Check that entries have full resolved teacher names, not just raw initials
      final kssEntries = result.entries.where((e) => e.teacherName.contains('Prof. Dr. K. Shivashankar')).toList();
      expect(kssEntries.isNotEmpty, isTrue, reason: 'KSS initials should be resolved to full name');

      final hpEntries = result.entries.where((e) => e.teacherName.contains('Dr. Hari Prasad')).toList();
      expect(hpEntries.isNotEmpty, isTrue, reason: 'HP initials should be resolved to full name');
    });

    test('Parses combined practical codes as joint lab sessions', () {
      final parser = TimetableParserService();
      final result = parser.parseStructured(rawUniversityTimetable);

      final mondayLab = result.entries.firstWhere(
        (e) => e.dayOfWeek == 'Monday' && e.type == 'lab',
      );
      expect(mondayLab.subjectCode, contains('CH-305'));
      expect(mondayLab.startTime, equals('02:00 PM'));
      expect(mondayLab.endTime, equals('05:00 PM'));
      expect(mondayLab.teacherName, contains('&'));
      expect(mondayLab.teacherName, contains('Prof. Dr. K. Shivashankar'));
      expect(mondayLab.teacherName, contains('Dr. R. Kundu'));
    });

    test('Parses Saturday as an Open Elective full-day session', () {
      final parser = TimetableParserService();
      final result = parser.parseStructured(rawUniversityTimetable);

      final saturdaySlot = result.entries.firstWhere((e) => e.dayOfWeek == 'Saturday');
      expect(saturdaySlot.subjectCode, equals('CH-3040E'));
      expect(saturdaySlot.subject, contains('Open Elective'));
    });

    test('Parses Friday afternoon seminar/library slot', () {
      final parser = TimetableParserService();
      final result = parser.parseStructured(rawUniversityTimetable);

      final fridayAfternoon = result.entries.firstWhere(
        (e) => e.dayOfWeek == 'Friday' && e.startTime == '02:00 PM',
      );
      expect(fridayAfternoon.subject, contains('Seminar'));
    });
  });
}
