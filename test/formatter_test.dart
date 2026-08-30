import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/utils/chemistry_text_formatter.dart';

void main() {
  group('ChemistryTextFormatter & Chemistry-Aware Sanitization Tests', () {
    test('TEST 1: Cannizzaro reaction formatting without decorative dots or prompt leaks', () {
      const rawAiResponse = '''
[Format as a structured 5-Mark MSc Chemistry Answer with Principle, Reaction, Mechanism, and Conditions]: cannizaro reaction
· · · Definition · · :
Cannizzaro reaction is a disproportionation reaction in which an aldehyde without alpha-hydrogen undergoes simultaneous oxidation and reduction in the presence of concentrated alkali.

⋯ Key Reaction / Equation ⋯
2C6H5CHO + KOH -> C6H5CH2OH + C6H5COOK

::: Key Point :::
One molecule of aldehyde is reduced to a primary alcohol, while another is oxidized to a carboxylate salt.
''';

      final clean = ChemistryTextFormatter.format(rawAiResponse);

      // Prompt leak removed
      expect(clean.contains('[Format as a structured'), false);
      // Decorative noise removed
      expect(clean.contains('· · ·'), false);
      expect(clean.contains('⋯'), false);
      expect(clean.contains(':::'), false);
      // Normalized headings
      expect(clean.contains('### Definition'), true);
      expect(clean.contains('### Key Reaction / Equation'), true);
      expect(clean.contains('### Key Point'), true);
      // Chemistry subscripts and arrows normalized
      expect(clean.contains('2C₆H₅CHO + KOH → C₆H₅CH₂OH + C₆H₅COOK'), true);
      expect(clean.contains('α-hydrogen'), true);
    });

    test('TEST 2: Sulfate ion subscripts and charges', () {
      final res1 = ChemistryTextFormatter.format('Sulfate ion is SO4^2- in aqueous solution with Ba2+ forming BaSO4.');
      expect(res1.contains('SO₄²⁻'), true);
      expect(res1.contains('Ba²⁺'), true);
      expect(res1.contains('BaSO₄'), true);
    });

    test('TEST 3: Iron oxidation states and charges', () {
      final res = ChemistryTextFormatter.format('Iron exists as Fe2+ and Fe3+ with oxidation states Fe(II) and Fe(III).');
      expect(res.contains('Fe²⁺'), true);
      expect(res.contains('Fe³⁺'), true);
      expect(res.contains('Fe(II)'), true);
      expect(res.contains('Fe(III)'), true);
    });

    test('TEST 4: Esterification reaction and equilibrium symbol', () {
      final res = ChemistryTextFormatter.format('CH3COOH + C2H5OH <=> CH3COOC2H5 + H2O in the presence of conc. H2SO4.');
      expect(res.contains('CH₃COOH + C₂H₅OH ⇌ CH₃COOC₂H₅ + H₂O'), true);
      expect(res.contains('H₂SO₄'), true);
    });

    test('TEST 5: Mechanism with electron movement, curly arrows, and partial charges', () {
      final res = ChemistryTextFormatter.format('Nu- attacks the delta+ carbonyl carbon while delta- develops on oxygen, followed by H+ and OH- transfer.');
      expect(res.contains('Nu⁻'), true);
      expect(res.contains('δ⁺'), true);
      expect(res.contains('δ⁻'), true);
      expect(res.contains('H⁺'), true);
      expect(res.contains('OH⁻'), true);
    });

    test('TEST 6: Mathematical thermodynamics and spectroscopy notations', () {
      expect(
        ChemistryTextFormatter.format(r'$\Delta G = \Delta H - T\Delta S$ at 298 K'),
        equals('ΔG = ΔH - TΔS at 298 K'),
      );

      expect(
        ChemistryTextFormatter.format('1H NMR and 13C NMR spectra show chemical shift in ppm relative to TMS (delta = 0).'),
        contains('¹H NMR and ¹³C NMR'),
      );
    });
  });
}
