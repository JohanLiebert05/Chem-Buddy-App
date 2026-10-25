import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
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
    final effectiveBg = backgroundColor ?? AppColors.surfaceContainerHigh;
    final effectiveBorder = borderColor ?? AppColors.borderSubtle;

    final cardContent = Container(
      width: double.infinity,
      padding: padding,
      decoration: BoxDecoration(
        color: effectiveBg,
        borderRadius: BorderRadius.circular(borderRadius),
        border: Border.all(color: effectiveBorder, width: 0.8),
      ),
      child: child,
    );

    if (onTap == null) {
      return cardContent;
    }

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () {
          AppHaptics.selection();
          onTap!();
        },
        borderRadius: BorderRadius.circular(borderRadius),
        splashColor: AppColors.brandPrimary.withValues(alpha: 0.12),
        highlightColor: AppColors.brandPrimary.withValues(alpha: 0.06),
        child: cardContent,
      ),
    );
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
      child: FilledButton(
        onPressed: loading || onPressed == null
            ? null
            : () {
                AppHaptics.confirm();
                onPressed!();
              },
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brandPrimary,
          foregroundColor: Colors.white,
          disabledBackgroundColor: AppColors.surfaceContainerHighest,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 0,
        ),
        child: loading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.2,
                  color: Colors.white,
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
    );
  }
}

/// Cohesive Material 3 Section Header without emoji clutter
class SectionTitle extends StatelessWidget {
  const SectionTitle(
    this.text, {
    super.key,
    this.action,
    this.icon,
  });

  final String text;
  final Widget? action;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    // Strip trailing or leading decorative emojis to maintain clean M3 typography
    final cleanText = _stripDecorativeEmojis(text);

    final titleWidget = Text(
      cleanText,
      style: const TextStyle(
        fontSize: 15,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        color: AppColors.textPrimary,
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
            Icon(icon, size: 18, color: AppColors.brandBright),
            const SizedBox(width: 8),
          ],
          if (action != null)
            Expanded(child: titleWidget)
          else
            titleWidget,
          ?action,
        ],
      ),
    );
  }

  static String _stripDecorativeEmojis(String s) {
    return s
        .replaceAll(RegExp(r'[\u{1F300}-\u{1F9FF}\u{2600}-\u{26FF}\u{2700}-\u{27BF}]', unicode: true), '')
        .trim();
  }
}
