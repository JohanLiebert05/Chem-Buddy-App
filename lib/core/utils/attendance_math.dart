enum AttendanceRiskTier {
  critical,
  warning,
  safe,
  exemplary,
}

extension AttendanceRiskTierX on AttendanceRiskTier {
  String get displayName {
    switch (this) {
      case AttendanceRiskTier.critical:
        return 'Critical Risk';
      case AttendanceRiskTier.warning:
        return 'Warning (Low)';
      case AttendanceRiskTier.safe:
        return 'Safe Standing';
      case AttendanceRiskTier.exemplary:
        return 'Exemplary Standing';
    }
  }
}

class SubjectAttendanceStats {
  const SubjectAttendanceStats({
    required this.present,
    required this.absent,
    required this.postponed,
    this.excused = 0,
  });

  final int present;
  final int absent;
  final int postponed;
  final int excused;

  int get counted => present + absent;
  int get total => counted + postponed + excused;

  double get percent => counted == 0 ? 0.0 : (present / counted) * 100.0;

  /// Default 75% threshold skips
  int get canSkip => canSkipForTarget(75.0);

  /// Default 75% threshold needed
  int get attendToReach75 => attendToReachTarget(75.0);

  /// Calculate classes that can be safely skipped while staying >= targetPercent
  int canSkipForTarget(double targetPercent) {
    if (counted == 0) return 0;
    final t = targetPercent.round();
    if (t <= 0 || t >= 100) return 0;
    final num = (100 * present) - (t * counted);
    if (num <= 0) return 0;
    return (num / t).floor().clamp(0, 999);
  }

  /// Calculate consecutive classes required to reach targetPercent
  int attendToReachTarget(double targetPercent) {
    if (percent >= targetPercent) return 0;
    final t = targetPercent.round();
    if (t >= 100) {
      return absent == 0 ? 0 : 999;
    }
    final num = (t * counted) - (100 * present);
    final denom = 100 - t;
    if (denom <= 0 || num <= 0) return 0;
    return (num / denom).ceil();
  }

  /// Risk Tier classification
  AttendanceRiskTier riskTier([double target = 75.0]) {
    if (percent < target - 10) return AttendanceRiskTier.critical;
    if (percent < target) return AttendanceRiskTier.warning;
    if (percent < target + 10) return AttendanceRiskTier.safe;
    return AttendanceRiskTier.exemplary;
  }

  /// Dynamic What-If Simulation
  double simulateFuture({
    required int attendAdditional,
    required int missAdditional,
  }) {
    final newPresent = present + attendAdditional;
    final newCounted = counted + attendAdditional + missAdditional;
    if (newCounted == 0) return 0.0;
    return (newPresent / newCounted) * 100.0;
  }

  double projectedPercent({required int remaining, bool attendAll = true}) {
    if (remaining <= 0) return percent;
    final extraPresent = attendAll ? remaining : 0;
    final newPresent = present + extraPresent;
    final newCounted = counted + remaining;
    if (newCounted == 0) return 0.0;
    return (newPresent / newCounted) * 100.0;
  }
}

class AttendanceMath {
  static const threshold = 75.0;

  static bool isSafe(double percent, [double customThreshold = threshold]) =>
      percent >= customThreshold;

  static String statusLabel(double percent, [double customThreshold = threshold]) {
    if (percent < customThreshold - 10) return 'Critical Risk';
    if (percent < customThreshold) return 'Needs Recovery';
    if (percent < customThreshold + 10) return 'Safe Margin';
    return 'Exemplary Attendance';
  }
}
