import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import 'package:uuid/uuid.dart';

import '../models/library_models.dart';

final _uuid = const Uuid();

Future<Directory> _root() async {
  final docs = await getApplicationDocumentsDirectory();
  final dir = Directory(p.join(docs.path, 'ChemBuddy', 'PDFs'));
  if (!await dir.exists()) await dir.create(recursive: true);
  return dir;
}

Future<PdfDoc?> importPdf({required String subjectId}) async {
  final result = await FilePicker.platform.pickFiles(
    type: FileType.custom,
    allowedExtensions: const ['pdf'],
    withData: false,
  );
  final file = result?.files.single;
  if (file == null || file.path == null) return null;
  if (!file.path!.toLowerCase().endsWith('.pdf')) {
    throw const FormatException('Only PDF files can be added to the library.');
  }
  final source = File(file.path!);
  if (!await source.exists()) {
    throw const FileSystemException('The selected PDF could not be found.');
  }
  final root = await _root();
  final folder = Directory(p.join(root.path, _safe(subjectId)));
  if (!await folder.exists()) await folder.create(recursive: true);
  var name = file.name;
  var dest = File(p.join(folder.path, name));
  var i = 1;
  while (await dest.exists()) {
    final stem = p.basenameWithoutExtension(file.name);
    dest = File(p.join(folder.path, '${stem}_$i.pdf'));
    name = p.basename(dest.path);
    i++;
  }
  await source.copy(dest.path);
  return PdfDoc(
    id: _uuid.v4(),
    filename: name,
    displayName: p.basenameWithoutExtension(name),
    subjectId: subjectId,
    localPath: dest.path,
    dateAdded: DateTime.now(),
    fileSize: await dest.length(),
  );
}

Future<void> deleteFile(String path) async {
  final file = File(path);
  if (await file.exists()) await file.delete();
}

bool exists(String path) => File(path).existsSync();

String _safe(String value) => value.replaceAll(RegExp(r'[^\w\-]+'), '_');
