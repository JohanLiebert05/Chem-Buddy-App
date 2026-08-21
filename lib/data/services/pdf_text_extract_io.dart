import 'dart:io';
import 'dart:typed_data';

import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'pdf_text_utils.dart';

Future<String> extractFromPath(String path) async {
  final file = File(path);
  if (!await file.exists()) {
    throw PdfExtractionException('The selected PDF could not be found.');
  }
  final bytes = await file.readAsBytes();
  return extractFromBytes(bytes);
}

String extractFromBytes(Uint8List bytes) {
  PdfDocument? doc;
  try {
    doc = PdfDocument(inputBytes: bytes);
    final text = cleanupExtractedText(PdfTextExtractor(doc).extractText());
    if (looksLikeScannedPdf(text)) {
      throw PdfExtractionException(
        'Unable to extract readable text from this document. This appears to be a scanned PDF.',
      );
    }
    return text;
  } on PdfExtractionException {
    rethrow;
  } catch (_) {
    throw PdfExtractionException(
      'Unable to extract readable text from this document. This appears to be a scanned PDF.',
    );
  } finally {
    doc?.dispose();
  }
}
