import '../widgets/molecule_3d/molecule_3d_models.dart';

/// Reads a 3D V2000 record without deriving coordinates from a 2D diagram.
abstract final class CompoundConformer {
  static Molecule3D? fromMolfile(
    String sdf, {
    required String id,
    required String name,
    required String formula,
  }) {
    try {
      final rows = sdf.split(RegExp(r'\r?\n'));
      if (rows.length < 5 ||
          !rows[1].trimRight().endsWith('3D') ||
          !rows[3].contains('V2000')) {
        return null;
      }
      int readInt(String line, int start) =>
          int.parse(line.substring(start, start + 3).trim());
      double readCoordinate(String line, int start) =>
          double.parse(line.substring(start, start + 10).trim());
      final atomCount = readInt(rows[3], 0);
      final bondCount = readInt(rows[3], 3);
      final propertiesStart = 4 + atomCount + bondCount;
      if (atomCount < 1 ||
          atomCount > 999 ||
          bondCount < 0 ||
          propertiesStart >= rows.length) {
        return null;
      }

      final atoms = <Atom3D>[];
      for (final row in rows.skip(4).take(atomCount)) {
        final symbol = row.substring(31, 34).trim();
        final x = readCoordinate(row, 0);
        final y = readCoordinate(row, 10);
        final z = readCoordinate(row, 20);
        if (!RegExp(r'^[A-Z][a-z]?$').hasMatch(symbol) ||
            !x.isFinite ||
            !y.isFinite ||
            !z.isFinite) {
          return null;
        }
        atoms.add(Atom3D(symbol: symbol, x: x, y: y, z: z));
      }
      final bonds = <Bond3D>[];
      for (final row in rows.skip(4 + atomCount).take(bondCount)) {
        final a = readInt(row, 0) - 1;
        final b = readInt(row, 3) - 1;
        final type = switch (readInt(row, 6)) {
          1 => BondType3D.single,
          2 => BondType3D.doubleBond,
          3 => BondType3D.tripleBond,
          4 => BondType3D.aromatic,
          _ => null,
        };
        if (a < 0 ||
            b < 0 ||
            a >= atomCount ||
            b >= atomCount ||
            a == b ||
            type == null) {
          return null;
        }
        bonds.add(Bond3D(atomIndex1: a, atomIndex2: b, type: type));
      }
      if (!rows
          .skip(propertiesStart)
          .takeWhile((row) => row != r'$$$$')
          .any((row) => row.startsWith('M  END'))) {
        return null;
      }
      return Molecule3D(
        id: id,
        name: name,
        formula: formula,
        atoms: atoms,
        bonds: bonds,
      );
    } on FormatException {
      return null;
    } on RangeError {
      return null;
    }
  }
}
