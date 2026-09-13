import '../models/pdf_ocr_models.dart';

class PdfExtractionException implements Exception {
  PdfExtractionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Splits notes so Gemini never receives a huge payload in one request.
/// Kept for backward compatibility — prefer [chunkBySentences] for RAG ingestion.
List<String> chunkNotes(String raw, {int size = 8000, int overlap = 200}) {
  final text = raw.replaceAll(RegExp(r'\s+'), ' ').trim();
  if (text.isEmpty) return const [];
  if (text.length <= size) return [text];
  final chunks = <String>[];
  var i = 0;
  while (i < text.length && chunks.length < 4) {
    final end = (i + size).clamp(0, text.length);
    chunks.add(text.substring(i, end));
    if (end >= text.length) break;
    i = end - overlap;
    if (i < 0) i = 0;
  }
  return chunks;
}

/// Semantic sentence/paragraph-boundary-aware chunker.
///
/// Splits text at sentence boundaries (`. `, `? `, `! `) or paragraph
/// boundaries (`\n\n`), ensuring each chunk stays within [maxChars].
/// Adjacent chunks share an [overlapChars] tail of the previous chunk so
/// cross-boundary context is preserved.
///
/// Use this for RAG ingestion to avoid splitting mid-sentence.
List<String> chunkBySentences(
  String raw, {
  int maxChars = 1200,
  int overlapChars = 120,
}) {
  final text = raw.replaceAll(RegExp(r'[ \t]+'), ' ').trim();
  if (text.isEmpty) return const [];
  if (text.length <= maxChars) return [text];

  // Split into candidate sentence units at `. `, `? `, `! `, or blank lines
  final sentencePattern = RegExp(r'(?<=[.?!])\s+|(?<=\n)\n+');
  final sentences = text
      .split(sentencePattern)
      .where((s) => s.trim().isNotEmpty)
      .toList();

  final chunks = <String>[];
  final buffer = StringBuffer();

  for (final sentence in sentences) {
    final candidate =
        buffer.isEmpty ? sentence : '${buffer.toString()} $sentence';

    if (candidate.length > maxChars && buffer.isNotEmpty) {
      // Flush current buffer as a chunk
      final flushed = buffer.toString().trim();
      chunks.add(flushed);

      // Start next buffer with an overlap tail from the previous chunk
      buffer.clear();
      if (flushed.length > overlapChars) {
        buffer.write(flushed.substring(flushed.length - overlapChars).trim());
        buffer.write(' ');
      }
      buffer.write(sentence);
    } else {
      if (buffer.isNotEmpty) buffer.write(' ');
      buffer.write(sentence);
    }
  }

  if (buffer.isNotEmpty) {
    final remaining = buffer.toString().trim();
    if (remaining.length > 10) chunks.add(remaining);
  }

  return chunks.where((c) => c.length > 10).toList();
}

/// Layout-aware cleaner that filters running headers, footers, diagram captions,
/// broken hyphenations, and non-chemistry OCR noise.
String sanitizeLayoutAndNoise(String raw, {bool filterDiagramCaptions = false}) {
  if (raw.trim().isEmpty) return '';

  var text = raw
      .replaceAll('\u0000', ' ')
      .replaceAll('\r\n', '\n')
      .replaceAll('\r', '\n');

  // 1. Repair hyphenated words split across line breaks (e.g. "reac-\ntion" -> "reaction")
  text = text.replaceAllMapped(
    RegExp(r'([a-zA-Z]{3,})-\s*\n\s*([a-zA-Z]{3,})'),
    (m) => '${m.group(1)}${m.group(2)}',
  );

  final lines = text.split('\n');
  final cleanedLines = <String>[];

  // Regex patterns for headers, footers, and noise
  final pageNumberPattern = RegExp(r'^\s*(?:Page\s+)?(?:-\s*)?\d+(?:\s*(?:of|/|-)\s*\d+)?\s*$', caseSensitive: false);
  final headerPattern = RegExp(
    r'^\s*(?:Chapter|Section|Unit|Module)\s+\d+[:\s].*$',
    caseSensitive: false,
  );
  final publisherPattern = RegExp(
    r'(?:©|copyright|all rights reserved|john wiley|springer|elsevier|oxford university press|cambridge university press|department of chemistry|pearson education|mcgraw-hill)',
    caseSensitive: false,
  );
  final captionPattern = RegExp(
    r'^\s*(?:Fig(?:ure)?|Scheme|Chart|Plate|Table)\s*[\d\.\-]+[:\.\s].*$',
    caseSensitive: false,
  );
  final ocrNoiseSymbolPattern = RegExp(r'^[~_.,\-^|/\\*+=<>:;#@!?()[\]{}]+$');

  for (final line in lines) {
    final trimmed = line.trim();
    if (trimmed.isEmpty) {
      if (cleanedLines.isNotEmpty && cleanedLines.last.isNotEmpty) {
        cleanedLines.add('');
      }
      continue;
    }

    // Filter lone page numbers (e.g. "14", "Page 14", "14 of 52", "- 14 -")
    if (pageNumberPattern.hasMatch(trimmed) && trimmed.length < 25) {
      continue;
    }

    // Filter short repeating running chapter headers (e.g. "Chapter 4: Pericyclic Reactions")
    if (headerPattern.hasMatch(trimmed) && trimmed.length < 50) {
      continue;
    }

    // Filter publisher / copyright lines
    if (publisherPattern.hasMatch(trimmed) && trimmed.length < 80) {
      continue;
    }

    // Optionally filter or clean diagram captions
    if (filterDiagramCaptions && captionPattern.hasMatch(trimmed)) {
      continue;
    }

    // Filter isolated OCR noise characters/symbols (e.g. "---", "___", "|", "~")
    if (trimmed.length < 5 && ocrNoiseSymbolPattern.hasMatch(trimmed)) {
      continue;
    }

    // Filter lines where >65% characters are non-alphanumeric and no chemical formula exists
    final lettersAndDigits = RegExp(r'[a-zA-Z0-9]').allMatches(trimmed).length;
    final totalLen = trimmed.length;
    if (totalLen > 6 && (lettersAndDigits / totalLen) < 0.35 && !trimmed.contains('->') && !trimmed.contains('=')) {
      continue;
    }

    cleanedLines.add(line);
  }

  return cleanedLines.join('\n')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

String cleanupExtractedText(String raw) {
  return sanitizeLayoutAndNoise(raw);
}

typedef DocumentQuality = PageQuality;

bool looksLikeScannedPdf(String text) {
  final letters = RegExp(r'[A-Za-z]').allMatches(text).length;
  return letters < 40;
}

PageQuality assessDocumentQuality(String text, {int pagesCount = 1}) {
  final clean = text.trim();
  final letters = RegExp(r'[A-Za-z]').allMatches(clean).length;
  final avgLettersPerPage = pagesCount > 0 ? letters / pagesCount : letters;

  if (letters < 40 || avgLettersPerPage < 60) {
    return PageQuality.scannedImage;
  } else if (avgLettersPerPage > 200) {
    return PageQuality.digitalText;
  }
  return PageQuality.mixed;
}
