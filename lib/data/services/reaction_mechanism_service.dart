import '../models/reaction_models.dart';

/// Service providing verified, step-by-step MSc chemistry reaction mechanisms,
/// electron movement, curved arrow descriptions, and intermediates.
class ReactionMechanismService {
  ReactionMechanismService._();
  static final ReactionMechanismService instance = ReactionMechanismService._();

  List<ReactionMechanism> get mechanisms => curatedMechanisms;

  static final List<ReactionMechanism> curatedMechanisms = [
    // 1. CANNIZZARO REACTION
    const ReactionMechanism(
      id: 'cannizzaro',
      name: 'Cannizzaro Reaction',
      aliases: ['Disproportionation of Aldehydes', 'Crossed Cannizzaro'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Base-induced disproportionation (redox) of non-enolizable aldehydes (lacking $\alpha$-hydrogens) to yield an equimolar mixture of a primary alcohol and a carboxylic acid salt.',
      reactants: r'2 R-CHO (where R = aryl, $3^\circ$ alkyl, or H, lacking $\alpha$-H)',
      reagentsAndConditions: r'Concentrated strong base ($50\%\text{ NaOH}$ or $\text{KOH}$), Heat ($60\text{–}100^\circ\text{C}$)',
      products: r'$\text{R-CH}_2\text{OH}$ (Primary Alcohol) + $\text{R-COO}^-\text{Na}^+$ (Carboxylate Salt)',
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
              r'The alkoxide collapses its negative charge back to reform a carbonyl ($C=O$), expelling a hydride ion ($:H^-$) directly to the carbonyl carbon of a second aldehyde molecule.',
          curvedArrowNotes:
              r'Electron pair on $O^-$ reforms $C=O$; $C-H$ bond pair attacks the carbonyl carbon of the second aldehyde; $\pi(C=O)$ electrons shift to second carbonyl oxygen.',
          intermediate: r'$\text{R-COOH}$ (Carboxylic Acid) + $\text{R-CH}_2\text{O}^-$ (Alkoxide Ion)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Rapid Proton Transfer & Irreversible Equilibrium',
          description:
              r'The newly formed strongly basic alkoxide ion ($\text{R-CH}_2\text{O}^-$) deprotonates the carboxylic acid ($\text{R-COOH}$), irreversibly driving the reaction to completion via resonance stabilization of the carboxylate anion.',
          curvedArrowNotes:
              r'Alkoxide oxygen attacks acidic proton on $R-COOH$; $O-H$ bond pair shifts entirely to carboxylate oxygen forming resonance-stabilized $R-COO^-$.',
          intermediate: r'$\text{R-CH}_2\text{OH}$ + $\text{R-COO}^-$ (Resonance Delocalized Carboxylate)',
        ),
      ],
    ),

    // 2. ALDOL CONDENSATION
    const ReactionMechanism(
      id: 'aldol',
      name: 'Aldol Condensation',
      aliases: [r'Claisen-Schmidt Condensation', r'$\beta$-Hydroxy Carbonyl Synthesis'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Carbon-carbon bond-forming reaction between enolizable aldehydes or ketones to form a $\beta$-hydroxy carbonyl (aldol addition), which subsequently dehydrates to an $\alpha,\beta$-unsaturated enone/enal.',
      reactants: r'2 Carbonyl compounds possessing acidic $\alpha$-hydrogens ($\text{R-CH}_2\text{CHO}$ or $\text{R-COCH}_3$)',
      reagentsAndConditions: r'Dilute base ($\text{NaOH}, \text{KOH}$) or dilute acid ($\text{HCl}, \text{H}_2\text{SO}_4$), followed by heat ($\Delta$)',
      products: r'$\alpha,\beta$-Unsaturated Carbonyl ($\text{R-CH}=\text{CH-CHO}$ or enone) + $\text{H}_2\text{O}$',
      isVerified: true,
      keyApplications: [
        r'Synthesis of chalcones, cinnamaldehyde derivatives, and conjugated enones in steroid synthesis.',
        r'Robinson Annulation tandem sequence for polycyclic ring synthesis.',
      ],
      limitations: [
        r'Cross-aldol between two different enolizable aldehydes gives a complex mixture of 4 products unless one component lacks $\alpha$-H or preformed lithium enolate (LDA) is used.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Enolate Generation via $\alpha$-Deprotonation',
          description:
              r'Base removes an acidic $\alpha$-proton ($pK_a \approx 19\text{–}20$) from the carbonyl compound to generate a resonance-stabilized carbanion / enolate intermediate.',
          curvedArrowNotes:
              r'Base lone pair attacks $\alpha-H$; $C-H$ bond pair shifts to form $C=C$ while $C=O$ double bond shifts to oxygen.',
          intermediate: r'$[\text{R-CH}=\text{C(H)-O}^- \leftrightarrow \text{R-CH}^--\text{CHO}]$ (Enolate nucleophile)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Nucleophilic Carbonyl Addition (C-C Bond Formation)',
          description:
              r'The nucleophilic enolate carbon attacks the electrophilic carbonyl carbon of an unionized aldehyde molecule, forming a new C-C $\sigma$-bond and an alkoxide.',
          curvedArrowNotes:
              r'Enolate $O^-$ reforms $C=O$; $\pi(C=C)$ attacks second carbonyl carbon; carbonyl $\pi$-electrons shift to oxygen.',
          intermediate: r'$[\text{R-CH(O}^-)\text{-CH(R)-CHO}]$ (Aldolate intermediate)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Protonation & Base-Catalyzed E1cB Dehydration',
          description:
              r'Protonation by solvent produces the neutral $\beta$-hydroxy aldehyde. Under warming, base abstracts the remaining $\alpha$-H via an $\text{E1cB}$ mechanism to eliminate hydroxide and yield the thermodynamically conjugated enal/enone.',
          curvedArrowNotes:
              r'Base removes remaining $\alpha-H$; enolate reforms and expels $OH^-$ leaving group to generate conjugated $\pi$-system.',
          intermediate: r'$\text{R-CH}=\text{C(R)-CHO}$ ($\alpha,\beta$-Unsaturated conjugated enone)',
        ),
      ],
    ),

    // 3. WITTIG REACTION
    const ReactionMechanism(
      id: 'wittig',
      name: 'Wittig Reaction',
      aliases: ['Phosphonium Ylide Olefination'],
      category: ReactionCategory.organometallics,
      summary:
          r'Reaction of an aldehyde or ketone with a triphenylphosphonium ylide ($\text{Ph}_3\text{P}=\text{CR}_2$) to yield an alkene with complete regiochemical control of the double bond.',
      reactants: r'Aldehyde or Ketone ($\text{R}_2\text{C}=\text{O}$) + Phosphonium Ylide ($\text{Ph}_3\text{P}=\text{CR}^\prime_2$)',
      reagentsAndConditions: r'$\text{Ph}_3\text{P}$, Alkyl Halide, Strong base ($n\text{-BuLi}$, $\text{NaH}$, or $\text{KO}t\text{Bu}$), anhydrous THF, $0^\circ\text{C}$ to RT',
      products: r'Alkene ($\text{R}_2\text{C}=\text{CR}^\prime_2$) + Triphenylphosphine Oxide ($\text{Ph}_3\text{P}=\text{O}$)',
      isVerified: true,
      keyApplications: [
        r'Synthesis of natural products, polyenes, and non-migrated terminal/internal olefins without positional isomers.',
        r'Z-selective olefination with unstabilized ylides; E-selective olefination with stabilized ylides or Horner-Wadsworth-Emmons.',
      ],
      limitations: [
        r'Sterically hindered ketones react sluggishly; phosphine oxide byproduct removal can require chromatography.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Ylide Generation & Nucleophilic Addition',
          description:
              r'Deprotonation of phosphonium salt by strong base yields the nucleophilic ylide ($\text{Ph}_3\text{P}^+-\text{C}^-\text{R}_2$). The carbanion attacks the electrophilic carbonyl carbon to generate a betaine intermediate.',
          curvedArrowNotes:
              r'Ylide $C^-$ attacks carbonyl carbon; carbonyl $\pi$-electrons shift to oxygen forming $O^-$.',
          intermediate: r'$[\text{Ph}_3\text{P}^+-\text{CR}_2-\text{CR}^\prime_2-\text{O}^-]$ (Betaine zwitterion)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Cyclization to Oxaphosphetane Four-Membered Ring',
          description:
              r'The negatively charged oxygen attacks the positively charged phosphorus atom ($\text{P}^+$), collapsing into a 4-membered oxaphosphetane heterocycle.',
          curvedArrowNotes:
              r'Alkoxide oxygen lone pair coordinates directly with phosphorus d-orbitals.',
          intermediate: r'4-Membered Oxaphosphetane ring containing P-O and P-C bonds',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Retro-Cycloaddition & Alkene Formation',
          description:
              r'The oxaphosphetane spontaneously collapses via a concerted $[2+2]$ cycloreversion driven by the exceptionally high bond dissociation energy of the $\text{P}=\text{O}$ bond ($\sim 535\text{ kJ/mol}$).',
          curvedArrowNotes:
              r'$P-C$ bond cleaves to form $C=C$ alkene double bond; $C-O$ bond cleaves to form $P=O$ double bond.',
          intermediate: r'Alkene ($\text{R}_2\text{C}=\text{CR}^\prime_2$) + $\text{Ph}_3\text{P}=\text{O}$',
        ),
      ],
    ),

    // 4. DIELS-ALDER [4+2] CYCLOADDITION
    const ReactionMechanism(
      id: 'diels_alder',
      name: 'Diels-Alder [4+2] Cycloaddition',
      aliases: ['Pericyclic Cycloaddition', 'Concerted Six-Membered Ring Synthesis'],
      category: ReactionCategory.pericyclic,
      summary:
          r'Thermally allowed $[4\pi_s + 2\pi_s]$ concerted pericyclic cycloaddition between a conjugated diene (in s-cis conformation) and a dienophile (alkene/alkyne) to yield a substituted cyclohexene ring with stereospecific preservation of geometry.',
      reactants: r'Conjugated Diene (s-cis) + Dienophile (electron-deficient alkene with EWG)',
      reagentsAndConditions: r'Thermal conditions ($50\text{–}150^\circ\text{C}$) or Lewis Acid catalysis ($\text{AlCl}_3, \text{TiCl}_4, \text{Sc(OTf)}_3$)',
      products: r'Substituted Cyclohexene Derivative (Endo-adduct favored kinetically)',
      isVerified: true,
      keyApplications: [
        r'Total synthesis of complex terpenes, alkaloids, steroids (cortisone, reserpine), and bicyclic norbornene frameworks.',
      ],
      limitations: [
        r'Dienes locked in an s-trans conformation (e.g. 1,3-cyclohexadiene derivatives with fixed trans geometry) cannot react.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Conformational Alignment (s-cis Diene)',
          description:
              r'The conjugated diene adopts the requisite planar s-cis conformation to allow simultaneous overlap of orbital lobes at C1 and C4 with the dienophile.',
          curvedArrowNotes:
              r'FMO alignment: $\text{HOMO}_{\text{diene}} \rightarrow \text{LUMO}_{\text{dienophile}}$.',
          intermediate: r'Suprafacial molecular complex in parallel plane alignment',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Concerted Six-Electron Transition State',
          description:
              r'A single, concerted transition state forms via a cyclic flow of 6 $\pi$-electrons ($4\pi + 2\pi$), converting two weak $\pi$-bonds into two strong $\sigma$-bonds with aromatic transition state stabilization ($4n+2, n=1$).',
          curvedArrowNotes:
              r'Three simultaneous curved arrows forming 6-membered cyclic electron movement with secondary orbital interaction producing Endo selectivity.',
          intermediate: r'Aromatic 6-membered boat-like transition state $[\ddagger]$',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Cyclohexene Ring Closure (Stereospecific Product)',
          description:
              r'Two new $C-C$ $\sigma$-bonds and one new $C=C$ $\pi$-bond form with $100\%$ retention of dienophile stereochemistry (cis-dienophile gives cis-ring; trans gives trans-ring).',
          curvedArrowNotes:
              r'Fully bonded cyclohexene framework without ionic or radical intermediates.',
          intermediate: r'Endo-substituted Cyclohexene Adduct',
        ),
      ],
    ),

    // 5. BECKMANN REARRANGEMENT
    const ReactionMechanism(
      id: 'beckmann',
      name: 'Beckmann Rearrangement',
      aliases: ['Oxime to Amide Rearrangement'],
      category: ReactionCategory.rearrangements,
      summary:
          r'Acid-catalyzed rearrangement of ketoximes ($\text{R}_2\text{C}=\text{N-OH}$) into substituted secondary amides via anti-periplanar 1,2-migration of the group trans to the hydroxyl group.',
      reactants: r'Ketoxime ($\text{R}_2\text{C}=\text{N-OH}$, derived from ketone + hydroxylamine)',
      reagentsAndConditions: r'Protic/Lewis acids: $\text{H}_2\text{SO}_4$, $\text{PCl}_5$, $\text{SOCl}_2$, $\text{PPA}$ (polyphosphoric acid), or $\text{TsCl}$',
      products: r'N-Substituted Amide or Lactam ($\text{R-CO-NH-R}^\prime$)',
      isVerified: true,
      keyApplications: [
        r'Industrial synthesis of $\epsilon$-caprolactam (precursor to Nylon-6) from cyclohexanone oxime.',
      ],
      limitations: [
        r'Aldoximes may dehydrate to nitriles ($\text{R-C}\equiv\text{N}$) rather than rearrange.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Protonation / Activation of the Oxime Hydroxyl Group',
          description:
              r'Acid converts the poor leaving group ($-OH$) on the oxime nitrogen into a good leaving group ($-\text{OH}_2^+$ or $-\text{OTs}$).',
          curvedArrowNotes:
              r'Nitrogen-bound hydroxyl lone pair attacks $H^+$ from acid.',
          intermediate: r'$[\text{R}_2\text{C}=\text{N-OH}_2^+]$ (Activated oxonium intermediate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Anti-Periplanar 1,2-Migration & Nitrilium Ion Formation',
          description:
              r'The alkyl or aryl group positioned strictly **anti** to the departing water molecule migrates to nitrogen with retention of configuration, simultaneously expelling water.',
          curvedArrowNotes:
              r'Bond pair of anti-alkyl group attacks nitrogen while $N-O$ bond pair leaves with water.',
          intermediate: r'$[\text{R-C}\equiv\text{N}^+-\text{R}^\prime]$ (Linear Nitrilium Cation)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Hydration of Nitrilium Ion & Tautomerization',
          description:
              r'Water attacks the electrophilic carbon of the nitrilium cation to form an imidic acid, which rapidly tautomerizes into the stable secondary amide or cyclic lactam.',
          curvedArrowNotes:
              r'$H_2O$ attacks carbocation carbon $\rightarrow$ imidic acid $[\text{R-C(OH)}=\text{NR}^\prime] \rightarrow$ amide $[\text{R-CO-NHR}^\prime]$.',
          intermediate: r'N-Substituted Amide ($\text{R-CO-NHR}^\prime$)',
        ),
      ],
    ),

    // 6. BENZOIN CONDENSATION
    const ReactionMechanism(
      id: 'benzoin',
      name: 'Benzoin Condensation',
      aliases: ['Cyanide / Thiamine Catalyzed Umpolung'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Cyanide or N-heterocyclic carbene (NHC / Vitamin B1) catalyzed coupling of two aromatic aldehydes to yield an $\alpha$-hydroxy ketone (benzoin) via polarity reversal (umpolung).',
      reactants: r'2 Aromatic Aldehydes (e.g. 2 $\text{C}_6\text{H}_5\text{CHO}$)',
      reagentsAndConditions: r'Catalytic $\text{NaCN}$ or $\text{KCN}$ in aqueous ethanol ($\text{EtOH/H}_2\text{O}$), or Thiamine hydrochloride / base, reflux',
      products: r'$\alpha$-Hydroxy Ketone (Benzoin: $\text{C}_6\text{H}_5\text{-CH(OH)-CO-C}_6\text{H}_5$)',
      isVerified: true,
      keyApplications: [
        r'Synthesis of benzil ($\text{Ph-CO-CO-Ph}$) via oxidation, and heterocyclic imidazole/oxazole precursors.',
      ],
      limitations: [
        r'Aliphatic aldehydes undergo Aldol condensation or polymerize instead of benzoin coupling.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Cyanide Addition & Cyanohydrin Anion Generation',
          description:
              r'Cyanide ion acts as a specific nucleophile, attacking the carbonyl carbon of benzaldehyde to form a cyanohydrin intermediate.',
          curvedArrowNotes:
              r'$:C\equiv N^-$ attacks carbonyl carbon; carbonyl $\pi$-electrons shift to oxygen.',
          intermediate: r'$[\text{Ph-CH(O}^-)\text{CN}]$ (Tetrahedral adduct)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Proton Transfer & Polarity Inversion (Umpolung)',
          description:
              r'Intramolecular proton shift converts the former electrophilic carbonyl carbon into a resonance-stabilized carbanion nucleophile, stabilized by both the phenyl ring and cyano group.',
          curvedArrowNotes:
              r'$\alpha-H$ is abstracted; negative charge delocalizes into cyano group $[\text{Ph-C}^-(\text{OH})\text{CN} \leftrightarrow \text{Ph-C(OH)}=\text{C}=\text{N}^-]$.',
          intermediate: r'$[\text{Ph-C}^-(\text{OH})\text{CN}]$ (Umpolung carbanion nucleophile)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Addition to Second Aldehyde & Cyanide Expulsion',
          description:
              r'The carbanion attacks the carbonyl carbon of a second benzaldehyde molecule. A rapid proton transfer occurs, followed by elimination of the cyanide catalyst to yield benzoin.',
          curvedArrowNotes:
              r'Alkoxide oxygen collapses to reform $C=O$ while $CN^-$ leaves as a regenerated catalytic species.',
          intermediate: r'$\text{Ph-CH(OH)-CO-Ph}$ (Benzoin) + $\text{CN}^-$ (Catalyst regenerated)',
        ),
      ],
    ),

    // 7. GRIGNARD ADDITION TO CARBONYLS
    const ReactionMechanism(
      id: 'grignard',
      name: 'Grignard Reaction',
      aliases: ['Organomagnesium Carbonyl Addition'],
      category: ReactionCategory.organometallics,
      summary:
          r'Addition of an organomagnesium halide ($\text{R-MgX}$) to aldehydes, ketones, or esters to synthesize primary, secondary, or tertiary alcohols with C-C bond formation.',
      reactants: r'Carbonyl ($\text{HCHO}$, $\text{R-CHO}$, or $\text{R}_2\text{C}=\text{O}$) + Grignard Reagent ($\text{R}^\prime\text{MgX}$)',
      reagentsAndConditions: r'Anhydrous ether or THF solvent ($\text{Et}_2\text{O}$), moisture-free ($N_2$ atmosphere), followed by acidic workup ($\text{H}_3\text{O}^+$)',
      products: r'Alcohol ($1^\circ, 2^\circ, \text{ or } 3^\circ$) + $\text{Mg(OH)X}$',
      isVerified: true,
      keyApplications: [
        r'Versatile C-C bond construction in complex pharmaceutical targets and natural products.',
      ],
      limitations: [
        r'Incompatible with acidic protons ($-OH, -NH_2, -COOH, -C\equiv CH$) which quench the reagent to alkane.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Coordination & Nucleophilic Attack',
          description:
              r'The magnesium atom coordinates to carbonyl oxygen, activating the carbonyl. The polarized carbon ($\text{R}^{\delta-}-\text{Mg}^{\delta+}$) attacks the electrophilic carbonyl carbon via a cyclic 6-membered or bimolecular transition state.',
          curvedArrowNotes:
              r'$C-Mg$ bond pair attacks carbonyl carbon; carbonyl $\pi$-electrons coordinate to magnesium forming magnesium alkoxide salt.',
          intermediate: r'$[\text{R}_2\text{C(R}^\prime)\text{-O}^-\text{MgX}^+]$ (Magnesium Alkoxide Complex)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Acidic Hydrolysis Workup',
          description:
              r'Dilute aqueous acid ($\text{H}_3\text{O}^+$ / $\text{NH}_4\text{Cl}$) protonates the alkoxide oxygen, releasing the target alcohol and water-soluble magnesium salts.',
          curvedArrowNotes:
              r'Alkoxide oxygen attacks $H_3O^+$ proton; $MgX^+$ coordinates with counterion.',
          intermediate: r'$\text{R}_2\text{C(R}^\prime)\text{OH}$ (Substituted Alcohol)',
        ),
      ],
    ),

    // 8. SN1 vs SN2 SUBSTITUTION
    const ReactionMechanism(
      id: 'sn1_sn2',
      name: 'Nucleophilic Substitution (SN1 & SN2)',
      aliases: ['Unimolecular vs Bimolecular Substitution'],
      category: ReactionCategory.namedReactions,
      summary:
          r'Fundamental aliphatic substitution: $\text{S}_\text{N}1$ proceeds via a two-step carbocation pathway with racemization, whereas $\text{S}_\text{N}2$ proceeds via a one-step concerted backside attack with complete Walden inversion.',
      reactants: r'Alkyl Halide ($\text{R-X}$) + Nucleophile ($\text{Nu}^-$)',
      reagentsAndConditions: r'$\text{S}_\text{N}1$: Polar protic solvent ($\text{H}_2\text{O}, \text{EtOH}$); $\text{S}_\text{N}2$: Polar aprotic solvent ($\text{DMSO, DMF, Acetone}$)',
      products: r'Substituted Product ($\text{R-Nu}$) + Halide Leaving Group ($\text{X}^-$)',
      isVerified: true,
      keyApplications: [
        r'Interconversion of functional groups (halides $\rightarrow$ alcohols, ethers, nitriles, amines, azides).',
      ],
      limitations: [
        r'Aryl and vinyl halides do not undergo $\text{S}_\text{N}1$ or $\text{S}_\text{N}2$ due to $sp^2$ $C-X$ bond strength and steric repulsion.',
      ],
      steps: [
        ReactionStep(
          stepNumber: 1,
          title: 'SN1 Step 1: Heterolysis & Planar Carbocation RDS',
          description:
              r'The leaving group departs spontaneously to generate a planar, $sp^2$-hybridized carbocation ($3^\circ > 2^\circ \gg 1^\circ$). This is the slow rate-determining step ($\text{Rate} = k[\text{RX}]$).',
          curvedArrowNotes:
              r'$C-X$ bond electrons leave with $X^-$; carbocation assumes $120^\circ$ trigonal planar geometry.',
          intermediate: r'$[\text{R}_3\text{C}^+]$ (Planar Carbocation Intermediate)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'SN1 Step 2: Front / Back Nucleophilic Attack',
          description:
              r'Nucleophile attacks the vacant $p$-orbital of the carbocation with equal probability from either face, yielding a racemic mixture ($\text{Inversion} + \text{Retention}$).',
          curvedArrowNotes:
              r'Nucleophile lone pair attacks $p$-orbital from top or bottom face.',
          intermediate: r'$\text{R}_3\text{C-Nu}$ (Racemized Product)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'SN2 Concerted Pathway: Backside Attack & Walden Inversion',
          description:
              r'Strong nucleophile attacks the $\sigma^*(\text{C-X})$ antibonding orbital at $180^\circ$ to the leaving group, passing through a pentacoordinate trigonal bipyramidal transition state with 100% Walden inversion.',
          curvedArrowNotes:
              r'Concerted attack from back while $X^-$ departs from front $[\text{Nu}\cdots\text{C}\cdots\text{X}]^{\ddagger}$.',
          intermediate: r'$\text{R-Nu}$ (Inverted Configuration Product)',
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
