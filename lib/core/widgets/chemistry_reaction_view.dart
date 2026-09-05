import 'package:flutter/material.dart';

import '../theme/app_colors.dart';
import '../utils/chemistry_text_formatter.dart';

/// Reusable widget for presenting chemical reaction equations and multi-step mechanisms.
///
/// Formats reactants, arrows (equilibrium ⇌, irreversible →, condition-bearing ─[reagent]→),
/// intermediate complexes, and products with textbook-grade chemical typography.
class ChemistryReactionView extends StatelessWidget {
  const ChemistryReactionView({
    super.key,
    required this.reaction,
    this.title,
    this.notes,
    this.stepNumber,
    this.selectable = true,
  });

  final String reaction;
  final String? title;
  final String? notes;
  final int? stepNumber;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final cleanReaction = _formatReaction(reaction);

    final card = Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 6),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surfaceElevated.withValues(alpha: 0.65),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.brandPrimary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null && title!.isNotEmpty) ...[
            Row(
              children: [
                if (stepNumber != null) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: AppColors.brandPrimary.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      'Step $stepNumber',
                      style: const TextStyle(
                        color: AppColors.brandBright,
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
                Expanded(
                  child: Text(
                    title!,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  cleanReaction,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14.5,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.3,
                  ),
                ),
              ],
            ),
          ),
          if (notes != null && notes!.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              notes!,
              style: const TextStyle(
                color: AppColors.textSecondary,
                fontSize: 12,
                fontStyle: FontStyle.italic,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );

    if (selectable) {
      return SelectionArea(child: card);
    }
    return card;
  }

  static String _formatReaction(String input) {
    var s = input.trim();
    // Strip external LaTeX wrappers if provided
    if (s.startsWith(r'$$') && s.endsWith(r'$$')) s = s.substring(2, s.length - 2).trim();
    if (s.startsWith(r'$') && s.endsWith(r'$')) s = s.substring(1, s.length - 1).trim();

    // Remove \text{...} or \mathrm{...}
    s = s.replaceAllMapped(RegExp(r'\\(?:text|mathrm|mathbf)\{([^}]*)\}'), (m) => m[1] ?? '');

    // Replace LaTeX arrows with clean Unicode
    s = s.replaceAll(r'\rightleftharpoons', ' ⇌ ');
    s = s.replaceAll(r'\rightarrow', ' → ');
    s = s.replaceAll(r'\to', ' → ');
    s = s.replaceAll(r'-->', ' → ');
    s = s.replaceAll(r'->', ' → ');
    s = s.replaceAll(r'<=>', ' ⇌ ');
    s = s.replaceAll(r'<->', ' ⇌ ');

    // Normalize condition arrows \xrightarrow[below]{above}
    s = s.replaceAllMapped(RegExp(r'\\xrightarrow(?:\[([^\]]*)\])?\{([^}]*)\}'), (m) {
      final above = m[2]?.trim() ?? '';
      final below = m[1]?.trim() ?? '';
      if (above.isNotEmpty && below.isNotEmpty) {
        return ' ─[$above / $below]→ ';
      } else if (above.isNotEmpty) {
        return ' ─[$above]→ ';
      }
      return ' → ';
    });

    // Convert formulas & charges using universal formatter
    return ChemistryTextFormatter.format(s);
  }
}
