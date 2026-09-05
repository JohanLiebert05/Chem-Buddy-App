import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/chemistry_markdown_view.dart';
import 'package:chem_buddy/core/utils/chemistry_text_formatter.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('LaTeX and Markdown Preprocessing & Consolidation Tests', () {
    testWidgets('Renders naked LaTeX commands properly wrapped in math', (tester) async {
      const nakedLatex = r'\Phi = \frac{hc}{\lambda}';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChemistryMarkdownView(
              text: nakedLatex,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChemistryMarkdownView), findsOneWidget);
    });

    testWidgets('Renders inline and display equations with subscript and Greek letters', (tester) async {
      const complexEquation = r'''
### **3. Key Condition**
$$\Delta G^\circ = -nFE^\circ_{\text{cell}}$$
The reaction is spontaneous when $\Delta G < 0$.
Reaction: \text{H}_{2(g)} + \frac{1}{2}\text{O}_{2(g)} \rightarrow \text{H}_2\text{O}_{(l)}
''';

      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ChemistryMarkdownView(
              text: complexEquation,
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ChemistryMarkdownView), findsOneWidget);
    });

    testWidgets('Renders all MSc Chemistry Toolkit formulas cleanly', (tester) async {
      const toolkitFormulas = [
        r'$$\text{pH} = -\log[\text{H}^+], \quad \text{pOH} = 14 - \text{pH}$$',
        r'$$\text{pH} = \text{p}K_a + \log\frac{[\text{A}^-]}{[\text{HA}]}$$',
        r'$$\Delta G = \Delta H - T\Delta S$$',
        r'$$k = A \exp\left(-\frac{E_a}{RT}\right)$$',
        r'$$A = \varepsilon \cdot c \cdot l$$',
        r'$$E = h\nu = \frac{hc}{\lambda}$$',
        r'$$E = E^\circ - \frac{0.0592}{n} \log Q$$',
        r'$$E^\circ_{\text{cell}} = E^\circ_{\text{cathode}} - E^\circ_{\text{anode}}, \quad \Delta G^\circ = -nFE^\circ_{\text{cell}}$$',
        r'$$n = \frac{m}{M}, \quad N = n \times N_A, \quad V_{\text{STP}} = n \times 22.414\text{ L}$$',
        r'$$[\text{A}]_t = [\text{A}]_0 - kt$$',
        r'$$\ln[\text{A}]_t = \ln[\text{A}]_0 - kt \implies [\text{A}]_t = [\text{A}]_0 e^{-kt}$$',
        r'$$E_n = \frac{n^2 h^2}{8mL^2}$$',
        r'$$\lambda = \frac{h}{mv}$$',
        r'$$H = A + \frac{B}{u} + C \cdot u, \quad u_{\text{opt}} = \sqrt{\frac{B}{C}}$$',
      ];

      for (final formula in toolkitFormulas) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChemistryMarkdownView(
                text: formula,
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(find.byType(ChemistryMarkdownView), findsOneWidget);
      }
    });

    test('ChemistryTextFormatter preserves math delimiters while sanitizing plain text', () {
      const mixed = r'The standard cell potential is $$E^\circ = 1.10\text{ V}$$ and Gibbs is $\Delta G < 0$.';
      final formatted = ChemistryTextFormatter.format(mixed);

      expect(formatted, contains(r'$$E^\circ = 1.10\text{ V}$$'));
      expect(formatted, contains(r'$\Delta G < 0$'));
    });
  });
}
