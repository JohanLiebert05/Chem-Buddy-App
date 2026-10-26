import 'package:flutter/material.dart';
import 'package:flutter/physics.dart';

/// A short, interruptible spring that preserves the child's gestures and semantics.
class SpringPress extends StatefulWidget {
  const SpringPress({
    super.key,
    required this.child,
    this.enabled = true,
    this.pressedScale = .965,
  });
  final Widget child;
  final bool enabled;
  final double pressedScale;
  @override
  State<SpringPress> createState() => _SpringPressState();
}

class _SpringPressState extends State<SpringPress>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spring = AnimationController.unbounded(
    vsync: this,
    value: 1,
  );
  Offset? _origin;
  bool _dragged = false;
  bool get reduced => MediaQuery.disableAnimationsOf(context);
  void move(double target) {
    if (!widget.enabled || reduced) {
      return;
    }
    _spring.animateWith(
      SpringSimulation(
        const SpringDescription(mass: 1, stiffness: 480, damping: 19),
        _spring.value,
        target,
        _spring.velocity,
      ),
    );
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (reduced) {
      _spring.stop();
      _spring.value = 1;
    }
  }

  @override
  void dispose() {
    _spring.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final child = widget.child;
    final disabled =
        !widget.enabled ||
        (child is ButtonStyleButton &&
            child.onPressed == null &&
            child.onLongPress == null) ||
        (child is IconButton && child.onPressed == null) ||
        (child is InkWell &&
            child.onTap == null &&
            child.onLongPress == null) ||
        (child is FloatingActionButton && child.onPressed == null) ||
        (child is GestureDetector &&
            child.onTap == null &&
            child.onLongPress == null) ||
        (child is ListTile &&
            (!child.enabled ||
                (child.onTap == null && child.onLongPress == null)));
    if (disabled) {
      return child;
    }
    return Listener(
      onPointerDown: (event) {
        _origin = event.position;
        _dragged = false;
        move(widget.pressedScale);
      },
      onPointerMove: (event) {
        if (!_dragged &&
            _origin != null &&
            (event.position - _origin!).distance > 8) {
          _dragged = true;
          move(1);
        }
      },
      onPointerUp: (_) {
        if (!_dragged && !reduced && _spring.value > .995) {
          // A fast click must still produce visible feedback after release.
          _spring.value = widget.pressedScale;
        }
        _origin = null;
        move(1);
      },
      onPointerCancel: (_) {
        _origin = null;
        _dragged = true;
        move(1);
      },
      child: AnimatedBuilder(
        animation: _spring,
        child: widget.child,
        builder: (context, child) {
          final pressure = (reduced || MediaQuery.highContrastOf(context))
              ? 0.0
              : ((1 - _spring.value) / (1 - widget.pressedScale)).clamp(
                  0.0,
                  1.0,
                );
          final colors = Theme.of(context).colorScheme;
          return Transform.scale(
            transformHitTests: false,
            scale: reduced ? 1 : _spring.value.clamp(.92, 1.04),
            child: DecoratedBox(
              position: DecorationPosition.foreground,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(24),
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Colors.white.withValues(alpha: pressure * .25),
                    colors.primary.withValues(alpha: pressure * .08),
                    Colors.white.withValues(alpha: pressure * .10),
                  ],
                ),
                border: Border.all(
                  color: Colors.white.withValues(alpha: pressure * .45),
                ),
              ),
              child: child,
            ),
          );
        },
      ),
    );
  }
}

/// Gentle shared route motion; selected controls retain stronger local feedback.
class ExpressivePageTransitionsBuilder extends PageTransitionsBuilder {
  const ExpressivePageTransitionsBuilder();
  @override
  Widget buildTransitions<T>(
    PageRoute<T> route,
    BuildContext context,
    Animation<double> animation,
    Animation<double> secondaryAnimation,
    Widget child,
  ) {
    if (MediaQuery.disableAnimationsOf(context)) {
      return child;
    }
    final settle = animation.drive(CurveTween(curve: Curves.easeOutBack));
    final opacity = animation.drive(CurveTween(curve: Curves.easeOutCubic));
    return FadeTransition(
      opacity: opacity,
      child: ScaleTransition(
        scale: settle.drive(Tween<double>(begin: .985, end: 1)),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}
