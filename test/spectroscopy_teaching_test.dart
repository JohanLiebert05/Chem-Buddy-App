import 'package:chem_buddy/core/chemistry/spectrum_svg_renderer.dart';
import 'package:chem_buddy/data/services/spectroscopy_service.dart';
import 'package:chem_buddy/data/services/spectroscopy_teaching_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test(
    'walkthrough substitutes the actual formula and preserves missing evidence',
    () {
      final result = SpectroscopyService.analyzeSpectraStructured(
        formula: 'C8H8O',
      );
      final steps = SpectroscopyTeachingService.explain(
        result: result,
        observed: {},
      );
      expect(steps, hasLength(8));
      expect(steps[1].explanation, contains('2 × 8 + 2 + 0 − 8 − 0'));
      expect(steps[1].explanation, contains('5.0'));
      expect(steps[3].explanation, contains('No carbon spectrum'));
      expect(
        steps.last.explanation,
        contains('does not yet support one exact structure'),
      );
      expect(steps.every((s) => s.mscCheckpoint.isNotEmpty), isTrue);
    },
  );
  test('entered carbon evidence leads to carbonyl explanation without inventing integrals', () {
    final result = SpectroscopyService.analyzeSpectraStructured(
      formula: 'C3H6O',
      nmr13CPeaks: [29.8, 206],
    );
    final steps = SpectroscopyTeachingService.explain(
      result: result,
      observed: {
        SpectrumTechnique.carbon: [
          const SpectrumSignal(position: 29.8),
          const SpectrumSignal(position: 206),
        ],
      },
    );
    expect(steps[3].explanation, contains('206.00 ppm'));
    expect(steps[3].explanation, contains('carbonyl'));
    expect(steps[4].explanation, contains('does not supply'));
    expect(steps[6].mscCheckpoint, contains('not an exhaustive isomer search'));
  });
}
