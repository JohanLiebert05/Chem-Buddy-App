import '../../core/widgets/molecule_3d/molecule_3d_models.dart';

/// Curated library of 3D molecular structures for MSc Chemistry reaction mechanisms.
/// Provides geometrically accurate Reactants, Intermediates / Transition States, and Products.
class Reaction3DDatabase {
  Reaction3DDatabase._();

  static final Map<String, Reaction3DSet> _catalog = {
    // -------------------------------------------------------------
    // 1. SN1 SUBSTITUTION
    // -------------------------------------------------------------
    'sn1': Reaction3DSet(
      reactionId: 'sn1',
      title: 'SN1 Nucleophilic Substitution',
      keyTransformationNote:
          'Observe the transition from tetrahedral sp³ reactant to the flat planar sp² carbocation with empty p-orbital, followed by nucleophilic attack to yield tetrahedral product.',
      reactant: const Molecule3D(
        id: 'sn1_reactant',
        name: 'tert-Butyl Bromide',
        formula: 'C4H9Br',
        iupacName: '2-bromo-2-methylpropane',
        description: 'Tetrahedral sp³ central carbon bonded to Br and 3 methyl groups.',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Electrophilic quaternary center'),
          Atom3D(symbol: 'Br', x: 0.0, y: 0.0, z: 1.95, note: 'Leaving group: weak C-Br bond'),
          Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: -0.52, hybridization: 'sp³', note: 'Methyl group 1'),
          Atom3D(symbol: 'C', x: -0.72, y: 1.25, z: -0.52, hybridization: 'sp³', note: 'Methyl group 2'),
          Atom3D(symbol: 'C', x: -0.72, y: -1.25, z: -0.52, hybridization: 'sp³', note: 'Methyl group 3'),
          Atom3D(symbol: 'H', x: 1.50, y: 0.90, z: -1.05),
          Atom3D(symbol: 'H', x: 1.50, y: -0.90, z: -1.05),
          Atom3D(symbol: 'H', x: -0.75, y: 2.15, z: -0.05),
          Atom3D(symbol: 'H', x: -0.75, y: -2.15, z: -0.05),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
          Bond3D(atomIndex1: 2, atomIndex2: 5),
          Bond3D(atomIndex1: 2, atomIndex2: 6),
          Bond3D(atomIndex1: 3, atomIndex2: 7),
          Bond3D(atomIndex1: 4, atomIndex2: 8),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'sn1_intermediate',
        name: 'tert-Butyl Carbocation + Br⁻',
        formula: '[C(CH3)3]⁺ + Br⁻',
        iupacName: '2-methylpropan-2-ylium',
        description: 'Trigonal planar sp² carbon (120° bond angles) stabilized by hyperconjugation, with departed Bromide ion.',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', formalCharge: '+1', note: 'Planar sp² carbocation with empty p-orbital'),
          Atom3D(symbol: 'C', x: 1.50, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Hyperconjugating methyl'),
          Atom3D(symbol: 'C', x: -0.75, y: 1.30, z: 0.0, hybridization: 'sp³', note: 'Hyperconjugating methyl'),
          Atom3D(symbol: 'C', x: -0.75, y: -1.30, z: 0.0, hybridization: 'sp³', note: 'Hyperconjugating methyl'),
          Atom3D(symbol: 'Br', x: 0.0, y: 0.0, z: 3.10, formalCharge: '-1', note: 'Departed solvated bromide anion'),
          Atom3D(symbol: 'H', x: 1.95, y: 0.88, z: 0.45),
          Atom3D(symbol: 'H', x: 1.95, y: -0.88, z: -0.45),
          Atom3D(symbol: 'H', x: -1.15, y: 1.85, z: 0.85),
          Atom3D(symbol: 'H', x: -1.15, y: -1.85, z: -0.85),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 1, atomIndex2: 5),
          Bond3D(atomIndex1: 1, atomIndex2: 6),
          Bond3D(atomIndex1: 2, atomIndex2: 7),
          Bond3D(atomIndex1: 3, atomIndex2: 8),
          Bond3D(atomIndex1: 0, atomIndex2: 4, type: BondType3D.partial),
        ],
      ),
      product: const Molecule3D(
        id: 'sn1_product',
        name: 'tert-Butanol',
        formula: 'C4H10O',
        iupacName: '2-methylpropan-2-ol',
        description: 'Substituted product after nucleophilic attack and proton transfer.',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Restored tetrahedral sp³ center'),
          Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.45, hybridization: 'sp³', note: 'Hydroxyl oxygen'),
          Atom3D(symbol: 'H', x: 0.85, y: 0.0, z: 1.85, note: 'Hydroxyl proton'),
          Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: -0.52, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: -0.72, y: 1.25, z: -0.52, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: -0.72, y: -1.25, z: -0.52, hybridization: 'sp³'),
          Atom3D(symbol: 'H', x: 1.50, y: 0.90, z: -1.05),
          Atom3D(symbol: 'H', x: -0.75, y: 2.15, z: -0.05),
          Atom3D(symbol: 'H', x: -0.75, y: -2.15, z: -0.05),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
          Bond3D(atomIndex1: 0, atomIndex2: 5),
          Bond3D(atomIndex1: 3, atomIndex2: 6),
          Bond3D(atomIndex1: 4, atomIndex2: 7),
          Bond3D(atomIndex1: 5, atomIndex2: 8),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 2. SN2 SUBSTITUTION
    // -------------------------------------------------------------
    'sn2': Reaction3DSet(
      reactionId: 'sn2',
      title: 'SN2 Nucleophilic Substitution',
      keyTransformationNote:
          'Explore Walden Inversion! The incoming hydroxide attacks 180° opposite bromide through a pentacoordinate trigonal bipyramidal transition state.',
      reactant: const Molecule3D(
        id: 'sn2_reactant',
        name: 'Bromomethane + Hydroxide',
        formula: 'CH3Br + OH⁻',
        iupacName: 'bromomethane',
        description: 'Tetrahedral methyl bromide with approaching nucleophile.',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'Br', x: 1.95, y: 0.0, z: 0.0, note: 'Leaving group'),
          Atom3D(symbol: 'H', x: -0.35, y: 1.02, z: 0.0),
          Atom3D(symbol: 'H', x: -0.35, y: -0.51, z: 0.88),
          Atom3D(symbol: 'H', x: -0.35, y: -0.51, z: -0.88),
          Atom3D(symbol: 'O', x: -3.20, y: 0.0, z: 0.0, note: 'Approaching nucleophile OH⁻'),
          Atom3D(symbol: 'H', x: -3.80, y: 0.70, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
          Bond3D(atomIndex1: 5, atomIndex2: 6),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'sn2_transition_state',
        name: '[HO···CH3···Br]‡ Transition State',
        formula: '[HO-CH3-Br]‡⁻',
        iupacName: 'pentacoordinate transition state',
        description: 'Trigonal bipyramidal TS: planar C-H3 equator with collinear axial O---C---Br forming and breaking bonds.',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Planar equatorial carbon (sp²)'),
          Atom3D(symbol: 'O', x: -1.90, y: 0.0, z: 0.0, note: 'Partial forming bond (axial)'),
          Atom3D(symbol: 'Br', x: 2.15, y: 0.0, z: 0.0, note: 'Partial breaking bond (axial)'),
          Atom3D(symbol: 'H', x: 0.0, y: 1.08, z: 0.0, note: 'Equatorial hydrogen'),
          Atom3D(symbol: 'H', x: 0.0, y: -0.54, z: 0.93, note: 'Equatorial hydrogen'),
          Atom3D(symbol: 'H', x: 0.0, y: -0.54, z: -0.93, note: 'Equatorial hydrogen'),
          Atom3D(symbol: 'H', x: -2.50, y: 0.65, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.partial),
          Bond3D(atomIndex1: 0, atomIndex2: 2, type: BondType3D.partial),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
          Bond3D(atomIndex1: 0, atomIndex2: 5),
          Bond3D(atomIndex1: 1, atomIndex2: 6),
        ],
      ),
      product: const Molecule3D(
        id: 'sn2_product',
        name: 'Methanol (Inverted) + Br⁻',
        formula: 'CH3OH + Br⁻',
        iupacName: 'methanol',
        description: 'Complete Walden inversion: umbrella turned inside out.',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'O', x: -1.43, y: 0.0, z: 0.0),
          Atom3D(symbol: 'H', x: -1.85, y: 0.85, z: 0.0),
          Atom3D(symbol: 'H', x: 0.35, y: 1.02, z: 0.0),
          Atom3D(symbol: 'H', x: 0.35, y: -0.51, z: 0.88),
          Atom3D(symbol: 'H', x: 0.35, y: -0.51, z: -0.88),
          Atom3D(symbol: 'Br', x: 3.50, y: 0.0, z: 0.0, formalCharge: '-1'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
          Bond3D(atomIndex1: 0, atomIndex2: 5),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 3. E1 ELIMINATION
    // -------------------------------------------------------------
    'e1': Reaction3DSet(
      reactionId: 'e1',
      title: 'E1 Elimination Reaction',
      keyTransformationNote:
          'Loss of halide generates planar carbocation; subsequent base-assisted deprotonation of β-H collapses C-H σ into C=C π double bond.',
      reactant: const Molecule3D(
        id: 'e1_reactant',
        name: '2-Bromo-2-methylbutane',
        formula: 'C5H11Br',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'Br', x: 0.0, y: 0.0, z: 1.95),
          Atom3D(symbol: 'C', x: 1.50, y: 0.0, z: -0.50, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: -1.50, y: 0.0, z: -0.50, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: -2.30, y: 1.25, z: -0.20, hybridization: 'sp³'),
          Atom3D(symbol: 'H', x: -1.45, y: -0.85, z: 0.15, note: 'β-Hydrogen for Zaitsev elimination'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 3, atomIndex2: 5),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'e1_intermediate',
        name: 'tert-Amyl Carbocation',
        formula: '[C5H11]⁺',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', formalCharge: '+1'),
          Atom3D(symbol: 'C', x: 1.48, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: -1.48, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: -2.35, y: 1.22, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'H', x: -1.50, y: -0.90, z: 0.50, note: 'Hyperconjugating β-H aligned with p-orbital'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 2, atomIndex2: 4),
        ],
      ),
      product: const Molecule3D(
        id: 'e1_product',
        name: '2-Methylbut-2-ene (Zaitsev)',
        formula: 'C5H10',
        atoms: [
          Atom3D(symbol: 'C', x: 0.67, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: -0.67, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: 1.45, y: 1.25, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: 1.45, y: -1.25, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: -1.45, y: 1.25, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'H', x: -1.20, y: -0.95, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 1, atomIndex2: 4),
          Bond3D(atomIndex1: 1, atomIndex2: 5),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 4. E2 ELIMINATION
    // -------------------------------------------------------------
    'e2': Reaction3DSet(
      reactionId: 'e2',
      title: 'E2 Bimolecular Elimination',
      keyTransformationNote:
          'Requires strict anti-periplanar (180° dihedral angle) geometry between the leaving group and the β-proton for orbital overlap.',
      reactant: const Molecule3D(
        id: 'e2_reactant',
        name: 'Anti-Periplanar Haloalkane',
        formula: 'R-CH2-CH2-Br',
        atoms: [
          Atom3D(symbol: 'C', x: -0.77, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'C(β) with anti-H'),
          Atom3D(symbol: 'C', x: 0.77, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'C(α) with Br'),
          Atom3D(symbol: 'H', x: -1.20, y: 1.05, z: 0.0, note: 'β-H at 180° to Br'),
          Atom3D(symbol: 'Br', x: 1.30, y: -1.85, z: 0.0, note: 'Leaving group Br'),
          Atom3D(symbol: 'H', x: -1.15, y: -0.50, z: 0.88),
          Atom3D(symbol: 'H', x: 1.15, y: 0.50, z: 0.88),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 1, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
          Bond3D(atomIndex1: 1, atomIndex2: 5),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'e2_transition_state',
        name: '[B···H···C=C···Br]‡ TS',
        formula: '[B-H-C2H4-Br]‡',
        atoms: [
          Atom3D(symbol: 'C', x: -0.70, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Rehybridizing toward sp²'),
          Atom3D(symbol: 'C', x: 0.70, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Rehybridizing toward sp²'),
          Atom3D(symbol: 'H', x: -1.40, y: 1.25, z: 0.0, note: 'Partially breaking C-H'),
          Atom3D(symbol: 'Br', x: 1.65, y: -2.10, z: 0.0, note: 'Partially breaking C-Br'),
          Atom3D(symbol: 'O', x: -2.25, y: 2.10, z: 0.0, note: 'Base oxygen capturing H'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.partial),
          Bond3D(atomIndex1: 0, atomIndex2: 2, type: BondType3D.partial),
          Bond3D(atomIndex1: 1, atomIndex2: 3, type: BondType3D.partial),
          Bond3D(atomIndex1: 2, atomIndex2: 4, type: BondType3D.partial),
        ],
      ),
      product: const Molecule3D(
        id: 'e2_product',
        name: 'Ethene (Alkene)',
        formula: 'C2H4',
        atoms: [
          Atom3D(symbol: 'C', x: -0.67, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: 0.67, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'H', x: -1.25, y: 0.92, z: 0.0),
          Atom3D(symbol: 'H', x: -1.25, y: -0.92, z: 0.0),
          Atom3D(symbol: 'H', x: 1.25, y: 0.92, z: 0.0),
          Atom3D(symbol: 'H', x: 1.25, y: -0.92, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 1, atomIndex2: 4),
          Bond3D(atomIndex1: 1, atomIndex2: 5),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 5. CANNIZZARO REACTION
    // -------------------------------------------------------------
    'cannizzaro': Reaction3DSet(
      reactionId: 'cannizzaro',
      title: 'Cannizzaro Reaction',
      keyTransformationNote:
          'Hydride transfer between non-enolizable aldehyde dianion/monoanion intermediate and a second aldehyde molecule.',
      reactant: const Molecule3D(
        id: 'cannizzaro_reactant',
        name: 'Benzaldehyde',
        formula: 'C7H6O',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 1.40, z: 0.0, hybridization: 'sp²', note: 'Carbonyl carbon'),
          Atom3D(symbol: 'O', x: 1.15, y: 1.85, z: 0.0),
          Atom3D(symbol: 'H', x: -0.90, y: 1.95, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Ipso carbon'),
          Atom3D(symbol: 'C', x: 1.20, y: -0.70, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: -1.20, y: -0.70, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: 1.20, y: -2.10, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: -1.20, y: -2.10, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: 0.0, y: -2.80, z: 0.0, hybridization: 'sp²'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.aromatic),
          Bond3D(atomIndex1: 3, atomIndex2: 5, type: BondType3D.aromatic),
          Bond3D(atomIndex1: 4, atomIndex2: 6, type: BondType3D.aromatic),
          Bond3D(atomIndex1: 5, atomIndex2: 7, type: BondType3D.aromatic),
          Bond3D(atomIndex1: 6, atomIndex2: 8, type: BondType3D.aromatic),
          Bond3D(atomIndex1: 7, atomIndex2: 8, type: BondType3D.aromatic),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'cannizzaro_intermediate',
        name: 'Hydride Transfer Transition State',
        formula: '[PhCH(O)OH···H···C(O)Ph]‡',
        atoms: [
          Atom3D(symbol: 'C', x: -1.35, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'O', x: -1.85, y: 1.25, z: 0.0),
          Atom3D(symbol: 'H', x: 0.0, y: 0.0, z: 0.0, note: 'Migrating hydride :H⁻'),
          Atom3D(symbol: 'C', x: 1.35, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 1.85, y: 1.25, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2, type: BondType3D.partial),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.partial),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
        ],
      ),
      product: const Molecule3D(
        id: 'cannizzaro_product',
        name: 'Benzoate + Benzyl Alcohol',
        formula: 'PhCOO⁻ + PhCH2OH',
        atoms: [
          Atom3D(symbol: 'C', x: -2.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Benzoate carbon'),
          Atom3D(symbol: 'O', x: -2.6, y: 1.1, z: 0.0),
          Atom3D(symbol: 'O', x: -2.6, y: -1.1, z: 0.0),
          Atom3D(symbol: 'C', x: 2.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Benzyl alcohol C'),
          Atom3D(symbol: 'O', x: 2.8, y: 1.1, z: 0.0),
          Atom3D(symbol: 'H', x: 2.3, y: -0.6, z: 0.8),
          Atom3D(symbol: 'H', x: 2.3, y: -0.6, z: -0.8),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 3, atomIndex2: 5),
          Bond3D(atomIndex1: 3, atomIndex2: 6),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 6. ALDOL CONDENSATION
    // -------------------------------------------------------------
    'aldol': Reaction3DSet(
      reactionId: 'aldol',
      title: 'Aldol Condensation',
      keyTransformationNote:
          'Enolate nucleophilic addition to acetaldehyde followed by E1cB dehydration to form conjugated crotonaldehyde.',
      reactant: const Molecule3D(
        id: 'aldol_reactant',
        name: 'Acetaldehyde + Enolate',
        formula: '2 CH3CHO',
        atoms: [
          Atom3D(symbol: 'C', x: -2.2, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: -2.2, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: -1.0, y: -0.75, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: 1.0, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Enolate carbanion'),
          Atom3D(symbol: 'C', x: 2.2, y: 0.75, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 2.2, y: 2.0, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'aldol_intermediate',
        name: '3-Hydroxybutanal (Aldol)',
        formula: 'CH3CH(OH)CH2CHO',
        atoms: [
          Atom3D(symbol: 'C', x: -1.85, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: -1.85, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: -0.65, y: -0.75, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: 0.65, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'O', x: 0.65, y: -1.25, z: 0.35),
          Atom3D(symbol: 'C', x: 1.85, y: 0.75, z: 0.0, hybridization: 'sp³'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 3, atomIndex2: 5),
        ],
      ),
      product: const Molecule3D(
        id: 'aldol_product',
        name: 'Crotonaldehyde',
        formula: 'CH3CH=CHCHO',
        atoms: [
          Atom3D(symbol: 'C', x: -1.85, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: -1.85, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: -0.65, y: -0.65, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: 0.65, y: -0.15, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: 1.85, y: -0.85, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'H', x: -2.75, y: -0.55, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 0, atomIndex2: 5),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 7. WITTIG REACTION
    // -------------------------------------------------------------
    'wittig': Reaction3DSet(
      reactionId: 'wittig',
      title: 'Wittig Reaction',
      keyTransformationNote:
          'Formation and collapse of the 4-membered oxaphosphetane ring driven by thermodynamic formation of the P=O bond.',
      reactant: const Molecule3D(
        id: 'wittig_reactant',
        name: 'Phosphonium Ylide + Formaldehyde',
        formula: 'Ph3P=CH2 + H2CO',
        atoms: [
          Atom3D(symbol: 'P', x: -1.2, y: 0.0, z: 0.0, note: 'Phosphorus center'),
          Atom3D(symbol: 'C', x: -0.1, y: 1.1, z: 0.0, note: 'Ylide carbanion'),
          Atom3D(symbol: 'C', x: 1.4, y: 0.0, z: 0.0, note: 'Carbonyl carbon'),
          Atom3D(symbol: 'O', x: 1.4, y: 1.25, z: 0.0, note: 'Carbonyl oxygen'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'wittig_intermediate',
        name: 'Oxaphosphetane (4-Ring)',
        formula: 'C2H4OP',
        atoms: [
          Atom3D(symbol: 'P', x: -0.85, y: -0.85, z: 0.0, note: 'Phosphorus center'),
          Atom3D(symbol: 'O', x: 0.85, y: -0.85, z: 0.0, note: 'Oxygen'),
          Atom3D(symbol: 'C', x: 0.85, y: 0.85, z: 0.0, note: 'Carbon 2'),
          Atom3D(symbol: 'C', x: -0.85, y: 0.85, z: 0.0, note: 'Carbon 1'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 0),
        ],
      ),
      product: const Molecule3D(
        id: 'wittig_product',
        name: 'Ethene + Triphenylphosphine Oxide',
        formula: 'CH2=CH2 + Ph3P=O',
        atoms: [
          Atom3D(symbol: 'C', x: 1.8, y: -0.67, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: 1.8, y: 0.67, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'P', x: -1.6, y: 0.0, z: 0.0),
          Atom3D(symbol: 'O', x: -0.2, y: 0.0, z: 0.0, note: 'Strong P=O bond (540 kJ/mol)'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 8. DIELS-ALDER CYCLOADDITION
    // -------------------------------------------------------------
    'diels_alder': Reaction3DSet(
      reactionId: 'diels_alder',
      title: 'Diels-Alder [4+2] Cycloaddition',
      keyTransformationNote:
          'Suprafacial-suprafacial overlap of s-cis butadiene (4π) and ethylene (2π) via a 6-electron aromatic transition state forming cyclohexene.',
      reactant: const Molecule3D(
        id: 'da_reactant',
        name: 's-cis Butadiene + Ethylene',
        formula: 'C4H6 + C2H4',
        atoms: [
          Atom3D(symbol: 'C', x: -1.2, y: 1.5, z: 0.5),
          Atom3D(symbol: 'C', x: -0.5, y: 0.5, z: 0.5),
          Atom3D(symbol: 'C', x: 0.5, y: 0.5, z: 0.5),
          Atom3D(symbol: 'C', x: 1.2, y: 1.5, z: 0.5),
          Atom3D(symbol: 'C', x: -0.67, y: 2.2, z: -1.2),
          Atom3D(symbol: 'C', x: 0.67, y: 2.2, z: -1.2),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.doubleBond),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'da_transition_state',
        name: 'Aromatic 6-Electron Transition State [‡]',
        formula: '[C6H10]‡',
        atoms: [
          Atom3D(symbol: 'C', x: -1.2, y: 1.2, z: 0.3),
          Atom3D(symbol: 'C', x: -0.65, y: 0.4, z: 0.2),
          Atom3D(symbol: 'C', x: 0.65, y: 0.4, z: 0.2),
          Atom3D(symbol: 'C', x: 1.2, y: 1.2, z: 0.3),
          Atom3D(symbol: 'C', x: 0.67, y: 1.8, z: -0.5),
          Atom3D(symbol: 'C', x: -0.67, y: 1.8, z: -0.5),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.partial),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.partial),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.partial),
          Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.partial),
          Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.partial),
          Bond3D(atomIndex1: 5, atomIndex2: 0, type: BondType3D.partial),
        ],
      ),
      product: const Molecule3D(
        id: 'da_product',
        name: 'Cyclohexene',
        formula: 'C6H10',
        atoms: [
          Atom3D(symbol: 'C', x: -1.25, y: 0.75, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: -0.67, y: -0.55, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: 0.67, y: -0.55, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: 1.25, y: 0.75, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: 0.65, y: 1.65, z: -0.35, hybridization: 'sp³'),
          Atom3D(symbol: 'C', x: -0.65, y: 1.65, z: 0.35, hybridization: 'sp³'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
          Bond3D(atomIndex1: 5, atomIndex2: 0),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 9. GRIGNARD REACTION
    // -------------------------------------------------------------
    'grignard': Reaction3DSet(
      reactionId: 'grignard',
      title: 'Grignard Reaction',
      keyTransformationNote:
          'Nucleophilic addition of MeMgBr to acetone carbonyl forming a magnesium alkoxide complex followed by hydrolysis to tert-butanol.',
      reactant: const Molecule3D(
        id: 'grignard_reactant',
        name: 'Acetone + Methylmagnesium Bromide',
        formula: '(CH3)2CO + CH3MgBr',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 0.0, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: 1.35, y: -0.65, z: 0.0),
          Atom3D(symbol: 'C', x: -1.35, y: -0.65, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: -2.2, z: 0.8, note: 'Nucleophilic methyl in MeMgBr'),
          Atom3D(symbol: 'Mg', x: 0.0, y: -2.2, z: 2.8),
          Atom3D(symbol: 'Br', x: 0.0, y: -2.2, z: 4.8),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
          Bond3D(atomIndex1: 5, atomIndex2: 6),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'grignard_intermediate',
        name: 'Halomagnesium Alkoxide Adduct',
        formula: '(CH3)3C-OMgBr',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.45),
          Atom3D(symbol: 'Mg', x: 0.0, y: 0.0, z: 3.35),
          Atom3D(symbol: 'Br', x: 0.0, y: 0.0, z: 5.35),
          Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: -0.52),
          Atom3D(symbol: 'C', x: -0.72, y: 1.25, z: -0.52),
          Atom3D(symbol: 'C', x: -0.72, y: -1.25, z: -0.52),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
          Bond3D(atomIndex1: 0, atomIndex2: 5),
          Bond3D(atomIndex1: 0, atomIndex2: 6),
        ],
      ),
      product: const Molecule3D(
        id: 'grignard_product',
        name: '2-Methylpropan-2-ol (tert-Butanol)',
        formula: '(CH3)3COH',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'O', x: 0.0, y: 0.0, z: 1.45),
          Atom3D(symbol: 'H', x: 0.85, y: 0.0, z: 1.85),
          Atom3D(symbol: 'C', x: 1.45, y: 0.0, z: -0.52),
          Atom3D(symbol: 'C', x: -0.72, y: 1.25, z: -0.52),
          Atom3D(symbol: 'C', x: -0.72, y: -1.25, z: -0.52),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
          Bond3D(atomIndex1: 0, atomIndex2: 5),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 10. BECKMANN REARRANGEMENT
    // -------------------------------------------------------------
    'beckmann': Reaction3DSet(
      reactionId: 'beckmann',
      title: 'Beckmann Rearrangement',
      keyTransformationNote:
          'Concerted anti-migration of alkyl group to nitrogen with simultaneous departure of water, generating nitrilium ion.',
      reactant: const Molecule3D(
        id: 'beckmann_reactant',
        name: 'Acetophenone Oxime',
        formula: 'PhC(Me)=N-OH',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'N', x: 1.25, y: 0.45, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 2.25, y: -0.55, z: 0.0, note: 'Anti-hydroxyl'),
          Atom3D(symbol: 'C', x: -1.25, y: -0.75, z: 0.0, note: 'Phenyl group anti to OH'),
          Atom3D(symbol: 'C', x: 0.0, y: 1.50, z: 0.0, note: 'Syn methyl group'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'beckmann_intermediate',
        name: 'Linear Nitrilium Ion',
        formula: '[Me-C≡N-Ph]⁺',
        atoms: [
          Atom3D(symbol: 'C', x: -1.20, y: 0.0, z: 0.0, note: 'Methyl group'),
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp', note: 'Linear nitrilium carbon'),
          Atom3D(symbol: 'N', x: 1.15, y: 0.0, z: 0.0, hybridization: 'sp', formalCharge: '+1'),
          Atom3D(symbol: 'C', x: 2.55, y: 0.0, z: 0.0, note: 'Migrated phenyl group'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.tripleBond),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
        ],
      ),
      product: const Molecule3D(
        id: 'beckmann_product',
        name: 'Acetanilide (Amide)',
        formula: 'CH3-CO-NH-Ph',
        atoms: [
          Atom3D(symbol: 'C', x: -1.45, y: -0.45, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: 0.15, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 0.25, y: 1.35, z: 0.0),
          Atom3D(symbol: 'N', x: 1.05, y: -0.75, z: 0.0),
          Atom3D(symbol: 'C', x: 2.45, y: -0.45, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 1, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 11. BENZOIN CONDENSATION
    // -------------------------------------------------------------
    'benzoin': Reaction3DSet(
      reactionId: 'benzoin',
      title: 'Benzoin Condensation',
      keyTransformationNote:
          'Cyanide catalyst reverses normal carbonyl electrophilic polarity into nucleophilic umpolung carbanion, attacking second aldehyde.',
      reactant: const Molecule3D(
        id: 'benzoin_reactant',
        name: '2 Benzaldehyde + Cyanide',
        formula: '2 PhCHO + CN⁻',
        atoms: [
          Atom3D(symbol: 'C', x: -1.6, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: -1.6, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: 1.6, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 1.6, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: -1.8, z: 0.0, note: 'Cyanide carbon'),
          Atom3D(symbol: 'N', x: 0.0, y: -3.0, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.tripleBond),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'benzoin_intermediate',
        name: 'Umpolung Carbanion Intermediate',
        formula: '[PhC(OH)(CN)]⁻',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, formalCharge: '-1', note: 'Reversed polarity carbanion'),
          Atom3D(symbol: 'O', x: 0.0, y: 1.40, z: 0.0),
          Atom3D(symbol: 'C', x: 1.40, y: 0.0, z: 0.0),
          Atom3D(symbol: 'N', x: 2.55, y: 0.0, z: 0.0),
          Atom3D(symbol: 'C', x: -1.45, y: -0.45, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.tripleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
        ],
      ),
      product: const Molecule3D(
        id: 'benzoin_product',
        name: 'Benzoin (α-Hydroxy Ketone)',
        formula: 'PhCH(OH)COPh',
        atoms: [
          Atom3D(symbol: 'C', x: -0.75, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'CH-OH center'),
          Atom3D(symbol: 'O', x: -0.75, y: 1.40, z: 0.0),
          Atom3D(symbol: 'C', x: 0.75, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'C=O carbonyl'),
          Atom3D(symbol: 'O', x: 0.75, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: -2.15, y: -0.65, z: 0.0),
          Atom3D(symbol: 'C', x: 2.15, y: -0.65, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
          Bond3D(atomIndex1: 2, atomIndex2: 5),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 12. MICHAEL ADDITION
    // -------------------------------------------------------------
    'michael': Reaction3DSet(
      reactionId: 'michael',
      title: 'Michael Addition',
      keyTransformationNote:
          '1,4-Conjugate addition of a soft resonance-stabilized enolate to the β-carbon of an α,β-unsaturated enone, yielding a 1,5-dicarbonyl adduct.',
      reactant: const Molecule3D(
        id: 'michael_reactant',
        name: 'Malonate Enolate + MVK',
        formula: 'CH(CO2Et)2⁻ + CH2=CHCOCH3',
        description: 'Enolate donor paired with electron-deficient conjugated acceptor.',
        atoms: [
          Atom3D(symbol: 'C', x: -2.0, y: 0.0, z: 0.0, note: 'Enolate donor carbanion'),
          Atom3D(symbol: 'C', x: -2.0, y: 1.4, z: 0.0),
          Atom3D(symbol: 'O', x: -2.0, y: 2.6, z: 0.0),
          Atom3D(symbol: 'C', x: 1.2, y: 0.0, z: 0.0, note: 'β-carbon of acceptor'),
          Atom3D(symbol: 'C', x: 2.4, y: 0.6, z: 0.0, note: 'α-carbon of acceptor'),
          Atom3D(symbol: 'C', x: 3.6, y: 0.0, z: 0.0, note: 'Carbonyl carbon'),
          Atom3D(symbol: 'O', x: 3.6, y: -1.2, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
          Bond3D(atomIndex1: 5, atomIndex2: 6, type: BondType3D.doubleBond),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'michael_intermediate',
        name: 'Extended Enolate Intermediate',
        formula: '[(EtO2C)2CH-CH2-CH=C(O⁻)Me]',
        description: 'New C-C σ bond formed between nucleophile and β-carbon; enolate oxyanion formed.',
        atoms: [
          Atom3D(symbol: 'C', x: -1.5, y: 0.0, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, note: 'Newly formed C-C bond'),
          Atom3D(symbol: 'C', x: 1.2, y: 0.8, z: 0.0),
          Atom3D(symbol: 'C', x: 2.4, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 2.4, y: -1.3, z: 0.0, note: 'Enolate oxyanion O⁻'),
          Atom3D(symbol: 'C', x: 3.7, y: 0.7, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 3, atomIndex2: 5),
        ],
      ),
      product: const Molecule3D(
        id: 'michael_product',
        name: '1,5-Dicarbonyl Michael Adduct',
        formula: 'R-CH2-CH2-CO-CH3',
        description: 'Protonated neutral 1,5-dicarbonyl compound in stable staggered conformation.',
        atoms: [
          Atom3D(symbol: 'C', x: -2.4, y: 0.0, z: 0.0),
          Atom3D(symbol: 'C', x: -1.0, y: 0.5, z: 0.0),
          Atom3D(symbol: 'C', x: 0.2, y: -0.3, z: 0.0),
          Atom3D(symbol: 'C', x: 1.5, y: 0.5, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 1.5, y: 1.7, z: 0.0),
          Atom3D(symbol: 'C', x: 2.8, y: -0.3, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 3, atomIndex2: 5),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 13. CLAISEN CONDENSATION
    // -------------------------------------------------------------
    'claisen': Reaction3DSet(
      reactionId: 'claisen',
      title: 'Claisen Ester Condensation',
      keyTransformationNote:
          'Base-induced condensation of esters through nucleophilic acyl substitution; expulsion of ethoxide yields β-keto ester.',
      reactant: const Molecule3D(
        id: 'claisen_reactant',
        name: 'Ethyl Acetate + Ester Enolate',
        formula: 'CH3COOEt + ⁻CH2COOEt',
        atoms: [
          Atom3D(symbol: 'C', x: -1.8, y: 0.0, z: 0.0, note: 'Ester enolate C⁻'),
          Atom3D(symbol: 'C', x: -1.8, y: 1.3, z: 0.0),
          Atom3D(symbol: 'O', x: -1.8, y: 2.5, z: 0.0),
          Atom3D(symbol: 'C', x: 1.4, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Electrophilic ester C=O'),
          Atom3D(symbol: 'O', x: 1.4, y: 1.25, z: 0.0),
          Atom3D(symbol: 'O', x: 2.5, y: -0.7, z: 0.0, note: 'Ethoxy leaving group'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 3, atomIndex2: 5),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'claisen_intermediate',
        name: 'Tetrahedral Intermediate',
        formula: '[CH3-C(O⁻)(OEt)-CH2COOEt]',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³', note: 'Tetrahedral center'),
          Atom3D(symbol: 'O', x: 0.0, y: 1.4, z: 0.0, note: 'Alkoxide oxyanion O⁻'),
          Atom3D(symbol: 'O', x: 1.3, y: -0.5, z: 0.0, note: 'EtO leaving group'),
          Atom3D(symbol: 'C', x: -1.3, y: -0.7, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 1.5),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
        ],
      ),
      product: const Molecule3D(
        id: 'claisen_product',
        name: 'Ethyl Acetoacetate (β-Keto Ester)',
        formula: 'CH3COCH2COOEt',
        atoms: [
          Atom3D(symbol: 'C', x: -2.4, y: -0.5, z: 0.0),
          Atom3D(symbol: 'C', x: -1.2, y: 0.2, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: -1.2, y: 1.4, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: -0.6, z: 0.0, note: 'Acidic α-methylene (pKa ~11)'),
          Atom3D(symbol: 'C', x: 1.3, y: 0.2, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 1.3, y: 1.4, z: 0.0),
          Atom3D(symbol: 'O', x: 2.4, y: -0.5, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 1, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 4, atomIndex2: 6),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 14. BAEYER-VILLIGER OXIDATION
    // -------------------------------------------------------------
    'baeyer_villiger': Reaction3DSet(
      reactionId: 'baeyer_villiger',
      title: 'Baeyer-Villiger Oxidation',
      keyTransformationNote:
          'Peracid nucleophilic addition produces tetrahedral Criegee intermediate followed by concerted 1,2-migration with retention of stereochemistry.',
      reactant: const Molecule3D(
        id: 'bv_reactant',
        name: 'Acetophenone + Peracid',
        formula: 'PhCOCH3 + RCOOOH',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 0.0, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: -1.4, y: -0.6, z: 0.0, note: 'Phenyl group'),
          Atom3D(symbol: 'C', x: 1.3, y: -0.6, z: 0.0, note: 'Methyl group'),
          Atom3D(symbol: 'O', x: 0.0, y: -1.8, z: 0.8, note: 'Peroxy OH'),
          Atom3D(symbol: 'O', x: 0.0, y: -2.8, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'bv_intermediate',
        name: 'Criegee Intermediate [‡]',
        formula: '[Ph(Me)C(OH)-O-O-COR]',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'O', x: 0.0, y: 1.4, z: 0.0),
          Atom3D(symbol: 'O', x: 1.3, y: 0.0, z: 0.0, note: 'Peroxy bridge O-O'),
          Atom3D(symbol: 'O', x: 2.3, y: 0.9, z: 0.0),
          Atom3D(symbol: 'C', x: -1.3, y: 0.6, z: 0.0, note: 'Migrating phenyl group'),
          Atom3D(symbol: 'C', x: -0.5, y: -1.3, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.partial),
          Bond3D(atomIndex1: 0, atomIndex2: 4, type: BondType3D.partial),
          Bond3D(atomIndex1: 0, atomIndex2: 5),
        ],
      ),
      product: const Molecule3D(
        id: 'bv_product',
        name: 'Phenyl Acetate (Ester)',
        formula: 'CH3-COO-Ph',
        atoms: [
          Atom3D(symbol: 'C', x: 1.3, y: 0.0, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: 0.6, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 0.0, y: 1.8, z: 0.0),
          Atom3D(symbol: 'O', x: -1.2, y: -0.2, z: 0.0, note: 'Inserted oxygen'),
          Atom3D(symbol: 'C', x: -2.4, y: 0.5, z: 0.0, note: 'Phenyl group'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 1, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 15. FAVORSKII REARRANGEMENT
    // -------------------------------------------------------------
    'favorskii': Reaction3DSet(
      reactionId: 'favorskii',
      title: 'Favorskii Rearrangement',
      keyTransformationNote:
          'Deprotonation of α-haloketone causes intramolecular displacement to a strained cyclopropanone, which cleaves to relieve angle strain.',
      reactant: const Molecule3D(
        id: 'favorskii_reactant',
        name: '2-Chlorocyclohexanone',
        formula: 'C6H9ClO',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 1.2, z: 0.0, hybridization: 'sp²', note: 'Carbonyl C1'),
          Atom3D(symbol: 'O', x: 0.0, y: 2.4, z: 0.0),
          Atom3D(symbol: 'C', x: 1.2, y: 0.5, z: 0.0, note: 'C2 with Cl'),
          Atom3D(symbol: 'Cl', x: 2.5, y: 1.4, z: 0.0, note: 'Leaving group'),
          Atom3D(symbol: 'C', x: -1.2, y: 0.5, z: 0.0, note: 'C6 (α\x27 acidic carbon)'),
          Atom3D(symbol: 'C', x: 1.2, y: -1.0, z: 0.0),
          Atom3D(symbol: 'C', x: -1.2, y: -1.0, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: -1.7, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
          Bond3D(atomIndex1: 2, atomIndex2: 5),
          Bond3D(atomIndex1: 4, atomIndex2: 6),
          Bond3D(atomIndex1: 5, atomIndex2: 7),
          Bond3D(atomIndex1: 6, atomIndex2: 7),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'favorskii_intermediate',
        name: 'Bicyclo[3.1.0]hexan-2-one',
        formula: 'C6H8O',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.8, z: 0.0, note: 'Cyclopropanone carbonyl'),
          Atom3D(symbol: 'O', x: 0.0, y: 2.0, z: 0.0),
          Atom3D(symbol: 'C', x: 0.7, y: -0.3, z: 0.0, note: 'Bridgehead 1'),
          Atom3D(symbol: 'C', x: -0.7, y: -0.3, z: 0.0, note: 'Bridgehead 2'),
          Atom3D(symbol: 'C', x: 1.2, y: -1.6, z: 0.0),
          Atom3D(symbol: 'C', x: -1.2, y: -1.6, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: -2.2, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 2, atomIndex2: 4),
          Bond3D(atomIndex1: 3, atomIndex2: 5),
          Bond3D(atomIndex1: 4, atomIndex2: 6),
          Bond3D(atomIndex1: 5, atomIndex2: 6),
        ],
      ),
      product: const Molecule3D(
        id: 'favorskii_product',
        name: 'Methyl Cyclopentanecarboxylate',
        formula: 'C7H12O2',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.5, z: 0.0, note: 'Ring-contracted C1'),
          Atom3D(symbol: 'C', x: 1.1, y: 1.5, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 1.1, y: 2.7, z: 0.0),
          Atom3D(symbol: 'O', x: 2.2, y: 0.8, z: 0.0),
          Atom3D(symbol: 'C', x: 3.4, y: 1.5, z: 0.0),
          Atom3D(symbol: 'C', x: -1.1, y: -0.3, z: 0.0),
          Atom3D(symbol: 'C', x: 1.1, y: -0.3, z: 0.0),
          Atom3D(symbol: 'C', x: -0.7, y: -1.6, z: 0.0),
          Atom3D(symbol: 'C', x: 0.7, y: -1.6, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 1, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 0, atomIndex2: 5),
          Bond3D(atomIndex1: 0, atomIndex2: 6),
          Bond3D(atomIndex1: 5, atomIndex2: 7),
          Bond3D(atomIndex1: 6, atomIndex2: 8),
          Bond3D(atomIndex1: 7, atomIndex2: 8),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 16. MANNICH REACTION
    // -------------------------------------------------------------
    'mannich': Reaction3DSet(
      reactionId: 'mannich',
      title: 'Mannich Reaction',
      keyTransformationNote:
          'Acid-catalyzed enol attacks electrophilic iminium ion to yield β-amino carbonyl Mannich base.',
      reactant: const Molecule3D(
        id: 'mannich_reactant',
        name: 'Ketone Enol + Dimethyliminium Ion',
        formula: 'PhC(OH)=CH2 + [CH2=NMe2]⁺',
        atoms: [
          Atom3D(symbol: 'C', x: -1.4, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: -1.4, y: 1.35, z: 0.0),
          Atom3D(symbol: 'C', x: -0.2, y: -0.7, z: 0.0, note: 'Enol nucleophilic carbon'),
          Atom3D(symbol: 'C', x: 1.2, y: 0.0, z: 0.0, note: 'Iminium electrophilic carbon'),
          Atom3D(symbol: 'N', x: 2.3, y: 0.7, z: 0.0, formalCharge: '+1'),
          Atom3D(symbol: 'C', x: 3.5, y: 0.1, z: 0.0),
          Atom3D(symbol: 'C', x: 2.3, y: 2.1, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
          Bond3D(atomIndex1: 4, atomIndex2: 6),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'mannich_intermediate',
        name: 'Protonated Mannich Base Adduct',
        formula: '[PhCOCH2CH2NHMe2]⁺',
        atoms: [
          Atom3D(symbol: 'C', x: -2.0, y: 0.0, z: 0.0),
          Atom3D(symbol: 'O', x: -2.0, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: -0.8, y: -0.7, z: 0.0),
          Atom3D(symbol: 'C', x: 0.5, y: 0.0, z: 0.0),
          Atom3D(symbol: 'N', x: 1.7, y: -0.7, z: 0.0),
          Atom3D(symbol: 'C', x: 2.9, y: 0.0, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
        ],
      ),
      product: const Molecule3D(
        id: 'mannich_product',
        name: 'Mannich Base (β-Amino Ketone)',
        formula: 'Ph-CO-CH2-CH2-NMe2',
        atoms: [
          Atom3D(symbol: 'C', x: -2.5, y: 0.0, z: 0.0, note: 'Carbonyl carbon'),
          Atom3D(symbol: 'O', x: -2.5, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: -1.2, y: -0.7, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0),
          Atom3D(symbol: 'N', x: 1.3, y: -0.7, z: 0.0),
          Atom3D(symbol: 'C', x: 2.4, y: 0.1, z: 0.0),
          Atom3D(symbol: 'C', x: 1.4, y: -2.1, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
          Bond3D(atomIndex1: 4, atomIndex2: 6),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 17. PINACOL-PINACOLONE REARRANGEMENT
    // -------------------------------------------------------------
    'pinacol': Reaction3DSet(
      reactionId: 'pinacol',
      title: 'Pinacol-Pinacolone Rearrangement',
      keyTransformationNote:
          'Loss of water forms tertiary carbocation; 1,2-methyl shift assisted by oxygen lone pair forms oxocarbenium ion.',
      reactant: const Molecule3D(
        id: 'pinacol_reactant',
        name: 'Pinacol (2,3-Dimethylbutane-2,3-diol)',
        formula: '(CH3)2C(OH)-C(OH)(CH3)2',
        atoms: [
          Atom3D(symbol: 'C', x: -0.77, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'O', x: -0.77, y: 1.4, z: 0.0),
          Atom3D(symbol: 'C', x: -1.5, y: -0.7, z: 1.1),
          Atom3D(symbol: 'C', x: -1.5, y: -0.7, z: -1.1),
          Atom3D(symbol: 'C', x: 0.77, y: 0.0, z: 0.0, hybridization: 'sp³'),
          Atom3D(symbol: 'O', x: 0.77, y: -1.4, z: 0.0),
          Atom3D(symbol: 'C', x: 1.5, y: 0.7, z: 1.1),
          Atom3D(symbol: 'C', x: 1.5, y: 0.7, z: -1.1),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 0, atomIndex2: 4),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
          Bond3D(atomIndex1: 4, atomIndex2: 6),
          Bond3D(atomIndex1: 4, atomIndex2: 7),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'pinacol_intermediate',
        name: '1,2-Methyl Shift Transition State',
        formula: '[(CH3)2C(OH)···CH3···C⁺(CH3)]‡',
        atoms: [
          Atom3D(symbol: 'C', x: -0.75, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: -0.75, y: 1.35, z: 0.0, note: 'Oxygen pushing lone pair'),
          Atom3D(symbol: 'C', x: 0.0, y: -1.2, z: 0.0, note: 'Migrating 1,2-methyl group'),
          Atom3D(symbol: 'C', x: 0.75, y: 0.0, z: 0.0, hybridization: 'sp²', formalCharge: '+1'),
          Atom3D(symbol: 'C', x: 1.6, y: 0.8, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.partial),
          Bond3D(atomIndex1: 0, atomIndex2: 2, type: BondType3D.partial),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.partial),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
        ],
      ),
      product: const Molecule3D(
        id: 'pinacol_product',
        name: 'Pinacolone (3,3-Dimethylbutan-2-one)',
        formula: '(CH3)3C-CO-CH3',
        atoms: [
          Atom3D(symbol: 'C', x: -0.6, y: 0.0, z: 0.0, hybridization: 'sp²', note: 'Carbonyl carbon'),
          Atom3D(symbol: 'O', x: -0.6, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: -1.8, y: -0.8, z: 0.0),
          Atom3D(symbol: 'C', x: 0.9, y: -0.4, z: 0.0, note: 'Quaternary carbon with 3 methyls'),
          Atom3D(symbol: 'C', x: 1.5, y: 0.9, z: 0.5),
          Atom3D(symbol: 'C', x: 1.5, y: -1.0, z: 1.1),
          Atom3D(symbol: 'C', x: 0.9, y: -1.3, z: -1.1),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 3, atomIndex2: 5),
          Bond3D(atomIndex1: 3, atomIndex2: 6),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 18. ROBINSON ANNULATION
    // -------------------------------------------------------------
    'robinson': Reaction3DSet(
      reactionId: 'robinson',
      title: 'Robinson Annulation',
      keyTransformationNote:
          'Sequential Michael 1,4-addition followed by intramolecular aldol condensation and dehydration to form fused 6-membered enone.',
      reactant: const Molecule3D(
        id: 'robinson_reactant',
        name: 'Cyclohexanone Enolate + MVK',
        formula: 'C6H9O⁻ + C4H6O',
        atoms: [
          Atom3D(symbol: 'C', x: -1.8, y: 0.0, z: 0.0, note: 'Cyclohexanone enolate C2'),
          Atom3D(symbol: 'C', x: -1.8, y: 1.3, z: 0.0),
          Atom3D(symbol: 'O', x: -1.8, y: 2.5, z: 0.0),
          Atom3D(symbol: 'C', x: 1.2, y: 0.0, z: 0.0, note: 'Terminal carbon of MVK'),
          Atom3D(symbol: 'C', x: 2.4, y: 0.6, z: 0.0),
          Atom3D(symbol: 'C', x: 3.6, y: 0.0, z: 0.0),
          Atom3D(symbol: 'O', x: 3.6, y: -1.2, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
          Bond3D(atomIndex1: 5, atomIndex2: 6, type: BondType3D.doubleBond),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'robinson_intermediate',
        name: '1,5-Diketone Adduct',
        formula: 'C10H16O2',
        atoms: [
          Atom3D(symbol: 'C', x: -1.2, y: 0.0, z: 0.0, note: 'Ring C2'),
          Atom3D(symbol: 'C', x: -1.2, y: 1.4, z: 0.0),
          Atom3D(symbol: 'O', x: -1.2, y: 2.6, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: -0.6, z: 0.0),
          Atom3D(symbol: 'C', x: 1.2, y: 0.0, z: 0.0),
          Atom3D(symbol: 'C', x: 2.4, y: -0.6, z: 0.0),
          Atom3D(symbol: 'O', x: 2.4, y: -1.8, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
          Bond3D(atomIndex1: 5, atomIndex2: 6, type: BondType3D.doubleBond),
        ],
      ),
      product: const Molecule3D(
        id: 'robinson_product',
        name: 'Δ¹,⁹-2-Octalone (Bicyclic Enone)',
        formula: 'C10H14O',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.7, z: 0.0, hybridization: 'sp²', note: 'C9 bridgehead'),
          Atom3D(symbol: 'C', x: 0.0, y: -0.7, z: 0.0, hybridization: 'sp²', note: 'C1 bridgehead'),
          Atom3D(symbol: 'C', x: 1.2, y: -1.4, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 1.2, y: -2.6, z: 0.0),
          Atom3D(symbol: 'C', x: 2.4, y: -0.7, z: 0.0),
          Atom3D(symbol: 'C', x: 2.4, y: 0.7, z: 0.0),
          Atom3D(symbol: 'C', x: 1.2, y: 1.4, z: 0.0),
          Atom3D(symbol: 'C', x: -1.2, y: -1.4, z: 0.0),
          Atom3D(symbol: 'C', x: -2.4, y: -0.7, z: 0.0),
          Atom3D(symbol: 'C', x: -2.4, y: 0.7, z: 0.0),
          Atom3D(symbol: 'C', x: -1.2, y: 1.4, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 2, atomIndex2: 4),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
          Bond3D(atomIndex1: 5, atomIndex2: 6),
          Bond3D(atomIndex1: 6, atomIndex2: 0),
          Bond3D(atomIndex1: 1, atomIndex2: 7),
          Bond3D(atomIndex1: 7, atomIndex2: 8),
          Bond3D(atomIndex1: 8, atomIndex2: 9),
          Bond3D(atomIndex1: 9, atomIndex2: 10),
          Bond3D(atomIndex1: 10, atomIndex2: 0),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 19. CURTIUS REARRANGEMENT
    // -------------------------------------------------------------
    'curtius': Reaction3DSet(
      reactionId: 'curtius',
      title: 'Curtius Rearrangement',
      keyTransformationNote:
          'Thermal extrusion of dinitrogen (N2) occurs concertedly with 1,2-migration to yield isocyanate with preserved stereocenters.',
      reactant: const Molecule3D(
        id: 'curtius_reactant',
        name: 'Benzoyl Azide',
        formula: 'Ph-CON3',
        atoms: [
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'O', x: 0.0, y: 1.25, z: 0.0),
          Atom3D(symbol: 'C', x: -1.4, y: -0.6, z: 0.0, note: 'Migrating phenyl group'),
          Atom3D(symbol: 'N', x: 1.2, y: -0.6, z: 0.0),
          Atom3D(symbol: 'N', x: 2.2, y: -0.1, z: 0.0, formalCharge: '+1'),
          Atom3D(symbol: 'N', x: 3.2, y: 0.4, z: 0.0, note: 'Departing :N≡N:'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.doubleBond),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'curtius_intermediate',
        name: 'Phenyl Isocyanate',
        formula: 'Ph-N=C=O',
        atoms: [
          Atom3D(symbol: 'C', x: -1.8, y: 0.0, z: 0.0, note: 'Phenyl group'),
          Atom3D(symbol: 'N', x: -0.4, y: 0.0, z: 0.0, hybridization: 'sp²'),
          Atom3D(symbol: 'C', x: 0.8, y: 0.0, z: 0.0, hybridization: 'sp', note: 'Linear central carbon'),
          Atom3D(symbol: 'O', x: 2.0, y: 0.0, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
        ],
      ),
      product: const Molecule3D(
        id: 'curtius_product',
        name: 'Aniline + Carbon Dioxide',
        formula: 'Ph-NH2 + CO2',
        atoms: [
          Atom3D(symbol: 'C', x: -1.8, y: 0.0, z: 0.0),
          Atom3D(symbol: 'N', x: -0.4, y: 0.0, z: 0.0, note: 'Primary amine'),
          Atom3D(symbol: 'H', x: 0.0, y: 0.8, z: 0.4),
          Atom3D(symbol: 'H', x: 0.0, y: -0.8, z: 0.4),
          Atom3D(symbol: 'C', x: 2.5, y: 0.0, z: 0.0, note: 'CO2 carbon'),
          Atom3D(symbol: 'O', x: 1.3, y: 0.0, z: 0.0),
          Atom3D(symbol: 'O', x: 3.7, y: 0.0, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 1, atomIndex2: 3),
          Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 4, atomIndex2: 6, type: BondType3D.doubleBond),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 20. [3,3]-COPE REARRANGEMENT
    // -------------------------------------------------------------
    'cope': Reaction3DSet(
      reactionId: 'cope',
      title: '[3,3]-Cope Rearrangement',
      keyTransformationNote:
          'Concerted suprafacial-suprafacial sigmatropic shift proceeding via a 6-electron aromatic chair-like transition state.',
      reactant: const Molecule3D(
        id: 'cope_reactant',
        name: '1,5-Hexadiene (Chair Conformer)',
        formula: 'C6H10',
        atoms: [
          Atom3D(symbol: 'C', x: -1.2, y: 0.8, z: 0.4, hybridization: 'sp³', note: 'C3'),
          Atom3D(symbol: 'C', x: 1.2, y: 0.8, z: -0.4, hybridization: 'sp³', note: 'C4'),
          Atom3D(symbol: 'C', x: -1.2, y: -0.6, z: 0.0, hybridization: 'sp²', note: 'C2'),
          Atom3D(symbol: 'C', x: -0.2, y: -1.5, z: 0.0, hybridization: 'sp²', note: 'C1'),
          Atom3D(symbol: 'C', x: 1.2, y: -0.6, z: 0.0, hybridization: 'sp²', note: 'C5'),
          Atom3D(symbol: 'C', x: 0.2, y: -1.5, z: 0.0, hybridization: 'sp²', note: 'C6'),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 0, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 1, atomIndex2: 4),
          Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.doubleBond),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'cope_intermediate',
        name: 'Chair-Like 6π Transition State [‡]',
        formula: '[C6H10]‡',
        atoms: [
          Atom3D(symbol: 'C', x: -1.1, y: 0.7, z: 0.3),
          Atom3D(symbol: 'C', x: 1.1, y: 0.7, z: -0.3),
          Atom3D(symbol: 'C', x: -1.1, y: -0.5, z: 0.0),
          Atom3D(symbol: 'C', x: -0.3, y: -1.3, z: 0.0),
          Atom3D(symbol: 'C', x: 1.1, y: -0.5, z: 0.0),
          Atom3D(symbol: 'C', x: 0.3, y: -1.3, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.partial),
          Bond3D(atomIndex1: 0, atomIndex2: 2, type: BondType3D.partial),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.partial),
          Bond3D(atomIndex1: 3, atomIndex2: 5, type: BondType3D.partial),
          Bond3D(atomIndex1: 5, atomIndex2: 4, type: BondType3D.partial),
          Bond3D(atomIndex1: 4, atomIndex2: 1, type: BondType3D.partial),
        ],
      ),
      product: const Molecule3D(
        id: 'cope_product',
        name: 'Rearranged 1,5-Hexadiene',
        formula: 'C6H10',
        atoms: [
          Atom3D(symbol: 'C', x: -1.2, y: 0.8, z: 0.4),
          Atom3D(symbol: 'C', x: 1.2, y: 0.8, z: -0.4),
          Atom3D(symbol: 'C', x: -1.2, y: -0.6, z: 0.0),
          Atom3D(symbol: 'C', x: -0.2, y: -1.5, z: 0.0),
          Atom3D(symbol: 'C', x: 1.2, y: -0.6, z: 0.0),
          Atom3D(symbol: 'C', x: 0.2, y: -1.5, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 2, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 1, atomIndex2: 4, type: BondType3D.doubleBond),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
          Bond3D(atomIndex1: 3, atomIndex2: 5),
        ],
      ),
    ),

    // -------------------------------------------------------------
    // 21. [3,3]-CLAISEN SIGMATROPIC REARRANGEMENT
    // -------------------------------------------------------------
    'claisen_sigmatropic': Reaction3DSet(
      reactionId: 'claisen_sigmatropic',
      title: '[3,3]-Claisen Sigmatropic Rearrangement',
      keyTransformationNote:
          'Thermal isomerization of allyl phenyl ether via chair transition state; dienone rapidly tautomerizes/enolizes to restore aromaticity in ortho-allylphenol.',
      reactant: const Molecule3D(
        id: 'claisen_sig_reactant',
        name: 'Allyl Phenyl Ether',
        formula: 'Ph-O-CH2-CH=CH2',
        atoms: [
          Atom3D(symbol: 'C', x: -1.5, y: 0.0, z: 0.0, note: 'Phenyl ipso carbon'),
          Atom3D(symbol: 'O', x: -0.2, y: 0.5, z: 0.0),
          Atom3D(symbol: 'C', x: 0.9, y: -0.3, z: 0.0, note: 'Allylic CH2'),
          Atom3D(symbol: 'C', x: 2.1, y: 0.5, z: 0.0),
          Atom3D(symbol: 'C', x: 3.3, y: -0.2, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 2, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.doubleBond),
        ],
      ),
      intermediate: const Molecule3D(
        id: 'claisen_sig_intermediate',
        name: 'Chair-Like TS & Dienone Intermediate',
        formula: 'C9H10O‡',
        atoms: [
          Atom3D(symbol: 'C', x: -0.8, y: 0.0, z: 0.0),
          Atom3D(symbol: 'O', x: -0.8, y: 1.3, z: 0.0),
          Atom3D(symbol: 'C', x: 0.5, y: 1.3, z: 0.0),
          Atom3D(symbol: 'C', x: 1.5, y: 0.5, z: 0.0),
          Atom3D(symbol: 'C', x: 1.2, y: -0.8, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: -1.0, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1, type: BondType3D.partial),
          Bond3D(atomIndex1: 1, atomIndex2: 2, type: BondType3D.partial),
          Bond3D(atomIndex1: 2, atomIndex2: 3, type: BondType3D.partial),
          Bond3D(atomIndex1: 3, atomIndex2: 4, type: BondType3D.partial),
          Bond3D(atomIndex1: 4, atomIndex2: 5, type: BondType3D.partial),
          Bond3D(atomIndex1: 5, atomIndex2: 0, type: BondType3D.partial),
        ],
      ),
      product: const Molecule3D(
        id: 'claisen_sig_product',
        name: 'ortho-Allylphenol',
        formula: 'o-(CH2=CH-CH2)C6H4-OH',
        atoms: [
          Atom3D(symbol: 'C', x: -1.2, y: 0.7, z: 0.0, note: 'C1 with -OH'),
          Atom3D(symbol: 'O', x: -1.2, y: 2.0, z: 0.0),
          Atom3D(symbol: 'H', x: -0.4, y: 2.4, z: 0.0),
          Atom3D(symbol: 'C', x: 0.0, y: 0.0, z: 0.0, note: 'C2 with allyl substituent'),
          Atom3D(symbol: 'C', x: 1.3, y: -0.7, z: 0.0, note: 'Allylic CH2'),
          Atom3D(symbol: 'C', x: 2.5, y: 0.1, z: 0.0),
          Atom3D(symbol: 'C', x: 3.7, y: -0.5, z: 0.0),
        ],
        bonds: [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
          Bond3D(atomIndex1: 1, atomIndex2: 2),
          Bond3D(atomIndex1: 0, atomIndex2: 3),
          Bond3D(atomIndex1: 3, atomIndex2: 4),
          Bond3D(atomIndex1: 4, atomIndex2: 5),
          Bond3D(atomIndex1: 5, atomIndex2: 6, type: BondType3D.doubleBond),
        ],
      ),
    ),
  };

  /// Returns 3D structure set for a mechanism ID.
  static Reaction3DSet? get3DSet(String id) => _catalog[id.toLowerCase()];

  /// Returns true if 3D molecular structures are available for this reaction.
  static bool has3D(String id) => _catalog.containsKey(id.toLowerCase());

  /// Returns all available 3D reaction IDs.
  static List<String> get availableIds => _catalog.keys.toList();
}
