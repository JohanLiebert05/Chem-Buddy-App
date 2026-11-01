import '../../core/chemistry/spectrum_svg_renderer.dart';
import 'spectroscopy_service.dart';

/// Converts curated textual assignments into typed resonances for plotting.
/// No invented resonances, integration or couplings are added when absent.
class SpectroscopyReferenceService {
  static List<SpectrumSignal> signals(
    SpectroscopyCompoundEntry compound,
    SpectrumTechnique technique,
  ) {
    final lines = switch (technique) {
      SpectrumTechnique.proton => compound.nmr1H,
      SpectrumTechnique.carbon => compound.nmr13C,
      SpectrumTechnique.ir => compound.diagnosticIr,
      SpectrumTechnique.mass => compound.msFragmentation,
    };
    final result = <SpectrumSignal>[];
    for (final line in lines) {
      final prefix = switch (technique) {
        SpectrumTechnique.proton || SpectrumTechnique.carbon => RegExp(
          r'δ\s*([^p(]+)',
        ).firstMatch(line)?.group(1),
        SpectrumTechnique.ir => RegExp(
          r'^([\d.,\s&–-]+)\s*cm',
        ).firstMatch(line)?.group(1),
        SpectrumTechnique.mass => RegExp(
          r'm/z\s*([\d.]+(?:\s*&\s*[\d.]+)?)',
        ).firstMatch(line)?.group(1),
      };
      if (prefix == null) continue;
      final normalized = prefix.trim().replaceAll(RegExp(r'\s*[–-]\s*'), '–');
      final positions = <double>[];
      for (final part in normalized.split(RegExp(r'[,\s&]+'))) {
        final range = part.split('–');
        if (range.length == 2 &&
            range.every((v) => double.tryParse(v) != null)) {
          positions.add(
            (double.parse(range.first) + double.parse(range.last)) / 2,
          );
        } else if (double.tryParse(part) case final value?) {
          positions.add(value);
        }
      }
      final integration = technique == SpectrumTechnique.proton
          ? int.tryParse(RegExp(r'(\d+)H\b').firstMatch(line)?.group(1) ?? '')
          : null;
      final multiplicity = technique == SpectrumTechnique.proton
          ? (RegExp(r'\(([^,;)]+)').firstMatch(line)?.group(1)?.trim() ?? '')
          : '';
      final couplingMatch = RegExp(r'J\s*=\s*([\d.,\s]+)\s*Hz')
          .firstMatch(line);
      final coupling = couplingMatch == null
          ? <double>[]
          : [
              for (final match in RegExp(
                r'\d+(?:\.\d+)?',
              ).allMatches(couplingMatch.group(1)!))
                double.parse(match.group(0)!),
            ];
      final intensity = technique == SpectrumTechnique.mass
          ? double.tryParse(
              RegExp(r'(\d+(?:\.\d+)?)\s*%').firstMatch(line)?.group(1) ?? '',
            )
          : null;
      for (final position in positions) {
        result.add(
          SpectrumSignal(
            position: position,
            assignment: line,
            integration: integration,
            multiplicity: multiplicity,
            couplingsHz: coupling,
            relativeIntensity: intensity,
            broad:
                line.toLowerCase().contains('broad') ||
                multiplicity.contains('br'),
          ),
        );
      }
    }
    return result;
  }

  static List<SpectroscopyCompoundEntry> formulaOptions(String formula) {
    final f = SpectroscopyService.parseFormula(formula);
    if (!f.isValid) return [];
    return SpectroscopyService.curatedCompoundDatabase.where((entry) {
      final other = SpectroscopyService.parseFormula(
        entry.formula.replaceAll('BR', 'Br').replaceAll('CL', 'Cl'),
      );
      return other.isValid &&
          [
                f.carbons,
                f.hydrogens,
                f.nitrogens,
                f.oxygens,
                f.chlorines,
                f.bromines,
                f.fluorines,
                f.iodines,
                f.sulfurs,
                f.phosphoruses,
              ].join(',') ==
              [
                other.carbons,
                other.hydrogens,
                other.nitrogens,
                other.oxygens,
                other.chlorines,
                other.bromines,
                other.fluorines,
                other.iodines,
                other.sulfurs,
                other.phosphoruses,
              ].join(',');
    }).toList();
  }
}
