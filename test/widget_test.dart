import 'package:flutter_test/flutter_test.dart';

import 'package:chem_buddy/core/utils/attendance_math.dart';

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
}
