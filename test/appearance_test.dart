import 'dart:math';

import 'package:chem_buddy/core/theme/app_theme.dart';
import 'package:chem_buddy/core/theme/appearance.dart';
import 'package:chem_buddy/core/widgets/liquid_glass.dart';
import 'package:chem_buddy/presentation/providers/appearance_provider.dart';
import 'package:chem_buddy/presentation/screens/appearance_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _ThemeApp extends ConsumerWidget {
  const _ThemeApp({this.scale = 1});
  final double scale;
  @override
  Widget build(BuildContext context, WidgetRef ref) => MaterialApp(
    theme: AppTheme.fromAppearance(
      ref.watch(appearanceProvider),
      useGoogleFonts: false,
      brightness: Brightness.light,
    ),
    darkTheme: AppTheme.fromAppearance(
      ref.watch(appearanceProvider),
      useGoogleFonts: false,
      brightness: Brightness.dark,
    ),
    themeMode: ref.watch(appearanceProvider).mode,
    builder: (context, child) => MediaQuery(
      data: MediaQuery.of(context)
          .copyWith(textScaler: TextScaler.linear(scale)),
      child: child!,
    ),
    home: const AppearanceScreen(),
  );
}

double contrast(Color a, Color b) {
  final values = [a.computeLuminance(), b.computeLuminance()]..sort();
  return (values.last + .05) / (values.first + .05);
}

void main() {
  test('curated and generated palettes retain readable Material roles', () {
    var appearance = const Appearance();
    final random = Random(42);
    final samples = ThemePalette.all
        .map((p) => Appearance(seed: p.seed))
        .toList();
    for (var i = 0; i < 100; i++) {
      final next = appearance.surprise(random);
      expect(next.seed, isNot(appearance.seed));
      expect(next.glass, appearance.glass);
      samples.add(next);
      appearance = next;
    }
    for (final sample in samples) {
      for (final brightness in Brightness.values) {
        final scheme = AppTheme.schemeFor(sample.seed, brightness);
        expect(
          contrast(scheme.onSurface, scheme.surfaceContainerHigh),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(scheme.onSurfaceVariant, scheme.surfaceContainerHigh),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(scheme.onPrimary, scheme.primary),
          greaterThanOrEqualTo(4.5),
        );
        expect(
          contrast(scheme.onPrimaryContainer, scheme.primaryContainer),
          greaterThanOrEqualTo(4.5),
        );
      }
    }
  });

  test(
    'appearance survives restart and malformed preferences fall back',
    () async {
      SharedPreferences.setMockInitialValues({
        'appearance.v1': ['invalid', 'unknown'],
      });
      final storage = await SharedPreferences.getInstance();
      var container = ProviderContainer(
        overrides: [appearanceStorageProvider.overrideWithValue(storage)],
      );
      expect(container.read(appearanceProvider).glass, GlassStyle.soft);
      final choice = Appearance(
        seed: ThemePalette.all[1].seed,
        glass: GlassStyle.crystal,
        mode: ThemeMode.light,
      );
      await container.read(appearanceProvider.notifier).apply(choice);
      container.dispose();
      container = ProviderContainer(
        overrides: [appearanceStorageProvider.overrideWithValue(storage)],
      );
      expect(container.read(appearanceProvider).seed, choice.seed);
      expect(container.read(appearanceProvider).glass, GlassStyle.crystal);
      expect(container.read(appearanceProvider).mode, ThemeMode.light);
      container.dispose();
    },
  );

  test('legacy preferences preserve the existing dark appearance', () async {
    SharedPreferences.setMockInitialValues({
      'appearance.v1': [
        ThemePalette.all.first.seed.toARGB32().toString(),
        'crystal',
      ],
    });
    final storage = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [appearanceStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    expect(container.read(appearanceProvider).mode, ThemeMode.dark);
    expect(container.read(appearanceProvider).glass, GlassStyle.crystal);
  });

  testWidgets('Light, Dark and System switch actual theme brightness', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [appearanceStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    tester.platformDispatcher.platformBrightnessTestValue = Brightness.dark;
    addTearDown(tester.platformDispatcher.clearPlatformBrightnessTestValue);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _ThemeApp()),
    );
    for (final mode in [ThemeMode.light, ThemeMode.dark, ThemeMode.system]) {
      await tester.tap(find.byKey(ValueKey('mode-${mode.name}')));
      await tester.pumpAndSettle();
      expect(container.read(appearanceProvider).mode, mode);
      expect(
        Theme.of(tester.element(find.byType(AppearanceScreen))).brightness,
        mode == ThemeMode.light ? Brightness.light : Brightness.dark,
      );
    }
    final before = container.read(appearanceProvider);
    expect(before.surprise(Random(1)).mode, ThemeMode.system);
  });

  test('failed storage leaves the current theme unchanged', () async {
    final container = ProviderContainer();
    addTearDown(container.dispose);
    final before = container.read(appearanceProvider);
    await expectLater(
      container
          .read(appearanceProvider.notifier)
          .apply(before.copyWith(seed: Colors.green)),
      throwsStateError,
    );
    expect(container.read(appearanceProvider), same(before));
  });

  testWidgets('Surprise me changes the theme and Undo restores it', (
    tester,
  ) async {
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [appearanceStorageProvider.overrideWithValue(storage)],
    );
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(container: container, child: const _ThemeApp()),
    );
    final before = container.read(appearanceProvider).seed;
    await tester.ensureVisible(find.byKey(const Key('surprise-theme')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('surprise-theme')));
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider).seed, isNot(before));
    expect(find.text('Your discovery'), findsOneWidget);
    await tester.ensureVisible(find.text('Undo'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider).seed, before);
    expect(tester.takeException(), isNull);
  });

  testWidgets('small screens and enlarged text keep controls reachable', (
    tester,
  ) async {
    tester.view.physicalSize = const Size(320, 740);
    tester.view.devicePixelRatio = 1;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferences.getInstance();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [appearanceStorageProvider.overrideWithValue(storage)],
        child: const _ThemeApp(scale: 2),
      ),
    );
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
    await tester.scrollUntilVisible(find.text('Restore original look'), 450);
    await tester.pumpAndSettle();
    expect(tester.takeException(), isNull);
  });

  testWidgets('solid and high contrast remove glass blur', (tester) async {
    for (final style in GlassStyle.values) {
      for (final highContrast in [false, true]) {
        await tester.pumpWidget(
          MaterialApp(
            theme: AppTheme.fromAppearance(
              Appearance(glass: style),
              useGoogleFonts: false,
            ),
            home: MediaQuery(
              data: MediaQueryData(highContrast: highContrast),
              child: const Scaffold(
                body: LiquidGlassContainer(child: Text('Glass')),
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          find.byType(BackdropFilter),
          highContrast || style == GlassStyle.solid
              ? findsNothing
              : findsOneWidget,
        );
      }
    }
  });
}
