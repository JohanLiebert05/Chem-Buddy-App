import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/utils/chemistry_text_formatter.dart';

void main() {
  test('ChemistryTextFormatter formats equations and chemistry notation', () {
    expect(
      ChemistryTextFormatter.format(r'Relates droplet radius ($r$) to terminal fall velocity ($v_t$)'),
      equals('Relates droplet radius (r) to terminal fall velocity (vₜ)'),
    );

    expect(
      ChemistryTextFormatter.format(r'v_t = (2 * r^2 * delta_rho * g) / (9 * eta)'),
      equals('vₜ = (2r² · Δρ · g) / (9η)'),
    );

    expect(
      ChemistryTextFormatter.format(r'$\Delta G = \Delta H - T\Delta S$'),
      equals('ΔG = ΔH - TΔS'),
    );

    expect(
      ChemistryTextFormatter.format('H_2SO_4 and Ca^{2+} and CH_3COOH and Fe^{3+} and SO_4^{2-}'),
      equals('H₂SO₄ and Ca²⁺ and CH₃COOH and Fe³⁺ and SO₄²⁻'),
    );

    expect(
      ChemistryTextFormatter.format('N2 + 3H2 <=> 2NH3'),
      equals('N₂ + 3H₂ ⇌ 2NH₃'),
    );

    expect(
      ChemistryTextFormatter.format(r'\frac{2r^2 \Delta\rho g}{9\eta}'),
      equals('(2r² Δρg) / (9η)'),
    );
  });
}
