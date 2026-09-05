import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../theme/app_colors.dart';
import '../utils/chemistry_text_formatter.dart';
import '../utils/haptics.dart';

/// Reusable display equation widget for chemistry formulas, reaction equations,
/// thermodynamic derivations, and KaTeX math blocks.
///
/// Features horizontal scrolling, subtle borders matching the dark chemistry theme,
/// one-tap copy, and graceful fallback to clean formatted Unicode math on parser errors.
class ChemistryEquation extends StatelessWidget {
  const ChemistryEquation({
    super.key,
    required this.equation,
    this.textStyle,
    this.label,
    this.selectable = true,
    this.showCopyButton = false,
  });

  final String equation;
  final TextStyle? textStyle;
  final String? label;
  final bool selectable;
  final bool showCopyButton;

  @override
  Widget build(BuildContext context) {
    final cleanExpr = _stripDelimiters(equation.trim());
    if (cleanExpr.isEmpty) return const SizedBox.shrink();

    final defaultStyle = textStyle ??
        const TextStyle(
          color: Colors.white,
          fontSize: 15.5,
          fontWeight: FontWeight.w600,
        );

    final content = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.75),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.28)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (label != null && label!.isNotEmpty) ...[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  label!,
                  style: const TextStyle(
                    color: AppColors.purpleBright,
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                if (showCopyButton)
                  InkWell(
                    onTap: () {
                      AppHaptics.tap();
                      Clipboard.setData(ClipboardData(text: cleanExpr));
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Equation copied to clipboard'),
                          duration: Duration(seconds: 2),
                        ),
                      );
                    },
                    borderRadius: BorderRadius.circular(4),
                    child: const Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.copy, size: 14, color: AppColors.textMuted),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 6),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Math.tex(
              _sanitizeLatex(cleanExpr),
              mathStyle: MathStyle.display,
              textStyle: defaultStyle,
              onErrorFallback: (err) => Text(
                ChemistryTextFormatter.toUnicodeMath(cleanExpr),
                style: defaultStyle.copyWith(
                  color: AppColors.purpleBright,
                  fontFamily: 'monospace',
                  fontSize: (defaultStyle.fontSize ?? 15.5) * 0.95,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (selectable) {
      return SelectionArea(child: content);
    }
    return content;
  }

  static String _stripDelimiters(String input) {
    var s = input.trim();
    if (s.startsWith(r'$$') && s.endsWith(r'$$') && s.length >= 4) {
      s = s.substring(2, s.length - 2).trim();
    } else if (s.startsWith(r'\[') && s.endsWith(r'\]') && s.length >= 4) {
      s = s.substring(2, s.length - 2).trim();
    } else if (s.startsWith(r'$') && s.endsWith(r'$') && s.length >= 2) {
      s = s.substring(1, s.length - 1).trim();
    }
    return s;
  }

  static String _sanitizeLatex(String input) {
    var s = input.trim();
    s = s.replaceAll(r'\rightleftharpoons', r'\rightleftharpoons');
    s = s.replaceAll(r'\xrightarrow', r'\to');
    s = s.replaceAll(r'->', r'\to');
    s = s.replaceAll(r'⇌', r'\rightleftharpoons');
    s = s.replaceAll(r'→', r'\to');
    s = s.replaceAll(r'\degree', r'^\circ');
    s = s.replaceAll(r'^\circ C', r'^\circ\text{C}');
    s = s.replaceAll(r'^\circC', r'^\circ\text{C}');
    // Fix naked superscripts like ^- -> ^{-} or ^+ -> ^{+}
    s = s.replaceAllMapped(RegExp(r'\^([-+])(?![{a-zA-Z0-9])'), (m) => '^{${m[1]}}');
    return s;
  }
}
