import 'dart:io';
import 'dart:ui' as ui;

import 'package:chem_buddy/presentation/widgets/spectroscopy_solver_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> mount(
    WidgetTester tester, {
    Size size = const Size(390, 844),
    bool dark = false,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    if (const bool.fromEnvironment('SPECTROSCOPY_PREVIEW')) {
      await tester.runAsync(() async {
        for (final font in [
          ('ReviewSans', 'C:/Windows/Fonts/segoeui.ttf'),
          ('sans-serif', 'C:/Windows/Fonts/segoeui.ttf'),
          ('monospace', 'C:/Windows/Fonts/consola.ttf'),
          (
            'MaterialIcons',
            'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
          ),
        ]) {
          final fontFile = File(font.$2);
          if (await fontFile.exists()) {
            final loader = FontLoader(font.$1)
              ..addFont(fontFile.readAsBytes().then(ByteData.sublistView));
            await loader.load();
          }
        }
      });
    }
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeData(
          fontFamily: const bool.fromEnvironment('SPECTROSCOPY_PREVIEW')
              ? 'ReviewSans'
              : null,
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xff087f8c),
            brightness: dark ? Brightness.dark : Brightness.light,
          ),
        ),
        home: const RepaintBoundary(
          key: ValueKey('workspace-preview'),
          child: Scaffold(body: SpectroscopySolverWorkspace()),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('SPECTROSCOPY_PREVIEW')) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('workspace-preview')),
      );
      final image = await boundary.toImage(pixelRatio: 2);
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      final directory = Directory('build/spectroscopy-review')
        ..createSync(recursive: true);
      File('${directory.path}/$name.png')
          .writeAsBytesSync(bytes!.buffer.asUint8List());
      image.dispose();
    });
  }

  testWidgets(
    'mobile solver shows SVG spectra and reveals a matched structure',
    (tester) async {
      await mount(tester);
      await capture(tester, 'mobile-inputs');
      final spectrum = find.byKey(const ValueKey('solver-spectrum-svg'));
      await tester.ensureVisible(spectrum);
      await tester.pumpAndSettle();
      expect(spectrum, findsOneWidget);
      await capture(tester, 'mobile-spectrum');
      final deduce = find.byKey(const ValueKey('deduce-structure-button'));
      await tester.ensureVisible(deduce);
      await tester.pumpAndSettle();
      await tester.tap(deduce);
      await tester.pumpAndSettle();
      final drawing = find.byKey(const ValueKey('deduced-structure-svg'));
      await tester.ensureVisible(drawing);
      await tester.pumpAndSettle();
      expect(drawing, findsOneWidget);
      expect(find.textContaining('SMILES: CC(=O)c1ccccc1'), findsOneWidget);
      await capture(tester, 'mobile-structure');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'dark desktop workspace and reference explorer remain distinct from deduction',
    (tester) async {
      await mount(tester, size: const Size(1200, 1100), dark: true);
      await tester.tap(find.text('Explore a compound'));
      await tester.pumpAndSettle();
      final search = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Compound name or formula',
      );
      await tester.enterText(search, 'Ethanol');
      await tester.pumpAndSettle();
      await tester.tap(find.text('Ethanol').last);
      await tester.pumpAndSettle();
      expect(find.text('Reference preview'), findsOneWidget);
      expect(find.text('Tentative match'), findsNothing);
      await tester.ensureVisible(
        find.byKey(const ValueKey('solver-spectrum-svg')),
      );
      await tester.pumpAndSettle();
      await capture(tester, 'desktop-reference');
      await tester.ensureVisible(
        find.byKey(const ValueKey('deduce-structure-button')),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('deduce-structure-button')));
      await tester.pumpAndSettle();
      expect(find.text('Selected reference structure'), findsOneWidget);
      expect(
        find.byKey(const ValueKey('deduced-structure-svg')),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('conflicting NMR cannot produce an exact structure SVG', (
    tester,
  ) async {
    await mount(tester, size: const Size(900, 1100));
    final proton = find.byWidgetPredicate(
      (w) =>
          w is TextField &&
          w.decoration?.labelText?.startsWith('¹H NMR Shifts') == true,
    );
    await tester.ensureVisible(proton);
    await tester.pumpAndSettle();
    await tester.enterText(proton, '3.8, 7.45, 7.55, 7.95');
    await tester.ensureVisible(find.text('Analyze spectra'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Analyze spectra'));
    await tester.pumpAndSettle();
    await tester.ensureVisible(
      find.byKey(const ValueKey('deduce-structure-button')),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('deduce-structure-button')));
    await tester.pumpAndSettle();
    expect(
      find.byKey(const ValueKey('structure-needs-evidence')),
      findsOneWidget,
    );
    expect(find.byKey(const ValueKey('deduced-structure-svg')), findsNothing);
    expect(tester.takeException(), isNull);
  });

  testWidgets(
    'switching compound references updates NMR and structural drawings',
    (tester) async {
      await mount(tester, size: const Size(1000, 900));
      await tester.tap(find.text('Explore a compound'));
      await tester.pumpAndSettle();
      final search = find.byWidgetPredicate(
        (w) =>
            w is TextField &&
            w.decoration?.labelText == 'Compound name or formula',
      );
      for (final name in ['Vanillin', 'Benzophenone']) {
        await tester.ensureVisible(search);
        await tester.pumpAndSettle();
        await tester.enterText(search, name);
        await tester.pumpAndSettle();
        await tester.tap(find.text(name).last);
        await tester.pumpAndSettle();
        final deduce = find.byKey(const ValueKey('deduce-structure-button'));
        await tester.ensureVisible(deduce);
        await tester.pumpAndSettle();
        await tester.tap(deduce);
        await tester.pumpAndSettle();
        final drawing = find.byKey(const ValueKey('deduced-structure-svg'));
        expect(drawing, findsOneWidget);
        await tester.ensureVisible(drawing);
        await tester.pumpAndSettle();
        await capture(tester, 'structure-${name.toLowerCase()}');
        expect(tester.takeException(), isNull);
      }
    },
  );
}
