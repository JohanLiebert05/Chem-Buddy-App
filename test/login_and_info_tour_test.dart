import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:chem_buddy/presentation/screens/onboarding_flow.dart';
import 'package:chem_buddy/presentation/screens/beginner_tutorial_dialog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Minimalist LoginPage Tests', () {
    testWidgets('Renders Sign In mode by default with minimalist inputs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: LoginPage(),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Sign In'), findsWidgets);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to access your notes, attendance, and AI.'), findsOneWidget);

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Full Name'), findsNothing);

      await tester.tap(find.text('Create Account').first);
      await tester.pumpAndSettle();

      expect(find.text('Full Name'), findsOneWidget);
      expect(find.text('Join ChemBuddy with your student register number.'), findsOneWidget);
      expect(find.byType(TextField), findsNWidgets(3));
    });
  });

  group('Intelligent Info Tour (BeginnerTutorialDialog) Tests', () {
    testWidgets('Steps through all 7 intelligent stages including ChemDraw and Gemini AI', (tester) async {
      await tester.pumpWidget(
        ProviderScope(
          child: MaterialApp(
            home: Scaffold(
              body: BeginnerTutorialDialog(
                onFinished: () {},
              ),
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('STEP 1 OF 7'), findsOneWidget);
      expect(find.text('Welcome to ChemBuddy 🧪'), findsOneWidget);
      expect(find.text('ChemDraw Canvas'), findsOneWidget);
      expect(find.text('Gemini AI Tutor'), findsOneWidget);

      await tester.tap(find.text('Next →'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 2 OF 7'), findsOneWidget);
      expect(find.text('Interactive Chemical Sketcher 🎨'), findsOneWidget);
      expect(find.text('Ring Templates & Fused Systems'), findsOneWidget);
      expect(find.text('Functional Groups & Smart Snapping'), findsOneWidget);
      expect(find.text('Reaction Arrows & Predictor'), findsOneWidget);

      await tester.tap(find.text('Next →'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 3 OF 7'), findsOneWidget);
      expect(find.text('Intelligent Academic Tutor ⚡'), findsOneWidget);
      expect(find.text('✨ General AI & Internet Access'), findsOneWidget);
      expect(find.text('Step-by-Step Reaction Mechanisms'), findsOneWidget);

      await tester.tap(find.text('Next →'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 4 OF 7'), findsOneWidget);
      expect(find.text('Handwritten Notes → Flashcards 📸'), findsOneWidget);
      expect(find.text('Multi-Page Photo Scanning'), findsOneWidget);

      await tester.tap(find.text('Next →'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 5 OF 7'), findsOneWidget);
      expect(find.text('Stay Confidently Above 75% 📊'), findsOneWidget);
      expect(find.text('Live "Can Skip" Buffer'), findsOneWidget);

      await tester.tap(find.text('Next →'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 6 OF 7'), findsOneWidget);
      expect(find.text('Your Daily Command Center 📅'), findsOneWidget);
      expect(find.text('MSc Timetable Presets'), findsOneWidget);

      await tester.tap(find.text('Next →'));
      await tester.pumpAndSettle();

      expect(find.text('STEP 7 OF 7'), findsOneWidget);
      expect(find.text('The 5-Step Academic Routine 🚀'), findsOneWidget);
      expect(find.text('Start Using ChemBuddy 🚀'), findsOneWidget);
    });
  });
}
