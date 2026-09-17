import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../core/widgets/glow_card.dart';

/// Complete Walkthrough Guide for ChemDraw Mobile Canvas
/// Explains all tools, gestures, templates, and provides a step-by-step example (Aspirin).
class ChemDrawGuideDialog extends StatefulWidget {
  const ChemDrawGuideDialog({super.key, required this.onLoadExample});

  final ValueChanged<String> onLoadExample;

  static Future<void> show(BuildContext context, {required ValueChanged<String> onLoadExample}) {
    return showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (_) => ChemDrawGuideDialog(onLoadExample: onLoadExample),
    );
  }

  @override
  State<ChemDrawGuideDialog> createState() => _ChemDrawGuideDialogState();
}

class _ChemDrawGuideDialogState extends State<ChemDrawGuideDialog> {
  final PageController _pageController = PageController();
  int _currentStep = 0;
  static const int _totalSteps = 5;

  void _next() {
    if (_currentStep < _totalSteps - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      Navigator.pop(context);
    }
  }

  void _prev() {
    if (_currentStep > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        constraints: const BoxConstraints(maxWidth: 460, maxHeight: 650),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.4), width: 1.2),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.7),
              blurRadius: 28,
              offset: const Offset(0, 10),
            ),
            BoxShadow(
              color: AppColors.brandBright.withValues(alpha: 0.15),
              blurRadius: 36,
              spreadRadius: -4,
            ),
          ],
        ),
        child: Column(
          children: [
            // Top Bar: Step indicator, title & Close button
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 12, 8),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: AppColors.brandBright.withValues(alpha: 0.4)),
                    ),
                    child: Text(
                      'STEP ${_currentStep + 1} OF $_totalSteps',
                      style: const TextStyle(
                        color: AppColors.brandBright,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.1,
                        fontSize: 10.5,
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Expanded(
                    child: Text(
                      'ChemDraw Masterclass',
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.w800,
                        fontSize: 14.5,
                      ),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded, color: AppColors.textMuted, size: 20),
                    onPressed: () => Navigator.pop(context),
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
                  value: (_currentStep + 1) / _totalSteps,
                  backgroundColor: Colors.white10,
                  valueColor: const AlwaysStoppedAnimation<Color>(AppColors.brandBright),
                  minHeight: 4,
                ),
              ),
            ),

            // Scrollable Content PageView
            Expanded(
              child: PageView(
                controller: _pageController,
                onPageChanged: (i) => setState(() => _currentStep = i),
                children: [
                  _buildStep1Gestures(),
                  _buildStep2Templates(),
                  _buildStep3FunctionalGroups(),
                  _buildStep4ReactionsAndEditing(),
                  _buildStep5AspirinExample(),
                ],
              ),
            ),

            // Bottom Navigation Controls
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 8, 20, 18),
              child: Row(
                children: [
                  if (_currentStep > 0) ...[
                    OutlinedButton(
                      onPressed: _prev,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.textSecondary,
                        side: const BorderSide(color: AppColors.border),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                        backgroundColor: AppColors.brandPrimary,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        elevation: 4,
                      ),
                      child: Text(
                        _currentStep == _totalSteps - 1 ? 'Start Sketching 🚀' : 'Next Step →',
                        style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
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

  // Step 1: Canvas Essentials & Drawing Tools
  Widget _buildStep1Gestures() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge('CANVAS ESSENTIALS', Icons.touch_app_rounded, const Color(0xFF06B6D4)),
          const SizedBox(height: 10),
          const Text(
            'Touch-First Molecular Drawing 🎨',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Designed specifically for fingers and touchscreens with magnetic snapping.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          const _GuideCard(
            icon: Icons.add_circle_outline_rounded,
            color: Color(0xFF06B6D4),
            title: 'Place Atoms',
            description: 'Tap anywhere on the blank canvas to place an atom. Select from the bottom atom bar (C, N, O, S, P, Cl, Br, F, I, H).',
          ),
          const SizedBox(height: 8),
          const _GuideCard(
            icon: Icons.timeline_rounded,
            color: Color(0xFF06B6D4),
            title: 'Draw Bonds (Single, Double, Triple)',
            description: 'Drag from an existing atom into empty space to spawn a bonded atom, or drag between two existing atoms to connect them.',
          ),
          const SizedBox(height: 8),
          const _GuideCard(
            icon: Icons.filter_center_focus_rounded,
            color: Color(0xFF06B6D4),
            title: 'Smart Magnetic Snapping',
            description: 'When dragging near another atom, a bright cyan dashed preview automatically snaps to the target atom.',
          ),
          const SizedBox(height: 8),
          const _GuideCard(
            icon: Icons.pinch_rounded,
            color: Color(0xFF06B6D4),
            title: 'Pinch-to-Zoom & Pan',
            description: 'Pinch with two fingers to zoom from 0.3x to 3.0x. Drag with two fingers to pan. Tap 🔍 to reset.',
          ),
        ],
      ),
    );
  }

  // Step 2: Ring Templates
  Widget _buildStep2Templates() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge('MSc RING TEMPLATES', Icons.hexagon_outlined, const Color(0xFF8B5CF6)),
          const SizedBox(height: 10),
          const Text(
            'Fused Rings & Heterocycles ⬡',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Insert standard and advanced ring systems with a single tap from the Templates sheet.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          const _GuideCard(
            icon: Icons.hexagon_outlined,
            color: Color(0xFF8B5CF6),
            title: 'Standard Aromatics & Alicyclics',
            description: 'Benzene (with Kekulé alternating double bonds), Cyclohexane (chair-ready), Cyclopentane, Pyridine.',
          ),
          const SizedBox(height: 8),
          const _GuideCard(
            icon: Icons.view_quilt_rounded,
            color: Color(0xFF8B5CF6),
            title: 'Fused Bicyclic & Polycyclic Systems',
            description: 'Naphthalene (two fused 6-rings sharing an edge), Indole (benzene fused to pyrrole), Ferrocene, Adamantane, Steroid nucleus.',
          ),
          const SizedBox(height: 8),
          const _GuideCard(
            icon: Icons.lens_blur_rounded,
            color: Color(0xFF8B5CF6),
            title: 'MSc Heterocycles & Crown Ethers',
            description: 'Imidazole (1,3-diazole), Thiophene (sulfur ring), Furan (oxygen ring), and 18-Crown-6 (chelating macrocycle).',
          ),
        ],
      ),
    );
  }

  // Step 3: Functional Group Quick Palette
  Widget _buildStep3FunctionalGroups() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge('QUICK PALETTE', Icons.hub_rounded, const Color(0xFF10B981)),
          const SizedBox(height: 10),
          const Text(
            'Functional Groups at Your Fingertips 🌿',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Skip tedious sketching of common functional groups using the Quick Palette toolbar.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFgChip('—OH', 'Alcohol / Hydroxy'),
              _buildFgChip('—NH₂', 'Primary Amine'),
              _buildFgChip('—COOH', 'Carboxylic Acid'),
              _buildFgChip('—CHO', 'Aldehyde / Formyl'),
              _buildFgChip('—NO₂', 'Nitro Group'),
              _buildFgChip('—CN', 'Nitrile / Cyano'),
            ],
          ),
          const SizedBox(height: 14),
          const _GuideCard(
            icon: Icons.auto_fix_high_rounded,
            color: Color(0xFF10B981),
            title: 'How It Works',
            description: 'Tap on any atom in your structure, then tap any functional group button (e.g. —COOH). ChemDraw connects the substituent with accurate stereochemistry and correct bond valency.',
          ),
        ],
      ),
    );
  }

  // Step 4: Reactions, Eraser & Mechanisms
  Widget _buildStep4ReactionsAndEditing() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge('REACTIONS & EDITING', Icons.swap_horiz_rounded, const Color(0xFFF59E0B)),
          const SizedBox(height: 10),
          const Text(
            'Reactions, Arrows & Smart Eraser 🧹',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Draw complete chemical reactions and mechanism pathways right on canvas.',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          const _GuideCard(
            icon: Icons.arrow_forward_rounded,
            color: Color(0xFFF59E0B),
            title: 'Reaction Arrow Tool (→)',
            description: 'Select the arrow tool and drag horizontally on the canvas to draw reaction arrows separating starting materials and products.',
          ),
          const SizedBox(height: 8),
          const _GuideCard(
            icon: Icons.add_rounded,
            color: Color(0xFF06B6D4),
            title: 'Auto "+" Fragment Labels',
            description: 'When sketching multiple reactants side by side, ChemDraw automatically renders a bold cyan "+" symbol between separate fragments.',
          ),
          const SizedBox(height: 8),
          const _GuideCard(
            icon: Icons.auto_awesome_motion_rounded,
            color: Color(0xFFA855F7),
            title: 'Curved Mechanism Arrows (↷)',
            description: 'Drag from bond pairs or lone pairs to electrophilic centers to illustrate curved electron-pushing mechanisms for MSc exams.',
          ),
          const SizedBox(height: 8),
          const _GuideCard(
            icon: Icons.cleaning_services_rounded,
            color: Color(0xFFEF4444),
            title: 'Smart Eraser Tool (🧹)',
            description: 'Tap on any atom to erase it and connected bonds, or tap near a bond to delete just the bond cleanly.',
          ),
        ],
      ),
    );
  }

  // Step 5: Practical Example: How to Draw Aspirin
  Widget _buildStep5AspirinExample() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildBadge('PRACTICAL EXAMPLE', Icons.science_rounded, const Color(0xFF38BDF8)),
          const SizedBox(height: 10),
          const Text(
            'Step-by-Step: Drawing Aspirin 💊',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 6),
          const Text(
            'Follow this 4-step walkthrough to sketch Acetylsalicylic Acid (Aspirin):',
            style: TextStyle(color: AppColors.textSecondary, fontSize: 12.5, height: 1.35),
          ),
          const SizedBox(height: 14),
          const GlowCard(
            padding: EdgeInsets.all(12),
            child: Column(
              children: [
                _StepRow(num: '1', title: 'Insert Benzene Ring', text: 'Tap Templates (Hexagon icon) and choose Benzene.'),
                _StepRow(num: '2', title: 'Add Carboxylic Acid', text: 'Select Carbon 1 and tap —COOH from the Quick Palette.'),
                _StepRow(num: '3', title: 'Attach Acetoxy Ester', text: 'Select adjacent Carbon 2, tap —OH, then extend with —C(=O)CH₃.'),
                _StepRow(num: '4', title: 'Calculate & Predict', text: 'Tap RDKit to inspect MW (180.16 g/mol) or ⚡ Predict to run AI reactions.', isLast: true),
              ],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF06B6D4),
                foregroundColor: Colors.black,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 4,
              ),
              onPressed: () {
                AppHaptics.confirm();
                Navigator.pop(context);
                widget.onLoadExample('CC(=O)Oc1ccccc1C(=O)O');
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('✓ Loaded Aspirin structure onto ChemDraw canvas!'),
                    backgroundColor: Color(0xFF0F172A),
                    duration: Duration(seconds: 2),
                  ),
                );
              },
              icon: const Icon(Icons.play_circle_fill_rounded, size: 20),
              label: const Text(
                'Try Aspirin Example Now 🚀',
                style: TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBadge(String title, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            title,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.w800,
              fontSize: 10.5,
              letterSpacing: 0.8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFgChip(String formula, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            formula,
            style: const TextStyle(color: AppColors.present, fontWeight: FontWeight.w800, fontSize: 12),
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: const TextStyle(color: AppColors.textMuted, fontSize: 11),
          ),
        ],
      ),
    );
  }
}

class _GuideCard extends StatelessWidget {
  const _GuideCard({
    required this.icon,
    required this.color,
    required this.title,
    required this.description,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String description;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.8),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.white.withValues(alpha: 0.07)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(7),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 13,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  description,
                  style: const TextStyle(
                    color: AppColors.textSecondary,
                    fontSize: 11.5,
                    height: 1.35,
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

class _StepRow extends StatelessWidget {
  const _StepRow({
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
      padding: EdgeInsets.only(bottom: isLast ? 0 : 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 22,
            height: 22,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.brandPrimary.withValues(alpha: 0.25),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: AppColors.brandBright.withValues(alpha: 0.5)),
            ),
            child: Text(
              num,
              style: const TextStyle(
                color: AppColors.brandBright,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: Colors.white)),
                const SizedBox(height: 2),
                Text(text, style: const TextStyle(fontSize: 11, color: AppColors.textSecondary, height: 1.3)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
