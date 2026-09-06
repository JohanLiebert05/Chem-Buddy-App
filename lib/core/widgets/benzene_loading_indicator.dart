import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import 'claude_loading_text.dart';

/// Interactive & Animated Benzene Bond Formation Loading Indicator.
///
/// Chemically accurate Kekulé & Delocalized resonance representation of Benzene (C₆H₆):
/// - 6 sp² Carbon atom vertices with atomic glow pulses.
/// - Progressive σ-bond (single bond) formation tracing around the hexagon (120° angles).
/// - Dynamic π-bond (double bond) localized formation alternating with aromatic delocalized circle resonance.
/// - Orbiting π-electron cloud particles and glowing resonance energy.
class BenzeneLoadingIndicator extends StatefulWidget {
  final double size;
  final bool showMicrocopy;
  final List<String> thoughts;
  final String? customMessage;
  final Color? primaryColor;
  final Color? accentColor;

  const BenzeneLoadingIndicator({
    super.key,
    this.size = 110,
    this.showMicrocopy = true,
    this.thoughts = ClaudeThinkingMicrocopy.askAi,
    this.customMessage,
    this.primaryColor,
    this.accentColor,
  });

  @override
  State<BenzeneLoadingIndicator> createState() => _BenzeneLoadingIndicatorState();
}

class _BenzeneLoadingIndicatorState extends State<BenzeneLoadingIndicator>
    with TickerProviderStateMixin {
  late final AnimationController _bondController;
  late final AnimationController _resonanceController;
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    // Controls the progressive bond drawing cycle (0.0 to 1.0)
    _bondController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    )..repeat();

    // Controls the spinning/pulsing aromatic delocalized ring
    _resonanceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 4000),
    )..repeat();

    // Subtle breathing/pulse animation
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _bondController.dispose();
    _resonanceController.dispose();
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final primary = widget.primaryColor ?? AppColors.purpleBright;
    final accent = widget.accentColor ?? AppColors.brandBright;

    final benzeneWidget = AnimatedBuilder(
      animation: Listenable.merge([_bondController, _resonanceController, _pulseController]),
      builder: (context, child) {
        return CustomPaint(
          size: Size(widget.size, widget.size),
          painter: _BenzeneBondsPainter(
            bondProgress: _bondController.value,
            resonanceProgress: _resonanceController.value,
            pulseProgress: _pulseController.value,
            primaryColor: primary,
            accentColor: accent,
          ),
        );
      },
    );

    if (!widget.showMicrocopy && widget.customMessage == null) {
      return benzeneWidget;
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        benzeneWidget,
        const SizedBox(height: 14),
        if (widget.customMessage != null)
          Text(
            widget.customMessage!,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w700,
              fontSize: 13.5,
              letterSpacing: -0.2,
            ),
          )
        else
          ClaudeThinkingIndicator(
            thoughts: widget.thoughts,
            isCard: false,
            showSparkle: false,
            showThinkingHeader: true,
            thinkingHeader: 'Synthesizing Response',
            fontSize: 13.0,
          ),
      ],
    );
  }
}

/// Custom painter for the dynamic Benzene C₆H₆ formation animation.
class _BenzeneBondsPainter extends CustomPainter {
  final double bondProgress;
  final double resonanceProgress;
  final double pulseProgress;
  final Color primaryColor;
  final Color accentColor;

  _BenzeneBondsPainter({
    required this.bondProgress,
    required this.resonanceProgress,
    required this.pulseProgress,
    required this.primaryColor,
    required this.accentColor,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = (size.width / 2) * 0.78;
    final innerDoubleOffset = radius * 0.16;

    // Calculate 6 carbon vertices of the regular hexagon
    final vertices = List<Offset>.generate(6, (i) {
      final angle = -math.pi / 2 + (i * math.pi / 3);
      return Offset(
        center.dx + radius * math.cos(angle),
        center.dy + radius * math.sin(angle),
      );
    });

    // 1. Ambient Glow Backing behind benzene structure
    final glowPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.08 + (0.06 * pulseProgress))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 16);
    canvas.drawCircle(center, radius * 0.95, glowPaint);

    // 2. Progressive Sigma (σ) Single Bonds (6 edges)
    // bondProgress [0.0 -> 0.6]: sequentially draw all 6 single bonds
    final sigmaProgress = (bondProgress / 0.60).clamp(0.0, 1.0);
    const totalEdges = 6;
    final singleBondPaint = Paint()
      ..color = primaryColor.withValues(alpha: 0.90)
      ..strokeWidth = math.max(2.2, size.width * 0.032)
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    for (int i = 0; i < totalEdges; i++) {
      final edgeStartProgress = i / totalEdges;
      final edgeEndProgress = (i + 1) / totalEdges;

      if (sigmaProgress > edgeStartProgress) {
        final p1 = vertices[i];
        final p2 = vertices[(i + 1) % totalEdges];

        if (sigmaProgress >= edgeEndProgress) {
          // Entire edge is complete
          canvas.drawLine(p1, p2, singleBondPaint);
        } else {
          // Edge is partially drawn
          final edgeFraction = (sigmaProgress - edgeStartProgress) / (edgeEndProgress - edgeStartProgress);
          final currentEnd = Offset.lerp(p1, p2, edgeFraction)!;
          canvas.drawLine(p1, currentEnd, singleBondPaint);

          // Glowing formation tip spark
          final sparkPaint = Paint()
            ..color = accentColor
            ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
          canvas.drawCircle(currentEnd, 3.5, sparkPaint);
        }
      }
    }

    // 3. Progressive Pi (π) Double Bonds or Aromatic Resonance Ring
    // bondProgress [0.40 -> 0.95]: draw alternating π double bonds and aromatic delocalized circle
    if (bondProgress > 0.40) {
      final piProgress = ((bondProgress - 0.40) / 0.55).clamp(0.0, 1.0);

      // Kekulé double bonds at edges 0, 2, 4 (with inner offset)
      final doubleBondPaint = Paint()
        ..color = accentColor.withValues(alpha: 0.85 * piProgress)
        ..strokeWidth = math.max(1.8, size.width * 0.024)
        ..style = PaintingStyle.stroke
        ..strokeCap = StrokeCap.round;

      final doubleBondIndices = [0, 2, 4];
      for (final i in doubleBondIndices) {
        final p1 = vertices[i];
        final p2 = vertices[(i + 1) % 6];

        // Compute inward offset direction toward center
        final edgeMid = Offset((p1.dx + p2.dx) / 2, (p1.dy + p2.dy) / 2);
        final toCenter = center - edgeMid;
        final dir = toCenter / toCenter.distance;
        final offsetVec = dir * innerDoubleOffset;

        final insetP1 = Offset.lerp(p1 + offsetVec, p2 + offsetVec, 0.14)!;
        final insetP2 = Offset.lerp(p1 + offsetVec, p2 + offsetVec, 0.86)!;

        final currentInsetEnd = Offset.lerp(insetP1, insetP2, piProgress)!;
        canvas.drawLine(insetP1, currentInsetEnd, doubleBondPaint);
      }

      // 4. Aromatic Delocalized π-Electron Ring (Resonance Circle)
      final innerCircleRadius = radius * 0.52;
      final resonancePaint = Paint()
        ..color = primaryColor.withValues(alpha: 0.35 * piProgress + (0.25 * pulseProgress))
        ..strokeWidth = math.max(1.5, size.width * 0.02)
        ..style = PaintingStyle.stroke;

      canvas.drawCircle(center, innerCircleRadius, resonancePaint);

      // Rotating π-electron orbital clouds / sparks
      const electronCount = 3;
      final electronPaint = Paint()..color = accentColor;
      for (int e = 0; e < electronCount; e++) {
        final eAngle = (resonanceProgress * 2 * math.pi) + (e * 2 * math.pi / electronCount);
        final ePos = Offset(
          center.dx + innerCircleRadius * math.cos(eAngle),
          center.dy + innerCircleRadius * math.sin(eAngle),
        );
        canvas.drawCircle(ePos, 2.2, electronPaint);

        final eGlowPaint = Paint()
          ..color = accentColor.withValues(alpha: 0.5)
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 3);
        canvas.drawCircle(ePos, 4.0, eGlowPaint);
      }
    }

    // 5. Carbon Atom Vertices (sp² Hybridized Nodes)
    for (int i = 0; i < 6; i++) {
      final vertexProgress = i / 6.0;
      final isActivated = sigmaProgress >= vertexProgress;

      final nodeCenter = vertices[i];
      final nodeBaseColor = isActivated ? primaryColor : AppColors.border;

      // Outer glow
      if (isActivated) {
        final nodeGlow = Paint()
          ..color = primaryColor.withValues(alpha: 0.4 + (0.3 * pulseProgress))
          ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
        canvas.drawCircle(nodeCenter, 4.5, nodeGlow);
      }

      // Solid vertex core
      final nodePaint = Paint()..color = isActivated ? Colors.white : nodeBaseColor;
      canvas.drawCircle(nodeCenter, math.max(2.4, size.width * 0.035), nodePaint);
    }
  }

  @override
  bool shouldRepaint(covariant _BenzeneBondsPainter oldDelegate) =>
      oldDelegate.bondProgress != bondProgress ||
      oldDelegate.resonanceProgress != resonanceProgress ||
      oldDelegate.pulseProgress != pulseProgress ||
      oldDelegate.primaryColor != primaryColor ||
      oldDelegate.accentColor != accentColor;
}

/// Compact Benzene Loading Bubble for chat streams & in-line actions.
class BenzeneThinkingBubble extends StatelessWidget {
  final List<String> thoughts;
  final VoidCallback? onCancel;

  const BenzeneThinkingBubble({
    super.key,
    this.thoughts = ClaudeThinkingMicrocopy.askAi,
    this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 14, left: 4, right: 32),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFF18122B).withValues(alpha: 0.90),
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(16),
            topRight: Radius.circular(16),
            bottomRight: Radius.circular(16),
            bottomLeft: Radius.circular(4),
          ),
          border: Border.all(
            color: AppColors.purple.withValues(alpha: 0.45),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: AppColors.purple.withValues(alpha: 0.18),
              blurRadius: 12,
              offset: const Offset(0, 3),
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            const BenzeneLoadingIndicator(
              size: 36,
              showMicrocopy: false,
            ),
            const SizedBox(width: 12),
            Flexible(
              child: ClaudeThinkingIndicator(
                thoughts: thoughts,
                isCard: false,
                showSparkle: false,
                showThinkingHeader: true,
                thinkingHeader: 'Synthesizing Response',
                fontSize: 13.0,
                onCancel: onCancel,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
