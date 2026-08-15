class SubjectAttendanceStats {
  const SubjectAttendanceStats({
    required this.present,
    required this.absent,
    required this.postponed,
  });

  final int present;
  final int absent;
  final int postponed;

  int get counted => present + absent;

  double get percent => counted == 0 ? 0 : (present / counted) * 100;

  int get canSkip {
    if (counted == 0) return 0;
    final skip = (present / 0.75) - counted;
    return skip.isFinite ? skip.floor().clamp(0, 999) : 0;
  }

  int get attendToReach75 {
    if (percent >= 75) return 0;
    final needed = (3 * counted) - (4 * present);
    return needed <= 0 ? 0 : needed;
  }

  double projectedPercent({required int remaining, bool attendAll = true}) {
    if (remaining <= 0) return percent;
    final extraPresent = attendAll ? remaining : 0;
    final newPresent = present + extraPresent;
    final newCounted = counted + remaining;
    if (newCounted == 0) return 0;
    return (newPresent / newCounted) * 100;
  }
}

class AttendanceMath {
  static const threshold = 75.0;

  static bool isSafe(double percent) => percent >= threshold;
}
