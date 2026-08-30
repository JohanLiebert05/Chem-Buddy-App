import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../core/theme/app_colors.dart';
import '../../core/widgets/atom_logo.dart';
import '../../core/widgets/glow_card.dart';
import '../providers/app_providers.dart';

class BeginnerTutorialDialog extends ConsumerStatefulWidget {
  const BeginnerTutorialDialog({super.key, this.onFinished});
  final VoidCallback? onFinished;

  static Future<void> show(BuildContext context, {VoidCallback? onFinished}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => BeginnerTutorialDialog(onFinished: onFinished),
    );
  }

  @override
  ConsumerState<BeginnerTutorialDialog> createState() => _BeginnerTutorialDialogState();
}

class _BeginnerTutorialDialogState extends ConsumerState<BeginnerTutorialDialog> {
  final PageController _controller = PageController();
  int _step = 0;
  static const int _totalSteps = 7;

  void _next() {
    if (_step < _totalSteps - 1) {
      _controller.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _prev() {
    if (_step > 0) {
      _controller.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  Future<void> _finish() async {
    await ref.read(appControllerProvider.notifier).setTutorialCompleted(true);
    if (mounted) {
      Navigator.of(context).pop();
      widget.onFinished?.call();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 620),
        decoration: BoxDecoration(
          color: const Color(0xF5161822),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.purple.withValues(alpha: 0.3), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.6),
              blurRadius: 24,
              offset: const Offset(0, 8),
            ),
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.15),
              blurRadius: 30,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Bar with step indicator & Skip button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 16, 8),
              child: Row(
                children: [
                  Text(
                    'STEP ${_step + 1} OF $_totalSteps',
                    style: const TextStyle(
                      color: AppColors.purpleBright,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.2,
                      fontSize: 11,
                    ),
                  ),
                  const Spacer(),
                  if (_step < _totalSteps - 1)
                    TextButton(
                      onPressed: _finish,
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        minimumSize: Size.zero,
                        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      ),
                      child: const Text(
                        'Skip',
                        style: TextStyle(color: AppColors.textMuted, fontSize: 12),
                      ),
                    ),
                ],
              ),
            ),

            // Progress bar
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: (_step + 1) / _totalSteps,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.purpleBright),
                  minHeight: 4,
                ),
              ),
            ),

            // Main Page Content
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (i) => setState(() => _step = i),
                children: [
                  _buildStep1Welcome(),
                  _buildStep2Home(),
                  _buildStep3Timetable(),
                  _buildStep4Attendance(),
                  _buildStep5PdfLibrary(),
                  _buildStep6StudyWithAi(),
                  _buildStep7StudyRoutine(),
                ],
              ),
            ),

            // Bottom Navigation Buttons
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
              child: Row(
                children: [
                  if (_step > 0) ...[
                    OutlinedButton(
                      onPressed: _prev,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                      ),
                      child: const Text('Back'),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: ElevatedButton(
                      onPressed: _next,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.purple,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                        padding: const EdgeInsets.symmetric(vertical: 13),
                        elevation: 4,
                        shadowColor: AppColors.purple.withValues(alpha: 0.5),
                      ),
                      child: Text(
                        _step == _totalSteps - 1 ? 'Start Using ChemBuddy 🚀' : 'Next →',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. WELCOME
  Widget _buildStep1Welcome() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          const SizedBox(height: 10),
          const AtomLogo(size: 80, animated: true),
          const SizedBox(height: 16),
          Text(
            'Welcome to ChemBuddy 🧪',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your academic companion for MSc Chemistry.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.purpleBright,
              fontSize: 13.5,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          const GlowCard(
            padding: EdgeInsets.all(14),
            child: Text(
              'ChemBuddy is designed specifically for MSc Chemistry coursework. It helps you track classes, maintain safe attendance, organize subject notes, and study efficiently with grounded AI.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }

  // 2. HOME SCREEN
  Widget _buildStep2Home() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('HOME SCREEN', Icons.home_rounded),
          const SizedBox(height: 10),
          const Text(
            'Your Daily Command Center',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your Home screen gives you everything important for today — upcoming classes, attendance health, study progress, and quick access to your chemistry resources.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 16),
          GlowCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.purple.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.school, color: AppColors.purpleBright, size: 22),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Next Class Alert', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('Organic Spectroscopy · Room 204', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 3. TIMETABLE
  Widget _buildStep3Timetable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('TIMETABLE & OCR', Icons.calendar_month_rounded),
          const SizedBox(height: 10),
          const Text(
            'Organize Classes & Reminders',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload your timetable photo or enter classes manually. ChemBuddy uses it to organize your daily schedule and alert you before lectures.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          GlowCard(
            padding: const EdgeInsets.all(12),
            borderColor: AppColors.blue.withValues(alpha: 0.4),
            child: Row(
              children: [
                const Icon(Icons.document_scanner_rounded, color: AppColors.blue, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('AI Timetable OCR Scanner', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      SizedBox(height: 2),
                      Text('Snap a photo of your printed timetable and ChemBuddy reads it into editable slots automatically.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 4. ATTENDANCE
  Widget _buildStep4Attendance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('ATTENDANCE TRACKER', Icons.how_to_reg_rounded),
          const SizedBox(height: 10),
          const Text(
            'Stay Safe Above 75%',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Mark your attendance after each class. ChemBuddy calculates your overall percentage and attendance risk in real time.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          GlowCard(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text('82%', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w900, fontSize: 20)),
                ),
                const SizedBox(width: 14),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Safe to Bunk 🟢', style: TextStyle(color: AppColors.success, fontWeight: FontWeight.w700, fontSize: 13)),
                      SizedBox(height: 2),
                      Text('You can skip 3 more classes while staying safely above the 75% requirement.', style: TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 5. PDF LIBRARY
  Widget _buildStep5PdfLibrary() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('PDF LIBRARY', Icons.menu_book_rounded),
          const SizedBox(height: 10),
          const Text(
            'Chemistry Notes & Textbooks',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Store your chemistry PDFs, syllabus notes, and reference books here. Organize them by subject folders so you can find material in seconds.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.4),
          ),
          const SizedBox(height: 14),
          GlowCard(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                const Icon(Icons.folder_special, color: AppColors.purpleBright, size: 24),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Organic / Inorganic / Physical Folders', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                      Text('Offline local storage with quick-search and bookmarking.', style: TextStyle(color: AppColors.textMuted, fontSize: 11.5)),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 6. STUDY WITH AI
  Widget _buildStep6StudyWithAi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('STUDY WITH AI', Icons.auto_awesome_rounded),
          const SizedBox(height: 10),
          const Text(
            'Upload Notes & Let AI Guide You',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 8),
          const Text(
            'Upload any chemistry PDF and ChemBuddy breaks it down into an intelligent study routine:',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 13, height: 1.35),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.surfaceElevated,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
            ),
            child: const Column(
              children: [
                _FlowStep(label: '1. Summary', desc: 'Academic overview, formulas & key definitions'),
                _FlowStep(label: '2. Important Topics', desc: '🔥 Ranked priorities based on depth & exams'),
                _FlowStep(label: '3. Ask ChemBuddy', desc: 'Grounded tutor attached to your notes'),
                _FlowStep(label: '4. Smart Flashcards', desc: '10/20/30 cards for active spaced recall'),
                _FlowStep(label: '5. Practice Quiz', desc: 'Exam questions with weak-area diagnostics', isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 7. STUDY ROUTINE
  Widget _buildStep7StudyRoutine() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('STUDY ROUTINE', Icons.psychology_rounded),
          const SizedBox(height: 10),
          const Text(
            'Your Recommended Workflow',
            style: TextStyle(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 10),
          const GlowCard(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                _RoutineRow(num: '1', text: 'Check today\'s classes & room numbers'),
                _RoutineRow(num: '2', text: 'Mark attendance right after lecture'),
                _RoutineRow(num: '3', text: 'Upload or open course notes in PDF Library'),
                _RoutineRow(num: '4', text: 'Identify High Priority topics with AI'),
                _RoutineRow(num: '5', text: 'Ask ChemBuddy about difficult mechanisms'),
                _RoutineRow(num: '6', text: 'Generate 10 flashcards for active recall'),
                _RoutineRow(num: '7', text: 'Take a practice quiz before tests'),
                _RoutineRow(num: '8', text: 'Review weak topics highlighted in results', isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String title, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.purple.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: AppColors.purpleBright, size: 14),
          const SizedBox(width: 6),
          Text(
            title,
            style: const TextStyle(
              color: AppColors.purpleBright,
              fontWeight: FontWeight.w800,
              fontSize: 11,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _FlowStep extends StatelessWidget {
  const _FlowStep({required this.label, required this.desc, this.isLast = false});
  final String label;
  final String desc;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.only(top: 4, right: 8),
            decoration: const BoxDecoration(
              color: AppColors.purpleBright,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(color: AppColors.textSecondary, fontSize: 12),
                children: [
                  TextSpan(text: '$label: ', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
                  TextSpan(text: desc),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({required this.num, required this.text, this.isLast = false});
  final String num;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 6),
      child: Row(
        children: [
          Container(
            width: 20,
            height: 20,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Text(
              num,
              style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(color: AppColors.textSecondary, fontSize: 12.5),
            ),
          ),
        ],
      ),
    );
  }
}
