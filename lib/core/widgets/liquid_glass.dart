import 'dart:ui';

import 'package:flutter/material.dart';

import '../theme/appearance.dart';

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
    final colors = Theme.of(context).colorScheme;
    final tokens = GlassTokens.of(context);
    final prism = PrismTokens.of(context);
    final light = colors.brightness == Brightness.light;
    final highContrast = MediaQuery.highContrastOf(context);
    final opaque = highContrast || tokens.blur == 0;
    final effectiveBlur = blurSigma.clamp(0.0, tokens.blur).toDouble();
    final effectiveBorderRadius =
        customBorderRadius ?? BorderRadius.circular(borderRadius);
    final effectiveBg = (backgroundColor ?? colors.surfaceContainerLow)
        .withValues(alpha: opaque ? 1 : tokens.opacity);
    final effectiveBorder =
        borderColor ??
        colors.primary.withValues(
          alpha: highContrast
              ? .65
              : light
              ? .14
              : .22,
        );
    final effectiveShadows =
        shadows ??
        [
          BoxShadow(
            color: (light ? colors.primary : Colors.black).withValues(
              alpha: light ? .055 : .24,
            ),
            blurRadius: light ? 28 : 22,
            offset: const Offset(0, 6),
          ),
        ];

    Widget content = Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: opaque
            ? null
            : LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color.alphaBlend(
                    (light ? Colors.white : colors.primary).withValues(
                      alpha: light ? .46 : .06,
                    ),
                    effectiveBg,
                  ),
                  prism.enabled
                      ? Color.alphaBlend(
                          prism.colors[1].withValues(alpha: light ? .045 : .04),
                          effectiveBg,
                        )
                      : effectiveBg,
                  Color.alphaBlend(
                    (prism.enabled ? prism.colors[2] : colors.tertiary)
                        .withValues(alpha: light ? .05 : .025),
                    effectiveBg,
                  ),
                ],
              ),
        color: opaque ? effectiveBg : null,
        borderRadius: effectiveBorderRadius,
        border: Border.all(color: effectiveBorder, width: borderWidth),
      ),
      child: child,
    );

    if (enableBlur && !opaque && effectiveBlur > 0) {
      content = ClipRRect(
        borderRadius: effectiveBorderRadius,
        clipBehavior: clipBehavior,
        child: BackdropFilter(
          filter: ImageFilter.blur(
            sigmaX: effectiveBlur,
            sigmaY: effectiveBlur,
          ),
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
