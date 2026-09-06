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

  group('Chemistry Toolkit Validation & Edge Case Tests', () {
    testWidgets('Solutions Tab: Renders Molar Mass, Molarity, Dilution calculators', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildToolkitApp(initialCategory: 0));
      await tester.pumpAndSettle();

      expect(find.text('Molar Mass Calculator'), findsOneWidget);
      expect(find.textContaining('Molarity & Normality'), findsOneWidget);
      expect(find.textContaining('Dilution Law'), findsOneWidget);
    });

    testWidgets('Molar Mass Calculator: empty or invalid formula shows error message', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildToolkitApp(initialCategory: 0));
      await tester.pumpAndSettle();

      final formulaField = find.byType(TextField).at(0);
      final calcBtn = find.widgetWithText(ElevatedButton, 'Calculate');

      // Clear input and calculate
      await tester.enterText(formulaField, '');
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Please enter a chemical formula'), findsOneWidget);

      // Invalid chemical formula with unknown element
      await tester.enterText(formulaField, 'XYZUnknown123');
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.textContaining('Unknown chemical element symbol'), findsOneWidget);
    });

    testWidgets('Molarity Calculator: zero or negative volume/molar mass shows error banner', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildToolkitApp(initialCategory: 0));
      await tester.pumpAndSettle();

      final massField = find.byType(TextField).at(1);
      final mmField = find.byType(TextField).at(2);
      final volField = find.byType(TextField).at(3);
      final calcBtn = find.widgetWithText(ElevatedButton, 'Compute M & N');

      // Test zero molar mass
      await tester.enterText(mmField, '0');
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.text('Molar mass must be strictly greater than 0 g/mol.'), findsOneWidget);

      // Test zero volume
      await tester.enterText(mmField, '40.0');
      await tester.enterText(volField, '0');
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.text('Volume must be strictly positive (> 0 mL).'), findsOneWidget);

      // Test negative mass
      await tester.enterText(massField, '-5');
      await tester.enterText(volField, '500');
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.text('Please enter a valid non-negative mass (g).'), findsOneWidget);
    });

    testWidgets('Dilution Calculator: zero or negative V2 shows error banner', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildToolkitApp(initialCategory: 0));
      await tester.pumpAndSettle();

      final v1Field = find.byType(TextField).at(6);
      final v2Field = find.byType(TextField).at(7);
      final calcBtn = find.widgetWithText(ElevatedButton, 'Calculate Final Conc C2');

      await tester.enterText(v2Field, '0');
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.text('Final volume V₂ must be strictly positive (> 0 mL).'), findsOneWidget);

      // Test negative V1
      await tester.enterText(v1Field, '-10');
      await tester.enterText(v2Field, '100');
      await tester.tap(calcBtn);
      await tester.pumpAndSettle();

      expect(find.text('Initial volume V₁ must be strictly positive (> 0 mL).'), findsOneWidget);
    });

    testWidgets('Acid-Base Tab: pH & Henderson-Hasselbalch calculators validate strictly positive inputs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildToolkitApp(initialCategory: 3));
      await tester.pumpAndSettle();

      // Index 0: [H+]
      final hField = find.byType(TextField).at(0);
      final phBtn = find.widgetWithText(ElevatedButton, 'Calculate pH');
      await tester.enterText(hField, '0');
      await tester.tap(phBtn);
      await tester.pumpAndSettle();

      expect(find.text('[H⁺] ion concentration must be strictly positive (> 0 mol/L).'), findsOneWidget);

      // Index 2: [Conjugate Base]
      final saltField = find.byType(TextField).at(2);
      final hhBtn = find.widgetWithText(ElevatedButton, 'Compute Buffer pH');
      await tester.enterText(saltField, '0');
      await tester.tap(hhBtn);
      await tester.pumpAndSettle();

      expect(find.text('Conjugate base concentration [A⁻] must be strictly positive (> 0).'), findsOneWidget);
    });

    testWidgets('Thermo & Kinetics Tab: Gibbs and Arrhenius calculators validate inputs', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildToolkitApp(initialCategory: 4));
      await tester.pumpAndSettle();

      // Index 1: Gibbs Temp T (K)
      final tempField = find.byType(TextField).at(1);
      final gibbsBtn = find.widgetWithText(ElevatedButton, 'Calculate ΔG');
      await tester.enterText(tempField, '-50');
      await tester.tap(gibbsBtn);
      await tester.pumpAndSettle();

      expect(find.text('Absolute temperature T must be non-negative (≥ 0 K).'), findsOneWidget);

      // Index 5: Arrhenius Temp (K)
      final arrhTemp = find.byType(TextField).at(5);
      final arrhBtn = find.widgetWithText(ElevatedButton, 'Compute Rate Constant k');
      await tester.enterText(arrhTemp, '0');
      await tester.tap(arrhBtn);
      await tester.pumpAndSettle();

      expect(find.text('Absolute temperature T must be strictly positive (> 0 K).'), findsOneWidget);
    });

    testWidgets('Spectroscopy Tab: Beer-Lambert and Photon Energy validate positive parameters', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildToolkitApp(initialCategory: 6));
      await tester.pumpAndSettle();

      // Index 1: Path length l (cm)
      final pathField = find.byType(TextField).at(1);
      final beerBtn = find.widgetWithText(ElevatedButton, 'Compute Absorbance A');
      await tester.enterText(pathField, '0');
      await tester.tap(beerBtn);
      await tester.pumpAndSettle();

      expect(find.text('Path length l must be strictly positive (> 0 cm).'), findsOneWidget);

      // Index 3: Wavelength (nm)
      final wlField = find.byType(TextField).at(3);
      final photonBtn = find.widgetWithText(ElevatedButton, 'Convert to Energy & Frequency');
      await tester.enterText(wlField, '-100');
      await tester.tap(photonBtn);
      await tester.pumpAndSettle();

      expect(find.text('Wavelength λ must be strictly positive (> 0 nm).'), findsOneWidget);
    });

    testWidgets('Electrochem Tab: Nernst and Cell Potential validate valid potentials and electron counts', (tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);

      await tester.pumpWidget(buildToolkitApp(initialCategory: 7));
      await tester.pumpAndSettle();

      // Index 1: Nernst n (electrons)
      final nernstN = find.byType(TextField).at(1);
      final nernstBtn = find.widgetWithText(ElevatedButton, 'Calculate Non-Standard E_cell');
      await tester.enterText(nernstN, '0');
      await tester.tap(nernstBtn);
      await tester.pumpAndSettle();

      expect(find.text('Number of transferred electrons n must be strictly positive (≥ 1).'), findsOneWidget);

      // Index 5: Cell Potential n (e-)
      final cellN = find.byType(TextField).at(5);
      final cellBtn = find.widgetWithText(ElevatedButton, 'Calculate E°cell & ΔG°');
      await tester.enterText(cellN, '0');
      await tester.tap(cellBtn);
      await tester.pumpAndSettle();

      expect(find.text('Number of transferred electrons n must be strictly positive (≥ 1).'), findsNWidgets(2));
    });
  });
}
