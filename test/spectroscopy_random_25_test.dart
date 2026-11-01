import 'dart:convert';
import 'dart:io';

import 'package:chem_buddy/core/chemistry/spectroscopy_structure_svg.dart';
import 'package:chem_buddy/core/chemistry/spectrum_svg_renderer.dart';
import 'package:chem_buddy/data/services/spectroscopy_prediction_benchmark.dart';
import 'package:chem_buddy/data/services/spectroscopy_reference_service.dart';
import 'package:chem_buddy/data/services/spectroscopy_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

void main() {
  final sample = SpectroscopyPredictionBenchmark.sample();
  final report = <Map<String, dynamic>>[];
  final html = StringBuffer(
    '''<!doctype html><meta charset="utf-8"><meta name="viewport" content="width=device-width,initial-scale=1"><title>25-molecule spectroscopy simulation</title><style>body{font:16px system-ui;background:#f4f7fa;color:#172033;max-width:1100px;margin:auto;padding:24px}article{background:white;border:1px solid #d9e1ea;border-radius:16px;padding:20px;margin:24px 0}svg{width:100%;height:auto}code{overflow-wrap:anywhere}.plots{display:grid;grid-template-columns:repeat(auto-fit,minmax(280px,1fr));gap:12px}</style><h1>25-molecule spectroscopy simulation</h1><p>Seed: 35625. Twenty-five unique molecular formulas, each paired with a specified structure and the app’s curated NMR reference data. This is an <strong>offline reference/rendering check, not a live Gemini accuracy benchmark</strong>. A molecular formula alone does not determine one isomer. Reference values are educational; they are not independently measured here.</p>''',
  );
  test('sample contains 25 unique formulas and is reproducible', () {
    expect(sample, hasLength(25));
    expect(sample.map((c) => c.formula).toSet(), hasLength(25));
    expect(
      SpectroscopyPredictionBenchmark.sample().map((c) => c.smiles),
      sample.map((c) => c.smiles),
    );
  });
  for (final entry in sample.indexed) {
    final compound = entry.$2;
    testWidgets(
      'random ${entry.$1 + 1}/25: ${compound.commonName} ${compound.formula}',
      (tester) async {
        final formula = compound.formula
            .replaceAll('BR', 'Br')
            .replaceAll('CL', 'Cl');
        final parsed = SpectroscopyService.parseFormula(formula);
        expect(parsed.isValid, isTrue);
        expect(parsed.dbe, compound.dbe);
        expect(
          SpectroscopyService.analyzeSpectraStructured(formula: formula)
              .supportedCompound,
          isNull,
          reason: 'Formula alone cannot identify a compound.',
        );
        final h = SpectroscopyReferenceService.signals(
          compound,
          SpectrumTechnique.proton,
        );
        final c = SpectroscopyReferenceService.signals(
          compound,
          SpectrumTechnique.carbon,
        );
        final result = SpectroscopyService.analyzeSpectraStructured(
          formula: formula,
          nmr1HPeaks: h.map((s) => s.position).toList(),
          nmr13CPeaks: c.map((s) => s.position).toList(),
        );
        expect(
          result.supportedCompound == null ||
              result.supportedCompound!.smiles == compound.smiles,
          isTrue,
          reason: 'Do not assign a wrong isomer.',
        );
        final drawing = SpectroscopyStructureSvg.depict(compound);
        expect(drawing.error, isNull);
        expect(drawing.graph, isNotNull);
        expect(
          drawing.graph!.atoms.where((a) => a.element == 'C'),
          hasLength(parsed.carbons),
        );
        expect(
          drawing.graph!.atoms.fold(0, (sum, a) => sum + a.implicitHydrogens),
          parsed.hydrogens,
        );
        final hSvg = SpectrumSvgRenderer.render(
          technique: SpectrumTechnique.proton,
          expected: h,
          showObserved: false,
        compact: true,
        );
        final cSvg = SpectrumSvgRenderer.render(
          technique: SpectrumTechnique.carbon,
          expected: c,
          showObserved: false,
        compact: true,
        );
        for (final svg in [drawing.svg!, hSvg, cSvg]) {
          expect(svg, startsWith('<svg'));
          expect(svg.trim(), endsWith('</svg>'));
          expect(svg, contains('http://www.w3.org/2000/svg'));
          expect(svg, contains('viewBox='));
          expect(svg, isNot(contains('NaN')));
          expect(svg, isNot(contains('Infinity')));
        }
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Column(
                children: [
                  for (final svg in [drawing.svg!, hSvg, cSvg])
                    SizedBox(height: 150, child: SvgPicture.string(svg)),
                ],
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        expect(
          tester.takeException(),
          isNull,
          reason: 'All three SVGs must parse and render.',
        );
        report.add({
          'compound': compound.commonName,
          'formula': formula,
          'smiles': compound.smiles,
          'dbe': parsed.dbe,
          'formula_only': 'unresolved as required',
          'reference_match':
              result.supportedCompound?.commonName ?? 'ambiguous / withheld',
          'proton_reference_ppm': h.map((s) => s.position).toList(),
          'carbon_reference_ppm': c.map((s) => s.position).toList(),
          'svg_structure_inventory': 'passed',
          'live_gemini_tested': false,
        });
        html.write(
          '<article><h2>${entry.$1 + 1}. ${SpectrumSvgRenderer.escape(compound.commonName)}</h2><p>$formula • DBE ${parsed.dbe}</p><code>${SpectrumSvgRenderer.escape(compound.smiles)}</code><p>Formula and SVG atom inventory: passed. Formula-only assignment: unresolved.</p><div class="plots">${drawing.svg}$hSvg$cSvg</div></article>',
        );
      },
    );
  }
  tearDownAll(() {
    if (const bool.fromEnvironment('WRITE_SPECTROSCOPY_REPORT')) {
      Directory('build/spectroscopy-review').createSync(recursive: true);
      File(
        'build/spectroscopy-review/random-25-report.json',
      ).writeAsStringSync(const JsonEncoder.withIndent('  ').convert(report));
      File('build/spectroscopy-review/random-25-report.html')
          .writeAsStringSync(html.toString());
    }
  });
}
