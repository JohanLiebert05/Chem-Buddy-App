import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chem_buddy/presentation/screens/onboarding_flow.dart';
import 'package:chem_buddy/presentation/screens/beginner_tutorial_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Minimalist LoginPage Tests', () {
    testWidgets('Renders Sign In mode by default with minimalist inputs', (
      tester,
    ) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(home: Scaffold(body: LoginPage())),
        ),
      );
      await tester.pump();

      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Welcome back.'), findsOneWidget);
      expect(find.text('Your chemistry, in one place.'), findsOneWidget);

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Full Name'), findsNothing);
      expect(find.byKey(const Key('continue-guest')), findsOneWidget);

      await tester.tap(find.text('Create Account').first);
      // The decorative logo keeps animating; wait for the form transition only.
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 800));

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('A study space that grows with you.'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });
  });

  group('Theme-aware onboarding tour', () {
    testWidgets('Moves through all seven focused tour pages', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(body: BeginnerTutorialDialog(onFinished: () {})),
          ),
        ),
      );
      await tester.pumpAndSettle();
      const titles = [
        'Welcome to ChemBuddy',
        'Draw your ideas.',
        'Ask with context.',
        'Turn notes into practice.',
        'Keep attendance in view.',
        'Explore one workspace at a time.',
        'Make it your space.',
      ];
      for (var i = 0; i < titles.length; i++) {
        expect(find.text(titles[i]), findsOneWidget);
        expect(find.byKey(const Key('tour-step')), findsOneWidget);
        if (i < titles.length - 1) {
          await tester.tap(find.text('Next'));
          await tester.pumpAndSettle();
        }
      }
      expect(find.text("Let's go"), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
