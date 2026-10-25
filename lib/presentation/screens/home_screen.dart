import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/attendance_math.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/animated_dashboard.dart';
import '../../core/widgets/branding/chembuddy_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../../data/models/smart_flashcard.dart';
import '../../data/models/timetable_entry.dart';
import '../../data/services/daily_chemistry_service.dart';
import '../../data/services/psychology_facts_service.dart';
import '../../data/services/study_analytics_service.dart';
import '../providers/app_providers.dart';
import '../widgets/home_widgets.dart';
import '../widgets/reaction_mechanisms_card.dart';
import 'beginner_tutorial_dialog.dart';
import 'chemistry_toolkit_screen.dart';
import 'exam_mode_screen.dart';
import 'pdf_library_screen.dart';
import 'pdf_study_hub_screen.dart';
import 'pericyclic_hub_screen.dart';
import 'reaction_mechanism_screen.dart';
import 'search_screen.dart';
import 'smart_flashcards_hub.dart';
import 'smart_flashcards_study_screen.dart';
import 'spectroscopy_hub_screen.dart';

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

  String _timeGreeting(int hour, int weekday) {
    if (hour < 5) return 'Late night study';
    if (hour < 9) return 'Good morning';
    if (hour < 12) {
      if (weekday == DateTime.monday) return 'Monday focus';
      if (weekday == DateTime.friday) return 'Friday wrap-up';
      return 'Good morning';
    }
    if (hour < 17) return 'Good afternoon';
    if (hour < 21) return 'Good evening';
    return 'Night study';
  }

  static String _chemistryThought(int dayOfMonth) {
    const thoughts = [
      '"The only failed experiment is the one you didn\'t try."',
      '"Chemistry is the science of matter — and you matter."',
      '"In chemistry, nothing is lost, nothing is created, everything is transformed." — Lavoisier',
      '"The meeting of two personalities is like the contact of two chemical substances." — Jung',
      '"Life is a chemical reaction — it only requires the right catalyst."',
      '"Science knows no country, because knowledge belongs to humanity." — Pasteur',
      '"Every great advance in science has issued from a new audacity of imagination." — Dewey',
      '"The important thing in science is not so much to obtain new facts as to discover new ways of thinking." — Bragg',
      '"Research is to see what everybody else has seen, and think what nobody has thought." — Szent-Györgyi',
      '"Nothing in life is to be feared, it is only to be understood." — Curie',
      '"Chemistry begins in the stars." — Primo Levi',
      '"The atoms of our bodies are traceable to stars that exploded." — Tyson',
      '"Discovery is seeing what everybody else has seen and thinking what nobody else has thought."',
      '"Science is a way of thinking much more than it is a body of knowledge." — Sagan',
      '"The best scientist is open to experience and begins with romance." — Ray Bradbury',
      '"Not every reaction needs a catalyst — sometimes patience is the reagent."',
      '"Your knowledge is a solution; keep dissolving new solutes into it."',
      '"Be like water: adapt, dissolve barriers, and find your equilibrium."',
      '"The periodic table is poetry arranged in columns."',
      '"A chemist who doesn\'t know mathematics is not a chemist at all." — Lomonosov',
      '"Think like a proton — always positive."',
      '"If you\'re not part of the solution, you\'re part of the precipitate."',
      '"Never trust an atom — they make up everything."',
      '"Chemistry: where alcohol IS a solution."',
      '"Organic chemistry is the chemistry of carbon compounds. Biochemistry is the study of carbon compounds that crawl." — Mike Adams',
      '"The nitrogen in our DNA, the calcium in our teeth, the iron in our blood... were made in the interiors of collapsing stars." — Sagan',
      '"Knowledge is like a chemical reaction: it needs activation energy, but once started, it\'s self-sustaining."',
      '"Your education is your compound interest — it grows exponentially."',
      '"Like Le Chatelier\'s principle: when stressed, shift to restore equilibrium."',
      '"Every expert was once a beginner. Every reaction starts with a single bond."',
      '"Today\'s effort is tomorrow\'s advantage. Keep compounding."',
    ];
    return thoughts[dayOfMonth % thoughts.length];
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final repo = ref.watch(chemRepositoryProvider);
    final overall = repo.overallStats();

    final rawFullName = state.profile.fullName.trim();
    final rawReg = state.profile.registerNumber.trim();

    String resolvedName = '';
    if (rawFullName.isNotEmpty && rawFullName.toLowerCase() != 'chemist') {
      resolvedName = rawFullName;
    } else if (rawReg.isNotEmpty) {
      final isPureDigits = RegExp(r'^\d+$').hasMatch(rawReg);
      if (!isPureDigits) {
        resolvedName = rawReg;
      }
    }

    final name = resolvedName.isNotEmpty
        ? resolvedName.split(' ').first
        : 'Prajwal';

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

    final analyticsService = ref.watch(studyAnalyticsServiceProvider);
    final analytics = analyticsService.computeSummary(streakDays: repo.streak());

    final hour = DateTime.now().hour;
    final weekday = DateTime.now().weekday;
    final overallPct = overall.percent;
    final timeGreeting = _timeGreeting(hour, weekday);

    return AnimatedDashboardList(
      padding: const EdgeInsets.fromLTRB(18, 12, 18, 96),
      children: [
        // 1. Header with greeting, student name, institution, and search
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.only(top: 2),
              child: ChemBuddyLogo(size: 40),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    timeGreeting,
                    style: const TextStyle(
                      color: AppColors.brandBright,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 0.2,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    name.isEmpty ? 'Prajwal' : name,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.4,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${state.profile.university.isEmpty ? "MSc Chemistry" : state.profile.university} · Sem ${state.profile.semester}',
                    style: const TextStyle(
                      color: AppColors.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      height: 1.3,
                    ),
                  ),
                ],
              ),
            ),
            IconButton.filledTonal(
              tooltip: 'Search',
              iconSize: 20,
              style: IconButton.styleFrom(
                backgroundColor: AppColors.surfaceContainerHigh,
                foregroundColor: AppColors.textPrimary,
              ),
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => const SearchScreen()),
              ),
              icon: const Icon(Icons.search_rounded),
            ),
          ],
        ),

        // Attendance Alert Banner (prominently displayed when below 75%)
        if (overallPct < 75.0) ...[
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.statusDanger.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.statusDanger.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.warning_amber_rounded, color: AppColors.statusDanger, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Attendance Warning: ${overallPct.toStringAsFixed(1)}% (Below 75%)',
                        style: const TextStyle(
                          color: AppColors.statusDanger,
                          fontWeight: FontWeight.w700,
                          fontSize: 12.5,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'Every class counts — attend upcoming classes to restore eligibility.',
                        style: TextStyle(
                          color: AppColors.textSecondary,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],

        // Daily Chemistry Thought
        Container(
          margin: const EdgeInsets.only(top: 10),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: AppColors.surfaceContainerHigh,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.borderSubtle),
          ),
          child: Row(
            children: [
              const Icon(Icons.format_quote_rounded, size: 16, color: AppColors.brandBright),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _chemistryThought(DateTime.now().day),
                  style: const TextStyle(
                    color: AppColors.textMuted,
                    fontSize: 11.5,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // Study Priorities
        StudyPrioritiesCard(
          weakTopics: analytics.weakTopics,
          moderateTopics: analytics.moderateTopics,
        ),

        // 2. CONTINUE STUDYING (Recently Studied Topic / PDF)
        const SectionTitle('Continue Studying', icon: Icons.menu_book_rounded),
        GlowCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.14),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.auto_stories_rounded, color: AppColors.brandBright, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          recentPdf != null ? recentPdf.displayName : 'MSc Chemistry Study Hub',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.textPrimary,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          recentPdf != null
                              ? 'Ready for quizzes, flashcards & notes review'
                              : 'Upload chemistry notes to begin interactive study',
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
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.brandPrimary,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
                  icon: const Icon(Icons.play_arrow_rounded, size: 20),
                  label: Text(
                    recentPdf != null ? 'Continue Studying ${recentPdf.displayName}' : 'Open Study Hub',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                  ),
                ),
              ),
            ],
          ),
        ),

        // 3. TODAY'S STUDY METRICS
        const SectionTitle('Today\'s Overview', icon: Icons.insights_rounded),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 2,
          mainAxisSpacing: 8,
          crossAxisSpacing: 8,
          childAspectRatio: 1.85,
          children: [
            _buildStatCard(
              label: 'Questions Answered',
              value: '${analytics.totalQuestionsAnswered}',
              icon: Icons.quiz_outlined,
              color: AppColors.brandBright,
            ),
            _buildStatCard(
              label: 'Flashcards Due',
              value: '${analytics.flashcardsDueToday}',
              icon: Icons.psychology_outlined,
              color: analytics.flashcardsDueToday > 0 ? AppColors.statusWarning : AppColors.statusSuccess,
            ),
            _buildAccuracyCard(
              analytics.overallQuizAccuracy,
              analytics.totalQuestionsAnswered,
            ),
            _buildStreakCard(
              analytics.studyStreakDays,
            ),
          ],
        ),

        // 4. DUE TODAY FLASHCARDS BANNER
        if (analytics.flashcardsDueToday > 0) ...[
          const SizedBox(height: 10),
          GlowCard(
            borderColor: AppColors.statusWarning.withValues(alpha: 0.4),
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.statusWarning.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.alarm_on_rounded, color: AppColors.statusWarning, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '${analytics.flashcardsDueToday} flashcard${analytics.flashcardsDueToday == 1 ? "" : "s"} due today',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary),
                      ),
                      const SizedBox(height: 1),
                      const Text(
                        'Reinforce active recall with spaced repetition',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                      ),
                    ],
                  ),
                ),
                FilledButton.tonal(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.statusWarning.withValues(alpha: 0.18),
                    foregroundColor: AppColors.statusWarning,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute<void>(
                        builder: (_) => const SmartFlashcardsStudyScreen(
                          setId: '',
                          review: ReviewMode.spacedRepetition,
                        ),
                      ),
                    );
                  },
                  child: const Text('Review', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12)),
                ),
              ],
            ),
          ),
        ],

        // 5. QUICK ACTIONS
        const SectionTitle('Quick Actions', icon: Icons.bolt_rounded),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 5,
          mainAxisSpacing: 8,
          crossAxisSpacing: 6,
          childAspectRatio: 0.85,
          children: [
            _QuickTile(
              icon: Icons.auto_awesome_rounded,
              label: 'Ask AI',
              onTap: () => ref.read(shellTabProvider.notifier).state = 2,
            ),
            _QuickTile(
              icon: Icons.quiz_outlined,
              label: 'Quiz',
              onTap: () {
                if (recentPdf != null) {
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => PdfStudyHubScreen(doc: recentPdf)));
                } else {
                  Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PdfLibraryScreen()));
                }
              },
            ),
            _QuickTile(
              icon: Icons.style_outlined,
              label: 'Cards',
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SmartFlashcardsPage())),
            ),
            _QuickTile(
              icon: Icons.upload_file_rounded,
              label: 'Upload',
              onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PdfLibraryScreen())),
            ),
            _QuickTile(
              icon: Icons.science_outlined,
              label: 'Mechanism',
              onTap: () {
                AppHaptics.selection();
                Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const ReactionMechanismsScreen(),
                  ),
                );
              },
            ),
          ],
        ),

        // 6. MSc Specialization & Advanced Tools
        const SectionTitle('Chemistry Tools', icon: Icons.science_rounded),
        Column(
          children: [
            _buildMscToolCard(
              title: 'Chemistry Toolkit',
              subtitle: '16 postgraduate calculators and solutions formulation',
              icon: Icons.calculate_rounded,
              color: AppColors.brandBright,
              onTap: () {
                AppHaptics.selection();
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ChemistryToolkitScreen()));
              },
            ),
            const SizedBox(height: 8),
            _buildMscToolCard(
              title: 'Spectroscopy Hub',
              subtitle: '¹H/¹³C NMR, FT-IR and mass spectrometry database',
              icon: Icons.graphic_eq_rounded,
              color: AppColors.accentCyan,
              onTap: () {
                AppHaptics.selection();
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const SpectroscopyHubScreen()));
              },
            ),
            const SizedBox(height: 8),
            _buildMscToolCard(
              title: 'Pericyclic Rules & FMO',
              subtitle: 'Woodward-Hoffmann, electrocyclic and cycloadditions',
              icon: Icons.all_inclusive_rounded,
              color: AppColors.brandPrimary,
              onTap: () {
                AppHaptics.selection();
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const PericyclicHubScreen()));
              },
            ),
            const SizedBox(height: 8),
            _buildMscToolCard(
              title: 'Exam Mode & Model Answers',
              subtitle: 'Blueprint rubrics, 2M/5M/10M marking criteria',
              icon: Icons.school_rounded,
              color: AppColors.accentGold,
              onTap: () {
                AppHaptics.selection();
                Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const ExamModeScreen()));
              },
            ),
          ],
        ),

        // 7. Daily Psychology Insight
        const SectionTitle('Daily Study Tip', icon: Icons.psychology_rounded),
        const _DailyPsychologyFactCard(),

        // 8. Schedule & Next Class
        const SectionTitle('Schedule & Classes', icon: Icons.calendar_today_rounded),
        _NextClassCard(state: state),
        const SizedBox(height: 10),

        // 9. Attendance status
        GlowCard(
          onTap: () => ref.read(shellTabProvider.notifier).state = 1,
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
                          padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                          decoration: BoxDecoration(
                            color: AttendanceMath.isSafe(overall.percent)
                                ? AppColors.statusSuccess.withValues(alpha: 0.14)
                                : AppColors.statusDanger.withValues(alpha: 0.14),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            AttendanceMath.isSafe(overall.percent) ? 'Safe Margin' : 'Attendance Low',
                            style: TextStyle(
                              color: AttendanceMath.isSafe(overall.percent)
                                  ? AppColors.statusSuccess
                                  : AppColors.statusDanger,
                              fontWeight: FontWeight.w700,
                              fontSize: 11,
                            ),
                          ),
                        ),
                        const Spacer(),
                        const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
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

        // 10. Reaction Mechanisms Feature Showcase
        const SectionTitle('Reaction Mechanisms', icon: Icons.biotech_rounded),
        const ReactionMechanismsCard(),

        // 11. Incomplete Flashcard Session
        if (incompleteSession != null && incompleteSet != null) ...[
          const SectionTitle('Incomplete Flashcard Session', icon: Icons.pending_actions_rounded),
          GlowCard(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Flashcard Review: ${incompleteSet.title}',
                  style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 8),
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: LinearProgressIndicator(
                    value: incompleteSet.cardCount > 0
                        ? (incompleteSession.currentPosition / incompleteSet.cardCount).clamp(0, 1)
                        : 0,
                    color: AppColors.accentCyan,
                    backgroundColor: AppColors.surfaceContainerLowest,
                    minHeight: 6,
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.tonal(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.surfaceContainerHighest,
                      foregroundColor: AppColors.textPrimary,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute<void>(builder: (_) => SmartFlashcardsStudyScreen(setId: incompleteSet!.id)),
                    ),
                    child: const Text('Resume Flashcards', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ),
              ],
            ),
          ),
        ],

        // 12. Upcoming Deadlines & Tests
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const SectionTitle('Upcoming Deadlines & Tests', icon: Icons.event_note_rounded),
            TextButton.icon(
              onPressed: () => _showAddTestDialog(context, ref, state),
              icon: const Icon(Icons.add_rounded, size: 16, color: AppColors.brandBright),
              label: const Text('Add', style: TextStyle(color: AppColors.brandBright, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        if (upcomingTests.isEmpty)
          GlowCard(
            padding: const EdgeInsets.all(14),
            child: const Row(
              children: [
                Icon(Icons.event_available_rounded, size: 22, color: AppColors.brandBright),
                SizedBox(width: 12),
                Expanded(
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

            String countdownLabel = daysLeft == 0 ? 'Due today' : (daysLeft == 1 ? 'Due tomorrow' : '$daysLeft days left');
            Color countdownColor = daysLeft <= 1 ? AppColors.statusWarning : AppColors.brandBright;

            final subject = state.subjects.where((s) => s.id == e.subjectId).firstOrNull;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlowCard(
                padding: const EdgeInsets.all(12),
                child: Row(
                  children: [
                    Icon(
                      e.type == EventType.test ? Icons.quiz_rounded : Icons.assignment_rounded,
                      color: AppColors.brandBright,
                      size: 20,
                    ),
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
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: countdownColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        countdownLabel,
                        style: TextStyle(color: countdownColor, fontWeight: FontWeight.w700, fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

        // 13. Academic Progress
        const SectionTitle('Academic Progress', icon: Icons.trending_up_rounded),
        _MyProgressSection(analytics: analytics),
        const SizedBox(height: 14),

        // 14. Daily Chemistry Concept
        _DailyChemistryCard(item: dailyChem),
      ],
    );
  }

  Widget _buildStatCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 0.6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(icon, size: 15, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 18,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAccuracyCard(double accuracy, int totalQuestions) {
    final hasData = totalQuestions > 0;
    final color = accuracy >= 70 ? AppColors.statusSuccess : AppColors.statusWarning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 0.6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 36,
            child: CustomPaint(
              painter: _RadialAccuracyPainter(
                percent: hasData ? (accuracy / 100).clamp(0.0, 1.0) : 0.0,
                color: color,
              ),
              child: Center(
                child: Icon(
                  hasData ? Icons.bolt_rounded : Icons.track_changes_outlined,
                  size: 14,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Quiz Accuracy',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  hasData ? '${accuracy.toStringAsFixed(0)}%' : 'N/A',
                  style: TextStyle(
                    color: color,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStreakCard(int streakDays) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.borderSubtle, width: 0.6),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            height: 28,
            child: CustomPaint(
              painter: _StreakSparklinePainter(streakDays: streakDays),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Text(
                  'Study Streak',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 2),
                Text(
                  '$streakDays Day${streakDays == 1 ? "" : "s"}',
                  style: const TextStyle(
                    color: AppColors.accentGold,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    fontFeatures: [FontFeature.tabularFigures()],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMscToolCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 0.6),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: color, size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
          ],
        ),
      ),
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
      backgroundColor: AppColors.bg2,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 12, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Add Academic Deadline', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 17, color: AppColors.textPrimary)),
                  const SizedBox(height: 14),
                  TextField(controller: title, decoration: const InputDecoration(hintText: 'Title (e.g. Midterm Test 1)')),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String?>(
                    initialValue: subjectId,
                    items: [
                      const DropdownMenuItem(value: null, child: Text('No subject')),
                      ...state.subjects.map((s) => DropdownMenuItem(value: s.id, child: Text(s.name))),
                    ],
                    onChanged: (v) => setModal(() => subjectId = v),
                    decoration: const InputDecoration(labelText: 'Subject'),
                  ),
                  const SizedBox(height: 10),
                  ListTile(
                    contentPadding: EdgeInsets.zero,
                    title: Text('Due ${DateFormat('d MMM yyyy').format(due)}', style: const TextStyle(color: AppColors.textPrimary)),
                    trailing: const Icon(Icons.calendar_month_rounded, color: AppColors.brandBright),
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
                  const SizedBox(height: 16),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.brandPrimary,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(48),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
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
      borderColor: AppColors.borderSubtle,
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
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            item.title,
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
          ),
          const SizedBox(height: 4),
          Text(
            item.content,
            style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.4),
          ),
        ],
      ),
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
          width: 48,
          height: 48,
          child: CircularProgressIndicator(
            value: percent / 100,
            color: AttendanceMath.isSafe(percent) ? AppColors.statusSuccess : AppColors.statusDanger,
            backgroundColor: AppColors.surfaceContainerLowest,
            strokeWidth: 4.5,
          ),
        ),
        Text(
          '${percent.round()}%',
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 11.5,
            color: AppColors.textPrimary,
            fontFeatures: [FontFeature.tabularFigures()],
          ),
        ),
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
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
        decoration: BoxDecoration(
          color: AppColors.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.borderSubtle, width: 0.6),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: AppColors.brandBright, size: 22),
            const SizedBox(height: 6),
            Text(
              label,
              textAlign: TextAlign.center,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _NextClassCard extends ConsumerWidget {
  const _NextClassCard({required this.state});
  final AppState state;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
        padding: const EdgeInsets.all(14),
        onTap: () => ref.read(shellTabProvider.notifier).state = 1,
        child: const Row(
          children: [
            Icon(Icons.bedtime_outlined, color: AppColors.textMuted, size: 20),
            SizedBox(width: 10),
            Expanded(child: Text('No classes scheduled for today.', style: TextStyle(color: AppColors.textSecondary, fontSize: 13))),
            Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 18),
          ],
        ),
      );
    }

    final isOngoing = displayClass == ongoing;
    final repo = ref.watch(chemRepositoryProvider);
    final todayNormalized = DateTime(now.year, now.month, now.day);
    final record = repo.recordFor(slotId: displayClass.id, date: todayNormalized);

    return GlowCard(
      borderColor: isOngoing ? AppColors.statusSuccess.withValues(alpha: 0.4) : AppColors.borderSubtle,
      padding: const EdgeInsets.all(14),
      onTap: () => ref.read(shellTabProvider.notifier).state = 1,
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (isOngoing ? AppColors.statusSuccess : AppColors.brandPrimary).withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(
              isOngoing ? Icons.play_arrow_rounded : Icons.schedule_rounded,
              color: isOngoing ? AppColors.statusSuccess : AppColors.brandBright,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      isOngoing ? 'Class in Progress' : 'Next Up Today',
                      style: TextStyle(
                        color: isOngoing ? AppColors.statusSuccess : AppColors.brandBright,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                    if (record != null) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(
                          color: AppColors.present.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          record.status == AttendanceStatus.present ? 'Marked Present' : record.status.name.toUpperCase(),
                          style: const TextStyle(color: AppColors.present, fontSize: 9.5, fontWeight: FontWeight.w700),
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  displayClass.displayName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.textPrimary),
                ),
                Text(
                  '${displayClass.startTime} – ${displayClass.endTime}${displayClass.room.isEmpty ? "" : " · ${displayClass.room}"}',
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                ),
                if (displayClass.teacherName.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Faculty: ${displayClass.teacherName}',
                    style: const TextStyle(color: AppColors.brandBright, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ],
            ),
          ),
          const Icon(Icons.chevron_right_rounded, color: AppColors.textMuted, size: 20),
        ],
      ),
    );
  }
}

class _RadialAccuracyPainter extends CustomPainter {
  _RadialAccuracyPainter({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) - 3.5;

    final bgPaint = Paint()
      ..color = const Color(0x1AFFFFFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5;
    canvas.drawCircle(center, radius, bgPaint);

    if (percent > 0) {
      final fgPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round;
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius),
        -math.pi / 2,
        2 * math.pi * percent,
        false,
        fgPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _RadialAccuracyPainter old) =>
      old.percent != percent || old.color != color;
}

class _StreakSparklinePainter extends CustomPainter {
  _StreakSparklinePainter({required this.streakDays});

  final int streakDays;

  @override
  void paint(Canvas canvas, Size size) {
    const bars = 7;
    const spacing = 2.5;
    final barWidth = (size.width - ((bars - 1) * spacing)) / bars;

    for (var i = 0; i < bars; i++) {
      final daysAgo = (bars - 1) - i;
      final isActive = daysAgo < streakDays;
      final x = i * (barWidth + spacing);
      final heightFactor = 0.35 + ((i + 1) / bars) * 0.65;
      final height = isActive ? (size.height * heightFactor) : (size.height * 0.22);
      final y = size.height - height;

      final paint = Paint()
        ..color = isActive
            ? AppColors.accentGold.withValues(alpha: 0.55 + ((i + 1) / bars) * 0.45)
            : const Color(0x1AFFFFFF)
        ..style = PaintingStyle.fill;

      canvas.drawRRect(
        RRect.fromRectAndRadius(
          Rect.fromLTWH(x, y, barWidth, height),
          const Radius.circular(2),
        ),
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _StreakSparklinePainter old) =>
      old.streakDays != streakDays;
}

class _MyProgressSection extends StatelessWidget {
  const _MyProgressSection({required this.analytics});
  final StudyAnalyticsSummary analytics;

  @override
  Widget build(BuildContext context) {
    final hasData = analytics.totalQuestionsAnswered > 0;

    if (!hasData) {
      return GlowCard(
        padding: const EdgeInsets.all(16),
        child: const Row(
          children: [
            Icon(Icons.bar_chart_rounded, color: AppColors.brandBright, size: 28),
            SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('No quiz data yet',
                      style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary)),
                  SizedBox(height: 3),
                  Text(
                    'Take your first quiz from a PDF to start tracking your chemistry progress.',
                    style: TextStyle(color: AppColors.textMuted, fontSize: 12.5),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    }

    final accuracy = analytics.overallQuizAccuracy;
    final accuracyColor = accuracy >= 70
        ? AppColors.statusSuccess
        : (accuracy >= 50 ? AppColors.statusWarning : AppColors.statusDanger);
    final weakList = analytics.weakTopics.take(3).toList();

    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerHigh,
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: AppColors.borderSubtle, width: 0.6),
                ),
                child: Row(
                  children: [
                    SizedBox(
                      width: 38,
                      height: 38,
                      child: CustomPaint(
                        painter: _RadialAccuracyPainter(
                          percent: (accuracy / 100).clamp(0.0, 1.0),
                          color: accuracyColor,
                        ),
                        child: Center(
                          child: Icon(Icons.bolt_rounded, size: 14, color: accuracyColor),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('Overall Accuracy',
                              style: TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600)),
                          Text(
                            '${accuracy.toStringAsFixed(0)}%',
                            style: TextStyle(
                              color: accuracyColor,
                              fontSize: 18,
                              fontWeight: FontWeight.w800,
                              fontFeatures: const [FontFeature.tabularFigures()],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                children: [
                  _MiniStatRow(
                    icon: Icons.quiz_outlined,
                    label: 'Quizzes',
                    value: '${analytics.totalQuizzesTaken}',
                    color: AppColors.brandBright,
                  ),
                  const SizedBox(height: 6),
                  _MiniStatRow(
                    icon: Icons.style_outlined,
                    label: 'Cards Mastered',
                    value: '${analytics.flashcardsMatureCount}',
                    color: AppColors.accentCyan,
                  ),
                ],
              ),
            ),
          ],
        ),

        // Weak Topics
        if (weakList.isNotEmpty) ...[
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerHigh,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.statusWarning.withValues(alpha: 0.25)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.warning_amber_rounded, size: 15, color: AppColors.statusWarning),
                    SizedBox(width: 6),
                    Text(
                      'Needs Attention',
                      style: TextStyle(
                        color: AppColors.statusWarning,
                        fontWeight: FontWeight.w700,
                        fontSize: 12.5,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 10),
                ...weakList.map((t) {
                  final acc = t.accuracy.clamp(0.0, 100.0);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Expanded(
                              child: Text(
                                t.topic,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: AppColors.textPrimary,
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                            Text(
                              '${acc.toStringAsFixed(0)}%',
                              style: const TextStyle(
                                color: AppColors.statusDanger,
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                fontFeatures: [FontFeature.tabularFigures()],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(4),
                          child: LinearProgressIndicator(
                            value: acc / 100,
                            minHeight: 5,
                            color: AppColors.statusDanger,
                            backgroundColor: AppColors.surfaceContainerLowest,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
                const SizedBox(height: 4),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.statusWarning,
                      side: const BorderSide(color: AppColors.statusWarning, width: 0.9),
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                    ),
                    icon: const Icon(Icons.refresh_rounded, size: 16),
                    label: const Text('Practice Weak Topics',
                        style: TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5)),
                    onPressed: () {
                      Navigator.of(context).push(MaterialPageRoute<void>(
                        builder: (_) => const SmartFlashcardsStudyScreen(
                          setId: '',
                          review: ReviewMode.difficult,
                        ),
                      ));
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _MiniStatRow extends StatelessWidget {
  const _MiniStatRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });
  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.surfaceContainerHigh,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle, width: 0.6),
      ),
      child: Row(
        children: [
          Icon(icon, size: 14, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                color: AppColors.textMuted,
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            value,
            style: TextStyle(
              color: color,
              fontSize: 14,
              fontWeight: FontWeight.w800,
              fontFeatures: const [FontFeature.tabularFigures()],
            ),
          ),
        ],
      ),
    );
  }
}

class _DailyPsychologyFactCard extends StatefulWidget {
  const _DailyPsychologyFactCard();

  @override
  State<_DailyPsychologyFactCard> createState() => _DailyPsychologyFactCardState();
}

class _DailyPsychologyFactCardState extends State<_DailyPsychologyFactCard> {
  late PsychologyFact _fact;

  @override
  void initState() {
    super.initState();
    _fact = PsychologyFactsService.instance.getTodayFact();
  }

  void _shuffle() {
    AppHaptics.selection();
    setState(() {
      _fact = PsychologyFactsService.instance.getRandomFact();
    });
  }

  @override
  Widget build(BuildContext context) {
    final catColor = PsychologyFactsService.getCategoryColor(_fact.category);

    return GlowCard(
      borderColor: AppColors.borderSubtle,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: catColor.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.psychology_outlined, size: 20, color: catColor),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: catColor.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        _fact.category.toUpperCase(),
                        style: TextStyle(
                          color: catColor,
                          fontSize: 9.5,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.4,
                        ),
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      _fact.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.shuffle_rounded, size: 18, color: AppColors.textMuted),
                tooltip: 'Another Fact',
                onPressed: _shuffle,
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            _fact.fact,
            style: const TextStyle(
              fontSize: 13,
              height: 1.45,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderSubtle),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.lightbulb_outline_rounded, size: 16, color: AppColors.accentGold),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    _fact.takeaway,
                    style: const TextStyle(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: AppColors.textSecondary,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
