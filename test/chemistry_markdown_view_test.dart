import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/chemistry_markdown_view.dart';

void main() {
  group('ChemistryMarkdownView Rendering Tests', () {
    testWidgets('1. Renders plain text and standard chemistry notation', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChemistryMarkdownView(
              text: 'The reaction of H2SO4 with 2 NaOH produces Na2SO4 and 2 H2O.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChemistryMarkdownView), findsOneWidget);
    });

    testWidgets('2. Renders inline LaTeX equations and reaction arrows', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChemistryMarkdownView(
              text: r'The rate equation is $\text{Rate} = k[\text{A}][\text{B}]$ and $\Delta G = \Delta H - T\Delta S$.',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChemistryMarkdownView), findsOneWidget);
    });

    testWidgets('3. Renders display math blocks without throwing layout overflow', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChemistryMarkdownView(
              text: r'''
### Key Reaction Mechanism
$$2 \text{R-CHO} + \text{OH}^- \xrightarrow{\text{conc. NaOH}} \text{R-CH}_2\text{OH} + \text{R-COO}^-$$
This represents the classic hydride transfer disproportionation.
''',
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChemistryMarkdownView), findsOneWidget);
    });
  });
}