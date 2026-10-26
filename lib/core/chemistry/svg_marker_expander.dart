import 'dart:math' as math;

/// Expand simple absolute SVG end markers for renderers without marker support.
String expandSvgArrowMarkers(String svg) {
  final arrows = <String>[];
  final converted = svg.replaceAllMapped(
    RegExp(r'<(?:path|line)\b[^>]*marker-end="url\(#[^"]+\)"[^>]*\/>'),
    (match) {
      final element = match.group(0)!;
      String? attribute(String name) =>
          RegExp('$name="([^"]*)"').firstMatch(element)?.group(1);
      final coords = <double>[];
      if (element.startsWith('<line')) {
        for (final key in ['x1', 'y1', 'x2', 'y2']) {
          final value = double.tryParse(attribute(key) ?? '');
          if (value == null) {
            return element;
          }
          coords.add(value);
        }
      } else {
        final d = attribute('d') ?? '';
        if (RegExp(r'[a-zA-BD-KN-PR-Z]').hasMatch(d)) {
          return element;
        }
        coords.addAll(
          RegExp(r'-?\d+(?:\.\d+)?')
              .allMatches(d)
              .map((m) => double.parse(m.group(0)!)),
        );
      }
      if (coords.length < 4 || coords.length.isOdd) {
        return element;
      }
      final x = coords[coords.length - 2], y = coords.last;
      final dx = x - coords[coords.length - 4],
          dy = y - coords[coords.length - 3];
      final length = math.sqrt(dx * dx + dy * dy);
      if (length == 0) {
        return element;
      }
      final size = (double.tryParse(attribute('stroke-width') ?? '') ?? 2) * 4;
      final ux = dx / length, uy = dy / length;
      final bx = x - ux * size, by = y - uy * size;
      final half = size * .45;
      final color = attribute('stroke') ?? '#F59E0B';
      arrows.add(
        '<polygon points="$x,$y ${bx - uy * half},${by + ux * half} ${bx + uy * half},${by - ux * half}" fill="$color"/>',
      );
      return element.replaceAll(RegExp(r'\s+marker-end="[^"]+"'), '');
    },
  );
  return converted.replaceAll('</svg>', '${arrows.join()}\n</svg>');
}
