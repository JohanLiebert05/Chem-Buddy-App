import 'dart:ui';
import 'package:flutter/material.dart';

import '../theme/app_colors.dart';

/// Selective Apple Liquid Glass-inspired container
///
/// Combines a restrained [BackdropFilter] optical blur, a translucent tinted fill,
/// and a subtle specular border highlight. Ideal for floating navigation,
/// transient popovers, search pills, and floating action panels.
class LiquidGlassContainer extends StatelessWidget {
  const LiquidGlassContainer({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20.0,
    this.customBorderRadius,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0.8,
    this.blurSigma = 16.0,
    this.enableBlur = true,
    this.shadows,
    this.clipBehavior = Clip.antiAlias,
  });

  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final BorderRadius? customBorderRadius;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;
  final double blurSigma;
  final bool enableBlur;
  final List<BoxShadow>? shadows;
  final Clip clipBehavior;

  @override
  Widget build(BuildContext context) {
    final effectiveBorderRadius = customBorderRadius ?? BorderRadius.circular(borderRadius);
    final effectiveBg = backgroundColor ?? AppColors.surfaceContainerLow.withValues(alpha: 0.78);
    final effectiveBorder = borderColor ?? Colors.white.withValues(alpha: 0.12);
    final effectiveShadows = shadows ??
        [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ];

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: effectiveBorderRadius,
        border: Border.all(
          color: effectiveBorder,
          width: borderWidth,
        ),
      ),
      child: child,
    );

    if (enableBlur && blurSigma > 0) {
      content = ClipRRect(
        borderRadius: effectiveBorderRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: blurSigma, sigmaY: blurSigma),
          child: content,
        ),
      );
    } else {
      content = ClipRRect(
        borderRadius: effectiveBorderRadius,
        clipBehavior: clipBehavior,
        child: content,
      );
    }

    if (effectiveShadows.isNotEmpty) {
      content = DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: effectiveBorderRadius,
          boxShadow: effectiveShadows,
        ),
        child: content,
      );
    }

    if (margin != null) {
      content = Padding(padding: margin!, child: content);
    }

    return content;
  }
}
