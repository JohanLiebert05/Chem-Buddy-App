import 'package:flutter/material.dart';

/// Staggered fade + slight rise for the home dashboard. Caps delay so long lists stay snappy.
class FadeSlideIn extends StatelessWidget {
  const FadeSlideIn({super.key, required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final delay = (index * 45).clamp(0, 420);
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: Duration(milliseconds: 420 + delay),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class AnimatedDashboardList extends StatelessWidget {
  const AnimatedDashboardList({
    super.key,
    required this.children,
    this.padding,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: padding,
      children: [
        for (var i = 0; i < children.length; i++) FadeSlideIn(index: i, child: children[i]),
      ],
    );
  }
}
