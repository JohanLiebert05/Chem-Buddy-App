import 'dart:math' as math;

class ElementalFormulaCandidate {
  ElementalFormulaCandidate(Map<String, int> atoms, this.maxPercentError)
    : atoms = Map.unmodifiable(atoms);
  final Map<String, int> atoms;
  final double maxPercentError;
  String get formula => ElementalCompositionService.formatFormula(atoms);
  double get molarMass => atoms.entries.fold(
    0.0,
    (sum, e) =>
        sum + ElementalCompositionService.atomicWeights[e.key]! * e.value,
  );
  int get atomCount => atoms.values.fold(0, (sum, n) => sum + n);
  Map<String, double> get percentages => {
    for (final e in atoms.entries)
      e.key:
          e.value *
          ElementalCompositionService.atomicWeights[e.key]! /
          molarMass *
          100,
  };
  Map<String, int> get empiricalAtoms {
    final divisor = atoms.values.reduce((a, b) => a.gcd(b));
    return {for (final e in atoms.entries) e.key: e.value ~/ divisor};
  }

  String get empiricalFormula =>
      ElementalCompositionService.formatFormula(empiricalAtoms);
  double? get dbe {
    // This neutral closed-shell valence model does not describe variable S/P.
    if ((atoms['P'] ?? 0) > 0 || (atoms['S'] ?? 0) > 0) return null;
    return (2 * (atoms['C'] ?? 0) +
            2 +
            (atoms['N'] ?? 0) -
            (atoms['H'] ?? 0) -
            (atoms['F'] ?? 0) -
            (atoms['Cl'] ?? 0) -
            (atoms['Br'] ?? 0) -
            (atoms['I'] ?? 0)) /
        2;
  }
}

class ElementalCompositionResult {
  const ElementalCompositionResult({
    required this.isValid,
    required this.message,
    this.percentages = const {},
    this.molesPer100g = const {},
    this.ratios = const {},
    this.empiricalCandidates = const [],
    this.molecularCandidates = const [],
    this.oxygenByDifference = false,
    this.molarMassProvided = false,
  });
  final bool isValid;
  final String message;
  final Map<String, double> percentages;
  final Map<String, double> molesPer100g;
  final Map<String, double> ratios;
  final List<ElementalFormulaCandidate> empiricalCandidates;
  final List<ElementalFormulaCandidate> molecularCandidates;
  final bool oxygenByDifference;
  final bool molarMassProvided;
  double get total => percentages.values.fold(0.0, (sum, value) => sum + value);
}

class ElementalQuestionInput {
  const ElementalQuestionInput(this.percentages, {this.error, this.molarMass});
  final Map<String, double> percentages;
  final String? error;
  final double? molarMass;
}

class ElementalCompositionService {
  // Conventional abridged weights, consistent with the spectroscopy service.
  static const atomicWeights = {
    'C': 12.011,
    'H': 1.008,
    'N': 14.007,
    'O': 15.999,
    'S': 32.06,
    'P': 30.974,
    'F': 18.998,
    'Cl': 35.45,
    'Br': 79.904,
    'I': 126.904,
  };
  static const _names = {
    'carbon': 'C',
    'hydrogen': 'H',
    'nitrogen': 'N',
    'oxygen': 'O',
    'sulfur': 'S',
    'sulphur': 'S',
    'phosphorus': 'P',
    'fluorine': 'F',
    'chlorine': 'Cl',
    'bromine': 'Br',
    'iodine': 'I',
  };

  static String formatFormula(Map<String, int> atoms) {
    final rest = atoms.keys.where((e) => e != 'C' && e != 'H').toList()..sort();
    return [
      for (final element in ['C', 'H', ...rest])
        if ((atoms[element] ?? 0) > 0)
          '$element${atoms[element] == 1 ? '' : atoms[element]}',
    ].join();
  }

  /// Read explicit percentages; do not infer a missing element from prose.
  static ElementalQuestionInput parseQuestion(String text) {
    final input = text.trim();
    final symbols =
        'carbon|hydrogen|nitrogen|oxygen|sulphur|sulfur|phosphorus|fluorine|chlorine|bromine|iodine|[A-Za-z]{1,2}';
    const number = r'[-+]?\d+(?:\.\d+)?';
    const percent = r'(?:%|percent(?:age)?|per\s+cent|pecent)';
    final forward = RegExp(
      '($number)\\s*$percent\\s*(?:of\\s+)?($symbols)\\b',
      caseSensitive: false,
    );
    final backward = RegExp(
      '\\b($symbols)\\s*(?:[:=]|is)?\\s*($number)\\s*$percent',
      caseSensitive: false,
    );
    final values = <String, double>{};
    final covered = <int>{};
    String? error;
    void add(RegExpMatch match, String rawElement, String rawValue) {
      if (covered.contains(match.start)) return;
      final element =
          _names[rawElement.toLowerCase()] ??
          atomicWeights.keys
              .where((key) => key.toLowerCase() == rawElement.toLowerCase())
              .firstOrNull;
      if (element == null) {
        error =
            'Unsupported element "$rawElement". Use C, H, N, O, S, P, F, Cl, Br or I.';
        return;
      }
      if (values.containsKey(element)) {
        error =
            '$element was provided more than once. Enter one percentage per element.';
        return;
      }
      values[element] = double.parse(rawValue);
      covered.addAll(
        List.generate(match.end - match.start, (i) => match.start + i),
      );
    }

    final first = forward.allMatches(input).toList();
    final second = backward.allMatches(input).toList();
    final ordered = second.length > first.length
        ? [
            ...second.map((m) => (match: m, reverse: true)),
            ...first.map((m) => (match: m, reverse: false)),
          ]
        : [
            ...first.map((m) => (match: m, reverse: false)),
            ...second.map((m) => (match: m, reverse: true)),
          ];
    for (final item in ordered) {
      final match = item.match;
      if (List.generate(
        match.end - match.start,
        (i) => match.start + i,
      ).any(covered.contains)) {
        continue;
      }
      add(
        match,
        match.group(item.reverse ? 1 : 2)!,
        match.group(item.reverse ? 2 : 1)!,
      );
    }
    for (final marker in RegExp(
      percent,
      caseSensitive: false,
    ).allMatches(input)) {
      if (!covered.contains(marker.start)) error ??= 'A percentage could not be assigned to an element. Try "40% carbon, 6.71% hydrogen, 53.29% oxygen".';
    }
    if (values.isEmpty) error ??= 'No explicit element percentages found. Try "C 40%, H 6.71%, O 53.29%".';
    final mass = RegExp(
      r'(?:molar\s+mass|molecular\s+(?:mass|weight))\s*(?:of|is|=|:)?\s*(\d+(?:\.\d+)?)\s*(?:g\s*/\s*mol|g\s*mol)',
      caseSensitive: false,
    ).firstMatch(input);
    return ElementalQuestionInput(
      values,
      error: error,
      molarMass: mass == null ? null : double.parse(mass.group(1)!),
    );
  }

  static ElementalCompositionResult solve({
    required Map<String, double> percentages,
    double? molarMass,
    double percentTolerance = .20,
    double massTolerance = .50,
    bool oxygenByDifference = false,
  }) {
    ElementalCompositionResult invalid(String message) =>
        ElementalCompositionResult(
          isValid: false,
          message: message,
          percentages: Map.unmodifiable(percentages),
          molarMassProvided: molarMass != null,
        );
    if (!percentTolerance.isFinite ||
        percentTolerance <= 0 ||
        percentTolerance > 1 ||
        !massTolerance.isFinite ||
        massTolerance <= 0 ||
        massTolerance > 5) {
      return invalid(
        'Use a percentage tolerance above 0 and at most 1 percentage point, and a mass tolerance above 0 and at most 5 g/mol.',
      );
    }
    if (percentages.isEmpty ||
        percentages.entries.any(
          (e) =>
              !atomicWeights.containsKey(e.key) ||
              !e.value.isFinite ||
              e.value < 0 ||
              e.value > 100,
        )) {
      return invalid(
        'Enter finite percentages between 0 and 100 for supported elements.',
      );
    }
    final composition = Map<String, double>.fromEntries(
      percentages.entries.where((e) => e.value > 0),
    );
    if (oxygenByDifference) {
      if (composition.containsKey('O')) {
        return invalid(
          'Clear the oxygen percentage before using oxygen by difference.',
        );
      }
      final remaining =
          100.0 -
          composition.values.fold<double>(0.0, (sum, value) => sum + value);
      if (remaining <= 0) {
        return invalid(
          'The entered percentages leave no positive remainder for oxygen.',
        );
      }
      composition['O'] = remaining;
    }
    if (!composition.containsKey('C')) {
      return invalid(
        'This organic-composition solver needs a positive carbon percentage.',
      );
    }
    final total = composition.values.fold(0.0, (sum, value) => sum + value);
    if ((total - 100).abs() > composition.length * percentTolerance + 1e-8) {
      final gap = 100 - total;
      return invalid(
        'Percentages total ${total.toStringAsFixed(2)}%. ${gap > 0 ? '${gap.toStringAsFixed(2)}% is unaccounted for' : 'They exceed 100% by ${(-gap).toStringAsFixed(2)}%'}. Supply all elements; no missing element is assumed.',
      );
    }
    if (molarMass != null &&
        (!molarMass.isFinite || molarMass <= 0 || molarMass > 5000)) {
      return invalid(
        'Enter a finite molar mass above 0 and at most 5000 g/mol.',
      );
    }
    final moles = {
      for (final e in composition.entries)
        e.key: e.value / atomicWeights[e.key]!,
    };
    final smallest = moles.values.reduce(math.min);
    if (smallest <= 0 || !smallest.isFinite) {
      return invalid(
        'The trace percentages are below supported numerical precision. Use meaningful reported mass percentages.',
      );
    }
    final ratios = {for (final e in moles.entries) e.key: e.value / smallest};
    if (ratios.values.any((ratio) => !ratio.isFinite)) {
      return invalid(
        'The mole ratios exceed supported numerical precision. Recheck the trace percentages.',
      );
    }
    double error(Map<String, int> atoms) {
      final candidate = ElementalFormulaCandidate(atoms, 0);
      return composition.entries
          .map((e) => (candidate.percentages[e.key]! - e.value).abs())
          .reduce(math.max);
    }

    final empirical = <String, ElementalFormulaCandidate>{};
    for (var multiplier = 1; multiplier <= 100; multiplier++) {
      if (ratios.values.any(
        (ratio) => !ratio.isFinite || ratio * multiplier > 300,
      )) {
        continue;
      }
      final counts = {
        for (final e in ratios.entries) e.key: (e.value * multiplier).round(),
      };
      if (counts.values.any((n) => n <= 0) ||
          counts.values.fold(0, (a, b) => a + b) > 300) {
        continue;
      }
      final divisor = counts.values.reduce((a, b) => a.gcd(b));
      final reduced = {
        for (final e in counts.entries) e.key: e.value ~/ divisor,
      };
      final residual = error(reduced);
      if (residual <= percentTolerance + 1e-8) {
        final candidate = ElementalFormulaCandidate(reduced, residual);
        empirical[candidate.formula] = candidate;
      }
    }
    final molecular = <ElementalFormulaCandidate>[];
    if (molarMass != null) {
      final elements = composition.keys.toList();
      final bounds = <({int min, int max})>[];
      var combinations = 1;
      for (final element in elements) {
        final low = math.max(
          1,
          ((composition[element]! - percentTolerance) *
                      math.max(0.0, molarMass - massTolerance) /
                      100 /
                      atomicWeights[element]! -
                  1e-9)
              .ceil(),
        );
        final high =
            ((composition[element]! + percentTolerance) *
                        (molarMass + massTolerance) /
                        100 /
                        atomicWeights[element]! +
                    1e-9)
                .floor();
        if (high < low) {
          combinations = 0;
          break;
        }
        combinations *= high - low + 1;
        if (combinations > 100000) {
          return invalid(
            'These tolerances allow too many formulas. Narrow the percentage or molar-mass tolerance.',
          );
        }
        bounds.add((min: low, max: high));
      }
      void enumerate(int index, Map<String, int> counts) {
        if (index == elements.length) {
          final candidate = ElementalFormulaCandidate(counts, error(counts));
          if ((candidate.molarMass - molarMass).abs() > massTolerance + 1e-8 ||
              candidate.maxPercentError > percentTolerance + 1e-8) {
            return;
          }
          final dbe = candidate.dbe;
          if (dbe != null && (dbe < 0 || dbe % 1 != 0)) return;
          molecular.add(candidate);
          final reduced = candidate.empiricalAtoms;
          final primitive = ElementalFormulaCandidate(
            reduced,
            candidate.maxPercentError,
          );
          empirical[primitive.formula] = primitive;
          return;
        }
        for (
          var count = bounds[index].min;
          count <= bounds[index].max;
          count++
        ) {
          enumerate(index + 1, {...counts, elements[index]: count});
        }
      }

      if (combinations > 0) enumerate(0, {});
      molecular.sort((a, b) => a.maxPercentError.compareTo(b.maxPercentError));
    }
    final massCompatibleEmpirical = <String, ElementalFormulaCandidate>{
      for (final candidate in molecular)
        candidate.empiricalFormula: ElementalFormulaCandidate(
          candidate.empiricalAtoms,
          candidate.maxPercentError,
        ),
    };
    final empiricalOptions =
        (molecular.isEmpty ? empirical : massCompatibleEmpirical).values
            .toList()
          ..sort((a, b) {
            final complexity = a.atomCount.compareTo(b.atomCount);
            return complexity == 0
                ? a.maxPercentError.compareTo(b.maxPercentError)
                : complexity;
          });
    final valid =
        empiricalOptions.isNotEmpty &&
        (molarMass == null || molecular.isNotEmpty);
    return ElementalCompositionResult(
      isValid: valid,
      message: !valid
          ? (molarMass != null
                ? 'No neutral closed-shell molecular formula fits both the reported mass and percentages within these tolerances. Recheck the data or the assumed chemical model.'
                : 'No small whole-number ratio (up to 300 atoms) fits these percentages. Check the data or reported precision.')
          : molarMass == null
          ? 'A compatible empirical ratio was found. Molar mass is needed to determine a molecular formula; spectra are needed to distinguish structures.'
          : molecular.length == 1
          ? 'One molecular formula fits the supplied mass and percentage tolerances. Its structure still requires spectroscopic evidence.'
          : '${molecular.length} molecular formulas fit these tolerances. Refine the data or compare the candidates; no single answer is forced.',
      percentages: Map.unmodifiable(composition),
      molesPer100g: Map.unmodifiable(moles),
      ratios: Map.unmodifiable(ratios),
      empiricalCandidates: empiricalOptions.take(5).toList(),
      molecularCandidates: molecular,
      oxygenByDifference: oxygenByDifference,
      molarMassProvided: molarMass != null,
    );
  }
}
