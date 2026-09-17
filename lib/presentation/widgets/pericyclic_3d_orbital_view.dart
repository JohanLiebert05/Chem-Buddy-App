import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../../core/utils/haptics.dart';
import '../../data/services/pericyclic_service.dart';

class Pericyclic3DOrbitalView extends StatefulWidget {
  final Pericyclic3DSystem system;
  final MolecularOrbital3D activeOrbital;
  final String? transitionStateLabel;
  final bool isTransitionState;
  final bool showSecondaryOverlap;

  const Pericyclic3DOrbitalView({
    super.key,
    required this.system,
    required this.activeOrbital,
    this.transitionStateLabel,
    this.isTransitionState = false,
    this.showSecondaryOverlap = false,
  });

  @override
  State<Pericyclic3DOrbitalView> createState() => _Pericyclic3DOrbitalViewState();
}

class _Pericyclic3DOrbitalViewState extends State<Pericyclic3DOrbitalView> with SingleTickerProviderStateMixin {
  double _rotX = -0.35; // pitch
  double _rotY = 0.55;  // yaw
  double _zoom = 1.0;
  bool _autoSpin = false;
  late AnimationController _spinController;

  @override
  void initState() {
    super.initState();
    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 12),
    )..addListener(() {
        if (_autoSpin) {
          setState(() {
            _rotY += 0.015;
            if (_rotY > math.pi * 2) _rotY -= math.pi * 2;
          });
        }
      });
  }

  @override
  void dispose() {
    _spinController.dispose();
    super.dispose();
  }

  void _resetOrientation() {
    AppHaptics.selection();
    setState(() {
      _rotX = -0.35;
      _rotY = 0.55;
      _zoom = 1.0;
    });
  }

  void _toggleAutoSpin() {
    AppHaptics.selection();
    setState(() {
      _autoSpin = !_autoSpin;
      if (_autoSpin) {
        _spinController.repeat();
      } else {
        _spinController.stop();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF070D18),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle.withValues(alpha: 0.6)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Stack(
          children: [
            // Background subtle 3D coordinate grid
            Positioned.fill(
              child: CustomPaint(
                painter: _GridBackgroundPainter(),
              ),
            ),

            // Interactive 3D Canvas
            GestureDetector(
              onScaleUpdate: (details) {
                setState(() {
                  _rotY += details.focalPointDelta.dx * 0.01;
                  _rotX -= details.focalPointDelta.dy * 0.01;
                  // Clamp pitch to avoid gimbal flip
                  _rotX = _rotX.clamp(-math.pi / 2.3, math.pi / 2.3);
                  if (details.scale != 1.0) {
                    _zoom = (_zoom * details.scale).clamp(0.65, 2.2);
                  }
                });
              },
              child: SizedBox(
                width: double.infinity,
                height: 320,
                child: CustomPaint(
                  painter: _Orbital3DPainter(
                    system: widget.system,
                    orbital: widget.activeOrbital,
                    rotX: _rotX,
                    rotY: _rotY,
                    zoom: _zoom,
                    isTransitionState: widget.isTransitionState,
                    showSecondaryOverlap: widget.showSecondaryOverlap,
                  ),
                ),
              ),
            ),

            // Top Status & Controls Overlay
            Positioned(
              top: 12,
              left: 12,
              right: 12,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: AppColors.accentCyan.withValues(alpha: 0.3)),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.view_in_ar_rounded, size: 14, color: AppColors.accentCyan),
                        const SizedBox(width: 6),
                        Text(
                          widget.transitionStateLabel ?? widget.activeOrbital.name,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Row(
                    children: [
                      _buildIconButton(
                        icon: _autoSpin ? Icons.pause_circle_filled_rounded : Icons.play_circle_filled_rounded,
                        color: _autoSpin ? AppColors.brandBright : Colors.white70,
                        tooltip: _autoSpin ? 'Pause Orbit' : 'Auto Orbit 3D',
                        onTap: _toggleAutoSpin,
                      ),
                      const SizedBox(width: 6),
                      _buildIconButton(
                        icon: Icons.refresh_rounded,
                        color: Colors.white70,
                        tooltip: 'Reset View',
                        onTap: _resetOrientation,
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Bottom Legend & Phase Indicators
            Positioned(
              bottom: 10,
              left: 12,
              right: 12,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFF0F172A).withValues(alpha: 0.88),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.white12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildLegendItem(
                      color: const Color(0xFF06B6D4),
                      label: '(+) Positive Phase (Ψ > 0)',
                    ),
                    _buildLegendItem(
                      color: const Color(0xFFF59E0B),
                      label: '(–) Negative Phase (Ψ < 0)',
                    ),
                    if (widget.isTransitionState)
                      _buildLegendItem(
                        color: const Color(0xFF10B981),
                        label: 'In-Phase Overlap',
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIconButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onTap,
  }) {
    return Material(
      color: const Color(0xFF0F172A).withValues(alpha: 0.85),
      borderRadius: BorderRadius.circular(8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white12),
          ),
          child: Icon(icon, color: color, size: 16),
        ),
      ),
    );
  }

  Widget _buildLegendItem({required Color color, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            color: color,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.6),
                blurRadius: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 5),
        Text(
          label,
          style: const TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.w600),
        ),
      ],
    );
  }
}

// ----------------------------------------------------
// 3D Orbital Custom Painter
// ----------------------------------------------------

class _Orbital3DPainter extends CustomPainter {
  final Pericyclic3DSystem system;
  final MolecularOrbital3D orbital;
  final double rotX;
  final double rotY;
  final double zoom;
  final bool isTransitionState;
  final bool showSecondaryOverlap;

  _Orbital3DPainter({
    required this.system,
    required this.orbital,
    required this.rotX,
    required this.rotY,
    required this.zoom,
    required this.isTransitionState,
    required this.showSecondaryOverlap,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final scale = 48.0 * zoom;

    // Rotation matrices: Yaw around Y, Pitch around X
    final cosY = math.cos(rotY);
    final sinY = math.sin(rotY);
    final cosX = math.cos(rotX);
    final sinX = math.sin(rotX);

    // 3D -> 2D Projection helper
    _Point3D project(double x, double y, double z) {
      // 1. Rotate Y (yaw)
      final x1 = x * cosY + z * sinY;
      final y1 = y;
      final z1 = -x * sinY + z * cosY;

      // 2. Rotate X (pitch)
      final x2 = x1;
      final y2 = y1 * cosX - z1 * sinX;
      final z2 = y1 * sinX + z1 * cosX;

      // Perspective divide
      final fov = 8.0;
      final pz = z2 + fov;
      final persp = pz > 0.1 ? fov / pz : 1.0;

      final sx = cx + x2 * scale * persp;
      final sy = cy - y2 * scale * persp;

      return _Point3D(sx, sy, z2, persp);
    }

    // Collect all renderable entities for painter's algorithm (depth sorting)
    final renderList = <_RenderEntity>[];

    // 1. Project Atoms
    final projectedAtoms = <_Point3D>[];
    for (int i = 0; i < system.atoms.length; i++) {
      final a = system.atoms[i];
      final p = project(a.x, a.y, a.z);
      projectedAtoms.add(p);
      renderList.add(_RenderEntity(
        depth: p.z,
        type: _EntityType.atom,
        index: i,
        pos: p,
      ));
    }

    // 2. Project Bonds
    for (int b = 0; b < system.bonds.length; b++) {
      final bond = system.bonds[b];
      if (bond.from < projectedAtoms.length && bond.to < projectedAtoms.length) {
        final p1 = projectedAtoms[bond.from];
        final p2 = projectedAtoms[bond.to];
        final avgZ = (p1.z + p2.z) / 2.0;
        renderList.add(_RenderEntity(
          depth: avgZ - 0.05,
          type: _EntityType.bond,
          index: b,
          pos: p1,
          targetPos: p2,
        ));
      }
    }

    // 3. Project Orbital Lobes
    for (int l = 0; l < orbital.lobes.length; l++) {
      final lobe = orbital.lobes[l];
      final p = project(lobe.x, lobe.y, lobe.z);
      renderList.add(_RenderEntity(
        depth: p.z,
        type: _EntityType.lobe,
        index: l,
        pos: p,
      ));
    }

    // 4. Sort all entities by depth (back to front)
    renderList.sort((a, b) => a.depth.compareTo(b.depth));

    // Paint in depth order
    for (final entity in renderList) {
      switch (entity.type) {
        case _EntityType.bond:
          _paintBond(canvas, entity);
          break;
        case _EntityType.atom:
          _paintAtom(canvas, entity);
          break;
        case _EntityType.lobe:
          _paintLobe(canvas, entity);
          break;
      }
    }

    // 5. If Transition State: Draw Primary & Secondary Overlap Interaction Rays
    if (isTransitionState) {
      _paintTransitionStateInteractions(canvas, project);
    }
  }

  void _paintBond(Canvas canvas, _RenderEntity entity) {
    final bond = system.bonds[entity.index];
    final p1 = entity.pos;
    final p2 = entity.targetPos!;

    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..strokeWidth = (bond.isDouble ? 3.5 : 2.5) * p1.persp
      ..strokeCap = StrokeCap.round;

    if (bond.isDouble) {
      final dx = p2.x - p1.x;
      final dy = p2.y - p1.y;
      final len = math.sqrt(dx * dx + dy * dy);
      if (len > 0) {
        final nx = -dy / len * 3.0;
        final ny = dx / len * 3.0;
        canvas.drawLine(Offset(p1.x + nx, p1.y + ny), Offset(p2.x + nx, p2.y + ny), paint);
        canvas.drawLine(Offset(p1.x - nx, p1.y - ny), Offset(p2.x - nx, p2.y - ny), paint);
      }
    } else {
      canvas.drawLine(Offset(p1.x, p1.y), Offset(p2.x, p2.y), paint);
    }
  }

  void _paintAtom(Canvas canvas, _RenderEntity entity) {
    final atom = system.atoms[entity.index];
    final p = entity.pos;
    final radius = 9.0 * p.persp * zoom;

    final glowPaint = Paint()
      ..color = AppColors.brandPrimary.withValues(alpha: 0.3)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 6);
    canvas.drawCircle(Offset(p.x, p.y), radius + 2, glowPaint);

    final spherePaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.35, -0.35),
        radius: 0.8,
        colors: [
          Colors.white,
          const Color(0xFF38BDF8),
          const Color(0xFF0284C7),
          const Color(0xFF0F172A),
        ],
        stops: const [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: Offset(p.x, p.y), radius: radius));

    canvas.drawCircle(Offset(p.x, p.y), radius, spherePaint);

    final textPainter = TextPainter(
      text: TextSpan(
        text: atom.label,
        style: TextStyle(
          color: Colors.white,
          fontSize: (9.0 * p.persp * zoom).clamp(7.0, 13.0),
          fontWeight: FontWeight.w800,
          shadows: const [Shadow(blurRadius: 3, color: Colors.black)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    textPainter.paint(
      canvas,
      Offset(p.x - textPainter.width / 2, p.y + radius + 2),
    );
  }

  void _paintLobe(Canvas canvas, _RenderEntity entity) {
    final lobe = orbital.lobes[entity.index];
    final p = entity.pos;
    final isPos = lobe.sign > 0;

    final baseRadius = 22.0 * lobe.size * p.persp * zoom;
    final radius = baseRadius.clamp(8.0, 36.0);

    final mainColor = isPos ? const Color(0xFF06B6D4) : const Color(0xFFF59E0B);
    final coreColor = isPos ? const Color(0xFF67E8F9) : const Color(0xFFFBBF24);
    final shadowColor = isPos ? const Color(0xFF0E7490) : const Color(0xFFB45309);

    final glowPaint = Paint()
      ..color = mainColor.withValues(alpha: 0.35)
      ..maskFilter = MaskFilter.blur(BlurStyle.normal, radius * 0.45);
    canvas.drawCircle(Offset(p.x, p.y), radius * 1.1, glowPaint);

    final lobeShader = RadialGradient(
      center: const Alignment(-0.3, -0.3),
      radius: 0.75,
      colors: [
        Colors.white,
        coreColor,
        mainColor,
        shadowColor,
      ],
      stops: const [0.0, 0.3, 0.7, 1.0],
    ).createShader(Rect.fromCircle(center: Offset(p.x, p.y), radius: radius));

    final paint = Paint()
      ..shader = lobeShader
      ..style = PaintingStyle.fill;

    canvas.save();
    canvas.translate(p.x, p.y);
    canvas.scale(1.0, 1.2);
    canvas.drawCircle(Offset.zero, radius, paint);

    final signText = isPos ? '+' : '–';
    final signPainter = TextPainter(
      text: TextSpan(
        text: signText,
        style: TextStyle(
          color: Colors.white,
          fontSize: (14.0 * p.persp * zoom).clamp(10.0, 18.0),
          fontWeight: FontWeight.w900,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black87)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    signPainter.paint(
      canvas,
      Offset(-signPainter.width / 2, -signPainter.height / 2),
    );

    canvas.restore();
  }

  void _paintTransitionStateInteractions(Canvas canvas, _Point3D Function(double, double, double) project) {
    final greenDashed = Paint()
      ..color = const Color(0xFF10B981)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke;

    if (system.atoms.length >= 6) {
      final pDiene1 = project(system.atoms[0].x, system.atoms[0].y, system.atoms[0].z);
      final pDieno1 = project(system.atoms[4].x, system.atoms[4].y, system.atoms[4].z);
      _drawDashedLine(canvas, Offset(pDiene1.x, pDiene1.y), Offset(pDieno1.x, pDieno1.y), greenDashed);

      final pDiene4 = project(system.atoms[3].x, system.atoms[3].y, system.atoms[3].z);
      final pDieno2 = project(system.atoms[5].x, system.atoms[5].y, system.atoms[5].z);
      _drawDashedLine(canvas, Offset(pDiene4.x, pDiene4.y), Offset(pDieno2.x, pDieno2.y), greenDashed);

      final midX = (pDiene1.x + pDieno1.x) / 2;
      final midY = (pDiene1.y + pDieno1.y) / 2;
      _drawBadge(canvas, Offset(midX - 35, midY), 'Primary [4s+2s] σ Overlap', const Color(0xFF10B981));
    }

    if (showSecondaryOverlap && system.atoms.length >= 7) {
      final purpleDashed = Paint()
        ..color = const Color(0xFFA855F7)
        ..strokeWidth = 2.2
        ..style = PaintingStyle.stroke;

      final pDiene2 = project(system.atoms[1].x, system.atoms[1].y, system.atoms[1].z);
      final pCarbonyl = project(system.atoms[6].x, system.atoms[6].y, system.atoms[6].z);
      _drawDashedLine(canvas, Offset(pDiene2.x, pDiene2.y), Offset(pCarbonyl.x, pCarbonyl.y), purpleDashed);

      final pDiene3 = project(system.atoms[2].x, system.atoms[2].y, system.atoms[2].z);
      _drawDashedLine(canvas, Offset(pDiene3.x, pDiene3.y), Offset(pCarbonyl.x, pCarbonyl.y), purpleDashed);

      final secMidX = (pDiene2.x + pCarbonyl.x) / 2;
      final secMidY = (pDiene2.y + pCarbonyl.y) / 2;
      _drawBadge(canvas, Offset(secMidX + 15, secMidY), 'Secondary Overlap (Endo Rule)', const Color(0xFFA855F7));
    }
  }

  void _drawDashedLine(Canvas canvas, Offset p1, Offset p2, Paint paint) {
    const dashWidth = 5.0;
    const dashSpace = 4.0;
    final dx = p2.dx - p1.dx;
    final dy = p2.dy - p1.dy;
    final distance = math.sqrt(dx * dx + dy * dy);
    if (distance == 0) return;

    final unitX = dx / distance;
    final unitY = dy / distance;

    double currentDist = 0.0;
    while (currentDist < distance) {
      final x1 = p1.dx + unitX * currentDist;
      final y1 = p1.dy + unitY * currentDist;
      final nextDist = math.min(currentDist + dashWidth, distance);
      final x2 = p1.dx + unitX * nextDist;
      final y2 = p1.dy + unitY * nextDist;
      canvas.drawLine(Offset(x1, y1), Offset(x2, y2), paint);
      currentDist += dashWidth + dashSpace;
    }
  }

  void _drawBadge(Canvas canvas, Offset pos, String text, Color color) {
    final textPainter = TextPainter(
      text: TextSpan(
        text: text,
        style: TextStyle(
          color: color,
          fontSize: 9.5,
          fontWeight: FontWeight.w800,
          shadows: const [Shadow(blurRadius: 4, color: Colors.black)],
        ),
      ),
      textDirection: TextDirection.ltr,
    )..layout();

    final rect = Rect.fromLTWH(
      pos.dx - 4,
      pos.dy - 2,
      textPainter.width + 8,
      textPainter.height + 4,
    );

    final bgPaint = Paint()..color = const Color(0xFF0F172A).withValues(alpha: 0.9);
    final borderPaint = Paint()
      ..color = color.withValues(alpha: 0.6)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.0;

    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), bgPaint);
    canvas.drawRRect(RRect.fromRectAndRadius(rect, const Radius.circular(4)), borderPaint);
    textPainter.paint(canvas, pos);
  }

  @override
  bool shouldRepaint(covariant _Orbital3DPainter oldDelegate) {
    return oldDelegate.rotX != rotX ||
        oldDelegate.rotY != rotY ||
        oldDelegate.zoom != zoom ||
        oldDelegate.orbital != orbital ||
        oldDelegate.isTransitionState != isTransitionState ||
        oldDelegate.showSecondaryOverlap != showSecondaryOverlap;
  }
}

class _GridBackgroundPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.03)
      ..strokeWidth = 1.0;

    const step = 32.0;
    for (double x = 0; x < size.width; x += step) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
    }
    for (double y = 0; y < size.height; y += step) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
    }
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _Point3D {
  final double x;
  final double y;
  final double z;
  final double persp;

  const _Point3D(this.x, this.y, this.z, this.persp);
}

enum _EntityType {
  atom,
  bond,
  lobe,
}

class _RenderEntity {
  final double depth;
  final _EntityType type;
  final int index;
  final _Point3D pos;
  final _Point3D? targetPos;

  _RenderEntity({
    required this.depth,
    required this.type,
    required this.index,
    required this.pos,
    this.targetPos,
  });
}
