import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/app_by_prajwal.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../../data/remote/supabase_service.dart';
import '../providers/app_providers.dart';
import 'app_guides_screen.dart';
import 'beginner_tutorial_dialog.dart';
import 'notification_settings_screen.dart';

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});

  @override
  ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  bool _testingConnection = false;

  Future<void> _testSync() async {
    setState(() => _testingConnection = true);
    final connected = await SupabaseService.instance.checkConnection();
    setState(() => _testingConnection = false);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: connected ? AppColors.success : AppColors.surfaceElevated,
          content: Text(
            connected
                ? '🟢 Connected to Supabase Cloud! Sync is active.'
                : '⚪ Offline Local Mode active. Your notes, attendance & timetable remain safe on this device.',
          ),
          duration: const Duration(seconds: 4),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final p = state.profile;
    final isConfigured = SupabaseService.instance.configured;

    final repo = ref.watch(chemRepositoryProvider);
    final analyticsService = ref.watch(studyAnalyticsServiceProvider);
    final analytics = analyticsService.computeSummary(streakDays: repo.streak());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: [
        const Text('Profile & Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800)),
        const SizedBox(height: 16),
        GlowCard(
          child: Column(
            children: [
              const AtomLogo(size: 64),
              const SizedBox(height: 10),
              Text(p.fullName.isEmpty ? 'MSc Chemistry Student' : p.fullName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w800)),
              const SizedBox(height: 2),
              Text(p.registerNumber.isNotEmpty ? 'Reg: ${p.registerNumber}' : p.email, style: const TextStyle(color: AppColors.textSecondary, fontSize: 13)),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.purple.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text('${p.university} · Semester ${p.semester}', style: const TextStyle(color: AppColors.purpleBright, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),

        // 1. STUDY ANALYTICS & MASTERY
        const SectionTitle('Study Analytics & Topic Mastery 📊'),
        GlowCard(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 4-Card Metric Grid
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Quiz Accuracy',
                      value: analytics.totalQuestionsAnswered > 0
                          ? '${analytics.overallQuizAccuracy.toStringAsFixed(0)}%'
                          : 'N/A',
                      color: analytics.overallQuizAccuracy >= 70 ? AppColors.success : AppColors.warning,
                      icon: Icons.track_changes_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Questions Solved',
                      value: '${analytics.totalQuestionsAnswered}',
                      color: AppColors.purpleBright,
                      icon: Icons.quiz_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Cards Mastered',
                      value: '${analytics.flashcardsMatureCount}',
                      color: AppColors.blue,
                      icon: Icons.school_outlined,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _buildMetricTile(
                      label: 'Study Streak',
                      value: '${analytics.studyStreakDays} Day${analytics.studyStreakDays == 1 ? "" : "s"} 🔥',
                      color: AppColors.warning,
                      icon: Icons.local_fire_department_outlined,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Weak Areas Section
              const Text('Chemistry Topic Mastery Breakdown', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: Colors.white)),
              const SizedBox(height: 8),

              if (analytics.weakTopics.isNotEmpty) ...[
                ...analytics.weakTopics.map((w) => Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppColors.danger.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: AppColors.danger.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      children: [
                        const Text('🔴', style: TextStyle(fontSize: 14)),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(w.topic, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white)),
                              Text(
                                '${w.accuracy.toStringAsFixed(0)}% Accuracy · Needs Review',
                                style: const TextStyle(color: AppColors.danger, fontSize: 11, fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            ref.read(shellTabProvider.notifier).state = 2; // Ask AI tab
                          },
                          style: TextButton.styleFrom(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4)),

                          child: const Text('Study →', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                )),
              ] else ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceElevated,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.check_circle_outline, color: AppColors.success, size: 18),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'No weak topics identified yet. Complete quizzes to track your chemistry mastery!',
                          style: TextStyle(color: AppColors.textSecondary, fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),

        // 2. ACADEMIC COURSES
        const SectionTitle('Academic Courses'),
        if (state.subjects.isEmpty)
          const GlowCard(
            child: Text('No courses added yet. Tap Add Custom Subject to get started.', style: TextStyle(color: AppColors.textMuted)),
          )
        else
          ...state.subjects.map(
            (s) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: GlowCard(
                onTap: () => _addSubject(context, ref, existing: s),
                child: Row(
                  children: [
                    Container(width: 10, height: 10, decoration: BoxDecoration(color: Color(s.colorHex), shape: BoxShape.circle)),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
                          Text('${s.code}${s.teacher.isEmpty ? '' : ' · ${s.teacher}'}', style: const TextStyle(color: AppColors.textMuted, fontSize: 12)),
                        ],
                      ),
                    ),
                    IconButton(
                      onPressed: () => ref.read(appControllerProvider.notifier).deleteSubject(s.id),
                      icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 20),
                    ),
                  ],
                ),
              ),
            ),
          ),
        const SizedBox(height: 4),
        OutlinedButton.icon(
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 12),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            side: BorderSide(color: AppColors.purple.withValues(alpha: 0.5)),
          ),
          onPressed: () => _addSubject(context, ref),
          icon: const Icon(Icons.add, size: 18, color: AppColors.purpleBright),
          label: const Text('Add Custom Subject', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700)),
        ),

        // 2. HELP & TUTORIALS
        const SectionTitle('Help & Guides'),
        GlowCard(
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const AppGuidesScreen())),
          child: const Row(
            children: [
              Icon(Icons.menu_book_rounded, color: AppColors.purpleBright),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('How to Use ChemBuddy', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Visual guides for Attendance, Timetable, PDF AI & Quizzes', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GlowCard(
          onTap: () => BeginnerTutorialDialog.show(context),
          child: const Row(
            children: [
              Icon(Icons.play_circle_outline_rounded, color: AppColors.blue),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Replay Onboarding Walkthrough', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('7-step interactive tour of ChemBuddy features', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),

        // 3. PREFERENCES
        const SectionTitle('Preferences'),
        GlowCard(
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen())),
          child: const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: AppColors.purpleBright),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Class & Study Reminders', style: TextStyle(fontWeight: FontWeight.w700)),
                    Text('Configure alert timing and quiet hours', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),

        // 4. STORAGE & CLOUD SYNC
        const SectionTitle('Storage & Cloud Sync'),
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(
                      color: isConfigured ? AppColors.success : AppColors.textMuted,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    isConfigured ? 'Cloud Sync: Connected' : 'Storage: Offline Local Mode (Hive)',
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      color: isConfigured ? AppColors.success : Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                isConfigured
                    ? 'Your profile, timetable, notes, and attendance sync automatically with Supabase cloud.'
                    : 'All your data is saved locally on this device in Hive. Cloud features will sync when online.',
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.3),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.surfaceElevated,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                      side: BorderSide(color: AppColors.border),
                    ),
                    onPressed: _testingConnection ? null : _testSync,
                    icon: _testingConnection
                        ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purple))
                        : const Icon(Icons.sync, size: 16, color: AppColors.purpleBright),
                    label: Text(
                      _testingConnection ? 'Testing...' : 'Test Connection / Retry',
                      style: const TextStyle(fontSize: 12, color: Colors.white, fontWeight: FontWeight.w600),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),

        // 5. ABOUT
        const SectionTitle('About'),
        GlowCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Chem Buddy v2.6.0', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
              const SizedBox(height: 4),
              const Text(
                'AI-Powered Academic & Study Assistant for MSc Chemistry students.',
                style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
              ),
              const SizedBox(height: 8),
              const Text(
                'Developed by Prajwal A Kambar',
                style: TextStyle(color: AppColors.textMuted, fontSize: 12, fontStyle: FontStyle.italic),
              ),
            ],
          ),
        ),

        const SizedBox(height: 20),
        Center(
          child: TextButton.icon(
            onPressed: () => _confirmLogout(context, ref),
            icon: const Icon(Icons.logout, color: AppColors.danger, size: 18),
            label: const Text('Log out', style: TextStyle(color: AppColors.danger, fontWeight: FontWeight.w700)),
          ),
        ),
        const SizedBox(height: 12),
        const Center(child: AppByPrajwal(large: true)),
      ],
    );
  }

  void _confirmLogout(BuildContext context, WidgetRef ref) {
    showDialog<void>(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          title: const Text('Log out of Chem Buddy?'),
          content: const Text('Your local data is saved on this device. You can log back in anytime.'),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancel')),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: AppColors.danger),
              onPressed: () {
                Navigator.pop(ctx);
                ref.read(appControllerProvider.notifier).logout();
              },
              child: const Text('Log out', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _addSubject(BuildContext context, WidgetRef ref, {Subject? existing}) async {
    final name = TextEditingController(text: existing?.name ?? '');
    final code = TextEditingController(text: existing?.code ?? '');
    final teacher = TextEditingController(text: existing?.teacher ?? '');
    var color = existing?.colorHex ?? AppColors.subjectPalette.first.toARGB32();
    await showModalBottomSheet<void>(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: StatefulBuilder(
            builder: (context, setModal) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(existing == null ? 'Custom subject' : 'Edit subject', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
                  const SizedBox(height: 12),
                  TextField(controller: name, decoration: const InputDecoration(hintText: 'Name')),
                  const SizedBox(height: 8),
                  TextField(controller: code, decoration: const InputDecoration(hintText: 'Code')),
                  const SizedBox(height: 8),
                  TextField(controller: teacher, decoration: const InputDecoration(hintText: 'Teacher')),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      for (final c in AppColors.subjectPalette)
                        GestureDetector(
                          onTap: () => setModal(() => color = c.toARGB32()),
                          child: CircleAvatar(
                            radius: 12,
                            backgroundColor: c,
                            child: color == c.toARGB32() ? const Icon(Icons.check, size: 14, color: Colors.white) : null,
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label: 'Save',
                    onPressed: () async {
                      if (name.text.trim().isEmpty || code.text.trim().isEmpty) return;
                      final id = existing?.id ?? ref.read(chemRepositoryProvider).newId();
                      await ref.read(appControllerProvider.notifier).saveSubject(
                            Subject(
                              id: id,
                              name: name.text.trim(),
                              code: code.text.trim(),
                              teacher: teacher.text.trim(),
                              colorHex: color,
                              isElective: existing?.isElective ?? false,
                            ),
                          );
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                  ),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 14, color: color),
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
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 16, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}
