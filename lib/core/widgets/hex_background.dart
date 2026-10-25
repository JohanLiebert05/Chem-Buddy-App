import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Clean ambient background with a very subtle molecular hex grid accent.
class HexBackground extends StatelessWidget {
  const HexBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        const DecoratedBox(
          decoration: BoxDecoration(
            gradient: RadialGradient(
              center: Alignment(0, -0.7),
              radius: 1.4,
              colors: [
                Color(0xFF171329), // Subtle dark violet top aura
                AppColors.bg0,     // Deep canvas base
              ],
            ),
          ),
        ),
        const CustomPaint(painter: _SubtleHexPainter(), size: Size.infinite),
        child,
      ],
    );
  }
}

class _SubtleHexPainter extends CustomPainter {
  const _SubtleHexPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = const Color(0x06A78BFA); // Extremely faint, whisper-level accent

    const radius = 34.0;
    final h = radius * math.sqrt(3);
    for (var row = 0; row < size.height / h + 2; row++) {
      for (var col = 0; col < size.width / (radius * 1.5) + 2; col++) {
        final dx = col * radius * 1.5;
        final dy = row * h + (col.isOdd ? h / 2 : 0);
        _hex(canvas, Offset(dx, dy), radius, paint);
      }
    }
  }

  void _hex(Canvas canvas, Offset c, double r, Paint paint) {
    final path = Path();
    for (var i = 0; i < 6; i++) {
      final a = (math.pi / 3) * i;
      final p = Offset(c.dx + r * math.cos(a), c.dy + r * math.sin(a));
      if (i == 0) {
        path.moveTo(p.dx, p.dy);
      } else {
        path.lineTo(p.dx, p.dy);
      }
    }
    path.close();
    canvas.drawPath(path, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
