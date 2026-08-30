import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../theme/app_colors.dart';
import '../utils/chemistry_text_formatter.dart';

/// Reusable widget for rendering MSc Chemistry notes, AI answers,
/// flashcard questions, and quiz options with native LaTeX math & chemical notation.
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

    final raw = text.trim();

    // Check if the text contains LaTeX delimiters ($...$ or $$...$$ or \[...\] or \(...\))
    final hasDisplayMath = raw.contains(r'$$') || raw.contains(r'\[');
    final hasInlineMath = raw.contains(r'$') || raw.contains(r'\(') || raw.contains(r'\frac') || raw.contains(r'\xrightarrow');

    if (!hasDisplayMath && !hasInlineMath) {
      // Standard chemistry-formatted markdown
      final formatted = ChemistryTextFormatter.format(raw);
      return MarkdownBody(
        data: formatted,
        selectable: selectable,
        styleSheet: _buildMarkdownStyleSheet(context, textStyle),
      );
    }

    // Parse and render hybrid Markdown + LaTeX blocks
    return _HybridChemistryRenderer(
      content: raw,
      textStyle: textStyle,
      selectable: selectable,
    );
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

class _HybridChemistryRenderer extends StatelessWidget {
  const _HybridChemistryRenderer({
    required this.content,
    this.textStyle,
    this.selectable = true,
  });

  final String content;
  final TextStyle? textStyle;
  final bool selectable;

  @override
  Widget build(BuildContext context) {
    final defaultStyle = textStyle ?? const TextStyle(color: AppColors.textPrimary, fontSize: 14.5, height: 1.45);
    final blocks = _splitIntoBlocks(content);

    final widgetList = <Widget>[];

    for (var i = 0; i < blocks.length; i++) {
      final b = blocks[i];
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
                    ChemistryTextFormatter.format(b.text),
                    style: defaultStyle.copyWith(color: AppColors.purpleBright, fontFamily: 'monospace'),
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        // Line with potential inline math
        widgetList.add(_buildInlineMathParagraph(b.text, defaultStyle));
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

  Widget _buildInlineMathParagraph(String text, TextStyle defaultStyle) {
    if (!text.contains(r'$') && !text.contains(r'\(')) {
      // Pure markdown / chemistry text
      final formatted = ChemistryTextFormatter.format(text);
      return MarkdownBody(
        data: formatted,
        selectable: false,
        styleSheet: ChemistryMarkdownView._buildMarkdownStyleSheet(null, defaultStyle),
      );
    }

    final spans = <InlineSpan>[];
    final pattern = RegExp(r'\$([^\$\n]+?)\$|\\\(([^\)]+?)\\\)');
    var lastIndex = 0;

    for (final match in pattern.allMatches(text)) {
      if (match.start > lastIndex) {
        final prefix = text.substring(lastIndex, match.start);
        spans.add(TextSpan(text: ChemistryTextFormatter.format(prefix), style: defaultStyle));
      }

      final mathCode = match.group(1) ?? match.group(2) ?? '';
      spans.add(
        WidgetSpan(
          alignment: PlaceholderAlignment.middle,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            child: Math.tex(
              _sanitizeLatex(mathCode),
              mathStyle: MathStyle.text,
              textStyle: defaultStyle.copyWith(color: Colors.white),
              onErrorFallback: (err) => Text(
                ChemistryTextFormatter.format(mathCode),
                style: defaultStyle.copyWith(color: AppColors.purpleBright),
              ),
            ),
          ),
        ),
      );

      lastIndex = match.end;
    }

    if (lastIndex < text.length) {
      final suffix = text.substring(lastIndex);
      spans.add(TextSpan(text: ChemistryTextFormatter.format(suffix), style: defaultStyle));
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text.rich(
        TextSpan(children: spans),
        style: defaultStyle,
      ),
    );
  }

  static String _sanitizeLatex(String input) {
    var s = input.trim();
    s = s.replaceAll(r'\rightleftharpoons', r'\rightleftharpoons');
    s = s.replaceAll(r'\xrightarrow', r'\to');
    s = s.replaceAll(r'->', r'\to');
    s = s.replaceAll(r'⇌', r'\rightleftharpoons');
    s = s.replaceAll(r'→', r'\to');
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
}

class _Block {
  const _Block({required this.text, required this.isDisplayMath});
  final String text;
  final bool isDisplayMath;
}