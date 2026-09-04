import 'package:shared_preferences/shared_preferences.dart';
import '../models/reaction_models.dart';
import 'chemdraw_library.dart';
import 'reaction_diagram_svg_catalog.dart';

/// Service providing verified, step-by-step MSc chemistry reaction mechanisms,
/// electron movement, curved arrow descriptions, intermediates, and cached vector SVGs.
class ReactionMechanismService {
  ReactionMechanismService._();
  static final ReactionMechanismService instance = ReactionMechanismService._();

  final Map<String, String> _svgCache = {};

  List<ReactionMechanism> get mechanisms => curatedMechanisms;

  /// Retrieves and caches SVG vector diagrams for the requested reaction mechanism.
  Future<String> getSvgForMechanism(String id) async {
    final cleanId = id.trim().toLowerCase();
    if (_svgCache.containsKey(cleanId)) {
      return _svgCache[cleanId]!;
    }
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('cached_svg_$cleanId');
      if (cached != null && cached.isNotEmpty) {
        _svgCache[cleanId] = cached;
        return cached;
      }
    } catch (_) {
      // SharedPreferences failure fallback
    }

    final svg = ReactionDiagramSvgCatalog.getSvgFor(cleanId);
    _svgCache[cleanId] = svg;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('cached_svg_$cleanId', svg);
    } catch (_) {}

    return svg;
  }

  static final List<ReactionMechanism> curatedMechanisms =
      _baseMechanisms.map(ChemDrawLibrary.attach).toList(growable: false);

  static final List<ReactionMechanism> _baseMechanisms = [
    // 1. SN1 SUBSTITUTION
    ReactionMechanism(
      id: 'sn1',
      name: 'SN1 Nucleophilic Substitution',
      aliases: ['Unimolecular Nucleophilic Substitution', 'Carbocation Pathway', 'Solvolysis'],
      category: ReactionCategory.stereochemistry,
      summary:
          r'Two-step unimolecular nucleophilic substitution proceeding via a planar carbocation intermediate. Rate depends only on substrate concentration: $\text{Rate} = k[\text{R-X}]$. Results in racemization with partial inversion.',
      reactants: r'$3^\circ$ Alkyl halide / Benzylic / Allylic halide ($\text{R}_3\text{C-X}$)',
      reagentsAndConditions: r'Weak nucleophile / polar protic solvent ($\text{H}_2\text{O}, \text{ROH}$), moderate temperature',
      products: r'Racemic nucleophilic product ($\text{R}_3\text{C-Nu}$)',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('sn1'),
      isVerified: true,
      keyApplications: [
        r'Solvolysis of tert-butyl halides to tert-butanol or ethers.',
        r'Formation of stable carbocations for synthetic rearrangements and Wagner-Meerwein shifts.',
      ],
      limitations: [
        r'Fails with $1^\circ$ and methyl halides due to high energy of primary carbocations.',
        r'Prone to carbocation rearrangements (hydride and alkyl shifts).',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Carbocation Formation (Heterolysis, Rate-Determining Step)',
          description:
              r'Departure of the leaving group $X^-$ produces a planar, trigonal $sp^2$-hybridized carbocation with an empty $p$-orbital.',
          curvedArrowNotes:
              r'Curved arrow from C-X bonding pair onto halogen atom $X$ to release halide ion $X^-$.',
          intermediate: r'$[\text{R}_3\text{C}^+]$ Planar Carbocation Intermediate',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Nucleophilic Attack & Deprotonation (Fast)',
          description:
              r'The nucleophile attacks the planar carbocation from either top or bottom face with equal probability, yielding racemization.',
          curvedArrowNotes:
              r'Nucleophile lone pair attacks the vacant $p$-orbital of $C^+$ from either re or si face.',
          intermediate: r'$\text{R}_3\text{C-Nu}$ (Racemic Product)',
        ),
      ],
    ),

    // 2. SN2 SUBSTITUTION
    ReactionMechanism(
      id: 'sn2',
      name: 'SN2 Nucleophilic Substitution',
      aliases: ['Bimolecular Nucleophilic Substitution', 'Walden Inversion', 'Backside Attack'],
      category: ReactionCategory.stereochemistry,
      summary:
          r'Concerted, single-step bimolecular substitution featuring a backside nucleophilic attack at $180^\circ$ to the leaving group, passing through a pentacoordinate trigonal bipyramidal transition state with 100% Walden inversion.',
      reactants: r'Methyl / $1^\circ$ Alkyl halide ($\text{R-CH}_2\text{-X}$)',
      reagentsAndConditions: r'Strong nucleophile ($\text{I}^-, \text{CN}^-, \text{N}_3^-, \text{OH}^-$) in Polar Aprotic Solvent (DMSO, DMF, Acetone)',
      products: r'Inverted Configuration Product ($\text{Nu-CH}_2\text{-R}$)',
      representativeExample:
          '(S)-2-bromobutane + hydroxide → (R)-butan-2-ol + bromide (canonical example; source directory lists the SN2 class, not this substrate)',
      verificationStatus: 'needs_review',
      isVerified: false,
      svgPath: 'assets/mechanisms/substitution/sn2/',
      svgContent: null,
      keyApplications: [
        r'Stereospecific synthesis of chiral alcohols, amines, azides, and nitriles with inversion of stereocenters.',
        r'Williamson ether synthesis: $\text{R-O}^- + \text{R\x27-X} \rightarrow \text{R-O-R\x27} + \text{X}^-$.',
      ],
      limitations: [
        r'Completely blocked by steric hindrance in $3^\circ$ substrates and neopentyl halides.',
        r'Unreactive with aryl and vinyl halides due to high $\sigma^*(\text{C-X})$ energy and geometric blockage.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Backside nucleophilic attack with simultaneous C–Br cleavage',
          description:
              r'Hydroxide donates a lone pair into $\sigma^*(\text{C-Br})$ from $180^\circ$ opposite bromine. The C–Br pair departs onto Br in the same concerted step.',
          curvedArrowNotes:
              r'Two-electron arrow: O lone pair → C2. Two-electron arrow: C2–Br bond → Br.',
          intermediate: r'Concerted; no carbocation. Proceeds through $[\text{HO}\cdots\text{C}\cdots\text{Br}]^\ddagger$.',
          svgAsset: 'assets/mechanisms/substitution/sn2/step-01.svg',
          electronFlow: const [
            ElectronFlow(type: 'two-electron', source: 'hydroxide oxygen lone pair', destination: 'electrophilic C2'),
            ElectronFlow(type: 'two-electron', source: 'C2–Br σ bond', destination: 'bromine atom'),
          ],
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Trigonal bipyramidal transition state',
          description:
              r'Pentacoordinate carbon with collinear $\text{HO}\cdots\text{C}\cdots\text{Br}$. Methyl, hydrogen, and ethyl are equatorial. This is a transition state, not an intermediate.',
          curvedArrowNotes:
              r'Partial C–O forming and C–Br breaking remain collinear (180°).',
          intermediate: r'$[\text{HO}\cdots\text{C}\cdots\text{Br}]^\ddagger$ (transition state)',
          svgAsset: 'assets/mechanisms/substitution/sn2/step-02.svg',
          electronFlow: const [
            ElectronFlow(type: 'two-electron', source: 'forming C–O', destination: 'C2'),
            ElectronFlow(type: 'two-electron', source: 'breaking C–Br', destination: 'Br'),
          ],
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Walden inversion — (R)-butan-2-ol',
          description:
              r'The nucleophile is fully bonded. Configuration at C2 is inverted relative to (S)-2-bromobutane. Bromide is the leaving-group product.',
          curvedArrowNotes: r'No further electron flow after collapse of the transition state.',
          intermediate: r'$(R)$-butan-2-ol + $\text{Br}^-$',
          svgAsset: 'assets/mechanisms/substitution/sn2/step-03.svg',
        ),
      ],
    ),

    // 3. E1 ELIMINATION
    ReactionMechanism(
      id: 'e1',
      name: 'E1 Elimination Reaction',
      aliases: ['Unimolecular Elimination', 'Zaitsev Alkene Formation'],
      category: ReactionCategory.stereochemistry,
      summary:
          r'Two-step unimolecular elimination. Rate-determining ionization produces a carbocation, which subsequently loses a $\beta$-proton to base, yielding the most substituted, thermodynamically stable (Zaitsev) alkene.',
      reactants: r'$3^\circ$ Alkyl halide / tertiary alcohol under acid conditions',
      reagentsAndConditions: r'Weak base ($\text{H}_2\text{O}, \text{EtOH}$) / $\text{H}_2\text{SO}_4$, Heat ($\Delta$)',
      products: r'Thermodynamically favored Zaitsev Alkene + $\text{H-Base}^+ + \text{X}^-$',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('e1'),
      isVerified: true,
      keyApplications: [
        r'Acid-catalyzed dehydration of $3^\circ$ alcohols to alkenes.',
        r'Thermodynamic alkene synthesis via stable carbocations.',
      ],
      limitations: [
        r'Competes directly with SN1 substitution in polar protic solvents.',
        r'Rearrangements of the carbocation intermediate often yield isomeric mixtures.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Carbocation Formation (Rate-Determining Step)',
          description:
              r'Heterolytic cleavage of the C-X bond releases $X^-$, forming a planar carbocation intermediate.',
          curvedArrowNotes: r'Arrow from C-X bond to halogen atom X.',
          intermediate: r'$[\text{R}_3\text{C}^+]$ Carbocation',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Base Deprotonation of β-Hydrogen (Fast)',
          description:
              r'A weak base abstracts a $\beta$-hydrogen. The C-H bonding pair collapses into the vacant $p$-orbital of $C^+$ to establish the $C=C$ $\pi$-bond.',
          curvedArrowNotes:
              r'Arrow from base lone pair to $\beta\text{-H}$, and arrow from $\text{C}_\beta\text{-H}$ bond to $\text{C}_\alpha\text{-C}_\beta$ bond.',
          intermediate: r'Zaitsev Alkene ($\text{R}_2\text{C=CR}_2$)',
        ),
      ],
    ),

    // 4. E2 ELIMINATION
    ReactionMechanism(
      id: 'e2',
      name: 'E2 Bimolecular Elimination',
      aliases: ['Bimolecular Elimination', 'Anti-Periplanar Elimination', 'Hofmann/Zaitsev Elimination'],
      category: ReactionCategory.stereochemistry,
      summary:
          r'Concerted bimolecular elimination requiring anti-periplanar ($180^\circ$ dihedral angle) geometry between the $\beta$-hydrogen and the leaving group. Non-bulky bases yield Zaitsev alkenes, while bulky bases (e.g. potassium t-butoxide) yield Hofmann alkenes.',
      reactants: r'$1^\circ, 2^\circ$, or $3^\circ$ Alkyl halide with accessible $\beta$-hydrogen',
      reagentsAndConditions: r'Strong base ($\text{EtO}^-, \text{OH}^-$, or $\text{t-BuO}^-$) in alcoholic solvent, Heat',
      products: r'Alkene + $\text{HB} + \text{X}^-$',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('e2'),
      isVerified: true,
      keyApplications: [
        r'Regioselective alkene synthesis (Hofmann product with $t\text{-BuOK}$, Zaitsev with $\text{NaOEt}$).',
        r'Stereospecific synthesis of trans-alkenes and cyclic alkenes based on diaxial anti-periplanar conformers.',
      ],
      limitations: [
        r'Requires strict anti-coplanar transition state geometry ($\text{H-C-C-X} \approx 180^\circ$). In cyclohexane rings, both H and X must be trans-diaxial.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Concerted Anti-Periplanar Transition State',
          description:
              r'Base abstracts the anti-periplanar $\beta$-proton simultaneously as the C-H electrons form the $C=C$ $\pi$-bond and the leaving group departs.',
          curvedArrowNotes:
              r'Three concerted arrows: Base $\rightarrow$ $\beta\text{-H}$, $\text{C}_\beta\text{-H}$ bond $\rightarrow$ $\text{C-C}$ bond, and $\text{C}_\alpha\text{-X}$ bond $\rightarrow$ X.',
          intermediate: r'$[\text{B}\cdots\text{H}\cdots\text{C}=\text{C}\cdots\text{X}]^\ddagger$ Transition State',
        ),
      ],
    ),

    // 5. CANNIZZARO REACTION
    ReactionMechanism(
      id: 'cannizzaro',
      name: 'Cannizzaro Reaction',
      aliases: ['Disproportionation of Aldehydes', 'Crossed Cannizzaro'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Base-induced disproportionation (redox) of non-enolizable aldehydes (lacking $\alpha$-hydrogens) to yield an equimolar mixture of a primary alcohol and a carboxylic acid salt.',
      reactants: r'2 R-CHO (where R = aryl, $3^\circ$ alkyl, or H, lacking $\alpha$-H)',
      reagentsAndConditions: r'Concentrated strong base ($50\%\text{ NaOH}$ or $\text{KOH}$), Heat ($60\text{–}100^\circ\text{C}$)',
      products: r'$\text{R-CH}_2\text{OH}$ (Primary Alcohol) + $\text{R-COO}^-\text{Na}^+$ (Carboxylate Salt)',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('cannizzaro'),
      isVerified: true,
      keyApplications: [
        r'Synthesis of benzoic acid and benzyl alcohol from benzaldehyde ($\text{C}_6\text{H}_5\text{CHO}$).',
        r'Industrial preparation of pentaerythritol using crossed Cannizzaro with formaldehyde ($\text{HCHO}$).',
      ],
      limitations: [
        r'Fails with aldehydes possessing acidic $\alpha$-hydrogens (which undergo Aldol condensation instead).',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Nucleophilic Hydroxide Addition',
          description:
              r'Hydroxide ion ($\text{OH}^-$) acts as a nucleophile and attacks the carbonyl carbon of the aldehyde, generating a tetrahedral dianionic/monoanionic alkoxide intermediate.',
          curvedArrowNotes:
              r'Curved arrow from $:O-H^-$ lone pair to carbonyl carbon $C=O$; electron pair from $C=O$ double bond shifts to oxygen atom to form $O^-$.',
          intermediate: r'$[\text{R-CH(OH)O}^-]$ or $[\text{R-CH(O}^-)_2]^{2-}$ (Hydride donor intermediate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Hydride Transfer (Rate-Determining Step)',
          description:
              r'Collapse of the alkoxide oxygen electron pair forces the transfer of a hydride ion ($:\text{H}^-$) to the carbonyl carbon of a second aldehyde molecule.',
          curvedArrowNotes:
              r'Oxygen $O^-$ lone pair pushes back to re-form $C=O$ double bond; C-H bonding pair shifts as $:H^-$ to attack carbonyl carbon of second aldehyde; second aldehyde $C=O$ opens to $O^-$.',
          intermediate: r'$\text{R-COOH}$ (Carboxylic Acid) + $\text{R-CH}_2\text{O}^-$ (Alkoxide Ion)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Rapid Acid-Base Proton Exchange',
          description:
              r'The strongly basic alkoxide ion ($\text{R-CH}_2\text{O}^-$) immediately deprotonates the carboxylic acid ($\text{R-COOH}$), driving the equilibrium irreversibly forward.',
          curvedArrowNotes:
              r'Alkoxide oxygen lone pair attacks acidic proton on carboxyl group $O-H$; $O-H$ electron pair shifts onto carboxylate oxygen.',
          intermediate: r'$\text{R-COO}^-$ (Carboxylate) + $\text{R-CH}_2\text{OH}$ (Primary Alcohol)',
        ),
      ],
    ),

    // 6. ALDOL CONDENSATION
    ReactionMechanism(
      id: 'aldol',
      name: 'Aldol Condensation',
      aliases: ['Aldol Reaction', 'Crossed Aldol', 'Claisen-Schmidt Condensation'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Base- or acid-catalyzed enolization of an aldehyde or ketone followed by nucleophilic addition to another carbonyl group, yielding a $\beta$-hydroxy carbonyl compound, which undergoes subsequent elimination to form an $\alpha,\beta$-unsaturated enone.',
      reactants: r'Aldehydes or ketones containing acidic $\alpha$-hydrogens',
      reagentsAndConditions: r'Dilute base ($10\%\text{ NaOH}$) or acid ($\text{HCl}$), followed by heat ($\Delta$)',
      products: r'$\alpha,\beta$-Unsaturated aldehyde/ketone (Enal / Enone) + $\text{H}_2\text{O}$',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('aldol'),
      isVerified: true,
      keyApplications: [
        r'Formation of carbon-carbon bonds in steroid and alkaloid synthesis (Robinson annulation).',
        r'Synthesis of chalcones and cinnamaldehyde via Claisen-Schmidt reaction.',
      ],
      limitations: [
        r'Crossed Aldols with two enolizable partners yield complex mixtures of four products unless one partner lacks $\alpha$-hydrogens or LDA is used.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Enolate Generation (Deprotonation)',
          description:
              r'Base removes an acidic $\alpha$-hydrogen to form a resonance-stabilized enolate anion.',
          curvedArrowNotes:
              r'Base abstracts $\alpha\text{-H}$; C-H electrons shift to form $C=C$ double bond, shifting $C=O$ $\pi$-electrons to oxygen.',
          intermediate: r'$[\text{R-CH}=\text{C(H)-O}^- \leftrightarrow \text{R-CH}^-\text{-CHO}]$ (Enolate Anion)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Nucleophilic Carbonyl Addition (C-C Bond Formation)',
          description:
              r'Enolate carbon attacks the electrophilic carbonyl carbon of the second aldehyde molecule, generating a tetrahedral alkoxide.',
          curvedArrowNotes:
              r'Enolate $C=C$ electrons attack electrophilic carbonyl carbon; second carbonyl $\pi$-electrons shift to oxygen.',
          intermediate: r'Tetrahedral alkoxide adduct',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Protonation & E1cB Dehydration',
          description:
              r'Protonation produces the $\beta$-hydroxy carbonyl (Aldol). Heating eliminates water via an E1cB pathway to give the conjugated $\alpha,\beta$-unsaturated carbonyl.',
          curvedArrowNotes:
              r'Base deprotonates residual $\alpha\text{-H}$ forming an enolate; $O^-$ pushes back to kick off $OH^-$ as leaving group.',
          intermediate: r'$\alpha,\beta$-Unsaturated Enone (Conjugated Product)',
        ),
      ],
    ),

    // 7. WITTIG REACTION
    ReactionMechanism(
      id: 'wittig',
      name: 'Wittig Reaction',
      aliases: ['Olefin Synthesis', 'Phosphonium Ylide Carbonyl Olefination'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Reaction of a phosphonium ylide (phosphorane) with an aldehyde or ketone to yield an alkene and triphenylphosphine oxide ($\text{Ph}_3\text{P=O}$) via a four-membered oxaphosphetane intermediate.',
      reactants: r'Aldehyde or Ketone ($\text{R}_2\text{C=O}$) + Phosphonium Ylide ($\text{Ph}_3\text{P=CHR\x27}$)',
      reagentsAndConditions: r'Strong base ($n\text{-BuLi, NaH, or NaHMDS}$ in dry THF / ether), $0^\circ\text{C}$ to RT',
      products: r'Alkene ($\text{R}_2\text{C=CHR\x27}$) + Triphenylphosphine oxide ($\text{Ph}_3\text{P=O}$)',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('wittig'),
      isVerified: true,
      keyApplications: [
        r'Precision alkene synthesis with unequivocal positioning of the double bond (no double bond migration).',
        r'Synthesis of vitamin A, prostaglandins, and complex natural products.',
      ],
      limitations: [
        r'Sterically hindered ketones react slowly or fail.',
        r'Non-stabilized ylides give predominantly (Z)-alkenes, while stabilized ylides give (E)-alkenes.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Nucleophilic Ylide Addition [2+2 Cycloaddition]',
          description:
              r'The carbanionic carbon of the ylide attacks the carbonyl carbon, and carbonyl oxygen attacks the phosphorus atom in a concerted $[2+2]$ cycloaddition to create a 4-membered oxaphosphetane ring.',
          curvedArrowNotes:
              r'Curved arrow from ylide $C^-$ to carbonyl carbon; curved arrow from $C=O$ oxygen to phosphorus atom $P^+$.',
          intermediate: r'Oxaphosphetane (4-Membered Cyclic Intermediate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Retro-[2+2] Cycloreversion (Driving Force)',
          description:
              r'The oxaphosphetane ring collapses via retro-[2+2] cleavage driven by the formation of the exceptionally strong phosphorus-oxygen bond ($P=O$, $\sim 540\text{ kJ/mol}$).',
          curvedArrowNotes:
              r'C-P bond electrons shift to form $C=C$ double bond; C-O bond electrons shift to form $P=O$ double bond.',
          intermediate: r'Alkene + $\text{Ph}_3\text{P=O}$ (Triphenylphosphine oxide)',
        ),
      ],
    ),

    // 8. DIELS-ALDER CYCLOADDITION
    ReactionMechanism(
      id: 'diels_alder',
      name: 'Diels-Alder [4+2] Cycloaddition',
      aliases: ['[4+2] Cycloaddition', 'Diene-Dienophile Addition', 'Endo-Selective Cyclization'],
      category: ReactionCategory.pericyclic,
      summary:
          r'Thermally allowed, concerted, suprafacial pericyclic $[4\pi_s + 2\pi_s]$ cycloaddition between a conjugated diene in s-cis conformation and a dienophile to form a cyclohexene ring with high stereospecificity and endo selectivity.',
      reactants: r'Conjugated diene (s-cis) + Dienophile (electron-deficient alkene/alkyne)',
      reagentsAndConditions: r'Thermal ($\Delta$, $25\text{–}150^\circ\text{C}$) or Lewis Acid catalyst ($\text{AlCl}_3, \text{TiCl}_4$)',
      products: r'Substituted Cyclohexene Derivative (Endo Adduct)',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('diels_alder'),
      isVerified: true,
      keyApplications: [
        r'Construction of polycyclic frameworks, steroids, cantharidin, and reserpine.',
        r'Total stereochemical control of up to 4 contiguous stereocenters in a single step.',
      ],
      limitations: [
        r'Dienes locked in an s-trans conformation (e.g. fixed trans-rings) cannot undergo the reaction.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Concerted Suprafacial Overlap & Aromatic Transition State',
          description:
              r'HOMO of the diene interacts with the LUMO of the dienophile in a cyclic, 6-electron aromatic transition state without ionic or radical intermediates.',
          curvedArrowNotes:
              r'Three curved arrows moving synchronously around the 6-membered perimeter: diene $\pi \rightarrow$ new $\sigma$ bond, dienophile $\pi \rightarrow$ new $\sigma$ bond, residual diene $\pi \rightarrow$ new internal $\pi$ bond.',
          intermediate: r'$[\text{Diene}\cdots\text{Dienophile}]^\ddagger$ (Aromatic 6-Electron Transition State)',
        ),
      ],
    ),

    // 9. GRIGNARD REACTION
    ReactionMechanism(
      id: 'grignard',
      name: 'Grignard Reaction',
      aliases: ['Organomagnesium Addition', 'Grignard Carbonyl Addition'],
      category: ReactionCategory.organometallics,
      summary:
          r'Addition of an alkyl- or arylmagnesium halide ($\text{R-MgX}$) to an electrophilic carbonyl carbon (aldehyde, ketone, ester) followed by acidic hydrolysis to form an alcohol with a newly formed carbon-carbon bond.',
      reactants: r'Carbonyl compound ($\text{R\x27}_2\text{C=O}$) + Grignard Reagent ($\text{R-MgX}$)',
      reagentsAndConditions: r'Anhydrous ether or THF solvent under inert $\text{N}_2/\text{Ar}$ atmosphere, followed by $\text{H}_3\text{O}^+$ aqueous workup',
      products: r'Alcohol ($1^\circ$ from $\text{HCHO}$, $2^\circ$ from aldehydes, $3^\circ$ from ketones/esters)',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('grignard'),
      isVerified: true,
      keyApplications: [
        r'Fundamental carbon-carbon bond forming reaction in organic synthesis for complex alcohol preparation.',
        r'Synthesis of carboxylic acids via carboxylation of Grignard reagents with dry ice ($\text{CO}_2$).',
      ],
      limitations: [
        r'Incompatible with acidic protons ($\text{-OH, -NH}_2, \text{-COOH, -SH}$) in the substrate or solvent (acts as a strong base instead).',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Nucleophilic Carbonyl Addition',
          description:
              r'The polarized, nucleophilic carbon of the Grignard reagent ($\text{R}^{\delta-}$) attacks the electrophilic carbonyl carbon, forming a halomagnesium alkoxide.',
          curvedArrowNotes:
              r'Electron pair from C-Mg bond attacks carbonyl carbon; carbonyl $\pi$-electrons shift to oxygen to coordinate with $MgX^+$.',
          intermediate: r'$\text{R\x27}_2\text{C(R)-O}^-\text{MgX}^+$ (Halomagnesium Alkoxide Complex)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Acidic Hydrolysis Workup',
          description:
              r'Aqueous acid protonates the alkoxide oxygen, releasing the free alcohol and water-soluble magnesium salts.',
          curvedArrowNotes:
              r'Alkoxide oxygen lone pair captures proton from $\text{H}_3\text{O}^+$.',
          intermediate: r'$\text{R\x27}_2\text{C(R)-OH}$ (Alcohol Product) + $\text{MgX(OH)}$',
        ),
      ],
    ),

    // 10. BECKMANN REARRANGEMENT
    ReactionMechanism(
      id: 'beckmann',
      name: 'Beckmann Rearrangement',
      aliases: ['Ketoxime to Amide Rearrangement', 'Caprolactam Synthesis'],
      category: ReactionCategory.rearrangements,
      summary:
          r'Acid-catalyzed rearrangement of a ketoxime to an N-substituted amide. Migration of the group positioned anti (trans) to the oxime hydroxyl group occurs concertedly with water loss, followed by nucleophilic hydration of the resulting nitrilium ion.',
      reactants: r'Ketoxime ($\text{R(R\x27)C=N-OH}$)',
      reagentsAndConditions: r'Acid catalyst ($\text{H}_2\text{SO}_4, \text{PCl}_5, \text{SOCl}_2, \text{PPA}$), Heat',
      products: r'N-Substituted Amide ($\text{R-CO-NH-R\x27}$)',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('beckmann'),
      isVerified: true,
      keyApplications: [
        r'Industrial synthesis of $\varepsilon$-caprolactam from cyclohexanone oxime for Nylon-6 production.',
        r'Regioselective synthesis of secondary amides and lactams.',
      ],
      limitations: [
        r'Requires specific anti-periplanar geometry: the migrating alkyl/aryl group must be strictly anti to the departing -OH leaving group.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Oxime Activation & Anti-Migration (Concerted)',
          description:
              r'Protonation of the oxime hydroxyl group converts it into a good leaving group ($\text{-OH}_2^+$). The alkyl/aryl group anti to the leaving group migrates with its electron pair to nitrogen as water departs.',
          curvedArrowNotes:
              r'Curved arrow from anti C-C bond to nitrogen atom; curved arrow from N-O bond onto departing $\text{H}_2\text{O}$.',
          intermediate: r'$[\text{R-C}\equiv\text{N-R\x27}]^+$ (Nitrilium Ion Intermediate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Hydration & Tautomerization',
          description:
              r'Water attacks the electrophilic carbon of the nitrilium ion. Deprotonation yields an imidic acid, which rapidly tautomerizes to the stable amide.',
          curvedArrowNotes:
              r'Water oxygen attacks nitrilium carbon; imidic acid $O-H$ proton shifts to nitrogen.',
          intermediate: r'$\text{R-CO-NH-R\x27}$ (N-Substituted Amide)',
        ),
      ],
    ),

    // 11. BENZOIN CONDENSATION
    ReactionMechanism(
      id: 'benzoin',
      name: 'Benzoin Condensation',
      aliases: ['Cyanide Umpolung', 'Acyloin Condensation of Aromatic Aldehydes'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Cyanide-catalyzed condensation between two molecules of an aromatic aldehyde to form an $\alpha$-hydroxy ketone (benzoin). Cyanide reverses the normal polarity (umpolung) of the carbonyl carbon, converting it into a powerful nucleophile.',
      reactants: r'2 Aromatic aldehydes ($\text{Ar-CHO}$)',
      reagentsAndConditions: r'Catalytic $\text{NaCN}$ or $\text{KCN}$ (or Thiamine vitamin B1) in aqueous ethanol, Reflux',
      products: r'Benzoin ($\alpha$-hydroxy ketone, $\text{Ar-CH(OH)-CO-Ar}$)',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('benzoin'),
      isVerified: true,
      keyApplications: [
        r'Synthesis of benzoin, benzil, and heterocyclic imidazole compounds.',
        r'Classic demonstration of organocatalytic Umpolung (polarity reversal).',
      ],
      limitations: [
        r'Limited to aromatic aldehydes and specific heterocyclic aldehydes lacking acidic $\alpha$-hydrogens.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Cyanide Addition & Umpolung Carbanion Formation',
          description:
              r'Cyanide ion adds to the carbonyl carbon. Subsequent intramolecular proton transfer produces a resonance-stabilized carbanion with reversed polarity ($d^1$ synthon).',
          curvedArrowNotes:
              r'Cyanide $:CN^-$ attacks carbonyl carbon; proton shifts from C to O; conjugate base formed with $C^-$ stabilized by cyano group.',
          intermediate: r'$[\text{Ar-C}^-\text{(OH)(CN)}]$ (Umpolung Carbanion Intermediate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Nucleophilic Addition to Second Aldehyde',
          description:
              r'The carbanion attacks the carbonyl group of a second aldehyde molecule to form a carbon-carbon bond.',
          curvedArrowNotes:
              r'Carbanion lone pair attacks second aldehyde carbonyl carbon; second carbonyl opens to $O^-$.',
          intermediate: r'Alkoxide intermediate',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Cyanide Elimination & Benzoin Formation',
          description:
              r'Proton transfer followed by collapse of the alkoxide ejects the cyanide ion as a leaving group, regenerating the catalyst.',
          curvedArrowNotes:
              r'Alkoxide oxygen electron pair collapses to form $C=O$ double bond, expelling $:CN^-$ catalyst.',
          intermediate: r'$\text{Ar-CH(OH)-CO-Ar}$ (Benzoin)',
        ),
      ],
    ),
  ];

  /// Find mechanism by ID or keyword/alias.
  ReactionMechanism? find(String query) {
    final q = query.trim().toLowerCase();
    for (final m in curatedMechanisms) {
      if (m.id.toLowerCase() == q || m.name.toLowerCase().contains(q)) {
        return m;
      }
      for (final alias in m.aliases) {
        if (alias.toLowerCase().contains(q)) {
          return m;
        }
      }
    }
    return null;
  }

  /// Search mechanisms by category or keyword.
  List<ReactionMechanism> search(String query, {ReactionCategory? category}) {
    final q = query.trim().toLowerCase();
    return curatedMechanisms.where((m) {
      if (category != null && m.category != category) return false;
      if (q.isEmpty) return true;
      return m.name.toLowerCase().contains(q) ||
          m.summary.toLowerCase().contains(q) ||
          m.reactants.toLowerCase().contains(q) ||
          m.aliases.any((a) => a.toLowerCase().contains(q));
    }).toList();
  }
}
