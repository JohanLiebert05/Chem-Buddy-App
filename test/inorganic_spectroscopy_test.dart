import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/inorganic_spectroscopy_service.dart';

void main() {
  group('InorganicSpectroscopyService Tests', () {
    test('calculateRacahOctahedralD8 calculates 10Dq, Racah B, and beta accurately', () {
      // [Ni(H2O)6]2+: nu1 = 8500 cm^-1, nu2 = 13800 cm^-1, nu3 = 25300 cm^-1
      final result = InorganicSpectroscopyService.calculateRacahOctahedralD8(
        nu1: 8500.0,
        nu2: 13800.0,
        nu3: 25300.0,
        b0: 1030.0,
        complexName: '[Ni(H₂O)₆]²⁺',
      );

      // 10Dq = nu1 = 8500
      expect(result.tenDq, equals(8500.0));
      // 15B = nu2 + nu3 - 3*nu1 = 13800 + 25300 - 25500 = 13600 => B = 906.67
      expect(result.bComplex, closeTo(906.67, 0.05));
      expect(result.bFreeIon, equals(1030.0));
      // beta = 906.67 / 1030 = 0.8803
      expect(result.beta, closeTo(0.8803, 0.001));
      // Nephelauxetic % = (1 - beta) * 100 = 11.97%
      expect(result.nephelauxeticPercentage, closeTo(11.97, 0.1));
      expect(result.racahC, closeTo(4.0 * 906.67, 1.0));
      expect(result.groundStateTerm, equals('^3A_{2g}'));
      expect(result.transitionTerms.length, equals(3));
      expect(result.derivationKaTeX, contains('10Dq = 8500.0'));
      expect(result.derivationKaTeX, contains('Racah Interelectronic Repulsion Parameter'));
    });

    test('calculateMagneticMoment calculates spin-only and spin-orbit corrected moments', () {
      // Ni2+ d8 Oh High Spin: 2 unpaired electrons, muSO = sqrt(8) = 2.828 BM
      // lambda = -315 cm^-1, 10Dq = 8500 cm^-1, alpha = 4
      final niResult = InorganicSpectroscopyService.calculateMagneticMoment(
        dElectrons: 8,
        geometry: 'Oh',
        isHighSpin: true,
        lambda: -315.0,
        tenDq: 8500.0,
        temperatureKelvin: 298.0,
      );

      expect(niResult.unpairedElectrons, equals(2));
      expect(niResult.spinOnlyMoment, closeTo(2.828, 0.002));
      // mu_eff = 2.828 * (1 - (4 * -315 / 8500)) = 2.828 * (1 + 0.1482) = 3.247 BM
      expect(niResult.effectiveMoment, greaterThan(niResult.spinOnlyMoment));
      expect(niResult.effectiveMoment, closeTo(3.247, 0.05));
      expect(niResult.groundTerm, equals('^3A_{2g}'));
      expect(niResult.susceptibilityChiM, isNotNull);

      // Cr3+ d3 Oh: 3 unpaired electrons, muSO = sqrt(15) = 3.873 BM
      // lambda = +92 cm^-1 (> 0, less than half filled d shell), muEff < muSO
      final crResult = InorganicSpectroscopyService.calculateMagneticMoment(
        dElectrons: 3,
        geometry: 'Oh',
        isHighSpin: true,
        lambda: 92.0,
        tenDq: 17400.0,
      );

      expect(crResult.unpairedElectrons, equals(3));
      expect(crResult.spinOnlyMoment, closeTo(3.873, 0.002));
      expect(crResult.effectiveMoment, lessThan(crResult.spinOnlyMoment));
      expect(crResult.effectiveMoment, closeTo(3.791, 0.05));

      // Fe2+ d6 Oh Low Spin: 0 unpaired electrons, diamagnetic
      final feLowSpin = InorganicSpectroscopyService.calculateMagneticMoment(
        dElectrons: 6,
        geometry: 'Oh',
        isHighSpin: false,
      );
      expect(feLowSpin.unpairedElectrons, equals(0));
      expect(feLowSpin.spinOnlyMoment, equals(0.0));
      expect(feLowSpin.effectiveMoment, equals(0.0));
    });

    test('calculateEprGFactor calculates resonance condition and hyperfine lines', () {
      // X-band nu = 9.50 GHz, B = 3300 Gauss
      final epr = InorganicSpectroscopyService.calculateEprGFactor(
        frequencyGhz: 9.50,
        magneticFieldGauss: 3300.0,
        nuclearSpinDouble: 3, // Cu-63 I = 3/2 => 2*I = 3
        numberOfCoupledNuclei: 1,
        superHyperfineSpinDouble: 2, // 14N I = 1 => 2*I = 2
        numberOfLigands: 2, // 2 equivalent nitrogens => 2 * 2 * 1 + 1 = 5
      );

      // g = 714.484 * 9.5 / 3300 = 2.0568
      expect(epr.gFactor, closeTo(2.0568, 0.001));
      // Cu lines: 2*1*(3/2) + 1 = 4 lines
      // N lines: 2*2*(1) + 1 = 5 lines
      // Total lines = 4 * 5 = 20 lines
      expect(epr.totalHyperfineLines, equals(20));
      expect(epr.isKramersDegenerate, isTrue);
      expect(epr.derivationKaTeX, contains('Landé \$g\$-factor'));
      expect(epr.derivationKaTeX, contains(r'20\text{ lines}'));
    });

    test('diagnoseMossbauerFe correctly identifies oxidation and spin states', () {
      // High-spin Fe(II): delta ~ 1.30 mm/s, Delta E_Q ~ 2.80 mm/s
      final fe2High = InorganicSpectroscopyService.diagnoseMossbauerFe(
        isomerShift: 1.30,
        quadrupoleSplitting: 2.80,
      );
      expect(fe2High.oxidationState, contains('Fe(II)'));
      expect(fe2High.spinState, contains('High Spin'));
      expect(fe2High.electronicConfiguration, equals('t_{2g}^4 e_g^2'));

      // High-spin Fe(III): delta ~ 0.70 mm/s, Delta E_Q ~ 0.30 mm/s
      final fe3High = InorganicSpectroscopyService.diagnoseMossbauerFe(
        isomerShift: 0.70,
        quadrupoleSplitting: 0.30,
      );
      expect(fe3High.oxidationState, contains('Fe(III)'));
      expect(fe3High.spinState, contains('High Spin'));
      expect(fe3High.electronicConfiguration, equals('t_{2g}^3 e_g^2'));

      // Low-spin Fe(III): delta ~ 0.35 mm/s, Delta E_Q ~ 2.00 mm/s
      final fe3Low = InorganicSpectroscopyService.diagnoseMossbauerFe(
        isomerShift: 0.35,
        quadrupoleSplitting: 2.00,
      );
      expect(fe3Low.oxidationState, contains('Fe(III)'));
      expect(fe3Low.spinState, contains('Low Spin'));
      expect(fe3Low.electronicConfiguration, equals('t_{2g}^5 e_g^0'));

      // Low-spin Fe(II) / Nitroprusside: delta ~ 0.05 mm/s
      final fe2Low = InorganicSpectroscopyService.diagnoseMossbauerFe(
        isomerShift: 0.05,
        quadrupoleSplitting: 0.10,
      );
      expect(fe2Low.oxidationState, contains('Fe(II)'));
      expect(fe2Low.spinState, contains('Low Spin'));
      expect(fe2Low.electronicConfiguration, equals('t_{2g}^6 e_g^0'));
    });

    test('predictCarbonylIrModes enforces group theory and mutual exclusion rules', () {
      // M(CO)6: Oh symmetry, 1 IR band (T1u), 2 Raman bands
      final oh = InorganicSpectroscopyService.predictCarbonylIrModes(complexType: 'M(CO)6');
      expect(oh.pointGroup, equals('O_h'));
      expect(oh.irActiveBands, equals(1));
      expect(oh.ramanActiveBands, equals(2));
      expect(oh.irSymmetries, contains('T_{1u} (Very Strong)'));

      // M(CO)5L: C4v symmetry, 3 IR bands (2A1 + E)
      final c4v = InorganicSpectroscopyService.predictCarbonylIrModes(complexType: 'M(CO)5L');
      expect(c4v.pointGroup, equals('C_{4v}'));
      expect(c4v.irActiveBands, equals(3));
      expect(c4v.irSymmetries, contains('2A_1'));

      // trans-M(CO)4L2: D4h symmetry with inversion center, 1 IR band (Eu)
      final transIso = InorganicSpectroscopyService.predictCarbonylIrModes(complexType: 'trans-M(CO)4L2');
      expect(transIso.pointGroup, equals('D_{4h}'));
      expect(transIso.irActiveBands, equals(1));

      // cis-M(CO)4L2: C2v symmetry without inversion center, 4 IR bands
      final cisIso = InorganicSpectroscopyService.predictCarbonylIrModes(complexType: 'cis-M(CO)4L2');
      expect(cisIso.pointGroup, equals('C_{2v}'));
      expect(cisIso.irActiveBands, equals(4));

      // fac-M(CO)3L3: C3v symmetry, 2 IR bands (A1 + E)
      final facIso = InorganicSpectroscopyService.predictCarbonylIrModes(complexType: 'fac-M(CO)3L3');
      expect(facIso.pointGroup, equals('C_{3v}'));
      expect(facIso.irActiveBands, equals(2));

      // mer-M(CO)3L3: C2v symmetry, 3 IR bands (2A1 + B1)
      final merIso = InorganicSpectroscopyService.predictCarbonylIrModes(complexType: 'mer-M(CO)3L3');
      expect(merIso.pointGroup, equals('C_{2v}'));
      expect(merIso.irActiveBands, equals(3));
    });

    test('examProblems collection contains comprehensive postgraduate questions', () {
      final problems = InorganicSpectroscopyService.curated10MarkProblems;
      expect(problems.length, greaterThanOrEqualTo(5));

      for (final prob in problems) {
        expect(prob.id, isNotEmpty);
        expect(prob.title, isNotEmpty);
        expect(prob.universityExam, isNotEmpty);
        expect(prob.rubricMarkDistribution.values.fold(0, (a, b) => a + b), equals(10));
        expect(prob.fullKaTeXSolution, contains('Model 10/10'));
        expect(prob.takeawayPoints, isNotEmpty);
      }
    });
  });
}
