import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/utils/attendance_math.dart';
import 'package:chem_buddy/data/models/models.dart';
import 'package:chem_buddy/data/repositories/chem_repository.dart';
import 'package:chem_buddy/data/services/export_service.dart';
import 'package:chem_buddy/data/services/reaction_mechanism_service.dart';

// Simple mock repository for testing export generation without Hive dependencies
class MockChemRepository implements ChemRepository {
  final List<Subject> _subjects = const [
    Subject(
      id: 'sub_org',
      name: 'Advanced Organic Chemistry',
      code: 'CH-501',
      teacher: 'Dr. Kambar',
      colorHex: 0xFF8B5CF6,
    ),
    Subject(
      id: 'sub_inorg',
      name: 'Coordination Chemistry',
      code: 'CH-502',
      teacher: 'Prof. Sharma',
      colorHex: 0xFF38BDF8,
    ),
  ];

  @override
  List<Subject> subjects() => _subjects;

  final List<AttendanceRecord> _attendance = [
    AttendanceRecord(
      id: 'rec_1',
      subjectId: 'sub_org',
      date: DateTime(2026, 9, 1),
      status: AttendanceStatus.present,
    ),
    AttendanceRecord(
      id: 'rec_2',
      subjectId: 'sub_org',
      date: DateTime(2026, 9, 2),
      status: AttendanceStatus.absent,
    ),
    AttendanceRecord(
      id: 'rec_3',
      subjectId: 'sub_inorg',
      date: DateTime(2026, 9, 1),
      status: AttendanceStatus.excused,
      note: 'Inter-collegiate seminar (OD)',
    ),
  ];

  @override
  List<AttendanceRecord> attendance() => _attendance;

  @override
  SubjectAttendanceStats overallStats() {
    return const SubjectAttendanceStats(
      present: 18,
      absent: 3,
      postponed: 1,
      excused: 2,
    );
  }

  @override
  SubjectAttendanceStats statsFor(String subjectId) {
    if (subjectId == 'sub_org') {
      return const SubjectAttendanceStats(present: 10, absent: 2, postponed: 1, excused: 1);
    }
    return const SubjectAttendanceStats(present: 8, absent: 1, postponed: 0, excused: 1);
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final mockProfile = UserProfile(
    fullName: 'Prajwal A Kambar',
    registerNumber: 'MScCHEM2026001',
    university: 'Bangalore University',
    semester: 3,
    email: 'prajwal@chembuddy.edu',
  );

  final mockRepo = MockChemRepository();
  late Directory testDir;

  setUp(() {
    testDir = Directory.systemTemp.createTempSync('chem_export_test_');
  });

  tearDown(() {
    if (testDir.existsSync()) {
      testDir.deleteSync(recursive: true);
    }
  });

  group('ExportService Academic & Reaction Export Tests', () {
    test('generateAttendanceCsv produces Excel-compatible CSV with UTF-8 BOM', () async {
      final file = await ExportService.instance.generateAttendanceCsv(
        profile: mockProfile,
        repository: mockRepo,
        outputDirectory: testDir,
      );

      expect(file.existsSync(), isTrue);
      final rawBytes = await file.readAsBytes();
      // Verify UTF-8 BOM (0xEF, 0xBB, 0xBF) for Microsoft Excel compatibility
      expect(rawBytes[0], 0xEF);
      expect(rawBytes[1], 0xBB);
      expect(rawBytes[2], 0xBF);

      final content = await file.readAsString();
      expect(content.contains('Prajwal A Kambar'), isTrue);
      expect(content.contains('MScCHEM2026001'), isTrue);
      expect(content.contains('Advanced Organic Chemistry'), isTrue);
      expect(content.contains('Coordination Chemistry'), isTrue);
      expect(content.contains('Inter-collegiate seminar (OD)'), isTrue);
    });

    test('generateAttendancePdf produces valid PDF with headers, KPIs, and subject table', () async {
      final file = await ExportService.instance.generateAttendancePdf(
        profile: mockProfile,
        repository: mockRepo,
        outputDirectory: testDir,
      );

      expect(file.existsSync(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(1000));
      // PDF file magic bytes: %PDF-
      expect(bytes[0], 0x25); // %
      expect(bytes[1], 0x50); // P
      expect(bytes[2], 0x44); // D
      expect(bytes[3], 0x46); // F
    });

    test('generateReactionPdf produces publication-grade single reaction monograph', () async {
      final sn1 = ReactionMechanismService.instance.find('sn1')!;
      final file = await ExportService.instance.generateReactionPdf(
        singleReaction: sn1,
        outputDirectory: testDir,
      );

      expect(file.existsSync(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(1000));
      expect(bytes[0], 0x25); // %PDF-
    });

    test('generateReactionPdf produces master compendium for all 21 reactions', () async {
      final allMechanisms = ReactionMechanismService.instance.mechanisms;
      expect(allMechanisms.length, 21);

      final file = await ExportService.instance.generateReactionPdf(
        reactions: allMechanisms,
        outputDirectory: testDir,
      );

      expect(file.existsSync(), isTrue);
      final bytes = await file.readAsBytes();
      expect(bytes.length, greaterThan(10000));
    });

    test('generateReactionsCsv produces tabular spreadsheet containing all 21 reactions', () async {
      final allMechanisms = ReactionMechanismService.instance.mechanisms;
      final file = await ExportService.instance.generateReactionsCsv(
        mechanisms: allMechanisms,
        outputDirectory: testDir,
      );

      expect(file.existsSync(), isTrue);
      final rawBytes = await file.readAsBytes();
      expect(rawBytes[0], 0xEF);
      expect(rawBytes[1], 0xBB);
      expect(rawBytes[2], 0xBF);

      final content = await file.readAsString();
      expect(content.contains('SN1 Nucleophilic Substitution'), isTrue);
      expect(content.contains('Diels-Alder [4+2] Cycloaddition'), isTrue);
      expect(content.contains('Michael Addition'), isTrue);
      expect(content.contains('Baeyer-Villiger Oxidation'), isTrue);
      expect(content.contains('Favorskii Rearrangement'), isTrue);
      expect(content.contains('Mannich Reaction'), isTrue);
      expect(content.contains('Pinacol-Pinacolone Rearrangement'), isTrue);
      expect(content.contains('Robinson Annulation'), isTrue);
      expect(content.contains('Curtius Rearrangement'), isTrue);
      expect(content.contains('[3,3]-Cope Rearrangement'), isTrue);
      expect(content.contains('[3,3]-Claisen Sigmatropic Rearrangement'), isTrue);
    });
  });
}
