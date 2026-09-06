import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/attendance_math.dart';
import '../../core/widgets/app_by_prajwal.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../../data/models/models.dart';
import '../../data/remote/supabase_service.dart';
import '../../data/services/export_service.dart';
import '../../data/services/reaction_mechanism_service.dart';
import '../../data/services/study_analytics_service.dart';
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
  bool _isExporting = false;
  String _selectedReactionForExport = 'all';
  int _selectedAuditTab = 0; // 0: Attendance, 1: Coursework, 2: MSc Reactions

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

  Future<void> _exportAttendance({required bool isPdf}) async {
    setState(() => _isExporting = true);
    try {
      final state = ref.read(appControllerProvider);
      final repo = ref.read(chemRepositoryProvider);
      final file = isPdf
          ? await ExportService.instance.generateAttendancePdf(profile: state.profile, repository: repo)
          : await ExportService.instance.generateAttendanceCsv(profile: state.profile, repository: repo);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            isPdf
                ? '🟢 Attendance PDF Generated! Opening share sheet...'
                : '🟢 Attendance Spreadsheet (CSV) Generated! Opening share sheet...',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      await ExportService.instance.shareFile(
        file,
        subject: 'Chem Buddy Attendance Audit - ${state.profile.fullName}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Failed to export attendance: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportCoursework({required bool isPdf}) async {
    setState(() => _isExporting = true);
    try {
      final state = ref.read(appControllerProvider);
      final repo = ref.read(chemRepositoryProvider);
      final analyticsService = ref.read(studyAnalyticsServiceProvider);
      final analytics = analyticsService.computeSummary(streakDays: repo.streak());

      final file = isPdf
          ? await ExportService.instance.generateCourseworkAuditPdf(profile: state.profile, analytics: analytics)
          : await ExportService.instance.generateCourseworkAuditCsv(profile: state.profile, analytics: analytics);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            isPdf
                ? '🟢 Coursework Audit PDF Ready! Opening share sheet...'
                : '🟢 Coursework Spreadsheet (CSV) Ready! Opening share sheet...',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      await ExportService.instance.shareFile(
        file,
        subject: 'Chem Buddy Coursework & Mastery Audit - ${state.profile.fullName}',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Failed to export coursework: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  Future<void> _exportReaction({required bool isPdf}) async {
    setState(() => _isExporting = true);
    try {
      final mechanisms = ReactionMechanismService.instance.mechanisms;
      File file;
      if (isPdf) {
        if (_selectedReactionForExport == 'all') {
          file = await ExportService.instance.generateReactionPdf(reactions: mechanisms);
        } else {
          final rxn = ReactionMechanismService.instance.find(_selectedReactionForExport);
          file = await ExportService.instance.generateReactionPdf(singleReaction: rxn);
        }
      } else {
        if (_selectedReactionForExport == 'all') {
          file = await ExportService.instance.generateReactionsCsv(mechanisms: mechanisms);
        } else {
          final rxn = ReactionMechanismService.instance.find(_selectedReactionForExport);
          file = await ExportService.instance.generateReactionsCsv(mechanisms: rxn != null ? [rxn] : mechanisms);
        }
      }

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.success,
          content: Text(
            isPdf
                ? '🟢 Reaction Dossier PDF Ready! Opening share sheet...'
                : '🟢 Reaction Catalog Spreadsheet Ready! Opening share sheet...',
          ),
          duration: const Duration(seconds: 3),
        ),
      );

      await ExportService.instance.shareFile(
        file,
        subject: _selectedReactionForExport == 'all'
            ? 'Chem Buddy MSc Reactions Compendium'
            : 'Chem Buddy - $_selectedReactionForExport Mechanism',
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          backgroundColor: AppColors.danger,
          content: Text('Failed to export reaction: $e'),
        ),
      );
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(appControllerProvider);
    final p = state.profile;
    final isConfigured = SupabaseService.instance.configured;

    final repo = ref.watch(chemRepositoryProvider);
    final overallStats = repo.overallStats();
    final analyticsService = ref.watch(studyAnalyticsServiceProvider);
    final analytics = analyticsService.computeSummary(streakDays: repo.streak());

    return ListView(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 110),
      children: [
        Row(
          children: [
            const Text('Profile & Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.w800, color: Colors.white)),
            const Spacer(),
            IconButton(
              icon: const Icon(Icons.edit_outlined, color: AppColors.purpleBright),
              tooltip: 'Edit Profile Details',
              onPressed: () => _editProfile(context, ref, p),
            ),
          ],
        ),
        const SizedBox(height: 14),

        // 1. STUDENT ACADEMIC PROFILE HERO CARD
        GlowCard(
          padding: const EdgeInsets.all(18),
          borderColor: AppColors.purple.withValues(alpha: 0.35),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.purpleBright, width: 2),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purple.withValues(alpha: 0.3),
                          blurRadius: 10,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: const AtomLogo(size: 52),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          p.fullName.isEmpty ? 'MSc Chemistry Scholar' : p.fullName,
                          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          p.registerNumber.isNotEmpty ? 'Reg: ${p.registerNumber}' : (p.email.isNotEmpty ? p.email : 'MSc Chemistry Student'),
                          style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
                        ),
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 6,
                          runSpacing: 4,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.purple.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Text(
                                '${p.university.isNotEmpty ? p.university : "University"} · Sem ${p.semester}',
                                style: const TextStyle(color: AppColors.purpleBright, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.statusSuccess.withValues(alpha: 0.18),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Text(
                                'Active Scholar 🎓',
                                style: TextStyle(color: AppColors.statusSuccess, fontSize: 11, fontWeight: FontWeight.w700),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // 2. QUICK ACADEMIC STATS STRIP
        Row(
          children: [
            Expanded(
              child: _buildMetricTile(
                label: 'Attendance',
                value: '${overallStats.percent.toStringAsFixed(0)}%',
                color: overallStats.percent >= 75 ? AppColors.statusSuccess : AppColors.statusDanger,
                icon: Icons.calendar_today_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                label: 'Quiz Accuracy',
                value: analytics.totalQuestionsAnswered > 0
                    ? '${analytics.overallQuizAccuracy.toStringAsFixed(0)}%'
                    : 'N/A',
                color: analytics.overallQuizAccuracy >= 70 ? AppColors.statusSuccess : AppColors.warning,
                icon: Icons.track_changes_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                label: 'Flashcards',
                value: '${analytics.flashcardsMatureCount}',
                color: AppColors.accentCyan,
                icon: Icons.flip_to_front_outlined,
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: _buildMetricTile(
                label: 'Streak',
                value: '${analytics.streakDays}d 🔥',
                color: AppColors.warning,
                icon: Icons.local_fire_department_outlined,
              ),
            ),
          ],
        ),
        const SizedBox(height: 18),

        // 3. UNIFIED REPORTS & ACADEMIC DATA EXPORT HUB
        const SectionTitle('Reports & Academic Data Export 📄📊'),
        GlowCard(
          padding: const EdgeInsets.all(16),
          borderColor: AppColors.purple.withValues(alpha: 0.45),
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
                    child: const Icon(Icons.download_for_offline_outlined, color: AppColors.purpleBright, size: 20),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Official Academic Audit Center', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white)),
                        Text('Export university-grade PDFs & Excel spreadsheets', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  if (_isExporting)
                    const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: AppColors.purpleBright),
                    ),
                ],
              ),
              const SizedBox(height: 14),

              // Segmented Tab Selector
              Container(
                padding: const EdgeInsets.all(3),
                decoration: BoxDecoration(
                  color: AppColors.surfaceElevated,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.border),
                ),
                child: Row(
                  children: [
                    _buildAuditSegmentTab(0, 'Attendance', Icons.event_available_rounded),
                    _buildAuditSegmentTab(1, 'Coursework', Icons.school_rounded),
                    _buildAuditSegmentTab(2, 'Reactions', Icons.science_rounded),
                  ],
                ),
              ),
              const SizedBox(height: 14),

              // Active Tab Content
              if (_selectedAuditTab == 0) _buildAttendanceAuditCard(overallStats),
              if (_selectedAuditTab == 1) _buildCourseworkAuditCard(analytics),
              if (_selectedAuditTab == 2) _buildReactionsAuditCard(),
            ],
          ),
        ),
        const SizedBox(height: 18),

        // 4. SUBJECT MANAGEMENT
        Row(
          children: [
            const SectionTitle('Enrolled Subjects'),
            const Spacer(),
            TextButton.icon(
              onPressed: () => _addSubject(context, ref),
              icon: const Icon(Icons.add, size: 16, color: AppColors.purpleBright),
              label: const Text('Add Subject', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
          ],
        ),
        for (final s in state.subjects)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: GlowCard(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    backgroundColor: Color(s.colorHex),
                    radius: 16,
                    child: Text(s.code.isNotEmpty ? s.code.substring(0, 1) : 'S', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 12)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(s.name, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: Colors.white)),
                        Text('${s.code} · ${s.teacher}', style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => _addSubject(context, ref, existing: s),
                    icon: const Icon(Icons.edit_outlined, size: 18, color: AppColors.textMuted),
                  ),
                  IconButton(
                    onPressed: () => ref.read(appControllerProvider.notifier).deleteSubject(s.id),
                    icon: const Icon(Icons.delete_outline, color: AppColors.danger, size: 18),
                  ),
                ],
              ),
            ),
          ),
        const SizedBox(height: 14),

        // 5. ACADEMIC HELP & SETTINGS
        const SectionTitle('Help, Guides & Settings ⚙️'),
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
                    Text('How to Use ChemBuddy', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
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
                    Text('Replay Onboarding Walkthrough', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('7-step interactive tour of ChemBuddy features', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: 8),
        GlowCard(
          onTap: () => Navigator.push(context, MaterialPageRoute<void>(builder: (_) => const NotificationSettingsScreen())),
          child: const Row(
            children: [
              Icon(Icons.notifications_active_outlined, color: AppColors.warning),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Class & Study Reminders', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                    Text('Configure alert timing and quiet hours', style: TextStyle(color: AppColors.textMuted, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: AppColors.textMuted),
            ],
          ),
        ),
        const SizedBox(height: 8),

        // 6. CLOUD SYNC STATUS
        GlowCard(
          child: Row(
            children: [
              Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                  color: isConfigured ? AppColors.success : AppColors.textMuted,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isConfigured ? 'Cloud Sync: Active (Supabase)' : 'Local Storage: Active (Offline)',
                      style: TextStyle(
                        fontWeight: FontWeight.w700,
                        color: isConfigured ? AppColors.success : Colors.white,
                        fontSize: 13,
                      ),
                    ),
                    Text(
                      isConfigured ? 'Notes & timetable sync across devices' : 'Data is stored securely on device in Hive',
                      style: const TextStyle(color: AppColors.textMuted, fontSize: 11.5),
                    ),
                  ],
                ),
              ),
              TextButton(
                onPressed: _testingConnection ? null : _testSync,
                child: _testingConnection
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : const Text('Test Sync', style: TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w700, fontSize: 12)),
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),
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

  Widget _buildAuditSegmentTab(int index, String label, IconData icon) {
    final isSelected = _selectedAuditTab == index;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedAuditTab = index),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.purple : Colors.transparent,
            borderRadius: BorderRadius.circular(9),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: isSelected ? Colors.white : AppColors.textMuted),
              const SizedBox(width: 5),
              Text(
                label,
                style: TextStyle(
                  color: isSelected ? Colors.white : AppColors.textMuted,
                  fontSize: 11.5,
                  fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAttendanceAuditCard(SubjectAttendanceStats stats) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.event_available_rounded, size: 16, color: AppColors.statusSuccess),
            const SizedBox(width: 6),
            const Text('Official Attendance Audit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: (stats.percent >= 75 ? AppColors.statusSuccess : AppColors.statusDanger).withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${stats.percent.toStringAsFixed(1)}% Overall',
                style: TextStyle(
                  color: stats.percent >= 75 ? AppColors.statusSuccess : AppColors.statusDanger,
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Subject-by-subject percentage audit, university cutoff compliance, safe skip margins, and complete attendance history.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.35),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isExporting ? null : () => _exportAttendance(isPdf: true),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                label: const Text('Export PDF 📄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accentCyan),
                  foregroundColor: AppColors.accentCyan,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isExporting ? null : () => _exportAttendance(isPdf: false),
                icon: const Icon(Icons.table_chart_outlined, size: 15),
                label: const Text('Excel / CSV 📊', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCourseworkAuditCard(StudyAnalyticsSummary analytics) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.school_rounded, size: 16, color: AppColors.purpleBright),
            const SizedBox(width: 6),
            const Text('Academic Coursework & Mastery Audit', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white)),
            const Spacer(),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.purple.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                '${analytics.totalQuizzesTaken} Quizzes Completed',
                style: const TextStyle(color: AppColors.purpleBright, fontSize: 11, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Detailed assessment of topic masteries, quiz accuracies, active recall flashcard retention rates, and revision logs.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.35),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isExporting ? null : () => _exportCoursework(isPdf: true),
                icon: const Icon(Icons.picture_as_pdf_rounded, size: 15),
                label: const Text('Export PDF 📄', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accentCyan),
                  foregroundColor: AppColors.accentCyan,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isExporting ? null : () => _exportCoursework(isPdf: false),
                icon: const Icon(Icons.table_chart_outlined, size: 15),
                label: const Text('Excel / CSV 📊', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildReactionsAuditCard() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Row(
          children: [
            Icon(Icons.science_rounded, size: 16, color: AppColors.accentCyan),
            SizedBox(width: 6),
            Text('MSc Reaction Mechanism Dossier', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5, color: Colors.white)),
          ],
        ),
        const SizedBox(height: 6),
        const Text(
          'Complete 21+ verified MSc organic reaction compendium with electron pushing notes and synthetic scope.',
          style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.35),
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          decoration: BoxDecoration(
            color: AppColors.surfaceElevated,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              isExpanded: true,
              value: _selectedReactionForExport,
              dropdownColor: AppColors.surfaceElevated,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600),
              items: [
                const DropdownMenuItem(
                  value: 'all',
                  child: Text('📚 Complete MSc Master Compendium (All 25+ Reactions)'),
                ),
                ...ReactionMechanismService.instance.mechanisms.map(
                  (m) => DropdownMenuItem(
                    value: m.id,
                    child: Text('⚗️ ${m.name}'),
                  ),
                ),
              ],
              onChanged: (val) {
                if (val != null) setState(() => _selectedReactionForExport = val);
              },
            ),
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.purple,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isExporting ? null : () => _exportReaction(isPdf: true),
                icon: const Icon(Icons.menu_book_rounded, size: 15),
                label: Text(
                  _selectedReactionForExport == 'all' ? 'Compendium PDF 📚' : 'Reaction PDF 📄',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.accentCyan),
                  foregroundColor: AppColors.accentCyan,
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                ),
                onPressed: _isExporting ? null : () => _exportReaction(isPdf: false),
                icon: const Icon(Icons.grid_on_rounded, size: 15),
                label: const Text('Excel / CSV 📊', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
              ),
            ),
          ],
        ),
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

  Future<void> _editProfile(BuildContext context, WidgetRef ref, UserProfile profile) async {
    final name = TextEditingController(text: profile.fullName);
    final regNo = TextEditingController(text: profile.registerNumber);
    final uni = TextEditingController(text: profile.university);
    var sem = profile.semester;

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
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Edit Profile Details 🎓', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 12),
                  TextField(
                    controller: name,
                    decoration: const InputDecoration(labelText: 'Full Name', hintText: 'Enter your full name'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: regNo,
                    decoration: const InputDecoration(labelText: 'Register / Roll Number', hintText: 'e.g. 24CHEM042'),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: uni,
                    decoration: const InputDecoration(labelText: 'University / Institute', hintText: 'e.g. BCU Central Campus'),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      const Text('Semester: ', style: TextStyle(fontWeight: FontWeight.w700, color: Colors.white)),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: sem,
                        dropdownColor: AppColors.surfaceElevated,
                        items: [1, 2, 3, 4].map((s) => DropdownMenuItem(value: s, child: Text('Semester $s'))).toList(),
                        onChanged: (v) {
                          if (v != null) setModal(() => sem = v);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(46),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
                    onPressed: () async {
                      final updated = profile.copyWith(
                        fullName: name.text.trim(),
                        registerNumber: regNo.text.trim(),
                        university: uni.text.trim(),
                        semester: sem,
                      );
                      await ref.read(appControllerProvider.notifier).saveProfile(updated);
                      if (ctx.mounted) Navigator.pop(ctx);
                    },
                    child: const Text('Save Profile Details', style: TextStyle(fontWeight: FontWeight.w700)),
                  ),
                ],
              );
            },
          ),
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
                  Text(existing == null ? 'Add Custom Subject' : 'Edit Subject', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: Colors.white)),
                  const SizedBox(height: 12),
                  TextField(controller: name, decoration: const InputDecoration(labelText: 'Subject Name')),
                  const SizedBox(height: 8),
                  TextField(controller: code, decoration: const InputDecoration(labelText: 'Subject Code (e.g. MCH101)')),
                  const SizedBox(height: 8),
                  TextField(controller: teacher, decoration: const InputDecoration(labelText: 'Faculty / Teacher Name')),
                  const SizedBox(height: 10),
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
                  const SizedBox(height: 14),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.purple,
                      foregroundColor: Colors.white,
                      minimumSize: const Size.fromHeight(44),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    ),
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
                    child: const Text('Save Subject', style: TextStyle(fontWeight: FontWeight.w700)),
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
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
              Icon(icon, size: 13, color: color),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(color: AppColors.textMuted, fontSize: 10.5, fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(
            value,
            style: TextStyle(color: color, fontSize: 14.5, fontWeight: FontWeight.w900),
          ),
        ],
      ),
    );
  }
}

class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 8),
      child: Text(text, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white)),
    );
  }
}
