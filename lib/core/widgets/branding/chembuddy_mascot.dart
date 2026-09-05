import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../claude_loading_text.dart';

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
  small(44),
  compact(64),
  medium(96),
  large(130),
  hero(170);

  final double dimension;
  const MascotSize(this.dimension);
}

/// The official ChemBuddy Mascot vector illustration.
/// Features high-detail academic goggles, crisp lab coat, and dynamic swirling chemical flask.
class ChemBuddyMascot extends StatefulWidget {
  const ChemBuddyMascot({
    super.key,
    this.state = MascotState.idle,
    this.size = MascotSize.medium,
    this.customDimension,
    this.animate = true,
    this.flaskColor,
  });

  final MascotState state;
  final MascotSize size;
  final double? customDimension;
  final bool animate;
  final Color? flaskColor;

  @override
  State<ChemBuddyMascot> createState() => _ChemBuddyMascotState();
}

class _ChemBuddyMascotState extends State<ChemBuddyMascot> with TickerProviderStateMixin {
  late final AnimationController _floatController;
  late final AnimationController _swirlController;
  late final AnimationController _pulseController;
  late final AnimationController _sparkleController;

  @override
  void initState() {
    super.initState();
    _floatController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2600),
    );
    _swirlController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2000),
    );
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    );

    if (widget.animate) {
      _floatController.repeat(reverse: true);
      _swirlController.repeat();
      _pulseController.repeat(reverse: true);
      _sparkleController.repeat();
    }
  }

  @override
  void didUpdateWidget(ChemBuddyMascot oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.animate && !_floatController.isAnimating) {
      _floatController.repeat(reverse: true);
      _swirlController.repeat();
      _pulseController.repeat(reverse: true);
      _sparkleController.repeat();
    } else if (!widget.animate && _floatController.isAnimating) {
      _floatController.stop();
      _swirlController.stop();
      _pulseController.stop();
      _sparkleController.stop();
    }
  }

  @override
  void dispose() {
    _floatController.dispose();
    _swirlController.dispose();
    _pulseController.dispose();
    _sparkleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dimension = widget.customDimension ?? widget.size.dimension;

    return AnimatedBuilder(
      animation: Listenable.merge([
        _floatController,
        _swirlController,
        _pulseController,
        _sparkleController,
      ]),
      builder: (context, child) {
        final floatOffset = widget.animate
            ? math.sin(_floatController.value * math.pi) * (dimension * 0.04)
            : 0.0;

        return Transform.translate(
          offset: Offset(0, -floatOffset),
          child: SizedBox(
            width: dimension,
            height: dimension,
            child: CustomPaint(
              painter: _MascotVectorPainter(
                state: widget.state,
                floatProgress: _floatController.value,
                swirlProgress: _swirlController.value,
                pulseProgress: _pulseController.value,
                sparkleProgress: _sparkleController.value,
                customFlaskColor: widget.flaskColor,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _MascotVectorPainter extends CustomPainter {
  _MascotVectorPainter({
    required this.state,
    required this.floatProgress,
    required this.swirlProgress,
    required this.pulseProgress,
    required this.sparkleProgress,
    this.customFlaskColor,
  });

  final MascotState state;
  final double floatProgress;
  final double swirlProgress;
  final double pulseProgress;
  final double sparkleProgress;
  final Color? customFlaskColor;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;
    final center = Offset(w * 0.5, h * 0.52);

    // 1. Aura glow based on state
    final glowColor = _getStateGlowColor();
    final glowPaint = Paint()
      ..color = glowColor.withValues(alpha: 0.18 + (pulseProgress * 0.12))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, w * 0.22);
    canvas.drawCircle(center, w * 0.38, glowPaint);

    // 2. Orbiting valence particles (when thinking / loading / celebration)
    if (state == MascotState.thinking || state == MascotState.loading || state == MascotState.celebration) {
      _drawOrbitingParticles(canvas, center, w * 0.44);
    }

    // 3. Mascot Body & Lab Coat
    _drawLabCoatAndBody(canvas, center, w, h);

    // 4. Mascot Head & Face
    _drawHeadAndFace(canvas, center, w, h);

    // 5. Goggles
    _drawAcademicGoggles(canvas, center, w, h);

    // 6. Erlenmeyer Flask or Tool based on State
    _drawStateAccessories(canvas, center, w, h);

    // 7. Floating Chemistry Symbols
    _drawFloatingChemistrySymbols(canvas, center, w);
  }

  Color _getStateGlowColor() {
    switch (state) {
      case MascotState.idle:
        return AppColors.purpleBright;
      case MascotState.thinking:
        return const Color(0xFF6366F1); // Indigo
      case MascotState.loading:
        return AppColors.blue;
      case MascotState.success:
        return AppColors.success;
      case MascotState.celebration:
        return AppColors.accentGold;
      case MascotState.empty:
        return AppColors.accentCyan;
      case MascotState.error:
        return AppColors.warning;
    }
  }

  void _drawOrbitingParticles(Canvas canvas, Offset center, double radius) {
    final particleCount = state == MascotState.loading ? 4 : 3;
    final speed = state == MascotState.loading ? 2.0 : 1.0;
    final angleBase = swirlProgress * 2 * math.pi * speed;

    final dotPaint = Paint()..style = PaintingStyle.fill;

    for (int i = 0; i < particleCount; i++) {
      final angle = angleBase + (i * 2 * math.pi / particleCount);
      // Elliptical orbit
      final px = center.dx + radius * math.cos(angle);
      final py = center.dy + (radius * 0.45) * math.sin(angle);

      final alpha = (0.5 + 0.5 * math.sin(angle)).clamp(0.2, 0.9);
      dotPaint.color = (i % 2 == 0 ? AppColors.accentCyan : AppColors.purpleBright).withValues(alpha: alpha);

      canvas.drawCircle(Offset(px, py), radius * 0.05, dotPaint);

      // Orbital trail ring
      final trailPaint = Paint()
        ..color = AppColors.purpleBright.withValues(alpha: 0.08)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.0;
      canvas.drawOval(
        Rect.fromCenter(center: center, width: radius * 2, height: radius * 0.9),
        trailPaint,
      );
    }
  }

  void _drawLabCoatAndBody(Canvas canvas, Offset center, double w, double h) {
    final coatPaint = Paint()
      ..shader = const LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [Color(0xFFE2E8F0), Color(0xFFCBD5E1), Color(0xFF94A3B8)],
      ).createShader(Rect.fromLTWH(0, h * 0.55, w, h * 0.45));

    final coatShadow = Paint()
      ..color = const Color(0xFF1E293B)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022;

    final bodyRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(center.dx, h * 0.78),
        width: w * 0.58,
        height: h * 0.42,
      ),
      Radius.circular(w * 0.18),
    );

    canvas.drawRRect(bodyRect, coatPaint);
    canvas.drawRRect(bodyRect, coatShadow);

    // Lab coat collar lapels (V-neck)
    final lapelPath = Path()
      ..moveTo(center.dx - w * 0.16, h * 0.62)
      ..lineTo(center.dx, h * 0.76)
      ..lineTo(center.dx + w * 0.16, h * 0.62)
      ..lineTo(center.dx + w * 0.11, h * 0.88)
      ..lineTo(center.dx - w * 0.11, h * 0.88)
      ..close();

    final innerShirtPaint = Paint()..color = const Color(0xFF0F172A);
    canvas.drawPath(lapelPath, innerShirtPaint);

    // Left lapel
    final leftLapel = Path()
      ..moveTo(center.dx - w * 0.16, h * 0.62)
      ..lineTo(center.dx - w * 0.02, h * 0.76)
      ..lineTo(center.dx - w * 0.18, h * 0.78)
      ..close();
    canvas.drawPath(leftLapel, Paint()..color = Colors.white);

    // Right lapel
    final rightLapel = Path()
      ..moveTo(center.dx + w * 0.16, h * 0.62)
      ..lineTo(center.dx + w * 0.02, h * 0.76)
      ..lineTo(center.dx + w * 0.18, h * 0.78)
      ..close();
    canvas.drawPath(rightLapel, Paint()..color = const Color(0xFFF1F5F9));

    // Pocket with miniature pen & NMR tube
    final pocketRect = RRect.fromRectAndRadius(
      Rect.fromLTWH(center.dx - w * 0.22, h * 0.74, w * 0.11, h * 0.1),
      Radius.circular(w * 0.02),
    );
    canvas.drawRRect(pocketRect, Paint()..color = const Color(0xFFCBD5E1));
    canvas.drawRRect(pocketRect, coatShadow..strokeWidth = 1.0);

    // Pen clip
    canvas.drawLine(
      Offset(center.dx - w * 0.18, h * 0.71),
      Offset(center.dx - w * 0.18, h * 0.76),
      Paint()..color = AppColors.accentCyan..strokeWidth = w * 0.015..strokeCap = StrokeCap.round,
    );
    // NMR tube
    canvas.drawLine(
      Offset(center.dx - w * 0.14, h * 0.70),
      Offset(center.dx - w * 0.14, h * 0.76),
      Paint()..color = AppColors.purpleBright..strokeWidth = w * 0.015..strokeCap = StrokeCap.round,
    );
  }

  void _drawHeadAndFace(Canvas canvas, Offset center, double w, double h) {
    final headCenter = Offset(center.dx, h * 0.42);
    final headRadius = w * 0.28;

    // Head base (deep violet-slate scholar tone)
    final headGradient = RadialGradient(
      center: const Alignment(-0.2, -0.3),
      colors: const [
        Color(0xFF332E63),
        Color(0xFF1E1B38),
        Color(0xFF131127),
      ],
      stops: const [0.0, 0.65, 1.0],
    ).createShader(Rect.fromCircle(center: headCenter, radius: headRadius));

    final headPaint = Paint()..shader = headGradient;
    canvas.drawCircle(headCenter, headRadius, headPaint);

    // Subtle rim light
    final rimPaint = Paint()
      ..color = AppColors.purpleBright.withValues(alpha: 0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.018;
    canvas.drawCircle(headCenter, headRadius, rimPaint);

    // Mouth / Expression
    _drawMouth(canvas, headCenter, w, h);
  }

  void _drawMouth(Canvas canvas, Offset headCenter, double w, double h) {
    final mouthY = headCenter.dy + (h * 0.14);
    final mouthPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.9)
      ..style = PaintingStyle.stroke
      ..strokeWidth = w * 0.022
      ..strokeCap = StrokeCap.round;

    switch (state) {
      case MascotState.idle:
        // Friendly scholarly smile
        final path = Path()
          ..moveTo(headCenter.dx - w * 0.06, mouthY)
          ..quadraticBezierTo(headCenter.dx, mouthY + (h * 0.03), headCenter.dx + w * 0.06, mouthY);
        canvas.drawPath(path, mouthPaint);
        break;

      case MascotState.thinking:
        // Thoughtful "O" / analytical curve
        final path = Path()
          ..moveTo(headCenter.dx - w * 0.04, mouthY + h * 0.01)
          ..quadraticBezierTo(headCenter.dx, mouthY - (h * 0.01), headCenter.dx + w * 0.05, mouthY + h * 0.01);
        canvas.drawPath(path, mouthPaint);
        break;

      case MascotState.loading:
        // Focused small smile
        final path = Path()
          ..moveTo(headCenter.dx - w * 0.04, mouthY)
          ..quadraticBezierTo(headCenter.dx, mouthY + (h * 0.02), headCenter.dx + w * 0.04, mouthY);
        canvas.drawPath(path, mouthPaint);
        break;

      case MascotState.success:
      case MascotState.celebration:
        // Big open happy smile
        final openMouth = Path()
          ..moveTo(headCenter.dx - w * 0.08, mouthY - h * 0.01)
          ..quadraticBezierTo(headCenter.dx, mouthY + (h * 0.06), headCenter.dx + w * 0.08, mouthY - h * 0.01)
          ..close();
        canvas.drawPath(openMouth, Paint()..color = const Color(0xFFEC4899));
        canvas.drawPath(openMouth, mouthPaint);
        break;

      case MascotState.empty:
        // Inquisitive dot / slight tilt
        canvas.drawCircle(Offset(headCenter.dx, mouthY), w * 0.025, Paint()..color = Colors.white70);
        break;

      case MascotState.error:
        // Slightly wavy / sympathetic "Let's rebalance!"
        final path = Path()
          ..moveTo(headCenter.dx - w * 0.06, mouthY + h * 0.01)
          ..quadraticBezierTo(headCenter.dx - w * 0.02, mouthY - h * 0.015, headCenter.dx + w * 0.06, mouthY + h * 0.01);
        canvas.drawPath(path, mouthPaint);
        break;
    }
  }

  void _drawAcademicGoggles(Canvas canvas, Offset center, double w, double h) {
    final goggleY = h * 0.38;
    final goggleRadius = w * 0.125;
    final leftX = center.dx - w * 0.11;
    final rightX = center.dx + w * 0.11;

    // Goggle Strap
    final strapPaint = Paint()
      ..color = const Color(0xFF1E293B)
      ..strokeWidth = w * 0.035
      ..style = PaintingStyle.stroke;
    canvas.drawLine(Offset(w * 0.18, goggleY), Offset(w * 0.82, goggleY), strapPaint);

    // Bridge between lenses
    final bridgePaint = Paint()
      ..color = AppColors.purpleBright
      ..strokeWidth = w * 0.03
      ..strokeCap = StrokeCap.round;
    canvas.drawLine(Offset(leftX + goggleRadius * 0.7, goggleY), Offset(rightX - goggleRadius * 0.7, goggleY), bridgePaint);

    // Draw Left & Right Lenses
    for (final lx in [leftX, rightX]) {
      final lensCenter = Offset(lx, goggleY);

      // Outer Rim (Metallic Purple/Cyan)
      final rimGradient = RadialGradient(
        colors: [AppColors.purpleBright, AppColors.blue, const Color(0xFF0F172A)],
        stops: const [0.7, 0.9, 1.0],
      ).createShader(Rect.fromCircle(center: lensCenter, radius: goggleRadius));

      canvas.drawCircle(lensCenter, goggleRadius, Paint()..shader = rimGradient);

      // Glass Interior (Teal-tinted reflective glass)
      final glassGradient = const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [
          Color(0xFF06B6D4),
          Color(0xFF0891B2),
          Color(0xFF164E63),
        ],
      ).createShader(Rect.fromCircle(center: lensCenter, radius: goggleRadius * 0.8));

      canvas.drawCircle(lensCenter, goggleRadius * 0.8, Paint()..shader = glassGradient);

      // Pupil / Eye
      _drawEyePupil(canvas, lensCenter, goggleRadius, lx == leftX);

      // Glass Specular Glare Reflection (Diagonal highlights)
      final glarePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.55)
        ..style = PaintingStyle.fill;

      final glarePath = Path()
        ..moveTo(lensCenter.dx - goggleRadius * 0.55, lensCenter.dy - goggleRadius * 0.4)
        ..lineTo(lensCenter.dx - goggleRadius * 0.25, lensCenter.dy - goggleRadius * 0.65)
        ..lineTo(lensCenter.dx + goggleRadius * 0.2, lensCenter.dy - goggleRadius * 0.2)
        ..lineTo(lensCenter.dx - goggleRadius * 0.1, lensCenter.dy + goggleRadius * 0.05)
        ..close();
      canvas.drawPath(glarePath, glarePaint);
    }
  }

  void _drawEyePupil(Canvas canvas, Offset lensCenter, double radius, bool isLeft) {
    double eyeOffsetX = 0;
    double eyeOffsetY = 0;

    if (state == MascotState.thinking) {
      eyeOffsetY = -radius * 0.15; // looking up thoughtfully
      eyeOffsetX = isLeft ? -radius * 0.1 : radius * 0.1;
    } else if (state == MascotState.empty) {
      eyeOffsetY = radius * 0.2; // looking down at empty vessel
    }

    final pupilCenter = Offset(lensCenter.dx + eyeOffsetX, lensCenter.dy + eyeOffsetY);
    final pupilRadius = radius * 0.42;

    // Pupil
    canvas.drawCircle(pupilCenter, pupilRadius, Paint()..color = const Color(0xFF09090B));

    // Eye catchlight (sparkle)
    canvas.drawCircle(
      Offset(pupilCenter.dx - pupilRadius * 0.35, pupilCenter.dy - pupilRadius * 0.35),
      pupilRadius * 0.35,
      Paint()..color = Colors.white,
    );
  }

  void _drawStateAccessories(Canvas canvas, Offset center, double w, double h) {
    // Erlenmeyer Flask on the right side
    final flaskX = center.dx + (w * 0.22);
    final flaskY = h * 0.72;
    final flaskScale = w * 0.32;

    _drawErlenmeyerFlask(canvas, Offset(flaskX, flaskY), flaskScale);
  }

  void _drawErlenmeyerFlask(Canvas canvas, Offset flaskCenter, double size) {
    final fw = size;
    final fh = size * 1.25;
    final left = flaskCenter.dx - fw * 0.5;
    final top = flaskCenter.dy - fh * 0.5;

    // Flask outline geometry
    final neckWidth = fw * 0.24;
    final baseWidth = fw * 0.85;

    final flaskPath = Path()
      ..moveTo(flaskCenter.dx - neckWidth * 0.5, top)
      ..lineTo(flaskCenter.dx + neckWidth * 0.5, top)
      ..lineTo(flaskCenter.dx + neckWidth * 0.5, top + fh * 0.32)
      ..lineTo(flaskCenter.dx + baseWidth * 0.5, top + fh * 0.88)
      ..quadraticBezierTo(flaskCenter.dx, top + fh * 0.98, flaskCenter.dx - baseWidth * 0.5, top + fh * 0.88)
      ..lineTo(flaskCenter.dx - neckWidth * 0.5, top + fh * 0.32)
      ..close();

    // Flask Glass Body
    final glassPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.12)
      ..style = PaintingStyle.fill;
    canvas.drawPath(flaskPath, glassPaint);

    // Liquid in flask
    final liquidColor = customFlaskColor ?? _getLiquidColor();
    final liquidLevel = (0.55 + 0.05 * math.sin(swirlProgress * 2 * math.pi)).clamp(0.4, 0.75);
    final liquidTopY = top + (fh * (1.0 - liquidLevel));

    final liquidPath = Path()
      ..moveTo(flaskCenter.dx - baseWidth * 0.42, liquidTopY)
      // Swirling wave
      ..quadraticBezierTo(
        flaskCenter.dx,
        liquidTopY + (size * 0.06 * math.sin(swirlProgress * 2 * math.pi)),
        flaskCenter.dx + baseWidth * 0.42,
        liquidTopY,
      )
      ..lineTo(flaskCenter.dx + baseWidth * 0.48, top + fh * 0.88)
      ..quadraticBezierTo(flaskCenter.dx, top + fh * 0.96, flaskCenter.dx - baseWidth * 0.48, top + fh * 0.88)
      ..close();

    final liquidShader = LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        liquidColor.withValues(alpha: 0.85),
        liquidColor,
        liquidColor.withValues(alpha: 0.95),
      ],
    ).createShader(Rect.fromLTWH(left, top, fw, fh));

    canvas.drawPath(liquidPath, Paint()..shader = liquidShader);

    // Rising Bubbles inside flask
    final bubblePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    for (int b = 0; b < 3; b++) {
      final bProgress = (swirlProgress + (b * 0.33)) % 1.0;
      final bx = flaskCenter.dx + (math.sin(bProgress * math.pi * 2 + b) * (fw * 0.18));
      final by = (top + fh * 0.85) - (bProgress * (fh * 0.45));
      final bRadius = (size * 0.03) * (1.0 - bProgress * 0.3);
      canvas.drawCircle(Offset(bx, by), bRadius, bubblePaint);
    }

    // Flask Glass Border
    final borderPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.7)
      ..style = PaintingStyle.stroke
      ..strokeWidth = size * 0.045
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(flaskPath, borderPaint);

    // Flask Rim Top Lip
    final lipRect = RRect.fromRectAndRadius(
      Rect.fromCenter(
        center: Offset(flaskCenter.dx, top),
        width: neckWidth * 1.3,
        height: size * 0.08,
      ),
      Radius.circular(size * 0.03),
    );
    canvas.drawRRect(lipRect, borderPaint..style = PaintingStyle.fill);
  }

  Color _getLiquidColor() {
    switch (state) {
      case MascotState.idle:
        return AppColors.purpleBright;
      case MascotState.thinking:
        return AppColors.accentCyan;
      case MascotState.loading:
        return AppColors.blue;
      case MascotState.success:
      case MascotState.celebration:
        return AppColors.success;
      case MascotState.empty:
        return const Color(0xFF64748B); // Slate transparent
      case MascotState.error:
        return AppColors.warning;
    }
  }

  void _drawFloatingChemistrySymbols(Canvas canvas, Offset center, double w) {
    if (state != MascotState.thinking && state != MascotState.loading && state != MascotState.celebration) {
      return;
    }

    final symbols = state == MascotState.thinking
        ? ['π', 'e⁻', 'ΔH']
        : (state == MascotState.celebration ? ['★', '⚗️', '✓'] : ['d⁶', 'pKₐ', '⚗️']);

    final tp = TextPainter(textDirection: TextDirection.ltr);

    for (int i = 0; i < symbols.length; i++) {
      final symProgress = (sparkleProgress + (i * 0.33)) % 1.0;
      final angle = (i * 2 * math.pi / symbols.length) + (swirlProgress * 0.5);
      final dist = w * (0.42 + (symProgress * 0.1));

      final sx = center.dx + math.cos(angle) * dist;
      final sy = (center.dy - w * 0.1) + math.sin(angle) * (dist * 0.6);

      final alpha = (math.sin(symProgress * math.pi)).clamp(0.0, 1.0);

      tp.text = TextSpan(
        text: symbols[i],
        style: TextStyle(
          color: (i == 0 ? AppColors.accentCyan : AppColors.accentGold).withValues(alpha: alpha * 0.85),
          fontSize: w * 0.11,
          fontWeight: FontWeight.w800,
        ),
      );
      tp.layout();
      tp.paint(canvas, Offset(sx - (tp.width * 0.5), sy - (tp.height * 0.5)));
    }
  }

  @override
  bool shouldRepaint(covariant _MascotVectorPainter oldDelegate) {
    return oldDelegate.state != state ||
        oldDelegate.floatProgress != floatProgress ||
        oldDelegate.swirlProgress != swirlProgress ||
        oldDelegate.pulseProgress != pulseProgress ||
        oldDelegate.sparkleProgress != sparkleProgress ||
        oldDelegate.customFlaskColor != customFlaskColor;
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

/// Dynamic Loading Mascot with Benzene Ring & Step Progress
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
