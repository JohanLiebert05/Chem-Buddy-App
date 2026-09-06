import '../models/pdf_ocr_models.dart';
import 'pdf_text_utils.dart';

Future<String> extractFromPath(String path, {void Function(String progress)? onProgress}) async {
  throw PdfExtractionException('PDF text extraction is available in the Android app.');
}

Future<DocumentOcrBundle> extractBundleFromPath(
  String path, {
  String docId = '',
  String docTitle = '',
  bool forceReprocess = false,
  void Function(String status, double progress)? onProgress,
}) async {
  throw PdfExtractionException('PDF text extraction is available in the Android app.');
}
