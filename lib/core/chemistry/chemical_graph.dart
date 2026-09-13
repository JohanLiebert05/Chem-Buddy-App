import 'dart:math' as math;

/// Represents the bond type between two atoms in a chemical structure.
enum BondType {
  single,
  double,
  triple,
  aromatic,
  wedge,
  dash,
}

/// Represents an atom in a 2D chemical structure graph.
class ChemicalAtom {
  final String id;
  final String element;
  final double x;
  final double y;
  final int formalCharge;
  final int implicitHydrogens;
  final bool isRadical;
  final String? role; // e.g., 'nucleophile', 'electrophile', 'leaving_group'

  const ChemicalAtom({
    required this.id,
    required this.element,
    required this.x,
    required this.y,
    this.formalCharge = 0,
    this.implicitHydrogens = 0,
    this.isRadical = false,
    this.role,
  });

  ChemicalAtom copyWith({
    String? id,
    String? element,
    double? x,
    double? y,
    int? formalCharge,
    int? implicitHydrogens,
    bool? isRadical,
    String? role,
  }) {
    return ChemicalAtom(
      id: id ?? this.id,
      element: element ?? this.element,
      x: x ?? this.x,
      y: y ?? this.y,
      formalCharge: formalCharge ?? this.formalCharge,
      implicitHydrogens: implicitHydrogens ?? this.implicitHydrogens,
      isRadical: isRadical ?? this.isRadical,
      role: role ?? this.role,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'element': element,
        'x': x,
        'y': y,
        'formalCharge': formalCharge,
        'implicitHydrogens': implicitHydrogens,
        'isRadical': isRadical,
        if (role != null) 'role': role,
      };

  factory ChemicalAtom.fromJson(Map<String, dynamic> json) => ChemicalAtom(
        id: json['id'] as String,
        element: json['element'] as String? ?? 'C',
        x: (json['x'] as num).toDouble(),
        y: (json['y'] as num).toDouble(),
        formalCharge: (json['formalCharge'] as num?)?.toInt() ?? 0,
        implicitHydrogens: (json['implicitHydrogens'] as num?)?.toInt() ?? 0,
        isRadical: json['isRadical'] as bool? ?? false,
        role: json['role'] as String?,
      );
}

/// Represents a bond connecting two atoms in a chemical structure.
class ChemicalBond {
  final String id;
  final String atom1Id;
  final String atom2Id;
  final BondType type;
  final bool isReacting; // Highlighted during mechanism step

  const ChemicalBond({
    required this.id,
    required this.atom1Id,
    required this.atom2Id,
    this.type = BondType.single,
    this.isReacting = false,
  });

  ChemicalBond copyWith({
    String? id,
    String? atom1Id,
    String? atom2Id,
    BondType? type,
    bool? isReacting,
  }) {
    return ChemicalBond(
      id: id ?? this.id,
      atom1Id: atom1Id ?? this.atom1Id,
      atom2Id: atom2Id ?? this.atom2Id,
      type: type ?? this.type,
      isReacting: isReacting ?? this.isReacting,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'atom1Id': atom1Id,
        'atom2Id': atom2Id,
        'type': type.name,
        'isReacting': isReacting,
      };

  factory ChemicalBond.fromJson(Map<String, dynamic> json) => ChemicalBond(
        id: json['id'] as String,
        atom1Id: json['atom1Id'] as String,
        atom2Id: json['atom2Id'] as String,
        type: BondType.values.firstWhere(
          (t) => t.name == json['type'],
          orElse: () => BondType.single,
        ),
        isReacting: json['isReacting'] as bool? ?? false,
      );
}

/// A complete 2D chemical structure graph with deterministic atom coordinates.
class ChemicalGraph {
  final String id;
  final String name;
  final String smiles;
  final List<ChemicalAtom> atoms;
  final List<ChemicalBond> bonds;

  const ChemicalGraph({
    required this.id,
    this.name = '',
    this.smiles = '',
    required this.atoms,
    required this.bonds,
  });

  ChemicalAtom? getAtom(String id) {
    try {
      return atoms.firstWhere((a) => a.id == id);
    } catch (_) {
      return null;
    }
  }

  ChemicalBond? getBond(String id) {
    try {
      return bonds.firstWhere((b) => b.id == id);
    } catch (_) {
      return null;
    }
  }

  ChemicalBond? findBondBetween(String atom1, String atom2) {
    try {
      return bonds.firstWhere(
        (b) =>
            (b.atom1Id == atom1 && b.atom2Id == atom2) ||
            (b.atom1Id == atom2 && b.atom2Id == atom1),
      );
    } catch (_) {
      return null;
    }
  }

  /// Calculates the bounding box (minX, minY, maxX, maxY) for layout scaling.
  ({double minX, double minY, double maxX, double maxY}) getBounds() {
    if (atoms.isEmpty) return (minX: 0.0, minY: 0.0, maxX: 100.0, maxY: 100.0);
    double minX = atoms.first.x;
    double maxX = atoms.first.x;
    double minY = atoms.first.y;
    double maxY = atoms.first.y;

    for (final a in atoms) {
      if (a.x < minX) minX = a.x;
      if (a.x > maxX) maxX = a.x;
      if (a.y < minY) minY = a.y;
      if (a.y > maxY) maxY = a.y;
    }
    return (minX: minX, minY: minY, maxX: maxX, maxY: maxY);
  }

  /// Returns a translated/offset copy of this graph.
  ChemicalGraph translate(double dx, double dy) {
    final newAtoms = atoms
        .map((a) => a.copyWith(x: a.x + dx, y: a.y + dy))
        .toList();
    return ChemicalGraph(
      id: id,
      name: name,
      smiles: smiles,
      atoms: newAtoms,
      bonds: bonds,
    );
  }

  /// Returns a scaled copy of this graph around its centroid.
  ChemicalGraph scale(double factor) {
    if (atoms.isEmpty) return this;
    final bounds = getBounds();
    final cx = (bounds.minX + bounds.maxX) / 2.0;
    final cy = (bounds.minY + bounds.maxY) / 2.0;

    final newAtoms = atoms.map((a) {
      final nx = cx + (a.x - cx) * factor;
      final ny = cy + (a.y - cy) * factor;
      return a.copyWith(x: nx, y: ny);
    }).toList();

    return ChemicalGraph(
      id: id,
      name: name,
      smiles: smiles,
      atoms: newAtoms,
      bonds: bonds,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'smiles': smiles,
        'atoms': atoms.map((a) => a.toJson()).toList(),
        'bonds': bonds.map((b) => b.toJson()).toList(),
      };

  factory ChemicalGraph.fromJson(Map<String, dynamic> json) => ChemicalGraph(
        id: json['id'] as String,
        name: json['name'] as String? ?? '',
        smiles: json['smiles'] as String? ?? '',
        atoms: (json['atoms'] as List<dynamic>? ?? [])
            .map((a) => ChemicalAtom.fromJson(a as Map<String, dynamic>))
            .toList(),
        bonds: (json['bonds'] as List<dynamic>? ?? [])
            .map((b) => ChemicalBond.fromJson(b as Map<String, dynamic>))
            .toList(),
      );

  // ---------------------------------------------------------------------------
  // BUILT-IN COMMON CHEMICAL GRAPH TEMPLATES FOR MECHANISMS
  // ---------------------------------------------------------------------------

  /// Benzene ring centered at (cx, cy) with radius r
  static ChemicalGraph createBenzene({
    String id = 'benzene',
    double cx = 100,
    double cy = 100,
    double r = 40,
  }) {
    final atoms = <ChemicalAtom>[];
    final bonds = <ChemicalBond>[];

    for (int i = 0; i < 6; i++) {
      final angle = (i * 60 - 30) * math.pi / 180;
      final x = cx + r * math.cos(angle);
      final y = cy + r * math.sin(angle);
      atoms.add(ChemicalAtom(id: 'C${i + 1}', element: 'C', x: x, y: y));
    }

    for (int i = 0; i < 6; i++) {
      final next = (i + 1) % 6;
      bonds.add(ChemicalBond(
        id: 'B${i + 1}',
        atom1Id: atoms[i].id,
        atom2Id: atoms[next].id,
        type: i % 2 == 0 ? BondType.double : BondType.single,
      ));
    }

    return ChemicalGraph(
      id: id,
      name: 'Benzene',
      smiles: 'c1ccccc1',
      atoms: atoms,
      bonds: bonds,
    );
  }

  /// Carbonyl group C=O with customizable substituents
  static ChemicalGraph createCarbonyl({
    String id = 'carbonyl',
    double cx = 100,
    double cy = 100,
    String r1 = 'CH3',
    String r2 = 'H',
  }) {
    final atoms = <ChemicalAtom>[
      ChemicalAtom(id: 'C_carbonyl', element: 'C', x: cx, y: cy, role: 'electrophile'),
      ChemicalAtom(id: 'O_carbonyl', element: 'O', x: cx, y: cy - 45, role: 'leaving_group'),
      ChemicalAtom(id: 'R1', element: r1, x: cx - 40, y: cy + 30),
      ChemicalAtom(id: 'R2', element: r2, x: cx + 40, y: cy + 30),
    ];

    final bonds = <ChemicalBond>[
      const ChemicalBond(id: 'B_CO', atom1Id: 'C_carbonyl', atom2Id: 'O_carbonyl', type: BondType.double),
      const ChemicalBond(id: 'B_CR1', atom1Id: 'C_carbonyl', atom2Id: 'R1', type: BondType.single),
      const ChemicalBond(id: 'B_CR2', atom1Id: 'C_carbonyl', atom2Id: 'R2', type: BondType.single),
    ];

    return ChemicalGraph(
      id: id,
      name: 'Carbonyl Group',
      atoms: atoms,
      bonds: bonds,
    );
  }

  /// Alkyl halide R-CH2-LG for SN2/E2
  static ChemicalGraph createAlkylHalide({
    String id = 'alkyl_halide',
    double cx = 100,
    double cy = 100,
    String lg = 'Br',
  }) {
    final atoms = <ChemicalAtom>[
      ChemicalAtom(id: 'C_alpha', element: 'C', x: cx, y: cy, role: 'electrophile'),
      ChemicalAtom(id: 'LG', element: lg, x: cx + 45, y: cy, role: 'leaving_group'),
      ChemicalAtom(id: 'H1', element: 'H', x: cx, y: cy - 35),
      ChemicalAtom(id: 'H2', element: 'H', x: cx, y: cy + 35),
      ChemicalAtom(id: 'R', element: 'CH3', x: cx - 45, y: cy),
    ];

    final bonds = <ChemicalBond>[
      const ChemicalBond(id: 'B_CLG', atom1Id: 'C_alpha', atom2Id: 'LG', type: BondType.single),
      const ChemicalBond(id: 'B_CH1', atom1Id: 'C_alpha', atom2Id: 'H1', type: BondType.wedge),
      const ChemicalBond(id: 'B_CH2', atom1Id: 'C_alpha', atom2Id: 'H2', type: BondType.dash),
      const ChemicalBond(id: 'B_CR', atom1Id: 'C_alpha', atom2Id: 'R', type: BondType.single),
    ];

    return ChemicalGraph(
      id: id,
      name: 'Alkyl Halide',
      atoms: atoms,
      bonds: bonds,
    );
  }
}
