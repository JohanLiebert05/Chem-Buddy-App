import 'package:chem_buddy/data/services/elemental_composition_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('user example flags its missing nine percent', () {
    final input = ElementalCompositionService.parseQuestion(
      '47 percent carbon, 8 pecent of hydrogen, 36 percent of oxygen',
    );
    expect(input.error, isNull);
    expect(input.percentages, {'C': 47, 'H': 8, 'O': 36});
    final result = ElementalCompositionService.solve(
      percentages: input.percentages,
    );
    expect(result.isValid, isFalse);
    expect(result.message, contains('91.00%'));
    expect(result.message, contains('9.00% is unaccounted'));
    expect(result.molecularCandidates, isEmpty);
  });

  test('reads element-first, percent-first and mixed question formats', () {
    for (final question in [
      'C 40%, H 6.71%, O 53.29%',
      '40% carbon, 6.71% hydrogen, 53.29% oxygen',
      '40% C; H = 6.71%; oxygen: 53.29%',
      'C 40% H 6.71% O 53.29%',
    ]) {
      final parsed = ElementalCompositionService.parseQuestion(question);
      expect(parsed.error, isNull, reason: question);
      expect(parsed.percentages, {
        'C': 40,
        'H': 6.71,
        'O': 53.29,
      }, reason: question);
    }
    final parsed = ElementalCompositionService.parseQuestion(
      '40% carbon, 6.71% hydrogen, 53.29% oxygen. Molar mass is 180.16 g/mol.',
    );
    expect(parsed.molarMass, 180.16);
  });

  test('duplicate, unknown or unassigned percentages are rejected', () {
    for (final question in [
      '40% carbon, 40% C',
      '40% Na, 60% carbon',
      '40% carbon, 60% unknown',
      'carbon and hydrogen',
      '40%',
    ]) {
      expect(
        ElementalCompositionService.parseQuestion(question).error,
        isNotNull,
        reason: question,
      );
    }
  });

  test(
    'same empirical composition gives different molecules only with mass',
    () {
      final values = {'C': 40.0, 'H': 6.71, 'O': 53.29};
      final empirical = ElementalCompositionService.solve(percentages: values);
      expect(empirical.isValid, isTrue);
      expect(empirical.empiricalCandidates.first.formula, 'CH2O');
      expect(empirical.molecularCandidates, isEmpty);
      for (final entry in [(60.05, 'C2H4O2'), (180.16, 'C6H12O6')]) {
        final result = ElementalCompositionService.solve(
          percentages: values,
          molarMass: entry.$1,
        );
        expect(result.isValid, isTrue);
        expect(result.molecularCandidates.single.formula, entry.$2);
      }
    },
  );

  test('fractional mole ratios become integers without rounding to a wrong formula', () {
    final result = ElementalCompositionService.solve(
      percentages: {'C': 50.0, 'H': 5.6, 'O': 44.4},
      molarMass: 72.06,
    );
    expect(result.isValid, isTrue);
    expect(result.empiricalCandidates.first.formula, 'C3H4O2');
    expect(result.molecularCandidates.single.dbe, 2);
  });

  test('benzene empirical CH is allowed without treating it as a molecule', () {
    final result = ElementalCompositionService.solve(
      percentages: {'C': 92.26, 'H': 7.74},
    );
    expect(result.isValid, isTrue);
    expect(result.empiricalCandidates.first.formula, 'CH');
    expect(result.molecularCandidates, isEmpty);
  });

  test(
    'oxygen is inferred only by explicit request and cannot be double counted',
    () {
      final data = {'C': 52.14, 'H': 13.13};
      expect(
        ElementalCompositionService.solve(
          percentages: data,
          molarMass: 46.07,
        ).isValid,
        isFalse,
      );
      final result = ElementalCompositionService.solve(
        percentages: data,
        molarMass: 46.07,
        oxygenByDifference: true,
      );
      expect(result.molecularCandidates.single.formula, 'C2H6O');
      expect(result.percentages['O'], closeTo(34.73, 1e-8));
      expect(
        ElementalCompositionService.solve(
          percentages: {...data, 'O': 34.73},
          oxygenByDifference: true,
        ).isValid,
        isFalse,
      );
    },
  );

  test('invalid totals, NaN, negative values and incompatible mass fail explicitly', () {
    for (final data in [
      {'C': -1.0, 'H': 101.0},
      {'C': double.nan},
      {'C': 120.0},
      {'C': 47.0, 'H': 8.0, 'O': 36.0},
      {'Na': 100.0},
    ]) {
      expect(
        ElementalCompositionService.solve(percentages: data).isValid,
        isFalse,
      );
    }
    final result = ElementalCompositionService.solve(
      percentages: {'C': 40, 'H': 6.71, 'O': 53.29},
      molarMass: 77,
    );
    expect(result.isValid, isFalse);
    expect(result.molecularCandidates, isEmpty);
  });

  test(
    'ambiguous measurements return multiple formulas rather than forcing one',
    () {
      final original = ElementalFormulaCandidate({
        'C': 50,
        'H': 100,
        'O': 10,
      }, 0);
      final result = ElementalCompositionService.solve(
        percentages: original.percentages,
        molarMass: original.molarMass,
        massTolerance: 3,
        percentTolerance: .5,
      );
      expect(result.isValid, isTrue);
      expect(result.molecularCandidates.length, greaterThan(1));
      expect(result.message, contains('no single answer is forced'));
    },
  );

  test('simulated CHO compositions round trip to their molecular formulas', () {
    var simulated = 0;
    for (var c = 1; c <= 10; c++) {
      for (var h = 2; h <= 2 * c + 2; h += 2) {
        for (var o = 0; o <= 5; o++) {
          final original = ElementalFormulaCandidate({
            'C': c,
            'H': h,
            if (o > 0) 'O': o,
          }, 0);
          final measured = {
            for (final e in original.percentages.entries)
              e.key: double.parse(e.value.toStringAsFixed(2)),
          };
          final result = ElementalCompositionService.solve(
            percentages: measured,
            molarMass: double.parse(original.molarMass.toStringAsFixed(2)),
            percentTolerance: .02,
            massTolerance: .05,
          );
          expect(result.isValid, isTrue, reason: original.formula);
          expect(
            result.molecularCandidates.map((c) => c.formula),
            contains(original.formula),
          );
          for (final candidate in result.molecularCandidates) {
            expect(candidate.maxPercentError, lessThanOrEqualTo(.02000001));
            expect(
              (candidate.molarMass - original.molarMass).abs(),
              lessThan(.06),
            );
          }
          simulated++;
        }
      }
    }
    expect(simulated, 390);
  });

  test('nitrogen and halogen formulas use full atom inventories', () {
    for (final atoms in [
      {'C': 3, 'H': 7, 'Br': 1},
      {'C': 6, 'H': 5, 'Cl': 1},
      {'C': 7, 'H': 7, 'N': 1, 'O': 1},
    ]) {
      final original = ElementalFormulaCandidate(atoms, 0);
      final result = ElementalCompositionService.solve(
        percentages: original.percentages,
        molarMass: original.molarMass,
        percentTolerance: .02,
        massTolerance: .05,
      );
      expect(result.molecularCandidates.single.formula, original.formula);
    }
  });
}
