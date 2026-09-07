import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

import '../theme/app_colors.dart';
import '../utils/chemistry_text_formatter.dart';
import 'chemistry_equation.dart';
import 'chemistry_reaction_view.dart';


/// Reusable widget for rendering MSc Chemistry notes, AI answers,
/// flashcard questions, and quiz options with native LaTeX math & chemical notation.
///
/// Fully supports simultaneous Markdown (headings, bold, lists, tables) AND
/// LaTeX formulas (inline $...$ and display $$...$$) without raw syntax bleed-through.
class ChemistryMarkdownView extends StatelessWidget {
  const ChemistryMarkdownView({
    super.key,
    required this.text,
    this.textStyle,
    this.selectable = true,
    this.isDisplayMath = false,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? textStyle;
  final bool selectable;
  final bool isDisplayMath;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    // 1. Sanitize chemistry & auto-wrap naked LaTeX expressions
    final sanitized = _preprocessText(text.trim());

    // 2. Check if display math blocks ($$...$$ or \[...\]) exist
    final hasDisplayMath = sanitized.contains(r'$$') || sanitized.contains(r'\[');
    final hasTable = RegExp(r'^\|.+\|', multiLine: true).hasMatch(sanitized);

    if (!hasDisplayMath) {
      // Direct unified markdown + inline LaTeX rendering
      return _buildMarkdownBlock(context, sanitized, textStyle, selectable, hasTable);
    }

    // Split display math blocks ($$...$$) from Markdown narrative blocks
    final blocks = _splitIntoBlocks(sanitized);
    final defaultStyle = textStyle ?? const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, height: 1.45);

    final widgetList = <Widget>[];

    for (final b in blocks) {
      if (b.isDisplayMath) {
        final isReaction = b.text.contains('→') ||
            b.text.contains(r'\rightarrow') ||
            b.text.contains(r'\to') ||
            b.text.contains('->') ||
            b.text.contains('⇌') ||
            b.text.contains(r'\rightleftharpoons') ||
            b.text.contains(r'\xrightarrow') ||
            b.text.contains(r'\text{Ph}') ||
            b.text.contains('(=O)');

        if (isReaction) {
          widgetList.add(
            ChemistryReactionView(
              reaction: b.text,
              selectable: false,
            ),
          );
        } else {
          widgetList.add(
            ChemistryEquation(
              equation: b.text,
              textStyle: defaultStyle.copyWith(
                color: Colors.white,
                fontSize: (defaultStyle.fontSize ?? 14.5) * 1.1,
              ),
              selectable: false,
            ),
          );
        }
      } else {
        widgetList.add(
          _buildMarkdownBlock(context, b.text, defaultStyle, false, hasTable),
        );
      }
    }

    final column = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      mainAxisSize: MainAxisSize.min,
      children: widgetList,
    );

    if (selectable) {
      return SizedBox(
        width: double.infinity,
        child: SelectionArea(child: column),
      );
    }
    return SizedBox(
      width: double.infinity,
      child: column,
    );
  }

  static Widget _buildMarkdownBlock(
    BuildContext context,
    String content,
    TextStyle? textStyle,
    bool selectable,
    bool hasTable,
  ) {
    final markdownBody = MarkdownBody(
      data: content,
      selectable: selectable,
      fitContent: false,
      styleSheet: _buildMarkdownStyleSheet(context, textStyle),
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: [
        LatexInlineSyntax(),
      ],
      builders: {
        'latex-inline': _LatexInlineBuilder(textStyle: textStyle),
      },
    );

    if (hasTable) {
      return SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minWidth: MediaQuery.sizeOf(context).width - 64,
          ),
          child: markdownBody,
        ),
      );
    }

    return SizedBox(
      width: double.infinity,
      child: markdownBody,
    );
  }

  static String _preprocessText(String input) {
    var s = input;

    // Failsafe 0: Purge any raw placeholder strings that may exist in AI response or cache
    s = s.replaceAll(RegExp(r'___?DISPLAY_MATH[0-9₀-₉_]*___?'), '');
    s = s.replaceAll(RegExp(r'DISPLAY_MATH[0-9₀-₉_]+'), '');

    // 0. Clean corrupted \text${} or \text$ or stray $$ remnants
    s = s.replaceAll(r'\text${}', '');
    s = s.replaceAllMapped(RegExp(r'\\text\$\{([^}]*)\}'), (m) => m[1] ?? '');
    s = s.replaceAll(r'\text$', '');

    // 1. Normalize markdown headings: ensure any heading (#, ##, ###) has a leading blank line so it never bleeds into paragraphs
    s = s.replaceAllMapped(RegExp(r'([^\n])\n(#{1,6}\s+.+)'), (m) {
      return '${m[1]}\n\n${m[2]}';
    });

    // 2. Normalize \[...\] display math → $$...$$
    s = s.replaceAllMapped(RegExp(r'\\\[(.*?)\\\]', dotAll: true), (m) {
      final inner = (m[1] ?? '').trim();
      return '\n\$\$$inner\$\$\n';
    });

    // 3. Normalize \(...\) inline math → $...$
    s = s.replaceAllMapped(RegExp(r'\\\(([^\)]+?)\\\)'), (m) {
      final inner = (m[1] ?? '').trim();
      return '\$$inner\$';
    });

    // 4. Convert pseudo-LaTeX arrows with conditions like \to {slow (RDS)} or \to{fast} into clean Unicode text
    s = s.replaceAllMapped(RegExp(r'\\to\s*\{([^}]*)\}'), (m) => '→ (${m[1]}) ');
    s = s.replaceAllMapped(RegExp(r'\\xrightarrow\s*\{([^}]*)\}'), (m) => '→ (${m[1]}) ');
    s = s.replaceAllMapped(RegExp(r'\\rightleftharpoons\s*\{([^}]*)\}'), (m) => '⇌ (${m[1]}) ');

    // 5. Preserve genuine display math blocks ($$...$$) while sanitizing narrative text
    // Use collision-proof Unicode Private Use Area tokens without underscores or ASCII letters
    final displayMathPlaceholders = <String>[];
    s = s.replaceAllMapped(RegExp(r'\$\$(.*?)\$\$', dotAll: true), (m) {
      displayMathPlaceholders.add(m[0]!);
      return '\uE000${displayMathPlaceholders.length - 1}\uE001';
    });

    // In narrative text, unwrap \text{...}, \mathrm{...}, \mathbf{...} so it never renders as literal "\text{...}"
    for (var pass = 0; pass < 3; pass++) {
      s = s.replaceAllMapped(RegExp(r'\\text\{([^{}]*)\}'), (m) => m[1] ?? '');
      s = s.replaceAllMapped(RegExp(r'\\mathrm\{([^{}]*)\}'), (m) => m[1] ?? '');
      s = s.replaceAllMapped(RegExp(r'\\mathbf\{([^{}]*)\}'), (m) => m[1] ?? '');
    }

    // Convert naked LaTeX commands in narrative text to clean Unicode
    s = s.replaceAll(r'\rightleftharpoons', '⇌')
        .replaceAll(r'\rightarrow', '→')
        .replaceAll(r'\leftarrow', '←')
        .replaceAll(RegExp(r'\\to\b'), '→')
        .replaceAll(r'\times', '×')
        .replaceAll(r'\cdot', '·')
        .replaceAll(r'\pm', '±')
        .replaceAll(r'\mp', '∓')
        .replaceAll(r'\degree', '°')
        .replaceAll(r'^\circ', '°')
        .replaceAll(r'\circ', '°')
        .replaceAll(r'\Delta', 'Δ')
        .replaceAll(r'\alpha', 'α')
        .replaceAll(r'\beta', 'β')
        .replaceAll(r'\gamma', 'γ')
        .replaceAll(r'\lambda', 'λ')
        .replaceAll(r'\mu', 'μ')
        .replaceAll(r'\pi', 'π')
        .replaceAll(r'\sigma', 'σ')
        .replaceAll(r'\omega', 'ω')
        .replaceAll(r'\infty', '∞')
        .replaceAll(r'\approx', '≈')
        .replaceAll(r'\neq', '≠')
        .replaceAll(r'\leq', '≤')
        .replaceAll(r'\geq', '≥')
        .replaceAll(r'\uparrow', '↑')
        .replaceAll(r'\downarrow', '↓');

    // Clean chemistry superscripts/subscripts in narrative text:
    // e.g. ^- -> ⁻, ^+ -> ⁺, ^2+ -> ²⁺, _2 -> ₂
    s = s.replaceAllMapped(RegExp(r'\^-\b'), (m) => '⁻');
    s = s.replaceAllMapped(RegExp(r'\^([0-9]*[-+])'), (m) {
      const map = {'0':'⁰','1':'¹','2':'²','3':'³','4':'⁴','5':'⁵','6':'⁶','7':'⁷','8':'⁸','9':'⁹','+':'⁺','-':'⁻'};
      return m[1]!.split('').map((c) => map[c] ?? c).join();
    });
    s = s.replaceAllMapped(RegExp(r'(?<=[a-zA-Z\)])_([0-9]+)'), (m) {
      const map = {'0':'₀','1':'₁','2':'₂','3':'₃','4':'₄','5':'₅','6':'₆','7':'₇','8':'₈','9':'₉'};
      return m[1]!.split('').map((c) => map[c] ?? c).join();
    });

    // Remove unmatched or trailing $$ at line ends in narrative text
    s = s.replaceAll(RegExp(r'(?<!\$)\$\$(?!\$)\s*$', multiLine: true), '');
    // Clean leftover empty braces
    s = s.replaceAll('{}', '');

    // Restore preserved display math blocks
    for (var i = 0; i < displayMathPlaceholders.length; i++) {
      s = s.replaceFirst('\uE000$i\uE001', displayMathPlaceholders[i]);
    }

    // Failsafe purge: ensure no leftover placeholders, PUA tokens or DISPLAY_MATH ever escape
    s = s.replaceAll(RegExp(r'___?DISPLAY_MATH[0-9₀-₉_]*___?'), '');
    s = s.replaceAll(RegExp(r'DISPLAY_MATH[0-9₀-₉_]+'), '');
    s = s.replaceAll(RegExp(r'[\uE000\uE001]'), '');

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
    s = s.replaceAll(r'°C', r'^\circ\text{C}');
    s = s.replaceAll(r'° C', r'^\circ\text{C}');
    s = s.replaceAll(r'°', r'^\circ');
    s = s.replaceAll(r'\quad', r'\space\space');
    s = s.replaceAll(r'\qquad', r'\space\space\space\space');
    // Wrap naked superscripts/subscripts for KaTeX
    s = s.replaceAllMapped(RegExp(r'\^([-+])(?![{a-zA-Z0-9])'), (m) => '^{${m[1]}}');
    s = s.replaceAllMapped(RegExp(r'\^([0-9]+[-+])(?![{a-zA-Z0-9])'), (m) => '^{${m[1]}}');
    return s;
  }

  static List<_Block> _splitIntoBlocks(String text) {
    final blocks = <_Block>[];
    final displayPattern = RegExp(r'\$\$(.*?)\$\$|\\\[(.*?)\\\]', dotAll: true);
    var lastIndex = 0;

    for (final match in displayPattern.allMatches(text)) {
      if (match.start > lastIndex) {
        final nonMath = text.substring(lastIndex, match.start).trim();
        if (nonMath.isNotEmpty) {
          blocks.add(_Block(text: nonMath, isDisplayMath: false));
        }
      }

      final mathContent = match.group(1) ?? match.group(2) ?? '';
      if (mathContent.trim().isNotEmpty) {
        blocks.add(_Block(text: mathContent.trim(), isDisplayMath: true));
      }

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final remaining = text.substring(lastIndex).trim();
      if (remaining.isNotEmpty) {
        blocks.add(_Block(text: remaining, isDisplayMath: false));
      }
    }

    return blocks;
  }

  static MarkdownStyleSheet _buildMarkdownStyleSheet(BuildContext? context, TextStyle? overrideStyle) {
    final base = overrideStyle ?? const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, height: 1.55);
    return MarkdownStyleSheet(
      p: base,
      strong: base.copyWith(fontWeight: FontWeight.w700, color: Colors.white),
      em: base.copyWith(fontStyle: FontStyle.italic, color: AppColors.brandBright),
      h1: const TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        height: 1.25,
      ),
      h2: const TextStyle(
        color: Colors.white,
        fontSize: 17.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.3,
        height: 1.3,
      ),
      h3: const TextStyle(
        color: AppColors.brandBright,
        fontSize: 15.5,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.2,
        height: 1.35,
      ),
      h4: const TextStyle(
        color: AppColors.brandBright,
        fontSize: 14.0,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.1,
        height: 1.35,
      ),
      h5: const TextStyle(
        color: Colors.white,
        fontSize: 13.0,
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
      h6: const TextStyle(
        color: AppColors.textSecondary,
        fontSize: 12.0,
        fontWeight: FontWeight.w600,
        height: 1.35,
      ),
      h1Padding: const EdgeInsets.only(top: 14, bottom: 6),
      h2Padding: const EdgeInsets.only(top: 12, bottom: 6),
      h3Padding: const EdgeInsets.only(top: 10, bottom: 4),
      h4Padding: const EdgeInsets.only(top: 8, bottom: 4),
      pPadding: const EdgeInsets.only(bottom: 6),
      listBullet: const TextStyle(
        color: AppColors.brandBright,
        fontSize: 14,
        fontWeight: FontWeight.w700,
      ),
      listBulletPadding: const EdgeInsets.only(right: 6),
      tableHead: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.w800,
        fontSize: 12.5,
        letterSpacing: 0.1,
      ),
      tableBody: base.copyWith(fontSize: 12.5, height: 1.4),
      tableBorder: TableBorder.all(
        color: AppColors.borderHighlight,
        width: 0.8,
        borderRadius: BorderRadius.circular(6),
      ),
      tableCellsPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      tableColumnWidth: const FlexColumnWidth(),
      code: TextStyle(
        color: AppColors.brandBright,
        backgroundColor: AppColors.bg2,
        fontFamily: 'monospace',
        fontSize: (base.fontSize ?? 14) * 0.9,
        fontWeight: FontWeight.w600,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.bg0,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.borderSubtle, width: 0.8),
      ),
      blockquote: TextStyle(
        color: AppColors.textSecondary,
        fontSize: 13.5,
        fontStyle: FontStyle.italic,
        height: 1.45,
      ),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.bg2.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(10),
        border: const Border(
          left: BorderSide(color: AppColors.brandPrimary, width: 3.5),
        ),
      ),
      blockquotePadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      horizontalRuleDecoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppColors.borderSubtle,
            width: 0.8,
          ),
        ),
      ),
    );
  }
}

/// Custom InlineSyntax that catches `$math$` expressions and converts them to
/// an element with tag 'latex-inline' for `_LatexInlineBuilder`.
class LatexInlineSyntax extends md.InlineSyntax {
  LatexInlineSyntax() : super(r'(?<!\\|\$)\$([^\$\n]+?)\$(?!\$)');

  @override
  bool onMatch(md.InlineParser parser, Match match) {
    final math = match.group(1);
    if (math == null || math.trim().isEmpty) return false;
    final el = md.Element.text('latex-inline', math.trim());
    parser.addNode(el);
    return true;
  }
}

/// Custom MarkdownElementBuilder that renders LaTeX inline formulas using
/// `flutter_math_fork` with fallback to clean Unicode mathematical notation.
class _LatexInlineBuilder extends MarkdownElementBuilder {
  _LatexInlineBuilder({this.textStyle});

  final TextStyle? textStyle;

  @override
  bool isBlockElement() => false;

  @override
  Widget? visitElementAfterWithContext(
    BuildContext context,
    md.Element element,
    TextStyle? preferredStyle,
    TextStyle? parentStyle,
  ) {
    final mathCode = element.textContent;
    final style = preferredStyle ?? parentStyle ?? textStyle ?? const TextStyle(color: AppColors.textPrimary, fontSize: 14.5);
    final sanitized = ChemistryMarkdownView._sanitizeLatex(mathCode);

    return Math.tex(
      sanitized,
      mathStyle: MathStyle.text,
      textStyle: style.copyWith(color: Colors.white),
      onErrorFallback: (err) {
        // Strip raw LaTeX commands so they never appear as ugly raw text
        final cleaned = _cleanLatexFallback(mathCode);
        return Text(
          cleaned,
          style: style.copyWith(
            color: AppColors.purpleBright,
            fontWeight: FontWeight.w600,
          ),
        );
      },
    );
  }

  /// Converts a raw LaTeX string into readable plain text, stripping all command syntax.
  static String _cleanLatexFallback(String raw) {
    var s = raw.trim();
    try {
      final unicode = ChemistryTextFormatter.toUnicodeMath(s);
      if (unicode.isNotEmpty && !unicode.contains(r'\')) return unicode;
    } catch (_) {}
    s = s.replaceAllMapped(RegExp(r'\\text\{([^}]*)\}'), (m) => m[1] ?? '');
    s = s.replaceAllMapped(RegExp(r'\\mathrm\{([^}]*)\}'), (m) => m[1] ?? '');
    s = s.replaceAllMapped(RegExp(r'\\mathbf\{([^}]*)\}'), (m) => m[1] ?? '');
    s = s.replaceAllMapped(RegExp(r'\\frac\{([^}]*)\}\{([^}]*)\}'), (m) => '(${m[1]})/(${m[2]})');
    s = s.replaceAllMapped(RegExp(r'\\sqrt\{([^}]*)\}'), (m) => '√(${m[1]})');
    s = s.replaceAll(r'\rightleftharpoons', '⇌').replaceAll(r'\rightarrow', '→')
        .replaceAll(r'\leftarrow', '←').replaceAll(RegExp(r'\\to\b'), '→')
        .replaceAll(r'\times', '×').replaceAll(r'\cdot', '·').replaceAll(r'\pm', '±')
        .replaceAll(r'\uparrow', '↑').replaceAll(r'\downarrow', '↓')
        .replaceAll(r'\Delta', 'Δ').replaceAll(r'\alpha', 'α')
        .replaceAll(r'\beta', 'β').replaceAll(r'\gamma', 'γ')
        .replaceAll(r'\lambda', 'λ').replaceAll(r'\mu', 'μ')
        .replaceAll(r'\pi', 'π').replaceAll(r'\sigma', 'σ')
        .replaceAll(r'\omega', 'ω').replaceAll(r'\infty', '∞')
        .replaceAll(r'\log', 'log').replaceAll(r'\ln', 'ln')
        .replaceAll(r'\leq', '≤').replaceAll(r'\geq', '≥')
        .replaceAll(r'\neq', '≠').replaceAll(r'\approx', '≈')
        .replaceAll(r'\degree', '°').replaceAll(r'^\circ', '°').replaceAll(r'\circ', '°');
    s = s.replaceAllMapped(RegExp(r'\^-\b'), (m) => '⁻');
    s = s.replaceAllMapped(RegExp(r'\^([0-9]*[-+])'), (m) {
      const map = {'0':'⁰','1':'¹','2':'²','3':'³','4':'⁴','5':'⁵','6':'⁶','7':'⁷','8':'⁸','9':'⁹','+':'⁺','-':'⁻'};
      return m[1]!.split('').map((c) => map[c] ?? c).join();
    });
    s = s.replaceAll(RegExp(r'\\[a-zA-Z]+'), '');
    s = s.replaceAll('{', '').replaceAll('}', '');
    s = s.replaceAll(r'$', '');
    s = s.replaceAll(RegExp(r'\s{2,}'), ' ').trim();
    return s.isEmpty ? raw : s;
  }
}

class _Block {
  const _Block({required this.text, required this.isDisplayMath});
  final String text;
  final bool isDisplayMath;
}