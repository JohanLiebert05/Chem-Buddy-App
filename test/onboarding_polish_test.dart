import 'package:chem_buddy/core/theme/app_theme.dart';
import 'package:chem_buddy/core/theme/appearance.dart';
import 'package:chem_buddy/presentation/screens/beginner_tutorial_dialog.dart';
import 'package:chem_buddy/presentation/screens/onboarding_flow.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets(
      'Walkthrough stays readable and reachable with enlarged text in $brightness',
      (tester) async {
        tester.view.physicalSize = const Size(320, 740);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final theme = AppTheme.fromAppearance(
          Appearance(
            seed: ThemePalette.gradientCollection.first.seed,
            glass: GlassStyle.crystal,
          ),
          brightness: brightness,
          useGoogleFonts: false,
        );
        await tester.pumpWidget(
          ProviderScope(
            child: MaterialApp(
              theme: theme,
              builder: (context, child) => MediaQuery(
                data: MediaQuery.of(context).copyWith(
                  textScaler: const TextScaler.linear(1.7),
                  disableAnimations: true,
                ),
                child: child!,
              ),
              home: const Scaffold(body: BeginnerTutorialDialog()),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.widget<Text>(find.text('Welcome to ChemBuddy')).style!.color,
          theme.colorScheme.onSurface,
        );
        expect(find.text('Skip'), findsOneWidget);
        for (var step = 0; step < 6; step++) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
        }
        expect(find.text("Let's go"), findsOneWidget);
      },
    );
  }
  testWidgets('First launch explains setup, guest mode and online AI', (
    tester,
  ) async {
    await tester.pumpWidget(
      ProviderScope(
        child: MaterialApp(
          theme: AppTheme.fromAppearance(
            const Appearance(),
            brightness: Brightness.light,
            useGoogleFonts: false,
          ),
          home: const OnboardingFlow(),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(
      find.text('Your chemistry.\nA clearer way through.'),
      findsOneWidget,
    );
    expect(find.text('Get started'), findsOneWidget);
    await tester.scrollUntilVisible(find.text('Start your way'), 250);
    expect(
      find.textContaining('Choose your university and subjects'),
      findsOneWidget,
    );
    expect(
      find.textContaining('Cloud AI needs an account and internet'),
      findsOneWidget,
    );
    expect(tester.takeException(), isNull);
  });
}
