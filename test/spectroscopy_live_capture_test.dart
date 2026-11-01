import 'dart:convert';
import 'dart:io';

import 'package:chem_buddy/core/chemistry/spectrum_svg_renderer.dart';
import 'package:chem_buddy/data/services/spectroscopy_prediction_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

// Replays captured public chemistry responses. This test makes no API requests
// and does not establish measured chemical-shift accuracy.
void main() {
  final captures = jsonDecode(File('test/fixtures/gemini_live_2026_11_01.json')
      .readAsStringSync()) as List;
  for (final capture in captures) {
    testWidgets('captured Gemini response: ${capture['name']}', (tester) async {
      final prediction = SpectroscopyPredictionService.parse(
        capture['text'] as String,
        SpectroscopyPredictionRequest(
          compound: capture['smiles'] as String,
          kind: CompoundInputKind.smiles,
        ),
        model: capture['model'] as String,
      );
      expect(prediction.compound.formula, capture['formula']);
      final plots = [
        prediction.depiction.svg!,
        SpectrumSvgRenderer.render(
          technique: SpectrumTechnique.proton,
          expected: prediction.proton.map((s) => s.signal).toList(),
          showObserved: false,
          compact: true,
        ),
        SpectrumSvgRenderer.render(
          technique: SpectrumTechnique.carbon,
          expected: prediction.carbon.map((s) => s.signal).toList(),
          showObserved: false,
          compact: true,
        ),
      ];
      await tester.pumpWidget(MaterialApp(home: Scaffold(body: Column(
        children: [for (final svg in plots)
          Expanded(child: SvgPicture.string(svg))],
      ))));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  }
}
