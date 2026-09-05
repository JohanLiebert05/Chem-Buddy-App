import 'dart:math' as math;
import 'package:flutter/material.dart';

import 'molecule_3d_models.dart';

enum MoleculeRenderMode {
  ballAndStick,
  spaceFilling,
}

/// Photorealistic 3D CustomPainter for molecules with depth-sorting and CPK specular shading.
class Molecule3DPainter extends CustomPainter {
  final Molecule3D molecule;
  final double yaw;
  final double pitch;
  final double zoom;
  final MoleculeRenderMode renderMode;
  final int? selectedAtomIndex;
  final bool showLabels;
  final Color primaryColor;

  Molecule3DPainter({
    required this.molecule,
    required this.yaw,
    required this.pitch,
    this.zoom = 1.0,
    this.renderMode = MoleculeRenderMode.ballAndStick,
    this.selectedAtomIndex,
    this.showLabels = true,
    this.primaryColor = const Color(0xFF8B5CF6),
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (molecule.atoms.isEmpty) return;

    final centerX = size.width / 2;
    final centerY = size.height / 2;

    // Determine scale to fit canvas comfortably based on molecular radius
    final maxR = math.max(molecule.maxRadius, 1.0);
    final baseScale = (math.min(size.width, size.height) * 0.36 / maxR) * zoom;

    const cameraDistance = 14.0; // Distance in arbitrary units for perspective

    final cosY = math.cos(yaw);
    final sinY = math.sin(yaw);
    final cosP = math.cos(pitch);
    final sinP = math.sin(pitch);

    // Project all atoms
    final projected = <_ProjectedAtom>[];
    for (int i = 0; i < molecule.atoms.length; i++) {
      final a = molecule.atoms[i];

      // 1. Rotation around Y-axis (yaw)
      final x1 = a.x * cosY + a.z * sinY;
      final z1 = -a.x * sinY + a.z * cosY;

      // 2. Rotation around X-axis (pitch)
      final y2 = a.y * cosP - z1 * sinP;
      final z2 = a.y * sinP + z1 * cosP;

      // 3. Perspective projection
      final factor = cameraDistance / (cameraDistance + z2);
      final screenX = centerX + x1 * baseScale * factor;
      final screenY = centerY + y2 * baseScale * factor;

      // Determine visual sphere radius based on render mode
      double radius;
      if (renderMode == MoleculeRenderMode.spaceFilling) {
        radius = (28.0 * a.covalentRadius * factor * (zoom * 0.9)).clamp(14.0, 50.0);
      } else {
        radius = (14.0 * math.sqrt(a.covalentRadius) * factor * (zoom * 0.9)).clamp(9.0, 26.0);
      }

      projected.add(_ProjectedAtom(
        index: i,
        atom: a,
        screenX: screenX,
        screenY: screenY,
        depth: z2,
        radius: radius,
        perspectiveFactor: factor,
      ));
    }

    // Build drawables list (atoms + bonds) for Z-sorting (Painter's algorithm)
    final drawables = <_Drawable>[];

    // Add bonds only if Ball & Stick mode
    if (renderMode == MoleculeRenderMode.ballAndStick) {
      for (final bond in molecule.bonds) {
        if (bond.atomIndex1 < projected.length && bond.atomIndex2 < projected.length) {
          final p1 = projected[bond.atomIndex1];
          final p2 = projected[bond.atomIndex2];
          final avgDepth = (p1.depth + p2.depth) / 2;

          drawables.add(_BondDrawable(
            bond: bond,
            p1: p1,
            p2: p2,
            depth: avgDepth,
          ));
        }
      }
    }

    // Add atoms
    for (final p in projected) {
      drawables.add(_AtomDrawable(projectedAtom: p));
    }

    // Sort back-to-front (lowest depth first)
    drawables.sort((a, b) => a.depth.compareTo(b.depth));

    // Paint all elements
    for (final d in drawables) {
      if (d is _BondDrawable) {
        _paintBond(canvas, d);
      } else if (d is _AtomDrawable) {
        _paintAtom(canvas, d.projectedAtom);
      }
    }
  }

  void _paintBond(Canvas canvas, _BondDrawable bd) {
    final p1 = bd.p1;
    final p2 = bd.p2;
    final bond = bd.bond;

    final dx = p2.screenX - p1.screenX;
    final dy = p2.screenY - p1.screenY;
    final dist = math.sqrt(dx * dx + dy * dy);
    if (dist < 1.0) return;

    final nx = -dy / dist;
    final ny = dx / dist;

    final strokeWidth = (5.5 * ((p1.perspectiveFactor + p2.perspectiveFactor) / 2)).clamp(2.5, 7.5);

    if (bond.isPartial) {
      // Dashed amber bond for transition state / forming / breaking bonds
      final paint = Paint()
        ..color = const Color(0xFFF59E0B)
        ..strokeWidth = strokeWidth * 0.8
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;

      // Draw dashed line
      const dashLen = 6.0;
      const gapLen = 4.0;
      var current = 0.0;
      while (current < dist) {
        final startRatio = current / dist;
        final endRatio = math.min((current + dashLen) / dist, 1.0);
        final sx = p1.screenX + dx * startRatio;
        final sy = p1.screenY + dy * startRatio;
        final ex = p1.screenX + dx * endRatio;
        final ey = p1.screenY + dy * endRatio;
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), paint);
        current += dashLen + gapLen;
      }
      return;
    }

    if (bond.isDouble) {
      // Two parallel cylinders
      final offsetDist = strokeWidth * 0.75;
      _drawCylinderBond(canvas, p1, p2, nx * offsetDist, ny * offsetDist, strokeWidth * 0.7);
      _drawCylinderBond(canvas, p1, p2, -nx * offsetDist, -ny * offsetDist, strokeWidth * 0.7);
    } else if (bond.isAromatic) {
      // Solid cylinder plus delocalized dashed parallel line
      _drawCylinderBond(canvas, p1, p2, 0, 0, strokeWidth * 0.8);
      final offsetDist = strokeWidth * 0.8;
      final paintDashed = Paint()
        ..color = Colors.white.withValues(alpha: 0.35)
        ..strokeWidth = strokeWidth * 0.35
        ..strokeCap = StrokeCap.round
        ..style = PaintingStyle.stroke;
      const dashLen = 4.0;
      const gapLen = 3.0;
      var current = 0.0;
      while (current < dist) {
        final startRatio = current / dist;
        final endRatio = math.min((current + dashLen) / dist, 1.0);
        final sx = p1.screenX + dx * startRatio + nx * offsetDist;
        final sy = p1.screenY + dy * startRatio + ny * offsetDist;
        final ex = p1.screenX + dx * endRatio + nx * offsetDist;
        final ey = p1.screenY + dy * endRatio + ny * offsetDist;
        canvas.drawLine(Offset(sx, sy), Offset(ex, ey), paintDashed);
        current += dashLen + gapLen;
      }
    } else {
      // Single solid cylinder with two-tone CPK gradient
      _drawCylinderBond(canvas, p1, p2, 0, 0, strokeWidth);
    }
  }

  void _drawCylinderBond(Canvas canvas, _ProjectedAtom p1, _ProjectedAtom p2, double offX, double offY, double width) {
    final p1Offset = Offset(p1.screenX + offX, p1.screenY + offY);
    final p2Offset = Offset(p2.screenX + offX, p2.screenY + offY);

    // Two-tone gradient bond matching atom colors
    final paint = Paint()
      ..shader = LinearGradient(
        colors: [
          Color.lerp(p1.atom.cpkColor, Colors.black, 0.25)!,
          Color.lerp(p2.atom.cpkColor, Colors.black, 0.25)!,
        ],
      ).createShader(Rect.fromPoints(p1Offset, p2Offset))
      ..strokeWidth = width
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(p1Offset, p2Offset, paint);

    // Subtle specular highlight spine along cylinder
    final highlightPaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.18)
      ..strokeWidth = width * 0.28
      ..strokeCap = StrokeCap.round;

    canvas.drawLine(p1Offset, p2Offset, highlightPaint);
  }

  void _paintAtom(Canvas canvas, _ProjectedAtom p) {
    final center = Offset(p.screenX, p.screenY);
    final radius = p.radius;
    final isSelected = selectedAtomIndex == p.index;

    // Selection / Orbital halo
    if (isSelected) {
      final glowPaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.45)
        ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 8);
      canvas.drawCircle(center, radius + 7, glowPaint);

      final ringPaint = Paint()
        ..color = Colors.white
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2.0;
      canvas.drawCircle(center, radius + 4, ringPaint);
    }

    // 3D Specular CPK Sphere Shader (glossy specular reflection)
    final baseColor = p.atom.cpkColor;
    final highlightColor = Color.lerp(baseColor, Colors.white, 0.82)!;
    final midLightColor = Color.lerp(baseColor, Colors.white, 0.35)!;
    final shadowColor = Color.lerp(baseColor, Colors.black, 0.65)!;

    final sphereGradient = RadialGradient(
      center: const Alignment(-0.38, -0.38),
      radius: 0.92,
      colors: [
        highlightColor, // Pinpoint specular highlight
        midLightColor,
        baseColor,      // True CPK color
        shadowColor,    // Dark limb / occlusion shadow
      ],
      stops: const [0.0, 0.22, 0.68, 1.0],
    );

    final spherePaint = Paint()
      ..shader = sphereGradient.createShader(Rect.fromCircle(center: center, radius: radius));

    canvas.drawCircle(center, radius, spherePaint);

    // Subtle dark rim border for definition against dark background
    final rimPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.45)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.8;
    canvas.drawCircle(center, radius, rimPaint);

    // Element symbol and formal charge label
    if (showLabels && radius >= 11.0) {
      // Determine readable text color
      final isLightAtom = p.atom.symbol.toUpperCase() == 'H';
      final textColor = isLightAtom ? const Color(0xFF1E293B) : Colors.white;

      final tp = TextPainter(
        text: TextSpan(
          text: p.atom.symbol,
          style: TextStyle(
            color: textColor,
            fontSize: (radius * 0.95).clamp(8.5, 14.0),
            fontWeight: FontWeight.w900,
            shadows: isLightAtom
                ? null
                : const [Shadow(color: Colors.black87, blurRadius: 3, offset: Offset(0.5, 0.5))],
          ),
        ),
        textDirection: TextDirection.ltr,
      )..layout();

      tp.paint(canvas, Offset(center.dx - tp.width / 2, center.dy - tp.height / 2));

      // Small formal charge indicator badge (+ or - or d+)
      if (p.atom.formalCharge != null && p.atom.formalCharge!.isNotEmpty && radius >= 14.0) {
        final isPositive = p.atom.formalCharge!.contains('+');
        final badgeColor = isPositive ? const Color(0xFFEF4444) : const Color(0xFF3B82F6);

        final badgeTp = TextPainter(
          text: TextSpan(
            text: p.atom.formalCharge,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 8.5,
              fontWeight: FontWeight.w900,
            ),
          ),
          textDirection: TextDirection.ltr,
        )..layout();

        final badgeCenter = Offset(center.dx + radius * 0.72, center.dy - radius * 0.72);
        final badgeBg = Paint()..color = badgeColor;
        canvas.drawCircle(badgeCenter, 6.5, badgeBg);
        badgeTp.paint(canvas, Offset(badgeCenter.dx - badgeTp.width / 2, badgeCenter.dy - badgeTp.height / 2));
      }
    }
  }

  @override
  bool shouldRepaint(covariant Molecule3DPainter oldDelegate) {
    return oldDelegate.yaw != yaw ||
        oldDelegate.pitch != pitch ||
        oldDelegate.zoom != zoom ||
        oldDelegate.renderMode != renderMode ||
        oldDelegate.selectedAtomIndex != selectedAtomIndex ||
        oldDelegate.showLabels != showLabels ||
        oldDelegate.molecule != molecule;
  }
}

class _ProjectedAtom {
  final int index;
  final Atom3D atom;
  final double screenX;
  final double screenY;
  final double depth;
  final double radius;
  final double perspectiveFactor;

  _ProjectedAtom({
    required this.index,
    required this.atom,
    required this.screenX,
    required this.screenY,
    required this.depth,
    required this.radius,
    required this.perspectiveFactor,
  });
}

abstract class _Drawable {
  double get depth;
}

class _AtomDrawable extends _Drawable {
  final _ProjectedAtom projectedAtom;
  _AtomDrawable({required this.projectedAtom});

  @override
  double get depth => projectedAtom.depth;
}

class _BondDrawable extends _Drawable {
  final Bond3D bond;
  final _ProjectedAtom p1;
  final _ProjectedAtom p2;
  @override
  final double depth;

  _BondDrawable({
    required this.bond,
    required this.p1,
    required this.p2,
    required this.depth,
  });
}
