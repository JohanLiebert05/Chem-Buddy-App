/// MSc Chemistry Pericyclic Service
/// Encapsulates the Woodward-Hoffmann rules, Frontier Molecular Orbital (FMO) analysis,
/// and stereochemical predictions for electrocyclic reactions, cycloadditions, and sigmatropic shifts.
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
      homoSymmetry: 'Thermal HOMO is Psi2 (C2 symmetric, antisymmetric on mirror plane m).',
    ),
    WoodwardHoffmannRule(
      reactionType: 'Electrocyclic',
      electronCount: '4n+2 (e.g. 6 pi: Hexatriene)',
      thermalMode: 'Disrotatory (Allowed)',
      photochemicalMode: 'Conrotatory (Allowed)',
      homoSymmetry: 'Thermal HOMO is Psi3 (Mirror plane m symmetric).',
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
}

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
