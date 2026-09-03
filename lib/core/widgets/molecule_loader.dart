import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Branded MSc Chemistry Benzene Molecule Loader.
/// Renders a pulsing hexagonal carbon ring with a rotating delocalized pi-electron cloud.
class BenzeneMoleculeLoader extends StatefulWidget {
  const BenzeneMoleculeLoader({
    super.key,
    this.size = 68,
    this.message,
    this.color = AppColors.brandBright,
  });

  final double size;
  final String? message;
  final Color color;

  @override
  State<BenzeneMoleculeLoader> createState() => _BenzeneMoleculeLoaderState();
}

class _BenzeneMoleculeLoaderState extends State<BenzeneMoleculeLoader> with TickerProviderStateMixin {
  late final AnimationController _rotationController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _rotationController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..repeat();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _rotationController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        AnimatedBuilder(
          animation: Listenable.merge([_rotationController, _pulseController]),
          builder: (context, child) {
            final pulseScale = 0.94 + (_pulseController.value * 0.10);
            return Transform.scale(
              scale: pulseScale,
              child: SizedBox(
                width: widget.size,
                height: widget.size,
                child: CustomPaint(
                  painter: _BenzenePainter(
                    rotation: _rotationController.value * 2 * math.pi,
                    pulse: _pulseController.value,
                    color: widget.color,
                  ),
                ),
              ),
            );
          },
        ),
        if (widget.message != null) ...[
          const SizedBox(height: 14),
          Text(
            widget.message!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: AppColors.textSecondary,
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: -0.2,
            ),
          ),
        ],
      ],
    );
  }
}

class _BenzenePainter extends CustomPainter {
  _BenzenePainter({
    required this.rotation,
    required this.pulse,
    required this.color,
  });

  final double rotation;
  final double pulse;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width * 0.42;

    // Ambient glow filter
    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.20 + (pulse * 0.15))
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, size.width * 0.18);
    canvas.drawCircle(center, radius * 0.9, glowPaint);

    // 1. Draw outer Hexagon (C-C aromatic bonds)
    final hexPath = Path();
    final vertices = <Offset>[];

    for (var i = 0; i < 6; i++) {
      final angle = (i * math.pi / 3) - (math.pi / 6); // Pointy top
      final x = center.dx + radius * math.cos(angle);
      final y = center.dy + radius * math.sin(angle);
      final vertex = Offset(x, y);
      vertices.add(vertex);
      if (i == 0) {
        hexPath.moveTo(x, y);
      } else {
        hexPath.lineTo(x, y);
      }
    }
    hexPath.close();

    final bondPaint = Paint()
      ..color = color.withValues(alpha: 0.85)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.2
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;
    canvas.drawPath(hexPath, bondPaint);

    // 2. Draw inner delocalized pi-electron ring (dashed / spinning circle)
    final innerRadius = radius * 0.60;
    final ringPaint = Paint()
      ..color = AppColors.accentCyan.withValues(alpha: 0.70 + (pulse * 0.25))
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.8;

    // Spinning dash segments (representing aromatic resonance)
    const dashCount = 6;
    final sweep = (2 * math.pi / dashCount) * 0.65;
    for (var i = 0; i < dashCount; i++) {
      final startAngle = rotation + (i * 2 * math.pi / dashCount);
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: innerRadius),
        startAngle,
        sweep,
        false,
        ringPaint,
      );
    }

    // 3. Draw 6 Carbon Node Vertices with luminescent glow
    final nodePaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    final nodeGlowPaint = Paint()
      ..color = color.withValues(alpha: 0.8)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);

    for (final v in vertices) {
      canvas.drawCircle(v, 3.4, nodeGlowPaint);
      canvas.drawCircle(v, 2.0, nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BenzenePainter oldDelegate) =>
      oldDelegate.rotation != rotation ||
      oldDelegate.pulse != pulse ||
      oldDelegate.color != color;
}
