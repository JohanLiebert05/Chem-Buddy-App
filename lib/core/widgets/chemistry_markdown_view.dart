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
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: widgetList,
    );

    if (selectable) {
      return SelectionArea(child: column);
    }
    return column;
  }

  static Widget _buildMarkdownBlock(
    BuildContext context,
    String content,
    TextStyle? textStyle,
    bool selectable,
    bool hasTable,
  ) {
    return MarkdownBody(
      data: content,
      selectable: selectable,
      styleSheet: _buildMarkdownStyleSheet(context, textStyle),
      extensionSet: md.ExtensionSet.gitHubFlavored,
      inlineSyntaxes: [
        LatexInlineSyntax(),
      ],
      builders: {
        'latex-inline': _LatexInlineBuilder(textStyle: textStyle),
        if (hasTable) 'table': _ScrollableTableBuilder(),
      },
    );
  }

  static String _preprocessText(String input) {
    var s = input;

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

    // 4. Wrap naked multi-line or standalone equations if the whole line is an equation with LaTeX commands
    final lines = s.split('\n');
    for (var i = 0; i < lines.length; i++) {
      var line = lines[i].trim();
      final dollarCount = RegExp(r'(?<!\\)\$').allMatches(line).length;

      if (dollarCount == 0 && _containsLatexCommand(line)) {
        if (!line.startsWith('#') && !line.startsWith('>')) {
          lines[i] = '\$$line\$';
          continue;
        }
      }

      // Auto-balance single unclosed dollar signs in a line
      if (dollarCount % 2 != 0 && (line.contains(r'\') || line.contains('=') || line.contains('^') || line.contains('_'))) {
        lines[i] = '$line\$';
      }
    }
    s = lines.join('\n');

    // 5. Wrap inline naked LaTeX fragments that appear within regular text without $...$
    s = _wrapInlineNakedLatex(s);

    // 6. Wrap naked scientific notation (e.g. 1.0 \times 10^{-14}) if not enclosed in $
    s = s.replaceAllMapped(RegExp(r'(?<!\$|\w)(\b[A-Za-z0-9_+\-()\[\]\s=]+?\\times\s*10\^?\{?-?\d+\}?)(?!\$)'), (m) {
      final expr = m[1]?.trim() ?? '';
      return '\$$expr\$';
    });

    return s;
  }

  static bool _containsLatexCommand(String text) {
    if (text.isEmpty) return false;
    return text.contains(r'\frac') ||
        text.contains(r'\text') ||
        text.contains(r'\sqrt') ||
        text.contains(r'\Delta') ||
        text.contains(r'\Phi') ||
        text.contains(r'\alpha') ||
        text.contains(r'\beta') ||
        text.contains(r'\gamma') ||
        text.contains(r'\theta') ||
        text.contains(r'\lambda') ||
        text.contains(r'\mu') ||
        text.contains(r'\nu') ||
        text.contains(r'\pi') ||
        text.contains(r'\sigma') ||
        text.contains(r'\omega') ||
        text.contains(r'\Omega') ||
        text.contains(r'\Psi') ||
        text.contains(r'\psi') ||
        text.contains(r'\times') ||
        text.contains(r'\cdot') ||
        text.contains(r'\pm') ||
        text.contains(r'\mp') ||
        text.contains(r'\degree') ||
        text.contains(r'^\circ') ||
        text.contains(r'\circ') ||
        text.contains(r'\log') ||
        text.contains(r'\ln') ||
        text.contains(r'\exp') ||
        text.contains(r'\quad') ||
        text.contains(r'\qquad') ||
        text.contains(r'\rightarrow') ||
        text.contains(r'\to') ||
        text.contains(r'\rightleftharpoons') ||
        text.contains(r'\sum') ||
        text.contains(r'\int') ||
        text.contains(r'\partial') ||
        text.contains(r'\varepsilon') ||
        text.contains(r'\approx') ||
        text.contains(r'\neq') ||
        text.contains(r'\leq') ||
        text.contains(r'\geq') ||
        text.contains(r'\infty');
  }

  static String _wrapInlineNakedLatex(String input) {
    return input.replaceAllMapped(
      RegExp(r'(?<!\$|\w)(\\[a-zA-Z]+(?:\{[^{}]*\}|[a-zA-Z0-9_\^\+\-\(\)\[\]·=])+(?:[\s\-_+\/*=]+\\[a-zA-Z]+(?:\{[^{}]*\}|[a-zA-Z0-9_\^\+\-\(\)\[\]·=])*)*)(?!\$)'),
      (match) {
        final raw = match[1]?.trim() ?? '';
        if (raw.isEmpty || raw.startsWith('#')) return raw;
        return '\$$raw\$';
      },
    );
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
    final base = overrideStyle ?? const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, height: 1.45);
    return MarkdownStyleSheet(
      p: base,
      strong: base.copyWith(fontWeight: FontWeight.bold, color: Colors.white),
      em: base.copyWith(fontStyle: FontStyle.italic, color: AppColors.purpleBright),
      h1: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.3),
      h2: const TextStyle(color: Colors.white, fontSize: 17.5, fontWeight: FontWeight.w700, height: 1.3),
      h3: const TextStyle(color: AppColors.purpleBright, fontSize: 15.5, fontWeight: FontWeight.w700, height: 1.3),
      listBullet: const TextStyle(color: AppColors.purpleBright, fontSize: 14),
      tableHead: const TextStyle(color: Colors.white, fontWeight: FontWeight.w700),
      tableBorder: TableBorder.all(color: AppColors.border, width: 0.6),
      tableBody: base,
      tableColumnWidth: const FlexColumnWidth(),
      code: TextStyle(
        color: AppColors.purpleBright,
        backgroundColor: AppColors.surfaceElevated,
        fontFamily: 'monospace',
        fontSize: (base.fontSize ?? 14) * 0.92,
      ),
      codeblockDecoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      blockquoteDecoration: BoxDecoration(
        color: AppColors.surfaceElevated,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.purple.withValues(alpha: 0.3)),
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

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Math.tex(
        sanitized,
        mathStyle: MathStyle.text,
        textStyle: style.copyWith(color: Colors.white),
        onErrorFallback: (err) => Text(
          ChemistryTextFormatter.toUnicodeMath(mathCode),
          style: style.copyWith(color: AppColors.purpleBright, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}

class _Block {
  const _Block({required this.text, required this.isDisplayMath});
  final String text;
  final bool isDisplayMath;
}

/// Custom markdown builder that wraps tables in a horizontal scroll container,
/// preventing narrow-screen column collapse on devices < 420px wide.
class _ScrollableTableBuilder extends MarkdownElementBuilder {
  @override
  Widget? visitElementAfter(md.Element element, TextStyle? preferredStyle) {
    if (element.tag != 'table') return null;

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.border, width: 0.6),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Scrollbar(
        thumbVisibility: true,
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.only(bottom: 6),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minWidth: 280),
            child: const SizedBox(),
          ),
        ),
      ),
    );
  }
}