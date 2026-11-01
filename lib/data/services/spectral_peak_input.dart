/// Peak positions only. Reject malformed input instead of silently discarding it.
class SpectralPeakInput {
  final List<double> values;
  final String? error;
  const SpectralPeakInput(this.values, [this.error]);

  static SpectralPeakInput parse(String text, String technique) {
    if (text.trim().isEmpty) return const SpectralPeakInput([]);
    final values = <double>[];
    for (final token in text.trim().split(RegExp(r'[,;\s]+'))) {
      if (token.isEmpty) continue;
      final value = double.tryParse(token);
      if (value == null || !value.isFinite) {
        return SpectralPeakInput(
          [],
          '$technique: "$token" is not a peak position. Enter numbers separated by commas; omit units, integrations and J values.',
        );
      }
      values.add(value);
    }
    return SpectralPeakInput(values);
  }

  /// Built-in examples include integrations, J values, intensities and atom
  /// labels. Extract only the explicitly marked positions, never those numbers.
  static List<double> fromAnnotated(String text, String technique) {
    final pattern = switch (technique) {
      'IR' => RegExp(r'([\d.,\s&–-]+)\s*cm'),
      'MS' => RegExp(r'm/z\s*(\d+(?:\.\d+)?(?:\s*&\s*\d+(?:\.\d+)?)?)'),
      _ => RegExp(r'δ\s*([^;(]+)'),
    };
    final result = <double>[];
    for (final match in pattern.allMatches(text)) {
      final positions = match.group(1)!.replaceAll('ppm', '').trim();
      for (final part in positions.split(RegExp(r'[, &]+'))) {
        if (part.isEmpty) continue;
        // A multiplet range describes one environment, represented by its centre.
        final range = part.split(RegExp(r'[–-]'));
        if (range.length == 2 &&
            range.every((p) => double.tryParse(p) != null)) {
          result.add((double.parse(range[0]) + double.parse(range[1])) / 2);
        } else if (double.tryParse(part) case final value?) {
          result.add(value);
        }
      }
    }
    return result;
  }
}
