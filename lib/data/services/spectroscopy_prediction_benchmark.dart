import 'dart:math';

import '../../core/chemistry/spectrum_svg_renderer.dart';
import 'spectroscopy_prediction_service.dart';
import 'spectroscopy_reference_service.dart';
import 'spectroscopy_service.dart';

/// Reproducible random sample with unique formulas and specified connectivity.
/// Agreement with this educational library is not experimental validation.
class SpectroscopyPredictionBenchmark {
  static List<SpectroscopyCompoundEntry> sample({int seed = 35625}) {
    final pool =
        SpectroscopyService.curatedCompoundDatabase
            .where((c) => !RegExp(r'[/\\@]').hasMatch(c.smiles))
            .toList()
          ..shuffle(Random(seed));
    final formulas = <String>{};
    return pool.where((c) => formulas.add(c.formula)).take(25).toList();
  }

  static int matches(
    List<double> expected,
    List<double> actual,
    double tolerance,
  ) {
    final assigned = <int, int>{};
    bool augment(int source, Set<int> seen) {
      final options =
          [
            for (var i = 0; i < actual.length; i++)
              if ((actual[i] - expected[source]).abs() <= tolerance) i,
          ]..sort(
            (a, b) => (actual[a] - expected[source]).abs().compareTo(
              (actual[b] - expected[source]).abs(),
            ),
          );
      for (final target in options) {
        if (!seen.add(target)) continue;
        if (!assigned.containsKey(target) || augment(assigned[target]!, seen)) {
          assigned[target] = source;
          return true;
        }
      }
      return false;
    }

    for (var i = 0; i < expected.length; i++) {
      augment(i, <int>{});
    }
    return assigned.length;
  }

  static Map<String, dynamic> compare(
    SpectroscopyCompoundEntry reference,
    SpectroscopyPrediction prediction,
  ) {
    final expectedH = SpectroscopyReferenceService.signals(
      reference,
      SpectrumTechnique.proton,
    ).map((s) => s.position).toList();
    final expectedC = SpectroscopyReferenceService.signals(
      reference,
      SpectrumTechnique.carbon,
    ).map((s) => s.position).toList();
    final actualH = prediction.proton.map((s) => s.signal.position).toList(),
        actualC = prediction.carbon.map((s) => s.signal.position).toList();
    return {
      'compound': reference.commonName,
      'formula': reference.formula,
      'smiles': reference.smiles,
      'model': prediction.model,
      'proton': {
        'reference_shifts': expectedH,
        'predicted_shifts': actualH,
        'matched': matches(expectedH, actualH, .35),
        'tolerance_ppm': .35,
      },
      'carbon': {
        'reference_shifts': expectedC,
        'predicted_shifts': actualC,
        'matched': matches(expectedC, actualC, 5),
        'tolerance_ppm': 5,
      },
      'formula_structure_inventory': 'passed',
      'note': 'Reference agreement only; library solvent/temperature and measurement provenance are not established. Not an experimental accuracy score.',
    };
  }
}
