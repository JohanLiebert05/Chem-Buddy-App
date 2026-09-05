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
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('sn2'),
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

    // 12. MICHAEL ADDITION
    ReactionMechanism(
      id: 'michael',
      name: 'Michael Addition',
      aliases: ['Conjugate 1,4-Addition', 'Michael Reaction', 'Enolate Conjugate Addition'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Thermodynamically controlled 1,4-conjugate addition of a resonance-stabilized carbon nucleophile (Michael donor, such as malonate or $\beta$-keto ester) to an $\alpha,\beta$-unsaturated carbonyl compound (Michael acceptor) yielding a 1,5-dicarbonyl compound.',
      reactants: r'Michael Donor (Active methylene compound) + Michael Acceptor ($\alpha,\beta$-unsaturated enone/ester)',
      reagentsAndConditions: r'Catalytic base ($\text{EtONa, KOH, or piperidine}$), $25\text{–}60^\circ\text{C}$',
      products: r'1,5-Dicarbonyl derivative (Michael adduct)',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('michael'),
      isVerified: true,
      keyApplications: [
        r'Initial step in the Robinson annulation for steroid and polycyclic terpenoid synthesis.',
        r'Carbon-carbon bond formation for synthesizing 1,5-difunctionalized intermediates.',
      ],
      limitations: [
        r'Hard organolithium or Grignard reagents favor competing 1,2-direct addition over 1,4-conjugate addition (use organocuprates $\text{R}_2\text{CuLi}$ for 1,4).',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Donor Deprotonation & Enolate Formation',
          description:
              r'Base removes an acidic proton between two electron-withdrawing groups to generate a soft, resonance-stabilized enolate carbanion.',
          curvedArrowNotes:
              r'Base $:B^-$ abstracts central proton; C-H electrons delocalize across both carbonyl oxygens.',
          intermediate: r'$[(\text{EtO}_2\text{C})_2\text{CH}^-]$ (Resonance-stabilized carbanion)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Conjugate 1,4-Nucleophilic Attack (C-C Bond Formation)',
          description:
              r'The soft enolate attacks the softer electrophilic $\beta$-carbon of the $\alpha,\beta$-unsaturated system. The $\pi$-electrons shift to form an extended enolate oxyanion.',
          curvedArrowNotes:
              r'Enolate carbanion attacks $\beta$-carbon; $C=C$ $\pi$-pair shifts to $\alpha$-carbon; $C=O$ $\pi$-pair opens onto oxygen.',
          intermediate: r'$[(\text{EtO}_2\text{C})_2\text{CH-CH}_2\text{-CH=C(O}^-)\text{Me}]$ (Extended Enolate)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Proton Transfer & Tautomerization',
          description:
              r'Protonation of the enolate at the $\alpha$-carbon produces the neutral, stable 1,5-dicarbonyl Michael adduct and regenerates the base catalyst.',
          curvedArrowNotes:
              r'Carbonyl $O^-$ collapses or $\alpha$-carbon attacks proton donor $BH^+$; yields neutral keto tautomer.',
          intermediate: r'$(\text{EtO}_2\text{C})_2\text{CH-CH}_2\text{-CH}_2\text{-CO-Me}$ (1,5-Dicarbonyl Adduct)',
        ),
      ],
    ),

    // 13. CLAISEN CONDENSATION
    ReactionMechanism(
      id: 'claisen',
      name: 'Claisen Ester Condensation',
      aliases: ['Claisen Reaction', 'Ester Self-Condensation', 'Dieckmann Cyclization (intramolecular)'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Base-catalyzed condensation between two esters (or an ester and a ketone) containing $\alpha$-hydrogens, proceeding via nucleophilic acyl substitution to form a $\beta$-keto ester. Irreversible final deprotonation of the acidic methylene ($pK_a \approx 11$) drives the equilibrium to completion.',
      reactants: r'2 Esters possessing $\alpha$-hydrogens (e.g. Ethyl acetate)',
      reagentsAndConditions: r'Sodium ethoxide ($\text{NaOEt}$) matching ester alkoxy group in absolute ethanol, followed by aqueous acid workup ($\text{H}_3\text{O}^+$)',
      products: r'$\beta$-Keto ester (Ethyl acetoacetate) + Ethanol',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('claisen'),
      isVerified: true,
      keyApplications: [
        r'Synthesis of ethyl acetoacetate for acetoacetic ester syntheses of ketones.',
        r'Dieckmann cyclization: intramolecular Claisen condensation to form 5- and 6-membered cyclic $\beta$-keto esters.',
      ],
      limitations: [
        r'Substrates must possess at least two $\alpha$-hydrogens: one for enolization and the second for final deprotonation to drive equilibrium.',
        r'Base must match the ester alkoxy group to avoid transesterification side-products.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Ester Enolization',
          description:
              r'Ethoxide base abstracts an $\alpha$-hydrogen from ethyl acetate to generate a resonance-stabilized ester enolate.',
          curvedArrowNotes:
              r'Ethoxide $:OEt^-$ abstracts $\alpha$-H; C-H bonding electrons delocalize into ester carbonyl.',
          intermediate: r'$[\text{CH}_2=\text{C(OEt)O}^- \leftrightarrow ^-\text{CH}_2\text{COOEt}]$ (Ester Enolate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Nucleophilic Acyl Addition & Alkoxide Elimination',
          description:
              r'The ester enolate attacks the carbonyl carbon of a second ethyl acetate molecule forming a tetrahedral intermediate, which expels ethoxide ion to give ethyl acetoacetate.',
          curvedArrowNotes:
              r'Enolate $C^-$ attacks second ester carbonyl; $C=O$ opens to $O^-$; tetrahedral collapse kicks off $:OEt^-$.',
          intermediate: r'$[\text{CH}_3\text{-C(O}^-)(\text{OEt})-\text{CH}_2\text{COOEt}]$ (Tetrahedral Intermediate)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Irreversible Acid-Base Deprotonation (Thermodynamic Driving Force)',
          description:
              r'The newly formed $\beta$-keto ester contains a very acidic methylene ($pK_a \approx 11$). Ethoxide deprotonates it irreversibly, forming a stable resonance-delocalized anion until acidified during workup.',
          curvedArrowNotes:
              r'Ethoxide abstracts doubly activated methylene proton; acidification with dilute $\text{HCl}$ protonates to give pure neutral $\beta$-keto ester.',
          intermediate: r'$\text{CH}_3\text{-CO-CH}_2\text{-COOEt}$ (Ethyl acetoacetate)',
        ),
      ],
    ),

    // 14. BAEYER-VILLIGER OXIDATION
    ReactionMechanism(
      id: 'baeyer_villiger',
      name: 'Baeyer-Villiger Oxidation',
      aliases: ['Ketone to Ester Oxidation', 'Lactone Formation', 'Peracid Carbonyl Insertion'],
      category: ReactionCategory.oxidationReduction,
      summary:
          r'Oxidation of ketones to esters (or cyclic ketones to lactones) using peroxy acids. The reaction proceeds via nucleophilic addition of the peroxy acid to form a tetrahedral Criegee intermediate, followed by concerted 1,2-migration with retention of configuration onto the peroxy oxygen with simultaneous cleavage of the weak O-O bond.',
      reactants: r'Ketone ($\text{R-CO-R\x27}$) or Cyclic Ketone + Peroxy acid ($\text{mCPBA}, \text{CF}_3\text{COOOH}, \text{RCOOOH}$)',
      reagentsAndConditions: r'$\text{mCPBA}$ in $\text{CH}_2\text{Cl}_2$ or Trifluoroacetic acid / $\text{H}_2\text{O}_2$, RT to $40^\circ\text{C}$',
      products: r'Ester ($\text{R-COO-R\x27}$) or Lactone + Carboxylic acid ($\text{ArCOOH}$)',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('baeyer_villiger'),
      isVerified: true,
      keyApplications: [
        r'Synthesis of $\varepsilon$-caprolactone from cyclohexanone (monomer for biodegradable polycaprolactone polymers).',
        r'Stereospecific conversion of ketones to esters with 100% retention of stereochemistry at migrating chiral centers.',
      ],
      limitations: [
        r'Aldehydes typically yield carboxylic acids via hydrogen migration rather than esters.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Peroxy Acid Nucleophilic Addition',
          description:
              r'Peracid oxygen attacks the carbonyl carbon of the ketone to establish the tetrahedral Criegee intermediate.',
          curvedArrowNotes:
              r'Peracid peroxy oxygen lone pair attacks carbonyl carbon; carbonyl $\pi$-electrons shift to oxygen.',
          intermediate: r'$[\text{R(R\x27)C(OH)-O-O-COAr}]$ (Tetrahedral Criegee Intermediate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Concerted 1,2-Alkyl Migration & O-O Cleavage (Rate-Determining Step)',
          description:
              r'Collapse of the alkoxide drives 1,2-migration of the group with higher migratory aptitude ($3^\circ > 2^\circ \approx \text{aryl} > 1^\circ > \text{methyl}$) to oxygen, concertedly expelling the carboxylate leaving group with complete stereochemical retention.',
          curvedArrowNotes:
              r'C-C bonding pair shifts to adjacent peroxy oxygen; O-O bond breaks onto carboxylate oxygen; $O-H$ proton departs.',
          intermediate: r'$\text{R-CO-O-R\x27}$ (Ester) + $\text{Ar-COO}^-$ (Carboxylate)',
        ),
      ],
    ),

    // 15. FAVORSKII REARRANGEMENT
    ReactionMechanism(
      id: 'favorskii',
      name: 'Favorskii Rearrangement',
      aliases: ['Cyclopropanone Intermediate Rearrangement', 'Skeletal Ring Contraction'],
      category: ReactionCategory.rearrangements,
      summary:
          r'Base-catalyzed rearrangement of $\alpha$-halo ketones containing an $\alpha\x27$-hydrogen to carboxylic acid derivatives. Deprotonation at $\alpha\x27$ followed by intramolecular displacement of the halide yields a strained cyclopropanone intermediate, which undergoes ring opening to relieve angle strain.',
      reactants: r'$\alpha$-Halocyclohexanone or $\alpha$-halo acyclic ketone with accessible $\alpha\x27$-hydrogen',
      reagentsAndConditions: r'Strong base ($\text{NaOMe, NaOEt, or NaOH}$) in alcoholic solvent, Heat',
      products: r'Ring-contracted ester (e.g. Methyl cyclopentanecarboxylate) or rearranged carboxylic acid',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('favorskii'),
      isVerified: true,
      keyApplications: [
        r'Efficient ring contraction of 6-membered to 5-membered cyclic carboxylic esters.',
        r'Synthesis of cubane, steroids, and highly strained cage compounds.',
      ],
      limitations: [
        r'Substrates lacking $\alpha\x27$-hydrogens proceed through the alternative "Quasi-Favorskii" semipinacolic pathway without cyclopropanones.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Enolate Generation & Intramolecular Halide Displacement',
          description:
              r'Base deprotonates the $\alpha\x27$-carbon opposite the halogen. The resulting carbanion performs an intramolecular $S_N2$ displacement of the halide, forming a strained 3-membered cyclopropanone intermediate.',
          curvedArrowNotes:
              r'Base abstracts $\alpha\x27$-H; carbanion lone pair attacks $\alpha$-carbon; C-X bond departs as halide $X^-$.',
          intermediate: r'Bicyclo[3.1.0]hexan-2-one (Cyclopropanone Intermediate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Alkoxide Addition & Strain-Relief Ring Cleavage',
          description:
              r'Methoxide nucleophile attacks the carbonyl carbon of the cyclopropanone. The tetrahedral intermediate collapses with regioselective cleavage of the C-C bond to yield the more stable carbanion, driving ring contraction.',
          curvedArrowNotes:
              r'Methoxide $:OMe^-$ attacks cyclopropanone $C=O$; $O^-$ collapses to re-form $C=O$, opening 3-membered ring to relieve 105 kJ/mol strain.',
          intermediate: r'Methyl cyclopentanecarboxylate (Ring-Contracted Product)',
        ),
      ],
    ),

    // 16. MANNICH REACTION
    ReactionMechanism(
      id: 'mannich',
      name: 'Mannich Reaction',
      aliases: ['Three-Component Condensation', 'Mannich Base Synthesis', 'Aminoalkylation'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Three-component condensation involving an enolizable ketone (or aldehyde), a non-enolizable aldehyde (formaldehyde), and a primary or secondary amine to form a $\beta$-amino carbonyl compound (Mannich base). The key intermediate is a resonance-stabilized iminium ion.',
      reactants: r'Formaldehyde ($\text{HCHO}$) + Secondary Amine ($\text{Me}_2\text{NH}\cdot\text{HCl}$) + Enolizable Ketone ($\text{Ph-CO-CH}_3$)',
      reagentsAndConditions: r'Catalytic $\text{HCl}$ in ethanol or water, Reflux ($70\text{–}90^\circ\text{C}$)',
      products: r'$\beta$-Amino carbonyl compound (Mannich Base: $\text{Ph-CO-CH}_2\text{-CH}_2\text{-NMe}_2$)',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('mannich'),
      isVerified: true,
      keyApplications: [
        r'Total synthesis of tropinone, atropine, and cocaine (Robinson classic synthesis).',
        r'Preparation of $\alpha,\beta$-unsaturated ketones via thermal elimination of the amine hydrochloride.',
      ],
      limitations: [
        r'Tertiary amines cannot participate; primary amines can undergo double Mannich condensations.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Iminium Ion Intermediate Generation',
          description:
              r'Secondary amine attacks formaldehyde under acid catalysis. Dehydration produces an exceptionally electrophilic iminium ion.',
          curvedArrowNotes:
              r'Amine nitrogen lone pair attacks protonated formaldehyde; loss of $\text{H}_2\text{O}$ yields $[\text{CH}_2=\text{N}^+\text{Me}_2]$.',
          intermediate: r'$[\text{CH}_2=\text{N}^+\text{Me}_2 \leftrightarrow ^+\text{CH}_2\text{-NMe}_2]$ (Iminium Ion)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Ketone Enolization & Nucleophilic Addition',
          description:
              r'Acid catalyzes enolization of the ketone. The nucleophilic enol $\pi$-bond attacks the electrophilic iminium carbon, forming a C-C bond.',
          curvedArrowNotes:
              r'Ketone enol $C=C$ attacks iminium carbon; iminium $\pi$-electrons return to nitrogen.',
          intermediate: r'$[\text{Ph-C(OH)=CH}_2 + \text{CH}_2=\text{N}^+\text{Me}_2]$',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Deprotonation to Neutral Mannich Base',
          description:
              r'Loss of the enol proton re-establishes the carbonyl group, yielding the stable $\beta$-amino ketone.',
          curvedArrowNotes:
              r'Water abstracts enol $O-H$ proton; electrons re-form $C=O$ double bond.',
          intermediate: r'$\text{Ph-CO-CH}_2\text{-CH}_2\text{-NMe}_2$ (Mannich Base)',
        ),
      ],
    ),

    // 17. PINACOL-PINACOLONE REARRANGEMENT
    ReactionMechanism(
      id: 'pinacol',
      name: 'Pinacol-Pinacolone Rearrangement',
      aliases: ['1,2-Diol Rearrangement', 'Vicinal Diol Dehydration', 'Oxocarbenium Shift'],
      category: ReactionCategory.rearrangements,
      summary:
          r'Acid-catalyzed dehydration of a 1,2-diol (pinacol) accompanied by 1,2-migration of an alkyl or aryl group to form a ketone (pinacolone). Driven by the formation of a resonance-stabilized oxocarbenium ion.',
      reactants: r'1,2-Diol (Pinacol: 2,3-dimethylbutane-2,3-diol)',
      reagentsAndConditions: r'Concentrated sulfuric acid ($\text{H}_2\text{SO}_4$) or phosphoric acid ($\text{H}_3\text{PO}_4$), Heat ($100^\circ\text{C}$)',
      products: r'Ketone with rearranged skeleton (Pinacolone: 3,3-dimethylbutan-2-one) + $\text{H}_2\text{O}$',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('pinacol'),
      isVerified: true,
      keyApplications: [
        r'Synthesis of hindered ketones and quaternary carbon centers.',
        r'Semipinacol rearrangements in terpene and natural product synthesis.',
      ],
      limitations: [
        r'Unsymmetrical diols can yield isomeric mixtures depending on carbocation stability and migratory aptitude (Aryl > Alkyl > H).',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Hydroxyl Protonation & Water Elimination',
          description:
              r'Acid protonates one of the tertiary hydroxyl groups. Departure of water produces a stable tertiary carbocation.',
          curvedArrowNotes:
              r'Acid protonates -OH to form $-\text{OH}_2^+$; C-O bond breaks onto departing $\text{H}_2\text{O}$.',
          intermediate: r'$[(\text{CH}_3)_2\text{C(OH)-C}^+(\text{CH}_3)_2]$ (Tertiary Carbocation)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: '1,2-Alkyl Migration Driven by Oxygen Lone Pair Push',
          description:
              r'An adjacent methyl group migrates with its bonding pair to the cationic carbon, assisted synchronously by the push of the hydroxyl oxygen lone pair to form an oxocarbenium ion.',
          curvedArrowNotes:
              r'Adjacent methyl C-C pair shifts to $C^+$; oxygen lone pair forms $C=O^+$ double bond.',
          intermediate: r'$[(\text{CH}_3)_3\text{C-C}^+(\text{OH})\text{CH}_3]$ (Protonated Oxocarbenium Ion)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Deprotonation to Pinacolone',
          description:
              r'Loss of the proton from the oxocarbenium ion gives the neutral ketone with high thermodynamic stability.',
          curvedArrowNotes:
              r'Base abstracts proton from $C=O^+-H$, releasing neutral pinacolone.',
          intermediate: r'$(\text{CH}_3)_3\text{C-CO-CH}_3$ (Pinacolone)',
        ),
      ],
    ),

    // 18. ROBINSON ANNULATION
    ReactionMechanism(
      id: 'robinson',
      name: 'Robinson Annulation',
      aliases: ['Tandem Michael-Aldol Annulation', 'Ring Construction', 'Octalone Synthesis'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Tandem reaction sequence combining a Michael addition of a cyclic ketone enolate to an $\alpha,\beta$-unsaturated ketone (methyl vinyl ketone) followed by an intramolecular Aldol condensation and dehydration to construct a fused 6-membered cyclohexenone ring.',
      reactants: r'Cyclic ketone (Cyclohexanone) + Methyl vinyl ketone (MVK)',
      reagentsAndConditions: r'Base ($\text{KOH, NaOMe}$, or pyrrolidine/acetic acid), Heat',
      products: r'Bicyclic $\alpha,\beta$-unsaturated enone ($\Delta^{1,9}$-2-Octalone) + $\text{H}_2\text{O}$',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('robinson'),
      isVerified: true,
      keyApplications: [
        r'Foundational method in steroid total synthesis (e.g. synthesis of the Wieland-Miescher ketone).',
        r'Formation of decalin and polycyclic terpene skeletons.',
      ],
      limitations: [
        r'Polymerization of methyl vinyl ketone can occur under harsh basic conditions; often generated in situ from Mannich salts.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Michael Addition (1,5-Diketone Formation)',
          description:
              r'Base generates the enolate of cyclohexanone, which undergoes conjugate 1,4-addition to methyl vinyl ketone yielding a 1,5-diketone.',
          curvedArrowNotes:
              r'Cyclohexanone enolate attacks terminal $\beta$-carbon of MVK; extended enolate protonates to give neutral 1,5-diketone.',
          intermediate: r'2-(3-Oxobutyl)cyclohexan-1-one (1,5-Diketone Intermediate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Intramolecular Aldol Cyclization',
          description:
              r'Base selectively removes a proton from the methyl group of the side chain. The resulting enolate attacks the ring carbonyl carbon, creating a fused 6-membered ring.',
          curvedArrowNotes:
              r'Base deprotonates methyl group; carbanion attacks cyclohexanone carbonyl to form bicyclic $\beta$-hydroxy ketone.',
          intermediate: r'Bicyclic $\beta$-hydroxy ketone adduct',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'E1cB Dehydration (Aromatization / Conjugation Driving Force)',
          description:
              r'Base-catalyzed elimination of water via an E1cB mechanism generates the conjugated enone framework.',
          curvedArrowNotes:
              r'Base removes $\alpha$-proton forming enolate; collapse expels $OH^-$ to produce $\Delta^{1,9}$-2-octalone.',
          intermediate: r'$\Delta^{1,9}$-2-Octalone (Fused Enone Product)',
        ),
      ],
    ),

    // 19. CURTIUS REARRANGEMENT
    ReactionMechanism(
      id: 'curtius',
      name: 'Curtius Rearrangement',
      aliases: ['Acyl Azide Rearrangement', 'Isocyanate Synthesis', 'Decarboxylative Amine Synthesis'],
      category: ReactionCategory.rearrangements,
      summary:
          r'Thermal or photochemical decomposition of an acyl azide to an isocyanate via concerted loss of nitrogen gas ($N_2$) and 1,2-migration of the alkyl/aryl group with complete retention of configuration. Subsequent nucleophilic trapping with water or alcohol yields primary amines or carbamates.',
      reactants: r'Acyl azide ($\text{R-CON}_3$)',
      reagentsAndConditions: r'Thermal activation ($\Delta$, $60\text{–}100^\circ\text{C}$ in toluene/benzene) or UV photolysis; followed by aqueous or alcoholic workup',
      products: r'Isocyanate ($\text{R-N=C=O}$) $\rightarrow$ Primary Amine ($\text{R-NH}_2$) + $\text{CO}_2$',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('curtius'),
      isVerified: true,
      keyApplications: [
        r'Synthesis of sterically hindered primary amines and chiral amines without loss of enantiomeric purity.',
        r'Preparation of protected urethanes/carbamates and ureas from carboxylic acid derivatives.',
      ],
      limitations: [
        r'Acyl azides are potentially explosive and must be prepared safely (e.g. using diphenylphosphoryl azide DPPA).',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Concerted N₂ Extrusion & 1,2-Migration (Rate-Determining Step)',
          description:
              r'Upon heating, the acyl azide undergoes simultaneous loss of dinitrogen ($N_2$) and 1,2-shift of the migrating group with its electrons from carbonyl carbon to nitrogen, preserving configuration.',
          curvedArrowNotes:
              r'R-C bonding electrons shift to nitrogen; terminal $N-N_2$ bond breaks to release $:N\equiv N:$; $C=O$ electrons form $N=C=O$ double bond.',
          intermediate: r'$\text{R-N=C=O}$ (Isocyanate Intermediate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Aqueous Hydrolysis & Decarboxylation',
          description:
              r'Water adds to the electrophilic carbon of the isocyanate forming an unstable carbamic acid, which spontaneously decarboxylates to yield the pure primary amine.',
          curvedArrowNotes:
              r'Water oxygen attacks isocyanate carbon; proton transfer gives carbamic acid $\text{R-NH-COOH}$; spontaneous decarboxylation releases $\text{CO}_2$ and $\text{R-NH}_2$.',
          intermediate: r'$\text{R-NH}_2$ (Primary Amine) + $\text{CO}_2$',
        ),
      ],
    ),

    // 20. [3,3]-COPE REARRANGEMENT
    ReactionMechanism(
      id: 'cope',
      name: '[3,3]-Cope Rearrangement',
      aliases: ['Cope Rearrangement', '1,5-Diene Isomerization', 'Oxy-Cope Variant'],
      category: ReactionCategory.pericyclic,
      summary:
          r'Thermally allowed, concerted suprafacial-suprafacial $[3\sigma + 3\pi]$ sigmatropic rearrangement of 1,5-hexadienes. The reaction proceeds through a 6-electron aromatic chair-like transition state, breaking the C3-C4 $\sigma$-bond while synchronously forming a new C1-C6 $\sigma$-bond with complete chirality transfer.',
      reactants: r'1,5-Hexadiene derivative',
      reagentsAndConditions: r'Thermal activation ($\Delta$, $150\text{–}250^\circ\text{C}$) or Oxy-Cope with $\text{KH / 18-crown-6}$ at RT',
      products: r'Isomeric 1,5-Hexadiene derivative',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('cope'),
      isVerified: true,
      keyApplications: [
        r'Chirality transfer in complex organic synthesis and terpene ring modifications.',
        r'Anionic Oxy-Cope acceleration by $10^{10}\text{–}10^{17}$ rate enhancement over neutral substrates.',
      ],
      limitations: [
        r'High temperatures required for simple unsubstituted neutral dienes unless driving force (e.g. ring strain relief or enolization) is present.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Concerted Chair-Like Transition State Overlap',
          description:
              r'The 1,5-hexadiene adopts a preferred chair conformation. The 6-electron cyclic transition state features simultaneous homolytic/concerted cleavage of the central C3-C4 bond and formation of the terminal C1-C6 bond.',
          curvedArrowNotes:
              r'Three electron pairs move synchronously around the 6-membered cycle: C3-C4 $\sigma \rightarrow$ C2-C3 $\pi$, C1-C2 $\pi \rightarrow$ C1-C6 $\sigma$, C5-C6 $\pi \rightarrow$ C4-C5 $\pi$.',
          intermediate: r'$[1,5\text{-Hexadiene}]^\ddagger$ (Chair-Like 6-Electron Aromatic TS)',
        ),
      ],
    ),

    // 21. [3,3]-CLAISEN SIGMATROPIC REARRANGEMENT
    ReactionMechanism(
      id: 'claisen_sigmatropic',
      name: '[3,3]-Claisen Sigmatropic Rearrangement',
      aliases: ['Claisen Rearrangement', 'Allyl Vinyl Ether Rearrangement', 'Allyl Phenyl Ether Shift'],
      category: ReactionCategory.pericyclic,
      summary:
          r'Thermally allowed, concerted $[3,3]$-sigmatropic rearrangement of allyl vinyl ethers (or allyl aryl ethers) passing through a 6-membered chair-like transition state. In allyl aryl ethers, the initial cyclohexadienone rapidly tautomerizes to restore aromatic resonance, yielding ortho-allylphenols.',
      reactants: r'Allyl phenyl ether or Allyl vinyl ether',
      reagentsAndConditions: r'Thermal activation ($\Delta$, $180\text{–}210^\circ\text{C}$) without catalyst, or Lewis acid ($\text{AlCl}_3, \text{BCl}_3$) at RT',
      products: r'ortho-Allylphenol (or $\gamma,\delta$-unsaturated aldehyde/ketone)',
      svgContent: ReactionDiagramSvgCatalog.getSvgFor('claisen_sigmatropic'),
      isVerified: true,
      keyApplications: [
        r'Stereoselective synthesis of ortho-substituted phenols and substituted allylic frameworks.',
        r'Ireland-Claisen, Johnson-Claisen, and Eschenmoser variants in total synthesis.',
      ],
      limitations: [
        r'If both ortho positions on the aromatic ring are blocked, a second [3,3]-shift occurs to yield the para-allylphenol.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Concerted [3,3]-Sigmatropic Shift via Chair Transition State',
          description:
              r'Thermal excitation drives simultaneous cleavage of the C-O single bond and formation of a new C-C single bond at the ortho ring position via a chair-like transition state.',
          curvedArrowNotes:
              r'Allylic C-O $\sigma$-bond shifts to form $C=O$ double bond; aromatic $\pi$-pair shifts to form new ortho C-C $\sigma$-bond; vinyl $\pi$-pair shifts to terminal position.',
          intermediate: r'6-Allylcyclohexa-2,4-dien-1-one (Cyclohexadienone Intermediate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Rapid Keto-Enol Aromatization',
          description:
              r'The non-aromatic dienone intermediate spontaneously undergoes keto-enol tautomerization, driven by the substantial thermodynamic gain of aromatic stabilization energy ($\sim 150\text{ kJ/mol}$).',
          curvedArrowNotes:
              r'Deprotonation of ortho ring proton; electron pair restores benzene aromatic sextet; oxygen captures proton to reform phenolic -OH.',
          intermediate: r'ortho-Allylphenol (Aromatic Product)',
        ),
      ],
    ),
  ];

  /// Find mechanism by ID or keyword/alias.
  ReactionMechanism? find(String query) {
    final q = query.trim().toLowerCase();
    // 1. Exact ID match takes highest precedence
    for (final m in curatedMechanisms) {
      if (m.id.toLowerCase() == q) return m;
    }
    // 2. Exact name or exact alias match
    for (final m in curatedMechanisms) {
      if (m.name.toLowerCase() == q) return m;
      for (final alias in m.aliases) {
        if (alias.toLowerCase() == q) return m;
      }
    }
    // 3. Name contains query
    for (final m in curatedMechanisms) {
      if (m.name.toLowerCase().contains(q)) return m;
    }
    // 4. Alias contains query
    for (final m in curatedMechanisms) {
      for (final alias in m.aliases) {
        if (alias.toLowerCase().contains(q)) return m;
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
