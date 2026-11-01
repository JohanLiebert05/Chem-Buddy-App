import 'package:chem_buddy/core/chemistry/spectrum_svg_renderer.dart';
import 'package:chem_buddy/data/services/spectroscopy_reference_service.dart';
import 'package:chem_buddy/data/services/spectroscopy_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('all library spectra and small shift perturbations avoid wrong unique matches', () {
    var checked = 0;
    var matched = 0;
    for (final compound in SpectroscopyService.curatedCompoundDatabase) {
      final h = SpectroscopyReferenceService.signals(
        compound,
        SpectrumTechnique.proton,
      ).map((s) => s.position).toList();
      final c = SpectroscopyReferenceService.signals(
        compound,
        SpectrumTechnique.carbon,
      ).map((s) => s.position).toList();
      for (final perturbation in [-1.0, 0.0, 1.0]) {
        final result = SpectroscopyService.analyzeSpectraStructured(
          formula: compound.formula
              .replaceAll('BR', 'Br')
              .replaceAll('CL', 'Cl'),
          nmr1HPeaks: h.map((v) => v + perturbation * .02).toList(),
          nmr13CPeaks: c.map((v) => v + perturbation * .30).toList(),
          irPeaks: SpectroscopyReferenceService.signals(
            compound,
            SpectrumTechnique.ir,
          ).map((s) => s.position).toList(),
          msPeaks: SpectroscopyReferenceService.signals(
            compound,
            SpectrumTechnique.mass,
          ).map((s) => s.position).toList(),
        );
        expect(result.isValid, isTrue, reason: compound.commonName);
        expect(
          result.supportedCompound == null ||
              result.supportedCompound!.smiles == compound.smiles,
          isTrue,
          reason:
              '${compound.commonName} was incorrectly assigned as ${result.supportedCompound?.commonName}',
        );
        expect(result.markdownFull, isNot(contains('uniquely validates')));
        if (result.supportedCompound != null) matched++;
        checked++;
      }
      final invalid = SpectroscopyService.analyzeSpectraStructured(
        formula: compound.formula.replaceAll('BR', 'Br').replaceAll('CL', 'Cl'),
        nmr1HPeaks: [...h, 19.5],
        nmr13CPeaks: c,
      );
      expect(
        invalid.supportedCompound,
        isNull,
        reason: '${compound.commonName}: unexplained proton',
      );
    }
    expect(checked, SpectroscopyService.curatedCompoundDatabase.length * 3);
    expect(
      matched,
      greaterThanOrEqualTo((checked * .8).floor()),
      reason: 'Well-supported reference spectra should be recognized.',
    );
  });

  test(
    'one reference resonance cannot account for two distinct entered peaks',
    () {
      final result = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C3H7Br',
        nmr1HPeaks: [1.72, 4.28],
        nmr13CPeaks: [27.2, 44.2, 44.3],
      );
      expect(result.supportedCompound, isNull);
    },
  );

  test('alkene and alkyne IR overlaps do not become impossible oxygen or nitrogen claims', () {
    final alkene = SpectroscopyService.runSanityChecks(
      formula: SpectroscopyService.parseFormula('C3H6'),
      irPeaks: [1655],
    );
    final alkyne = SpectroscopyService.runSanityChecks(
      formula: SpectroscopyService.parseFormula('C4H6'),
      irPeaks: [2240],
    );
    expect(alkene.hasViolations, isFalse);
    expect(alkyne.hasViolations, isFalse);
    expect(alkyne.warningCount, greaterThan(0));
  });

  test(
    'bromine nominal ion is not the average mass or its heavier isotope',
    () {
      final formula = SpectroscopyService.parseFormula('C3H7Br');
      expect(formula.nominalMass, 122);
      final result = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C3H7Br',
        msPeaks: [122, 124, 43, 105],
      );
      final ms = result.steps[4].content;
      expect(ms, contains('heavier halogen isotopologue'));
      expect(ms, isNot(contains('Benzoyl Cation')));
      expect(ms, isNot(contains('acetylium')));
      expect(ms, contains('propyl'));
    },
  );

  test('unsupplied intensities are not fabricated as one-percent peaks', () {
    final svg = SpectrumSvgRenderer.render(
      technique: SpectrumTechnique.mass,
      expected: const [
        SpectrumSignal(position: 43, relativeIntensity: 100),
        SpectrumSignal(position: 88),
      ],
    );
    final group = svg.split('<g id="expected"').last.split('</g>').first;
    final heights = RegExp(r'y2="([\d.]+)"')
        .allMatches(group)
        .map((m) => m.group(1))
        .toSet();
    expect(heights.length, 1);
  });
}
