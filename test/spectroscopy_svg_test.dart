import 'package:chem_buddy/core/chemistry/chemical_graph.dart';
import 'package:chem_buddy/core/chemistry/spectroscopy_graph_layout.dart';
import 'package:chem_buddy/core/chemistry/spectroscopy_structure_svg.dart';
import 'package:chem_buddy/core/chemistry/spectrum_svg_renderer.dart';
import 'package:chem_buddy/data/services/spectroscopy_reference_service.dart';
import 'package:chem_buddy/data/services/spectroscopy_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  SpectroscopyCompoundEntry compound(String name) => SpectroscopyService
      .curatedCompoundDatabase
      .firstWhere((c) => c.commonName.startsWith(name));

  test('reference proton values preserve integration, multiplicity and J', () {
    final signals = SpectroscopyReferenceService.signals(
      compound('Acetophenone'),
      SpectrumTechnique.proton,
    );
    expect(signals.map((s) => s.position), [2.6, 7.45, 7.55, 7.95]);
    expect(signals.map((s) => s.integration), [3, 2, 1, 2]);
    expect(signals.first.multiplicity, 's');
    expect(signals.last.multiplicity, 'd');
    expect(signals.last.couplingsHz, [8.0]);
  });

  test(
    'reference 13C positions do not include carbon counts or assignments',
    () {
      final signals = SpectroscopyReferenceService.signals(
        compound('Acetophenone'),
        SpectrumTechnique.carbon,
      );
      expect(signals.map((s) => s.position), [
        198.1,
        137.1,
        133.1,
        128.5,
        128.3,
        26.6,
      ]);
      expect(
        signals.every((s) => s.integration == null && s.couplingsHz.isEmpty),
        isTrue,
      );
    },
  );

  test('MS isotope doublets and percent intensities are separate fields', () {
    final bromine = SpectroscopyReferenceService.signals(
      compound('1-Bromopropane'),
      SpectrumTechnique.mass,
    );
    expect(bromine.take(2).map((s) => s.position), [122, 124]);
    final acetophenone = SpectroscopyReferenceService.signals(
      compound('Acetophenone'),
      SpectrumTechnique.mass,
    );
    expect(acetophenone.first.position, 120);
    expect(acetophenone.first.relativeIntensity, 30);
  });

  test('first-order triplet uses Pascal ratios and J divided by frequency', () {
    const signal = SpectrumSignal(
      position: 1.2,
      multiplicity: 't',
      couplingsHz: [7],
    );
    final lines = SpectrumSvgRenderer.lines(signal, frequencyMhz: 400);
    expect(lines.map((l) => l.weight), [.25, .5, .25]);
    expect(lines[1].position, closeTo(1.2, 1e-9));
    expect(lines[1].position - lines[0].position, closeTo(7 / 400, 1e-9));
    final highField = SpectrumSvgRenderer.lines(signal, frequencyMhz: 800);
    expect(
      highField[1].position - highField[0].position,
      closeTo(7 / 800, 1e-9),
    );
  });

  test('doublet of doublets requires two J values and does not invent one', () {
    expect(
      SpectrumSvgRenderer.lines(
        const SpectrumSignal(
          position: 7.4,
          multiplicity: 'dd',
          couplingsHz: [8, 2],
        ),
      ).length,
      4,
    );
    expect(
      SpectrumSvgRenderer.lines(
        const SpectrumSignal(
          position: 7.4,
          multiplicity: 'dd',
          couplingsHz: [8],
        ),
      ).length,
      1,
    );
    expect(
      () => SpectrumSvgRenderer.lines(
        const SpectrumSignal(position: 1),
        frequencyMhz: 0,
      ),
      throwsArgumentError,
    );
  });

  test('NMR and IR coordinate axes decrease from left to right', () {
    final nmr = SpectrumSvgRenderer.render(
      technique: SpectrumTechnique.carbon,
      observed: const [
        SpectrumSignal(position: 200),
        SpectrumSignal(position: 20),
      ],
    );
    final observed = nmr.split('<g id="observed"').last.split('</g>').first;
    final x = RegExp(r'<line x1="([\d.]+)"')
        .allMatches(observed)
        .map((m) => double.parse(m.group(1)!))
        .toList();
    expect(x.length, 2);
    expect(x.first, lessThan(x.last));
    final ir = SpectrumSvgRenderer.render(technique: SpectrumTechnique.ir);
    expect(ir, contains('>4000</text>'));
    expect(ir, contains('>400</text>'));
    expect(ir, contains('Transmittance'));
  });

  test(
    'SVG traces can be independently toggled without fabricating expected data',
    () {
      final svg = SpectrumSvgRenderer.render(
        technique: SpectrumTechnique.proton,
        observed: const [SpectrumSignal(position: 2.6)],
        expected: const [SpectrumSignal(position: 2.55)],
        showObserved: false,
      );
      expect(svg, contains('id="expected"'));
      expect(svg, isNot(contains('id="observed"')));
      final unknown = SpectrumSvgRenderer.render(
        technique: SpectrumTechnique.proton,
        observed: const [SpectrumSignal(position: 2.6)],
      );
      expect(unknown, isNot(contains('id="expected"')));
      expect(unknown, contains('Reconstructed from peak lists'));
    },
  );

  test(
    'every library compound supplies typed proton and carbon resonances',
    () {
      for (final entry in SpectroscopyService.curatedCompoundDatabase) {
        expect(
          SpectroscopyReferenceService.signals(entry, SpectrumTechnique.proton),
          isNotEmpty,
          reason: entry.commonName,
        );
        expect(
          SpectroscopyReferenceService.signals(entry, SpectrumTechnique.carbon),
          isNotEmpty,
          reason: entry.commonName,
        );
      }
    },
  );

  test('formula lookup presents isomers without choosing one', () {
    final options = SpectroscopyReferenceService.formulaOptions('C8H8O3');
    expect(
      options.map((c) => c.commonName),
      containsAll(['Vanillin', 'Methyl Salicylate']),
    );
    expect(SpectroscopyReferenceService.formulaOptions('bad'), isEmpty);
  });

  test(
    'structure SVG depicts actual acetophenone with carbonyl oxygen, not OH',
    () {
      final depiction = SpectroscopyStructureSvg.depict(
        compound('Acetophenone'),
      );
      expect(depiction.error, isNull);
      final graph = depiction.graph!;
      expect(graph.atoms.where((a) => a.element == 'C').length, 8);
      expect(
        graph.atoms.where((a) => a.element == 'O').single.implicitHydrogens,
        0,
      );
      expect(graph.atoms.fold<int>(0, (n, a) => n + a.implicitHydrogens), 8);
      expect(graph.bonds.where((b) => b.type == BondType.aromatic).length, 6);
      expect(graph.bonds.where((b) => b.type == BondType.double).length, 1);
      expect(depiction.svg, contains('<svg'));
    },
  );

  test('every supplied solver example passes depiction formula validation', () {
    for (final name in [
      'Acetophenone',
      'Benzocaine',
      '1-Bromopropane',
      '2-Bromopropane',
      'Ethyl Propionate',
      'Vanillin',
      'Aspirin',
      'Benzophenone',
      'Ethanol',
    ]) {
      final depiction = SpectroscopyStructureSvg.depict(compound(name));
      expect(depiction.error, isNull, reason: '$name: ${depiction.error}');
      expect(depiction.svg, isNotNull);
    }
  });

  test('all selectable references pass molecular formula validation before drawing', () {
    for (final entry in SpectroscopyService.curatedCompoundDatabase) {
      final depiction = SpectroscopyStructureSvg.depict(entry);
      expect(
        depiction.error,
        isNull,
        reason: '${entry.commonName}: ${depiction.error}',
      );
    }
  });

  test('separate and fused aromatic rings retain regular bond geometry', () {
    for (final name in ['Benzophenone', 'Naphthalene', 'Anthracene']) {
      final graph = SpectroscopyStructureSvg.depict(compound(name)).graph!;
      for (final ring in SpectroscopyGraphLayout.rings(graph)) {
        for (var i = 0; i < ring.length; i++) {
          final a = graph.getAtom(ring[i])!;
          final b = graph.getAtom(ring[(i + 1) % ring.length])!;
          final lengthSquared =
              (a.x - b.x) * (a.x - b.x) + (a.y - b.y) * (a.y - b.y);
          expect(
            lengthSquared,
            closeTo(42 * 42, 0.001),
            reason: '$name ring geometry',
          );
        }
      }
    }
  });
}
