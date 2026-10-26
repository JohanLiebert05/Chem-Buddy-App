import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/export_service.dart';
import 'package:chem_buddy/data/services/reaction_mechanism_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  test('reaction PDF embeds the actual diagram image', () async {
    final requested = Platform.environment['EXPORT_QA_DIR'];
    final dir = requested == null
        ? await Directory.systemTemp.createTemp('reaction_export_')
        : await Directory(requested).create(recursive: true);
    try {
      final mechanism = ReactionMechanismService.instance.mechanisms.firstWhere((m) => m.id == 'sn1');
      final file = await ExportService.instance.generateReactionPdf(singleReaction: mechanism, outputDirectory: dir);
      final raw = String.fromCharCodes(await file.readAsBytes());
      expect(RegExp(r'/Subtype\s*/Image').hasMatch(raw), isTrue,
        reason: 'A valid PDF header alone does not establish that the reaction diagram was embedded.');
      if (requested != null) {
        await ExportService.instance.generateReactionPdf(
          reactions: ReactionMechanismService.instance.mechanisms, outputDirectory: dir);
      }
    } finally {
      if (requested == null) await dir.delete(recursive: true);
    }
  });
}
