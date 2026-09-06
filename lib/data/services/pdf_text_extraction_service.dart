import '../models/pdf_ocr_models.dart';
import 'pdf_text_extract_io.dart' if (dart.library.html) 'pdf_text_extract_stub.dart' as impl;

class PdfTextExtractionService {
  PdfTextExtractionService._();
  static final instance = PdfTextExtractionService._();

  Future<String> extractFromPath(String path, {void Function(String progress)? onProgress}) =>
      impl.extractFromPath(path, onProgress: onProgress);

  Future<DocumentOcrBundle> extractBundleFromPath(
    String path, {
    String docId = '',
    String docTitle = '',
    bool forceReprocess = false,
    void Function(String status, double progress)? onProgress,
  }) =>
      impl.extractBundleFromPath(
        path,
        docId: docId,
        docTitle: docTitle,
        forceReprocess: forceReprocess,
        onProgress: onProgress,
      );
}
