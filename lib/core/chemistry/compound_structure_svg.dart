import 'dart:math' as math;
import 'dart:ui';

/// Converts PubChem's 2D V2000 coordinates into a scalable structure diagram.
class CompoundStructureSvg {
  static String? fromMolfile(String sdf) {
    try {
      final lines = sdf.trimLeft().split(RegExp(r'\r?\n'));
      if (lines.length < 5 || !lines[3].contains('V2000')) return null;
      int column(String row, int offset) =>
          int.tryParse(row.substring(offset, offset + 3).trim()) ?? 0;
      final atomCount = column(lines[3], 0);
      final bondCount = column(lines[3], 3);
      if (atomCount < 1 ||
          atomCount > 250 ||
          bondCount < 0 ||
          lines.length < 5 + atomCount + bondCount) {
        return null;
      }
      final atoms = [
        for (final line in lines.skip(4).take(atomCount))
          (
            position: Offset(
              double.parse(line.substring(0, 10)),
              -double.parse(line.substring(10, 20)),
            ),
            element: line.substring(31, 34).trim(),
            chargeCode: column(line, 36),
          ),
      ];
      final bonds = [
        for (final line in lines.skip(4 + atomCount).take(bondCount))
          (
            from: column(line, 0) - 1,
            to: column(line, 3) - 1,
            order: column(line, 6),
            stereo: column(line, 9),
          ),
      ];
      if (atoms.any(
            (atom) =>
                !atom.position.isFinite ||
                !RegExp(r'^[A-Z][a-z]?$').hasMatch(atom.element),
          ) ||
          bonds.any(
            (bond) =>
                bond.order < 1 ||
                bond.order > 4 ||
                !const [0, 1, 6].contains(bond.stereo),
          )) {
        return null;
      }

      final charges = <int, int>{
        for (final (index, atom) in atoms.indexed)
          if (const [1, 2, 3, 5, 6, 7].contains(atom.chargeCode))
            index: 4 - atom.chargeCode,
      };
      final isotopes = <int, int>{};
      final radicals = <int>{
        for (final (index, atom) in atoms.indexed)
          if (atom.chargeCode == 4) index,
      };
      for (final line in lines.skip(4 + atomCount)) {
        if (line.startsWith('M  END')) break;
        final fields = line.trim().split(RegExp(r'\s+'));
        if (fields.length < 5 || fields.first != 'M') continue;
        for (var i = 3; i + 1 < fields.length; i += 2) {
          final index = int.parse(fields[i]) - 1;
          final value = int.parse(fields[i + 1]);
          switch (fields[1]) {
            case 'CHG':
              charges[index] = value;
            case 'ISO':
              isotopes[index] = value;
            case 'RAD':
              if (value != 2) return null;
              radicals.add(index);
          }
        }
      }

      // Preserve H on heteroatoms, isotopes and stereochemical bonds. Ordinary
      // C-H bonds are implicit in the skeletal drawing.
      final skeletalCarbons = <int>{};
      for (final bond in bonds) {
        final from = atoms[bond.from].element;
        final to = atoms[bond.to].element;
        if (from == 'C' && to != 'H') skeletalCarbons.add(bond.from);
        if (to == 'C' && from != 'H') skeletalCarbons.add(bond.to);
      }
      final hidden = <int>{};
      for (final bond in bonds) {
        if (bond.stereo != 0 || bond.order != 1) continue;
        final a = atoms[bond.from].element;
        final b = atoms[bond.to].element;
        final h = a == 'H' && skeletalCarbons.contains(bond.to)
            ? bond.from
            : (b == 'H' && skeletalCarbons.contains(bond.from)
                  ? bond.to
                  : null);
        if (h != null && !isotopes.containsKey(h) && !charges.containsKey(h)) {
          hidden.add(h);
        }
      }
      final visible = [
        for (final (index, atom) in atoms.indexed)
          if (!hidden.contains(index)) atom.position,
      ];
      final minX = visible.map((point) => point.dx).reduce(math.min);
      final maxX = visible.map((point) => point.dx).reduce(math.max);
      final minY = visible.map((point) => point.dy).reduce(math.min);
      final maxY = visible.map((point) => point.dy).reduce(math.max);
      final scale = math
          .min(300 / math.max(maxX - minX, 1), 150 / math.max(maxY - minY, 1))
          .clamp(0.0, 54.0);
      final center = Offset((minX + maxX) / 2, (minY + maxY) / 2);
      Offset project(int index) =>
          (atoms[index].position - center) * scale + const Offset(180, 105);
      String point(Offset p) =>
          '${p.dx.toStringAsFixed(2)} ${p.dy.toStringAsFixed(2)}';
      const ink = '#233144';
      const paper = '#FBFCFF';
      final svg = StringBuffer(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 360 210">'
        '<rect width="360" height="210" rx="18" fill="$paper"/>',
      );
      void line(Offset a, Offset b, {bool dashed = false}) {
        svg.write(
          '<path d="M ${point(a)} L ${point(b)}" '
          'fill="none" stroke="$ink" stroke-width="2.2" stroke-linecap="round"'
          '${dashed ? ' stroke-dasharray="3 3"' : ''}/>',
        );
      }

      final connected = <int>{};
      for (final bond in bonds) {
        connected.addAll([bond.from, bond.to]);
        if (hidden.contains(bond.from) || hidden.contains(bond.to)) continue;
        final start = project(bond.from);
        final end = project(bond.to);
        final delta = end - start;
        if (delta.distance == 0) return null;
        final normal = Offset(-delta.dy, delta.dx) / delta.distance;
        if (bond.stereo == 1) {
          svg.write(
            '<path d="M ${point(start)} L ${point(end + normal * 5)} '
            'L ${point(end - normal * 5)} Z" fill="$ink"/>',
          );
        } else if (bond.stereo == 6) {
          for (var i = 1; i <= 7; i++) {
            final t = i / 7;
            final at = start + delta * t;
            final half = normal * (5 * t);
            line(at - half, at + half);
          }
        } else if (bond.order == 1) {
          line(start, end);
        } else {
          final separation = normal * (bond.order == 3 ? 4.4 : 3);
          line(start + separation, end + separation);
          line(start - separation, end - separation, dashed: bond.order == 4);
          if (bond.order == 3) line(start, end);
        }
      }

      for (final (index, atom) in atoms.indexed) {
        if (hidden.contains(index)) continue;
        final charge = charges[index] ?? 0;
        final isotope = isotopes[index];
        final radical = radicals.contains(index);
        if (atom.element == 'C' &&
            connected.contains(index) &&
            charge == 0 &&
            isotope == null &&
            !radical) {
          continue;
        }
        final p = project(index);
        final color = switch (atom.element) {
          'O' => '#9B2443',
          'N' => '#185894',
          'F' || 'Cl' || 'Br' || 'I' => '#12664F',
          'P' || 'S' => '#805300',
          _ => ink,
        };
        final label = '${isotope ?? ''}${atom.element}';
        final width = math.max(17, label.length * 8 + 4);
        svg.write(
          '<rect x="${p.dx - width / 2}" y="${p.dy - 9}" '
          'width="$width" height="18" rx="4" fill="$paper"/>'
          '<text x="${p.dx}" y="${p.dy + 5}" text-anchor="middle" '
          'font-size="15" font-family="sans-serif" font-weight="700" fill="$color">$label</text>',
        );
        if (charge != 0 || radical) {
          final badge =
              '${charge.abs() > 1 ? charge.abs() : ''}'
              '${charge > 0 ? '+' : (charge < 0 ? '−' : '')}${radical ? '•' : ''}';
          svg.write(
            '<text x="${p.dx + width / 2}" y="${p.dy - 7}" '
            'font-size="11" font-weight="700" fill="$color">$badge</text>',
          );
        }
      }
      return '${svg.toString()}</svg>';
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }
}
