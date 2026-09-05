import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/utils/attendance_math.dart';
import 'package:chem_buddy/data/models/models.dart';

void main() {
  group('Smart Attendance Math & Multi-Target Tests', () {
    test('canSkipForTarget calculates accurate buffer across 75%, 80%, 85%, 90%', () {
      const stats = SubjectAttendanceStats(present: 20, absent: 0, postponed: 0);

      // 75% target: (2000 - 75*20) / 75 = 500 / 75 = 6
      expect(stats.canSkipForTarget(75.0), 6);

      // 80% target: (2000 - 80*20) / 80 = 400 / 80 = 5
      expect(stats.canSkipForTarget(80.0), 5);

      // 85% target: (2000 - 85*20) / 85 = 300 / 85 = 3
      expect(stats.canSkipForTarget(85.0), 3);

      // 90% target: (2000 - 90*20) / 90 = 200 / 90 = 2
      expect(stats.canSkipForTarget(90.0), 2);
    });

    test('attendToReachTarget calculates exact recovery roadmap', () {
      // 10 present out of 20 counted = 50%
      const stats = SubjectAttendanceStats(present: 10, absent: 10, postponed: 0);

      // To reach 75%: (75*20 - 100*10) / 25 = 500 / 25 = 20 classes
      expect(stats.attendToReachTarget(75.0), 20);

      // To reach 80%: (80*20 - 100*10) / 20 = 600 / 20 = 30 classes
      expect(stats.attendToReachTarget(80.0), 30);

      // Already safe
      const safe = SubjectAttendanceStats(present: 18, absent: 2, postponed: 0); // 90%
      expect(safe.attendToReachTarget(75.0), 0);
      expect(safe.attendToReachTarget(85.0), 0);
    });

    test('riskTier classifies critical, warning, safe, and exemplary standing', () {
      const criticalStats = SubjectAttendanceStats(present: 5, absent: 5, postponed: 0); // 50%
      expect(criticalStats.riskTier(75.0), AttendanceRiskTier.critical);

      const warningStats = SubjectAttendanceStats(present: 14, absent: 6, postponed: 0); // 70%
      expect(warningStats.riskTier(75.0), AttendanceRiskTier.warning);

      const safeStats = SubjectAttendanceStats(present: 16, absent: 4, postponed: 0); // 80%
      expect(safeStats.riskTier(75.0), AttendanceRiskTier.safe);

      const honorsStats = SubjectAttendanceStats(present: 19, absent: 1, postponed: 0); // 95%
      expect(honorsStats.riskTier(75.0), AttendanceRiskTier.exemplary);
    });

    test('simulateFuture dynamically calculates predicted standing and delta', () {
      const stats = SubjectAttendanceStats(present: 15, absent: 5, postponed: 0); // 75.0%

      // If student attends next 5 and misses 0: (15 + 5) / (20 + 5) = 20/25 = 80.0%
      final simulated = stats.simulateFuture(attendAdditional: 5, missAdditional: 0);
      expect(simulated, closeTo(80.0, 0.01));

      // If student attends 0 and skips 4: 15 / (20 + 4) = 15/24 = 62.5%
      final dropped = stats.simulateFuture(attendAdditional: 0, missAdditional: 4);
      expect(dropped, closeTo(62.5, 0.01));
    });

    test('Excused / On-Duty classes are excluded from counted denominator without penalizing student', () {
      // 10 present, 2 absent, 5 excused (symposium, medical)
      const stats = SubjectAttendanceStats(present: 10, absent: 2, postponed: 1, excused: 5);

      expect(stats.counted, 12); // only present + absent
      expect(stats.total, 18);   // counted + postponed + excused
      expect(stats.percent, closeTo(83.33, 0.01)); // (10/12)*100
      expect(stats.canSkipForTarget(75.0), 1);
    });

    test('AttendanceMath helpers provide proper threshold checks and descriptive labels', () {
      expect(AttendanceMath.isSafe(75.0), isTrue);
      expect(AttendanceMath.isSafe(74.9), isFalse);
      expect(AttendanceMath.isSafe(80.0, 85.0), isFalse);
      expect(AttendanceMath.isSafe(86.0, 85.0), isTrue);

      expect(AttendanceMath.statusLabel(55.0), 'Critical Risk');
      expect(AttendanceMath.statusLabel(70.0), 'Needs Recovery');
      expect(AttendanceMath.statusLabel(78.0), 'Safe Margin');
      expect(AttendanceMath.statusLabel(92.0), 'Exemplary Attendance');
    });

    test('AttendanceRecord serializes and deserializes excused status with note', () {
      final record = AttendanceRecord(
        id: 'rec_1',
        subjectId: 'sub_msc',
        date: DateTime(2026, 9, 5),
        status: AttendanceStatus.excused,
        slotId: 'slot_1',
        markedAt: DateTime(2026, 9, 5, 10, 30),
        note: 'University Chemistry Symposium',
      );

      final json = record.toJson();
      expect(json['status'], 'excused');
      expect(json['note'], 'University Chemistry Symposium');

      final fromJson = AttendanceRecord.fromJson(json);
      expect(fromJson.status, AttendanceStatus.excused);
      expect(fromJson.note, 'University Chemistry Symposium');
    });
  });
}
