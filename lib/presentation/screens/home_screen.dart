import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/attendance_math.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../providers/app_providers.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(appControllerProvider);
    final repo = ref.watch(chemRepositoryProvider);
    final overall = repo.overallStats();
    final today = DateTime.now();
    final slots = repo.slotsFor(today);
    final upcoming = state.events.where((e) => !e.completed).take(3).toList();
    final name = state.profile.fullName.isEmpty ? 'Chemist' : state.profile.fullName.split(' ').first;

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        Row(
          children: [
            const AtomLogo(size: 42),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Hi, $name', style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  Text(
                    '${state.profile.university} · Sem ${state.profile.semester}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              backgroundColor: AppColors.surfaceElevated,
              child: Text(name.isEmpty ? 'C' : name[0].toUpperCase()),
            ),
          ],
        ),
        const SizedBox(height: 20),
        GlowCard(
          child: Row(
            children: [
              CircularAttendance(percent: overall.percent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AttendanceMath.isSafe(overall.percent)
                            ? AppColors.success.withValues(alpha: 0.15)
                            : AppColors.danger.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        AttendanceMath.isSafe(overall.percent) ? 'Safe to Bunk' : 'Better Attend',
                        style: TextStyle(
                          color: AttendanceMath.isSafe(overall.percent) ? AppColors.success : AppColors.danger,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text('Can skip ${overall.canSkip} more', style: const TextStyle(color: AppColors.textSecondary)),
                    Text('Streak ${repo.streak()} days', style: const TextStyle(color: AppColors.textSecondary)),
                    const SizedBox(height: 6),
                    const Text('Threshold 75%', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SectionTitle('Subject-wise'),
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
                  Text(s.code, style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  const SizedBox(height: 8),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: LinearProgressIndicator(
                      minHeight: 8,
                      value: (stats.percent / 100).clamp(0, 1),
                      color: AppColors.attendanceColor(stats.percent),
                      backgroundColor: Colors.white12,
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SectionTitle("Today's timetable"),
        if (slots.isEmpty)
          const GlowCard(child: Text('No classes scheduled today.', style: TextStyle(color: AppColors.textSecondary))),
        ...slots.map((slot) {
          final subject = state.subjects.cast<Subject?>().firstWhere(
                (s) => s!.id == slot.subjectId,
                orElse: () => null,
              );
          return Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              child: Row(
                children: [
                  Container(
                    width: 4,
                    height: 42,
                    decoration: BoxDecoration(
                      color: Color(subject?.colorHex ?? AppColors.purple.toARGB32()),
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(subject?.name ?? 'Class', style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text('${slot.timeLabel} · ${slot.room}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
        }),
        const SectionTitle('Upcoming'),
        if (upcoming.isEmpty)
          const GlowCard(child: Text('No tests or assignments yet.', style: TextStyle(color: AppColors.textSecondary))),
        ...upcoming.map(
          (e) => Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: GlowCard(
              child: Row(
                children: [
                  Icon(
                    e.type == EventType.test ? Icons.quiz_outlined : Icons.assignment_outlined,
                    color: AppColors.purpleBright,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700)),
                        Text(
                          '${e.type.name.toUpperCase()} · ${DateFormat('EEE, d MMM').format(e.dueDate)}',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
