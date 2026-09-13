import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import '../../core/chemistry/mechanism_svg_renderer.dart';
import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../data/services/reaction_curation_repository.dart';

/// Interactive, animated mechanism viewer for MSc organic chemistry students.
/// Features step-by-step playback, pinch-to-zoom, active site highlighting,
/// and pedagogical step explanations.
class AnimatedMechanismViewer extends StatefulWidget {
  final CuratedReaction reaction;
  final int initialStepIndex;

  const AnimatedMechanismViewer({
    super.key,
    required this.reaction,
    this.initialStepIndex = 0,
  });

  @override
  State<AnimatedMechanismViewer> createState() => _AnimatedMechanismViewerState();
}

class _AnimatedMechanismViewerState extends State<AnimatedMechanismViewer> {
  late int _currentStepIndex;
  bool _isPlaying = false;
  Timer? _playbackTimer;
  final TransformationController _transformController = TransformationController();

  List<CuratedReactionStep> get _steps => widget.reaction.steps;

  @override
  void initState() {
    super.initState();
    _currentStepIndex = widget.initialStepIndex.clamp(0, _steps.isEmpty ? 0 : _steps.length - 1);
  }

  @override
  void dispose() {
    _playbackTimer?.cancel();
    _transformController.dispose();
    super.dispose();
  }

  void _togglePlayPause() {
    AppHaptics.confirm();
    setState(() {
      _isPlaying = !_isPlaying;
      if (_isPlaying) {
        _startPlayback();
      } else {
        _playbackTimer?.cancel();
      }
    });
  }

  void _startPlayback() {
    _playbackTimer?.cancel();
    _playbackTimer = Timer.periodic(const Duration(milliseconds: 3200), (timer) {
      if (!mounted) return;
      if (_currentStepIndex < _steps.length - 1) {
        setState(() {
          _currentStepIndex++;
        });
      } else {
        // Loop back to beginning
        setState(() {
          _currentStepIndex = 0;
        });
      }
      _resetZoom();
    });
  }

  void _goToStep(int index) {
    if (index >= 0 && index < _steps.length) {
      AppHaptics.selection();
      setState(() {
        _currentStepIndex = index;
        if (_isPlaying) {
          _playbackTimer?.cancel();
          _isPlaying = false;
        }
      });
      _resetZoom();
    }
  }

  void _resetZoom() {
    _transformController.value = Matrix4.identity();
  }

  @override
  Widget build(BuildContext context) {
    if (_steps.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(24),
        decoration: BoxDecoration(
          color: const Color(0xFF0F172A),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF1E293B)),
        ),
        child: const Center(
          child: Text(
            'No mechanism steps available for this reaction.',
            style: TextStyle(color: Color(0xFF94A3B8), fontSize: 14),
          ),
        ),
      );
    }

    final step = _steps[_currentStepIndex];
    final String svgContent;
    if (step.intermediateGraph != null) {
      svgContent = MechanismSvgRenderer.renderStep(
        graph: step.intermediateGraph!,
        electronFlows: step.electronFlows,
        stepTitle: 'Step ${step.stepNumber}: ${step.stepTitle}',
        stepDescription: step.stepDescription,
        transitionStateNote: step.isRds
            ? 'Rate-Determining (RDS)'
            : (step.isReversible ? 'Equilibrium (Reversible)' : null),
      );
    } else {
      svgContent = MechanismSvgRenderer.renderAiStepSvg(
        stepNumber: step.stepNumber,
        stepTitle: step.stepTitle,
        intermediateSmiles: step.intermediateSmiles,
        electronPushing: step.bondChanges,
        stepDescription: step.stepDescription,
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF0F172A),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF1E293B)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha:0.4),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Header Bar with Reaction Title & Step Badges
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 12),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppColors.electricViolet.withValues(alpha:0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.account_tree_rounded,
                    color: AppColors.electricViolet,
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.reaction.reactionName,
                        style: const TextStyle(
                          color: Color(0xFFF8FAFC),
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'Step ${_currentStepIndex + 1} of ${_steps.length}',
                        style: const TextStyle(
                          color: Color(0xFF38BDF8),
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (step.isRds)
                  Container(
                    margin: const EdgeInsets.only(right: 6),
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha:0.15),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha:0.5)),
                    ),
                    child: const Text(
                      'RDS',
                      style: TextStyle(
                        color: Color(0xFFFBBF24),
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: _resetZoom,
                  icon: const Icon(Icons.refresh_rounded, color: Color(0xFF94A3B8), size: 20),
                  tooltip: 'Reset Zoom',
                ),
              ],
            ),
          ),

          // 2. Interactive SVG Canvas with Zoom and Pan
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              height: 260,
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: const Color(0xFF0B1120),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF1E293B)),
              ),
              child: InteractiveViewer(
                transformationController: _transformController,
                minScale: 0.6,
                maxScale: 3.5,
                child: Center(
                  child: SvgPicture.string(
                    svgContent,
                    fit: BoxFit.contain,
                  ),
                ),
              ),
            ),
          ),

          // 3. Step Title & Pedagogical Description
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      step.stepTitle,
                      style: const TextStyle(
                        color: Color(0xFFF1F5F9),
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const Spacer(),
                    if (step.isReversible)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF8B5CF6).withValues(alpha:0.15),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: const Text(
                          '⇌ Reversible',
                          style: TextStyle(color: Color(0xFFA78BFA), fontSize: 10, fontWeight: FontWeight.w600),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  step.stepDescription,
                  style: const TextStyle(
                    color: Color(0xFF94A3B8),
                    fontSize: 13,
                    height: 1.45,
                  ),
                ),
                if (step.bondChanges.isNotEmpty || step.chargeChanges.isNotEmpty) ...[
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: [
                      if (step.bondChanges.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0284C7).withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFF0284C7).withValues(alpha:0.3)),
                          ),
                          child: Text(
                            'Bonds: ${step.bondChanges}',
                            style: const TextStyle(color: Color(0xFF38BDF8), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                      if (step.chargeChanges.isNotEmpty)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEC4899).withValues(alpha:0.15),
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(color: const Color(0xFFEC4899).withValues(alpha:0.3)),
                          ),
                          child: Text(
                            'Charges: ${step.chargeChanges}',
                            style: const TextStyle(color: Color(0xFFF472B6), fontSize: 11, fontWeight: FontWeight.w500),
                          ),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),

          // 4. Playback Controls & Step Slider Bar
          Container(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: Color(0xFF1E293B))),
            ),
            child: Row(
              children: [
                // Previous Step Button
                IconButton(
                  onPressed: _currentStepIndex > 0 ? () => _goToStep(_currentStepIndex - 1) : null,
                  icon: const Icon(Icons.skip_previous_rounded),
                  color: const Color(0xFF38BDF8),
                  disabledColor: const Color(0xFF334155),
                  tooltip: 'Previous Step',
                ),

                // Play / Pause Button
                Container(
                  decoration: BoxDecoration(
                    color: AppColors.electricViolet,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.electricViolet.withValues(alpha:0.4),
                        blurRadius: 8,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: IconButton(
                    onPressed: _togglePlayPause,
                    icon: Icon(_isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded),
                    color: Colors.white,
                    tooltip: _isPlaying ? 'Pause' : 'Auto Play',
                  ),
                ),

                // Next Step Button
                IconButton(
                  onPressed: _currentStepIndex < _steps.length - 1 ? () => _goToStep(_currentStepIndex + 1) : null,
                  icon: const Icon(Icons.skip_next_rounded),
                  color: const Color(0xFF38BDF8),
                  disabledColor: const Color(0xFF334155),
                  tooltip: 'Next Step',
                ),

                const SizedBox(width: 8),

                // Step Dots
                Expanded(
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(_steps.length, (idx) {
                      final isCurrent = idx == _currentStepIndex;
                      return GestureDetector(
                        onTap: () => _goToStep(idx),
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 250),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: isCurrent ? 24 : 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: isCurrent ? const Color(0xFF38BDF8) : const Color(0xFF334155),
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      );
                    }),
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
