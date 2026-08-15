import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

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
              center: Alignment(0, -0.6),
              radius: 1.2,
              colors: [Color(0xFF2A1548), AppColors.background],
            ),
          ),
        ),
        const CustomPaint(painter: _HexPainter(), size: Size.infinite),
        child,
      ],
    );
  }
}

class _HexPainter extends CustomPainter {
  const _HexPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = const Color(0x22A78BFA);

    const radius = 28.0;
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
