import 'dart:math' as math;

import 'chemical_graph.dart';

/// Ring-aware 2D layout for the small organic reference library. Places every
/// ring (including edge-fused rings) before growing the remaining substituents.
class SpectroscopyGraphLayout {
  static List<List<String>> rings(ChemicalGraph graph) {
    final result = <List<String>>[];
    final signatures = <String>{};
    for (final excluded in graph.bonds) {
      final queue = <List<String>>[
        [excluded.atom1Id],
      ];
      final visited = <String>{excluded.atom1Id};
      while (queue.isNotEmpty) {
        final path = queue.removeAt(0);
        if (path.length > 8) continue;
        if (path.last == excluded.atom2Id) {
          final sorted = [...path]..sort();
          if (path.length >= 3 && signatures.add(sorted.join(','))) {
            result.add(path);
          }
          break;
        }
        for (final bond in graph.bonds) {
          if (bond.id == excluded.id) continue;
          final next = bond.atom1Id == path.last
              ? bond.atom2Id
              : bond.atom2Id == path.last
              ? bond.atom1Id
              : null;
          if (next != null && visited.add(next)) queue.add([...path, next]);
        }
      }
    }
    result.sort((a, b) => a.length.compareTo(b.length));
    return result;
  }

  static ChemicalGraph layout(ChemicalGraph graph) {
    const length = 42.0;
    final cycles = rings(graph);
    final positions = <String, math.Point<double>>{};
    final parents = <String, String>{};
    final centers = <int, math.Point<double>>{};
    final adjacency = <String, List<String>>{
      for (final a in graph.atoms) a.id: [],
    };
    for (final bond in graph.bonds) {
      adjacency[bond.atom1Id]!.add(bond.atom2Id);
      adjacency[bond.atom2Id]!.add(bond.atom1Id);
    }

    void placeRing(int index, {String? previous}) {
      if (centers.containsKey(index)) return;
      final cycle = cycles[index];
      final known = cycle.where(positions.containsKey).toList();
      final radius = length / (2 * math.sin(math.pi / cycle.length));
      math.Point<double> center;
      Map<String, math.Point<double>> points(
        math.Point<double> middle,
        int anchorIndex,
        double angle,
        double step,
      ) => {
        for (var i = 0; i < cycle.length; i++)
          cycle[i]: math.Point(
            middle.x + radius * math.cos(angle + (i - anchorIndex) * step),
            middle.y + radius * math.sin(angle + (i - anchorIndex) * step),
          ),
      };
      Map<String, math.Point<double>> proposed;
      var sharedIndex = -1;
      for (var i = 0; i < cycle.length; i++) {
        if (positions.containsKey(cycle[i]) &&
            positions.containsKey(cycle[(i + 1) % cycle.length])) {
          sharedIndex = i;
          break;
        }
      }
      if (sharedIndex >= 0) {
        final a = positions[cycle[sharedIndex]]!;
        final b = positions[cycle[(sharedIndex + 1) % cycle.length]]!;
        final dx = b.x - a.x, dy = b.y - a.y;
        final edgeLength = a.distanceTo(b);
        final distance = edgeLength / (2 * math.tan(math.pi / cycle.length));
        final candidates =
            <
              ({
                math.Point<double> center,
                Map<String, math.Point<double>> points,
                double score,
              })
            >[];
        for (final sign in [-1, 1]) {
          final middle = math.Point(
            (a.x + b.x) / 2 - sign * dy / edgeLength * distance,
            (a.y + b.y) / 2 + sign * dx / edgeLength * distance,
          );
          final angle = math.atan2(a.y - middle.y, a.x - middle.x);
          final positive = math.Point(
            middle.x + radius * math.cos(angle + 2 * math.pi / cycle.length),
            middle.y + radius * math.sin(angle + 2 * math.pi / cycle.length),
          );
          final step =
              (positive.distanceTo(b) < 0.01 ? 1 : -1) *
              2 *
              math.pi /
              cycle.length;
          final proposed = points(middle, sharedIndex, angle, step);
          var score = 0.0;
          for (final entry in proposed.entries) {
            if (positions.containsKey(entry.key)) {
              score += entry.value.distanceTo(positions[entry.key]!) * 100;
            } else {
              for (final old in positions.values) {
                final d = entry.value.distanceTo(old);
                score += 1 / (d * d + 0.01);
              }
            }
          }
          candidates.add((center: middle, points: proposed, score: score));
        }
        candidates.sort((a, b) => a.score.compareTo(b.score));
        center = candidates.first.center;
        proposed = candidates.first.points;
      } else if (known.isNotEmpty) {
        final anchorId = known.first;
        final anchor = positions[anchorId]!;
        final outside =
            previous ??
            adjacency[anchorId]!
                .where((n) => !cycle.contains(n) && positions.containsKey(n))
                .firstOrNull;
        final origin = outside == null
            ? math.Point(anchor.x - length, anchor.y)
            : positions[outside]!;
        final direction = math.atan2(anchor.y - origin.y, anchor.x - origin.x);
        center = math.Point(
          anchor.x + radius * math.cos(direction),
          anchor.y + radius * math.sin(direction),
        );
        proposed = points(
          center,
          cycle.indexOf(anchorId),
          direction + math.pi,
          2 * math.pi / cycle.length,
        );
      } else {
        center = const math.Point(0.0, 0.0);
        proposed = points(center, 0, -math.pi / 2, 2 * math.pi / cycle.length);
      }
      for (final entry in proposed.entries) {
        positions.putIfAbsent(entry.key, () => entry.value);
      }
      centers[index] = center;
    }

    if (graph.atoms.isEmpty) return graph;
    if (cycles.isNotEmpty) {
      placeRing(0);
    } else {
      positions[graph.atoms.first.id] = const math.Point(0.0, 0.0);
    }
    final processed = <String>{};
    while (processed.length < graph.atoms.length) {
      // Fused cycles have two already placed adjacent atoms. Lay them out now,
      // across their shared edge, before any new chain atoms are grown.
      var moreRings = true;
      while (moreRings) {
        moreRings = false;
        for (var i = 0; i < cycles.length; i++) {
          if (!centers.containsKey(i) &&
              cycles[i].where(positions.containsKey).length >= 2) {
            placeRing(i);
            moreRings = true;
          }
        }
      }
      final pending = positions.keys
          .where((id) => !processed.contains(id))
          .toList();
      if (pending.isEmpty) {
        final next = graph.atoms.firstWhere((a) => !processed.contains(a.id));
        positions[next.id] = math.Point(positions.length * length, 0.0);
        continue;
      }
      final id = pending.first;
      processed.add(id);
      final point = positions[id]!;
      final free = adjacency[id]!
          .where((n) => !positions.containsKey(n))
          .toList();
      final ringIndices = centers.keys
          .where((i) => cycles[i].contains(id))
          .toList();
      final parent = parents[id];
      double direction;
      if (ringIndices.isNotEmpty) {
        final center = centers[ringIndices.first]!;
        direction = math.atan2(point.y - center.y, point.x - center.x);
      } else if (parent != null) {
        direction = math.atan2(
          point.y - positions[parent]!.y,
          point.x - positions[parent]!.x,
        );
      } else {
        direction = 0;
      }
      for (var j = 0; j < free.length; j++) {
        final next = free[j];
        if (positions.containsKey(next)) continue;
        final turn = free.length > 1
            ? (j - (free.length - 1) / 2) * 2 * math.pi / 3
            : ringIndices.isNotEmpty || parent == null
            ? 0.0
            : (processed.length.isEven ? 1 : -1) * math.pi / 3;
        final angle = direction + turn;
        positions[next] = math.Point(
          point.x + length * math.cos(angle),
          point.y + length * math.sin(angle),
        );
        parents[next] = id;
        for (var i = 0; i < cycles.length; i++) {
          if (!centers.containsKey(i) && cycles[i].contains(next)) {
            placeRing(i, previous: id);
          }
        }
      }
    }
    return ChemicalGraph(
      id: graph.id,
      smiles: graph.smiles,
      name: graph.name,
      bonds: graph.bonds,
      atoms: [
        for (final atom in graph.atoms)
          atom.copyWith(x: positions[atom.id]!.x, y: positions[atom.id]!.y),
      ],
    );
  }
}
