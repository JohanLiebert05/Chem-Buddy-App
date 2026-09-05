import 'dart:math' as math;
import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';

/// The official ChemBuddy logo badge widget.
/// Renders an atomic orbital system with a glowing hexagonal benzene core.
class ChemBuddyLogo extends StatefulWidget {
  const ChemBuddyLogo({
    super.key,
    this.size = 56,
    this.animated = true,
    this.showBadge = true,
  });

  final double size;
  final bool animated;
  final bool showBadge;

  @override
  State<ChemBuddyLogo> createState() => _ChemBuddyLogoState();
}

class _ChemBuddyLogoState extends State<ChemBuddyLogo> with TickerProviderStateMixin {
  late final AnimationController _spinController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
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
        final pulse = 0.96 + (_pulseController.value * 0.08);
        return Transform.scale(
          scale: pulse,
          child: Container(
            width: widget.size,
            height: widget.size,
            decoration: widget.showBadge
                ? BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: const RadialGradient(
                      colors: [
                        Color(0xFF26214B),
                        Color(0xFF131127),
                        Color(0xFF0A0914),
                      ],
                    ),
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.purpleBright.withValues(alpha: 0.25 + (_pulseController.value * 0.15)),
                        blurRadius: widget.size * 0.35,
                        spreadRadius: widget.size * 0.05,
                      ),
                    ],
                    border: Border.all(
                      color: AppColors.purpleBright.withValues(alpha: 0.5),
                      width: widget.size * 0.03,
                    ),
                  )
                : null,
            child: CustomPaint(
              painter: _ChemBuddyLogoPainter(
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

class _ChemBuddyLogoPainter extends CustomPainter {
  _ChemBuddyLogoPainter({required this.spin, required this.pulse});

  final double spin;
  final double pulse;

  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final r = size.width * 0.42;

    // 1. Orbital Ring 1 (60 deg tilt)
    _drawOrbital(canvas, c, r * 0.95, r * 0.38, spin + (math.pi / 3), AppColors.purpleBright);

    // 2. Orbital Ring 2 (-60 deg tilt)
    _drawOrbital(canvas, c, r * 0.95, r * 0.38, -spin - (math.pi / 3), AppColors.accentCyan);

    // 3. Orbital Ring 3 (Horizontal)
    _drawOrbital(canvas, c, r * 0.95, r * 0.35, spin * 0.8, AppColors.blue);

    // 4. Hexagonal Benzene Core
    _drawHexagonCore(canvas, c, size.width * 0.22);
  }

  void _drawOrbital(Canvas canvas, Offset center, double rx, double ry, double angle, Color color) {
    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(angle);

    final orbitalPaint = Paint()
      ..color = color.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.3;

    canvas.drawOval(
      Rect.fromCenter(center: Offset.zero, width: rx * 2, height: ry * 2),
      orbitalPaint,
    );

    // Orbiting electron dot
    final ex = rx * math.cos(angle * 2);
    final ey = ry * math.sin(angle * 2);
    final electronPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(ex, ey), 2.2, electronPaint);

    final electronGlow = Paint()
      ..color = color
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(Offset(ex, ey), 3.5, electronGlow);

    canvas.restore();
  }

  void _drawHexagonCore(Canvas canvas, Offset center, double radius) {
    final path = Path();
    for (int i = 0; i < 6; i++) {
      final angle = (i * 60) * math.pi / 180;
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      if (i == 0) {
        path.moveTo(x, y);
      } else {
        path.lineTo(x, y);
      }
    }
    path.close();

    // Hexagon fill with glowing gradient
    final fillPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          Colors.white,
          AppColors.purpleBright,
          AppColors.purpleDeep,
        ],
        stops: const [0.0, 0.5, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawPath(path, fillPaint);

    // Inner Pi-ring
    final piRingPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.2;
    canvas.drawCircle(center, radius * 0.45, piRingPaint);
  }

  @override
  bool shouldRepaint(covariant _ChemBuddyLogoPainter oldDelegate) {
    return oldDelegate.spin != spin || oldDelegate.pulse != pulse;
  }
}
