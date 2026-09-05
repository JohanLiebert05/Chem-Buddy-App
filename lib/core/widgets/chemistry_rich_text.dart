import 'package:flutter/material.dart';
import 'package:flutter_math_fork/flutter_math.dart';

import '../theme/app_colors.dart';
import '../utils/chemistry_text_formatter.dart';

/// Reusable inline chemistry text widget that renders mixed narrative,
/// chemical formulas (subscripts, superscripts, charges, Greek symbols),
/// and inline LaTeX ($...$ or \(...\)) without raw syntax bleed-through.
class ChemistryRichText extends StatelessWidget {
  const ChemistryRichText({
    super.key,
    required this.text,
    this.textStyle,
    this.selectable = true,
    this.maxLines,
    this.overflow,
  });

  final String text;
  final TextStyle? textStyle;
  final bool selectable;
  final int? maxLines;
  final TextOverflow? overflow;

  @override
  Widget build(BuildContext context) {
    if (text.trim().isEmpty) return const SizedBox.shrink();

    final defaultStyle = textStyle ??
        const TextStyle(
          color: AppColors.textPrimary,
          fontSize: 14.5,
          height: 1.45,
        );

    // Split text into inline math segments ($...$ or \(...\)) and plain text
    final segments = _parseSegments(text);

    final spans = <InlineSpan>[];
    for (final seg in segments) {
      if (seg.isMath) {
        spans.add(
          WidgetSpan(
            alignment: PlaceholderAlignment.middle,
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              physics: const BouncingScrollPhysics(),
              child: Math.tex(
                _cleanLatex(seg.content),
                mathStyle: MathStyle.text,
                textStyle: defaultStyle.copyWith(color: Colors.white),
                onErrorFallback: (err) => Text(
                  ChemistryTextFormatter.toUnicodeMath(seg.content),
                  style: defaultStyle.copyWith(
                    color: AppColors.purpleBright,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        );
      } else {
        // Plain text: format with chemistry subscripts/charges
        final formattedText = ChemistryTextFormatter.format(seg.content);
        spans.add(
          TextSpan(
            text: formattedText,
            style: defaultStyle,
          ),
        );
      }
    }

    final textWidget = Text.rich(
      TextSpan(children: spans),
      maxLines: maxLines,
      overflow: overflow ?? (maxLines != null ? TextOverflow.ellipsis : TextOverflow.clip),
    );

    if (selectable) {
      return SelectionArea(child: textWidget);
    }
    return textWidget;
  }

  static String _cleanLatex(String raw) {
    var s = raw.trim();
    // Normalize common chemistry arrows and symbols
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

  static List<_TextSegment> _parseSegments(String raw) {
    final segments = <_TextSegment>[];
    // Match $...$ (inline) or \(...\)
    final pattern = RegExp(r'\$([^\$\n]+?)\$|\\\(([^\)]+?)\\\)');
    var lastEnd = 0;

    for (final match in pattern.allMatches(raw)) {
      if (match.start > lastEnd) {
        final plain = raw.substring(lastEnd, match.start);
        if (plain.isNotEmpty) {
          segments.add(_TextSegment(content: plain, isMath: false));
        }
      }
      final math = match.group(1) ?? match.group(2) ?? '';
      if (math.isNotEmpty) {
        segments.add(_TextSegment(content: math, isMath: true));
      }
      lastEnd = match.end;
    }

    if (lastEnd < raw.length) {
      final trailing = raw.substring(lastEnd);
      if (trailing.isNotEmpty) {
        segments.add(_TextSegment(content: trailing, isMath: false));
      }
    }

    return segments;
  }
}

class _TextSegment {
  const _TextSegment({required this.content, required this.isMath});
  final String content;
  final bool isMath;
}
