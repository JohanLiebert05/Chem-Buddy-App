import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/chemistry_markdown_view.dart';
import 'package:chem_buddy/core/widgets/chemistry_rich_text.dart';
import 'package:chem_buddy/data/services/chemistry_knowledge_engine.dart';

void main() {
  group('ChemBuddy AI Chat & Math Rendering Verification Tests (10 Test Cases)', () {
    // -------------------------------------------------------------------------
    // TEST 1: Plain text chemistry question does not leak DISPLAY_MATH_0
    // -------------------------------------------------------------------------
    testWidgets('Test 1: Plain text chemistry response never leaks DISPLAY_MATH_0 or placeholder tokens', (tester) async {
      const responseText = '''
2) Representative Reaction
(Aspirin Synthesis)

\$\$C_7H_6O_3 + C_4H_6O_3 \\to C_9H_8O_4 + C_2H_4O_2\$\$

3) Key Condition/Nuance
- Temperature: 85 °C
- Catalyst: Concentrated H_2SO_4
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChemistryMarkdownView(text: responseText),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Ensure NO DISPLAY_MATH tokens, underscores, or internal placeholders are rendered
      expect(find.textContaining('DISPLAY_MATH'), findsNothing);
      expect(find.textContaining('DISPLAY_MATH_0'), findsNothing);
      expect(find.textContaining('___DISPLAY_MATH'), findsNothing);
      expect(find.textContaining('\uE000'), findsNothing);
      expect(find.textContaining('\uE001'), findsNothing);

      // Verify content is visible
      expect(find.textContaining('Representative Reaction'), findsOneWidget);
      expect(find.textContaining('Aspirin Synthesis'), findsOneWidget);
      expect(find.textContaining('Key Condition/Nuance'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST 2: Multiple display math blocks render cleanly without placeholders
    // -------------------------------------------------------------------------
    testWidgets('Test 2: Multiple display math blocks render formulas and text without placeholder leaks', (tester) async {
      const input = '''
### Enthalpy and Free Energy
First equation:
\$\$\\Delta H^\\circ = -120 \\text{ kJ/mol}\$\$

Second equation:
\$\$\\Delta G^\\circ = \\Delta H^\\circ - T\\Delta S^\\circ\$\$

Conclusion: Spontaneous under standard conditions.
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChemistryMarkdownView(text: input),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('DISPLAY_MATH'), findsNothing);
      expect(find.textContaining('Enthalpy and Free Energy'), findsOneWidget);
      expect(find.textContaining('First equation:'), findsOneWidget);
      expect(find.textContaining('Second equation:'), findsOneWidget);
      expect(find.textContaining('Conclusion: Spontaneous under standard conditions.'), findsOneWidget);
    });

    // -------------------------------------------------------------------------
    // TEST 3: Inline math does not cause single-character-per-line vertical wrapping
    // -------------------------------------------------------------------------
    testWidgets('Test 3: Inline math in narrative text maintains normal horizontal width and does not collapse vertically', (tester) async {
      const textWithInlineMath = 'Temperature is a measure of kinetic energy where \$E = k_B T\$ in Kelvin.';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 360,
              child: ChemistryMarkdownView(text: textWithInlineMath),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find the ChemistryMarkdownView render object
      final markdownFinder = find.byType(ChemistryMarkdownView);
      expect(markdownFinder, findsOneWidget);

      final renderBox = tester.renderObject<RenderBox>(markdownFinder);
      // The widget should occupy the available width (360), NOT collapse to a tiny width like 10px
      expect(renderBox.size.width, equals(360.0));
      // And its height should be normal text paragraph height (around 20-60px), NOT an elongated vertical column (e.g. > 200px)
      expect(renderBox.size.height, lessThan(80.0));
    });

    // -------------------------------------------------------------------------
    // TEST 4: Long text with multiple formulas wraps properly across multiple lines
    // -------------------------------------------------------------------------
    testWidgets('Test 4: Long text with multiple inline formulas flows naturally across multiple lines without overflowing', (tester) async {
      const longText = '''
In physical chemistry and chemical kinetics, the Arrhenius equation is given by \$k = A e^{-E_a/(RT)}\$.
Here, \$k\$ is the reaction rate constant, \$A\$ is the pre-exponential frequency factor, \$E_a\$ is the activation energy in \$\\text{J/mol}\$,
\$R = 8.314 \\text{ J/(mol K)}\$ is the universal gas constant, and \$T\$ is absolute temperature in Kelvin.
As temperature increases, the fraction of molecules with energy exceeding \$E_a\$ increases dramatically.
''';

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 320,
              child: SingleChildScrollView(
                child: ChemistryMarkdownView(text: longText),
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('Arrhenius equation'), findsOneWidget);
      expect(find.textContaining('activation energy'), findsOneWidget);
      expect(find.textContaining('universal gas constant'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // TEST 5: Fallback on malformed LaTeX renders clean Unicode without raw commands
    // -------------------------------------------------------------------------
    testWidgets('Test 5: Fallback on malformed or unrecognized LaTeX renders clean readable text without raw command bleed', (tester) async {
      const malformed = 'The calculation gives \$\\unknownMacro{x}{y}\$ and \$\\text{pH} = \\text{p}K_a + \\log\\frac{[\\text{A}^-]}{[\\text{HA}]}\$.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChemistryMarkdownView(text: malformed),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Raw unrendered commands must be stripped
      expect(find.textContaining(r'\unknownMacro'), findsNothing);
      expect(find.textContaining(r'\frac'), findsNothing);
      expect(find.textContaining(r'\text{'), findsNothing);
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // TEST 6: Answer mode "quick" produces concise output
    // -------------------------------------------------------------------------
    test('Test 6: Answer mode "quick" produces concise, direct output without forced 10M essay padding', () {
      final response = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'What is ppm in analytical chemistry?',
        mode: 'quick',
      );

      expect(response.answer, isNotEmpty);
      expect(response.answer.contains('DISPLAY_MATH'), isFalse);
      // Quick answer should not contain 10-mark essay rubric breakdown
      expect(response.answer.contains('10-Mark Comprehensive'), isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 7: Answer mode "2m" includes definition and essential points
    // -------------------------------------------------------------------------
    test('Test 7: Answer mode "2m" formats response with 2-Mark structure', () {
      final response = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'Define molarity and parts per million',
        mode: '2m',
      );

      expect(response.answer, isNotEmpty);
      expect(response.answer.contains('2-Mark Academic Response') || response.answer.contains('Core Definition'), isTrue);
      expect(response.answer.contains('DISPLAY_MATH'), isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 8: Answer mode "5m" includes structured exam sections
    // -------------------------------------------------------------------------
    test('Test 8: Answer mode "5m" formats response with 5-Mark MSc structure and exam mark allocation', () {
      final response = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'Explain parts per million and normality in analytical chemistry',
        mode: '5m',
      );

      expect(response.answer, isNotEmpty);
      expect(response.answer.contains('5-Mark Academic Response'), isTrue);
      expect(response.answer.contains('Exam Mark Allocation Guide (5 Marks)'), isTrue);
      expect(response.answer.contains('DISPLAY_MATH'), isFalse);
    });

    // -------------------------------------------------------------------------
    // TEST 9: Complex chemical formulas with subscripts and superscripts render cleanly
    // -------------------------------------------------------------------------
    testWidgets('Test 9: Complex chemical formulas with charges and subscripts render cleanly in ChemistryRichText and MarkdownView', (tester) async {
      const formulas = 'Equilibrium: 2 H_2O ⇌ H_3O^+ + OH^-. Calcium sulfate: Ca^2+ + SO_4^2- → CaSO_4↓.';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ChemistryMarkdownView(text: formulas),
                ChemistryRichText(text: formulas),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('DISPLAY_MATH'), findsNothing);
      expect(find.byType(ChemistryMarkdownView), findsOneWidget);
      expect(find.byType(ChemistryRichText), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // -------------------------------------------------------------------------
    // TEST 10: Mixed markdown with headings, bold, bullet points, and math renders cleanly
    // -------------------------------------------------------------------------
    testWidgets('Test 10: Mixed markdown with headings, bold, bullet points, and display math renders seamlessly', (tester) async {
      const fullDoc = '''
### 1. Le Chatelier's Principle in the Haber Process

The synthesis of ammonia is represented by the equilibrium:

\$\$N_2(g) + 3 H_2(g) \\rightleftharpoons 2 NH_3(g) \\quad \\Delta H^\\circ = -92.4 \\text{ kJ/mol}\$\$

**Key Factors Governing Equilibrium:**
* **Pressure**: Because \$\\Delta n = 2 - (1+3) = -2\$, high pressure favours the forward reaction.
* **Temperature**: Because the reaction is exothermic (\$\\Delta H < 0\$), optimal temperature is maintained at 450 °C.
* **Catalyst**: Finely divided iron with \$\\text{K}_2\\text{O}\$ promoter increases the rate to equilibrium.
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChemistryMarkdownView(text: fullDoc),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('DISPLAY_MATH'), findsNothing);
      expect(find.textContaining("Le Chatelier's Principle in the Haber Process"), findsOneWidget);
      expect(find.textContaining('Key Factors Governing Equilibrium:'), findsOneWidget);
      expect(find.textContaining('Pressure'), findsOneWidget);
      expect(find.textContaining('Temperature'), findsOneWidget);
      expect(find.textContaining('Catalyst'), findsOneWidget);
      expect(tester.takeException(), isNull);
    });
  });
}
