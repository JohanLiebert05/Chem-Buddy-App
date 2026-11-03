import 'dart:ui' as ui;
import 'dart:io';

import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:chem_buddy/data/services/organic_diagrams.dart';
import 'package:chem_buddy/data/services/organic_curriculum.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  setUpAll(() async {
    if (const bool.fromEnvironment('WRITE_STUDY_REVIEW')) {
      final file = File('C:/Windows/Fonts/segoeui.ttf');
      if (file.existsSync()) {
        await (FontLoader('sans-serif')..addFont(
              Future.value(ByteData.sublistView(file.readAsBytesSync())),
            ))
            .load();
      }
    }
  });
  for (final entry in organicDiagrams.entries) {
    test('SVG ${entry.key} parses and rasterises with both theme palettes', () async {
      for (final dark in [false, true]) {
        final svg = entry.value.svg(
          ink: dark ? '#EFE8FF' : '#282237',
          accent: '#A786EF',
          surface: dark ? '#24202C' : '#F6F0FF',
        );
        expect(svg.contains('@ink'), false);
        expect(svg.contains('@accent'), false);
        expect(
          svg.contains('<marker'),
          false,
          reason: 'Native electron arrows require explicit arrowheads.',
        );
        final info = await vg.loadPicture(SvgStringLoader(svg), null);
        final recorder = ui.PictureRecorder();
        final canvas = ui.Canvas(recorder);
        canvas.drawPicture(info.picture);
        final picture = recorder.endRecording();
        final image = await picture.toImage(640, 320);
        final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
        expect(bytes!.lengthInBytes, greaterThan(500), reason: entry.key);
        if (const bool.fromEnvironment('WRITE_STUDY_REVIEW')) {
          final directory = Directory('build/study-mode-review')
            ..createSync(recursive: true);
          File(
            '${directory.path}/diagram-${entry.key}-${dark ? 'dark' : 'light'}.png',
          ).writeAsBytesSync(
            bytes.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
          );
        }
        image.dispose();
        picture.dispose();
        info.picture.dispose();
      }
    });
  }
  test(
    'every lesson has an explanatory caption, not an unlabelled placeholder',
    () {
      for (final lesson in organicLessons) {
        final diagram = organicDiagrams[lesson.diagram]!;
        expect(diagram.caption.length, greaterThan(50));
        expect(diagram.body, isNotEmpty);
      }
    },
  );
}
