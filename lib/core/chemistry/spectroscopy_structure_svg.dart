import 'dart:math' as math;

import '../../data/services/spectroscopy_service.dart';
import 'chemical_graph.dart';
import 'smiles_svg_generator.dart';
import 'spectroscopy_graph_layout.dart';
import 'spectrum_svg_renderer.dart';

class SpectroscopyStructureDepiction {
  const SpectroscopyStructureDepiction({this.svg, this.error, this.graph});
  final String? svg;
  final String? error;
  final ChemicalGraph? graph;
}

/// Depicts the selected candidate's actual SMILES, with a formula check before
/// drawing. Does not substitute a generic benzene or invent connectivity.
class SpectroscopyStructureSvg {
  static SpectroscopyStructureDepiction depict(
    SpectroscopyCompoundEntry compound, {
    String foreground = '#243244',
    String background = '#FFFFFF',
  }) {
    try {
      final raw = SmilesSvgGenerator.parseSmilesToGraph(compound.smiles);
      final tokens = RegExp(r'\[[^\]]+\]|Cl|Br|[BCNOPSFIbcnops]')
          .allMatches(compound.smiles)
          .map((m) => m.group(0)!)
          .toList();
      if (tokens.length != raw.atoms.length || raw.atoms.isEmpty) {
        return const SpectroscopyStructureDepiction(
          error: 'This reference structure cannot be reliably depicted.',
        );
      }
      final aromatic = <String>{};
      final explicitH = <String, int>{};
      final normalized = <ChemicalAtom>[];
      for (var i = 0; i < raw.atoms.length; i++) {
        final token = tokens[i];
        final inside = token.startsWith('[')
            ? token.substring(1, token.length - 1)
            : token;
        final element = RegExp(r'Cl|Br|[BCNOPSFIbcnops]')
            .firstMatch(inside)!
            .group(0)!;
        final atom = raw.atoms[i];
        if (RegExp(r'^[bcnops]$').hasMatch(element)) aromatic.add(atom.id);
        if (token.startsWith('[')) {
          final h = RegExp(r'H(\d*)').firstMatch(inside);
          explicitH[atom.id] = h == null ? 0 : int.tryParse(h.group(1)!) ?? 1;
        }
        normalized.add(
          atom.copyWith(
            element: element.length == 1 ? element.toUpperCase() : element,
          ),
        );
      }
      // An aromatic-to-aromatic bridge between rings is a single bond; only
      // aromatic edges that belong to a cycle get aromatic bond styling.
      bool inCycle(ChemicalBond excluded) {
        final seen = <String>{excluded.atom1Id};
        final queue = <String>[excluded.atom1Id];
        while (queue.isNotEmpty) {
          final current = queue.removeLast();
          for (final bond in raw.bonds) {
            if (bond.id == excluded.id) continue;
            final next = bond.atom1Id == current
                ? bond.atom2Id
                : bond.atom2Id == current
                ? bond.atom1Id
                : null;
            if (next == excluded.atom2Id) return true;
            if (next != null && seen.add(next)) queue.add(next);
          }
        }
        return false;
      }

      final bonds = [
        for (final bond in raw.bonds)
          if (bond.type == BondType.single &&
              aromatic.contains(bond.atom1Id) &&
              aromatic.contains(bond.atom2Id) &&
              inCycle(bond))
            bond.copyWith(type: BondType.aromatic)
          else
            bond,
      ];
      final atoms = <ChemicalAtom>[];
      final counts = <String, int>{};
      for (final atom in normalized) {
        var valence = 0.0;
        for (final bond in bonds.where(
          (b) => b.atom1Id == atom.id || b.atom2Id == atom.id,
        )) {
          valence += switch (bond.type) {
            BondType.double => 2,
            BondType.triple => 3,
            BondType.aromatic => 1.5,
            _ => 1,
          };
        }
        final target = switch (atom.element) {
          'C' => 4,
          'N' => atom.formalCharge > 0 ? 4 : 3,
          'O' => atom.formalCharge < 0 ? 1 : 2,
          'S' => 2,
          'P' => 3,
          _ => 1,
        };
        final h =
            explicitH[atom.id] ??
            (aromatic.contains(atom.id) && atom.element != 'C'
                ? 0
                : math.max(0, (target - valence).floor()));
        atoms.add(atom.copyWith(implicitHydrogens: h));
        counts.update(atom.element, (n) => n + 1, ifAbsent: () => 1);
        counts.update('H', (n) => n + h, ifAbsent: () => h);
      }
      final formula = SpectroscopyService.parseFormula(
        compound.formula.replaceAll('BR', 'Br').replaceAll('CL', 'Cl'),
      );
      final expected = {
        'C': formula.carbons,
        'H': formula.hydrogens,
        'N': formula.nitrogens,
        'O': formula.oxygens,
        'F': formula.fluorines,
        'Cl': formula.chlorines,
        'Br': formula.bromines,
        'I': formula.iodines,
        'S': formula.sulfurs,
        'P': formula.phosphoruses,
      };
      if (!formula.isValid ||
          expected.entries.any((e) => (counts[e.key] ?? 0) != e.value)) {
        return const SpectroscopyStructureDepiction(
          error: 'The reference SMILES does not pass the molecular formula check. Structure drawing withheld; review the reference data.',
        );
      }
      final graph = SpectroscopyGraphLayout.layout(
        ChemicalGraph(
          id: 'spectroscopy-candidate',
          smiles: compound.smiles,
          atoms: atoms,
          bonds: bonds,
        ),
      );
      return SpectroscopyStructureDepiction(
        svg: _render(graph, foreground, background),
        graph: graph,
      );
    } catch (_) {
      return const SpectroscopyStructureDepiction(
        error: 'A reliable drawing could not be generated for this reference.',
      );
    }
  }

  static String _render(
    ChemicalGraph graph,
    String foreground,
    String background,
  ) {
    final bounds = graph.getBounds();
    final rings = SpectroscopyGraphLayout.rings(graph);
    final width = math.max(1, bounds.maxX - bounds.minX);
    final height = math.max(1, bounds.maxY - bounds.minY);
    final scale = math.min(460 / width, math.min(200 / height, 1.8));
    double x(ChemicalAtom a) =>
        300 + (a.x - (bounds.maxX + bounds.minX) / 2) * scale;
    double y(ChemicalAtom a) =>
        145 + (a.y - (bounds.maxY + bounds.minY) / 2) * scale;
    final b = StringBuffer(
      '<svg xmlns="http://www.w3.org/2000/svg" width="600" height="290" viewBox="0 0 600 290">',
    );
    b.writeln(
      '<title>Molecular structure</title><desc>${SpectrumSvgRenderer.escape(graph.smiles)}</desc><rect width="600" height="290" rx="16" fill="$background"/>',
    );
    for (final bond in graph.bonds) {
      final a = graph.getAtom(bond.atom1Id)!;
      final c = graph.getAtom(bond.atom2Id)!;
      final dx = x(c) - x(a), dy = y(c) - y(a);
      final length = math.sqrt(dx * dx + dy * dy);
      if (length < 0.001) continue;
      final px = -dy / length * 3, py = dx / length * 3;
      void line(double offset, {bool dashed = false}) {
        b.writeln(
          '<line x1="${x(a) + offset * px}" y1="${y(a) + offset * py}" x2="${x(c) + offset * px}" y2="${y(c) + offset * py}" stroke="$foreground" stroke-width="2.2" stroke-linecap="round" ${dashed ? 'stroke-dasharray="4 3"' : ''}/>',
        );
      }

      switch (bond.type) {
        case BondType.double:
          line(-1);
          line(1);
        case BondType.triple:
          line(-1.5);
          line(0);
          line(1.5);
        case BondType.aromatic:
          line(0);
          final ring = rings.firstWhere(
            (ring) => ring.contains(a.id) && ring.contains(c.id),
          );
          final middleX =
              ring.map((id) => x(graph.getAtom(id)!)).reduce((a, b) => a + b) /
              ring.length;
          final middleY =
              ring.map((id) => y(graph.getAtom(id)!)).reduce((a, b) => a + b) /
              ring.length;
          final side =
              (middleX - (x(a) + x(c)) / 2) * px +
                      (middleY - (y(a) + y(c)) / 2) * py >=
                  0
              ? 1
              : -1;
          b.writeln(
            '<line x1="${x(a) + dx * .12 + side * px * 1.8}" y1="${y(a) + dy * .12 + side * py * 1.8}" x2="${x(c) - dx * .12 + side * px * 1.8}" y2="${y(c) - dy * .12 + side * py * 1.8}" stroke="$foreground" stroke-width="1.5" stroke-dasharray="4 3"/>',
          );
        default:
          line(0);
      }
    }
    for (final atom in graph.atoms.where(
      (a) => a.element != 'C' || a.formalCharge != 0,
    )) {
      final h = atom.implicitHydrogens;
      final suffix = atom.formalCharge == 0
          ? ''
          : atom.formalCharge == 1
          ? '⁺'
          : atom.formalCharge == -1
          ? '⁻'
          : '${atom.formalCharge > 0 ? '+' : ''}${atom.formalCharge}';
      final label =
          '${atom.element}${h == 0
              ? ''
              : h == 1
              ? 'H'
              : 'H$h'}$suffix';
      final color = switch (atom.element) {
        'O' => '#D64A5C',
        'N' => '#1688B0',
        'Br' => '#BB661A',
        'Cl' || 'F' => '#17845B',
        _ => foreground,
      };
      b.writeln(
        '<rect x="${x(atom) - 11}" y="${y(atom) - 13}" width="${math.max(22, label.length * 11)}" height="26" rx="5" fill="$background"/>',
      );
      b.writeln(
        '<text x="${x(atom)}" y="${y(atom) + 6}" text-anchor="middle" fill="$color" font-family="sans-serif" font-size="19" font-weight="600">${SpectrumSvgRenderer.escape(label)}</text>',
      );
    }
    b.writeln('</svg>');
    return b.toString();
  }
}
