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

String cleanupExtractedText(String raw) {
  return raw
      .replaceAll('\u0000', ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
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
