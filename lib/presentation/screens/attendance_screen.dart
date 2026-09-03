import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../providers/app_providers.dart';
import 'smart_flashcards_generate_screen.dart';
import 'smart_flashcards_hub.dart';

class AttendanceScreen extends ConsumerWidget {
  final bool embedded;

  const AttendanceScreen({super.key, this.embedded = false});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final repo = ref.watch(chemRepositoryProvider);
    final overall = repo.overallStats();
    final week = repo.lastSevenDayPercents();
    final today = DateTime.now();
    final slots = repo.slotsFor(today);
    final remaining = repo.remainingClasses();
    final projected = overall.projectedPercent(remaining: remaining);

    return ListView(
      padding: EdgeInsets.fromLTRB(20, embedded ? 4 : 12, 20, 100),
      children: [
        if (!embedded) ...[
          const Text('Attendance', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
          const SizedBox(height: 12),
        ],

        GlowCard(
          child: Row(
            children: [
              CircularAttendance(percent: overall.percent, size: 120),
              const SizedBox(width: 12),
              Expanded(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    _StatChip(label: 'Can skip', value: '${overall.canSkip}'),
                    _StatChip(label: 'Streak', value: '${repo.streak()}'),
                    _StatChip(label: 'Projected', value: '${projected.round()}%'),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('This week'),
        GlowCard(
          child: SizedBox(
            height: 160,
            child: BarChart(
              BarChartData(
                gridData: const FlGridData(show: false),
                borderData: FlBorderData(show: false),
                titlesData: FlTitlesData(
                  leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (v, _) {
                        final day = DateTime.now().subtract(Duration(days: 6 - v.toInt()));
                        return Text(DateFormat('E').format(day), style: const TextStyle(fontSize: 10, color: AppColors.textMuted));
                      },
                    ),
                  ),
                ),
                barGroups: [
                  for (var i = 0; i < week.length; i++)
                    BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                          toY: week[i],
                          width: 14,
                          borderRadius: BorderRadius.circular(6),
                          color: AppColors.attendanceColor(week[i] == 0 ? 75 : week[i]),
                        ),
                      ],
                    ),
                ],
                maxY: 100,
              ),
            ),
          ),
        ),
        const SectionTitle("Mark today's classes"),
        if (slots.isEmpty)
          const GlowCard(
            child: Text(
              'No classes on today’s timetable. Scan or add classes in the Classes tab — attendance follows your real schedule, not a fixed two-class day.',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
        ...slots.map((slot) {
          final subject = state.subjects.where((s) => s.id == slot.subjectId).firstOrNull;
          final entry = state.entries.where((e) => e.id == slot.id).firstOrNull;
          final current = repo.recordFor(slotId: slot.id, date: today);
          final title = subject?.name ?? (entry != null && entry.displayName.isNotEmpty ? entry.displayName : 'Class');
          final timeStr = slot.timeLabel.isNotEmpty ? slot.timeLabel : (entry != null ? '${entry.startTime} – ${entry.endTime}' : '');
          final roomStr = slot.room.isNotEmpty ? slot.room : (entry?.room ?? '');

          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                      ),
                      if (current != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: (current.status == AttendanceStatus.present
                                    ? AppColors.present
                                    : current.status == AttendanceStatus.absent
                                        ? AppColors.absent
                                        : AppColors.warning)
                                .withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            current.status == AttendanceStatus.present
                                ? '✓ Marked Present'
                                : current.status == AttendanceStatus.absent
                                    ? '✗ Marked Absent'
                                    : '⏸ Postponed',
                            style: TextStyle(
                              color: current.status == AttendanceStatus.present
                                  ? AppColors.present
                                  : current.status == AttendanceStatus.absent
                                      ? AppColors.absent
                                      : AppColors.warning,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    [timeStr, if (roomStr.isNotEmpty) 'Room: $roomStr'].where((s) => s.isNotEmpty).join(' • '),
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (final status in AttendanceStatus.values)
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.only(right: 6),
                            child: _StatusButton(
                              status: status,
                              selected: current?.status == status,
                              onTap: () => ref.read(appControllerProvider.notifier).mark(
                                    subjectId: subject?.id ?? slot.subjectId,
                                    date: today,
                                    status: status,
                                    slotId: slot.id,
                                  ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  if (current?.markedAt != null) ...[
                    const SizedBox(height: 8),
                    Text(
                      'Marked at: ${DateFormat('h:mm a').format(current!.markedAt!)}',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontStyle: FontStyle.italic),
                    ),
                  ],
                ],
              ),
            ),
          );
        }),
        const SectionTitle('Subject breakdown'),
        if (state.subjects.isEmpty)
          const GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Icon(Icons.book, size: 48, color: AppColors.purpleBright),
                SizedBox(height: 12),
                Text('No subjects added.', textAlign: TextAlign.center, style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
                SizedBox(height: 8),
                Text('Add subjects to start tracking attendance.', textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary)),
              ],
            ),
          ),
        ...state.subjects.map((s) {
          final stats = repo.statsFor(s.id);
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(child: Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700))),
                      Text('${stats.percent.round()}%', style: TextStyle(color: AppColors.attendanceColor(stats.percent), fontWeight: FontWeight.w800)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    stats.percent >= 75
                        ? 'You can skip ${stats.canSkip} more class${stats.canSkip == 1 ? '' : 'es'}.'
                        : 'Attend ${stats.attendToReach75} more to reach 75%.',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 13),
                  ),
                  Text(
                    'Projected if you attend remaining ${repo.remainingClasses(subjectId: s.id)} classes: ${stats.projectedPercent(remaining: repo.remainingClasses(subjectId: s.id)).round()}%',
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          foregroundColor: AppColors.purple,
                          side: const BorderSide(color: AppColors.purple),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsHub())),
                        icon: const Icon(Icons.menu_book, size: 16),
                        label: const Text('Study', style: TextStyle(fontSize: 12)),
                      ),
                      const SizedBox(width: 8),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          foregroundColor: AppColors.purple,
                          side: const BorderSide(color: AppColors.purple),
                        ),
                        onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SmartFlashcardsGenerateScreen(prefilledTopic: s.name))),
                        icon: const Icon(Icons.style, size: 16),
                        label: const Text('Flashcards', style: TextStyle(fontSize: 12)),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        children: [
          Text(value, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16)),
          Text(label, style: const TextStyle(color: AppColors.textMuted, fontSize: 11)),
        ],
      ),
    );
  }
}

class _StatusButton extends StatelessWidget {
  const _StatusButton({required this.status, required this.selected, required this.onTap});
  final AttendanceStatus status;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (status) {
      AttendanceStatus.present => (AppColors.present, Icons.check_circle_outline, 'Present'),
      AttendanceStatus.absent => (AppColors.absent, Icons.cancel_outlined, 'Absent'),
      AttendanceStatus.postponed => (AppColors.warning, Icons.pause_circle_outline, 'Postponed'),
    };
    return Material(
      color: selected ? color.withValues(alpha: 0.2) : AppColors.surfaceElevated,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          if (status == AttendanceStatus.absent) {
            AppHaptics.warn();
          } else {
            AppHaptics.tap();
          }
          onTap();
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: selected ? color : AppColors.border.withValues(alpha: 0.6),
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: selected ? color : AppColors.textMuted),
              const SizedBox(width: 4),
              Text(
                label,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  color: selected ? color : AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
