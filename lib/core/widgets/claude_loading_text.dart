import 'dart:async';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Intellectual, reflective microcopy in the distinctive analytical voice of Claude.
/// Reflects transparent reasoning, deep subject evaluation, and multi-step cognitive distillation.
class ClaudeThinkingMicrocopy {
  ClaudeThinkingMicrocopy._();

  /// For Ask ChemBuddy conversational queries
  static const List<String> askAi = [
    'Thinking...',
    'Interpreting question context & chemical principles...',
    'Evaluating reaction pathways & transition state stability...',
    'Analyzing orbital symmetry & stereochemical consequences...',
    'Cross-referencing syllabus concepts with verified literature...',
    'Structuring step-by-step academic explanation...',
    'Polishing chemical equations & final response...',
  ];

  /// For Quiz Generation from PDFs or Syllabus topics
  static const List<String> quiz = [
    'Thinking...',
    'Reviewing syllabus scope & core MSc examination objectives...',
    'Formulating diagnostic question stems & conceptual problems...',
    'Engineering plausible, chemically sound distractors...',
    'Verifying stoichiometric balance & answer justifications...',
    'Calibrating difficulty curve for comprehensive assessment...',
    'Assembling balanced MSc chemistry quiz deck...',
  ];

  /// For Flashcard Deck Creation
  static const List<String> flashcards = [
    'Thinking...',
    'Scanning lecture material & extracting high-yield definitions...',
    'Distilling reaction mechanisms & key reagent conditions...',
    'Structuring active-recall prompt & response pairs...',
    'Tagging stereochemical nuances & driving forces...',
    'Calibrating spaced repetition review intervals...',
    'Assembling your personalized revision deck...',
  ];

  /// For Exam Question Prediction & Past Paper Analysis
  static const List<String> predictQuestions = [
    'Thinking...',
    'Deconstructing previous years\' university examination papers...',
    'Mapping topic recurrence & mark distributions across semesters...',
    'Detecting high-frequency 2-mark, 5-mark, and 10-mark patterns...',
    'Correlating named reactions, derivations, and spectroscopic problems...',
    'Compiling prioritized, high-probability exam dossier...',
  ];

  /// For Document & Study Hub Summarization
  static const List<String> summary = [
    'Thinking...',
    'Extracting conceptual architecture from study material...',
    'Cataloging primary equations, theorems, and mechanisms...',
    'Distilling key definitions and high-probability exam topics...',
    'Synthesizing structured academic overview...',
  ];

  /// For Spectroscopy & Structure Deduction
  static const List<String> spectroscopy = [
    'Thinking...',
    'Calculating Degrees of Unsaturation (DBE / IHD)...',
    'Correlating FT-IR characteristic stretching & bending frequencies...',
    'Assigning ¹H NMR chemical shifts & spin-spin splitting...',
    'Correlating ¹³C NMR & DEPT carbon multiplicities...',
    'Evaluating mass spec fragmentation & isotopic abundance...',
    'Deducing congruent molecular structure...',
  ];
}

/// A text widget with a continuous, fluid horizontal shimmer wave sweep
/// reminiscent of Claude's signature loading states.
class ClaudeShimmerText extends StatefulWidget {
  final String text;
  final TextStyle? style;
  final TextAlign textAlign;
  final int? maxLines;
  final TextOverflow overflow;
  final Duration duration;
  final Color? baseColor;
  final Color? highlightColor;

  const ClaudeShimmerText(
    this.text, {
    super.key,
    this.style,
    this.textAlign = TextAlign.start,
    this.maxLines,
    this.overflow = TextOverflow.clip,
    this.duration = const Duration(milliseconds: 1900),
    this.baseColor,
    this.highlightColor,
  });

  @override
  State<ClaudeShimmerText> createState() => _ClaudeShimmerTextState();
}

class _ClaudeShimmerTextState extends State<ClaudeShimmerText>
    with SingleTickerProviderStateMixin {
  late final AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController(
      vsync: this,
      duration: widget.duration,
    )..repeat();
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final base = widget.baseColor ?? const Color(0xFFE2E8F0).withValues(alpha: 0.85);
    final highlight = widget.highlightColor ?? Colors.white;

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final progress = _shimmerController.value;
        return ShaderMask(
          blendMode: BlendMode.srcIn,
          shaderCallback: (bounds) {
            final double width = bounds.width > 0 ? bounds.width : 200.0;

            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                base,
                base,
                highlight,
                AppColors.purpleBright,
                highlight,
                base,
                base,
              ],
              stops: const [0.0, 0.25, 0.45, 0.52, 0.60, 0.80, 1.0],
              transform: _GradientSlideTransform(
                progress: progress,
                boundsWidth: width,
              ),
            ).createShader(bounds);
          },
          child: Text(
            widget.text,
            textAlign: widget.textAlign,
            maxLines: widget.maxLines,
            overflow: widget.overflow,
            style: widget.style ??
                const TextStyle(
                  fontSize: 13.5,
                  fontWeight: FontWeight.w600,
                  letterSpacing: -0.2,
                  color: Colors.white,
                ),
          ),
        );
      },
    );
  }
}

class _GradientSlideTransform extends GradientTransform {
  final double progress;
  final double boundsWidth;

  const _GradientSlideTransform({
    required this.progress,
    required this.boundsWidth,
  });

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    // Translate from -boundsWidth to +boundsWidth
    final dx = (progress * 2.0 - 1.0) * bounds.width;
    return Matrix4.translationValues(dx, 0.0, 0.0);
  }
}

/// A Claude-inspired animated thinking indicator that presents a rotating sequence
/// of intellectual, reflective reasoning thoughts with smooth slide-fade transitions
/// and a shimmering text animation.
class ClaudeThinkingIndicator extends StatefulWidget {
  final List<String> thoughts;
  final Duration thoughtInterval;
  final bool isCard;
  final bool showSparkle;
  final bool showThinkingHeader;
  final String thinkingHeader;
  final double fontSize;
  final EdgeInsetsGeometry? padding;
  final VoidCallback? onCancel;

  const ClaudeThinkingIndicator({
    super.key,
    required this.thoughts,
    this.thoughtInterval = const Duration(milliseconds: 2300),
    this.isCard = false,
    this.showSparkle = true,
    this.showThinkingHeader = true,
    this.thinkingHeader = 'Thinking',
    this.fontSize = 13.5,
    this.padding,
    this.onCancel,
  });

  @override
  State<ClaudeThinkingIndicator> createState() => _ClaudeThinkingIndicatorState();
}

class _ClaudeThinkingIndicatorState extends State<ClaudeThinkingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _pulseController;
  Timer? _cycleTimer;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _startCycle();
  }

  void _startCycle() {
    _cycleTimer?.cancel();
    if (widget.thoughts.length > 1) {
      _cycleTimer = Timer.periodic(widget.thoughtInterval, (_) {
        if (mounted) {
          setState(() {
            _currentIndex = (_currentIndex + 1) % widget.thoughts.length;
          });
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant ClaudeThinkingIndicator oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.thoughts != oldWidget.thoughts ||
        widget.thoughtInterval != oldWidget.thoughtInterval) {
      _currentIndex = 0;
      _startCycle();
    }
  }

  @override
  void dispose() {
    _cycleTimer?.cancel();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final thought = widget.thoughts.isNotEmpty
        ? widget.thoughts[_currentIndex % widget.thoughts.length]
        : 'Thinking...';

    Widget content = Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        if (widget.showSparkle) ...[
          AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final scale = 0.88 + (_pulseController.value * 0.22);
              final opacity = 0.70 + (_pulseController.value * 0.30);
              return Transform.scale(
                scale: scale,
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    padding: const EdgeInsets.all(5),
                    decoration: BoxDecoration(
                      color: AppColors.purple.withValues(alpha: 0.25),
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.purpleBright.withValues(
                            alpha: 0.25 * _pulseController.value,
                          ),
                          blurRadius: 8,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.auto_awesome_rounded,
                      size: 14,
                      color: AppColors.purpleBright,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 10),
        ],
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (widget.showThinkingHeader) ...[
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      widget.thinkingHeader,
                      style: TextStyle(
                        fontSize: widget.fontSize - 1.5,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.3,
                        color: AppColors.purpleBright,
                      ),
                    ),
                    const SizedBox(width: 4),
                    _ClaudeThinkingDots(color: AppColors.purpleBright),
                  ],
                ),
                const SizedBox(height: 2),
              ],
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 320),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                layoutBuilder: (currentChild, previousChildren) {
                  return Stack(
                    alignment: Alignment.centerLeft,
                    children: <Widget>[
                      ...previousChildren,
                      ?currentChild,
                    ],
                  );
                },
                transitionBuilder: (child, animation) {
                  final inAnimation = Tween<Offset>(
                    begin: const Offset(0.0, 0.30),
                    end: Offset.zero,
                  ).animate(CurvedAnimation(
                    parent: animation,
                    curve: Curves.easeOutCubic,
                  ));
                  return SlideTransition(
                    position: inAnimation,
                    child: FadeTransition(
                      opacity: animation,
                      child: child,
                    ),
                  );
                },
                child: ClaudeShimmerText(
                  thought,
                  key: ValueKey<String>(thought),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: widget.fontSize,
                    fontWeight: FontWeight.w500,
                    height: 1.35,
                    color: const Color(0xFFE2E8F0),
                    letterSpacing: -0.2,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (widget.onCancel != null) ...[
          const SizedBox(width: 8),
          IconButton(
            icon: const Icon(Icons.close, size: 16, color: AppColors.textMuted),
            onPressed: widget.onCancel,
            tooltip: 'Cancel',
            visualDensity: VisualDensity.compact,
          ),
        ],
      ],
    );

    if (widget.isCard) {
      return Container(
        padding: widget.padding ??
            const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: const Color(0xFF1E1638).withValues(alpha: 0.75),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.35),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: content,
      );
    }

    return Padding(
      padding: widget.padding ?? EdgeInsets.zero,
      child: content,
    );
  }
}

/// A specialized Claude-style thinking chat bubble for the Ask ChemBuddy chat stream.
class ClaudeThinkingBubble extends StatelessWidget {
  final List<String> thoughts;
  final Duration thoughtInterval;
  final VoidCallback? onCancel;

  const ClaudeThinkingBubble({
    super.key,
    this.thoughts = ClaudeThinkingMicrocopy.askAi,
    this.thoughtInterval = const Duration(milliseconds: 2200),
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, left: 4, right: 32),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF18122B).withValues(alpha: 0.85),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.4),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.15),
              blurRadius: 10,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: ClaudeThinkingIndicator(
          thoughts: thoughts,
          thoughtInterval: thoughtInterval,
          isCard: false,
          showSparkle: true,
          showThinkingHeader: true,
          thinkingHeader: 'Thinking',
          fontSize: 13.0,
          onCancel: onCancel,
        ),
      ),
    );
  }
}

/// Animated 3-dot pulse for the "Thinking..." header
class _ClaudeThinkingDots extends StatefulWidget {
  final Color color;

  const _ClaudeThinkingDots({required this.color});

  @override
  State<_ClaudeThinkingDots> createState() => _ClaudeThinkingDotsState();
}

class _ClaudeThinkingDotsState extends State<_ClaudeThinkingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        final val = _controller.value;
        final dots = val < 0.33 ? '.' : (val < 0.66 ? '..' : '...');
        return SizedBox(
          width: 14,
          child: Text(
            dots,
            style: TextStyle(
              color: widget.color,
              fontWeight: FontWeight.w800,
              fontSize: 12,
            ),
          ),
        );
      },
    );
  }
}
