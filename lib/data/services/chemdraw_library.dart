import '../models/reaction_models.dart';

/// Bundled ChemDraw-style step SVGs for the 10 in-app mechanisms.
class ChemDrawLibrary {
  ChemDrawLibrary._();

  static const folders = <String, String>{
    'sn1': 'assets/mechanisms/substitution/sn1/',
    'sn2': 'assets/mechanisms/substitution/sn2/',
    'e1': 'assets/mechanisms/elimination/e1/',
    'e2': 'assets/mechanisms/elimination/e2/',
    'cannizzaro': 'assets/mechanisms/named/cannizzaro/',
    'aldol': 'assets/mechanisms/enolate/aldol/',
    'wittig': 'assets/mechanisms/carbonyl/wittig/',
    'diels_alder': 'assets/mechanisms/pericyclic/diels_alder/',
    'grignard': 'assets/mechanisms/carbonyl/grignard/',
    'beckmann': 'assets/mechanisms/rearrangements/beckmann/',
    'benzoin': 'assets/mechanisms/named/benzoin/',
  };

  static const examples = <String, String>{
    'sn1': 'tert-butyl bromide + water → tert-butanol (canonical SN1 class example)',
    'sn2': '(S)-2-bromobutane + HO- → (R)-butan-2-ol (canonical SN2 class example)',
    'e1': 'tert-butyl bromide + heat/water → 2-methylpropene (canonical E1 class example)',
    'e2': '2-bromobutane + EtO- → trans-but-2-ene (canonical E2 class example)',
    'cannizzaro': 'benzaldehyde + conc. NaOH → benzoate + benzyl alcohol',
    'aldol': 'acetaldehyde + NaOEt → crotonaldehyde after dehydration',
    'wittig': 'Ph3P=CH2 + acetone → 2-methylpropene + Ph3P=O',
    'diels_alder': '1,3-butadiene + ethene → cyclohexene (canonical [4+2])',
    'grignard': 'MeMgBr + acetone, then H3O+ → tert-butanol',
    'beckmann': 'cyclohexanone oxime + acid → epsilon-caprolactam',
    'benzoin': '2 PhCHO + KCN → benzoin',
  };

  static List<ReactionStep>? stepsFor(String id) => _steps[id];

  static ReactionMechanism attach(ReactionMechanism m) {
    final steps = _steps[m.id];
    if (steps == null) return m;
    return ReactionMechanism(
      id: m.id,
      name: m.name,
      aliases: m.aliases,
      category: m.category,
      summary: m.summary,
      reactants: m.reactants,
      reagentsAndConditions: m.reagentsAndConditions,
      products: m.products,
      steps: steps,
      svgPath: folders[m.id],
      svgUrl: m.svgUrl,
      svgContent: null,
      keyApplications: m.keyApplications,
      limitations: m.limitations,
      isVerified: false,
      representativeExample: examples[m.id] ?? m.representativeExample,
      verificationStatus: 'needs_review',
    );
  }

  static final _steps = <String, List<ReactionStep>>{
    'sn1': [
      ReactionStep(
        stepNumber: 1,
        title: 'C-Br heterolysis (RDS)',
        description: 'The C-Br bonding pair moves onto bromine, giving a planar tert-butyl cation.',
        curvedArrowNotes: 'Two-electron: C-Br bond to Br.',
        svgAsset: 'assets/mechanisms/substitution/sn1/step-01.svg',
        electronFlow: [
          ElectronFlow(type: 'two-electron', source: 'C-Br sigma bond', destination: 'bromine'),
        ],
      ),
      ReactionStep(
        stepNumber: 2,
        title: 'Water attacks the carbocation',
        description: 'A water lone pair attacks the empty p orbital. Either face is possible (racemization if the carbon is chiral).',
        curvedArrowNotes: 'Two-electron: O lone pair to C+.',
        svgAsset: 'assets/mechanisms/substitution/sn1/step-02.svg',
        electronFlow: [
          ElectronFlow(type: 'two-electron', source: 'water oxygen lone pair', destination: 'carbocation carbon'),
        ],
      ),
      ReactionStep(
        stepNumber: 3,
        title: 'Deprotonation to tert-butanol',
        description: 'A second water removes the oxonium proton. Product is tert-butanol.',
        svgAsset: 'assets/mechanisms/substitution/sn1/step-03.svg',
      ),
    ],
    'sn2': [
      ReactionStep(
        stepNumber: 1,
        title: 'Backside attack and C-Br cleavage',
        description: 'Hydroxide lone pair to C2; C-Br bonding pair to Br, concerted.',
        svgAsset: 'assets/mechanisms/substitution/sn2/step-01.svg',
        electronFlow: [
          ElectronFlow(type: 'two-electron', source: 'hydroxide lone pair', destination: 'C2'),
          ElectronFlow(type: 'two-electron', source: 'C2-Br bond', destination: 'Br'),
        ],
      ),
      ReactionStep(
        stepNumber: 2,
        title: 'Trigonal bipyramidal TS',
        description: 'Collinear HO...C...Br transition state, not a carbocation.',
        svgAsset: 'assets/mechanisms/substitution/sn2/step-02.svg',
      ),
      ReactionStep(
        stepNumber: 3,
        title: 'Walden inversion product',
        description: '(R)-butan-2-ol and bromide.',
        svgAsset: 'assets/mechanisms/substitution/sn2/step-03.svg',
      ),
    ],
    'e1': [
      ReactionStep(
        stepNumber: 1,
        title: 'Ionization (RDS)',
        description: 'C-Br heterolysis to the tert-butyl cation.',
        svgAsset: 'assets/mechanisms/elimination/e1/step-01.svg',
        electronFlow: [
          ElectronFlow(type: 'two-electron', source: 'C-Br bond', destination: 'Br'),
        ],
      ),
      ReactionStep(
        stepNumber: 2,
        title: 'Beta-deprotonation',
        description: 'Water abstracts a beta-H; C-H electrons form the C=C bond. No rearrangement needed here.',
        svgAsset: 'assets/mechanisms/elimination/e1/step-02.svg',
        electronFlow: [
          ElectronFlow(type: 'two-electron', source: 'water lone pair', destination: 'beta-H'),
          ElectronFlow(type: 'two-electron', source: 'C-H bond', destination: 'C-C bond'),
        ],
      ),
      ReactionStep(
        stepNumber: 3,
        title: '2-methylpropene',
        description: 'Zaitsev alkene plus H3O+ and Br-.',
        svgAsset: 'assets/mechanisms/elimination/e1/step-03.svg',
      ),
    ],
    'e2': [
      ReactionStep(
        stepNumber: 1,
        title: 'Concerted anti-periplanar elimination',
        description: 'EtO- to beta-H, C-H to C=C, C-Br to Br, all in one step.',
        svgAsset: 'assets/mechanisms/elimination/e2/step-01.svg',
        electronFlow: [
          ElectronFlow(type: 'two-electron', source: 'ethoxide lone pair', destination: 'beta-H'),
          ElectronFlow(type: 'two-electron', source: 'C-H bond', destination: 'C-C bond'),
          ElectronFlow(type: 'two-electron', source: 'C-Br bond', destination: 'Br'),
        ],
      ),
      ReactionStep(
        stepNumber: 2,
        title: 'trans-but-2-ene',
        description: 'Zaitsev trans alkene, ethanol, and bromide.',
        svgAsset: 'assets/mechanisms/elimination/e2/step-02.svg',
      ),
    ],
    'cannizzaro': [
      ReactionStep(
        stepNumber: 1,
        title: 'Hydroxide addition',
        description: 'HO- attacks benzaldehyde; C=O pi electrons go to oxygen.',
        svgAsset: 'assets/mechanisms/named/cannizzaro/step-01.svg',
      ),
      ReactionStep(
        stepNumber: 2,
        title: 'Hydride transfer',
        description: 'The tetrahedral C-H is the hydride source; destination is a second carbonyl carbon.',
        svgAsset: 'assets/mechanisms/named/cannizzaro/step-02.svg',
      ),
      ReactionStep(
        stepNumber: 3,
        title: 'Benzoate and benzyl alcohol',
        description: 'After proton transfer: PhCO2- and PhCH2OH.',
        svgAsset: 'assets/mechanisms/named/cannizzaro/step-03.svg',
      ),
    ],
    'aldol': [
      ReactionStep(
        stepNumber: 1,
        title: 'Enolate formation',
        description: 'Ethoxide deprotonates acetaldehyde; C-H electrons feed the enolate.',
        svgAsset: 'assets/mechanisms/enolate/aldol/step-01.svg',
      ),
      ReactionStep(
        stepNumber: 2,
        title: 'Enolate attack',
        description: 'Enolate carbon attacks a second acetaldehyde carbonyl.',
        svgAsset: 'assets/mechanisms/enolate/aldol/step-02.svg',
      ),
      ReactionStep(
        stepNumber: 3,
        title: 'Dehydration to crotonaldehyde',
        description: 'After protonation, heat drives E1cB-type dehydration.',
        svgAsset: 'assets/mechanisms/enolate/aldol/step-03.svg',
      ),
    ],
    'wittig': [
      ReactionStep(
        stepNumber: 1,
        title: 'Ylide attack',
        description: 'Ph3P=CH2 carbon attacks acetone; C=O pi electrons go to oxygen.',
        svgAsset: 'assets/mechanisms/carbonyl/wittig/step-01.svg',
      ),
      ReactionStep(
        stepNumber: 2,
        title: 'Oxaphosphetane',
        description: 'Four-membered P-C-C-O intermediate (salt-free [2+2] path).',
        svgAsset: 'assets/mechanisms/carbonyl/wittig/step-02.svg',
      ),
      ReactionStep(
        stepNumber: 3,
        title: 'Alkene + Ph3P=O',
        description: 'Cycloreversion gives 2-methylpropene and triphenylphosphine oxide.',
        svgAsset: 'assets/mechanisms/carbonyl/wittig/step-03.svg',
      ),
    ],
    'diels_alder': [
      ReactionStep(
        stepNumber: 1,
        title: 'Concerted [4+2] electron flow',
        description: 'Three two-electron arrows; no zwitterionic intermediate for this simple case.',
        svgAsset: 'assets/mechanisms/pericyclic/diels_alder/step-01.svg',
      ),
      ReactionStep(
        stepNumber: 2,
        title: 'Cyclohexene',
        description: 'New sigma bonds at the diene termini; remaining endocyclic alkene.',
        svgAsset: 'assets/mechanisms/pericyclic/diels_alder/step-02.svg',
      ),
    ],
    'grignard': [
      ReactionStep(
        stepNumber: 1,
        title: 'C-Mg attack on acetone',
        description: 'C-Mg bonding pair to carbonyl carbon; pi bond to oxygen.',
        svgAsset: 'assets/mechanisms/carbonyl/grignard/step-01.svg',
      ),
      ReactionStep(
        stepNumber: 2,
        title: 'Alkoxide-MgX complex',
        description: 'Tetrahedral intermediate; do not skip this stage.',
        svgAsset: 'assets/mechanisms/carbonyl/grignard/step-02.svg',
      ),
      ReactionStep(
        stepNumber: 3,
        title: 'H3O+ workup',
        description: 'Protonation yields tert-butanol.',
        svgAsset: 'assets/mechanisms/carbonyl/grignard/step-03.svg',
      ),
    ],
    'beckmann': [
      ReactionStep(
        stepNumber: 1,
        title: 'Anti migration',
        description: 'The C-C bond anti to the leaving group migrates to nitrogen as water departs.',
        svgAsset: 'assets/mechanisms/rearrangements/beckmann/step-01.svg',
      ),
      ReactionStep(
        stepNumber: 2,
        title: 'Hydration of the nitrilium',
        description: 'Water attacks the electron-deficient carbon.',
        svgAsset: 'assets/mechanisms/rearrangements/beckmann/step-02.svg',
      ),
      ReactionStep(
        stepNumber: 3,
        title: 'Caprolactam',
        description: 'Tautomerization gives epsilon-caprolactam.',
        svgAsset: 'assets/mechanisms/rearrangements/beckmann/step-03.svg',
      ),
    ],
    'benzoin': [
      ReactionStep(
        stepNumber: 1,
        title: 'Cyanide addition / umpolung',
        description: 'CN- attacks benzaldehyde; after proton shifts the carbon is nucleophilic.',
        svgAsset: 'assets/mechanisms/named/benzoin/step-01.svg',
      ),
      ReactionStep(
        stepNumber: 2,
        title: 'Attack on second aldehyde',
        description: 'Umpolung carbanion to the second carbonyl carbon.',
        svgAsset: 'assets/mechanisms/named/benzoin/step-02.svg',
      ),
      ReactionStep(
        stepNumber: 3,
        title: 'Cyanide elimination',
        description: 'Collapse regenerates CN- and yields benzoin.',
        svgAsset: 'assets/mechanisms/named/benzoin/step-03.svg',
      ),
    ],
  };
}
