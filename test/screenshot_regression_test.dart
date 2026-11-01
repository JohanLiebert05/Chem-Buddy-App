import 'dart:io';
import 'dart:ui' as ui;

import 'package:chem_buddy/core/theme/appearance.dart';
import 'package:chem_buddy/presentation/providers/appearance_provider.dart';
import 'package:chem_buddy/presentation/screens/spectroscopy_hub_screen.dart';
import 'package:chem_buddy/presentation/widgets/profile_appearance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> previewFonts(WidgetTester tester) async {
  if (!const bool.fromEnvironment('SPECTROSCOPY_PREVIEW')) return;
  await tester.runAsync(() async {
    for (final entry in [
      ('ReviewSans', 'C:/Windows/Fonts/segoeui.ttf'),
      (
        'MaterialIcons',
        'build/unit_test_assets/fonts/MaterialIcons-Regular.otf',
      ),
    ]) {
      final file = File(entry.$2);
      if (await file.exists()) {
        await (FontLoader(
          entry.$1,
        )..addFont(file.readAsBytes().then(ByteData.sublistView))).load();
      }
    }
  });
}

Future<void> screenshot(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('SPECTROSCOPY_PREVIEW')) return;
  await tester.runAsync(() async {
    final boundary = tester.renderObject<RenderRepaintBoundary>(
      find.byKey(const ValueKey('screenshot-review')),
    );
    final image = await boundary.toImage(pixelRatio: 2);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    Directory('build/spectroscopy-review').createSync(recursive: true);
    File('build/spectroscopy-review/$name.png')
        .writeAsBytesSync(bytes!.buffer.asUint8List());
    image.dispose();
  });
}

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Signals cards remain readable in ${brightness.name} mode on narrow screens',
      (tester) async {
        await previewFonts(tester);
        await tester.binding.setSurfaceSize(const Size(360, 1000));
        addTearDown(() => tester.binding.setSurfaceSize(null));
        final colors = ColorScheme.fromSeed(
          seedColor: const Color(0xffb70046),
          brightness: brightness,
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context)
                    .copyWith(textScaler: const TextScaler.linear(1.2)),
                child: child!,
              ),
              theme: ThemeData(
                colorScheme: colors,
                fontFamily: const bool.fromEnvironment('SPECTROSCOPY_PREVIEW')
                    ? 'ReviewSans'
                    : null,
              ),
              home: const RepaintBoundary(
                key: ValueKey('screenshot-review'),
                child: SpectroscopyHubScreen(),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        final destination = find.byKey(
          const ValueKey('Chromatograms & Spectrograms'),
        );
        await tester.ensureVisible(destination);
        await tester.tap(destination);
        await tester.pumpAndSettle();
        final banner = tester.widget<Container>(
          find.byKey(const ValueKey('spectroscopy-instrument-banner')),
        );
        expect(
          ((banner.decoration as BoxDecoration).gradient as LinearGradient)
              .colors
              .last,
          colors.surfaceContainerHigh,
        );
        final card = find.byKey(const ValueKey('spectroscopy-signals-card'));
        await tester.scrollUntilVisible(card, 400,
            scrollable: find.byType(Scrollable).last);
        await tester.pumpAndSettle();
        final background =
            (tester.widget<Container>(card).decoration as BoxDecoration).color!;
        final values = [
          background.computeLuminance(),
          colors.onSurface.computeLuminance(),
        ]..sort();
        expect((values.last + .05) / (values.first + .05), greaterThan(4.5));
        await tester.ensureVisible(card);
        await tester.pumpAndSettle();
        await screenshot(tester, 'signals-${brightness.name}-chart-fixed');
        expect(tester.takeException(), isNull);
      },
    );
  }
  testWidgets(
    'Your look uses vertical choices and preserves palette, mode and Undo',
    (tester) async {
      await previewFonts(tester);
      await tester.binding.setSurfaceSize(const Size(360, 1000));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      SharedPreferences.setMockInitialValues({});
      final storage = await SharedPreferences.getInstance();
      final container = ProviderContainer(
        overrides: [appearanceStorageProvider.overrideWithValue(storage)],
      );
      addTearDown(container.dispose);
      await tester.pumpWidget(
        UncontrolledProviderScope(
          container: container,
          child: MaterialApp(
            theme: ThemeData(
              fontFamily: const bool.fromEnvironment('SPECTROSCOPY_PREVIEW')
                  ? 'ReviewSans'
                  : null,
            ),
            home: const Scaffold(
              body: SingleChildScrollView(
                child: RepaintBoundary(
                  key: ValueKey('screenshot-review'),
                  child: ProfileAppearanceCard(),
                ),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      await screenshot(tester, 'profile-your-look-clean');
      await tester.tap(find.text('Display mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Light'));
      await tester.pumpAndSettle();
      expect(container.read(appearanceProvider).mode, ThemeMode.light);
      await tester.tap(find.text('Display mode'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Colour collection'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Gradients'));
      await tester.tap(find.text('Gradients'));
      await tester.pumpAndSettle();
      final first = find.byKey(
            ValueKey(ThemePalette.gradientCollection[0].name),
          ),
          second = find.byKey(
            ValueKey(ThemePalette.gradientCollection[1].name),
          );
      expect(tester.getRect(first).left, tester.getRect(second).left);
      expect(
        tester.getRect(second).top,
        greaterThan(tester.getRect(first).bottom),
      );
      await tester.ensureVisible(first);
      await tester.tap(first);
      await tester.pumpAndSettle();
      expect(
        container.read(appearanceProvider).seed,
        ThemePalette.gradientCollection.first.seed,
      );
      await screenshot(tester, 'profile-your-look-vertical-palettes');
      await tester.ensureVisible(find.text('Undo'));
      await tester.tap(find.text('Undo'));
      await tester.pumpAndSettle();
      expect(
        container.read(appearanceProvider).seed,
        isNot(ThemePalette.gradientCollection.first.seed),
      );
      expect(tester.takeException(), isNull);
    },
  );
}
