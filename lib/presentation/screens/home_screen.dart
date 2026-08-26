import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/attendance_math.dart';
import '../../core/widgets/animated_dashboard.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../widgets/reminder_editor.dart';
import '../widgets/timetable_scanner_card.dart';
import '../../data/models/models.dart';
import '../../data/models/timetable_entry.dart';
import '../providers/app_providers.dart';
import '../screens/pdf_library_screen.dart';
import '../screens/pdf_reader_screen.dart';
import '../screens/search_screen.dart';
import '../screens/smart_flashcards_hub.dart';

import '../../data/models/study_models.dart';
import '../../data/models/smart_flashcard.dart';
import '../../data/services/daily_focus_service.dart';
import '../../data/services/study_session_service.dart';
import '../../data/local/local_store.dart';

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

    final dailyFocus = ref.watch(dailyFocusServiceProvider).computeFocus(state, repo);
    final localStore = ref.watch(localStoreProvider);
    final allSessions = localStore.all(localStore.studySessions).map((j) => StudySession.fromJson(j)).toList();
    final incompleteSession = allSessions.where((s) => !s.completed).firstOrNull;
    SmartFlashcardSet? incompleteSet;
    if (incompleteSession != null) {
      final allSets = localStore.all(localStore.smartSets).map((j) => SmartFlashcardSet.fromJson(j)).toList();
      incompleteSet = allSets.where((s) => s.id == incompleteSession.flashcardSetId).firstOrNull;
    }

    return AnimatedDashboardList(
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
            IconButton(
              tooltip: 'Search',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: 20),
        
        if (dailyFocus != null) ...[
          const SectionTitle("Today's Focus"),
          GlowCard(
            borderColor: AppColors.purpleBright,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(child: Text(dailyFocus.subjectName, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 16))),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: AppColors.purple.withValues(alpha: 0.2), borderRadius: BorderRadius.circular(12)),
                      child: Text('${dailyFocus.recommendedMinutes} min', style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(dailyFocus.reason, style: const TextStyle(color: AppColors.textSecondary)),
                if (dailyFocus.upcomingTestTitle != null) ...[
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.warning_amber_rounded, color: AppColors.warning, size: 16),
                      const SizedBox(width: 6),
                      Expanded(child: Text('Upcoming: ${dailyFocus.upcomingTestTitle}', style: const TextStyle(color: AppColors.warning, fontSize: 12, fontWeight: FontWeight.w600))),
                    ],
                  ),
                ],
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsPage())),
                    child: const Text('Start Study Session', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (incompleteSession != null && incompleteSet != null) ...[
          const SectionTitle("Continue Studying"),
          GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Flashcard Review: ${incompleteSet.title}', style: const TextStyle(fontWeight: FontWeight.w700)),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: LinearProgressIndicator(
                    value: incompleteSet.cardCount > 0 ? (incompleteSession.currentPosition / incompleteSet.cardCount).clamp(0, 1) : 0,
                    color: AppColors.blue,
                    backgroundColor: Colors.white12,
                    minHeight: 8,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.surfaceElevated, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                    onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsPage())),
                    child: const Text('Continue Session', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        if (dailyFocus == null && incompleteSession == null) ...[
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.purple, foregroundColor: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsPage())),
              child: const Text('Start Study Session', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
            ),
          ),
          const SizedBox(height: 20),
        ],

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
        const SizedBox(height: 12),
        const TimetableScannerCard(),
        _NextClassCard(state: state),
        if (state.reminders.isNotEmpty) ...[
          const SectionTitle('Upcoming reminder'),
          GlowCard(
            child: Text(
              '${state.reminders.first.title} · ${DateFormat('EEE d MMM, h:mm a').format(state.reminders.first.when)}',
              style: const TextStyle(fontWeight: FontWeight.w700),
            ),
          ),
        ],
        if (state.pdfs.isNotEmpty) ...[
          const SectionTitle('Recent PDFs'),
          ...state.pdfs.take(3).map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlowCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfReaderScreen(doc: d))),
                    child: Text(d.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
        ],
        if (state.pdfs.any((p) => p.favorite)) ...[
          const SectionTitle('Favorite PDFs'),
          ...state.pdfs.where((p) => p.favorite).take(3).map(
                (d) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: GlowCard(
                    onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfReaderScreen(doc: d))),
                    child: Text(d.displayName, style: const TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ),
        ],
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
        
        const SectionTitle('Quick access'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 3,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 1.05,
          children: [
            _QuickTile(icon: Icons.document_scanner_outlined, label: 'Scan Timetable', onTap: () => ref.read(shellTabProvider.notifier).state = 3),
            _QuickTile(icon: Icons.picture_as_pdf_outlined, label: 'Add PDF', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PdfLibraryScreen()))),
            _QuickTile(icon: Icons.folder_open_outlined, label: 'PDF Library', onTap: () => ref.read(shellTabProvider.notifier).state = 4),
            _QuickTile(
              icon: Icons.style_outlined,
              label: 'Flashcards',
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsPage())),
            ),
            _QuickTile(icon: Icons.science_outlined, label: 'Ask AI', onTap: () => ref.read(shellTabProvider.notifier).state = 1),
            _QuickTile(icon: Icons.alarm_add_outlined, label: 'Reminder', onTap: () => ReminderEditor.show(context, ref)),
            _QuickTile(icon: Icons.fact_check_outlined, label: 'Attendance', onTap: () => ref.read(shellTabProvider.notifier).state = 2),
            _QuickTile(icon: Icons.calendar_month_outlined, label: 'Classes', onTap: () => ref.read(shellTabProvider.notifier).state = 3),
            _QuickTile(icon: Icons.quiz_outlined, label: 'Tests', onTap: () => ref.read(shellTabProvider.notifier).state = 4),
          ],
        ),
        
        const SizedBox(height: 20),
        const SectionTitle('Study Streak & Stats'),
        Row(
          children: [
            Expanded(child: _StatChip(icon: Icons.local_fire_department, color: AppColors.warning, label: '${repo.streak()} Days')),
            const SizedBox(width: 8),
            Expanded(child: _StatChip(icon: Icons.style, color: AppColors.purple, label: '${localStore.all(localStore.smartSets).length} Sets')),
            const SizedBox(width: 8),
            Expanded(child: _StatChip(icon: Icons.percent, color: AppColors.success, label: '${overall.percent.round()}%')),
          ],
        ),

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
        const SizedBox(height: 10),
        GlowCard(
          child: Row(
            children: [
              const Icon(Icons.hourglass_bottom, color: AppColors.blue),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${DateTime(DateTime.now().year, DateTime.now().month + 2, 15).difference(DateTime.now()).inDays} days left in the semester',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 10),
        const GlowCard(
          child: Text(
            '“Chemistry is the study of matter, but I prefer to see it as the study of change.”',
            style: TextStyle(color: AppColors.textSecondary, fontStyle: FontStyle.italic),
          ),
        ),
      ],
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({required this.icon, required this.color, required this.label});
  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      decoration: BoxDecoration(color: AppColors.surfaceElevated, borderRadius: BorderRadius.circular(12), border: Border.all(color: AppColors.border)),
      child: Column(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(height: 4),
          Text(label, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.title, {super.key});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
    );
  }
}

class CircularAttendance extends StatelessWidget {
  const CircularAttendance({required this.percent, super.key});
  final double percent;

  @override
  Widget build(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        SizedBox(
          width: 50,
          height: 50,
          child: CircularProgressIndicator(
            value: percent / 100,
            color: AttendanceMath.isSafe(percent) ? AppColors.success : AppColors.danger,
            backgroundColor: Colors.white12,
            strokeWidth: 6,
          ),
        ),
        Text('${percent.round()}%', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 12)),
      ],
    );
  }
}

class _QuickTile extends StatelessWidget {
  const _QuickTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      padding: const EdgeInsets.all(12),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.purple),
          const SizedBox(height: 8),
          Text(label, textAlign: TextAlign.center, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _NextClassCard extends StatelessWidget {
  const _NextClassCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = state.entries.where((e) => e.weekdayNumber == now.weekday).toList()
      ..sort((a, b) => a.startMinutes.compareTo(b.startMinutes));
    
    TimetableEntry? ongoing;
    TimetableEntry? next;
    final minutes = now.hour * 60 + now.minute;
    
    for (final e in today) {
      if (minutes >= e.startMinutes && minutes <= e.endMinutes) {
        ongoing = e;
      }
      if (e.startMinutes > minutes && next == null) {
        next = e;
      }
    }
    
    final displayClass = ongoing ?? next ?? (today.isEmpty ? null : today.first);
    if (displayClass == null) return const SizedBox.shrink();
    
    final isOngoing = displayClass == ongoing;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionTitle(isOngoing ? 'Ongoing class' : 'Next class'),
        GlowCard(
          borderColor: isOngoing ? AppColors.success : AppColors.border,
          child: Row(
            children: [
              if (isOngoing) ...[
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: AppColors.success,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
              ],
              Expanded(
                child: Text(
                  '${displayClass.displayName} • ${displayClass.startTime}${displayClass.room.isEmpty ? '' : ' • ${displayClass.room}'}',
                  style: const TextStyle(fontWeight: FontWeight.w800),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
