import 'dart:math' as math;
import 'package:flutter/material.dart';

enum MascotMood { idle, thinking, celebrating }

class InteractiveMascot extends StatefulWidget {
  final MascotMood mood;
  final double size;
  final VoidCallback? onTap;

  const InteractiveMascot({
    super.key,
    this.mood = MascotMood.idle,
    this.size = 130.0,
    this.onTap,
  });

  @override
  State<InteractiveMascot> createState() => _InteractiveMascotState();
}

class _InteractiveMascotState extends State<InteractiveMascot>
    with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final AnimationController _bounceController;

  late final Animation<double> _floatAnim;
  late final Animation<double> _tiltAnim;
  late final Animation<double> _glowAnim;
  late final Animation<double> _scaleAnim;

  String? _dialogueText;
  int _dialogueIndex = 0;

  final List<String> _studyQuips = [
    "Ready to crack some NMR spectra? \u2697\ufe0f",
    "Keep that 75% attendance safe! \ud83d\udcda",
    "Remember: Walden inversion flips stereocenters! \ud83d\udd04",
    "Check your units before submitting Molarity calculations. \ud83e\uddea",
    "Kannada pride + MSc Chemistry rigor! \ud83c\udf1f",
    "Mastering pericyclic reactions step by step! \ud83d\udd2c",
  ];

  @override
  void initState() {
    super.initState();

    // 1. Idle vertical floating & slight head tilt
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    )..repeat(reverse: true);

    _floatAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _tiltAnim = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    // 2. Neon back-glow pulsation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);

    _glowAnim = Tween<double>(begin: 12.0, end: 28.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // 3. Quick tap reaction (squash & stretch bounce)
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.90), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 20),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );
  }

  void _handleTap() {
    _bounceController.forward(from: 0.0);
    setState(() {
      _dialogueText = _studyQuips[_dialogueIndex % _studyQuips.length];
      _dialogueIndex++;
    });

    widget.onTap?.call();

    // Auto-dismiss dialogue after 3.5s
    Future.delayed(const Duration(milliseconds: 3500), () {
      if (mounted && _dialogueText != null) {
        setState(() => _dialogueText = null);
      }
    });
  }

  Color get _themeGlowColor {
    switch (widget.mood) {
      case MascotMood.thinking:
        return const Color(0xFF00F2FE); // Cyan pulse for AI thinking
      case MascotMood.celebrating:
        return const Color(0xFF00E676); // Green bloom for quiz/streak win
      case MascotMood.idle:
        return const Color(0xFF7928CA); // Deep neon purple ambient
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _handleTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Dynamic Speech Bubble
          AnimatedSwitcher(
            duration: const Duration(milliseconds: 200),
            transitionBuilder: (child, anim) => FadeTransition(
              opacity: anim,
              child: ScaleTransition(scale: anim, child: child),
            ),
            child: _dialogueText != null
                ? Container(
                    key: ValueKey(_dialogueText),
                    margin: const EdgeInsets.only(bottom: 10),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 8,
                    ),
                    constraints: const BoxConstraints(maxWidth: 220),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1B2E),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _themeGlowColor.withValues(alpha: 0.5),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.4),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      _dialogueText!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        height: 1.3,
                      ),
                    ),
                  )
                : const SizedBox.shrink(),
          ),

          // Floating Mascot with Shader/Glow Backing
          AnimatedBuilder(
            animation: Listenable.merge([
              _floatController,
              _pulseController,
              _bounceController,
            ]),
            builder: (context, child) {
              return Transform.translate(
                offset: Offset(0, _floatAnim.value),
                child: Transform.rotate(
                  angle: _tiltAnim.value * (math.pi / 180),
                  child: Transform.scale(
                    scale: _scaleAnim.value,
                    child: child,
                  ),
                ),
              );
            },
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: _themeGlowColor.withValues(
                      alpha: widget.mood == MascotMood.thinking ? 0.60 : 0.30,
                    ),
                    blurRadius: _glowAnim.value,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Image.asset(
                'assets/images/mascot_transparent.webp',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Image.asset(
                    'assets/images/mascot_transparent.png',
                    fit: BoxFit.contain,
                    errorBuilder: (ctx, err, st) {
                      return const Icon(
                        Icons.science_rounded,
                        color: Color(0xFF00F2FE),
                        size: 48,
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}
