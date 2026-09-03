import 'dart:math' as math;
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/haptics.dart';

/// 3D Perspective Flip Card Widget for Active Recall Flashcards.
/// Animates 180 degrees along the Y-axis with realistic depth perspective.
class FlipCard3D extends StatefulWidget {
  const FlipCard3D({
    super.key,
    required this.front,
    required this.back,
    this.isFlipped = false,
    this.onFlip,
    this.duration = const Duration(milliseconds: 360),
    this.canTapToFlip = true,
  });

  final Widget front;
  final Widget back;
  final bool isFlipped;
  final ValueChanged<bool>? onFlip;
  final Duration duration;
  final bool canTapToFlip;

  @override
  State<FlipCard3D> createState() => FlipCard3DState();
}

class FlipCard3DState extends State<FlipCard3D> with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late bool _isFront;

  @override
  void initState() {
    super.initState();
    _isFront = !widget.isFlipped;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutCubic),
    );

    if (widget.isFlipped) {
      _controller.value = 1.0;
    }
  }

  @override
  void didUpdateWidget(FlipCard3D oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isFlipped != oldWidget.isFlipped) {
      if (widget.isFlipped) {
        _flipToBack();
      } else {
        _flipToFront();
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void flip() {
    AppHaptics.selection();
    if (_controller.isAnimating) return;
    final willShowBack = _isFront;
    if (_isFront) {
      _flipToBack();
    } else {
      _flipToFront();
    }
    widget.onFlip?.call(willShowBack);
  }


  void _flipToBack() {
    _controller.forward().then((_) {
      if (mounted) setState(() => _isFront = false);
    });
  }

  void _flipToFront() {
    _controller.reverse().then((_) {
      if (mounted) setState(() => _isFront = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: widget.canTapToFlip ? flip : null,
      child: AnimatedBuilder(
        animation: _animation,
        builder: (context, child) {
          final angle = _animation.value * math.pi;
          final isShowingFront = angle <= (math.pi / 2);

          // 3D perspective matrix
          final transform = Matrix4.identity()
            ..setEntry(3, 2, 0.0012) // Perspective depth
            ..rotateY(angle);

          // Correct inversion for back of card
          if (!isShowingFront) {
            transform.rotateY(math.pi);
          }

          return Transform(
            transform: transform,
            alignment: Alignment.center,
            child: isShowingFront
                ? _buildCardSide(widget.front, isFront: true)
                : _buildCardSide(widget.back, isFront: false),
          );
        },
      ),
    );
  }

  Widget _buildCardSide(Widget content, {required bool isFront}) {
    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
          BoxShadow(
            color: AppColors.brandPrimary.withValues(alpha: 0.12),
            blurRadius: 20,
            spreadRadius: -2,
          ),
        ],
      ),
      child: Stack(
        children: [
          content,
          // Subtle flip affordance badge in top-right
          Positioned(
            top: 12,
            right: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.bg2.withValues(alpha: 0.85),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.borderHighlight, width: 0.6),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.flip_camera_android_rounded,
                    size: 12,
                    color: isFront ? AppColors.brandBright : AppColors.statusSuccess,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    isFront ? 'Flip' : 'Answer',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: isFront ? AppColors.brandBright : AppColors.statusSuccess,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
