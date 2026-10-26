import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:chem_buddy/core/widgets/chemistry_markdown_view.dart';

void main() {
  for (final brightness in Brightness.values) {
    testWidgets('Markdown emphasis remains readable in $brightness', (
      tester,
    ) async {
      final scheme = ColorScheme.fromSeed(
        seedColor: Colors.pink,
        brightness: brightness,
      );
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData(colorScheme: scheme),
          home: const Scaffold(
            body: ChemistryMarkdownView(
              text: '# Heading\n\n**Upload Notes / PDF** and *Common Exam Topics*',
            ),
          ),
        ),
      );
      final style = tester
          .widget<MarkdownBody>(find.byType(MarkdownBody))
          .styleSheet!;
      for (final text in [
        style.p,
        style.strong,
        style.em,
        style.h1,
        style.h2,
        style.h3,
        style.h4,
        style.h5,
        style.h6,
        style.listBullet,
        style.tableHead,
      ]) {
        final foreground = text!.color!.computeLuminance();
        final background = scheme.surface.computeLuminance();
        final contrast =
            (foreground > background ? foreground + .05 : background + .05) /
            (foreground > background ? background + .05 : foreground + .05);
        expect(contrast, greaterThanOrEqualTo(4.5));
      }
    });
  }

  group('ChemistryMarkdownView Rendering Tests', () {
    testWidgets('1. Renders plain text and standard chemistry notation', (
      tester,
    ) async {
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

    testWidgets('2. Renders inline LaTeX equations and reaction arrows', (
      tester,
    ) async {
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

    testWidgets(
      '3. Renders display math blocks without throwing layout overflow',
      (tester) async {
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
      },
    );
  });
}
