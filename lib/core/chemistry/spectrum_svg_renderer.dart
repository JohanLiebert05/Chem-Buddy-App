import 'dart:math' as math;

enum SpectrumTechnique {
  proton('¹H NMR', 'Chemical shift δ / ppm', 14, 0),
  carbon('¹³C NMR', 'Chemical shift δ / ppm', 220, 0),
  ir('FT-IR', 'Wavenumber / cm⁻¹', 4000, 400),
  mass('Mass spectrum', 'm/z', 0, 200);

  const SpectrumTechnique(this.label, this.axis, this.start, this.end);
  final String label;
  final String axis;
  final double start;
  final double end;
}

class SpectrumSignal {
  const SpectrumSignal({
    required this.position,
    this.assignment = '',
    this.integration,
    this.multiplicity = '',
    this.couplingsHz = const [],
    this.relativeIntensity,
    this.broad = false,
  });
  final double position;
  final String assignment;
  final int? integration;
  final String multiplicity;
  final List<double> couplingsHz;
  final double? relativeIntensity;
  final bool broad;
}

/// SVG diagrams reconstructed from peak lists, never experimental spectra.
/// NMR line splitting is first order and only used when reference J is known.
class SpectrumSvgRenderer {
  static String escape(String text) => text
      .replaceAll('&', '&amp;')
      .replaceAll('<', '&lt;')
      .replaceAll('>', '&gt;')
      .replaceAll('"', '&quot;')
      .replaceAll("'", '&apos;');

  static List<({double position, double weight})> lines(
    SpectrumSignal signal, {
    double frequencyMhz = 400,
  }) {
    if (!frequencyMhz.isFinite || frequencyMhz <= 0) {
      throw ArgumentError.value(frequencyMhz, 'frequencyMhz');
    }
    final pattern = signal.multiplicity.toLowerCase().replaceAll(' ', '');
    final orders = switch (pattern) {
      'd' => [2],
      't' => [3],
      'q' => [4],
      'quintet' || 'quint' => [5],
      'sextet' => [6],
      'septet' || 'heptet' => [7],
      'nonet' => [9],
      'dd' => [2, 2],
      'dt' => [2, 3],
      'td' => [3, 2],
      'dq' => [2, 4],
      'qd' => [4, 2],
      'ddd' => [2, 2, 2],
      _ => <int>[],
    };
    if (orders.isEmpty ||
        signal.couplingsHz.length < orders.length ||
        signal.couplingsHz.any((j) => !j.isFinite || j <= 0)) {
      return [(position: signal.position, weight: 1)];
    }
    var result = [(position: signal.position, weight: 1.0)];
    for (var axis = 0; axis < orders.length; axis++) {
      final count = orders[axis];
      final coefficients = <double>[1];
      for (var i = 1; i < count; i++) {
        coefficients.add(coefficients.last * (count - i) / i);
      }
      final sum = coefficients.reduce((a, b) => a + b);
      result = [
        for (final line in result)
          for (var i = 0; i < count; i++)
            (
              position:
                  line.position +
                  (i - (count - 1) / 2) *
                      signal.couplingsHz[axis] /
                      frequencyMhz,
              weight: line.weight * coefficients[i] / sum,
            ),
      ];
    }
    return result;
  }

  static String render({
    required SpectrumTechnique technique,
    List<SpectrumSignal> observed = const [],
    List<SpectrumSignal> expected = const [],
    bool showObserved = true,
    bool showExpected = true,
    bool compact = false,
    double frequencyMhz = 400,
    String foreground = '#243244',
    String background = '#FFFFFF',
    String observedColor = '#087F8C',
    String expectedColor = '#BB5A1D',
    String gridColor = '#DFE6ED',
  }) {
    if (!frequencyMhz.isFinite || frequencyMhz <= 0) {
      throw ArgumentError.value(frequencyMhz, 'frequencyMhz');
    }
    final measured = showObserved
        ? observed.where((s) => s.position.isFinite).toList()
        : <SpectrumSignal>[];
    final reference = showExpected
        ? expected.where((s) => s.position.isFinite).toList()
        : <SpectrumSignal>[];
    final all = [...measured, ...reference];
    var start = technique.start;
    var end = technique.end;
    if (technique == SpectrumTechnique.mass && all.isNotEmpty) {
      end = math
          .max(
            50,
            (all.map((s) => s.position).reduce(math.max) * 1.12 / 25).ceil() *
                25,
          )
          .toDouble();
    } else if (technique == SpectrumTechnique.proton ||
        technique == SpectrumTechnique.carbon) {
      if (all.isNotEmpty) {
        start = math.max(
          start,
          all.map((s) => s.position).reduce(math.max).ceilToDouble() + 1,
        );
        end = math.min(
          end,
          all.map((s) => s.position).reduce(math.min).floorToDouble() - 0.5,
        );
      }
    }
    // Preserve 0 ppm at the right when all resonances are positive.
    if (all.every((s) => s.position >= 0) &&
        technique != SpectrumTechnique.ir &&
        technique != SpectrumTechnique.mass) {
      end = 0;
    }
    final canvasWidth = compact ? 600.0 : 800.0;
    const left = 64.0, top = 60.0, bottom = 270.0;
    final right = canvasWidth - 24;
    final middle = (left + right) / 2;
    double x(double position) =>
        left + (position - start) / (end - start) * (right - left);
    final b = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" width="$canvasWidth" height="340" viewBox="0 0 $canvasWidth 340">',
    );
    b.writeln(
      '<title>${escape(technique.label)} schematic spectrum</title><desc>Entered positions and expected reference positions. Curves are reconstructed, not measured. NMR axes decrease left to right.</desc>',
    );
    b.writeln(
      '<rect width="$canvasWidth" height="340" rx="14" fill="$background"/>',
    );
    b.writeln('<g font-family="sans-serif" fill="$foreground">');
    b.writeln(
      '<text x="24" y="28" font-size="16" font-weight="700">${escape(technique.label)}</text>',
    );
    b.writeln(
      '<text x="$right" y="28" text-anchor="end" font-size="${compact ? 16 : 11}">SCHEMATIC • ${technique == SpectrumTechnique.proton ? '${frequencyMhz.toInt()} MHz • ' : ''}SVG</text>',
    );
    final ticks = compact ? 4 : 8;
    for (var i = 0; i <= ticks; i++) {
      final px = left + (right - left) * i / ticks;
      final value = start + (end - start) * i / ticks;
      b.writeln(
        '<line x1="$px" y1="$top" x2="$px" y2="$bottom" stroke="$gridColor" stroke-dasharray="3 5"/>',
      );
      b.writeln(
        '<text x="$px" y="293" text-anchor="middle" font-size="${compact ? 22 : 11}">${value.toStringAsFixed(technique == SpectrumTechnique.proton ? 1 : 0)}</text>',
      );
    }
    b.writeln(
      '<line x1="$left" y1="$bottom" x2="$right" y2="$bottom" stroke="$foreground"/>',
    );
    b.writeln(
      '<text x="$middle" y="${compact ? 327 : 312}" text-anchor="middle" font-size="${compact ? 20 : 12}">${escape(technique.axis)}</text>',
    );
    b.writeln(
      '<text x="18" y="170" transform="rotate(-90 18 170)" text-anchor="middle" font-size="${compact ? 18 : 11}">${technique == SpectrumTechnique.ir ? 'Transmittance' : 'Relative intensity'}</text>',
    );

    void trace(List<SpectrumSignal> signals, String color, String id) {
      if (signals.isEmpty) return;
      b.writeln('<g id="$id" stroke="$color" fill="none">');
      if (technique == SpectrumTechnique.carbon ||
          technique == SpectrumTechnique.mass) {
        final completeIntensities = signals.every(
          (s) => s.relativeIntensity != null && s.relativeIntensity! > 0,
        );
        final maxIntensity = !completeIntensities
            ? 1.0
            : signals.map((s) => s.relativeIntensity ?? 1).reduce(math.max);
        for (final signal in signals) {
          final height =
              165 *
              (completeIntensities ? signal.relativeIntensity! : 1) /
              math.max(0.01, maxIntensity);
          b.writeln(
            '<line x1="${x(signal.position)}" y1="$bottom" x2="${x(signal.position)}" y2="${bottom - height}" stroke-width="${id == 'observed' ? 2.5 : 1.7}" ${id == 'expected' ? 'stroke-dasharray="5 3"' : ''}/>',
          );
        }
      } else {
        final samples = <double>[];
        final resolved = [
          for (final signal in signals)
            (
              signal: signal,
              lines: technique == SpectrumTechnique.proton
                  ? lines(signal, frequencyMhz: frequencyMhz)
                  : [(position: signal.position, weight: 1.0)],
            ),
        ];
        const sampleCount = 2400;
        for (var i = 0; i <= sampleCount; i++) {
          final position = start + (end - start) * i / sampleCount;
          var intensity = 0.0;
          for (final group in resolved) {
            final width = technique == SpectrumTechnique.ir
                ? (group.signal.broad ? 120.0 : 17.0)
                : (group.signal.broad || group.signal.multiplicity == 'm'
                      ? 0.045
                      : 0.006);
            for (final line in group.lines) {
              final delta = (position - line.position) / width;
              intensity +=
                  line.weight *
                  (technique == SpectrumTechnique.proton
                      ? (group.signal.integration ?? 1)
                      : 1) *
                  (technique == SpectrumTechnique.ir
                      ? math.exp(-0.5 * delta * delta)
                      : 1 / (1 + delta * delta));
            }
          }
          samples.add(intensity);
        }
        final maxValue = math.max(0.001, samples.reduce(math.max));
        final path = StringBuffer();
        for (var i = 0; i < samples.length; i++) {
          final px = left + i / (samples.length - 1) * (right - left);
          final py = technique == SpectrumTechnique.ir
              ? top + 22 + samples[i] / maxValue * 160
              : bottom - samples[i] / maxValue * 165;
          path.write(
            '${i == 0 ? 'M' : 'L'}${px.toStringAsFixed(2)},${py.toStringAsFixed(2)} ',
          );
        }
        b.writeln(
          '<path d="$path" stroke-width="1.8" ${id == 'expected' ? 'stroke-dasharray="6 3"' : ''}/>',
        );
      }
      b.writeln('</g>');
      // Keep crowded aromatic labels from obscuring each other. The complete
      // numerical peak list and assignments remain available beside the plot.
      var lastLabel = -100.0;
      final sorted = [...signals]
        ..sort((a, b) => x(a.position).compareTo(x(b.position)));
      for (final signal in sorted) {
        final px = x(signal.position);
        if (px - lastLabel < (compact ? 90 : 48)) continue;
        lastLabel = px;
        b.writeln(
          '<text x="$px" y="${id == 'observed' ? 46 : 64}" fill="$color" text-anchor="middle" font-size="${compact ? 18 : 10}">${signal.position.toStringAsFixed(technique == SpectrumTechnique.proton ? 2 : 1)}</text>',
        );
      }
    }

    trace(reference, expectedColor, 'expected');
    trace(measured, observedColor, 'observed');
    if (all.isEmpty) {
      b.writeln(
        '<text x="$middle" y="166" text-anchor="middle" font-size="14">No peak positions available for this technique</text>',
      );
    }
    if (!compact) {
      b.writeln(
        '<text x="420" y="331" text-anchor="middle" font-size="10">Reconstructed from peak lists • heights and line shapes are illustrative</text>',
      );
    }
    b.writeln('</g></svg>');
    return b.toString();
  }
}
