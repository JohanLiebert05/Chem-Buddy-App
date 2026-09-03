import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/chemistry_markdown_view.dart';
import 'package:chem_buddy/core/utils/chemistry_text_formatter.dart';

void main() {
  group('ChemistryMarkdownView & LaTeX Rendering Tests', () {
    testWidgets('Renders headings and inline math without raw ### artifacts', (tester) async {
      const input = '''
### 1. Acid-Base Equilibrium
The autoionization constant of pure water at 25 °C is given by:
\$K_w = [H_3O^+][OH^-] = 1.0 \\times 10^{-14}\$
For any aqueous solution, neutral pH occurs when \$[H_3O^+] = [OH^-] = 1.0 \\times 10^{-7}\$.
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

      // Ensure NO raw ### literals appear in the rendered text
      expect(find.textContaining('###'), findsNothing);
      expect(find.textContaining('Acid-Base Equilibrium'), findsOneWidget);
      expect(find.textContaining('autoionization constant'), findsOneWidget);
    });

    testWidgets('Renders messy real chemistry cases: Henderson-Hasselbalch & buffers', (tester) async {
      const input = '''
## Buffer Chemistry & The Henderson-Hasselbalch Equation
The Henderson-Hasselbalch equation expresses the relationship between pH and buffer components:
\$\\text{pH} = \\text{p}K_a + \\log\\frac{[\\text{A}^-]}{[\\text{HA}]}\$

Key Principles:
- When \$[\\text{A}^-] = [\\text{HA}]\$, the ratio is 1, hence \$\\text{pH} = \\text{p}K_a\$.
- Maximum buffer capacity occurs within the range \$\\text{pH} = \\text{p}K_a \\pm 1\$.
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

      expect(find.textContaining('##'), findsNothing);
      expect(find.textContaining('Henderson-Hasselbalch Equation'), findsOneWidget);
      expect(find.textContaining('buffer capacity'), findsOneWidget);
    });


    testWidgets('Renders MO diagrams and spin state terms properly', (tester) async {
      const input = '''
### Molecular Orbital & Spin States
For the \$O_2\$ molecule with ground state configuration:
\$\\sigma_{1s}^2 \\sigma_{1s}^{*2} \\sigma_{2s}^2 \\sigma_{2s}^{*2} \\sigma_{2p_z}^2 \\pi_{2p_x}^2 \\pi_{2p_y}^2 \\pi_{2p_x}^{*1} \\pi_{2p_y}^{*1}\$
The spin multiplicity is given by \$2S + 1 = 3\$ (triplet ground state, \$^3\\Sigma_g^-\$).
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

      expect(find.textContaining('###'), findsNothing);
      expect(find.textContaining('Molecular Orbital & Spin States'), findsOneWidget);
      expect(find.textContaining('triplet ground state'), findsOneWidget);
    });

    test('ChemistryTextFormatter.toUnicodeMath converts LaTeX macros to clean Unicode', () {
      final res1 = ChemistryTextFormatter.toUnicodeMath(r'K_w = [H_3O^+][OH^-] = 1.0 \times 10^{-14}');
      expect(res1.contains(r'\times'), isFalse);
      expect(res1.contains('×'), isTrue);
      expect(res1.contains('⁻¹⁴'), isTrue);

      final res2 = ChemistryTextFormatter.toUnicodeMath(r'\text{pH} = \text{p}K_a + \log\frac{[\text{A}^-]}{[\text{HA}]}');
      expect(res2.contains(r'\frac'), isFalse);
      expect(res2.contains(r'\text'), isFalse);
      expect(res2.contains('/'), isTrue);

      final res3 = ChemistryTextFormatter.toUnicodeMath(r'\Delta G = \Delta H - T\Delta S');
      expect(res3.contains(r'\Delta'), isFalse);
      expect(res3.contains('ΔG'), isTrue);
    });
  });
}
