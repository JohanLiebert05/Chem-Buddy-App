import 'expressive_motion.dart';

import 'package:flutter/material.dart';

import 'liquid_glass.dart';
import '../utils/haptics.dart';

/// Material 3 Expressive Container Card
///
/// Clean tonal surface, gentle rounded corners, responsive ink response,
/// with no jarring neon blur or unnecessary shadow bloat.
class GlowCard extends StatelessWidget {
  const GlowCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderColor,
    this.borderRadius = 18.0,
    this.backgroundColor,
  });

  final Widget child;
  final EdgeInsets padding;
  final VoidCallback? onTap;
  final Color? borderColor;
  final double borderRadius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) {
    final cardContent = LiquidGlassContainer(
      enableBlur: false,
      borderRadius: borderRadius,
      backgroundColor: backgroundColor,
      borderColor: borderColor,
      shadows: const [],
      child: Material(
        color: Colors.transparent,
        child: SpringPress(
          child: InkWell(
            onTap: onTap == null
                ? null
                : () {
                    AppHaptics.selection();
                    onTap!();
                  },
            borderRadius: BorderRadius.circular(borderRadius),
            child: Padding(
              padding: padding,
              child: SizedBox(width: double.infinity, child: child),
            ),
          ),
        ),
      ),
    );

    return cardContent;
  }
}

/// Material 3 Expressive Primary Action Button
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: SpringPress(
        child: FilledButton(
          onPressed: loading || onPressed == null
              ? null
              : () {
                  AppHaptics.confirm();
                  onPressed!();
                },
          style: FilledButton.styleFrom(
            backgroundColor: Theme.of(context).colorScheme.primary,
            foregroundColor: Theme.of(context).colorScheme.onPrimary,
            disabledBackgroundColor: Theme.of(context)
                .colorScheme
                .surfaceContainerHighest,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            elevation: 0,
          ),
          child: loading
              ? SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.2,
                    color: Theme.of(context).colorScheme.onPrimary,
                  ),
                )
              : Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (icon != null) ...[
                      Icon(icon, size: 18),
                      const SizedBox(width: 8),
                    ],
                    Flexible(
                      child: Text(
                        label,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          letterSpacing: 0.1,
                        ),
                      ),
                    ),
                  ],
                ),
        ),
      ),
    );
  }
}

/// Cohesive Material 3 Section Header without emoji clutter
class SectionTitle extends StatelessWidget {
  const SectionTitle(this.text, {super.key, this.action, this.icon});

  final String text;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Strip trailing or leading decorative emojis to maintain clean M3 typography
    final cleanText = _stripDecorativeEmojis(text);

    final titleWidget = Text(
      cleanText,
      style: TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );

    if (icon == null && action == null) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 18),
        child: titleWidget,
      );
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 10, top: 18),
      child: Row(
        mainAxisSize: action != null ? MainAxisSize.max : MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Theme.of(context).colorScheme.primary),
            const SizedBox(width: 8),
          ],
          if (action != null) Expanded(child: titleWidget) else titleWidget,
          ?action,
        ],
      ),
    );
  }

  static String _stripDecorativeEmojis(String s) {
    return s
        .replaceAll(
          RegExp(
            r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]',
            unicode: true,
          ),
          '',
        )
        .trim();
  }
}
