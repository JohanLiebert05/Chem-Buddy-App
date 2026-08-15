import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

class AtomLogo extends StatelessWidget {
  const AtomLogo({super.key, this.size = 88});

  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _AtomPainter()),
    );
  }
}

class _AtomPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final c = Offset(size.width / 2, size.height / 2);
    final glow = Paint()
      ..color = AppColors.glow
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(c, size.width * 0.22, glow);

    final nucleus = Paint()
      ..shader = const RadialGradient(
        colors: [AppColors.purpleBright, AppColors.purpleDeep],
      ).createShader(Rect.fromCircle(center: c, radius: size.width * 0.12));
    canvas.drawCircle(c, size.width * 0.1, nucleus);

    final orbit = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.6
      ..color = AppColors.purpleBright.withValues(alpha: 0.85);

    for (final angle in [0.4, 2.1, 4.0]) {
      canvas.save();
      canvas.translate(c.dx, c.dy);
      canvas.rotate(angle);
      canvas.drawOval(
        Rect.fromCenter(center: Offset.zero, width: size.width * 0.86, height: size.height * 0.34),
        orbit,
      );
      canvas.restore();
    }

    final electron = Paint()..color = Colors.white;
    canvas.drawCircle(c + Offset(size.width * 0.32, -size.height * 0.08), 3.2, electron);
    canvas.drawCircle(c + Offset(-size.width * 0.28, size.height * 0.12), 3.2, electron);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
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
