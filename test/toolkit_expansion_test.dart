import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/presentation/screens/chemistry_toolkit_screen.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Widget buildToolkitApp({int initialCategory = 0}) {
    return MaterialApp(
      home: ChemistryToolkitScreen(initialCategory: initialCategory),
    );
  }

  group('Chemistry Toolkit Expansion Tests', () {
    testWidgets('Acid-Base Tab: Buffer Formulation Assistant switches modes and renders recipe', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildToolkitApp(initialCategory: 3));
      await tester.pumpAndSettle();

      // Find the "Formulation Recipe (g)" chip
      final recipeChip = find.text('Formulation Recipe (g)');
      expect(recipeChip, findsOneWidget);

      await tester.tap(recipeChip);
      await tester.pumpAndSettle();

      // Should display recipe controls
      expect(find.text('Select Standard Buffer System:'), findsOneWidget);
      expect(find.text('Calculate Formulation Recipe'), findsOneWidget);

      // Tap calculate
      final calcBtn = find.widgetWithText(ElevatedButton, 'Calculate Formulation Recipe');
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      // Verify recipe details are rendered
      expect(find.textContaining('Formulation for pH'), findsOneWidget);
      expect(find.textContaining('Weigh Sodium Acetate Trihydrate'), findsOneWidget);
      expect(find.textContaining('Pipette Glacial Acetic Acid'), findsOneWidget);
      expect(find.text('Laboratory Protocol 🧪:'), findsOneWidget);
    });

    testWidgets('Analytical Tab: HPLC Calibration Curve Plotter renders chart, regression metrics, and quantifies unknown', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildToolkitApp(initialCategory: 8));
      await tester.pumpAndSettle();

      // Verify HPLC Calibration Curve Plotter is present
      expect(find.text('HPLC Calibration Curve Plotter'), findsOneWidget);
      expect(find.textContaining('Regression Equation:'), findsOneWidget);
      expect(find.textContaining('Coefficient of Determination (R²):'), findsOneWidget);
      expect(find.textContaining('Limit of Detection (LOD'), findsOneWidget);
      expect(find.textContaining('Limit of Quantitation (LOQ'), findsOneWidget);

      // Verify Unknown sample card
      expect(find.text('Unknown Sample Quantification 🔍'), findsOneWidget);
      expect(find.textContaining('Quantified Conc (x_unk):'), findsOneWidget);

      // Verify standards table has default data
      expect(find.text('Calibration Standards Table:'), findsOneWidget);
      expect(find.text('10.0'), findsWidgets);
      expect(find.text('15200'), findsWidgets);
    });
  });
}
