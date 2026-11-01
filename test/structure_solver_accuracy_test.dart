import 'package:chem_buddy/data/services/spectral_peak_input.dart';
import 'package:chem_buddy/data/services/spectroscopy_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  DeductionStep candidate(SpectroscopyAnalysisResult result) =>
      result.steps.firstWhere((step) => step.stepNumber == 7);

  test('a matching formula and IR cannot override incompatible proton NMR', () {
    final result = SpectroscopyService.analyzeSpectraStructured(
      formula: 'C8H8O',
      irPeaks: [1685, 1600],
      nmr1HPeaks: [3.6, 7.3, 9.7],
      nmr13CPeaks: [50, 127, 128, 130, 135, 200],
    );
    expect(candidate(result).summary, isNot(contains('Acetophenone')));
    expect(result.markdownFull, isNot(contains('uniquely validates')));
    expect(candidate(result).content, isNot(contains('**SMILES**')));
  });

  test('matching proton shifts cannot override incompatible carbon NMR', () {
    final match = SpectroscopyService.findKnownSpectroscopyCompound(
      formula: 'C8H8O',
      irPeaks: [1685],
      nmrPeaks: [2.6, 7.5, 7.95],
      nmr13CPeaks: [40, 70, 115, 120, 150, 175],
    );
    expect(match, isNull);
  });

  test(
    'matching aromatic signals cannot hide the wrong alkyl proton shift',
    () {
      final match = SpectroscopyService.findKnownSpectroscopyCompound(
        formula: 'C8H8O',
        irPeaks: [1685, 1600],
        nmrPeaks: [3.8, 7.45, 7.55, 7.95],
        nmr13CPeaks: [26.6, 128.3, 128.5, 133.1, 137.1, 198.1],
      );
      expect(match, isNull);
    },
  );

  test(
    'formula alone, IR alone and a single resonance do not identify isomers',
    () {
      for (final result in [
        SpectroscopyService.findKnownSpectroscopyCompound(formula: 'C8H8O'),
        SpectroscopyService.findKnownSpectroscopyCompound(
          formula: 'C8H8O',
          irPeaks: [1685],
        ),
        SpectroscopyService.findKnownSpectroscopyCompound(
          formula: 'C8H8O',
          nmrPeaks: [7.5],
        ),
      ]) {
        expect(result, isNull);
      }
    },
  );

  test(
    'chlorinated formulas and subscript formulas retain their atom identity',
    () {
      final parsed = SpectroscopyService.parseFormula(' C₆H₅Cl ');
      expect(parsed.isValid, isTrue);
      expect(parsed.chlorines, 1);
      final result = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C₈H₈O',
        nmr1HPeaks: [2.6, 7.5, 7.95],
        nmr13CPeaks: [26.6, 128.3, 128.6, 133.1, 137.1, 198.1],
      );
      expect(candidate(result).summary, contains('Acetophenone'));
    },
  );

  test('malformed or unsupported formulas are rejected in full', () {
    for (final formula in [
      'C8H8O junk',
      'C8H8O)',
      'C0H2',
      'C6H5Na',
      'C6H5+',
      'C8H8O2.5',
    ]) {
      expect(
        SpectroscopyService.parseFormula(formula).isValid,
        isFalse,
        reason: formula,
      );
    }
  });

  test('ordinary aromatic C-H stretch is not assigned as acid O-H', () {
    final result = SpectroscopyService.analyzeSpectraStructured(
      formula: 'C8H8O',
      irPeaks: [1685, 3050],
      nmr1HPeaks: [2.6, 7.5, 7.95],
      nmr13CPeaks: [26.6, 128.3, 128.6, 133.1, 137.1, 198.1],
    );
    expect(result.sanityReport!.hasViolations, isFalse);
    expect(candidate(result).summary, contains('Acetophenone'));
  });

  test(
    'vanillin is selected by aldehyde NMR even when IR overlaps an ester',
    () {
      final result = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C8H8O3',
        irPeaks: [1685, 1590],
        nmr1HPeaks: [3.96, 7.03, 7.41, 9.82],
        nmr13CPeaks: [56.1, 108.8, 114.4, 127.6, 130, 147.2, 151.7, 190.9],
      );
      expect(candidate(result).summary, contains('Vanillin'));
      expect(candidate(result).content, contains('Expected Reference Data'));
    },
  );

  test('alkene protons are not an impossible benzene ring', () {
    final result = SpectroscopyService.analyzeSpectraStructured(
      formula: 'C3H4O',
      nmr1HPeaks: [6.0, 6.5, 9.5],
      nmr13CPeaks: [130, 140, 195],
    );
    expect(result.sanityReport!.hasViolations, isFalse);
  });

  test('aryl C-O at 162 ppm is not automatically called a carbonyl', () {
    final result = SpectroscopyService.analyzeSpectraStructured(
      formula: 'C6H6O',
      irPeaks: [3350, 1590],
      nmr1HPeaks: [6.8, 7.1],
      nmr13CPeaks: [116, 121, 130, 162],
    );
    expect(result.steps[3].content, contains('aryl C–O/C–N'));
    expect(
      result.steps[3].content,
      isNot(contains('**Ester / Acid Derivative Carbonyl')),
    );
  });

  test('carbon shifts cannot determine DEPT multiplicity', () {
    final result = SpectroscopyService.analyzeSpectraStructured(
      formula: 'C7H8',
      nmr13CPeaks: [21, 125, 128, 129, 138],
    );
    expect(result.steps[3].content, isNot(contains('appears upright in DEPT')));
    expect(result.steps[3].content, contains('DEPT/HSQC'));
  });

  test('non-finite and out of range peak positions are rejected', () {
    for (final values in [
      [double.nan],
      [double.infinity],
      [198.1],
    ]) {
      expect(
        SpectroscopyService.analyzeSpectraStructured(
          formula: 'C8H8O',
          nmr1HPeaks: values,
        ).isValid,
        isFalse,
      );
    }
    expect(
      SpectroscopyService.analyzeSpectraStructured(
        formula: 'C8H8O',
        irPeaks: [50],
      ).isValid,
      isFalse,
    );
  });

  test(
    'presets extract positions without integration, coupling or intensity',
    () {
      final acetophenone = SpectroscopyService.caseStudies.first;
      expect(SpectralPeakInput.fromAnnotated(acetophenone.irHighlights, 'IR'), [
        1685,
        1600,
        1450,
        3050,
      ]);
      expect(
        SpectralPeakInput.fromAnnotated(
          acetophenone.nmr1H.replaceAll(RegExp(r'\s+[–-]\s+'), '–'),
          'NMR',
        ),
        [2.6, 7.5, 7.95],
      );
      expect(SpectralPeakInput.fromAnnotated(acetophenone.nmr13C, 'NMR'), [
        26.6,
        128.3,
        128.6,
        133.1,
        137.1,
        198.1,
      ]);
      expect(SpectralPeakInput.fromAnnotated(acetophenone.massSpec, 'MS'), [
        120,
        105,
        77,
      ]);
      final bromopropane = SpectroscopyService.caseStudies[2];
      expect(SpectralPeakInput.fromAnnotated(bromopropane.massSpec, 'MS'), [
        122,
        124,
        43,
      ]);
    },
  );

  test('every preset still supports its intended reference compound', () {
    for (final study in SpectroscopyService.caseStudies) {
      final result = SpectroscopyService.analyzeSpectraStructured(
        formula: study.formula,
        irPeaks: SpectralPeakInput.fromAnnotated(study.irHighlights, 'IR'),
        nmr1HPeaks: SpectralPeakInput.fromAnnotated(
          study.nmr1H.replaceAll(RegExp(r'\s+[–-]\s+'), '–'),
          'NMR',
        ),
        nmr13CPeaks: SpectralPeakInput.fromAnnotated(study.nmr13C, 'NMR'),
        msPeaks: SpectralPeakInput.fromAnnotated(study.massSpec, 'MS'),
      );
      expect(result.isValid, isTrue, reason: study.compoundName);
      expect(
        candidate(result).content,
        contains('Tentative Reference Candidate'),
        reason: '${study.compoundName}: ${candidate(result).content}',
      );
    }
  });

  test('invalid tokens are not silently removed from a user spectrum', () {
    expect(
      SpectralPeakInput.parse('2.6, nope, 7.5', '¹H NMR').error,
      isNotNull,
    );
    expect(SpectralPeakInput.parse('NaN', '¹H NMR').error, isNotNull);
    expect(SpectralPeakInput.parse('2.6; 7.5 7.95', '¹H NMR').values, [
      2.6,
      7.5,
      7.95,
    ]);
  });
}
