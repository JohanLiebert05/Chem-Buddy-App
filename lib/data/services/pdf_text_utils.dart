class PdfExtractionException implements Exception {
  PdfExtractionException(this.message);
  final String message;
  @override
  String toString() => message;
}

/// Splits notes so Gemini never receives a huge payload in one request.
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

String cleanupExtractedText(String raw) {
  return raw
      .replaceAll('\u0000', ' ')
      .replaceAll(RegExp(r'[ \t]+'), ' ')
      .replaceAll(RegExp(r'\n{3,}'), '\n\n')
      .trim();
}

bool looksLikeScannedPdf(String text) {
  final letters = RegExp(r'[A-Za-z]').allMatches(text).length;
  return letters < 40;
}
