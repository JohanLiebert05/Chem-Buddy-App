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

    test('Dr. Manmohan Singh BCU Organic Timetable preset has complete weekly slots & faculty', () {
      final organicEntries = TimetablePreset.organic.entries;
      expect(organicEntries.length, greaterThanOrEqualTo(16));
      expect(TimetablePreset.organic.institution, contains('Bengaluru City University'));
      expect(TimetablePreset.organic.effectiveDate, equals('w.e.f. 24-08-2026'));

      // Check specific faculty and classes
      final mondayLab = organicEntries.firstWhere((e) => e.dayOfWeek == 'Monday' && e.type == 'lab');
      expect(mondayLab.teacherName, contains('Prof. Dr. K. Shivashankar'));
      expect(mondayLab.teacherName, contains('Dr. Roopesh Kumar L'));
      expect(mondayLab.startTime, equals('01:30 PM'));
      expect(mondayLab.endTime, equals('05:30 PM'));

      final tuesday303 = organicEntries.firstWhere((e) => e.dayOfWeek == 'Tuesday' && e.startTime == '10:00 AM');
      expect(tuesday303.subjectCode, equals('OCH 303'));
      expect(tuesday303.teacherName, contains('Prof. Dr. Hari Prasad S'));

      final saturdayOE = organicEntries.firstWhere((e) => e.dayOfWeek == 'Saturday');
      expect(saturdayOE.subjectCode, equals('CH-304 OE'));
    });

    test('Dr. Manmohan Singh BCU Inorganic Timetable preset has complete weekly slots & faculty', () {
      final inorganicEntries = TimetablePreset.inorganic.entries;
      expect(inorganicEntries.length, greaterThanOrEqualTo(16));
      expect(TimetablePreset.inorganic.institution, contains('Bengaluru City University'));
      expect(TimetablePreset.inorganic.effectiveDate, equals('w.e.f. 24-08-2026'));

      // Check specific faculty and classes
      final mondayLab = inorganicEntries.firstWhere((e) => e.dayOfWeek == 'Monday' && e.type == 'lab');
      expect(mondayLab.teacherName, contains('Prof. Dr. P. R. Chetana'));
      expect(mondayLab.teacherName, contains('Dr. Mary Anne Anitha'));

      final monday302 = inorganicEntries.firstWhere((e) => e.dayOfWeek == 'Monday' && e.startTime == '11:00 AM');
      expect(monday302.subjectCode, equals('ICH 302'));
      expect(monday302.teacherName, contains('Prof. M Pandurangappa'));

      final fridaySeminar = inorganicEntries.firstWhere((e) => e.dayOfWeek == 'Friday' && e.startTime == '01:30 PM');
      expect(fridaySeminar.subjectCode, equals('SEMINAR'));
      expect(fridaySeminar.subject, contains('Seminar'));
    });
  });
}

