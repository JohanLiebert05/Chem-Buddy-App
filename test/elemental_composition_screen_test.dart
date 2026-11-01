import 'dart:io';
import 'dart:ui' as ui;

import 'package:chem_buddy/presentation/screens/spectroscopy_hub_screen.dart';
import 'package:chem_buddy/presentation/widgets/elemental_composition_workspace.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> prepare(
    WidgetTester tester,
    Widget child, {
    Size size = const Size(390, 844),
    double textScale = 1,
  }) async {
    await tester.binding.setSurfaceSize(size);
    addTearDown(() => tester.binding.setSurfaceSize(null));
    if (const bool.fromEnvironment('SPECTROSCOPY_PREVIEW')) {
      await tester.runAsync(() async {
        for (final font in [
          ('ReviewSans', 'C:/Windows/Fonts/segoeui.ttf'),
          (
            'MaterialIcons',
            'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
          ),
        ]) {
          final file = File(font.$2);
          if (await file.exists()) {
            await (FontLoader(
              font.$1,
            )..addFont(file.readAsBytes().then(ByteData.sublistView))).load();
          }
        }
      });
    }
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: ThemeData(
            fontFamily: const bool.fromEnvironment('SPECTROSCOPY_PREVIEW')
                ? 'ReviewSans'
                : null,
            colorScheme: ColorScheme.fromSeed(
              seedColor: const Color(0xff087f8c),
            ),
          ),
          builder: (context, child) => MediaQuery(
            data: MediaQuery.of(context)
                .copyWith(textScaler: TextScaler.linear(textScale)),
            child: child!,
          ),
          home: RepaintBoundary(
            key: const ValueKey('composition-preview'),
            child: child,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  Future<void> capture(WidgetTester tester, String name) async {
    if (!const bool.fromEnvironment('SPECTROSCOPY_PREVIEW')) return;
    await tester.runAsync(() async {
      final boundary = tester.renderObject<RenderRepaintBoundary>(
        find.byKey(const ValueKey('composition-preview')),
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
    'composition result and missing-total errors remain clear on mobile',
    (tester) async {
      String? sent;
      await prepare(
        tester,
        Scaffold(
          body: ElementalCompositionWorkspace(
            onUseFormula: (value) => sent = value,
          ),
        ),
      );
      await tester.tap(find.widgetWithText(ActionChip, 'Ethanol'));
      await tester.pumpAndSettle();
      expect(find.byKey(const ValueKey('molecular-C2H6O')), findsOneWidget);
      final use = find.text('Use formula in Structure Solver');
      await tester.ensureVisible(find.text('02 / Formula result'));
      await tester.pumpAndSettle();
      await capture(tester, 'elemental-formula-mobile');
      await tester.ensureVisible(use);
      await tester.pumpAndSettle();
      await tester.tap(use);
      expect(sent, 'C2H6O');

      for (final e in [('C', '47'), ('H', '8'), ('O', '36')]) {
        final field = find.byWidgetPredicate(
          (w) => w is TextField && w.decoration?.labelText == '${e.$1} mass %',
        );
        await tester.ensureVisible(field);
        await tester.pumpAndSettle();
        await tester.enterText(field, e.$2);
      }
      await tester.ensureVisible(find.text('Calculate formula'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Calculate formula'));
      await tester.pumpAndSettle();
      expect(find.textContaining('9.00% is unaccounted'), findsOneWidget);
      expect(find.text('Use formula in Structure Solver'), findsNothing);
      await capture(tester, 'elemental-incomplete-mobile');
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'hub transfers the molecular formula without stale sample spectra',
    (tester) async {
      await prepare(
        tester,
        const SpectroscopyHubScreen(),
        size: const Size(1000, 1300),
      );
      await tester.enterText(find.byType(TextField).first, 'percentage');
      await tester.pumpAndSettle();
      final destination = find.byKey(const ValueKey('Elemental Analysis'));
      await tester.ensureVisible(destination);
      await tester.pumpAndSettle();
      await tester.tap(destination);
      await tester.pumpAndSettle();
      await tester.tap(find.widgetWithText(ActionChip, 'Ethanol'));
      await tester.pumpAndSettle();
      final use = find.text('Use formula in Structure Solver');
      await tester.ensureVisible(use);
      await tester.pumpAndSettle();
      await tester.tap(use);
      await tester.pumpAndSettle();
      final formula = tester.widget<TextField>(
        find.byWidgetPredicate(
          (w) =>
              w is TextField &&
              w.decoration?.labelText?.startsWith('Molecular Formula') == true,
        ),
      );
      expect(formula.controller!.text, 'C2H6O');
      for (final label in [
        '¹H NMR Shifts',
        '¹³C NMR Shifts',
        'FT-IR Peaks',
        'Mass Spec m/z',
      ]) {
        final field = tester.widget<TextField>(
          find.byWidgetPredicate(
            (w) =>
                w is TextField &&
                w.decoration?.labelText?.startsWith(label) == true,
          ),
        );
        expect(field.controller!.text, isEmpty);
      }
      expect(
        find.textContaining('Formula imported from elemental analysis'),
        findsOneWidget,
      );
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets('composition inputs tolerate narrow screens and larger type', (
    tester,
  ) async {
    await prepare(
      tester,
      Scaffold(body: ElementalCompositionWorkspace(onUseFormula: (_) {})),
      size: const Size(320, 1000),
      textScale: 1.4,
    );
    await tester.tap(find.widgetWithText(ActionChip, 'Glucose'));
    await tester.pumpAndSettle();
    expect(find.byKey(const ValueKey('molecular-C6H12O6')), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
