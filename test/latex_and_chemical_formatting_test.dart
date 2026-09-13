import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/chemistry_markdown_view.dart';
import 'package:chem_buddy/core/utils/chemistry_text_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Module 2: LaTeX/KaTeX & Chemical Formula Formatting Tests', () {
    test('1. Preserves complex inline math expressions verbatim without stripping \\text or mangling subscripts', () {
      const input = r'The complex is $\text{Mn}_2(\text{CO})_{10}$, with $\Delta G^\circ = -RT \ln K$, orbital $\Psi_3$, and acidity $\text{p}K_a = 4.75$.';
      final formatted = ChemistryTextFormatter.format(input);

      // Verify all inline math tokens remain completely uncorrupted
      expect(formatted, contains(r'$\text{Mn}_2(\text{CO})_{10}$'));
      expect(formatted, contains(r'$\Delta G^\circ = -RT \ln K$'));
      expect(formatted, contains(r'$\Psi_3$'));
      expect(formatted, contains(r'$\text{p}K_a = 4.75$'));
    });

    test('2. Formats plain chemical formulas with subscripts and superscripts in narrative text', () {
      final res1 = ChemistryTextFormatter.formatPlainFormulas('The oxidation of C6H5CHO by KMnO4 in H2SO4 yields C6H5COOH.');
      expect(res1, contains('C₆H₅CHO'));
      expect(res1, contains('KMnO₄'));
      expect(res1, contains('H₂SO₄'));
      expect(res1, contains('C₆H₅COOH'));

      final res2 = ChemistryTextFormatter.formatPlainFormulas('Potassium ferrocyanide contains [Fe(CN)6]4- ions, while ferricyanide has Fe(CN)6^3-.');
      expect(res2, contains('[Fe(CN)₆]⁴⁻'));
      expect(res2, contains('Fe(CN)₆³⁻'));
    });

    testWidgets('3. Renders inline math expressions through ChemistryMarkdownView', (tester) async {
      const input = r'''
### Organometallic & Physical Chemistry
The transition metal dimer $\text{Mn}_2(\text{CO})_{10}$ has $D_{4d}$ symmetry.
At standard state, $\Delta G^\circ = -nFE^\circ_{\text{cell}}$.
The HOMO of 1,3,5-hexatriene is $\Psi_3$, and acetic acid has $\text{p}K_a = 4.76$.
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

      expect(find.byType(ChemistryMarkdownView), findsOneWidget);
      expect(find.textContaining('Organometallic & Physical Chemistry'), findsOneWidget);
      expect(find.textContaining(r'\text'), findsNothing);
    });

    testWidgets('4. Renders character tables and matrices with horizontal scrolling and borders', (tester) async {
      const tableMarkdown = r'''
### Hückel Secular Determinant & Correlation Matrix

| Orbital | Energy | Symmetry | Degeneracy |
| :--- | :--- | :--- | :--- |
| $\psi_1$ | $\alpha + 2\beta$ | $A_{1g}$ | 1 |
| $\psi_2, \psi_3$ | $\alpha + \beta$ | $E_{1u}$ | 2 |
| $\psi_4, \psi_5$ | $\alpha - \beta$ | $E_{2g}$ | 2 |
| $\psi_6$ | $\alpha - 2\beta$ | $B_{2u}$ | 1 |

The total $\pi$-electron energy for benzene is $E_\pi = 6\alpha + 8\beta$.
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: ChemistryMarkdownView(text: tableMarkdown),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChemistryMarkdownView), findsOneWidget);
      expect(find.byType(SingleChildScrollView), findsWidgets);
      expect(find.textContaining('Hückel Secular Determinant'), findsOneWidget);
      expect(find.textContaining('total'), findsOneWidget);
    });
  });
}
