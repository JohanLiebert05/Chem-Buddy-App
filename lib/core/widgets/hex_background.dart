import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/appearance.dart';

/// Clean ambient background with a very subtle molecular hex grid accent.
class HexBackground extends StatelessWidget {
  const HexBackground({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    if (context.findAncestorWidgetOfExactType<HexBackground>() != null) {
      return child;
    }
    final colors = Theme.of(context).colorScheme;
    final glass = GlassTokens.of(context);
    final prism = PrismTokens.of(context);
    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: prism.enabled
                ? LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: prism.colors
                        .map(
                          (tone) => Color.alphaBlend(
                            tone.withValues(
                              alpha: colors.brightness == Brightness.light
                                  ? .12
                                  : .19,
                            ),
                            colors.surface,
                          ),
                        )
                        .toList(),
                  )
                : RadialGradient(
                    center: Alignment(0, -0.7),
                    radius: 1.4,
                    colors: [
                      Color.alphaBlend(
                        colors.primary.withValues(
                          alpha:
                              glass.glow *
                              (colors.brightness == Brightness.light ? .46 : 1),
                        ),
                        colors.surface,
                      ),
                      colors.surface,
                    ],
                  ),
          ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: const Alignment(1, .45),
                  radius: 1.0,
                  colors: [
                    colors.tertiary.withValues(
                      alpha:
                          glass.glow *
                          (colors.brightness == Brightness.light ? .25 : .55),
                    ),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ),
        CustomPaint(
          painter: _SubtleHexPainter(colors.primary.withValues(alpha: .025)),
          size: Size.infinite,
        ),
        child,
      ],
    );
  }
}

class _SubtleHexPainter extends CustomPainter {
  const _SubtleHexPainter(this.color);
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.6
      ..color = color; // Extremely faint, whisper-level accent

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
  bool shouldRepaint(covariant _SubtleHexPainter oldDelegate) =>
      color != oldDelegate.color;
}
