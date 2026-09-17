/// MSc Chemistry Pericyclic Service
/// Encapsulates the Woodward-Hoffmann rules, Frontier Molecular Orbital (FMO) analysis,
/// stereochemical predictions for electrocyclic reactions, cycloadditions, and sigmatropic shifts,
/// and complete 3D orbital coordinate and nodal topology data for interactive spatial visualization.
library;

enum PericyclicType {
  electrocyclic,
  cycloaddition,
  sigmatropic,
}

enum ReactionCondition {
  thermal,       // Delta
  photochemical, // h*nu
}

class PericyclicService {
  // 1. Woodward-Hoffmann Selection Rules Matrix
  static const List<WoodwardHoffmannRule> selectionRules = [
    WoodwardHoffmannRule(
      reactionType: 'Electrocyclic',
      electronCount: '4n (e.g. 4 pi: Butadiene)',
      thermalMode: 'Conrotatory (Allowed)',
      photochemicalMode: 'Disrotatory (Allowed)',
      homoSymmetry: 'Thermal HOMO is Psi2 (C2 symmetric, antisymmetric on mirror plane m). Terminal lobes have opposite phases on same face.',
    ),
    WoodwardHoffmannRule(
      reactionType: 'Electrocyclic',
      electronCount: '4n+2 (e.g. 6 pi: Hexatriene)',
      thermalMode: 'Disrotatory (Allowed)',
      photochemicalMode: 'Conrotatory (Allowed)',
      homoSymmetry: 'Thermal HOMO is Psi3 (Mirror plane m symmetric). Terminal lobes have identical phases on same face.',
    ),
    WoodwardHoffmannRule(
      reactionType: 'Cycloaddition',
      electronCount: '4n (e.g. [2+2])',
      thermalMode: 'Antarafacial (Geometrically forbidden) / Stepwise',
      photochemicalMode: 'Suprafacial-Suprafacial [2s+2s] (Allowed)',
      homoSymmetry: 'Photochemical excitation promotes electron to Psi2*, permitting constructive supra-supra overlap.',
    ),
    WoodwardHoffmannRule(
      reactionType: 'Cycloaddition',
      electronCount: '4n+2 (e.g. [4+2] Diels-Alder)',
      thermalMode: 'Suprafacial-Suprafacial [4s+2s] (Allowed)',
      photochemicalMode: 'Supra-Antara (Forbidden / Unfavorable)',
      homoSymmetry: 'Thermal diene HOMO (Psi2) overlaps constructively with dienophile LUMO (pi*).',
    ),
    WoodwardHoffmannRule(
      reactionType: 'Sigmatropic Shift',
      electronCount: '[1,3]-shift (4 electrons)',
      thermalMode: 'Antarafacial (Inversion of migrating group)',
      photochemicalMode: 'Suprafacial (Retention of migrating group)',
      homoSymmetry: 'Allyl radical SOMO dictates orbital topology.',
    ),
    WoodwardHoffmannRule(
      reactionType: 'Sigmatropic Shift',
      electronCount: '[1,5]-shift (6 electrons)',
      thermalMode: 'Suprafacial (Retention - very facile)',
      photochemicalMode: 'Antarafacial (Thermally forbidden)',
      homoSymmetry: 'Pentadienyl system: constructive terminal lobe overlap in helical transition state.',
    ),
    WoodwardHoffmannRule(
      reactionType: 'Sigmatropic Shift',
      electronCount: '[3,3]-shift (Cope / Claisen, 6 electrons)',
      thermalMode: 'Suprafacial-Suprafacial via Chair-like TS',
      photochemicalMode: 'Boat-like or Stepwise',
      homoSymmetry: 'Aromatic 6-electron Hückel-type transition state.',
    ),
  ];

  // 2. Predict Stereochemical & Symmetry Outcome
  static PericyclicPrediction predict({
    required PericyclicType type,
    required int electrons,
    required ReactionCondition condition,
  }) {
    final isThermal = condition == ReactionCondition.thermal;
    final is4n = electrons % 4 == 0;

    switch (type) {
      case PericyclicType.electrocyclic:
        if (is4n) {
          return PericyclicPrediction(
            allowedMode: isThermal ? 'Conrotatory' : 'Disrotatory',
            forbiddenMode: isThermal ? 'Disrotatory' : 'Conrotatory',
            isThermallyAllowed: isThermal,
            transitionStateSymmetry: isThermal ? 'C₂ symmetry maintained' : 'Mirror plane (m) symmetry maintained',
            homoState: isThermal
                ? 'Thermal HOMO = Ψ₂ (Antisymmetric lobes, requires like-phase rotation in same direction = Conrotatory)'
                : 'Photochemical SOMO = Ψ₃* (Symmetric terminal lobes, requires opposite-direction rotation = Disrotatory)',
            stereochemistryExample: isThermal
                ? '(2E,4E)-Hexadiene yields trans-3,4-dimethylcyclobutene via Conrotation.'
                : '(2E,4E)-Hexadiene yields cis-3,4-dimethylcyclobutene under UV light via Disrotation.',
          );
        } else {
          // 4n + 2
          return PericyclicPrediction(
            allowedMode: isThermal ? 'Disrotatory' : 'Conrotatory',
            forbiddenMode: isThermal ? 'Conrotatory' : 'Disrotatory',
            isThermallyAllowed: isThermal,
            transitionStateSymmetry: isThermal ? 'Mirror plane (m) symmetry maintained' : 'C₂ symmetry maintained',
            homoState: isThermal
                ? 'Thermal HOMO = Ψ₃ (Symmetric terminal lobes, requires opposite-direction rotation = Disrotatory)'
                : 'Photochemical SOMO = Ψ₄* (Antisymmetric terminal lobes, requires same-direction rotation = Conrotatory)',
            stereochemistryExample: isThermal
                ? '(2E,4Z,6E)-Octatriene yields cis-5,6-dimethyl-1,3-cyclohexadiene via Disrotation.'
                : '(2E,4Z,6E)-Octatriene yields trans-5,6-dimethyl-1,3-cyclohexadiene under UV light via Conrotation.',
          );
        }

      case PericyclicType.cycloaddition:
        if (is4n) {
          return PericyclicPrediction(
            allowedMode: isThermal ? 'Antarafacial [2s+2a] (Geometrically Strained)' : 'Suprafacial-Suprafacial [2s+2s]',
            forbiddenMode: isThermal ? 'Suprafacial [2s+2s]' : 'Antarafacial [2s+2a]',
            isThermallyAllowed: !isThermal,
            transitionStateSymmetry: isThermal ? 'Mobius topology (0 nodes / 1 twist)' : 'Hückel topology (4n electrons)',
            homoState: isThermal
                ? 'Thermal HOMO (pi) + LUMO (pi*) phase cancellation prevents [2s+2s] thermal overlap.'
                : 'Photochemical HOMO* (pi*) + Ground State LUMO (pi*) gives phase-matched constructive overlap.',
            stereochemistryExample: isThermal
                ? 'Thermal dimerizations of simple alkenes do not proceed pericyclically; require high energy or ketene [2s+2a].'
                : 'Photochemical [2+2] cycloaddition of alkenes smoothly yields cyclobutanes with stereospecific retention.',
          );
        } else {
          // 4n + 2 (e.g. Diels-Alder [4+2])
          return PericyclicPrediction(
            allowedMode: isThermal ? 'Suprafacial-Suprafacial [4s+2s]' : 'Supra-Antara [4s+2a] (Forbidden)',
            forbiddenMode: isThermal ? '[4s+2a] (Forbidden)' : '[4s+2s] (Photochemically Forbidden)',
            isThermallyAllowed: isThermal,
            transitionStateSymmetry: 'Aromatic 6-electron Hückel transition state (Dewar-Evans-Zimmerman rule)',
            homoState: isThermal
                ? 'Diene HOMO (Ψ₂) and Dienophile LUMO (pi*) match phases at terminal carbons 1 and 4.'
                : 'Photoexcited diene HOMO* (Ψ₃) phase matches opposite dienophile face, disfavoring supra-supra alignment.',
            stereochemistryExample: isThermal
                ? 'Diels-Alder reaction: 1,3-Butadiene + Maleic anhydride -> cis-norbornene derivative (Endo rule favored via secondary orbital interaction).'
                : 'Photochemical Diels-Alder is symmetry-forbidden and typically proceeds by radical or non-pericyclic pathways.',
          );
        }

      case PericyclicType.sigmatropic:
        if (is4n) {
          return PericyclicPrediction(
            allowedMode: isThermal ? '[1,3]-Antarafacial (Inversion)' : '[1,3]-Suprafacial (Retention)',
            forbiddenMode: isThermal ? '[1,3]-Suprafacial' : '[1,3]-Antarafacial',
            isThermallyAllowed: isThermal,
            transitionStateSymmetry: 'Mobius transition state required for thermal antarafacial shift',
            homoState: 'Allyl radical SOMO Ψ₂ has opposite signs at C1 and C3, requiring migration to opposite face.',
            stereochemistryExample: isThermal
                ? 'Thermal [1,3]-shifts are geometrically very difficult due to strain across 3 carbons; often observe radical cleavage instead.'
                : 'Photochemical [1,3]-hydride and carbon shifts proceed cleanly with suprafacial stereochemistry.',
          );
        } else {
          // 6 electrons: [1,5] and [3,3]
          return PericyclicPrediction(
            allowedMode: isThermal ? 'Suprafacial [3,3] & [1,5] (Retention)' : 'Antarafacial (Forbidden)',
            forbiddenMode: isThermal ? 'Antarafacial' : 'Suprafacial',
            isThermallyAllowed: isThermal,
            transitionStateSymmetry: '6-electron aromatic chair-like Hückel transition state',
            homoState: 'Constructive in-phase overlap of terminal orbitals in a 6-membered cyclic transition state.',
            stereochemistryExample: isThermal
                ? 'Cope Rearrangement (1,5-hexadienes) & Claisen Rearrangement (allyl vinyl ethers) proceed through chair-like transition state with complete chirality transfer.'
                : 'Photochemical [3,3]-rearrangements are symmetry-forbidden and undergo competing cleavage or [2+2] cyclization.',
          );
        }
    }
  }

  // 3. Curated 3D Molecular Orbital Systems & Pericyclic Reactions
  static final List<Pericyclic3DExample> threeDExamples = [
    // ----------------------------------------------------
    // EXAMPLE 1: 4pi Electrocyclic (Butadiene -> Cyclobutene)
    // ----------------------------------------------------
    Pericyclic3DExample(
      id: 'electrocyclic_4pi',
      title: '4π Electrocyclic Ring Closure',
      subtitle: '1,3-Butadiene ⇌ Cyclobutene (Thermal Conrotatory vs Photo Disrotatory)',
      category: 'Electrocyclic Reactions',
      condition: 'Thermal (Δ) Conrotatory vs UV (hν) Disrotatory',
      stereochemicalRule: 'Woodward-Hoffmann 4n rule: Thermal requires Conrotation; Photochemical requires Disrotation.',
      academicExplanation: 'In 1,3-butadiene, the thermal HOMO is Ψ₂ with 1 nodal plane at the center. The terminal lobes at C1 and C4 have opposite signs on the top face (+ at C1, - at C4). For the terminal lobes to overlap constructively (+ with + or - with -), both termini must rotate in the SAME direction (Conrotatory), maintaining C₂ axis symmetry. Under UV irradiation, an electron is promoted to Ψ₃* (LUMO becomes SOMO), which has 2 nodal planes and symmetric terminal lobes (+ at C1, + at C4 on top). Therefore, Disrotation (opposite-direction turning) is required to close the ring constructively.',
      fmoOverlapDescription: 'Ψ₂ terminal lobes rotate conrotatorily by 90° to form a new σ C1-C4 bond with in-phase (+)/(+) overlap.',
      transitionStateNotes: 'Conrotatory motion preserves C₂ orbital symmetry throughout the reaction coordinate.',
      secondaryOrbitalNotes: 'Steric bulk on (2E,4E)-hexadiene forces both methyls outward, yielding trans-3,4-dimethylcyclobutene cleanly.',
      system: Pericyclic3DSystem(
        id: 'sys_butadiene',
        title: '1,3-Butadiene (4π Electron System)',
        formulaOrName: 'CH₂=CH–CH=CH₂',
        piElectrons: 4,
        atoms: [
          PericyclicAtom3D(index: 0, label: 'C1', x: -1.5, y: -0.6, z: 0.0),
          PericyclicAtom3D(index: 1, label: 'C2', x: -0.5, y: 0.4, z: 0.0),
          PericyclicAtom3D(index: 2, label: 'C3', x: 0.5, y: -0.4, z: 0.0),
          PericyclicAtom3D(index: 3, label: 'C4', x: 1.5, y: 0.6, z: 0.0),
        ],
        bonds: [
          PericyclicBond3D(from: 0, to: 1, isDouble: true),
          PericyclicBond3D(from: 1, to: 2, isDouble: false),
          PericyclicBond3D(from: 2, to: 3, isDouble: true),
        ],
        orbitals: [
          MolecularOrbital3D(
            name: 'Ψ₁ (All Bonding)',
            energy: -1.618,
            symmetry: 'Mirror plane (m) symmetric',
            nodes: 0,
            isHomo: false,
            isLumo: false,
            description: '0 nodes. All p-orbitals in phase on top (+, +, +, +). Net bonding across all 4 carbons.',
            lobes: [
              OrbitalLobe3D(atomIndex: 0, x: -1.5, y: -0.6, z: 0.6, sign: 1, size: 0.37),
              OrbitalLobe3D(atomIndex: 0, x: -1.5, y: -0.6, z: -0.6, sign: -1, size: 0.37),
              OrbitalLobe3D(atomIndex: 1, x: -0.5, y: 0.4, z: 0.6, sign: 1, size: 0.60),
              OrbitalLobe3D(atomIndex: 1, x: -0.5, y: 0.4, z: -0.6, sign: -1, size: 0.60),
              OrbitalLobe3D(atomIndex: 2, x: 0.5, y: -0.4, z: 0.6, sign: 1, size: 0.60),
              OrbitalLobe3D(atomIndex: 2, x: 0.5, y: -0.4, z: -0.6, sign: -1, size: 0.60),
              OrbitalLobe3D(atomIndex: 3, x: 1.5, y: 0.6, z: 0.6, sign: 1, size: 0.37),
              OrbitalLobe3D(atomIndex: 3, x: 1.5, y: 0.6, z: -0.6, sign: -1, size: 0.37),
            ],
          ),
          MolecularOrbital3D(
            name: 'Ψ₂ (Thermal HOMO)',
            energy: -0.618,
            symmetry: 'C₂ axis symmetric (Antisymmetric on m)',
            nodes: 1,
            isHomo: true,
            isLumo: false,
            description: '1 central node between C2 and C3. Top phases are (+, +, -, -). Terminal lobes C1 and C4 have opposite signs on top, requiring Conrotation.',
            lobes: [
              OrbitalLobe3D(atomIndex: 0, x: -1.5, y: -0.6, z: 0.6, sign: 1, size: 0.60),
              OrbitalLobe3D(atomIndex: 0, x: -1.5, y: -0.6, z: -0.6, sign: -1, size: 0.60),
              OrbitalLobe3D(atomIndex: 1, x: -0.5, y: 0.4, z: 0.6, sign: 1, size: 0.37),
              OrbitalLobe3D(atomIndex: 1, x: -0.5, y: 0.4, z: -0.6, sign: -1, size: 0.37),
              OrbitalLobe3D(atomIndex: 2, x: 0.5, y: -0.4, z: 0.6, sign: -1, size: 0.37),
              OrbitalLobe3D(atomIndex: 2, x: 0.5, y: -0.4, z: -0.6, sign: 1, size: 0.37),
              OrbitalLobe3D(atomIndex: 3, x: 1.5, y: 0.6, z: 0.6, sign: -1, size: 0.60),
              OrbitalLobe3D(atomIndex: 3, x: 1.5, y: 0.6, z: -0.6, sign: 1, size: 0.60),
            ],
          ),
          MolecularOrbital3D(
            name: 'Ψ₃* (Photochemical SOMO / LUMO)',
            energy: 0.618,
            symmetry: 'Mirror plane (m) symmetric',
            nodes: 2,
            isHomo: false,
            isLumo: true,
            description: '2 nodes between C1-C2 and C3-C4. Top phases are (+, -, -, +). Terminal lobes C1 and C4 have identical signs (+, +) on top, requiring Disrotation.',
            lobes: [
              OrbitalLobe3D(atomIndex: 0, x: -1.5, y: -0.6, z: 0.6, sign: 1, size: 0.60),
              OrbitalLobe3D(atomIndex: 0, x: -1.5, y: -0.6, z: -0.6, sign: -1, size: 0.60),
              OrbitalLobe3D(atomIndex: 1, x: -0.5, y: 0.4, z: 0.6, sign: -1, size: 0.37),
              OrbitalLobe3D(atomIndex: 1, x: -0.5, y: 0.4, z: -0.6, sign: 1, size: 0.37),
              OrbitalLobe3D(atomIndex: 2, x: 0.5, y: -0.4, z: 0.6, sign: -1, size: 0.37),
              OrbitalLobe3D(atomIndex: 2, x: 0.5, y: -0.4, z: -0.6, sign: 1, size: 0.37),
              OrbitalLobe3D(atomIndex: 3, x: 1.5, y: 0.6, z: 0.6, sign: 1, size: 0.60),
              OrbitalLobe3D(atomIndex: 3, x: 1.5, y: 0.6, z: -0.6, sign: -1, size: 0.60),
            ],
          ),
          MolecularOrbital3D(
            name: 'Ψ₄* (All Antibonding)',
            energy: 1.618,
            symmetry: 'C₂ axis symmetric',
            nodes: 3,
            isHomo: false,
            isLumo: false,
            description: '3 nodes alternating (+, -, +, -). Fully antibonding orbital.',
            lobes: [
              OrbitalLobe3D(atomIndex: 0, x: -1.5, y: -0.6, z: 0.6, sign: 1, size: 0.37),
              OrbitalLobe3D(atomIndex: 0, x: -1.5, y: -0.6, z: -0.6, sign: -1, size: 0.37),
              OrbitalLobe3D(atomIndex: 1, x: -0.5, y: 0.4, z: 0.6, sign: -1, size: 0.60),
              OrbitalLobe3D(atomIndex: 1, x: -0.5, y: 0.4, z: -0.6, sign: 1, size: 0.60),
              OrbitalLobe3D(atomIndex: 2, x: 0.5, y: -0.4, z: 0.6, sign: 1, size: 0.60),
              OrbitalLobe3D(atomIndex: 2, x: 0.5, y: -0.4, z: -0.6, sign: -1, size: 0.60),
              OrbitalLobe3D(atomIndex: 3, x: 1.5, y: 0.6, z: 0.6, sign: -1, size: 0.37),
              OrbitalLobe3D(atomIndex: 3, x: 1.5, y: 0.6, z: -0.6, sign: 1, size: 0.37),
            ],
          ),
        ],
      ),
    ),

    // ----------------------------------------------------
    // EXAMPLE 2: 6pi Electrocyclic (Hexatriene -> Cyclohexadiene)
    // ----------------------------------------------------
    Pericyclic3DExample(
      id: 'electrocyclic_6pi',
      title: '6π Electrocyclic Ring Closure',
      subtitle: '1,3,5-Hexatriene ⇌ 1,3-Cyclohexadiene (Thermal Disrotatory vs Photo Conrotatory)',
      category: 'Electrocyclic Reactions',
      condition: 'Thermal (Δ) Disrotatory vs UV (hν) Conrotatory',
      stereochemicalRule: 'Woodward-Hoffmann 4n+2 rule: Thermal requires Disrotation; Photochemical requires Conrotation.',
      academicExplanation: 'In 1,3,5-hexatriene, the thermal ground state HOMO is Ψ₃ (2 nodes, mirror plane m symmetric). The terminal lobes at C1 and C6 have IDENTICAL phases on the top face (+ at C1, + at C6). Under thermal activation, opposite-direction rotation (Disrotatory) brings these top lobes inward into direct constructive overlap (+)/(+) to form a σ bond while preserving mirror plane symmetry. Under UV excitation, promotion to Ψ₄* (3 nodes, C₂ symmetric) inverts the relative terminal signs, necessitating Conrotation.',
      fmoOverlapDescription: 'Ψ₃ terminal lobes rotate in opposite directions (Disrotatory) to overlap constructively in a Hückel 6-electron aromatic transition state.',
      transitionStateNotes: 'Disrotation maintains a vertical mirror plane (m) throughout ring closure.',
      secondaryOrbitalNotes: '(2E,4Z,6E)-octatriene thermal cyclization yields cis-5,6-dimethyl-1,3-cyclohexadiene with 100% stereospecificity.',
      system: Pericyclic3DSystem(
        id: 'sys_hexatriene',
        title: '1,3,5-Hexatriene (6π Electron System)',
        formulaOrName: 'CH₂=CH–CH=CH–CH=CH₂',
        piElectrons: 6,
        atoms: [
          PericyclicAtom3D(index: 0, label: 'C1', x: -2.0, y: -0.5, z: 0.0),
          PericyclicAtom3D(index: 1, label: 'C2', x: -1.2, y: 0.4, z: 0.0),
          PericyclicAtom3D(index: 2, label: 'C3', x: -0.4, y: -0.3, z: 0.0),
          PericyclicAtom3D(index: 3, label: 'C4', x: 0.4, y: 0.3, z: 0.0),
          PericyclicAtom3D(index: 4, label: 'C5', x: 1.2, y: -0.4, z: 0.0),
          PericyclicAtom3D(index: 5, label: 'C6', x: 2.0, y: 0.5, z: 0.0),
        ],
        bonds: [
          PericyclicBond3D(from: 0, to: 1, isDouble: true),
          PericyclicBond3D(from: 1, to: 2, isDouble: false),
          PericyclicBond3D(from: 2, to: 3, isDouble: true),
          PericyclicBond3D(from: 3, to: 4, isDouble: false),
          PericyclicBond3D(from: 4, to: 5, isDouble: true),
        ],
        orbitals: [
          MolecularOrbital3D(
            name: 'Ψ₃ (Thermal HOMO)',
            energy: -0.445,
            symmetry: 'Mirror plane (m) symmetric',
            nodes: 2,
            isHomo: true,
            isLumo: false,
            description: '2 nodes. Top phases are (+, -, -, -, -, +). Terminal lobes C1 and C6 have IDENTICAL signs (+, +) on top, demanding Disrotatory ring closure.',
            lobes: [
              OrbitalLobe3D(atomIndex: 0, x: -2.0, y: -0.5, z: 0.6, sign: 1, size: 0.50),
              OrbitalLobe3D(atomIndex: 0, x: -2.0, y: -0.5, z: -0.6, sign: -1, size: 0.50),
              OrbitalLobe3D(atomIndex: 1, x: -1.2, y: 0.4, z: 0.6, sign: -1, size: 0.30),
              OrbitalLobe3D(atomIndex: 1, x: -1.2, y: 0.4, z: -0.6, sign: 1, size: 0.30),
              OrbitalLobe3D(atomIndex: 2, x: -0.4, y: -0.3, z: 0.6, sign: -1, size: 0.45),
              OrbitalLobe3D(atomIndex: 2, x: -0.4, y: -0.3, z: -0.6, sign: 1, size: 0.45),
              OrbitalLobe3D(atomIndex: 3, x: 0.4, y: 0.3, z: 0.6, sign: -1, size: 0.45),
              OrbitalLobe3D(atomIndex: 3, x: 0.4, y: 0.3, z: -0.6, sign: 1, size: 0.45),
              OrbitalLobe3D(atomIndex: 4, x: 1.2, y: -0.4, z: 0.6, sign: -1, size: 0.30),
              OrbitalLobe3D(atomIndex: 4, x: 1.2, y: -0.4, z: -0.6, sign: 1, size: 0.30),
              OrbitalLobe3D(atomIndex: 5, x: 2.0, y: 0.5, z: 0.6, sign: 1, size: 0.50),
              OrbitalLobe3D(atomIndex: 5, x: 2.0, y: 0.5, z: -0.6, sign: -1, size: 0.50),
            ],
          ),
        ],
      ),
    ),

    // ----------------------------------------------------
    // EXAMPLE 3: Diels-Alder [4+2] with Endo Secondary Overlap
    // ----------------------------------------------------
    Pericyclic3DExample(
      id: 'diels_alder_endo',
      title: 'Diels-Alder [4+2] & The Endo Rule in 3D',
      subtitle: 'Suprafacial-Suprafacial [4s+2s] Approach with Secondary Orbital Overlap',
      category: 'Cycloaddition Reactions',
      condition: 'Thermal (Δ) Suprafacial-Suprafacial',
      stereochemicalRule: 'Endo Rule (Alder Rule): Electron-withdrawing substituents point toward diene.',
      academicExplanation: 'The [4+2] Diels-Alder reaction proceeds through a concerted, suprafacial-suprafacial [4s+2s] pathway governed by Diene HOMO (Ψ₂) overlapping constructively with Dienophile LUMO (π*). When dienophiles possess conjugated electron-withdrawing groups (e.g. acrolein C=O, maleic anhydride), the transition state can adopt either an ENDO or EXO geometry. In the ENDO transition state, the carbonyl π* orbital lies directly beneath C2 and C3 of the diene, creating a favorable Secondary Orbital Interaction. While no net bond forms between the carbonyl and C2/C3, this secondary overlap lowers the activation barrier (ΔG‡_endo < ΔG‡_exo), making the endo adduct the kinetic product.',
      fmoOverlapDescription: 'Primary in-phase overlap between Diene C1-C4 and Dienophile C1-C2, PLUS secondary in-phase overlap between Dienophile C=O π* and Diene C2-C3.',
      transitionStateNotes: 'Aromatic 6-electron Hückel transition state; thermally allowed by Woodward-Hoffmann rules.',
      secondaryOrbitalNotes: 'Secondary orbital overlap imparts a 3–5 kcal/mol kinetic preference for the endo isomer.',
      system: Pericyclic3DSystem(
        id: 'sys_diels_alder',
        title: 'Diene + Dienophile Transition State (Endo Approach)',
        formulaOrName: '1,3-Butadiene + Acrolein (CH₂=CH–CHO)',
        piElectrons: 6,
        atoms: [
          // Diene in s-cis conformation (top layer, z ≈ 0.8)
          PericyclicAtom3D(index: 0, label: 'C1 (Diene)', x: -1.0, y: -0.8, z: 0.8),
          PericyclicAtom3D(index: 1, label: 'C2 (Diene)', x: -0.7, y: 0.3, z: 0.8),
          PericyclicAtom3D(index: 2, label: 'C3 (Diene)', x: 0.7, y: 0.3, z: 0.8),
          PericyclicAtom3D(index: 3, label: 'C4 (Diene)', x: 1.0, y: -0.8, z: 0.8),
          // Dienophile (bottom layer, z ≈ -0.8)
          PericyclicAtom3D(index: 4, label: 'C1 (Dienophile)', x: -0.7, y: -0.8, z: -0.8),
          PericyclicAtom3D(index: 5, label: 'C2 (Dienophile)', x: 0.7, y: -0.8, z: -0.8),
          // Carbonyl of dienophile tucked under C2-C3 for Endo overlap
          PericyclicAtom3D(index: 6, label: 'C=O (Carbonyl)', x: 0.0, y: 0.4, z: -0.8),
        ],
        bonds: [
          PericyclicBond3D(from: 0, to: 1, isDouble: true),
          PericyclicBond3D(from: 1, to: 2, isDouble: false),
          PericyclicBond3D(from: 2, to: 3, isDouble: true),
          PericyclicBond3D(from: 4, to: 5, isDouble: true),
          PericyclicBond3D(from: 5, to: 6, isDouble: false),
        ],
        orbitals: [
          MolecularOrbital3D(
            name: 'Diene HOMO + Dienophile LUMO Transition Overlap',
            energy: 0.0,
            symmetry: 'Suprafacial-Suprafacial Concerted',
            nodes: 1,
            isHomo: true,
            isLumo: true,
            description: 'Green interaction lines demonstrate primary bond-forming overlap at C1/C4, while purple dashed lines show the stabilizing secondary orbital interaction at C2/C3.',
            lobes: [
              // Diene terminal lobes (bottom lobe pointing down to dienophile)
              OrbitalLobe3D(atomIndex: 0, x: -1.0, y: -0.8, z: 0.3, sign: 1, size: 0.55),
              OrbitalLobe3D(atomIndex: 3, x: 1.0, y: -0.8, z: 0.3, sign: -1, size: 0.55),
              // Diene internal lobes
              OrbitalLobe3D(atomIndex: 1, x: -0.7, y: 0.3, z: 0.3, sign: 1, size: 0.40),
              OrbitalLobe3D(atomIndex: 2, x: 0.7, y: 0.3, z: 0.3, sign: -1, size: 0.40),
              // Dienophile alkene lobes (top lobe pointing up to diene)
              OrbitalLobe3D(atomIndex: 4, x: -0.7, y: -0.8, z: -0.3, sign: 1, size: 0.55),
              OrbitalLobe3D(atomIndex: 5, x: 0.7, y: -0.8, z: -0.3, sign: -1, size: 0.55),
              // Dienophile carbonyl lobe (underneath C2-C3 for secondary interaction)
              OrbitalLobe3D(atomIndex: 6, x: 0.0, y: 0.4, z: -0.3, sign: -1, size: 0.45),
            ],
          ),
        ],
      ),
    ),

    // ----------------------------------------------------
    // EXAMPLE 4: [3,3] Sigmatropic Cope & Claisen Chair TS
    // ----------------------------------------------------
    Pericyclic3DExample(
      id: 'sigmatropic_33_chair',
      title: '[3,3] Sigmatropic Rearrangement in 3D',
      subtitle: 'Cope & Claisen Rearrangements via 6-Membered Chair-like Transition State',
      category: 'Sigmatropic Shifts',
      condition: 'Thermal (Δ) Suprafacial-Suprafacial',
      stereochemicalRule: 'Chair-like transition state favored by ~5.7 kcal/mol over boat-like TS.',
      academicExplanation: 'The [3,3] sigmatropic rearrangement involves the simultaneous cleavage of one sigma bond and formation of a new sigma bond with relocation of two pi bonds across a 6-electron framework. The reaction proceeds through a 6-membered cyclic transition state with an aromatic Hückel electron topology. The transition state overwhelmingly prefers a chair conformation over a boat conformation because the chair minimizes 1,3-diaxial interactions and avoids unfavorable cross-ring non-bonding repulsions. This chair geometry enforces complete chirality transfer from reactant to product.',
      fmoOverlapDescription: 'Suprafacial migration along both allyl frameworks with simultaneous breaking of C3-C4 and forming of C1-C6 sigma bond.',
      transitionStateNotes: 'Equatorial substituents on the chair transition state are favored, dictating (E) vs (Z) double bond geometry in the product.',
      secondaryOrbitalNotes: 'Boat-like transition state is observed only in constrained bicyclic frameworks (e.g. bicyclo[2.2.1]heptanes).',
      system: Pericyclic3DSystem(
        id: 'sys_cope_chair',
        title: '1,5-Hexadiene Chair Transition State',
        formulaOrName: 'CH₂=CH–CH₂–CH₂–CH=CH₂',
        piElectrons: 6,
        atoms: [
          PericyclicAtom3D(index: 0, label: 'C1', x: -1.2, y: -0.7, z: -0.4),
          PericyclicAtom3D(index: 1, label: 'C2', x: -1.2, y: 0.6, z: -0.2),
          PericyclicAtom3D(index: 2, label: 'C3', x: 0.0, y: 1.2, z: 0.4),
          PericyclicAtom3D(index: 3, label: 'C4', x: 1.2, y: 0.7, z: -0.4),
          PericyclicAtom3D(index: 4, label: 'C5', x: 1.2, y: -0.6, z: -0.2),
          PericyclicAtom3D(index: 5, label: 'C6', x: 0.0, y: -1.2, z: 0.4),
        ],
        bonds: [
          PericyclicBond3D(from: 0, to: 1, isDouble: true),
          PericyclicBond3D(from: 1, to: 2, isDouble: false),
          PericyclicBond3D(from: 2, to: 3, isDouble: false), // breaking bond
          PericyclicBond3D(from: 3, to: 4, isDouble: true),
          PericyclicBond3D(from: 4, to: 5, isDouble: false),
          PericyclicBond3D(from: 5, to: 0, isDouble: false), // forming bond
        ],
        orbitals: [
          MolecularOrbital3D(
            name: 'Chair TS Suprafacial Orbital Topology',
            energy: 0.0,
            symmetry: 'Aromatic 6-electron Hückel TS',
            nodes: 0,
            isHomo: true,
            isLumo: false,
            description: 'All 6 orbital lobes maintain continuous constructive in-phase overlap around the chair-shaped loop, conferring aromatic stabilization to the transition state.',
            lobes: [
              OrbitalLobe3D(atomIndex: 0, x: -1.2, y: -0.7, z: 0.2, sign: 1, size: 0.50),
              OrbitalLobe3D(atomIndex: 1, x: -1.2, y: 0.6, z: 0.4, sign: 1, size: 0.50),
              OrbitalLobe3D(atomIndex: 2, x: 0.0, y: 1.2, z: 1.0, sign: 1, size: 0.50),
              OrbitalLobe3D(atomIndex: 3, x: 1.2, y: 0.7, z: 0.2, sign: 1, size: 0.50),
              OrbitalLobe3D(atomIndex: 4, x: 1.2, y: -0.6, z: 0.4, sign: 1, size: 0.50),
              OrbitalLobe3D(atomIndex: 5, x: 0.0, y: -1.2, z: 1.0, sign: 1, size: 0.50),
            ],
          ),
        ],
      ),
    ),

    // ----------------------------------------------------
    // EXAMPLE 5: Regioselectivity via Orbital Coefficients
    // ----------------------------------------------------
    Pericyclic3DExample(
      id: 'regioselectivity_fmo',
      title: 'FMO Regioselectivity & Frontier Coefficients',
      subtitle: '2-Methylbutadiene + Methyl Acrylate (1,4-Para Directing Rule)',
      category: 'Frontier Molecular Orbital Theory',
      condition: 'Thermal (Δ) Frontier Orbital Coefficient Matching',
      stereochemicalRule: 'Largest HOMO coefficient pairs with Largest LUMO coefficient.',
      academicExplanation: 'In unsymmetrical Diels-Alder reactions, regioselectivity is dictated by the magnitude of the frontier orbital coefficients (c_i). For 2-methylbutadiene (isoprene), electron-donation by the methyl group polarizes the diene HOMO: C1 has the largest coefficient (c_1 = 0.58) and C4 has a smaller coefficient (c_4 = 0.40). For methyl acrylate, the electron-withdrawing ester group polarizes the dienophile LUMO: C_beta has the largest coefficient (c_beta = 0.70) while C_alpha is smaller (c_alpha = 0.40). The perturbation equation shows that initial interaction energy is maximized when the atoms with the largest coefficients bond together (C1 to C_beta). This cleanly yields the "para" (1-methyl-4-carbomethoxycyclohexene) regioisomer as the 85% dominant product over the "meta" isomer.',
      fmoOverlapDescription: 'Matching large coefficient (c=0.58 at C1) with large coefficient (c=0.70 at C_beta) lowers transition state energy Delta G‡.',
      transitionStateNotes: 'Synchronous vs Asynchronous bond formation: the bond between the two largest coefficients forms first in an asynchronous transition state.',
      secondaryOrbitalNotes: 'Lewis acid catalysts (AlCl3, BF3) coordinate to the carbonyl, dramatically increasing LUMO polarization and boosting regioselectivity to >98%.',
      system: Pericyclic3DSystem(
        id: 'sys_regio_fmo',
        title: 'Isoprene + Acrylate Coefficient Alignment',
        formulaOrName: '2-Methyl-1,3-butadiene + CH₂=CH–COOMe',
        piElectrons: 6,
        atoms: [
          PericyclicAtom3D(index: 0, label: 'C1 (c=0.58 - Largest)', x: -1.2, y: -0.7, z: 0.5),
          PericyclicAtom3D(index: 1, label: 'C2 (Me-subst)', x: -0.8, y: 0.4, z: 0.5),
          PericyclicAtom3D(index: 2, label: 'C3 (c=0.42)', x: 0.6, y: 0.4, z: 0.5),
          PericyclicAtom3D(index: 3, label: 'C4 (c=0.40)', x: 1.1, y: -0.7, z: 0.5),
          PericyclicAtom3D(index: 4, label: 'C_beta (c=0.70 - Largest)', x: -0.8, y: -0.7, z: -0.5),
          PericyclicAtom3D(index: 5, label: 'C_alpha (c=0.40)', x: 0.7, y: -0.7, z: -0.5),
        ],
        bonds: [
          PericyclicBond3D(from: 0, to: 1, isDouble: true),
          PericyclicBond3D(from: 1, to: 2, isDouble: false),
          PericyclicBond3D(from: 2, to: 3, isDouble: true),
          PericyclicBond3D(from: 4, to: 5, isDouble: true),
        ],
        orbitals: [
          MolecularOrbital3D(
            name: 'Largest Coefficient Matching (1,4-Para Regioselectivity)',
            energy: 0.0,
            symmetry: 'Polarized FMO Overlap',
            nodes: 1,
            isHomo: true,
            isLumo: true,
            description: 'Notice the prominently larger orbital dumbbell at Diene C1 (size 0.58) pairing directly with the enlarged LUMO lobe at Dienophile C_beta (size 0.70).',
            lobes: [
              OrbitalLobe3D(atomIndex: 0, x: -1.2, y: -0.7, z: 0.2, sign: 1, size: 0.70), // largest diene lobe
              OrbitalLobe3D(atomIndex: 3, x: 1.1, y: -0.7, z: 0.2, sign: -1, size: 0.40),
              OrbitalLobe3D(atomIndex: 4, x: -0.8, y: -0.7, z: -0.2, sign: 1, size: 0.85), // largest dienophile lobe
              OrbitalLobe3D(atomIndex: 5, x: 0.7, y: -0.7, z: -0.2, sign: -1, size: 0.40),
            ],
          ),
        ],
      ),
    ),
  ];
}

// ----------------------------------------------------
// Auxiliary Data Models
// ----------------------------------------------------

class WoodwardHoffmannRule {
  final String reactionType;
  final String electronCount;
  final String thermalMode;
  final String photochemicalMode;
  final String homoSymmetry;

  const WoodwardHoffmannRule({
    required this.reactionType,
    required this.electronCount,
    required this.thermalMode,
    required this.photochemicalMode,
    required this.homoSymmetry,
  });
}

class PericyclicPrediction {
  final String allowedMode;
  final String forbiddenMode;
  final bool isThermallyAllowed;
  final String transitionStateSymmetry;
  final String homoState;
  final String stereochemistryExample;

  const PericyclicPrediction({
    required this.allowedMode,
    required this.forbiddenMode,
    required this.isThermallyAllowed,
    required this.transitionStateSymmetry,
    required this.homoState,
    required this.stereochemistryExample,
  });
}

class OrbitalLobe3D {
  final int atomIndex;
  final double x;
  final double y;
  final double z;
  final int sign; // +1 or -1
  final double size; // magnitude of coefficient

  const OrbitalLobe3D({
    required this.atomIndex,
    required this.x,
    required this.y,
    required this.z,
    required this.sign,
    required this.size,
  });
}

class MolecularOrbital3D {
  final String name;
  final double energy;
  final String symmetry;
  final int nodes;
  final bool isHomo;
  final bool isLumo;
  final String description;
  final List<OrbitalLobe3D> lobes;

  const MolecularOrbital3D({
    required this.name,
    required this.energy,
    required this.symmetry,
    required this.nodes,
    required this.isHomo,
    required this.isLumo,
    required this.description,
    required this.lobes,
  });
}

class PericyclicAtom3D {
  final int index;
  final String label;
  final double x;
  final double y;
  final double z;

  const PericyclicAtom3D({
    required this.index,
    required this.label,
    required this.x,
    required this.y,
    required this.z,
  });
}

class PericyclicBond3D {
  final int from;
  final int to;
  final bool isDouble;

  const PericyclicBond3D({
    required this.from,
    required this.to,
    required this.isDouble,
  });
}

class Pericyclic3DSystem {
  final String id;
  final String title;
  final String formulaOrName;
  final int piElectrons;
  final List<PericyclicAtom3D> atoms;
  final List<PericyclicBond3D> bonds;
  final List<MolecularOrbital3D> orbitals;

  const Pericyclic3DSystem({
    required this.id,
    required this.title,
    required this.formulaOrName,
    required this.piElectrons,
    required this.atoms,
    required this.bonds,
    required this.orbitals,
  });
}

class Pericyclic3DExample {
  final String id;
  final String title;
  final String subtitle;
  final String category;
  final String condition;
  final String stereochemicalRule;
  final String academicExplanation;
  final String fmoOverlapDescription;
  final String transitionStateNotes;
  final String? secondaryOrbitalNotes;
  final Pericyclic3DSystem system;

  const Pericyclic3DExample({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.category,
    required this.condition,
    required this.stereochemicalRule,
    required this.academicExplanation,
    required this.fmoOverlapDescription,
    required this.transitionStateNotes,
    this.secondaryOrbitalNotes,
    required this.system,
  });
}
