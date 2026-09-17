import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/spectroscopy_service.dart';

void main() {
  group('SpectroscopyService Tests', () {
    test('calculateDBE accurately determines unsaturation degrees', () {
      // Benzene: C6H6 -> 6 + 1 - 3 = 4
      expect(SpectroscopyService.calculateDBE(carbons: 6, hydrogens: 6), equals(4.0));

      // Acetophenone: C8H8O -> 8 + 1 - 4 = 5
      expect(SpectroscopyService.calculateDBE(carbons: 8, hydrogens: 8, oxygens: 1), equals(5.0));

      // Ethyl 4-aminobenzoate: C9H11NO2 -> 9 + 1 - 5.5 + 0.5 = 5.0
      expect(SpectroscopyService.calculateDBE(carbons: 9, hydrogens: 11, nitrogens: 1, oxygens: 2), equals(5.0));

      // 1-Bromopropane: C3H7Br -> 3 + 1 - 3.5 - 0.5 = 0
      expect(SpectroscopyService.calculateDBE(carbons: 3, hydrogens: 7, halogens: 1), equals(0.0));
    });

    test('Mass spec halogen isotope patterns are accurately recorded', () {
      final clPattern = SpectroscopyService.massSpecPatterns.firstWhere((p) => p.name.contains('Monochloro'));
      expect(clPattern.ratio, contains('3 : 1'));

      final brPattern = SpectroscopyService.massSpecPatterns.firstWhere((p) => p.name.contains('Monobromo'));
      expect(brPattern.ratio, contains('1 : 1'));
    });

    test('analyzeUserSpectra produces comprehensive structural deduction output', () {
      final walkthrough = SpectroscopyService.analyzeUserSpectra(
        formula: 'C8H8O',
        irPeaks: [1685, 1600, 1450],
        nmrPeaks: [2.6, 7.5, 7.9],
        msPeaks: [120, 105, 77],
      );

      expect(walkthrough, contains('Degrees of Unsaturation (DBE / IHD)'));
      expect(walkthrough, contains('FT-IR Functional Group Diagnostics'));
      expect(walkthrough, contains('¹H NMR Chemical Shift Assignment'));
      expect(walkthrough, contains('Mass Spectrometry Fragment Diagnostics'));
      expect(walkthrough, contains('m/z 105'));
      expect(walkthrough, contains('Rule-Based Spectral Sanity Checks 🛡️'));
    });

    test('runSanityChecks passes consistent spectra for Acetophenone', () {
      final parsed = SpectroscopyService.parseFormula('C8H8O');
      final report = SpectroscopyService.runSanityChecks(
        formula: parsed,
        irPeaks: [1685, 1600, 1450],
        nmrPeaks: [2.6, 7.5, 7.9],
        msPeaks: [120, 105, 77],
      );

      expect(report.hasViolations, isFalse);
      expect(report.violationCount, equals(0));
      expect(report.passedCount, greaterThanOrEqualTo(3));
      expect(report.items.any((i) => i.title.contains('Carbonyl (C=O) Valence Consistency') && i.passed), isTrue);
      expect(report.items.any((i) => i.title.contains('Aromatic Proton vs DBE') && i.passed), isTrue);
      expect(report.items.any((i) => i.title.contains('Molecular Ion [M]⁺•') && i.passed), isTrue);
    });

    test('runSanityChecks flags Carbonyl stretch with zero oxygens as violation', () {
      final parsed = SpectroscopyService.parseFormula('C6H12');
      final report = SpectroscopyService.runSanityChecks(
        formula: parsed,
        irPeaks: [1715],
      );

      expect(report.hasViolations, isTrue);
      final cViolation = report.items.firstWhere((i) => i.title.contains('Carbonyl Stretch Without Oxygen'));
      expect(cViolation.severity, equals(SanitySeverity.violation));
      expect(cViolation.passed, isFalse);
    });

    test('runSanityChecks flags aromatic protons with DBE < 4 as violation', () {
      final parsed = SpectroscopyService.parseFormula('C3H6O'); // DBE = 1
      final report = SpectroscopyService.runSanityChecks(
        formula: parsed,
        nmrPeaks: [7.25, 7.35],
      );

      expect(report.hasViolations, isTrue);
      final aroDeficit = report.items.firstWhere((i) => i.title.contains('Aromatic Ring DBE Deficit'));
      expect(aroDeficit.severity, equals(SanitySeverity.violation));
      expect(aroDeficit.message, contains('intact benzene ring requires at least 4 units'));
    });

    test('runSanityChecks flags nitrile stretch with 0 nitrogens as violation', () {
      final parsed = SpectroscopyService.parseFormula('C6H10O');
      final report = SpectroscopyService.runSanityChecks(
        formula: parsed,
        irPeaks: [2240],
      );

      expect(report.hasViolations, isTrue);
      final nitViolation = report.items.firstWhere((i) => i.title.contains('Nitrile Stretch Without Nitrogen'));
      expect(nitViolation.severity, equals(SanitySeverity.violation));
    });

    test('runSanityChecks flags ester peak with only 1 oxygen as warning', () {
      final parsed = SpectroscopyService.parseFormula('C4H8O'); // only 1 oxygen
      final report = SpectroscopyService.runSanityChecks(
        formula: parsed,
        irPeaks: [1745],
      );

      expect(report.warningCount, greaterThanOrEqualTo(1));
      final esterWarn = report.items.firstWhere((i) => i.title.contains('Ester Oxygen Requirement'));
      expect(esterWarn.severity, equals(SanitySeverity.warning));
    });
    test('analyzeSpectraStructured differentiates Ketone from Aldehyde using 13C and 1H', () {
      // Ketone: 13C at 198.1 ppm, NO proton at 9.5-10.5 ppm
      final ketoneRes = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C8H8O',
        irPeaks: [1685, 1600, 1450],
        nmr1HPeaks: [2.60, 7.50, 7.95],
        nmr13CPeaks: [26.6, 128.3, 128.6, 133.1, 137.1, 198.1],
      );
      expect(ketoneRes.isValid, isTrue);
      expect(ketoneRes.markdownFull, contains('Ketone Carbonyl'));
      expect(ketoneRes.markdownFull, isNot(contains('Aldehyde Group')));

      // Aldehyde: 13C at 190.9 ppm, proton at 9.82 ppm
      final aldehydeRes = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C8H8O3',
        irPeaks: [1665, 1590],
        nmr1HPeaks: [3.96, 7.03, 7.41, 9.82],
        nmr13CPeaks: [56.1, 108.8, 114.4, 127.6, 130.0, 147.2, 151.7, 190.9],
      );
      expect(aldehydeRes.isValid, isTrue);
      expect(aldehydeRes.markdownFull, contains('Aldehyde Carbonyl'));
    });

    test('analyzeSpectraStructured auto-filters 13C shifts mistakenly placed in nmrPeaks', () {
      // User entered both 1H (2.6, 7.5) and 13C (128.3, 198.1) in generic nmrPeaks
      final res = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C8H8O',
        nmrPeaks: [2.6, 7.5, 7.9, 26.6, 128.3, 137.1, 198.1],
      );
      expect(res.isValid, isTrue);
      // Shifts > 20 should be handled in 13C step and not erroneously mapped to aliphatic protons
      final step3 = res.steps[2].content;
      expect(step3, contains('δ 2.60 ppm'));
      expect(step3, isNot(contains('δ 198.10 ppm')));
      final step4 = res.steps[3].content;
      expect(step4, contains('198.1'));
    });

    test('All 8 analytical techniques are registered with detailed X/Y guides', () {
      final techs = SpectroscopyService.analyticalTechniques;
      expect(techs.length, equals(8));

      final ids = techs.map((t) => t.id).toList();
      expect(ids, containsAll(['gc', 'hplc', 'tlc', 'ms', '1h_nmr', '13c_nmr', 'ftir', 'uv_vis']));

      for (final t in techs) {
        expect(t.xAxisName.isNotEmpty, isTrue);
        expect(t.xAxisUnit.isNotEmpty, isTrue);
        expect(t.xAxisPhysicalMeaning.isNotEmpty, isTrue);
        expect(t.yAxisName.isNotEmpty, isTrue);
        expect(t.yAxisPhysicalMeaning.isNotEmpty, isTrue);
        expect(t.howToRead.isNotEmpty, isTrue);
        expect(t.keyFormulas.isNotEmpty, isTrue);
        expect(t.examples.isNotEmpty, isTrue);
        final ex = t.examples.first;
        expect(ex.peaks.isNotEmpty, isTrue);
      }
    });

    test('13C DEPT multiplicity signals correctly report CH3, CH2, CH, Cq', () {
      final signals = [
        const CarbonSignal(shift: 14.1, deptType: CarbonDeptType.ch3),
        const CarbonSignal(shift: 22.5, deptType: CarbonDeptType.ch2),
        const CarbonSignal(shift: 35.2, deptType: CarbonDeptType.ch),
        const CarbonSignal(shift: 172.0, deptType: CarbonDeptType.cq),
      ];

      final res = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C4H8O2',
        carbonSignals: signals,
      );

      expect(res.isValid, isTrue);
      expect(res.markdownFull, contains('CH₃ Carbons'));
      expect(res.markdownFull, contains('CH₂ Carbons'));
      expect(res.markdownFull, contains('CH Carbons'));
      expect(res.markdownFull, contains('Quaternary C_q Carbons'));
    });
  });
}
