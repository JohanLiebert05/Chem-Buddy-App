import 'dart:io';
import 'dart:math';
import 'dart:typed_data';

import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart' as pdfx;
import 'package:syncfusion_flutter_pdf/pdf.dart';

import 'pdf_text_utils.dart';

Future<String> extractFromPath(String path, {void Function(String progress)? onProgress}) async {
  final file = File(path);
  if (!await file.exists()) {
    throw PdfExtractionException('The selected PDF could not be found.');
  }

  onProgress?.call('Reading document structure...');
  final bytes = await file.readAsBytes();

  // 1. Try fast native text extraction first
  try {
    final text = extractFromBytes(bytes);
    if (!looksLikeScannedPdf(text) && text.trim().length > 40) {
      return text;
    }
  } catch (_) {
    // Fall back to OCR
  }

  // 2. Perform On-Device OCR for scanned or image-based PDFs
  return _extractViaOcr(path, onProgress: onProgress);
}

String extractFromBytes(Uint8List bytes) {
  PdfDocument? doc;
  try {
    doc = PdfDocument(inputBytes: bytes);
    final text = cleanupExtractedText(PdfTextExtractor(doc).extractText());
    return text;
  } catch (_) {
    return '';
  } finally {
    doc?.dispose();
  }
}

Future<String> _extractViaOcr(String path, {void Function(String progress)? onProgress}) async {
  pdfx.PdfDocument? document;
  TextRecognizer? recognizer;
  try {
    onProgress?.call('Initializing OCR engine...');
    document = await pdfx.PdfDocument.openFile(path);
    recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final tempDir = await getTemporaryDirectory();
    final buffer = StringBuffer();

    final totalPages = document.pagesCount;
    final maxPages = min(totalPages, 20); // Process up to 20 pages

    for (var i = 1; i <= maxPages; i++) {
      onProgress?.call('Scanning page $i of $maxPages (OCR)...');
      final page = await document.getPage(i);
      final pageImage = await page.render(
        width: page.width * 2,
        height: page.height * 2,
        format: pdfx.PdfPageImageFormat.jpeg,
      );
      await page.close();

      if (pageImage != null) {
        final tempFile = File('${tempDir.path}/ocr_page_${DateTime.now().millisecondsSinceEpoch}_$i.jpg');
        await tempFile.writeAsBytes(pageImage.bytes);

        try {
          final inputImage = InputImage.fromFilePath(tempFile.path);
          final recognized = await recognizer.processImage(inputImage);
          if (recognized.text.trim().isNotEmpty) {
            buffer.writeln('--- Page $i ---');
            buffer.writeln(recognized.text.trim());
            buffer.writeln();
          }
        } finally {
          if (await tempFile.exists()) {
            await tempFile.delete();
          }
        }
      }
    }

    final ocrText = cleanupExtractedText(buffer.toString());
    if (ocrText.trim().length < 20) {
      throw PdfExtractionException(
        'Unable to extract readable text from this scanned document. Please ensure the scan is sharp and clear.',
      );
    }
    return ocrText;
  } on PdfExtractionException {
    rethrow;
  } catch (e) {
    throw PdfExtractionException(
      'OCR scanning failed: ${e.toString().replaceAll("Exception:", "").trim()}',
    );
  } finally {
    await document?.close();
    await recognizer?.close();
  }
}
