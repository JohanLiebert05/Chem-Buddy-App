import 'spectroscopy_service.dart';

class SpectroscopyEvidenceGuide {
  static List<String> suggest({
    required SpectroscopyAnalysisResult result,
    required List<double> proton,
    required List<double> carbon,
    required List<double> ir,
    List<int> integrations = const [],
  }) {
    if (!result.isValid) {
      return ['Correct the input before interpreting a structure.'];
    }
    final suggestions = <String>[];
    final formula = SpectroscopyService.parseFormula(result.formula);
    if (result.sanityReport?.hasViolations == true) {
      suggestions.add(
        'Resolve the reported formula/spectrum conflicts before selecting a structure.',
      );
    }
    if (proton.isEmpty) {
      suggestions.add(
        'Collect a proton spectrum with chemical shifts, integration and splitting; formula and DBE alone cannot identify an isomer.',
      );
    }
    if (integrations.isEmpty && proton.isNotEmpty) {
      suggestions.add(
        'Add absolute proton counts in the same order as the shifts. This lets the solver reject candidates with incompatible integrations.',
      );
    } else if (integrations.isNotEmpty) {
      final total = integrations.fold(0, (a, b) => a + b);
      suggestions.add(
        '$total of ${formula.hydrogens} formula hydrogens are accounted for by the entered integrations. These are absolute H counts, not an arbitrary normalised ratio.',
      );
      if (total < formula.hydrogens) {
        suggestions.add(
          'Account for the remaining hydrogens: consider unresolved overlaps, incomplete data and exchangeable O–H/N–H signals before excluding a candidate.',
        );
      }
    }
    if (carbon.isEmpty) {
      suggestions.add(
        'A carbon spectrum and DEPT/edited HSQC can distinguish carbonyl, CH, CH₂, CH₃ and quaternary environments.',
      );
    }
    if (formula.oxygens > 0 && ir.isEmpty) {
      suggestions.add(
        'Use IR to test O–H and C=O hypotheses; a missing unmeasured band is not evidence of absence.',
      );
    }
    final matches = result.candidateMatches;
    if (matches.length >= 2) {
      final a = matches[0].compound, b = matches[1].compound;
      for (final (label, linesA, linesB, tolerance) in [
        ('¹³C', a.nmr13C, b.nmr13C, 3.0),
        ('¹H', a.nmr1H, b.nmr1H, .3),
      ]) {
        List<double> shifts(List<String> lines) => [
          for (final line in lines)
            if (RegExp(r'δ\s*(\d+(?:\.\d+)?)').firstMatch(line) case final m?)
              double.parse(m.group(1)!),
        ];
        final others = shifts(linesB);
        final distinct = shifts(linesA)
            .where((p) => !others.any((q) => (p - q).abs() <= tolerance))
            .toList();
        if (distinct.isNotEmpty) {
          suggestions.add(
            'To distinguish ${a.commonName} from ${b.commonName}, inspect the $label region near ${distinct.first.toStringAsFixed(2)} ppm. This is a reference discriminator, not a newly observed peak; solvent and overlap can affect it.',
          );
          break;
        }
      }
    }
    if (matches.isEmpty) {
      suggestions.add(
        'No compatible library candidate is established. The library is limited; this does not prove the compound is impossible.',
      );
    }
    suggestions.add(
      'Use COSY for neighbouring proton networks, HSQC for directly attached C–H pairs and HMBC for longer-range connections. Choose the experiment that tests your unresolved bond.',
    );
    if (result.dbe >= 4) {
      suggestions.add(
        'Test aromaticity with the actual proton/carbon environments. DBE ≥ 4 also permits non-aromatic polyunsaturated or polycyclic structures.',
      );
    }
    return suggestions;
  }

  static List<int> parseIntegrations(String text, int protonSignals) {
    if (text.trim().isEmpty) return [];
    final tokens = text.trim().split(RegExp(r'[,;\s]+'));
    final values = tokens.map(int.tryParse).toList();
    if (values.length != protonSignals ||
        values.any((v) => v == null || v <= 0 || v > 200)) {
      throw const FormatException(
        'Enter one positive whole-number H count for each proton shift, in the same order. Leave blank if unknown.',
      );
    }
    return values.cast<int>();
  }
}
