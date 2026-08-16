import '../models/library_models.dart';

Future<PdfDoc?> importPdf({required String subjectId}) async {
  throw UnsupportedError('PDF import is available in the Android app.');
}

Future<void> deleteFile(String path) async {}

bool exists(String path) => false;
