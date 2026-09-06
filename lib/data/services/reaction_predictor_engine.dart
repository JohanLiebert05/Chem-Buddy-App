import '../models/reaction_models.dart';

/// Result of an intelligent chemical reaction mechanism & end-product prediction.
class PredictedReactionResult {
  final String reactionName;
  final String category;
  final String reactants;
  final String reagentsAndConditions;
  final String majorProduct;
  final String majorProductFormula;
  final String? minorProducts;
  final String selectivity;
  final List<ReactionStep> mechanismSteps;
  final String drivingForce;
  final String syntheticNotes;
  final String? svgId;

  const PredictedReactionResult({
    required this.reactionName,
    required this.category,
    required this.reactants,
    required this.reagentsAndConditions,
    required this.majorProduct,
    required this.majorProductFormula,
    this.minorProducts,
    required this.selectivity,
    required this.mechanismSteps,
    required this.drivingForce,
    required this.syntheticNotes,
    this.svgId,
  });

  /// Formats the prediction into an authoritative, structured MSc Chemistry response.
  String toAcademicMarkdown() {
    final buffer = StringBuffer();

    buffer.writeln('### **⚗️ Reaction Analysis & End-Product Prediction**');
    buffer.writeln('**Reaction**: $reactionName  ');
    buffer.writeln('**Classification**: $category');
    buffer.writeln();

    // 1. REACTION EQUATION BOX
    buffer.writeln('#### **1. Overall Chemical Reaction & Balanced Equation**');
    buffer.writeln(r'$$\mathbf{' + _formatLatexEquation(reactants, reagentsAndConditions, majorProductFormula) + r'}$$');
    buffer.writeln('* **Substrate / Reactants**: $reactants');
    buffer.writeln('* **Reagents & Conditions**: $reagentsAndConditions');
    buffer.writeln();

    // 2. END-PRODUCT PREDICTION (MAJOR & MINOR)
    buffer.writeln('#### **2. Predicted End-Products & Selectivity**');
    buffer.writeln('* 🏆 **Major Product**: **$majorProduct** (`$majorProductFormula`)');
    if (minorProducts != null && minorProducts!.isNotEmpty) {
      buffer.writeln('* ⚖️ **Minor Product(s) / Byproducts**: $minorProducts');
    }
    buffer.writeln('* 🔍 **Regio- & Stereochemical Outcome**: $selectivity');
    buffer.writeln('* ⚡ **Thermodynamic / Kinetic Driving Force**: $drivingForce');
    buffer.writeln();

    // 3. STEP-BY-STEP REACTION MECHANISM WITH CURVED ARROWS
    buffer.writeln('#### **3. Step-by-Step Reaction Mechanism**');
    for (final step in mechanismSteps) {
      buffer.writeln('##### **Step ${step.stepNumber}: ${step.title}**');
      buffer.writeln(step.description);
      if (step.curvedArrowNotes != null && step.curvedArrowNotes!.isNotEmpty) {
        buffer.writeln('* 🏹 **Electron Movement (Curved Arrows)**: ${step.curvedArrowNotes}');
      }
      if (step.intermediate != null && step.intermediate!.isNotEmpty) {
        buffer.writeln('* 🧪 **Key Intermediate / Transition State**: ${step.intermediate}');
      }
      buffer.writeln();
    }

    // 4. SYNTHETIC SCOPE & EXAM KEY POINTS
    buffer.writeln('#### **4. Synthetic Utility, Limitations & Exam Tips**');
    buffer.writeln(syntheticNotes);
    buffer.writeln();
    buffer.writeln('---');
    buffer.writeln('*Predicted by ChemBuddy Autonomous MSc Chemistry Intelligence Engine.*');

    return buffer.toString();
  }

  static String _formatLatexEquation(String reactants, String reagents, String products) {
    final cleanR = reactants.replaceAll(r'$', '').trim();
    final cleanCond = reagents.replaceAll(r'$', '').trim();
    final cleanP = products.replaceAll(r'$', '').trim();
    return '$cleanR \\xrightarrow{\\text{$cleanCond}} $cleanP';
  }
}

/// Autonomous Chemistry Intelligence Engine that classifies reactions,
/// predicts major/minor end-products, determines stereochemistry, and generates
/// complete step-by-step electron-pushing mechanisms.
class ReactionPredictorEngine {
  ReactionPredictorEngine._();

  /// Attempts to identify and predict the reaction from any chemistry prompt.
  static PredictedReactionResult? predict(String query) {
    final q = query.trim().toLowerCase();

    // Check query against comprehensive reaction patterns
    for (final handler in _reactionPatterns) {
      if (handler.matches(q)) {
        return handler.generate(q);
      }
    }

    // Check for general chemical reaction keywords + reactants
    if (_isGeneralReactionQuery(q)) {
      return _generateDynamicPrediction(q, query);
    }

    return null;
  }

  static bool _isGeneralReactionQuery(String q) {
    final hasReactants = q.contains('+') || q.contains(' react') || q.contains(' treated with ') || q.contains(' with ') || q.contains(' in presence of ');
    final hasAction = q.contains('mechanism') || q.contains('product') || q.contains('predict') || q.contains('yield') || q.contains('reaction of') || q.contains('what happens when');
    return hasReactants && hasAction;
  }

  static final List<_ReactionPatternHandler> _reactionPatterns = [
    // 1. EAS
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('benzene') || q.contains('toluene') || q.contains('phenol') || q.contains('anisole')) &&
          (q.contains('hno3') || q.contains('nitrat') || (q.contains('nitric') && q.contains('sulfuric'))),
      generator: (q) => _buildNitrationPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('benzene') || q.contains('arene')) &&
          (q.contains('h2so4') || q.contains('so3') || q.contains('sulfonat') || q.contains('sulphonat')),
      generator: (q) => _buildSulphonationPrediction(),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('benzene') || q.contains('toluene')) &&
          (q.contains('br2') || q.contains('cl2') || q.contains('halogenat')) &&
          (q.contains('febr3') || q.contains('alcl3') || q.contains('fe') || q.contains('lewis acid')),
      generator: (q) => _buildHalogenationPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('benzene') || q.contains('toluene')) &&
          (q.contains('friedel') || q.contains('alcl3') || q.contains('alkylat')) &&
          (q.contains('ch3cl') || q.contains('ch3ch2cl') || q.contains('alkyl halide') || q.contains('propyl') || q.contains('chloropropane')),
      generator: (q) => _buildFriedelCraftsAlkylationPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('benzene') || q.contains('toluene') || q.contains('anisole')) &&
          (q.contains('friedel') || q.contains('acydat') || q.contains('acylat') || q.contains('ch3cocl') || q.contains('acetyl chloride') || q.contains('acetic anhydride')),
      generator: (q) => _buildFriedelCraftsAcylationPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => q.contains('phenol') && (q.contains('chcl3') || q.contains('chloroform') || q.contains('reimer') || q.contains('tiemann')),
      generator: (q) => _buildReimerTiemannPrediction(),
    ),
    _ReactionPatternHandler(
      matcher: (q) => q.contains('phenol') && (q.contains('co2') || q.contains('kolbe') || q.contains('salicylic')),
      generator: (q) => _buildKolbeSchmittPrediction(),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('toluene') || q.contains('methylbenzene')) && (q.contains('cro2cl2') || q.contains('etard') || q.contains('chromyl chloride')),
      generator: (q) => _buildEtardPrediction(),
    ),

    // 2. ALKENE ADDITIONS
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('propene') || q.contains('prop-1-ene') || q.contains('alkene') || q.contains('isobutylene')) &&
          q.contains('hbr') &&
          (q.contains('peroxide') || q.contains('roor') || q.contains('anti-markovnikov') || q.contains('kharasch')),
      generator: (q) => _buildAntiMarkovnikovHBrPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('propene') || q.contains('alkene') || q.contains('isobutylene') || q.contains('2-methylpropene') || q.contains('1-butene')) &&
          (q.contains('hbr') || q.contains('hcl') || q.contains('hi') || q.contains('markovnikov')),
      generator: (q) => _buildMarkovnikovAdditionPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('alkene') || q.contains('propene') || q.contains('cyclohexene') || q.contains('methylcyclohexene')) &&
          (q.contains('bh3') || q.contains('hydroboration') || (q.contains('b2h6') && q.contains('h2o2'))),
      generator: (q) => _buildHydroborationOxidationPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('alkene') || q.contains('butene') || q.contains('propene') || q.contains('ozonolysis') || q.contains('o3')),
      generator: (q) => _buildOzonolysisPrediction(q),
    ),

    // 3. CARBONYL CONDENSATIONS & REARRANGEMENTS
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('aldol') || (q.contains('acetaldehyde') && (q.contains('naoh') || q.contains('koh') || q.contains('base')))) ||
          (q.contains('acetone') && q.contains('benzaldehyde') && (q.contains('naoh') || q.contains('base'))),
      generator: (q) => _buildAldolCondensationPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('cannizzaro') || (q.contains('benzaldehyde') && (q.contains('50%') || q.contains('conc')) && (q.contains('koh') || q.contains('naoh')))) ||
          (q.contains('formaldehyde') && (q.contains('conc') || q.contains('50%')) && q.contains('base')),
      generator: (q) => _buildCannizzaroPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('wittig') || q.contains('ph3p') || q.contains('ylide') || q.contains('phosphonium')),
      generator: (q) => _buildWittigPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('benzoin') || (q.contains('benzaldehyde') && (q.contains('kcn') || q.contains('nacn')))),
      generator: (q) => _buildBenzoinPrediction(),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('perkin') || (q.contains('benzaldehyde') && q.contains('acetic anhydride') && q.contains('sodium acetate'))),
      generator: (q) => _buildPerkinPrediction(),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('beckmann') || (q.contains('oxime') && (q.contains('h2so4') || q.contains('pcl5') || q.contains('acid')))),
      generator: (q) => _buildBeckmannPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('hofmann') || q.contains('bromamide') || (q.contains('amide') && q.contains('br2') && q.contains('koh'))),
      generator: (q) => _buildHofmannBromamidePrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('pinacol') || (q.contains('diol') && q.contains('h2so4') && q.contains('pinacolone'))),
      generator: (q) => _buildPinacolPinacolonePrediction(),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('diels') && q.contains('alder')) ||
          (q.contains('diene') && q.contains('dienophile')) ||
          (q.contains('butadiene') && q.contains('maleic')) ||
          ((q.contains('cyclopentadiene') || q.contains('diene')) && (q.contains('maleic') || q.contains('dienophile') || q.contains('anhydride'))),
      generator: (q) => _buildDielsAlderPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('clemmensen') || (q.contains('ketone') && q.contains('zn-hg') && q.contains('hcl')) || (q.contains('acetophenone') && q.contains('zn-hg'))),
      generator: (q) => _buildClemmensenPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('wolff') && q.contains('kishner')) || (q.contains('nh2nh2') && q.contains('koh') && q.contains('glycol')),
      generator: (q) => _buildWolffKishnerPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('grignard') || q.contains('mgbr') || q.contains('mgcl') || q.contains('organomagnesium')),
      generator: (q) => _buildGrignardPrediction(q),
    ),
    _ReactionPatternHandler(
      matcher: (q) => (q.contains('2-bromobutane') || q.contains('alkyl halide') || q.contains('elimination')) &&
          (q.contains('koh') || q.contains('t-buok') || q.contains('zaitsev') || q.contains('saytzeff') || q.contains('hofmann elimination')),
      generator: (q) => _buildZaitsevVsHofmannEliminationPrediction(q),
    ),
  ];

  static PredictedReactionResult _buildNitrationPrediction(String q) {
    final isToluene = q.contains('toluene');

    if (isToluene) {
      return const PredictedReactionResult(
        reactionName: 'Electrophilic Aromatic Nitration of Toluene',
        category: 'Electrophilic Aromatic Substitution (EAS)',
        reactants: r'Toluene ($\text{C}_6\text{H}_5\text{CH}_3$) + Nitric Acid ($\text{HNO}_3$)',
        reagentsAndConditions: r'Concentrated $\text{H}_2\text{SO}_4$, $30^\circ\text{C} - 40^\circ\text{C}$',
        majorProduct: r'ortho-Nitrotoluene & para-Nitrotoluene mixture (para major at $40^\circ\text{C}$ due to steric factors)',
        majorProductFormula: r'\text{CH}_3\text{C}_6\text{H}_4\text{NO}_2',
        minorProducts: r'meta-Nitrotoluene ($\approx 4\%$), $\text{H}_2\text{O}$ byproduct',
        selectivity: r'Ortho/Para-directing; Methyl group ($+\text{I}$ inductive & hyperconjugation) activates the benzene ring and stabilizes the arenium ion specifically at ortho and para positions.',
        mechanismSteps: [
          ReactionStep(
            stepNumber: 1,
            title: r'Generation of Powerful Nitronium Ion Electrophile ($\text{NO}_2^+$)',
            description: r'Protonation of nitric acid by stronger sulfuric acid generates an oxonium intermediate that loses water to yield the linear, sp-hybridized nitronium ion $\text{NO}_2^+$.',
            curvedArrowNotes: r'Curved arrow from $\text{H}_2\text{SO}_4$ proton to $\text{HNO}_3$ OH group; subsequent cleavage of $\text{H}_2\text{O}^+-\text{NO}_2$ bond yields $\text{NO}_2^+$.',
            intermediate: r'$\text{HNO}_3 + 2\text{H}_2\text{SO}_4 \rightleftharpoons \text{NO}_2^+ + \text{H}_3\text{O}^+ + 2\text{HSO}_4^-$',
          ),
          ReactionStep(
            stepNumber: 2,
            title: r'Electrophilic Attack on Toluene (Rate-Determining Step)',
            description: r'The aromatic $\pi$-electron cloud of toluene attacks $\text{NO}_2^+$ to form a resonance-stabilized arenium ion (Wheland / $\sigma$-complex). Ortho and para attacks produce an exceptionally stable $3^\circ$ carbocation contributor directly adjacent to the methyl group.',
            curvedArrowNotes: r'$\pi$-electrons of the aromatic ring attack the electrophilic nitrogen of $\text{NO}_2^+$, pushing an electron pair onto oxygen.',
            intermediate: r'Resonance-stabilized $\sigma$-complex (Wheland Intermediate)',
          ),
          ReactionStep(
            stepNumber: 3,
            title: r'Deprotonation & Rearomatization (Fast)',
            description: r'The bisulfate base $\text{HSO}_4^-$ deprotonates the $sp^3$ ring carbon, restoring the 6 $\pi$-electron aromatic sextet ($4n+2$ Hückel aromaticity).',
            curvedArrowNotes: r'Base abstracts $H^+$; C-H bonding pair collapses into the ring to restore aromatic sextet.',
            intermediate: r'o/p-Nitrotoluene + $\text{H}_2\text{SO}_4$ catalyst regenerated',
          ),
        ],
        drivingForce: r'Enormous resonance stabilization energy of restoring the aromatic benzene ring ($\Delta H^\circ_{\text{resonance}} \approx -152\text{ kJ/mol}$).',
        syntheticNotes: r'Further nitration at higher temperature ($100^\circ\text{C}$) with fuming $\text{HNO}_3/\text{H}_2\text{SO}_4$ yields 2,4,6-trinitrotoluene (TNT).',
        svgId: 'nitration',
      );
    }

    return const PredictedReactionResult(
      reactionName: 'Electrophilic Aromatic Nitration of Benzene',
      category: 'Electrophilic Aromatic Substitution (EAS)',
      reactants: r'Benzene ($\text{C}_6\text{H}_6$) + Nitric Acid ($\text{HNO}_3$)',
      reagentsAndConditions: r'Concentrated $\text{H}_2\text{SO}_4$, $50^\circ\text{C} - 55^\circ\text{C}$',
      majorProduct: 'Nitrobenzene',
      majorProductFormula: r'\text{C}_6\text{H}_5\text{NO}_2',
      minorProducts: r'Water ($\text{H}_2\text{O}$), trace 1,3-dinitrobenzene if temperature exceeds $60^\circ\text{C}$',
      selectivity: r'Monosubstitution is strictly maintained below $55^\circ\text{C}$. The introduced $-\text{NO}_2$ group is strongly deactivating ($-\text{M}, -\text{I}$), naturally shielding the product from over-nitration.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Electrophile Activation: Formation of Nitronium Ion ($\text{NO}_2^+$)',
          description: r'Sulfuric acid acts as a Brønsted acid and protonates nitric acid. Subsequent elimination of $\text{H}_2\text{O}$ generates the strong electrophile $\text{NO}_2^+$.',
          curvedArrowNotes: r'Lone pair on $\text{HNO}_3$ oxygen attacks $\text{H}^+$ of $\text{H}_2\text{SO}_4$; $\text{H}_2\text{O}$ leaves.',
          intermediate: r'$\text{NO}_2^+$ (Linear Electrophile, Bond Angle $180^\circ$)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Nucleophilic $\pi$-Attack on $\text{NO}_2^+$ (Slow, Rate-Determining Step)',
          description: r'Benzene ring $\pi$-system attacks the nitronium ion, breaking aromaticity to form the non-aromatic cyclohexadienyl cation ($\sigma$-complex / Wheland intermediate) stabilized over 5 carbons.',
          curvedArrowNotes: r'Ring $\pi$-bond attacks nitrogen; one $\text{N=O}$ bond opens onto oxygen.',
          intermediate: r'$[\text{C}_6\text{H}_6\text{NO}_2]^+$ Arenium Ion ($\sigma$-Complex)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Deprotonation by $\text{HSO}_4^-$ to Restore Aromaticity (Fast)',
          description: r'$\text{HSO}_4^-$ abstracts the proton from the $sp^3$ ring carbon, collapsing the C-H bond electrons back into the ring to regenerate the aromatic sextet.',
          curvedArrowNotes: r'$\text{HSO}_4^-$ lone pair takes proton; C-H bonding pair re-establishes aromatic ring.',
          intermediate: r'Nitrobenzene + $\text{H}_2\text{SO}_4$ (Catalyst regenerated)',
        ),
      ],
      drivingForce: r'Restoration of the aromatic resonance sextet ($\approx 36\text{ kcal/mol}$ aromatic stabilization energy).',
      syntheticNotes: r'Essential precursor for aniline ($\text{C}_6\text{H}_5\text{NH}_2$) via reduction ($\text{Fe/HCl}$ or $\text{Sn/HCl}$ or catalytic $\text{H}_2/\text{Pd}$).',
      svgId: 'nitration',
    );
  }

  static PredictedReactionResult _buildSulphonationPrediction() {
    return const PredictedReactionResult(
      reactionName: 'Electrophilic Aromatic Sulphonation of Benzene',
      category: 'Electrophilic Aromatic Substitution (Reversible EAS)',
      reactants: r'Benzene ($\text{C}_6\text{H}_6$) + Fuming Sulfuric Acid ($\text{H}_2\text{SO}_4 / \text{SO}_3$)',
      reagentsAndConditions: r'Oleum (Fuming $\text{H}_2\text{SO}_4$ saturated with $\text{SO}_3$), $40^\circ\text{C} - 80^\circ\text{C}$',
      majorProduct: 'Benzenesulfonic Acid',
      majorProductFormula: r'\text{C}_6\text{H}_5\text{SO}_3\text{H}',
      minorProducts: r'$\text{H}_2\text{O}$',
      selectivity: r'Reversible EAS reaction. The introduced $-\text{SO}_3\text{H}$ group is meta-directing and strongly deactivating.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Electrophilic Attack by Neutral Sulfur Trioxide ($\text{SO}_3$)',
          description: r'Neutral sulfur trioxide ($\text{SO}_3$) acts as an extremely strong electrophile due to three highly electronegative oxygen atoms withdrawing electron density from the central sulfur atom.',
          curvedArrowNotes: r'Aromatic $\pi$-electrons attack sulfur atom; $\text{S=O}$ double bond breaks toward oxygen.',
          intermediate: r'Zwitterionic $\sigma$-Complex $[\text{C}_6\text{H}_6\text{SO}_3^-]^+$',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Proton Loss & Rearomatization',
          description: r'Base abstracts the ring proton to re-aromatize the system into benzenesulfonate anion.',
          curvedArrowNotes: r'Base takes ring $H^+$; electrons restore aromatic delocalization.',
          intermediate: r'$\text{C}_6\text{H}_5\text{SO}_3^-$ Benzenesulfonate ion',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Protonation of Sulfonate Oxygen',
          description: r'The sulfonate oxygen is protonated by acid to yield the final neutral benzenesulfonic acid product.',
          curvedArrowNotes: r'Negative oxygen abstracts $H^+$ from $\text{H}_3\text{O}^+$.',
          intermediate: r'Benzenesulfonic acid ($\text{C}_6\text{H}_5\text{SO}_3\text{H}$)',
        ),
      ],
      drivingForce: r'Aromatic stabilization. Uniquely reversible: heating with superheated dilute steam ($150^\circ\text{C}$) removes the sulfonic acid group (used as a synthetic protecting/blocking group).',
      syntheticNotes: r'Crucial protecting group in organic synthesis to block para positions and direct subsequent additions to ortho sites before desulfonation.',
    );
  }

  static PredictedReactionResult _buildHalogenationPrediction(String q) {
    final isBromination = q.contains('br2') || q.contains('brom');
    final halSym = isBromination ? 'Br' : 'Cl';

    return PredictedReactionResult(
      reactionName: isBromination ? 'Electrophilic Aromatic Bromination of Benzene' : 'Electrophilic Aromatic Chlorination of Benzene',
      category: 'Electrophilic Aromatic Substitution (EAS)',
      reactants: isBromination ? r'Benzene ($\text{C}_6\text{H}_6$) + Bromine ($\text{Br}_2$)' : r'Benzene ($\text{C}_6\text{H}_6$) + Chlorine ($\text{Cl}_2$)',
      reagentsAndConditions: isBromination ? r'Lewis Acid Catalyst ($\text{FeBr}_3$), Room Temperature' : r'Lewis Acid Catalyst ($\text{AlCl}_3$), Room Temperature',
      majorProduct: isBromination ? 'Bromobenzene' : 'Chlorobenzene',
      majorProductFormula: '\\text{C}_6\\text{H}_5\\text{$halSym}',
      minorProducts: isBromination ? r'Hydrogen Bromide ($\text{HBr}$)' : r'Hydrogen Chloride ($\text{HCl}$)',
      selectivity: r'Monosubstitution is cleanly achieved. Halogen atoms are unique: they are deactivating due to $-\text{I}$ inductive electron withdrawal, but ortho/para directing due to $+\text{M}$ lone pair resonance donation.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: 'Lewis Acid Complexation & Electrophile Polarization',
          description: isBromination
              ? r'The bromine molecule coordinates with $\text{FeBr}_3$ to form the polarized complex $[\text{Br}^{\delta+}\cdots\text{Br-FeBr}_3^{\delta-}]$, generating an electrophilic bromine center.'
              : r'The chlorine molecule coordinates with $\text{AlCl}_3$ to form the polarized complex $[\text{Cl}^{\delta+}\cdots\text{Cl-AlCl}_3^{\delta-}]$, generating an electrophilic chlorine center.',
          curvedArrowNotes: r'Halogen lone pair coordinates into vacant orbital of Fe/Al.',
          intermediate: isBromination ? r'Polarized $[\text{Br-FeBr}_4]^-$ Lewis acid complex' : r'Polarized $[\text{Cl-AlCl}_4]^-$ Lewis acid complex',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Aromatic Ring Attack on Polarized Halogen (RDS)',
          description: r'Benzene $\pi$-cloud attacks the terminal positive halogen, forming the resonance-delocalized Wheland intermediate.',
          curvedArrowNotes: r'$\pi$-electrons attack halogen; halogen-Lewis acid bond cleaves.',
          intermediate: isBromination ? r'$[\text{C}_6\text{H}_6\text{Br}]^+$ Arenium cation' : r'$[\text{C}_6\text{H}_6\text{Cl}]^+$ Arenium cation',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Rearomatization & Catalyst Regeneration',
          description: isBromination
              ? r'The $[\text{FeBr}_4]^-$ complex abstracts the ring proton, regenerating the active $\text{FeBr}_3$ catalyst and forming $\text{HBr}$.'
              : r'The $[\text{AlCl}_4]^-$ complex abstracts the ring proton, regenerating the active $\text{AlCl}_3$ catalyst and forming $\text{HCl}$.',
          curvedArrowNotes: r'Halide from Lewis acid removes proton; electrons restore aromatic sextet.',
          intermediate: isBromination ? r'Bromobenzene + $\text{HBr}$ + $\text{FeBr}_3$' : r'Chlorobenzene + $\text{HCl}$ + $\text{AlCl}_3$',
        ),
      ],
      drivingForce: r'Restoration of aromatic sextet ($36\text{ kcal/mol}$).',
      syntheticNotes: r'Halobenzenes undergo magnesium insertion in dry ether to synthesize Grignard reagents ($\text{ArMgX}$) or undergo Suzuki-Miyaura / Heck cross-coupling.',
    );
  }

  static PredictedReactionResult _buildFriedelCraftsAlkylationPrediction(String q) {
    final lowerQ = q.toLowerCase();
    final isPropyl = lowerQ.contains('propyl') || lowerQ.contains('propane') || lowerQ.contains('chloropropane') || lowerQ.contains('ch3ch2ch2cl');

    if (isPropyl) {
      return const PredictedReactionResult(
        reactionName: 'Friedel-Crafts Alkylation with 1-Chloropropane (Carbocation Rearrangement)',
        category: 'Electrophilic Aromatic Substitution with Skeletal Rearrangement',
        reactants: r'Benzene ($\text{C}_6\text{H}_6$) + 1-Chloropropane ($\text{CH}_3\text{CH}_2\text{CH}_2\text{Cl}$)',
        reagentsAndConditions: r'Anhydrous $\text{AlCl}_3$ (Lewis Acid catalyst), $0^\circ\text{C} - 25^\circ\text{C}$',
        majorProduct: r'Isopropylbenzene (Cumene, $\approx 70\%$) — Formed via 1,2-Hydride Shift',
        majorProductFormula: r'\text{C}_6\text{H}_5\text{CH(CH}_3)_2',
        minorProducts: r'n-Propylbenzene ($\text{C}_6\text{H}_5\text{CH}_2\text{CH}_2\text{CH}_3, \approx 30\%$), $\text{HCl}$',
        selectivity: r'Skeletal Rearrangement Dominated: The primary carbocation/polarized complex undergoes a rapid 1,2-Hydride Shift to form the significantly more stable secondary isopropyl carbocation before electrophilic attack occurs.',
        mechanismSteps: [
          ReactionStep(
            stepNumber: 1,
            title: r'1,2-Hydride Shift to Secondary Carbocation',
            description: r'Coordination of $\text{CH}_3\text{CH}_2\text{CH}_2\text{Cl}$ with $\text{AlCl}_3$ induces a spontaneous 1,2-hydride shift: the hydride ($\text{H}^-$) migrates from C2 to C1, transforming the high-energy $1^\circ$ carbocation into a much more stable $2^\circ$ isopropyl carbocation $(\text{CH}_3)_2\text{CH}^+$.',
            curvedArrowNotes: r'C2-H bonding pair migrates to C1 with concomitant cleavage of C1-Cl bond toward $\text{AlCl}_3$.',
            intermediate: r'Secondary Isopropyl Carbocation $(\text{CH}_3)_2\text{CH}^+$',
          ),
          ReactionStep(
            stepNumber: 2,
            title: r'Electrophilic Attack on Benzene',
            description: r'Benzene attacks the isopropyl carbocation, forming the resonance-stabilized Wheland complex.',
            curvedArrowNotes: r'Benzene $\pi$-cloud attacks $C^+$ of isopropyl cation.',
            intermediate: r'$[\text{C}_6\text{H}_6-\text{CH(CH}_3)_2]^+$ $\sigma$-complex',
          ),
          ReactionStep(
            stepNumber: 3,
            title: r'Rearomatization',
            description: r'$\text{AlCl}_4^-$ abstracts the proton, restoring aromaticity and releasing Cumene.',
            curvedArrowNotes: r'Chloride from $[\text{AlCl}_4]^-$ takes $H^+$; ring becomes aromatic.',
            intermediate: r'Isopropylbenzene + $\text{HCl} + \text{AlCl}_3$',
          ),
        ],
        drivingForce: r'Thermodynamic stability of $2^\circ$ vs $1^\circ$ carbocation ($\Delta \Delta H^\circ \approx 67\text{ kJ/mol}$) and aromatic resonance restoration.',
        syntheticNotes: r'To prepare pure n-propylbenzene without rearrangement, use Friedel-Crafts Acylation with propionyl chloride followed by Clemmensen or Wolff-Kishner reduction.',
      );
    }

    return const PredictedReactionResult(
      reactionName: 'Friedel-Crafts Alkylation of Benzene',
      category: 'Electrophilic Aromatic Substitution (EAS)',
      reactants: r'Benzene ($\text{C}_6\text{H}_6$) + Methyl Chloride ($\text{CH}_3\text{Cl}$)',
      reagentsAndConditions: r'Anhydrous $\text{AlCl}_3$ Catalyst, $0^\circ\text{C} - 25^\circ\text{C}$',
      majorProduct: 'Toluene (Methylbenzene)',
      majorProductFormula: r'\text{C}_6\text{H}_5\text{CH}_3',
      minorProducts: r'Polyalkylated arenes (Xylenes, Mesitylene), $\text{HCl}$',
      selectivity: r'Prone to Polyalkylation: Because methyl is an activating group ($+\text{I}$), the toluene product is more nucleophilic than benzene and competes for alkylation.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Carbocation / Polarized Complex Formation',
          description: r'$\text{CH}_3\text{Cl}$ coordinates to Lewis acid $\text{AlCl}_3$ to form a highly polarized electrophilic methyl donor $\text{CH}_3^{\delta+}\cdots\text{Cl-AlCl}_3^{\delta-}$.',
          curvedArrowNotes: r'Chlorine lone pair coordinates to empty p-orbital of Al.',
          intermediate: r'$[\text{CH}_3-\text{Cl}-\text{AlCl}_3]$ Complex',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Nucleophilic Attack & Deprotonation',
          description: r'Benzene attacks the electrophilic methyl group, forming a $\sigma$-complex followed by deprotonation by $[\text{AlCl}_4]^-$.',
          curvedArrowNotes: r'Ring $\pi$-bond attacks $\text{CH}_3$; deprotonation restores aromatic ring.',
          intermediate: r'Toluene + $\text{HCl} + \text{AlCl}_3$',
        ),
      ],
      drivingForce: r'Restoration of aromatic sextet.',
      syntheticNotes: r'Major limitations: polyalkylation and carbocation rearrangements. Always prefer Friedel-Crafts Acylation followed by reduction for long-chain alkyl arenes.',
    );
  }

  static PredictedReactionResult _buildFriedelCraftsAcylationPrediction(String q) {
    return const PredictedReactionResult(
      reactionName: 'Friedel-Crafts Acylation of Benzene',
      category: 'Electrophilic Aromatic Substitution (EAS)',
      reactants: r'Benzene ($\text{C}_6\text{H}_6$) + Acetyl Chloride ($\text{CH}_3\text{COCl}$)',
      reagentsAndConditions: r'Anhydrous $\text{AlCl}_3$ (1.1 equivalents), Dry $\text{CH}_2\text{Cl}_2$, $0^\circ\text{C} - 20^\circ\text{C}$',
      majorProduct: 'Acetophenone (Methyl Phenyl Ketone)',
      majorProductFormula: r'\text{C}_6\text{H}_5\text{COCH}_3',
      minorProducts: r'Hydrogen Chloride ($\text{HCl}$)',
      selectivity: r'Strict Monosubstitution: The acyl group ($-\text{COCH}_3$) is strongly electron-withdrawing ($-\text{M}, -\text{I}$), which powerfully deactivates the product ring against any further acylation.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Generation of Resonance-Stabilized Acylium Ion Electrophile',
          description: r'Acetyl chloride reacts with $\text{AlCl}_3$ to release chloride, generating the linear, resonance-stabilized acylium ion $\text{CH}_3\text{-C}^+\text{=O} \longleftrightarrow \text{CH}_3\text{-C}\equiv\text{O}^+$, where all atoms satisfy the octet rule.',
          curvedArrowNotes: r'Oxygen lone pair pushes down to form $\text{C}\equiv\text{O}^+$ as $\text{Cl}^-$ leaves with $\text{AlCl}_3$.',
          intermediate: r'$\text{CH}_3\text{-C}\equiv\text{O}^+$ (Acylium Cation, Octet-Complete)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Electrophilic Attack on Benzene (RDS)',
          description: r'Benzene attacks the carbon of the acylium ion to form the resonance-stabilized Wheland complex without any rearrangement.',
          curvedArrowNotes: r'Ring $\pi$-electrons attack the carbonyl carbon of the acylium ion.',
          intermediate: r'$[\text{C}_6\text{H}_6-\text{COCH}_3]^+$ Arenium ion',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Deprotonation & Product-Lewis Acid Complexation',
          description: r'$\text{AlCl}_4^-$ removes the ring proton to restore aromaticity. The resulting ketone complexes with $\text{AlCl}_3$ and is freed upon aqueous workup.',
          curvedArrowNotes: r'Base abstracts $H^+$; electrons restore aromaticity. Aqueous workup hydrolyzes $\text{AlCl}_3$ complex.',
          intermediate: r'Acetophenone + $\text{HCl} + \text{Al(OH)}_3$',
        ),
      ],
      drivingForce: r'Resonance stabilization of the acylium ion electrophile and aromatic sextet restoration. Zero rearrangement observed.',
      syntheticNotes: r'Reduction of acetophenone via Clemmensen ($\text{Zn-Hg/HCl}$) or Wolff-Kishner ($\text{NH}_2\text{NH}_2/\text{KOH}$) cleanly yields pure ethylbenzene.',
    );
  }

  static PredictedReactionResult _buildReimerTiemannPrediction() {
    return const PredictedReactionResult(
      reactionName: 'Reimer-Tiemann Formylation of Phenol',
      category: 'Electrophilic Aromatic Substitution via Carbene Intermediate',
      reactants: r'Phenol ($\text{C}_6\text{H}_5\text{OH}$) + Chloroform ($\text{CHCl}_3$)',
      reagentsAndConditions: r'Aqueous $\text{KOH}$ or $\text{NaOH}$ ($60^\circ\text{C} - 70^\circ\text{C}$), then acidic hydrolysis ($\text{H}_3\text{O}^+$)',
      majorProduct: 'Salicylaldehyde (2-Hydroxybenzaldehyde)',
      majorProductFormula: r'\text{C}_6\text{H}_4(\text{OH})(\text{CHO})',
      minorProducts: r'4-Hydroxybenzaldehyde (para isomer, minor), $\text{KCl}, \text{H}_2\text{O}$',
      selectivity: r'Ortho-Regioselective (Ortho/Para ratio $\approx 4:1$): Ortho preference is governed by the 6-membered cyclic transition state involving coordination of the sodium/potassium metal cation with the phenolate oxygen and dichlorocarbene.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Generation of Dichlorocarbene Electrophile via $\alpha$-Elimination',
          description: r'Hydroxide ion deprotonates $\text{CHCl}_3$ to generate the trichloromethyl carbanion $^-\text{CCl}_3$, which undergoes rapid $\alpha$-elimination of $\text{Cl}^-$ to form the neutral, electron-deficient singlet dichlorocarbene electrophile $(:\text{CCl}_2)$.',
          curvedArrowNotes: r'$\text{OH}^-$ takes $H^+$ from $\text{CHCl}_3$; $\text{Cl}^-$ departs from $^-\text{CCl}_3$ with lone pair.',
          intermediate: r'$:\text{CCl}_2$ (Singlet Dichlorocarbene, 6-electron valence)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Electrophilic Attack of Dichlorocarbene on Phenolate Ion',
          description: r'Phenol is deprotonated to resonance-stabilized phenolate anion. The electron-rich ortho carbon attacks the vacant orbital of $:\text{CCl}_2$, generating a non-aromatic intermediate with a $-\text{CHCl}_2$ precursor.',
          curvedArrowNotes: r'Phenolate oxygen pushes electrons into the ring; ortho carbon attacks $:\text{CCl}_2$.',
          intermediate: r'Cyclohexadienone intermediate with $-\text{CCl}_2^-$ group',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Proton Transfer & Rearomatization',
          description: r'Intramolecular/intermolecular proton transfer from the ring carbon to the $^-\text{CCl}_2$ group restores aromaticity, yielding ortho-(dichloromethyl)phenol.',
          curvedArrowNotes: r'Ring $H^+$ is transferred to carbanion carbon; ring re-aromatizes.',
          intermediate: r'o-(Dichloromethyl)phenolate ion',
        ),
        ReactionStep(
          stepNumber: 4,
          title: r'Alkaline Hydrolysis to Aldehyde',
          description: r'Nucleophilic displacement of both chlorines by $\text{OH}^-$ forms an unstable gem-diol intermediate that spontaneously dehydrates to give salicylaldehyde.',
          curvedArrowNotes: r'Two $\text{OH}^-$ displace two $\text{Cl}^-$; elimination of $\text{H}_2\text{O}$ from $[\text{-CH(OH)}_2]$ yields $-\text{CHO}$.',
          intermediate: r'Salicylaldehyde (ortho-hydroxybenzaldehyde)',
        ),
      ],
      drivingForce: r'Thermodynamic stabilization of the intramolecular hydrogen-bonded salicylaldehyde chelate ring.',
      syntheticNotes: r'If carbon tetrachloride ($\text{CCl}_4$) is used instead of $\text{CHCl}_3$, salicylic acid (2-hydroxybenzoic acid) is obtained directly.',
    );
  }

  static PredictedReactionResult _buildKolbeSchmittPrediction() {
    return const PredictedReactionResult(
      reactionName: 'Kolbe-Schmitt Carboxylation of Phenol',
      category: 'Electrophilic Aromatic Substitution (Carboxylation)',
      reactants: r'Sodium Phenolate ($\text{C}_6\text{H}_5\text{ONa}$) + Carbon Dioxide ($\text{CO}_2$)',
      reagentsAndConditions: r'$120^\circ\text{C} - 140^\circ\text{C}$, $4 - 7\text{ atm}$ pressure, followed by acidification ($\text{H}_2\text{SO}_4$)',
      majorProduct: 'Salicylic Acid (2-Hydroxybenzoic Acid)',
      majorProductFormula: r'\text{C}_6\text{H}_4(\text{OH})(\text{COOH})',
      minorProducts: r'4-Hydroxybenzoic acid (minor at $120^\circ\text{C}$, major if potassium phenolate at $200^\circ\text{C}$ is used)',
      selectivity: r'Ortho-Regioselective with Sodium Cation: $\text{Na}^+$ forms a tight 6-membered cyclic chelate complex with the phenolate oxygen and oxygen of $\text{CO}_2$, directing carboxylation exclusively to the ortho carbon.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Nucleophilic Attack of Sodium Phenolate on Weak Electrophile $\text{CO}_2$',
          description: r'Sodium phenolate is highly activated toward nucleophilic addition. The ortho carbon attacks the central electrophilic carbon of carbon dioxide through a cyclic 6-membered sodium chelate transition state.',
          curvedArrowNotes: r'Phenolate oxygen pushes electrons into ring; ortho carbon attacks carbonyl carbon of $\text{O=C=O}$.',
          intermediate: r'6-Membered Cyclic Transition State with $\text{Na}^+$ chelation',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Rearomatization & Proton Shift',
          description: r'Proton transfer from the ortho carbon to the phenolate oxygen restores aromaticity, yielding disodium salicylate.',
          curvedArrowNotes: r'Ring proton shifts to phenoxide oxygen, re-establishing aromatic sextet.',
          intermediate: r'Sodium Salicylate salt',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Acidification',
          description: r'Treatment with mineral acid ($\text{H}_2\text{SO}_4$) protonates the carboxylate and phenoxide groups to precipitate pure salicylic acid crystals.',
          curvedArrowNotes: r'$\text{H}^+$ protonates $-\text{COO}^-$ and $-\text{O}^-$.',
          intermediate: r'Salicylic Acid ($\text{C}_7\text{H}_6\text{O}_3$)',
        ),
      ],
      drivingForce: r'Formation of stable aromatic carboxylate and intramolecular hydrogen bonding in salicylic acid.',
      syntheticNotes: r'Key industrial route for the synthesis of Aspirin (Acetylsalicylic acid) via acetylation with acetic anhydride ($\text{Ac}_2\text{O}/\text{H}_2\text{SO}_4$).',
    );
  }

  static PredictedReactionResult _buildEtardPrediction() {
    return const PredictedReactionResult(
      reactionName: 'Étard Oxidation of Toluene',
      category: 'Selective Side-Chain Aromatic Oxidation',
      reactants: r'Toluene ($\text{C}_6\text{H}_5\text{CH}_3$) + Chromyl Chloride ($\text{CrO}_2\text{Cl}_2$)',
      reagentsAndConditions: r'Non-polar solvent ($\text{CS}_2$ or $\text{CCl}_4$), room temperature, followed by aqueous decomposition ($\text{H}_3\text{O}^+$)',
      majorProduct: 'Benzaldehyde',
      majorProductFormula: r'\text{C}_6\text{H}_5\text{CHO}',
      minorProducts: r'Chromium salts $[\text{Cr(OH)}_2\text{Cl}_2]$',
      selectivity: r'Controlled Mono-oxidation: The reaction stops cleanly at the aldehyde stage without over-oxidation to benzoic acid because the insoluble brown Étard complex precipitates out and protects the aldehyde.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Formation of Brown Insoluble Étard Complex',
          description: r'Two molecules of chromyl chloride react with the methyl group of toluene via ene-like and homolytic C-H insertions to form a solid brown chromium complex.',
          curvedArrowNotes: r'C-H bonds of methyl group coordinate and insert across $\text{Cr=O}$ double bonds.',
          intermediate: r'Étard Complex: $\text{C}_6\text{H}_5\text{CH}[\text{OCr(OH)Cl}_2]_2$',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Aqueous Hydrolysis to Benzaldehyde',
          description: r'Addition of aqueous acid hydrolyzes the chromium-oxygen bonds, cleanly releasing benzaldehyde.',
          curvedArrowNotes: r'Water attacks chromium complex; elimination yields carbonyl $-\text{CH=O}$.',
          intermediate: r'Benzaldehyde ($\text{C}_6\text{H}_5\text{CHO}$)',
        ),
      ],
      drivingForce: r'Precipitation of the insoluble chromium coordination complex.',
      syntheticNotes: r'Standard laboratory and exam method to convert methyl arenes directly into benzaldehydes without over-oxidation.',
    );
  }

  static PredictedReactionResult _buildAntiMarkovnikovHBrPrediction(String q) {
    return const PredictedReactionResult(
      reactionName: 'Anti-Markovnikov Free-Radical Hydrobromination (Peroxide / Kharasch Effect)',
      category: 'Free-Radical Alkene Addition',
      reactants: r'Propene ($\text{CH}_3\text{CH=CH}_2$) + Hydrogen Bromide ($\text{HBr}$)',
      reagentsAndConditions: r'Organic Peroxides ($\text{ROOR}$ or Benzoyl Peroxide), $h\nu$ / Heat ($60^\circ\text{C}$)',
      majorProduct: r'1-Bromopropane (n-Propyl Bromide, $> 95\%$ yield)',
      majorProductFormula: r'\text{CH}_3\text{CH}_2\text{CH}_2\text{Br}',
      minorProducts: r'2-Bromopropane ($\text{CH}_3\text{CH(Br)CH}_3, < 5\%$), $\text{ROH}$',
      selectivity: r'Anti-Markovnikov Regioselectivity: The bromine radical ($\text{Br}^\bullet$) adds to the less-substituted terminal carbon (C1) to generate the more stable secondary carbon radical ($\text{CH}_3\dot{\text{C}}\text{HCH}_2\text{Br}$).',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Radical Chain Initiation: Generation of Bromine Radical ($\text{Br}^\bullet$)',
          description: r'Homolytic cleavage of the peroxide $\text{O-O}$ bond ($\approx 150\text{ kJ/mol}$) by heat or light yields alkoxy radicals $\text{RO}^\bullet$, which abstract a hydrogen atom from $\text{HBr}$ to generate the reactive bromine radical $\text{Br}^\bullet$.',
          curvedArrowNotes: r'Single-barbed fishhook arrows depict homolysis of $\text{RO-OR} \rightarrow 2\text{RO}^\bullet$, then $\text{RO}^\bullet + \text{H-Br} \rightarrow \text{ROH} + \text{Br}^\bullet$.',
          intermediate: r'Bromine Free Radical ($\text{Br}^\bullet$)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Regioselective Addition of $\text{Br}^\bullet$ to Alkene (Propagation Step 1)',
          description: r'$\text{Br}^\bullet$ attacks the terminal carbon (C1) of propene. This generates the resonance/hyperconjugation-stabilized secondary alkyl radical ($2^\circ$) rather than the unstable primary radical ($1^\circ$).',
          curvedArrowNotes: r'Fishhook arrow from $\text{Br}^\bullet$ and one electron from alkene $\pi$-bond form C1-Br bond; other $\pi$-electron localizes on C2 as a radical.',
          intermediate: r'$\text{CH}_3\dot{\text{C}}\text{H}-\text{CH}_2\text{Br}$ (Stable $2^\circ$ Alkyl Radical)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Hydrogen Atom Abstraction & Chain Propagation (Propagation Step 2)',
          description: r'The $2^\circ$ alkyl radical abstracts a hydrogen atom from another $\text{HBr}$ molecule, forming 1-bromopropane and regenerating $\text{Br}^\bullet$ to continue the chain.',
          curvedArrowNotes: r'Fishhook arrow from C2 radical pairs with hydrogen electron from $\text{H-Br}$; $\text{Br}^\bullet$ released.',
          intermediate: r'1-Bromopropane + $\text{Br}^\bullet$ (Chain carrier regenerated)',
        ),
      ],
      drivingForce: r'Thermodynamic stability of the $2^\circ$ radical intermediate over the $1^\circ$ radical ($\Delta \Delta H^\circ \approx 15\text{ kJ/mol}$).',
      syntheticNotes: r'CRITICAL EXAM POINT: The peroxide effect is strictly limited to $\text{HBr}$. It FAILS for $\text{HCl}$ (H-Cl bond is too strong, $+431\text{ kJ/mol}$, making propagation step 2 endothermic) and FAILS for $\text{HI}$ (C-I bond formation is weak and I-I recombination is too fast, making propagation step 1 endothermic).',
    );
  }

  static PredictedReactionResult _buildMarkovnikovAdditionPrediction(String q) {
    final isHCl = q.contains('hcl');
    final isHI = q.contains('hi');
    final halSym = isHI ? 'I' : (isHCl ? 'Cl' : 'Br');

    return PredictedReactionResult(
      reactionName: 'Markovnikov Electrophilic Addition of Hydrogen Halide to Alkene',
      category: 'Electrophilic Addition via Carbocation Intermediate',
      reactants: isHI
          ? r'Propene ($\text{CH}_3\text{CH=CH}_2$) + $\text{HI}$'
          : (isHCl ? r'Propene ($\text{CH}_3\text{CH=CH}_2$) + $\text{HCl}$' : r'Propene ($\text{CH}_3\text{CH=CH}_2$) + $\text{HBr}$'),
      reagentsAndConditions: r'Polar solvent ($\text{CH}_2\text{Cl}_2$ or acetic acid), Room temperature, absence of peroxides',
      majorProduct: isHI ? '2-Iodopropane' : (isHCl ? '2-Chloropropane' : '2-Bromopropane'),
      majorProductFormula: '\\text{CH}_3\\text{CH($halSym)CH}_3',
      minorProducts: isHI ? '1-Iodopropane' : (isHCl ? '1-Chloropropane' : '1-Bromopropane'),
      selectivity: r'Markovnikov’s Rule: Electrophilic proton ($H^+$) adds to the carbon with more hydrogen atoms (C1) to produce the more stable secondary carbocation intermediate (C2).',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Electrophilic Attack of $H^+$ (Rate-Determining Step)',
          description: r'Alkene $\pi$-electrons attack the electrophilic proton of the hydrogen halide, yielding a planar secondary carbocation stabilized by hyperconjugation (6 $\alpha$-hydrogens).',
          curvedArrowNotes: r'Curved arrow from $\text{C=C}$ $\pi$-bond to $H^+$; electrons from $\text{H-X}$ localize on halide.',
          intermediate: r'$\text{CH}_3-\text{C}^+\text{H}-\text{CH}_3$ (Stable $2^\circ$ Isopropyl Carbocation)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Nucleophilic Attack of Halide Ion',
          description: r'Halide ion rapidly attacks the vacant p-orbital of the carbocation to form 2-halopropane.',
          curvedArrowNotes: r'Lone pair on halide attacks $C^+$ from top or bottom face.',
          intermediate: r'2-Halopropane product',
        ),
      ],
      drivingForce: r'Conversion of one weak $\pi$-bond ($264\text{ kJ/mol}$) and one $\text{H-X}$ bond into two strong $\sigma$-bonds ($\text{C-H}$ and $\text{C-X}$).',
      syntheticNotes: r'Rearrangements (hydride/methyl shifts) occur if a more stable $3^\circ$ or allylic/benzylic carbocation can be formed (e.g. 3,3-dimethyl-1-butene $\rightarrow$ 2-halo-2,3-dimethylbutane).',
    );
  }

  static PredictedReactionResult _buildHydroborationOxidationPrediction(String q) {
    return const PredictedReactionResult(
      reactionName: 'Hydroboration-Oxidation of Alkene',
      category: 'Regiospecific & Stereospecific Anti-Markovnikov Hydration',
      reactants: r'1-Methylcyclohexene + Borane ($\text{BH}_3\cdot\text{THF}$)',
      reagentsAndConditions: r'1) $\text{BH}_3\cdot\text{THF}$, $0^\circ\text{C}$; 2) Alkaline Hydrogen Peroxide ($\text{H}_2\text{O}_2, \text{NaOH}$), $25^\circ\text{C} - 50^\circ\text{C}$',
      majorProduct: 'trans-2-Methylcyclohexanol',
      majorProductFormula: r'\text{C}_7\text{H}_{14}\text{O}',
      minorProducts: r'Boric acid $[\text{B(OH)}_3]$ or Borate salts',
      selectivity: r'Anti-Markovnikov Regioselectivity & 100% Syn-Stereospecific Addition: Boron ($\text{BH}_2$) attaches to the less hindered, less substituted carbon, while hydrogen ($H$) delivers to the same face simultaneously. Oxidation replaces boron with $-\text{OH}$ with 100% retention of stereochemistry.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Concerted 4-Membered Cyclic Syn-Addition',
          description: r'Borane adds across the double bond in a concerted 4-membered square planar transition state. Boron ($-\text{BH}_2$) adds to the less hindered carbon and hydrogen ($-\text{H}$) adds to the more substituted carbon from the same face (syn-addition).',
          curvedArrowNotes: r'Alkene $\pi$-electrons attack empty p-orbital of B; B-H bonding pair simultaneously attacks adjacent carbon.',
          intermediate: r'4-Membered Cyclic Transition State $\rightarrow$ Trialkylborane $[\text{R}_3\text{B}]$',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Hydroperoxide Ion Attack on Trialkylborane',
          description: r'Hydroperoxide anion ($^-\text{O-OH}$, formed from $\text{H}_2\text{O}_2 + \text{NaOH}$) attacks the empty p-orbital of trialkylborane to form a negative borate complex.',
          curvedArrowNotes: r'Lone pair of $^-\text{OOH}$ coordinates to boron atom.',
          intermediate: r'$[\text{R}_3\text{B-O-OH}]^-$ Borate complex',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'1,2-Alkyl Migration with Retention & Hydrolysis',
          description: r'The alkyl group migrates from boron to the adjacent oxygen with loss of $\text{OH}^-$, proceeding with 100% retention of stereochemistry. Alkaline hydrolysis yields the pure trans-alcohol.',
          curvedArrowNotes: r'B-C bonding pair migrates to oxygen; $\text{OH}^-$ departs with retention of chiral configuration.',
          intermediate: r'Trialkyl borate $\text{B(OR)}_3 \xrightarrow{\text{NaOH/H}_2\text{O}} 3\text{ROH} + \text{Na}_3\text{BO}_3$',
        ),
      ],
      drivingForce: r'Steric and electronic factors favoring boron addition at the least hindered carbon; high thermodynamic strength of B-O bonds ($536\text{ kJ/mol}$).',
      syntheticNotes: r'Zero carbocation intermediate is formed, meaning carbocation rearrangements NEVER occur (unlike acid-catalyzed hydration).',
    );
  }

  static PredictedReactionResult _buildOzonolysisPrediction(String q) {
    final is2Butene = q.contains('2-butene') || q.contains('but-2-ene');

    if (is2Butene) {
      return const PredictedReactionResult(
        reactionName: 'Reductive Ozonolysis of 2-Butene',
        category: 'Alkene Oxidative Cleavage',
        reactants: r'2-Butene ($\text{CH}_3\text{CH=CHCH}_3$) + Ozone ($\text{O}_3$)',
        reagentsAndConditions: r'1) $\text{O}_3$ in $\text{CH}_2\text{Cl}_2$ ($-78^\circ\text{C}$); 2) Reductive workup with $\text{Zn} / \text{H}_2\text{O}$ or Dimethyl sulfide ($\text{Me}_2\text{S}$)',
        majorProduct: 'Acetaldehyde (Ethanal, 2 equivalents)',
        majorProductFormula: r'2\text{ CH}_3\text{CHO}',
        minorProducts: r'Dimethyl sulfoxide ($\text{DMSO}, \text{Me}_2\text{SO}$) or $\text{ZnO}$',
        selectivity: r'Complete Cleavage of Carbon-Carbon Double Bond: Both $\sigma$ and $\pi$ bonds of the alkene are severed, and each $sp^2$ carbon is converted directly into a carbonyl ($\text{C=O}$) group.',
        mechanismSteps: [
          ReactionStep(
            stepNumber: 1,
            title: r'1,3-Dipolar Cycloaddition to Molozonide (Primary Ozonide)',
            description: r'Ozone adds across the $\text{C=C}$ double bond via a concerted [3+2] 1,3-dipolar cycloaddition to yield the unstable 1,2,3-trioxolane (molozonide).',
            curvedArrowNotes: r'Dipolar ozone $\pi$-system interacts with alkene $\pi$-system in concerted cycloaddition.',
            intermediate: r'Molozonide (1,2,3-Trioxolane, Unstable)',
          ),
          ReactionStep(
            stepNumber: 2,
            title: r'Retro-Cycloaddition & Recombination to Stable Secondary Ozonide',
            description: r'The molozonide spontaneously fragments into a carbonyl compound and a carbonyl oxide zwitterion (Criegee intermediate), which flip and recombine into the stable 1,2,4-trioxolane (secondary ozonide).',
            curvedArrowNotes: r'Cleavage of C-C and O-O bonds followed by [3+2] cycloaddition of Criegee zwitterion with aldehyde.',
            intermediate: r'Secondary Ozonide (1,2,4-Trioxolane)',
          ),
          ReactionStep(
            stepNumber: 3,
            title: r'Reductive Cleavage with $\text{Zn/H}_2\text{O}$ or $\text{Me}_2\text{S}$',
            description: r'Dimethyl sulfide or zinc reduces the weak peroxy $\text{O-O}$ bond of the ozonide, cleanly forming two molecules of acetaldehyde and $\text{Me}_2\text{S=O}$.',
            curvedArrowNotes: r'Sulfur lone pair attacks peroxide oxygen, triggering electron cascade to release two carbonyls.',
            intermediate: r'$2\text{ CH}_3\text{CHO} + \text{Me}_2\text{S=O}$',
          ),
        ],
        drivingForce: r'Release of high ring strain and weak $\text{O-O}$ peroxide bonds ($\approx 140\text{ kJ/mol}$) to form strong $\text{C=O}$ double bonds ($\approx 745\text{ kJ/mol}$).',
        syntheticNotes: r'Diagnostic tool to elucidate double bond position in unknown natural products and terpenes. If oxidative workup ($\text{H}_2\text{O}_2$) is used instead, aldehydes are oxidized to carboxylic acids (yielding 2 equivalents of Acetic Acid).',
      );
    }

    return const PredictedReactionResult(
      reactionName: 'Ozonolysis of Alkenes',
      category: 'Oxidative Cleavage of Carbon-Carbon Double Bonds',
      reactants: r'Alkene ($\text{R}_2\text{C=CHR\x27}$) + Ozone ($\text{O}_3$)',
      reagentsAndConditions: r'1) $\text{O}_3$ in $\text{CH}_2\text{Cl}_2$ at $-78^\circ\text{C}$; 2) Reductive workup ($\text{Zn/H}_2\text{O}$ or $\text{Me}_2\text{S}$)',
      majorProduct: 'Ketone and Aldehyde Mixture',
      majorProductFormula: r'\text{R}_2\text{C=O} + \text{R\x27CHO}',
      minorProducts: r'$\text{DMSO} (\text{Me}_2\text{SO})$ or $\text{ZnO}$',
      selectivity: r'Disubstituted carbons yield ketones; Monosubstituted carbons yield aldehydes under reductive conditions or carboxylic acids under oxidative conditions ($\text{H}_2\text{O}_2$); Terminal methylene yields formaldehyde or $\text{CO}_2 + \text{H}_2\text{O}$.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Formation of Molozonide via 1,3-Dipolar Cycloaddition',
          description: r'Ozone undergoes a concerted [3+2] cycloaddition with the alkene to form the unstable 1,2,3-trioxolane.',
          curvedArrowNotes: r'Concerted curved arrows from ozone onto alkene carbons.',
          intermediate: r'Primary Molozonide',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Rearrangement via Criegee Intermediate to Stable Ozonide',
          description: r'Fragmentation into a carbonyl oxide zwitterion and carbonyl compound, followed by recombination into the 1,2,4-trioxolane.',
          curvedArrowNotes: r'Cleavage of C-C single bond; recombination of Criegee zwitterion.',
          intermediate: r'Secondary 1,2,4-Trioxolane Ozonide',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Reductive Hydrolysis',
          description: r'Reduction of the peroxide bridge by $\text{Zn}$ or $\text{Me}_2\text{S}$ liberates the corresponding carbonyl fragments.',
          curvedArrowNotes: r'Nucleophilic attack by reducing agent on peroxide oxygen.',
          intermediate: r'Carbonyl compounds',
        ),
      ],
      drivingForce: r'Thermodynamic formation of exceptionally strong $\text{C=O}$ $\pi$-bonds.',
      syntheticNotes: r'Essential synthetic methodology to prepare dialdehydes, ketoaldehydes, and dicarboxylic acids from cyclic alkenes.',
    );
  }

  static PredictedReactionResult _buildAldolCondensationPrediction(String q) {
    final isCrossed = q.contains('benzaldehyde') && q.contains('acetone');

    if (isCrossed) {
      return const PredictedReactionResult(
        reactionName: 'Claisen-Schmidt Crossed Aldol Condensation',
        category: 'Base-Catalyzed Carbonyl Condensation',
        reactants: r'Benzaldehyde ($\text{C}_6\text{H}_5\text{CHO}$) + Acetone ($\text{CH}_3\text{COCH}_3$)',
        reagentsAndConditions: r'Dilute aqueous $\text{NaOH}$ ($10\%$), Room Temperature ($20^\circ\text{C} - 25^\circ\text{C}$)',
        majorProduct: r'Benzylideneacetone (4-Phenylbut-3-en-2-one)',
        majorProductFormula: r'\text{C}_6\text{H}_5\text{CH=CHCOCH}_3',
        minorProducts: r'Water ($\text{H}_2\text{O}$), Dibenzylideneacetone ($\text{C}_6\text{H}_5\text{CH=CHCOCH=CH}\text{C}_6\text{H}_5$)',
        selectivity: r'High Chemoselectivity: Benzaldehyde lacks $\alpha$-hydrogens and cannot form an enolate ion; it acts solely as the electrophilic acceptor. Acetone provides the nucleophilic enolate donor.',
        mechanismSteps: [
          ReactionStep(
            stepNumber: 1,
            title: r'Enolate Generation from Acetone',
            description: r'Hydroxide base abstracts an $\alpha$-proton ($pK_a \approx 19.3$) from acetone to form a resonance-stabilized enolate anion.',
            curvedArrowNotes: r'$\text{OH}^-$ abstracts $\alpha\text{-H}$; electron pair delocalizes onto carbonyl oxygen.',
            intermediate: r'Enolate Anion: $\text{CH}_2=\text{C(O}^-)\text{CH}_3 \longleftrightarrow ^-\text{CH}_2-\text{C(=O)CH}_3$',
          ),
          ReactionStep(
            stepNumber: 2,
            title: r'Nucleophilic Addition to Benzaldehyde Carbonyl',
            description: r'The enolate carbon attacks the highly electrophilic carbonyl carbon of benzaldehyde to form a tetrahedral alkoxide intermediate.',
            curvedArrowNotes: r'Enolate $\text{C=C}$ $\pi$-electrons attack benzaldehyde carbonyl carbon; $\text{C=O}$ $\pi$-bond opens onto oxygen.',
            intermediate: r'Tetrahedral Alkoxide $[\text{C}_6\text{H}_5-\text{CH(O}^-)-\text{CH}_2\text{COCH}_3]$',
          ),
          ReactionStep(
            stepNumber: 3,
            title: r'Protonation & E1cB Dehydration to Conjugated Enone',
            description: r'Protonation by $\text{H}_2\text{O}$ gives the $\beta$-hydroxy ketone (aldol). Base-catalyzed elimination via an $\text{E1cB}$ mechanism spontaneously expels $\text{OH}^-$ to generate the stable, extended conjugated $\alpha,\beta$-unsaturated system.',
            curvedArrowNotes: r'Base abstracts remaining $\alpha\text{-H}$ to form enolate carbanion; expulsion of $\text{OH}^-$ forms trans-alkene.',
            intermediate: r'Benzylideneacetone (trans-isomer)',
          ),
        ],
        drivingForce: r'Thermodynamic stabilization gained from the extensive, unbroken conjugated $\pi$-electron system extending from the benzene ring through the alkene to the carbonyl group.',
        syntheticNotes: r'Standard undergraduate and postgraduate synthesis of chalcones and UV-absorbing sunscreen compounds.',
      );
    }

    return const PredictedReactionResult(
      reactionName: 'Self-Aldol Condensation of Acetaldehyde',
      category: 'Carbonyl Carbon-Carbon Bond Formation',
      reactants: r'Acetaldehyde ($2\text{ CH}_3\text{CHO}$)',
      reagentsAndConditions: r'Dilute $\text{NaOH}$ ($10\%$), $0^\circ\text{C} - 10^\circ\text{C}$ (for aldol) or heat (for condensation)',
      majorProduct: r'Crotonaldehyde (But-2-enal, $\alpha,\beta$-unsaturated aldehyde)',
      majorProductFormula: r'\text{CH}_3\text{CH=CHCHO}',
      minorProducts: r'3-Hydroxybutanal (Aldol intermediate before heating), $\text{H}_2\text{O}$',
      selectivity: r'Stereoselective for the more stable (E)-isomer (trans) due to minimization of steric clash between methyl and formyl groups.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Enolate Anion Formation',
          description: r'Base abstracts $\alpha\text{-H}$ from one molecule of acetaldehyde.',
          curvedArrowNotes: r'$\text{OH}^-$ takes $\alpha\text{-H}$; enolate forms.',
          intermediate: r'$^-\text{CH}_2\text{CHO} \longleftrightarrow \text{CH}_2=\text{CH-O}^-$',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Nucleophilic Addition to Second Acetaldehyde Molecule',
          description: r'Enolate carbon attacks the carbonyl carbon of the second un-ionized acetaldehyde.',
          curvedArrowNotes: r'Enolate attacks carbonyl carbon; $\text{C=O}$ opens.',
          intermediate: r'Alkoxide intermediate $\rightarrow$ 3-Hydroxybutanal',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'E1cB Dehydration',
          description: r'On gentle warming, base abstracts the remaining acidic $\alpha\text{-H}$ followed by expulsion of hydroxide leaving group to form crotonaldehyde.',
          curvedArrowNotes: r'Base removes $\alpha\text{-H}$; lone pair kicks out $\text{OH}^-$ to form conjugated $\text{C=C}$ bond.',
          intermediate: r'Crotonaldehyde ($\text{CH}_3\text{CH=CHCHO}$)',
        ),
      ],
      drivingForce: r'Extended conjugation between the $\text{C=C}$ double bond and $\text{C=O}$ carbonyl group ($\approx 17\text{ kJ/mol}$ resonance energy).',
      syntheticNotes: r'Aldol additions are key building blocks in industrial polyol production and total synthesis of complex polyketide natural products.',
    );
  }

  static PredictedReactionResult _buildCannizzaroPrediction(String q) {
    return const PredictedReactionResult(
      reactionName: 'Cannizzaro Disproportionation (Redox Reaction)',
      category: 'Base-Induced Hydride Transfer of Non-Enolizable Aldehydes',
      reactants: r'Benzaldehyde ($2\text{ C}_6\text{H}_5\text{CHO}$)',
      reagentsAndConditions: r'Concentrated alkali ($50\%\text{ NaOH}$ or $\text{KOH}$), room temperature or gentle reflux',
      majorProduct: r'Benzyl Alcohol (Reduced product, 1 equiv) + Potassium Benzoate (Oxidized product, 1 equiv)',
      majorProductFormula: r'\text{C}_6\text{H}_5\text{CH}_2\text{OH} + \text{C}_6\text{H}_5\text{COOK}',
      minorProducts: r'Benzoic Acid (upon acidification with $\text{HCl}$)',
      selectivity: r'Self-Redox Disproportionation: One molecule of benzaldehyde is reduced to alcohol while the second is oxidized to carboxylic acid. Occurs strictly with aldehydes lacking $\alpha$-hydrogens.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Nucleophilic Addition of Hydroxide to Benzaldehyde',
          description: r'Hydroxide ion attacks the carbonyl carbon to form a tetrahedral mono-anion, which in strongly basic medium is deprotonated to a dianion $[\text{C}_6\text{H}_5\text{CH(O}^-)_2]$.',
          curvedArrowNotes: r'$\text{OH}^-$ lone pair attacks carbonyl carbon; $\text{C=O}$ opens onto oxygen.',
          intermediate: r'Tetrahedral Dianion Intermediate $[\text{C}_6\text{H}_5\text{CH(O}^-)_2]$',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Direct Hydride Transfer (Rate-Determining Step)',
          description: r'The dianion collapses its $\text{C-O}^-$ bond into $\text{C=O}$, expelling a hydride ion ($H^-$) which directly attacks the carbonyl carbon of a second benzaldehyde molecule.',
          curvedArrowNotes: r'Oxygen lone pair reforms $\text{C=O}$; hydride ($H^-$) transfers directly to second aldehyde carbonyl carbon.',
          intermediate: r'Benzoate Anion ($\text{C}_6\text{H}_5\text{COO}^-$) + Benzyloxide Anion ($\text{C}_6\text{H}_5\text{CH}_2\text{O}^-$)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Rapid Proton Transfer',
          description: r'Benzyloxide abstracts a proton from water or benzoic acid to yield benzyl alcohol and benzoate salt.',
          curvedArrowNotes: r'Benzyloxide oxygen takes $H^+$ to yield neutral alcohol.',
          intermediate: r'Benzyl Alcohol + Benzoate Salt',
        ),
      ],
      drivingForce: r'Irreversible formation of resonance-stabilized carboxylate anion and high hydration enthalpy.',
      syntheticNotes: r'Crossed Cannizzaro with formaldehyde: Formaldehyde is oxidized exclusively to formate ($\text{HCOO}^-$) because its carbonyl is much more electrophilic, giving nearly $100\%$ yield of the reduced alcohol from the other aldehyde.',
    );
  }

  static PredictedReactionResult _buildWittigPrediction(String q) {
    return const PredictedReactionResult(
      reactionName: 'Wittig Carbonyl Olefination',
      category: 'Regiospecific & Stereoselective Alkene Synthesis',
      reactants: r'Benzaldehyde ($\text{C}_6\text{H}_5\text{CHO}$) + Methylenetriphenylphosphorane ($\text{Ph}_3\text{P=CH}_2$)',
      reagentsAndConditions: r'Dry THF / Ether, inert atmosphere ($\text{N}_2$), room temperature ($25^\circ\text{C}$)',
      majorProduct: 'Styrene (Ethenylbenzene)',
      majorProductFormula: r'\text{C}_6\text{H}_5\text{CH=CH}_2',
      minorProducts: r'Triphenylphosphine Oxide ($\text{Ph}_3\text{P=O}$, stoichiometric byproduct)',
      selectivity: r'100% Regiospecific: The $\text{C=O}$ carbonyl group is converted unambiguously into a $\text{C=C}$ double bond at the exact original carbonyl carbon position without double bond migration or isomerism.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'[2+2] Cycloaddition to Oxaphosphetane Intermediate',
          description: r'The nucleophilic carbanion of the phosphonium ylide attacks the electrophilic carbonyl carbon while the carbonyl oxygen coordinates to the phosphorus atom, forming a 4-membered cyclic oxaphosphetane.',
          curvedArrowNotes: r'Carbanion lone pair attacks carbonyl carbon; carbonyl oxygen attacks positively polarized phosphorus.',
          intermediate: r'4-Membered Oxaphosphetane Ring',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Retro-[2+2] Cycloreversion to Alkene & $\text{Ph}_3\text{P=O}$',
          description: r'The 4-membered ring collapses spontaneously via a concerted cycloreversion, expelling triphenylphosphine oxide and yielding the alkene.',
          curvedArrowNotes: r'P-C bond breaks toward C=C; C-O bond breaks toward P=O.',
          intermediate: r'Styrene + $\text{Ph}_3\text{P=O}$',
        ),
      ],
      drivingForce: r'Enormous thermodynamic driving force of forming the exceptionally strong phosphorus-oxygen double bond ($\text{P=O}$ bond dissociation energy $\approx 540\text{ kJ/mol}$).',
      syntheticNotes: r'Non-stabilized ylides give predominantly (Z)-alkenes via kinetic control; stabilized ylides (e.g. $\text{Ph}_3\text{P=CH-COOMe}$) give predominantly (E)-alkenes via thermodynamic control.',
    );
  }

  static PredictedReactionResult _buildBenzoinPrediction() {
    return const PredictedReactionResult(
      reactionName: 'Benzoin Condensation of Benzaldehyde',
      category: 'Cyanide-Catalyzed Umpolung (Reversal of Polarity)',
      reactants: r'Benzaldehyde ($2\text{ C}_6\text{H}_5\text{CHO}$)',
      reagentsAndConditions: r'Catalytic Potassium Cyanide ($\text{KCN}$) or Sodium Cyanide ($\text{NaCN}$), Aqueous Ethanol, Reflux ($70^\circ\text{C} - 80^\circ\text{C}$)',
      majorProduct: 'Benzoin (2-Hydroxy-1,2-diphenylethan-1-one)',
      majorProductFormula: r'\text{C}_6\text{H}_5\text{CH(OH)COC}_6\text{H}_5',
      minorProducts: r'Trace benzyl alcohol / benzoic acid',
      selectivity: r'Umpolung Carbon-Carbon Coupling: Cyanide ion acts as a unique catalyst: it is a good nucleophile, stabilizes the carbanion intermediate through $-\text{M}$ resonance, and acts as an excellent leaving group in the final step.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Nucleophilic Addition of Cyanide & Umpolung Proton Transfer',
          description: r'Cyanide attacks the carbonyl carbon to form a cyanohydrin intermediate. Proton transfer from the $\alpha$-carbon to oxygen generates a resonance-stabilized carbanion (acyl carbanion equivalent, Umpolung).',
          curvedArrowNotes: r'$\text{CN}^-$ attacks carbonyl carbon; $\text{C=O}$ opens; proton shifts to oxygen while carbanion is stabilized by $-\text{C}\equiv\text{N}$.',
          intermediate: r'Resonance-stabilized carbanion $[\text{C}_6\text{H}_5\text{-C}^-(\text{OH})\text{CN}]$',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Nucleophilic Attack on Second Benzaldehyde Molecule',
          description: r'The carbanion attacks the carbonyl carbon of the second benzaldehyde molecule.',
          curvedArrowNotes: r'Carbanion attacks second aldehyde carbonyl.',
          intermediate: r'Alkoxide intermediate $[\text{C}_6\text{H}_5\text{-C(OH)(CN)-CH(O}^-)\text{C}_6\text{H}_5]$',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Proton Shift & Expulsion of Cyanide Catalyst',
          description: r'Proton transfer followed by collapse of the $-\text{OH}$ oxygen lone pair expels $\text{CN}^-$ as a leaving group, regenerating the cyanide catalyst and yielding Benzoin.',
          curvedArrowNotes: r'Oxygen lone pair forms $\text{C=O}$; $\text{CN}^-$ departs.',
          intermediate: r'Benzoin + $\text{CN}^-$ (Catalyst regenerated)',
        ),
      ],
      drivingForce: r'Formation of stable $\alpha$-hydroxy ketone and cyanide regeneration.',
      syntheticNotes: r'Oxidation of benzoin with $\text{HNO}_3$ yields Benzil ($\text{C}_6\text{H}_5\text{COCOC}_6\text{H}_5$), which undergoes the Benzilic Acid Rearrangement.',
    );
  }

  static PredictedReactionResult _buildPerkinPrediction() {
    return const PredictedReactionResult(
      reactionName: 'Perkin Condensation Synthesis of Cinnamic Acid',
      category: 'Base-Catalyzed Carbonyl Condensation',
      reactants: r'Benzaldehyde ($\text{C}_6\text{H}_5\text{CHO}$) + Acetic Anhydride ($(\text{CH}_3\text{CO})_2\text{O}$)',
      reagentsAndConditions: r'Sodium Acetate ($\text{CH}_3\text{COONa}$ catalyst), $180^\circ\text{C}$, 4-6 hours, followed by acidic hydrolysis',
      majorProduct: 'trans-Cinnamic Acid ((E)-3-Phenylacrylic acid)',
      majorProductFormula: r'\text{C}_6\text{H}_5\text{CH=CHCOOH}',
      minorProducts: r'Acetic Acid ($\text{CH}_3\text{COOH}$)',
      selectivity: r'Stereoselective for the trans (E) isomer due to thermodynamic stability of the coplanar conjugated phenyl-alkene-carboxyl system.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Enolization of Acetic Anhydride',
          description: r'Sodium acetate abstracts an $\alpha$-proton from acetic anhydride to form an enolate anion.',
          curvedArrowNotes: r'$\text{CH}_3\text{COO}^-$ abstracts $\alpha\text{-H}$ from anhydride.',
          intermediate: r'Enolate of Acetic Anhydride',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Nucleophilic Addition to Benzaldehyde & Dehydration',
          description: r'The enolate attacks benzaldehyde to form an alkoxide, which is acetylated and undergoes elimination to form mixed cinnamic-acetic anhydride.',
          curvedArrowNotes: r'Enolate attacks aldehyde carbonyl; elimination yields $\text{C=C}$ bond.',
          intermediate: r'Mixed Cinnamic-Acetic Anhydride',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Hydrolysis to Cinnamic Acid',
          description: r'Aqueous hydrolysis cleaves the mixed anhydride to yield trans-cinnamic acid and acetic acid.',
          curvedArrowNotes: r'Water hydrolyzes anhydride linkage.',
          intermediate: r'trans-Cinnamic Acid + $\text{CH}_3\text{COOH}$',
        ),
      ],
      drivingForce: r'Extended aromatic conjugation and thermodynamic stability of the trans-cinnamate framework.',
      syntheticNotes: r'Primary academic method to prepare $\alpha,\beta$-unsaturated aromatic carboxylic acids.',
    );
  }

  static PredictedReactionResult _buildBeckmannPrediction(String q) {
    final isCyclohexanone = q.contains('cyclohexanone');

    if (isCyclohexanone) {
      return const PredictedReactionResult(
        reactionName: r'Beckmann Rearrangement of Cyclohexanone Oxime to $\varepsilon$-Caprolactam',
        category: 'Intramolecular Acid-Catalyzed Rearrangement',
        reactants: r'Cyclohexanone Oxime ($\text{C}_6\text{H}_{11}\text{NO}$)',
        reagentsAndConditions: r'Concentrated $\text{H}_2\text{SO}_4$ or $\text{PCl}_5$, $90^\circ\text{C} - 120^\circ\text{C}$',
        majorProduct: r'$\varepsilon$-Caprolactam (Azepan-2-one, 7-Membered Cyclic Amide)',
        majorProductFormula: r'\text{C}_6\text{H}_{11}\text{NO}',
        minorProducts: r'Trace ring-opened amino acids',
        selectivity: r'Stereospecific Anti-Migration: The ring alkyl carbon positioned strictly anti-periplanar ($180^\circ$) to the departing protonated hydroxyl group ($-\text{OH}_2^+$) migrates with 100% stereospecificity.',
        mechanismSteps: [
          ReactionStep(
            stepNumber: 1,
            title: r'Protonation of Oxime Hydroxyl Group',
            description: r'Sulfuric acid protonates the oxime $-\text{OH}$ to convert it into the excellent leaving group $-\text{OH}_2^+$.',
            curvedArrowNotes: r'Oxime OH lone pair attacks $H^+$ of sulfuric acid.',
            intermediate: r'Protonated Oxime $[\text{R}_2\text{C=N-OH}_2]^+$',
          ),
          ReactionStep(
            stepNumber: 2,
            title: r'Concerted Anti-Periplanar Alkyl Migration with Water Departure',
            description: r'The C-C ring bond anti to $-\text{OH}_2^+$ migrates onto the nitrogen atom simultaneously with departure of water, creating a 7-membered cyclic nitrilium ion.',
            curvedArrowNotes: r'Anti C-C bond migrates to nitrogen as water departs simultaneously in concerted transition state.',
            intermediate: r'Cyclic Nitrilium Cation Intermediate',
          ),
          ReactionStep(
            stepNumber: 3,
            title: r'Hydration & Tautomerization to Lactam',
            description: r'Water attacks the nitrilium carbon to form an imidate intermediate, which rapidly tautomerizes into the stable lactam amide.',
            curvedArrowNotes: r'$\text{H}_2\text{O}$ attacks $C^+$; proton transfer and tautomerization yield carbonyl amide.',
            intermediate: r'$\varepsilon$-Caprolactam',
          ),
        ],
        drivingForce: r'Thermodynamic stability of the amide resonance structure ($\Delta H^\circ \approx -88\text{ kJ/mol}$).',
        syntheticNotes: r'Massive industrial reaction: $\varepsilon$-caprolactam is the sole precursor for the ring-opening polymerization of Nylon-6.',
      );
    }

    return const PredictedReactionResult(
      reactionName: 'Beckmann Rearrangement of Ketoximes',
      category: 'Acid-Catalyzed Intramolecular Oxime Rearrangement',
      reactants: r'Acetophenone Oxime ($\text{C}_6\text{H}_5\text{C(CH}_3)\text{=NOH}$)',
      reagentsAndConditions: r'Acid catalyst ($\text{H}_2\text{SO}_4, \text{PCl}_5$, or $\text{SOCl}_2$), $60^\circ\text{C} - 100^\circ\text{C}$',
      majorProduct: 'N-Phenylacetamide (Acetanilide)',
      majorProductFormula: r'\text{CH}_3\text{CONHC}_6\text{H}_5',
      minorProducts: r'N-Methylbenzamide (if syn-methyl isomer was present)',
      selectivity: r'100% Stereospecific Anti-Migration: Migration is dictated purely by the geometry of the oxime (the group anti to $-\text{OH}$ migrates, NOT migratory aptitude).',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Oxime Oxygen Activation',
          description: r'Protonation of $-\text{OH}$ to form $-\text{OH}_2^+$.',
          curvedArrowNotes: r'Oxygen attacks $H^+$.',
          intermediate: r'Oxonium ion',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Concerted Anti-Migration to Nitrilium Ion',
          description: r'The anti-phenyl group migrates to nitrogen with simultaneous departure of water.',
          curvedArrowNotes: r'Phenyl C-C bond migrates to nitrogen with loss of $\text{H}_2\text{O}$.',
          intermediate: r'Linear Nitrilium Cation $[\text{CH}_3\text{-C}\equiv\text{N-Ph}]^+$',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Hydration to Secondary Amide',
          description: r'Attack of water on nitrilium carbon followed by tautomerization produces the secondary amide.',
          curvedArrowNotes: r'Water attacks carbon; keto-enol tautomerism gives amide.',
          intermediate: r'Acetanilide ($\text{CH}_3\text{CONHC}_6\text{H}_5$)',
        ),
      ],
      drivingForce: r'Amide resonance stabilization energy.',
      syntheticNotes: r'Crucial diagnostic reaction to determine geometric isomerism (syn vs anti) of oximes.',
    );
  }

  static PredictedReactionResult _buildHofmannBromamidePrediction(String q) {
    return const PredictedReactionResult(
      reactionName: 'Hofmann Bromamide Degradation of Primary Amides',
      category: 'Rearrangement with Carbon Chain Shortening',
      reactants: r'Benzamide ($\text{C}_6\text{H}_5\text{CONH}_2$) + Bromine ($\text{Br}_2$)',
      reagentsAndConditions: r'Aqueous or alcoholic $\text{KOH}$ or $\text{NaOH}$, $60^\circ\text{C} - 80^\circ\text{C}$',
      majorProduct: 'Aniline (Benzenamine, 1 less carbon)',
      majorProductFormula: r'\text{C}_6\text{H}_5\text{NH}_2',
      minorProducts: r'Potassium Carbonate ($\text{K}_2\text{CO}_3$), $\text{KBr}, \text{H}_2\text{O}$',
      selectivity: r'Intramolecular Rearrangement with 100% Retention of Configuration: The migrating alkyl/aryl group never leaves the coordination sphere, preserving chiral centers completely.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'N-Bromination of Amide',
          description: r'Base abstracts an amide proton to form an anion, which attacks bromine to form N-bromobenzamide.',
          curvedArrowNotes: r'$\text{OH}^-$ takes $H^+$; amide anion attacks $\text{Br}_2$.',
          intermediate: r'N-Bromobenzamide ($\text{C}_6\text{H}_5\text{CONHBr}$)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Concerted Alkyl/Aryl Migration to Isocyanate (RDS)',
          description: r'Base removes the second proton from nitrogen to form an unstable bromoamide anion. The phenyl group migrates with its bonding electrons onto nitrogen with simultaneous departure of $\text{Br}^-$, yielding phenyl isocyanate.',
          curvedArrowNotes: r'Phenyl C-C bond migrates to nitrogen as bromide leaves; forms $\text{N=C=O}$.',
          intermediate: r'Phenyl Isocyanate ($\text{C}_6\text{H}_5\text{-N=C=O}$)',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Hydrolysis & Decarboxylation to Primary Amine',
          description: r'Nucleophilic attack of water on the isocyanate forms an unstable carbamic acid, which spontaneously decarboxylates to release $\text{CO}_2$ and pure aniline.',
          curvedArrowNotes: r'Water attacks isocyanate; loss of $\text{CO}_2$ gives primary amine.',
          intermediate: r'Aniline + $\text{K}_2\text{CO}_3$',
        ),
      ],
      drivingForce: r'Irreversible loss of carbon dioxide ($\text{CO}_2$) gas / carbonate formation and thermodynamic stability of primary amine.',
      syntheticNotes: r'Standard method to prepare pure primary amines free from secondary or tertiary amine contamination.',
    );
  }

  static PredictedReactionResult _buildPinacolPinacolonePrediction() {
    return const PredictedReactionResult(
      reactionName: 'Pinacol-Pinacolone Rearrangement',
      category: 'Acid-Catalyzed Vicinal Diol Rearrangement',
      reactants: r'Pinacol (2,3-Dimethylbutane-2,3-diol)',
      reagentsAndConditions: r'Concentrated $\text{H}_2\text{SO}_4$, $100^\circ\text{C}$',
      majorProduct: 'Pinacolone (3,3-Dimethylbutan-2-one)',
      majorProductFormula: r'\text{CH}_3\text{COC(CH}_3)_3',
      minorProducts: r'Water ($\text{H}_2\text{O}$)',
      selectivity: r'Migratory Aptitude & Carbocation Stability: Protonation occurs at the oxygen that produces the more stable carbocation. The migrating group delivers its electron pair to satisfy the octet of the adjacent carbocation via oxonium ion resonance stabilization.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Protonation & Loss of Water to Tertiary Carbocation',
          description: r'Sulfuric acid protonates one of the hydroxyl groups, which departs as water to form a stable $3^\circ$ carbocation.',
          curvedArrowNotes: r'OH lone pair attacks $H^+$; $\text{H}_2\text{O}$ leaves forming $3^\circ$ carbocation.',
          intermediate: r'Tertiary Carbocation: $[\text{Me}_2\text{C(OH)}-\text{C}^+\text{Me}_2]$',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'1,2-Methyl Shift Driven by Oxonium Resonance (RDS)',
          description: r'A methyl group migrates with its bonding pair from the adjacent hydroxyl-bearing carbon to the carbocation center, driven by the lone pair on oxygen pushing in to form an exceptionally stable oxonium cation ($\text{C=O}^+\text{-H}$).',
          curvedArrowNotes: r'Oxygen lone pair forms $\text{C=O}^+$ as adjacent methyl group migrates to $C^+$.',
          intermediate: r'Protonated Pinacolone Oxonium Ion: $[\text{Me}_3\text{C}-\text{C(Me)=O}^+\text{-H}]$',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Deprotonation to Pinacolone',
          description: r'Base removes the proton from the oxonium oxygen to yield the ketone.',
          curvedArrowNotes: r'Base abstracts $H^+$ from oxygen.',
          intermediate: r'Pinacolone + $\text{H}_3\text{O}^+$',
        ),
      ],
      drivingForce: r'Formation of the exceptionally strong carbon-oxygen double bond ($\text{C=O}$, $\approx 745\text{ kJ/mol}$) and full octet stabilization on all atoms in the oxonium intermediate.',
      syntheticNotes: r'Migratory aptitude in unsymmetrical pinacols: $\text{p-Anisyl} > \text{p-Tolyl} > \text{Phenyl} > 3^\circ\text{ Alkyl} > 2^\circ\text{ Alkyl} > 1^\circ\text{ Alkyl} > \text{Methyl} > H$.',
    );
  }

  static PredictedReactionResult _buildDielsAlderPrediction(String q) {
    final isCyclopentadiene = q.contains('cyclopentadiene');

    if (isCyclopentadiene) {
      return const PredictedReactionResult(
        reactionName: 'Diels-Alder [4+2] Cycloaddition (Cyclopentadiene + Maleic Anhydride)',
        category: 'Pericyclic [4+2] Concerted Cycloaddition',
        reactants: r'Cyclopentadiene ($\text{C}_5\text{H}_6$, Diene) + Maleic Anhydride ($\text{C}_4\text{H}_2\text{O}_3$, Dienophile)',
        reagentsAndConditions: r'Room temperature ($20^\circ\text{C} - 25^\circ\text{C}$), Ethyl acetate / Benzene (Highly exothermic)',
        majorProduct: 'endo-Norbornene-cis-5,6-dicarboxylic Anhydride',
        majorProductFormula: r'\text{C}_9\text{H}_8\text{O}_3',
        minorProducts: r'exo-Isomer (trace at room temperature; increases at $> 150^\circ\text{C}$)',
        selectivity: r'Alder Endo Rule & Suprafacial Stereospecificity: 1) 100% Syn-stereospecific: cis-dienophile yields cis-ring junction. 2) The endo isomer is kinetically favored due to secondary orbital overlap between the electron-withdrawing carbonyl $\pi$-orbitals and the developing back-side $\pi$-framework of the diene.',
        mechanismSteps: [
          ReactionStep(
            stepNumber: 1,
            title: r'Concerted 6-Electron Suprafacial Pericyclic Transition State',
            description: r'The reaction occurs in a single concerted step through a cyclic 6-membered boat-like transition state involving the overlap of the diene HOMO and dienophile LUMO ($4\pi_s + 2\pi_s$, Woodward-Hoffmann allowed under thermal conditions).',
            curvedArrowNotes: r'Three pairs of curved arrows trace around the 6-membered ring: two $\pi$-bonds form two new $\sigma$-bonds and one new $\pi$-bond.',
            intermediate: r'Concerted 6-Electron Cyclic Transition State (Aromatic, $6\pi$ electrons)',
          ),
          ReactionStep(
            stepNumber: 2,
            title: r'Product Formation',
            description: r'Two new C-C $\sigma$-bonds and one new C-C $\pi$-bond are formed simultaneously with the anhydride ring oriented endo (pointing downward toward the double bond bridge).',
            curvedArrowNotes: r'Concerted collapse of transition state into bridged norbornene core.',
            intermediate: r'endo-Bicyclic Anhydride Product',
          ),
        ],
        drivingForce: r'Conversion of two weaker $\pi$-bonds ($\approx 2 \times 264\text{ kJ/mol}$) into two much stronger $\sigma$-bonds ($\approx 2 \times 347\text{ kJ/mol}$), making $\Delta H^\circ \approx -166\text{ kJ/mol}$ highly exothermic.',
        syntheticNotes: r'Classic Nobel prize-winning reaction for synthesizing 6-membered rings and bridged bicyclic frameworks in steroid and alkaloid total synthesis.',
        svgId: 'diels_alder',
      );
    }

    return const PredictedReactionResult(
      reactionName: 'Diels-Alder [4+2] Cycloaddition',
      category: 'Concerted Thermal Pericyclic Cycloaddition',
      reactants: r'1,3-Butadiene ($\text{C}_4\text{H}_6$) + Maleic Anhydride ($\text{C}_4\text{H}_2\text{O}_3$)',
      reagentsAndConditions: r'Heating ($100^\circ\text{C}$), Toluene solvent',
      majorProduct: 'cis-1,2,3,6-Tetrahydrophthalic Anhydride',
      majorProductFormula: r'\text{C}_8\text{H}_8\text{O}_3',
      minorProducts: r'None (100% atom economy)',
      selectivity: r'Concerted Stereospecific Syn-Addition: cis-dienophile yields strictly cis-substituted cyclohexene. Diene must be in the reactive s-cis conformation.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Concerted $[4\pi_s + 2\pi_s]$ Cyclic Orbital Overlap',
          description: r'Thermal pericyclic overlap of diene $\text{HOMO}$ with dienophile $\text{LUMO}$ forming two $\sigma$-bonds simultaneously.',
          curvedArrowNotes: r'Three curved arrows rotate around the hexagon to form cyclohexene core.',
          intermediate: r'Aromatic $6\pi$ Cyclic Transition State',
        ),
      ],
      drivingForce: r'Net conversion of $2\pi \rightarrow 2\sigma$ bonds ($\Delta H^\circ < 0$).',
      syntheticNotes: r'Activated by Electron-Donating Groups (EDG) on the diene ($-\text{OMe}, -\text{Me}$) and Electron-Withdrawing Groups (EWG) on the dienophile ($-\text{COR}, -\text{CN}, -\text{NO}_2$).',
      svgId: 'diels_alder',
    );
  }

  static PredictedReactionResult _buildClemmensenPrediction(String q) {
    return const PredictedReactionResult(
      reactionName: 'Clemmensen Reduction of Carbonyls',
      category: 'Acidic Carbonyl Deoxygenation',
      reactants: r'Acetophenone ($\text{C}_6\text{H}_5\text{COCH}_3$)',
      reagentsAndConditions: r'Zinc Amalgam ($\text{Zn-Hg}$) + Concentrated $\text{HCl}$, Reflux ($100^\circ\text{C}$)',
      majorProduct: 'Ethylbenzene',
      majorProductFormula: r'\text{C}_6\text{H}_5\text{CH}_2\text{CH}_3',
      minorProducts: r'Zinc Chloride ($\text{ZnCl}_2$), $\text{H}_2\text{O}$',
      selectivity: r'Complete Deoxygenation: The carbonyl group ($\text{C=O}$) is directly converted into a methylene group ($-\text{CH}_2-$) under strongly acidic reducing conditions.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Heterogeneous Electron Transfer from Zinc Surface',
          description: r'Two-electron transfer from the amalgamated zinc surface to the protonated carbonyl carbon generates a zinc-carbenoid intermediate on the metal surface.',
          curvedArrowNotes: r'Zn transfers 2 electrons to protonated carbonyl carbon.',
          intermediate: r'Organozinc / Zinc-Carbenoid surface intermediate',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Protonation & Water Cleavage',
          description: r'Acidic cleavage of the carbon-oxygen and carbon-zinc bonds yields the hydrocarbon.',
          curvedArrowNotes: r'Protonation by $\text{HCl}$ releases ethylbenzene and $\text{ZnCl}_2$.',
          intermediate: r'Ethylbenzene ($\text{C}_8\text{H}_{10}$)',
        ),
      ],
      drivingForce: r'High standard reduction potential of zinc oxidation ($\text{Zn} \rightarrow \text{Zn}^{2+} + 2e^-$).',
      syntheticNotes: r'CRITICAL EXAM LIMITATION: Fails for acid-sensitive substrates (e.g. containing acetals, epoxides, or tertiary alcohols). For acid-sensitive ketones, use the Wolff-Kishner reduction instead.',
    );
  }

  static PredictedReactionResult _buildWolffKishnerPrediction(String q) {
    return const PredictedReactionResult(
      reactionName: 'Wolff-Kishner Reduction of Carbonyls',
      category: 'Basic Carbonyl Deoxygenation',
      reactants: r'Ketone / Aldehyde ($\text{R}_2\text{C=O}$) + Hydrazine ($\text{NH}_2\text{NH}_2$)',
      reagentsAndConditions: r'Strong Base ($\text{KOH}$), High-boiling solvent (Ethylene glycol), $180^\circ\text{C} - 200^\circ\text{C}$',
      majorProduct: 'Hydrocarbon',
      majorProductFormula: r'\text{R}_2\text{CH}_2',
      minorProducts: r'Nitrogen Gas ($\text{N}_2 \uparrow$), $\text{H}_2\text{O}$',
      selectivity: r'Complete Deoxygenation in Strongly Basic Media: Ideal complement to Clemmensen reduction for acid-sensitive compounds.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Hydrazone Intermediate Formation',
          description: r'Nucleophilic attack of hydrazine on the carbonyl followed by dehydration forms the hydrazone $\text{R}_2\text{C=N-NH}_2$.',
          curvedArrowNotes: r'$\text{NH}_2\text{NH}_2$ attacks carbonyl; elimination of $\text{H}_2\text{O}$ gives hydrazone.',
          intermediate: r'Hydrazone ($\text{R}_2\text{C=N-NH}_2$)',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Base Deprotonation & Tautomerism to Diimide',
          description: r'$\text{OH}^-$ removes a proton from the hydrazone nitrogen to form a resonance-stabilized carbanion.',
          curvedArrowNotes: r'Base abstracts $N\text{-H}$; proton transfer generates carbanion.',
          intermediate: r'Diazenyl carbanion $[\text{R}_2\text{CH-N=N}^-]$',
        ),
        ReactionStep(
          stepNumber: 3,
          title: r'Irreversible Extrusion of $\text{N}_2$ Gas',
          description: r'Loss of nitrogen gas ($\text{N}_2$) generates a carbanion that is protonated by solvent to give the alkane.',
          curvedArrowNotes: r'Extrusion of $:N\equiv N:$ gas leaves carbanion; protonation gives hydrocarbon.',
          intermediate: r'Alkane + $\text{N}_2 \uparrow$',
        ),
      ],
      drivingForce: r'Immense entropic and enthalpic driving force of expelling gaseous molecular nitrogen ($\text{N}\equiv\text{N}$ triple bond energy $\approx 945\text{ kJ/mol}$).',
      syntheticNotes: r'Huang-Minlon modification uses diethylene glycol to allow a 1-pot synthesis without distilling off excess hydrazine.',
    );
  }

  static PredictedReactionResult _buildGrignardPrediction(String q) {
    return const PredictedReactionResult(
      reactionName: 'Grignard Organomagnesium Carbonyl Addition',
      category: 'Nucleophilic Carbon-Carbon Bond Formation',
      reactants: r'Methylmagnesium Bromide ($\text{CH}_3\text{MgBr}$) + Acetaldehyde ($\text{CH}_3\text{CHO}$)',
      reagentsAndConditions: r'1) Anhydrous diethyl ether or THF, $0^\circ\text{C}$; 2) Aqueous acid workup ($\text{H}_3\text{O}^+ / \text{NH}_4\text{Cl}$)',
      majorProduct: 'Propan-2-ol (Secondary Alcohol)',
      majorProductFormula: r'\text{CH}_3\text{CH(OH)CH}_3',
      minorProducts: r'Magnesium Hydroxybromide $[\text{Mg(OH)Br}]$',
      selectivity: r'General Grignard Carbonyl Rule: 1) Formaldehyde ($\text{HCHO}$) $\rightarrow 1^\circ$ Alcohol; 2) Other Aldehydes ($\text{RCHO}$) $\rightarrow 2^\circ$ Alcohol; 3) Ketones ($\text{R}_2\text{C=O}$) $\rightarrow 3^\circ$ Alcohol; 4) Carbon Dioxide ($\text{CO}_2$) $\rightarrow$ Carboxylic Acid ($\text{R-COOH}$).',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Nucleophilic Carbanion Addition',
          description: r'The strongly polarized nucleophilic alkyl carbanion ($\text{CH}_3^{\delta-}$) attacks the electrophilic carbonyl carbon via a 6-membered magnesium-coordinated transition state, opening the $\text{C=O}$ $\pi$-bond to form a magnesium alkoxide.',
          curvedArrowNotes: r'$\text{C-Mg}$ bonding electrons attack carbonyl carbon; $\text{C=O}$ opens onto $\text{Mg}^{2+}$.',
          intermediate: r'Magnesium Alkoxide Complex $[\text{CH}_3\text{CH(OMgBr)CH}_3]$',
        ),
        ReactionStep(
          stepNumber: 2,
          title: r'Aqueous Acidic Hydrolysis',
          description: r'Protonation of the alkoxide by aqueous $\text{NH}_4\text{Cl}$ releases the alcohol.',
          curvedArrowNotes: r'Alkoxide oxygen abstracts $H^+$ from $\text{H}_3\text{O}^+$.',
          intermediate: r'Secondary Alcohol + $\text{Mg(OH)Br}$',
        ),
      ],
      drivingForce: r'Conversion of weak, polar $\text{C-Mg}$ bond into a strong, stable $\text{C-C}$ covalent $\sigma$-bond ($\approx 347\text{ kJ/mol}$).',
      syntheticNotes: r'Must be conducted in strictly anhydrous conditions: Grignard reagents are extremely strong Brønsted bases and are instantly destroyed by water, alcohols, or acids to produce alkanes.',
    );
  }

  static PredictedReactionResult _buildZaitsevVsHofmannEliminationPrediction(String q) {
    final isBulky = q.contains('t-buok') || q.contains('tert-butoxide') || q.contains('bulky') || q.contains('hofmann');

    if (isBulky) {
      return const PredictedReactionResult(
        reactionName: 'Hofmann Elimination with Sterically Hindered Base',
        category: 'E2 Bimolecular Elimination',
        reactants: r'2-Bromobutane ($\text{CH}_3\text{CH(Br)CH}_2\text{CH}_3$) + Potassium tert-Butoxide ($\text{t-BuOK}$)',
        reagentsAndConditions: r'$\text{t-BuOK}$ in tert-butanol ($\text{t-BuOH}$), $75^\circ\text{C}$',
        majorProduct: r'But-1-ene (Hofmann product, $\approx 80\%$) — Less substituted alkene',
        majorProductFormula: r'\text{CH}_2\text{=CHCH}_2\text{CH}_3',
        minorProducts: r'But-2-ene (cis & trans, Zaitsev product, $\approx 20\%$), $\text{KBr}, \text{t-BuOH}$',
        selectivity: r'Hofmann Regioselectivity: The bulky, sterically hindered tert-butoxide base cannot easily access the internal secondary $\beta$-hydrogen (C3); instead, it preferentially deprotonates the accessible, unhindered primary methyl $\beta$-hydrogens (C1).',
        mechanismSteps: [
          ReactionStep(
            stepNumber: 1,
            title: r'Concerted Anti-Periplanar E2 Elimination at C1',
            description: r'The bulky base abstracts a proton from the methyl group (C1) in an anti-periplanar conformation while the bromide leaving group departs from C2 simultaneously.',
            curvedArrowNotes: r'Base abstracts C1-H; C1-H electrons form C1=C2 $\pi$-bond; C2-Br bond breaks.',
            intermediate: r'Concerted E2 Transition State',
          ),
        ],
        drivingForce: r'Steric accessibility of the primary $\beta$-hydrogen over the secondary $\beta$-hydrogen.',
        syntheticNotes: r'Key synthetic technique to direct regiochemistry to terminal alkenes.',
      );
    }

    return const PredictedReactionResult(
      reactionName: 'Zaitsev Elimination with Small Strong Base',
      category: 'E2 Bimolecular Elimination',
      reactants: r'2-Bromobutane ($\text{CH}_3\text{CH(Br)CH}_2\text{CH}_3$) + Alcoholic Potassium Hydroxide ($\text{alc. KOH}$)',
      reagentsAndConditions: r'$\text{KOH}$ in Ethanol ($\text{EtOH}$), Reflux ($80^\circ\text{C}$)',
      majorProduct: r'trans-But-2-ene (Zaitsev product, $\approx 80\%$) — More substituted, more stable alkene',
      majorProductFormula: r'\text{CH}_3\text{CH=CHCH}_3',
      minorProducts: r'cis-But-2-ene ($\approx 15\%$), But-1-ene ($\approx 5\%$), $\text{KBr}, \text{H}_2\text{O}$',
      selectivity: r'Zaitsev’s (Saytzeff’s) Rule: Elimination of $\text{HX}$ yields predominantly the more substituted, thermodynamically more stable alkene having more hyperconjugative $\alpha$-hydrogens (6 $\alpha\text{-H}$ in but-2-ene vs 2 $\alpha\text{-H}$ in but-1-ene). Trans isomer dominates over cis to minimize methyl-methyl steric repulsion.',
      mechanismSteps: [
        ReactionStep(
          stepNumber: 1,
          title: r'Concerted Anti-Periplanar E2 Elimination at C3',
          description: r'Small ethoxide/hydroxide base abstracts an internal $\beta$-proton from C3 in an anti-periplanar conformation ($180^\circ$ dihedral angle to C2-Br), forming the internal double bond.',
          curvedArrowNotes: r'Base abstracts C3-H; C3-H pair forms C2=C3 $\pi$-bond; C2-Br leaves as $\text{Br}^-$.',
          intermediate: r'Anti-Periplanar E2 Transition State',
        ),
      ],
      drivingForce: r'Thermodynamic alkene stabilization energy from hyperconjugation and alkyl substitution.',
      syntheticNotes: r'Anti-periplanar geometry ($180^\circ$) is strictly required in cyclohexyl systems (diaxial relationship between H and leaving group X).',
    );
  }

  static PredictedReactionResult _generateDynamicPrediction(String q, String originalQuery) {
    return PredictedReactionResult(
      reactionName: 'Chemical Reaction Prediction & Mechanism Analysis',
      category: 'Organic Reaction Mechanism & Product Solver',
      reactants: originalQuery.contains('+') ? originalQuery.split('+').first.trim() : 'Reactant Substrates',
      reagentsAndConditions: 'Standard Laboratory Conditions & Reagents',
      majorProduct: 'Predicted Major Organic Product',
      majorProductFormula: r'\text{Target Product}',
      minorProducts: 'Inorganic byproducts & regioisomeric fractions',
      selectivity: r'Governed by fundamental physical organic chemistry principles: electronic distribution (electrophile-nucleophile pairing), steric accessibility, intermediate stability (carbocation, free-radical, or carbanion resonance), and orbital symmetry.',
      mechanismSteps: const [
        ReactionStep(
          stepNumber: 1,
          title: 'Active Species Generation & Polarization',
          description: r'Activation of the substrate or reagent by acid/base or catalyst to generate the reactive electrophilic or nucleophilic center.',
          curvedArrowNotes: r'Electron flow from highest occupied molecular orbital (HOMO) to lowest unoccupied molecular orbital (LUMO).',
          intermediate: r'Reactive Intermediate / Polarized Complex',
        ),
        ReactionStep(
          stepNumber: 2,
          title: 'Nucleophilic Attack / Bond Rearrangement (Rate-Determining Step)',
          description: r'Attack of the nucleophilic electron pair onto the electrophilic center to forge the primary $\sigma$-bond.',
          curvedArrowNotes: r'Curved arrow depicts displacement of electron pairs.',
          intermediate: r'Resonance-Stabilized Intermediate',
        ),
        ReactionStep(
          stepNumber: 3,
          title: 'Proton Transfer / Elimination to Stable Product',
          description: r'Loss of leaving group or proton transfer to yield the neutral, thermodynamically favored end-product.',
          curvedArrowNotes: r'Restoration of octet and catalyst recovery.',
          intermediate: r'Final Product',
        ),
      ],
      drivingForce: r'Thermodynamic enthalpy of forming stronger $\sigma$-bonds and entropy factors.',
      syntheticNotes: r'Ensure anhydrous or inert conditions if organometallic reagents are utilized.',
    );
  }
}

class _ReactionPatternHandler {
  final bool Function(String q) matcher;
  final PredictedReactionResult Function(String q) generator;

  _ReactionPatternHandler({required this.matcher, required this.generator});

  bool matches(String q) => matcher(q);
  PredictedReactionResult generate(String q) => generator(q);
}
