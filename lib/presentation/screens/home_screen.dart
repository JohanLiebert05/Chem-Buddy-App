import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/attendance_math.dart';
import '../../core/widgets/animated_dashboard.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../../data/models/smart_flashcard.dart';
import '../../data/models/timetable_entry.dart';
import '../../data/services/daily_chemistry_service.dart';
import '../providers/app_providers.dart';
import 'beginner_tutorial_dialog.dart';
import 'pdf_library_screen.dart';
import 'pdf_study_hub_screen.dart';
import 'search_screen.dart';
import 'smart_flashcards_hub.dart';
import 'smart_flashcards_study_screen.dart';
import '../widgets/reminder_editor.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _checkTutorial();
    });
  }

  void _checkTutorial() {
    final completed = ref.read(appControllerProvider.notifier).hasCompletedTutorial();
    if (!completed && mounted) {
      BeginnerTutorialDialog.show(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final repo = ref.watch(chemRepositoryProvider);
    final overall = repo.overallStats();
    final name = state.profile.fullName.isEmpty ? 'Chemist' : state.profile.fullName.split(' ').first;

    final localStore = ref.watch(localStoreProvider);
    final allSessions = localStore.all(localStore.studySessions).map((j) => StudySession.fromJson(j)).toList();
    final incompleteSession = allSessions.where((s) => !s.completed).firstOrNull;
    SmartFlashcardSet? incompleteSet;
    if (incompleteSession != null) {
      final allSets = localStore.all(localStore.smartSets).map((j) => SmartFlashcardSet.fromJson(j)).toList();
      incompleteSet = allSets.where((s) => s.id == incompleteSession.flashcardSetId).firstOrNull;
    }

    final recentPdf = state.pdfs.isNotEmpty
        ? (state.pdfs.where((p) => p.favorite).firstOrNull ?? state.pdfs.first)
        : null;

    final upcomingTests = state.events.where((e) => !e.completed).take(3).toList();
    final dailyChem = DailyChemistryService.instance.getTodayContent();

    return AnimatedDashboardList(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 100),
      children: [
        // 1. Header with greeting and search
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
                    '${state.profile.university.isEmpty ? "MSc Chemistry" : state.profile.university} · Sem ${state.profile.semester}',
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            CircleAvatar(
              backgroundColor: AppColors.surfaceElevated,
              foregroundColor: AppColors.purpleBright,
              child: Text(name.isEmpty ? 'C' : name[0].toUpperCase(), style: const TextStyle(fontWeight: FontWeight.w800)),
            ),
            IconButton(
              tooltip: 'Search',
              onPressed: () => Navigator.of(context).push(MaterialPageRoute<void>(builder: (_) => const SearchScreen())),
              icon: const Icon(Icons.search),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // 2. Next class or schedule status
        _NextClassCard(state: state),
        const SizedBox(height: 12),

        // 3. Attendance health status
        GlowCard(
          onTap: () => ref.read(shellTabProvider.notifier).state = 2,
          child: Row(
            children: [
              CircularAttendance(percent: overall.percent),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AttendanceMath.isSafe(overall.percent)
                                ? AppColors.success.withValues(alpha: 0.15)
                                : AppColors.danger.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            AttendanceMath.isSafe(overall.percent) ? 'Safe to Bunk 🟢' : 'Better Attend 🔴',
                            style: TextStyle(
                              color: AttendanceMath.isSafe(overall.percent) ? AppColors.success : AppColors.danger,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right, color: AppColors.textMuted, size: 18),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Can skip ${overall.canSkip} more class${overall.canSkip == 1 ? "" : "es"} · Streak ${repo.streak()} days',
                      style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 4. Primary CTA: Study with ChemBuddy
        const SectionTitle('Study with ChemBuddy ✨'),
        GlowCard(
          borderColor: AppColors.purpleBright.withValues(alpha: 0.45),
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(Icons.auto_awesome, color: AppColors.purpleBright, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recentPdf != null ? recentPdf.displayName : 'Academic AI Tutor',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white),
                        ),
                        Text(
                          recentPdf != null ? 'Ready for Important Topics & Quizzes' : 'Upload your chemistry PDF notes to study',
                          style: const TextStyle(color: AppColors.textMuted, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.purple,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  onPressed: () {
                    if (recentPdf != null) {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => PdfStudyHubScreen(doc: recentPdf)),
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute<void>(builder: (_) => const PdfLibraryScreen()),
                      );
                    }
                  },
                  icon: const Icon(Icons.school, size: 18),
                  label: Text(
                    recentPdf != null ? 'Study ${recentPdf.displayName}' : 'Open PDF Study Library',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 5. Continue Studying (Progressive disclosure: only if session in progress)
        if (incompleteSession != null && incompleteSet != null) ...[
          const SectionTitle('Continue Flashcard Session'),
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
                    onPressed: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => SmartFlashcardsStudyScreen(setId: incompleteSet!.id))),
                    child: const Text('Resume Flashcards', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // 6. Chemistry Tools (Grouped quick-access tiles)
        const SectionTitle('Chemistry Tools'),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 0.95,
          children: [
            _QuickTile(icon: Icons.calendar_month_outlined, label: 'Timetable', onTap: () => ref.read(shellTabProvider.notifier).state = 3),
            _QuickTile(icon: Icons.menu_book_outlined, label: 'PDFs', onTap: () => ref.read(shellTabProvider.notifier).state = 4),
            _QuickTile(icon: Icons.style_outlined, label: 'Cards', onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsPage()))),
            _QuickTile(icon: Icons.alarm_add_outlined, label: 'Reminder', onTap: () => ReminderEditor.show(context, ref)),
          ],
        ),
        const SizedBox(height: 16),

        // 7. Upcoming Deadlines & Tests
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle('Upcoming Tests & Deadlines'),
            TextButton.icon(
              onPressed: () => _showAddTestDialog(context, ref, state),
              icon: const Icon(Icons.add, size: 16, color: AppColors.purpleBright),
              label: const Text('Add', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        if (upcomingTests.isEmpty)
          GlowCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.event_available_outlined, size: 24, color: AppColors.purple),
                const SizedBox(width: 12),
                const Expanded(
                  child: Text('No upcoming tests scheduled. Tap + Add to track deadlines.', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                ),
              ],
            ),
          )
        else
          ...upcomingTests.map((e) {
            final now = DateTime.now();
            final todayDate = DateTime(now.year, now.month, now.day);
            final eventDate = DateTime(e.dueDate.year, e.dueDate.month, e.dueDate.day);
            final daysLeft = eventDate.difference(todayDate).inDays;

            String countdownLabel = daysLeft == 0 ? 'Today! 🎯' : (daysLeft == 1 ? 'Tomorrow ⏰' : '$daysLeft days left');
            Color countdownColor = daysLeft <= 1 ? AppColors.warning : AppColors.purpleBright;

            final subject = state.subjects.where((s) => s.id == e.subjectId).firstOrNull;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlowCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(e.type == EventType.test ? Icons.quiz_rounded : Icons.assignment_rounded, color: AppColors.purpleBright, size: 20),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(e.title, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          Text(
                            '${DateFormat("d MMM").format(e.dueDate)}${subject != null ? " · ${subject.name}" : ""}',
                            style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                          ),
                        ],
                      ),
                    ),
                    Text(countdownLabel, style: TextStyle(color: countdownColor, fontWeight: FontWeight.w700, fontSize: 11.5)),
                  ],
                ),
              ),
            );
          }),
        const SizedBox(height: 16),

        // 8. Daily Chemistry Concept / Quote
        _DailyChemistryCard(item: dailyChem),
      ],
    );
  }

  void _showAddTestDialog(BuildContext context, WidgetRef ref, AppState state) {
    final title = TextEditingController();
    final desc = TextEditingController();
    var type = EventType.test;
    var due = DateTime.now().add(const Duration(days: 7));
    String? subjectId = state.subjects.isNotEmpty ? state.subjects.first.id : null;

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Academic Deadline', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17)),
                  const SizedBox(height: 12),
                  TextField(controller: title, decoration: const InputDecoration(hintText: 'Title (e.g. Midterm Test 1)')),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String?>(
                    initialValue: subjectId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No subject')),
                      ...state.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => setModal(() => subjectId = v),
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  const SizedBox(height: 8),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Due ${DateFormat('d MMM yyyy').format(due)}'),
                    trailing: const Icon(Icons.calendar_month),
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: due,
                        firstDate: DateTime.now(),
                        lastDate: DateTime.now().add(const Duration(days: 365)),
                      );
                      if (picked != null) setModal(() => due = picked);
                    },
                  ),
                  const SizedBox(height: 12),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      if (title.text.trim().isEmpty) return;
                      final repo = ref.read(chemRepositoryProvider);
                      await ref.read(appControllerProvider.notifier).saveEvent(
                            AcademicEvent(
                              id: repo.newId(),
                              title: title.text.trim(),
                              type: type,
                              dueDate: due,
                              subjectId: subjectId,
                              description: desc.text.trim(),
                            ),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Deadline', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}

class _DailyChemistryCard extends StatelessWidget {
  const _DailyChemistryCard({required this.item});
  final DailyChemistryItem item;

  @override
  Widget build(BuildContext context) {
    return GlowCard(
      borderColor: item.type.color.withValues(alpha: 0.35),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(item.type.icon, size: 16, color: item.type.color),
              const SizedBox(width: 8),
              Text(
                item.type.header,
                style: TextStyle(
                  color: item.type.color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white),
          ),
          const SizedBox(height: 4),
          Text(
            item.content,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
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
      padding: const EdgeInsets.only(top: 14, bottom: 8),
      child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textSecondary)),
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
            strokeWidth: 5,
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
      padding: const EdgeInsets.all(8),
      onTap: onTap,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: AppColors.purpleBright, size: 22),
          const SizedBox(height: 4),
          Text(label, textAlign: TextAlign.center, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
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
    if (displayClass == null) {
      return GlowCard(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: const [
            Icon(Icons.bedtime_outlined, color: AppColors.textMuted, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('No classes scheduled for today.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
          ],
        ),
      );
    }

    final isOngoing = displayClass == ongoing;

    return GlowCard(
      borderColor: isOngoing ? AppColors.success : AppColors.purple.withValues(alpha: 0.35),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: (isOngoing ? AppColors.success : AppColors.purple).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOngoing ? Icons.play_arrow_rounded : Icons.schedule_rounded,
              color: isOngoing ? AppColors.success : AppColors.purpleBright,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isOngoing ? 'Class in Progress' : 'Next Up Today',
                  style: TextStyle(
                    color: isOngoing ? AppColors.success : AppColors.purpleBright,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
                Text(
                  displayClass.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
                ),
                Text(
                  '${displayClass.startTime} – ${displayClass.endTime}${displayClass.room.isEmpty ? "" : " · ${displayClass.room}"}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
