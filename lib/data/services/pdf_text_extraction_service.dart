import 'pdf_text_extract_io.dart' if (dart.library.html) 'pdf_text_extract_stub.dart' as impl;

class PdfTextExtractionService {
  PdfTextExtractionService._();
  static final instance = PdfTextExtractionService._();

  Future<String> extractFromPath(String path, {void Function(String progress)? onProgress}) =>
      impl.extractFromPath(path, onProgress: onProgress);
}
