import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AtomLogo extends StatefulWidget {
  const AtomLogo({super.key, this.size = 88, this.animated = true});

  final double size;
  final bool animated;

  @override
  State<AtomLogo> createState() => _AtomLogoState();
}

class _AtomLogoState extends State<AtomLogo> with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    );
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2200),
    );

    if (widget.animated) {
      _spinController.repeat();
      _pulseController.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _spinController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: Listenable.merge([_spinController, _pulseController]),
      builder: (context, child) {
        final pulse = 0.95 + (_pulseController.value * 0.08);
        return Transform.scale(
          scale: pulse,
          child: SizedBox(
            width: widget.size,
            height: widget.size,
            child: CustomPaint(
              painter: _AestheticAtomPainter(
                spin: _spinController.value * 2 * math.pi,
                pulse: _pulseController.value,
              ),
            ),
          ),
        );
      },
    );
  }
}

class _AestheticAtomPainter extends CustomPainter {
  _AestheticAtomPainter({required this.spin, required this.pulse});

  final double spin;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);

    // 1. Ambient Outer Glow
    final glowPaint = Paint()
      ..color = AppColors.purpleBright.withValues(alpha: 0.22 + (pulse * 0.15))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.2);
    canvas.drawCircle(c, size.width * 0.28, glowPaint);

    // 2. Cyan Secondary Glow
    final cyanGlow = Paint()
      ..color = AppColors.blue.withValues(alpha: 0.15 + (pulse * 0.1))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.14);
    canvas.drawCircle(c, size.width * 0.18, cyanGlow);

    // 3. Nucleus Core
    final nucleusGradient = RadialGradient(
      colors: [
        Colors.white,
        AppColors.purpleBright,
        AppColors.purpleDeep,
      ],
      stops: const [0.0, 0.45, 1.0],
    ).createShader(Rect.fromCircle(center: c, radius: size.width * 0.14));

    final nucleusPaint = Paint()
      ..shader = nucleusGradient
      ..style = PaintingStyle.fill;
    canvas.drawCircle(c, size.width * 0.11, nucleusPaint);

    // 4. Three 3D Orbits with Phase Shifts
    final angles = [0.0, math.pi / 3, 2 * math.pi / 3];
    final orbitColors = [
      AppColors.purpleBright.withValues(alpha: 0.85),
      AppColors.blue.withValues(alpha: 0.85),
      const Color(0xFFC084FC).withValues(alpha: 0.85),
    ];

    for (var i = 0; i < angles.length; i++) {
      final baseAngle = angles[i];
      final orbitPaint = Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.8
        ..color = orbitColors[i];

      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(baseAngle + (spin * 0.15 * (i % 2 == 0 ? 1 : -1)));

      final ovalRect = Rect.fromCenter(
        center: Offset.zero,
        width: size.width * 0.90,
        height: size.height * 0.36,
      );
      canvas.drawOval(ovalRect, orbitPaint);

      // Orbiting Electron on this ellipse
      final electronAngle = spin * (1.2 + i * 0.3) + (i * math.pi / 2);
      final eX = (size.width * 0.45) * math.cos(electronAngle);
      final eY = (size.height * 0.18) * math.sin(electronAngle);

      final electronGlow = Paint()
        ..color = Colors.white.withValues(alpha: 0.8)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
      canvas.drawCircle(Offset(eX, eY), 4.5, electronGlow);

      final electronCore = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(eX, eY), 2.8, electronCore);

      canvas.restore();
    }
  }

  @override
  bool shouldRepaint(covariant _AestheticAtomPainter oldDelegate) =>
      oldDelegate.spin != spin || oldDelegate.pulse != pulse;
}

class CircularAttendance extends StatelessWidget {
  const CircularAttendance({
    super.key,
    required this.percent,
    this.size = 148,
    this.label = 'Overall',
  });

  final double percent;
  final double size;
  final String label;

  @override
  Widget build(BuildContext context) {
    final color = AppColors.attendanceColor(percent);
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(
        painter: _RingPainter(percent: percent.clamp(0, 100) / 100, color: color),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${percent.round()}%',
                style: TextStyle(
                  fontSize: size * 0.22,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
              Text(
                label,
                style: TextStyle(fontSize: size * 0.08, color: AppColors.textSecondary),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _RingPainter extends CustomPainter {
  _RingPainter({required this.percent, required this.color});

  final double percent;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width / 2 - 10;
    final bg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..color = const Color(0x33FFFFFF);
    canvas.drawCircle(c, r, bg);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color.withValues(alpha: 0.35)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
    final fg = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10
      ..strokeCap = StrokeCap.round
      ..color = color;

    final rect = Rect.fromCircle(center: c, radius: r);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * percent, false, glow);
    canvas.drawArc(rect, -math.pi / 2, 2 * math.pi * percent, false, fg);
  }

  @override
  bool shouldRepaint(covariant _RingPainter oldDelegate) =>
      oldDelegate.percent != percent || oldDelegate.color != color;
}
