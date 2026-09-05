import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../claude_loading_text.dart';

export '../../../widgets/interactive_mascot.dart';

/// Mascot expression and animation states
enum MascotState {
  idle,
  thinking,
  loading,
  success,
  empty,
  error,
  celebration,
}

/// Standard mascot display sizes
enum MascotSize {
  small(48),
  compact(64),
  medium(96),
  large(130),
  hero(170);

  final double dimension;
  const MascotSize(this.dimension);
}

/// The official ChemBuddy Mascot illustration.
/// Features the Kannada scholar bunny with safety goggles, lab coat, red scarf,
/// and dynamic chemical glassware with vibrant glowing animations.
class ChemBuddyMascot extends StatefulWidget {
  const ChemBuddyMascot({
    super.key,
    this.state = MascotState.idle,
    this.size = MascotSize.medium,
    this.customDimension,
    this.animate = true,
    this.flaskColor,
    this.onTap,
  });

  final MascotState state;
  final MascotSize size;
  final double? customDimension;
  final bool animate;
  final Color? flaskColor;
  final VoidCallback? onTap;

  @override
  State<ChemBuddyMascot> createState() => _ChemBuddyMascotState();
}

class _ChemBuddyMascotState extends State<ChemBuddyMascot> with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _pulseController;
  late final AnimationController _orbitController;
  late final AnimationController _bounceController;

  late final Animation<double> _floatAnim;
  late final Animation<double> _tiltAnim;
  late final Animation<double> _glowAnim;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );
    _orbitController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2400),
    );
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 220),
    );

    _floatAnim = Tween<double>(begin: -5.0, end: 5.0).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _tiltAnim = Tween<double>(begin: -0.02, end: 0.02).animate(
      CurvedAnimation(parent: _floatController, curve: Curves.easeInOutSine),
    );

    _glowAnim = Tween<double>(begin: 10.0, end: 26.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _scaleAnim = TweenSequence<double>([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.90), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 0.90, end: 1.08), weight: 40),
      TweenSequenceItem(tween: Tween(begin: 1.08, end: 1.0), weight: 20),
    ]).animate(
      CurvedAnimation(parent: _bounceController, curve: Curves.easeOut),
    );

    if (widget.animate) {
      _floatController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
      _orbitController.repeat();
    }
  }

  @override
  void didUpdateWidget(ChemBuddyMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_floatController.isAnimating) {
      _floatController.repeat(reverse: true);
      _pulseController.repeat(reverse: true);
      _orbitController.repeat();
    } else if (!widget.animate && _floatController.isAnimating) {
      _floatController.stop();
      _pulseController.stop();
      _orbitController.stop();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _pulseController.dispose();
    _orbitController.dispose();
    _bounceController.dispose();
    super.dispose();
  }

  Color _getStateGlowColor() {
    switch (widget.state) {
      case MascotState.idle:
        return const Color(0xFF7928CA); // Deep neon purple ambient
      case MascotState.thinking:
        return const Color(0xFF00F2FE); // Cyan pulse for AI thinking
      case MascotState.loading:
        return const Color(0xFF38BDF8); // Electric sky blue
      case MascotState.success:
      case MascotState.celebration:
        return const Color(0xFF00E676); // Green bloom for quiz/streak win
      case MascotState.empty:
        return const Color(0xFF818CF8); // Indigo aura
      case MascotState.error:
        return const Color(0xFFF59E0B); // Amber warning
    }
  }

  void _handleTap() {
    _bounceController.forward(from: 0.0);
    widget.onTap?.call();
  }

  @override
  Widget build(BuildContext context) {
    final dimension = widget.customDimension ?? widget.size.dimension;
    final glowColor = widget.flaskColor ?? _getStateGlowColor();

    return GestureDetector(
      onTap: widget.onTap != null ? _handleTap : null,
      child: AnimatedBuilder(
        animation: Listenable.merge([
          _floatController,
          _pulseController,
          _orbitController,
          _bounceController,
        ]),
        builder: (context, child) {
          final floatOffset = widget.animate ? _floatAnim.value * (dimension / 130.0) : 0.0;
          final tiltAngle = widget.animate ? _tiltAnim.value * (math.pi / 180) : 0.0;
          final scale = _bounceController.isAnimating ? _scaleAnim.value : 1.0;

          return Transform.translate(
            offset: Offset(0, floatOffset),
            child: Transform.rotate(
              angle: tiltAngle,
              child: Transform.scale(
                scale: scale,
                child: SizedBox(
                  width: dimension,
                  height: dimension,
                  child: Stack(
                    alignment: Alignment.center,
                    clipBehavior: Clip.none,
                    children: [
                      // 1. Neon Aura / Radial Glow
                      Container(
                        width: dimension * 0.75,
                        height: dimension * 0.75,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: glowColor.withValues(
                                alpha: widget.state == MascotState.thinking
                                    ? 0.55
                                    : (widget.state == MascotState.celebration ? 0.60 : 0.30),
                              ),
                              blurRadius: widget.animate ? _glowAnim.value * (dimension / 130.0) : 16.0,
                              spreadRadius: 2,
                            ),
                          ],
                        ),
                      ),

                      // 2. Orbiting valence particles (when thinking / loading / celebration)
                      if (widget.animate &&
                          (widget.state == MascotState.thinking ||
                              widget.state == MascotState.loading ||
                              widget.state == MascotState.celebration))
                        Positioned.fill(
                          child: CustomPaint(
                            painter: _OrbitParticlesPainter(
                              progress: _orbitController.value,
                              glowColor: glowColor,
                              state: widget.state,
                            ),
                          ),
                        ),

                      // 3. Transparent Mascot Image
                      Image.asset(
                        'assets/images/mascot_transparent.webp',
                        width: dimension,
                        height: dimension,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) {
                          return Image.asset(
                            'assets/images/mascot_transparent.png',
                            width: dimension,
                            height: dimension,
                            fit: BoxFit.contain,
                            errorBuilder: (ctx, err, st) {
                              return Icon(
                                Icons.science_rounded,
                                color: glowColor,
                                size: dimension * 0.6,
                              );
                            },
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _OrbitParticlesPainter extends CustomPainter {
  _OrbitParticlesPainter({
    required this.progress,
    required this.glowColor,
    required this.state,
  });

  final double progress;
  final Color glowColor;
  final MascotState state;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width * 0.5, size.height * 0.52);
    final radius = size.width * 0.44;
    final count = state == MascotState.loading ? 4 : 3;
    final speed = state == MascotState.loading ? 2.0 : 1.0;
    final baseAngle = progress * 2 * math.pi * speed;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < count; i++) {
      final angle = baseAngle + (i * 2 * math.pi / count);
      final px = center.dx + radius * math.cos(angle);
      final py = center.dy + (radius * 0.45) * math.sin(angle);
      final alpha = (0.4 + 0.5 * math.sin(angle)).clamp(0.2, 0.9);

      dotPaint.color = (i % 2 == 0 ? const Color(0xFF00F2FE) : glowColor).withValues(alpha: alpha);
      canvas.drawCircle(Offset(px, py), size.width * 0.024, dotPaint);

      final trailPaint = Paint()
        ..color = glowColor.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 0.9),
        trailPaint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _OrbitParticlesPainter oldDelegate) {
    return oldDelegate.progress != progress ||
        oldDelegate.glowColor != glowColor ||
        oldDelegate.state != state;
  }
}

/// Dynamic Thinking Mascot with rotating academic microcopy
class MascotThinking extends StatelessWidget {
  const MascotThinking({
    super.key,
    this.thoughts = ClaudeThinkingMicrocopy.askAi,
    this.title = 'ChemBuddy is thinking',
    this.size = MascotSize.medium,
  });

  final List<String> thoughts;
  final String title;
  final MascotSize size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChemBuddyMascot(
          state: MascotState.thinking,
          size: size,
        ),
        const SizedBox(height: 12),
        Text(
          title,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 14.5,
            color: Colors.white,
          ),
        ),
        const SizedBox(height: 6),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: ClaudeThinkingIndicator(
            thoughts: thoughts,
            isCard: false,
          ),
        ),
      ],
    );
  }
}

/// Dynamic Loading Mascot with Step Progress
class MascotLoading extends StatelessWidget {
  const MascotLoading({
    super.key,
    this.title = 'Preparing Chemistry Dossier...',
    this.subtitle,
    this.size = MascotSize.medium,
  });

  final String title;
  final String? subtitle;
  final MascotSize size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChemBuddyMascot(
          state: MascotState.loading,
          size: size,
        ),
        const SizedBox(height: 12),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 15,
            color: Colors.white,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 4),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ],
    );
  }
}

/// Branded Empty State with friendly Mascot guidance
class MascotEmptyState extends StatelessWidget {
  const MascotEmptyState({
    super.key,
    required this.title,
    required this.description,
    this.buttonLabel,
    this.onAction,
    this.size = MascotSize.large,
    this.secondaryButtonLabel,
    this.onSecondaryAction,
  });

  final String title;
  final String description;
  final String? buttonLabel;
  final VoidCallback? onAction;
  final MascotSize size;
  final String? secondaryButtonLabel;
  final VoidCallback? onSecondaryAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ChemBuddyMascot(
            state: MascotState.empty,
            size: size,
          ),
          const SizedBox(height: 16),
          Text(
            title,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 18,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13.5,
              height: 1.45,
            ),
          ),
          if (buttonLabel != null && onAction != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.purple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              ),
              onPressed: onAction,
              child: Text(
                buttonLabel!,
                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
              ),
            ),
          ],
          if (secondaryButtonLabel != null && onSecondaryAction != null) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: onSecondaryAction,
              child: Text(
                secondaryButtonLabel!,
                style: const TextStyle(color: AppColors.textMuted, fontSize: 13),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Celebratory Success Mascot
class MascotSuccess extends StatelessWidget {
  const MascotSuccess({
    super.key,
    required this.title,
    this.subtitle,
    this.buttonLabel,
    this.onAction,
    this.size = MascotSize.medium,
  });

  final String title;
  final String? subtitle;
  final String? buttonLabel;
  final VoidCallback? onAction;
  final MascotSize size;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        ChemBuddyMascot(
          state: MascotState.celebration,
          size: size,
        ),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w800,
            fontSize: 18,
            color: Colors.white,
          ),
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 6),
          Text(
            subtitle!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
            ),
          ),
        ],
        if (buttonLabel != null && onAction != null) ...[
          const SizedBox(height: 16),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.success,
              foregroundColor: Colors.black,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
            onPressed: onAction,
            child: Text(
              buttonLabel!,
              style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5),
            ),
          ),
        ],
      ],
    );
  }
}

/// Resilient Error Recovery Mascot
class MascotError extends StatelessWidget {
  const MascotError({
    super.key,
    required this.message,
    this.onRetry,
    this.size = MascotSize.medium,
  });

  final String message;
  final VoidCallback? onRetry;
  final MascotSize size;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ChemBuddyMascot(
            state: MascotState.error,
            size: size,
          ),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.warning,
              fontWeight: FontWeight.w600,
              fontSize: 13.5,
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.warning),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              onPressed: onRetry,
              icon: const Icon(Icons.refresh, size: 16, color: AppColors.warning),
              label: const Text(
                'Rebalance & Try Again',
                style: TextStyle(color: AppColors.warning, fontWeight: FontWeight.w700, fontSize: 12.5),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
