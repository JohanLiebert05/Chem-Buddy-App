import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';
import 'package:markdown/markdown.dart' as md;

import '../theme/app_colors.dart';
import '../utils/chemistry_text_formatter.dart';


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
        widgetList.add(
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: AppColors.surfaceElevated.withValues(alpha: 0.7),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: AppColors.purple.withValues(alpha: 0.25)),
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const BouncingScrollPhysics(),
                child: Math.tex(
                  _sanitizeLatex(b.text),
                  mathStyle: MathStyle.display,
                  textStyle: defaultStyle.copyWith(color: Colors.white, fontSize: (defaultStyle.fontSize ?? 14.5) * 1.1),
                  onErrorFallback: (err) => Text(
                    ChemistryTextFormatter.toUnicodeMath(b.text),
                    style: defaultStyle.copyWith(color: AppColors.purpleBright, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ),
        );
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

    // Normalize \[...\] display math → $$...$$
    s = s.replaceAllMapped(RegExp(r'\\\[(.*?)\\\]', dotAll: true), (m) {
      final inner = (m[1] ?? '').trim();
      return '\n\$\$$inner\$\$\n';
    });

    // Normalize \(...\) inline math → $...$
    s = s.replaceAllMapped(RegExp(r'\\\(([^\)]+?)\\\)'), (m) {
      final inner = (m[1] ?? '').trim();
      return '\$$inner\$';
    });

    // Wrap naked LaTeX expressions that LLM forgot to put in $...$
    // e.g. "Kw = [H3O+][OH-] = 1.0 \times 10^{-14}" or "\frac{a}{b}" outside of $
    s = s.replaceAllMapped(RegExp(r'(?<!\$|\w)(\b[A-Za-z0-9_+\-()\[\]\s=]+?\\times\s*10\^?\{?-?\d+\}?)(?!\$)'), (m) {
      final expr = m[1]?.trim() ?? '';
      return '\$$expr\$';
    });

    // Auto-balance single unclosed dollar signs in a line
    final lines = s.split('\n');
    for (var i = 0; i < lines.length; i++) {
      final line = lines[i];
      final dollarCount = RegExp(r'(?<!\\)\$').allMatches(line).length;
      if (dollarCount == 1 && (line.contains(r'\') || line.contains('=') || line.contains('^') || line.contains('_'))) {
        lines[i] = '$line\$';
      }
    }
    s = lines.join('\n');

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