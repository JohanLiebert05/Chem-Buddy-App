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
                  _buildStep2ChemDraw(),
                  _buildStep3GeminiAi(),
                  _buildStep4HandwrittenNotes(),
                  _buildStep5Attendance(),
                  _buildStep6Timetable(),
                  _buildStep7StudyWorkflow(),
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
          const SizedBox(height: 8),
          const AtomLogo(size: 72, animated: true),
          const SizedBox(height: 14),
          Text(
            'Welcome to ChemBuddy 🧪',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 21,
              fontWeight: FontWeight.w800,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Chem Buddy by Prajwal A Kambar\nattendance, tests, and notes for MSc Chemistry students.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.purpleBright,
              fontSize: 12.5,
              fontWeight: FontWeight.w700,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 14),
          const GlowCard(
            padding: EdgeInsets.all(14),
            child: Text(
              'Your all-in-one companion for postgraduate chemistry. Calculate attendance & safe bunk limits, switch Organic & Inorganic timetables, study reference PDFs, sketch molecules in ChemDraw, and master mechanisms with ChemBuddy AI.',
              textAlign: TextAlign.center,
              style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.45),
            ),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            alignment: WrapAlignment.center,
            children: const [
              _FeatureChip(icon: '📊', label: 'Attendance & Safe Bunks'),
              _FeatureChip(icon: '📅', label: 'Timetable Presets'),
              _FeatureChip(icon: '📖', label: 'PDF Library & Notes'),
              _FeatureChip(icon: '🎨', label: 'ChemDraw Canvas'),
              _FeatureChip(icon: '⚡', label: 'ChemBuddy AI Tutor'),
              _FeatureChip(icon: '📸', label: 'Notes to Flashcards'),
              _FeatureChip(icon: '📝', label: 'Tests & Quizzes'),
            ],
          ),
        ],
      ),
    );
  }

  // 2. CHEMDRAW CANVAS (NEW FEATURE)
  Widget _buildStep2ChemDraw() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('NEW · CHEMDRAW CANVAS', Icons.draw_rounded, color: const Color(0xFF06B6D4)),
          const SizedBox(height: 10),
          const Text(
            'Interactive Chemical Sketcher 🎨',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Draw molecules and reaction mechanisms with a touch-first canvas.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          const _TourCard(
            icon: Icons.hexagon_outlined,
            iconColor: Color(0xFF06B6D4),
            title: 'Ring Templates & Fused Systems',
            description: 'One-tap insertion for Benzene, Cyclohexane, Naphthalene, Indole, Ferrocene, and crown ethers.',
          ),
          const SizedBox(height: 8),
          const _TourCard(
            icon: Icons.hub_rounded,
            iconColor: Color(0xFF06B6D4),
            title: 'Functional Groups & Smart Snapping',
            description: 'Quick-insert palette (—OH, —COOH, —NO₂, —CHO) with automatic magnetic bond snapping.',
          ),
          const SizedBox(height: 8),
          const _TourCard(
            icon: Icons.arrow_forward_rounded,
            iconColor: Color(0xFF06B6D4),
            title: 'Reaction Arrows & Predictor',
            description: 'Draw multi-reactant reactions with "+" symbols, mechanism arrows, and instant AI reaction prediction.',
          ),
        ],
      ),
    );
  }

  // 3. GEMINI AI TUTOR
  Widget _buildStep3GeminiAi() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('CHEMBUDDY AI TUTOR', Icons.auto_awesome_rounded, color: const Color(0xFFA855F7)),
          const SizedBox(height: 10),
          const Text(
            'Intelligent Academic Tutor ⚡',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Powered by intelligent academic reasoning with dedicated modes for MSc studies.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          const _TourCard(
            icon: Icons.psychology_rounded,
            iconColor: Color(0xFFA855F7),
            title: '✨ General AI & Internet Access',
            description: 'Ask any chemistry, scientific, or research question with live internet intelligence and multi-key failover.',
          ),
          const SizedBox(height: 8),
          const _TourCard(
            icon: Icons.compare_arrows_rounded,
            iconColor: Color(0xFFA855F7),
            title: 'Step-by-Step Reaction Mechanisms',
            description: 'Arrow-pushing, reaction intermediates, stereochemistry, and transition states explained clearly.',
          ),
          const SizedBox(height: 8),
          const _TourCard(
            icon: Icons.graphic_eq_rounded,
            iconColor: Color(0xFFA855F7),
            title: 'Spectroscopy Deciphering',
            description: 'Decode NMR proton splits, IR absorption bands, and mass spectrometry fragmentation effortlessly.',
          ),
        ],
      ),
    );
  }

  // 4. NOTES TO FLASHCARDS (OCR)
  Widget _buildStep4HandwrittenNotes() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('AI OCR & FLASHCARDS', Icons.document_scanner_rounded, color: const Color(0xFF3B82F6)),
          const SizedBox(height: 10),
          const Text(
            'Handwritten Notes → Flashcards 📸',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Convert classroom notes and blackboard photos into study sets in seconds.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          const _TourCard(
            icon: Icons.camera_alt_rounded,
            iconColor: Color(0xFF3B82F6),
            title: 'Multi-Page Photo Scanning',
            description: 'Snap photos with your camera or select multiple notebook pages directly from your gallery.',
          ),
          const SizedBox(height: 8),
          const _TourCard(
            icon: Icons.spellcheck_rounded,
            iconColor: Color(0xFF3B82F6),
            title: 'Chemistry Formula OCR',
            description: 'Advanced vision AI extracts molecular formulas, synthesis steps, and reaction conditions accurately.',
          ),
          const SizedBox(height: 8),
          const _TourCard(
            icon: Icons.style_rounded,
            iconColor: Color(0xFF3B82F6),
            title: 'Active Spaced Repetition',
            description: 'Review cards with self-grading (Easy, Difficult, Skip) to lock difficult mechanisms into long-term memory.',
          ),
        ],
      ),
    );
  }

  // 5. ATTENDANCE & SAFE BUNKS
  Widget _buildStep5Attendance() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('ATTENDANCE INTELLIGENCE', Icons.how_to_reg_rounded, color: const Color(0xFF10B981)),
          const SizedBox(height: 10),
          const Text(
            'Stay Confidently Above 75% 📊',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Real-time calculations so you never risk university attendance shortages.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          const _TourCard(
            icon: Icons.check_circle_outline_rounded,
            iconColor: Color(0xFF10B981),
            title: 'Live "Can Skip" Buffer',
            description: 'Knows exactly how many lectures you can miss while staying safely above the 75% requirement.',
          ),
          const SizedBox(height: 8),
          const _TourCard(
            icon: Icons.trending_up_rounded,
            iconColor: Color(0xFF10B981),
            title: 'Recovery Roadmap',
            description: 'In the warning zone? ChemBuddy calculates the exact number of consecutive classes needed to recover.',
          ),
          const SizedBox(height: 8),
          const _TourCard(
            icon: Icons.filter_list_rounded,
            iconColor: Color(0xFF10B981),
            title: 'Multi-Target Buffers',
            description: 'Target 75%, 80%, 85%, or 90% with full Excused and On-Duty attendance preservation.',
          ),
        ],
      ),
    );
  }

  // 6. TIMETABLE & SCHEDULE
  Widget _buildStep6Timetable() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('SMART TIMETABLE', Icons.calendar_month_rounded, color: const Color(0xFFF59E0B)),
          const SizedBox(height: 10),
          const Text(
            'Your Daily Command Center 📅',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Your day at a glance. Class timings, room locations, and lecture alerts.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          const _TourCard(
            icon: Icons.school_rounded,
            iconColor: Color(0xFFF59E0B),
            title: 'MSc Timetable Presets',
            description: 'Pre-loaded schedules for Organic and Inorganic MSc chemistry streams with faculty mapping.',
          ),
          const SizedBox(height: 8),
          const _TourCard(
            icon: Icons.photo_size_select_actual_rounded,
            iconColor: Color(0xFFF59E0B),
            title: 'Pinch-to-Zoom Reference Photo',
            description: 'Keep your official printed department schedule handy with instant pinch-to-zoom access.',
          ),
          const SizedBox(height: 8),
          const _TourCard(
            icon: Icons.notifications_active_rounded,
            iconColor: Color(0xFFF59E0B),
            title: 'Lecture Reminders',
            description: 'Automated notifications before each class so you always reach the right lecture hall on time.',
          ),
        ],
      ),
    );
  }

  // 7. STUDY ROUTINE
  Widget _buildStep7StudyWorkflow() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _badge('STUDY ROUTINE', Icons.rocket_launch_rounded, color: const Color(0xFFA855F7)),
          const SizedBox(height: 10),
          const Text(
            'The 5-Step Academic Routine 🚀',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Proven daily routine for top marks in university exams.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 12),
          const GlowCard(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                _RoutineRow(num: '1', title: 'Morning Schedule', text: 'Check today\'s classes, timings, and lecture halls.'),
                _RoutineRow(num: '2', title: 'Mark Attendance', text: 'Tap Present right after each lecture to update your safe bunk buffer.'),
                _RoutineRow(num: '3', title: 'Sketch & Scan', text: 'Draw structures in ChemDraw or snap photos of lecture notes.'),
                _RoutineRow(num: '4', title: 'Active Recall', text: 'Review 10 flashcards daily to cement reaction mechanisms.'),
                _RoutineRow(num: '5', title: 'Exam Readiness', text: 'Test yourself with AI quizzes and review weak topic diagnostics.', isLast: true),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _badge(String title, IconData icon, {Color? color}) {
    final c = color ?? AppColors.purpleBright;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: c.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: c.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: c, size: 14),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: c,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }
}

class _TourCard extends StatelessWidget {
  const _TourCard({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: iconColor.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: iconColor, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  description,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.35),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  const _FeatureChip({required this.icon, required this.label});
  final String icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 12)),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

class _RoutineRow extends StatelessWidget {
  const _RoutineRow({
    required this.num,
    required this.title,
    required this.text,
    this.isLast = false,
  });

  final String num;
  final String title;
  final String text;
  final bool isLast;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: isLast ? 0 : 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.purple.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.purpleBright.withValues(alpha: 0.4)),
            ),
            child: Text(
              num,
              style: const TextStyle(color: AppColors.purpleBright, fontWeight: FontWeight.w800, fontSize: 11),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12.5, color: Colors.white),
                ),
                const SizedBox(height: 1),
                Text(
                  text,
                  style: const TextStyle(color: AppColors.textSecondary, fontSize: 11.5, height: 1.3),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
