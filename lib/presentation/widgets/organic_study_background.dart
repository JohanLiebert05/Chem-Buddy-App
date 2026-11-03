import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';

/// A static colour field with sparse chemistry details. Separate paint boundary
/// keeps scrolling, timers and ink responses from repainting the backdrop.
class OrganicStudyBackground extends StatelessWidget {
  const OrganicStudyBackground({super.key, required this.child});
  final Widget child;
  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final dark = colors.brightness == Brightness.dark;
    final contrast = MediaQuery.highContrastOf(context);
    final tones = [
      colors.primary,
      const Color(0xFFFF809F),
      const Color(0xFF38CDBC),
      colors.tertiary,
    ];
    return Stack(
      fit: StackFit.expand,
      children: [
        Positioned.fill(
          child: IgnorePointer(
            child: RepaintBoundary(
              child: CustomPaint(
                painter: _StudyBackdrop(colors.surface, tones, dark, contrast),
              ),
            ),
          ),
        ),
        child,
      ],
    );
  }
}

class _StudyBackdrop extends CustomPainter {
  const _StudyBackdrop(this.surface, this.tones, this.dark, this.highContrast);
  final Color surface;
  final List<Color> tones;
  final bool dark, highContrast;
  @override
  void paint(Canvas canvas, Size size) {
    if (size.isEmpty) {
      return;
    }
    final area = Offset.zero & size;
    canvas.drawRect(area, Paint()..color = surface);
    final opacity = highContrast
        ? .045
        : dark
        ? .20
        : .17;
    final centers = [
      Offset(size.width * .04, size.height * .10),
      Offset(size.width * .98, size.height * .32),
      Offset(size.width * .10, size.height * .82),
      Offset(size.width * .90, size.height * .98),
    ];
    for (var i = 0; i < tones.length; i++) {
      final radius = math.max(size.width * .9, size.height * .52);
      canvas.drawRect(
        area,
        Paint()
          ..shader = RadialGradient(
            colors: [
              tones[i].withValues(alpha: opacity),
              tones[i].withValues(alpha: 0),
            ],
          ).createShader(Rect.fromCircle(center: centers[i], radius: radius)),
      );
    }
    final ink = tones.first.withValues(
      alpha: highContrast
          ? .025
          : dark
          ? .09
          : .075,
    );
    final line = Paint()
      ..color = ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.1;
    // Three incomplete molecular motifs along the margins, leaving the reading
    // column quiet. Decorative geometry carries no chemical assignments.
    for (final anchor in [
      Offset(size.width - 18, size.height * .16),
      Offset(8, size.height * .57),
      Offset(size.width - 24, size.height * .88),
    ]) {
      final ring = Path();
      const r = 35.0;
      final points = [
        for (var i = 0; i < 6; i++)
          anchor +
              Offset(
                math.cos(i * math.pi / 3) * r,
                math.sin(i * math.pi / 3) * r,
              ),
      ];
      ring.moveTo(points.first.dx, points.first.dy);
      for (final point in points.skip(1)) {
        ring.lineTo(point.dx, point.dy);
      }
      ring.close();
      canvas.drawPath(ring, line);
      canvas.drawLine(points[1], points[1] + const Offset(15, 25), line);
      canvas.drawCircle(
        points[1] + const Offset(15, 25),
        3,
        Paint()..color = ink,
      );
    }
    final dots = Paint()..color = ink;
    for (var i = 0; i < 15; i++) {
      final x = (i * 83.0 + 23) % size.width;
      final y = (i * 137.0 + 47) % size.height;
      canvas.drawCircle(Offset(x, y), i % 3 == 0 ? 1.8 : 1, dots);
    }
  }

  @override
  bool shouldRepaint(covariant _StudyBackdrop old) =>
      surface != old.surface ||
      dark != old.dark ||
      highContrast != old.highContrast ||
      !listEquals(tones, old.tones);
}
