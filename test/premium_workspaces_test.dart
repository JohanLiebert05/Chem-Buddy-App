import 'package:chem_buddy/core/widgets/study_hub_shell.dart';
import 'package:chem_buddy/core/widgets/curiosity_cabinet.dart';
import 'package:chem_buddy/core/theme/appearance.dart';
import 'package:chem_buddy/core/theme/app_theme.dart';
import 'package:chem_buddy/presentation/providers/appearance_provider.dart';
import 'package:chem_buddy/presentation/widgets/profile_appearance_card.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _WorkspaceHarness extends StatefulWidget {
  const _WorkspaceHarness();
  @override
  State<_WorkspaceHarness> createState() => _WorkspaceHarnessState();
}

class _WorkspaceHarnessState extends State<_WorkspaceHarness>
    with SingleTickerProviderStateMixin {
  late final controller = TabController(length: 2, vsync: this);
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => StudyHubShell(
    title: 'Study hub',
    headline: 'One clear next step.',
    description: 'Choose a workspace.',
    icon: Icons.science_outlined,
    controller: controller,
    destinations: const [
      HubDestination(
        'Calculate',
        'Work with a formula.',
        Icons.calculate_outlined,
      ),
      HubDestination('Explore', 'Inspect the evidence.', Icons.search_rounded),
    ],
    panes: const [
      _SavedField(),
      Center(child: Text('Evidence workspace')),
    ],
  );
}

class _SavedField extends StatefulWidget {
  const _SavedField();
  @override
  State<_SavedField> createState() => _SavedFieldState();
}

class _SavedFieldState extends State<_SavedField> {
  final controller = TextEditingController();
  @override
  void dispose() {
    controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.all(20),
    child: TextField(
      key: const Key('retained-formula'),
      controller: controller,
      decoration: const InputDecoration(labelText: 'Formula'),
    ),
  );
}

void main() {
  testWidgets(
    'A focused workspace retains input when returning to the overview',
    (tester) async {
      await tester.pumpWidget(const MaterialApp(home: _WorkspaceHarness()));
      expect(find.byType(TabBarView), findsNothing);
      await tester.enterText(find.byType(TextField), 'Calculate');
      await tester.pump();
      await tester.tap(find.byKey(const ValueKey('Calculate')));
      await tester.pumpAndSettle();
      await tester.enterText(find.byKey(const Key('retained-formula')), 'C6H6');
      await tester.tap(find.byTooltip('All workspaces'));
      await tester.pumpAndSettle();
      await tester.tap(find.byKey(const ValueKey('Calculate')));
      await tester.pumpAndSettle();
      expect(
        tester
            .widget<TextField>(find.byKey(const Key('retained-formula')))
            .controller!
            .text,
        'C6H6',
      );
      expect(tester.takeException(), isNull);
    },
  );
  test('Prism palettes retain three colours and readable Material roles in both modes', () {
    expect(ThemePalette.gradientCollection, hasLength(6));
    for (final palette in ThemePalette.gradientCollection) {
      expect(ThemePalette.gradientFor(palette.seed), hasLength(3));
      final restored = Appearance.decode(
        palette.seed.toARGB32(),
        'crystal',
        'light',
      );
      expect(ThemePalette.nameFor(restored.seed), palette.name);
      for (final brightness in Brightness.values) {
        final theme = AppTheme.fromAppearance(
          restored,
          brightness: brightness,
          useGoogleFonts: false,
        );
        expect(theme.extension<PrismTokens>()!.colors, palette.swatches);
        for (final pair in [
          (
            theme.colorScheme.primaryContainer,
            theme.colorScheme.onPrimaryContainer,
          ),
          (
            theme.colorScheme.surfaceContainerHigh,
            theme.colorScheme.onSurfaceVariant,
          ),
        ]) {
          final values = [
            pair.$1.computeLuminance(),
            pair.$2.computeLuminance(),
          ]..sort();
          expect(
            (values.last + .05) / (values.first + .05),
            greaterThanOrEqualTo(4.5),
          );
        }
      }
    }
  });
  testWidgets('Profile edits the palette inline and supports Undo', (
    tester,
  ) async {
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
          theme: AppTheme.fromAppearance(
            const Appearance(),
            useGoogleFonts: false,
          ),
          home: const Scaffold(
            body: SingleChildScrollView(child: ProfileAppearanceCard()),
          ),
        ),
      ),
    );
    final before = container.read(appearanceProvider);
    await tester.tap(find.text('Gradients'));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const ValueKey('Aurora')));
    await tester.pumpAndSettle();
    expect(
      container.read(appearanceProvider).seed,
      ThemePalette.gradientCollection.first.seed,
    );
    expect(find.byKey(const Key('profile-theme-name')), findsOneWidget);
    await tester.ensureVisible(find.text('Undo'));
    await tester.tap(find.text('Undo'));
    await tester.pumpAndSettle();
    expect(container.read(appearanceProvider).seed, before.seed);
    expect(tester.takeException(), isNull);
  });
  test('Discoveries save independently from private account data', () async {
    SharedPreferences.setMockInitialValues({});
    final storage = await SharedPreferences.getInstance();
    final container = ProviderContainer(
      overrides: [appearanceStorageProvider.overrideWithValue(storage)],
    );
    await container.read(curiosityProvider.notifier).discover('molybdenum');
    await container.read(curiosityProvider.notifier).discover('molybdenum');
    await container.read(curiosityProvider.notifier).discover('unknown');
    expect(container.read(curiosityProvider), {'molybdenum'});
    container.dispose();
    final reopened = ProviderContainer(
      overrides: [appearanceStorageProvider.overrideWithValue(storage)],
    );
    expect(reopened.read(curiosityProvider), {'molybdenum'});
    reopened.dispose();
  });
  testWidgets(
    'Seven taps reveal a discovery and reduced motion remains supported',
    (tester) async {
      SharedPreferences.setMockInitialValues({});
      final storage = await SharedPreferences.getInstance();
      await tester.pumpWidget(
        ProviderScope(
          overrides: [appearanceStorageProvider.overrideWithValue(storage)],
          child: const MaterialApp(
            home: MediaQuery(
              data: MediaQueryData(disableAnimations: true),
              child: Scaffold(body: CuriosityTrigger(child: Text('Atom mark'))),
            ),
          ),
        ),
      );
      for (var i = 0; i < 7; i++) {
        await tester.tap(find.text('Atom mark'));
      }
      await tester.pumpAndSettle();
      expect(find.text('Curious mind'), findsOneWidget);
      await tester.tap(find.text('Back to the lab'));
      await tester.pumpAndSettle();
      expect(find.text('Curious mind'), findsNothing);
      expect(
        storage.getStringList('curiosity.discoveries.v1'),
        contains('curious'),
      );
    },
  );
}
