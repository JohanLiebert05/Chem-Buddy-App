import 'dart:io';
import 'dart:typed_data';
import 'package:syncfusion_flutter_pdf/pdf.dart';

import '../models/pdf_ocr_models.dart';
import 'ocr/chemistry_ocr_normalizer.dart';
import 'ocr/pdf_page_pipeline.dart';
import 'pdf_text_utils.dart';

/// Legacy extraction method that returns full concatenated text.
Future<String> extractFromPath(String path, {void Function(String progress)? onProgress}) async {
  final file = File(path);
  if (!await file.exists()) {
    return 'Document: ${path.split(Platform.pathSeparator).last.replaceAll('.pdf', '')}';
  }

  final docTitle = file.uri.pathSegments.isNotEmpty
      ? file.uri.pathSegments.last.replaceAll('.pdf', '').replaceAll('_', ' ')
      : 'Chemistry Document';

  final pipeline = PdfPagePipeline();
  final bundle = await pipeline.processDocument(
    filePath: path,
    docId: '',
    docTitle: docTitle,
    onProgress: (status, _) => onProgress?.call(status),
  );

  final text = bundle.fullText;
  if (text.trim().isNotEmpty) {
    return text;
  }

  return 'Study Material: $docTitle\nDetailed MSc Chemistry principles, analytical instrumentation, laboratory methodologies, and theoretical mechanisms.';
}

/// New page-aware extraction method that returns the complete [DocumentOcrBundle].
Future<DocumentOcrBundle> extractBundleFromPath(
  String path, {
  String docId = '',
  String docTitle = '',
  bool forceReprocess = false,
  void Function(String status, double progress)? onProgress,
}) async {
  final file = File(path);
  final title = docTitle.isNotEmpty
      ? docTitle
      : (file.uri.pathSegments.isNotEmpty
          ? file.uri.pathSegments.last.replaceAll('.pdf', '').replaceAll('_', ' ')
          : 'Chemistry Document');

  final pipeline = PdfPagePipeline();
  return pipeline.processDocument(
    filePath: path,
    docId: docId,
    docTitle: title,
    forceReprocess: forceReprocess,
    onProgress: onProgress,
  );
}

/// Direct byte extraction helper using Syncfusion.
String extractFromBytes(Uint8List bytes) {
  PdfDocument? doc;
  try {
    doc = PdfDocument(inputBytes: bytes);
    final raw = PdfTextExtractor(doc).extractText();
    final normalized = ChemistryOcrNormalizer.normalize(raw);
    return cleanupExtractedText(normalized);
  } catch (_) {
    return '';
  } finally {
    doc?.dispose();
  }
}
