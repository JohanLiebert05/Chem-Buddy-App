import '../models/library_models.dart';

import 'pdf_library_io.dart' if (dart.library.html) 'pdf_library_stub.dart' as impl;

class PdfLibraryService {
  PdfLibraryService._();
  static final instance = PdfLibraryService._();

  Future<PdfDoc?> importPdf({required String subjectId}) => impl.importPdf(subjectId: subjectId);

  Future<void> deleteFile(String path) => impl.deleteFile(path);

  bool exists(String path) => impl.exists(path);
}
