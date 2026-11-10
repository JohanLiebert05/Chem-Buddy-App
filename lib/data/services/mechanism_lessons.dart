import '../../core/chemistry/mechanism_flow_frame.dart';
import '../../core/chemistry/reaction_center_drawings.dart';
import '../models/reaction_models.dart';
import 'mechanism_lesson_steps.dart';
import 'predictor_mechanism_frames.dart';

/// Authored reaction-center explanations for entries without atom-resolved art.
/// Keys are the stable Library and predictor catalog IDs.
abstract final class MechanismLessons {
  static List<ReactionStep>? librarySteps(String id) => _librarySteps[id];

  static List<ReactionStep>? predictorSteps(String id) =>
      _predictorSteps[id] ?? librarySteps(_predictorLibrary[id] ?? '');

  static String? libraryIdForPredictor(String id) => _predictorLibrary[id];

  static bool hasPredictorLesson(String id) =>
      _predictorSteps.containsKey(id) || _predictorLibrary.containsKey(id);

  static final _librarySteps = _buildSteps(_library);
  static final _predictorSteps = _buildSteps(predictorMechanismFrames);

  static Map<String, List<ReactionStep>> _buildSteps(
    Map<String, List<MechanismFlowFrame>> lessons,
  ) => lessons.map(
    (id, frames) => MapEntry(id, [
      for (final (index, frame) in frames.indexed) frame.toStep(index + 1),
    ]),
  );

  static const _predictorLibrary = {
    'RXN_SN1_001': 'sn1',
    'RXN_SN2_001': 'sn2',
    'RXN_E1_001': 'e1',
    'RXN_E2_001': 'e2',
    'RXN_ALDOL_COND_001': 'aldol',
    'RXN_CLAISEN_001': 'claisen',
    'RXN_MICHAEL_001': 'michael',
    'RXN_CANNIZZARO_001': 'cannizzaro',
    'RXN_GRIGNARD_ALD_001': 'grignard',
    'RXN_WITTIG_001': 'wittig',
    'RXN_DIELS_ALDER_001': 'diels_alder',
    'RXN_BAEYER_VILLIGER_001': 'baeyer_villiger',
    'RXN_BECKMANN_001': 'beckmann',
    'RXN_PINACOL_001': 'pinacol',
  };

  static final _library = <String, List<MechanismFlowFrame>>{
    'michael': [enolate(), michaelAttack(), protonateEnolate()],
    'claisen': [
      enolate('Ester enolate formation'),
      carbonylAddition('Ester enolate → ester', 'Ester enolate carbon'),
      acylCollapse('Ethoxy oxygen'),
      flow(
        'Product deprotonation',
        'Alkoxide removes the acidic proton between the two carbonyls. Acidic workup returns the neutral β-keto ester.',
        [
          ('Alkoxide O lone pair', 'β-Keto ester α-H'),
          ('α-C–H σ bond', 'Delocalized enolate'),
        ],
      ),
    ],
    'baeyer_villiger': [
      flow(
        'Criegee intermediate',
        'The terminal peroxy oxygen adds to an acid-activated ketone. Proton transfer prepares the carboxylate leaving group.',
        [
          ('Peroxy OH oxygen lone pair', 'Activated carbonyl carbon'),
          ('Carbonyl π bond', 'Carbonyl oxygen'),
        ],
      ),
      flow(
        'Concerted migration',
        'The migrating carbon group moves with its bonding pair as the O–O bond breaks. Carbonyl re-formation gives a protonated ester or lactone.',
        [
          ('Migrating C–C σ bond', 'New C–O bond'),
          ('Peroxide O–O σ bond', 'Carboxylate leaving oxygen'),
          ('Hydroxyl O lone pair', 'Re-forming C=O π bond'),
        ],
      ),
      change(
        'Ester or lactone',
        'Proton transfer gives the neutral product. Oxygen is inserted beside the carbonyl.',
        'Protonated ester',
        'Neutral ester or lactone',
      ),
    ],
    'favorskii': favorskiiFrames,
    'favorskii_rearrangement': favorskiiFrames,
    'mannich': [
      carbonylAddition('Amine adds to aldehyde', 'Amine N lone pair'),
      flow(
        'Iminium formation',
        'After proton transfers, the protonated hemiaminal loses water as the nitrogen lone pair forms the iminium bond.',
        [
          ('Amine N lone pair', 'C=N π bond'),
          ('C–OH₂⁺ σ bond', 'Departing water oxygen'),
        ],
      ),
      flow(
        'Enol traps the iminium',
        'The enol attacks the iminium carbon. Re-forming the carbonyl and proton transfers furnish the β-amino carbonyl.',
        [
          ('Enol C=C π bond', 'Iminium carbon'),
          ('Iminium C=N π bond', 'Iminium nitrogen'),
          ('Enol O lone pair', 'Re-forming C=O π bond'),
        ],
      ),
    ],
    'pinacol': [
      flow(
        'Water leaves',
        'Acid converts one hydroxyl group into a water leaving group. C–O cleavage opens the site for migration.',
        [('C–OH₂⁺ σ bond', 'Departing water oxygen')],
      ),
      flow(
        '1,2-Methyl shift',
        'The adjacent C–Me bond migrates toward the cationic carbon as the remaining oxygen forms a carbonyl.',
        [
          ('Adjacent C–Me σ bond', 'Cationic carbon'),
          ('Remaining OH lone pair', 'C=O π bond'),
        ],
      ),
      deprotonate(
        'Pinacolone formation',
        'Oxonium O–H σ bond',
        'Carbonyl oxygen',
      ),
    ],
    'robinson': [
      michaelAttack(),
      carbonylAddition(
        'Intramolecular aldol closure',
        'Tethered enolate carbon',
      ),
      e1cbElimination('Dehydration to a cyclohexenone'),
    ],
    'curtius': [
      flow(
        'Acyl azide rearranges',
        'In the thermal pathway the acyl substituent migrates to the nitrogen attached to the carbonyl as N₂ is expelled. The product is an isocyanate.',
        [
          ('Acyl C–R σ bond', 'Acyl-bound nitrogen'),
          ('Acyl-bound N–N σ bond', 'Departing N₂ fragment'),
          ('Acyl-bound N lone pair', 'Isocyanate C=N π bond'),
        ],
      ),
      flow(
        'Water adds to isocyanate',
        'Water attacks the central carbon. Proton transfers lead to carbamic acid, which decarboxylates to the amine.',
        [
          ('Water O lone pair', 'Isocyanate carbon'),
          ('Isocyanate C=N π bond', 'Isocyanate nitrogen'),
        ],
      ),
      change(
        'Decarboxylation',
        'Carbamic acid loses carbon dioxide after hydration and proton transfer.',
        'Carbamic acid',
        'Primary amine + CO₂',
      ),
    ],
    'cope': [
      flow(
        'Concerted [3,3] shift',
        'Number the starting 1,5-diene C1 through C6. All three transfers occur in the same elementary step.',
        [
          ('C1=C2 π bond', 'New C1–C6 σ bond'),
          ('C5=C6 π bond', 'New C4=C5 π bond'),
          ('C3–C4 σ bond', 'New C2=C3 π bond'),
        ],
        drawing: ReactionCenterDrawings.sigmatropic(oxygen: false),
      ),
    ],
    'claisen_sigmatropic': [
      flow(
        'Concerted [3,3] shift',
        'Number the chain C1=C2–O3–C4–C5=C6. This is the allyl vinyl ether example. The cyclic electron shift produces an unsaturated carbonyl.',
        [
          ('C1=C2 π bond', 'New C1–C6 σ bond'),
          ('C5=C6 π bond', 'New C4=C5 π bond'),
          ('O3–C4 σ bond', 'New C2=O3 π bond'),
        ],
        drawing: ReactionCenterDrawings.sigmatropic(oxygen: true),
      ),
      change(
        'Aryl ether variant',
        'An allyl aryl ether first forms a dearomatized carbonyl product. Tautomerization restores aromaticity.',
        'Cyclohexadienone',
        'Ortho-allyl phenol',
      ),
    ],
    'fischer_indole': [
      carbonylAddition('Hydrazone precursor', 'Terminal hydrazine N'),
      change(
        'Enehydrazine formation',
        'Condensation gives the hydrazone. Acid-catalyzed tautomerization generates the enehydrazine required for rearrangement.',
        'Arylhydrazone',
        'Protonated enehydrazine',
      ),
      flow(
        'Fischer [3,3] rearrangement',
        'The six-atom array is ortho-C–ipso-C–N–N–C–C. A cyclic redistribution breaks the N–N bond and forms the new ortho C–C bond.',
        [
          ('Aryl ortho–ipso π bond', 'Ipso C=N π bond'),
          ('N–N σ bond', 'Second C=N π bond'),
          ('Enehydrazine C=C π bond', 'New ortho C–C σ bond'),
        ],
      ),
      flow(
        'Ring closure',
        'After rearomatization, the aryl-bound nitrogen attacks the iminium carbon. Proton transfers and ammonia loss give the aromatic indole.',
        [
          ('Aryl-bound N lone pair', 'Iminium carbon'),
          ('Iminium C=N π bond', 'Departing-group nitrogen'),
        ],
      ),
    ],
    'paal_knorr': [
      carbonylAddition('Hemiaminal formation', 'Amine N lone pair'),
      carbonylAddition('Five-membered ring closure', 'Tethered N lone pair'),
      change(
        'Dehydration and aromatization',
        'In this hemiaminal pathway, proton transfer and two net water losses furnish the pyrrole. The order can depend on substrate and conditions.',
        'Cyclic oxygenated intermediates',
        'Pyrrole + 2 H₂O',
      ),
    ],
    'chichibabin': [
      flow(
        'Addition at pyridine C2',
        'Amide adds at C2 and gives a dearomatized anionic σ-adduct.',
        [
          ('Amide N lone pair', 'Pyridine C2'),
          ('Pyridine N=C2 π bond', 'Ring nitrogen'),
        ],
      ),
      flow(
        'Hydride loss restores aromaticity',
        'The anionic ring reforms N=C2 as C2 loses hydride. Hydrogen can form by proton transfer to hydride.',
        [
          ('Ring N lone pair', 'Re-forming N=C2 π bond'),
          ('C2–H σ bond', 'Departing H⁻'),
        ],
      ),
      change(
        'Aqueous workup',
        'Workup protonates any deprotonated aminopyridine.',
        'Aminopyridine anion',
        '2-Aminopyridine',
      ),
    ],
    'oxidative_addition': [ligandLoss, oxidativeAddition],
    'migratory_insertion': [
      coInsertion,
      change(
        'Ligand capture',
        'A donor ligand binds the coordinatively unsaturated acyl complex. CO insertion itself does not change the metal oxidation state.',
        'Unsaturated metal acyl',
        'Ligand-bound metal acyl',
      ),
    ],
    'reductive_elimination': [
      change(
        'Cis alignment',
        'For the representative square-planar coupling, the two groups to be joined occupy adjacent sites before elimination.',
        'Trans R groups',
        'Cis R groups',
      ),
      reductiveElimination,
    ],
    'sharpless_epoxidation': [
      change(
        'Chiral catalyst assembly',
        'Titanium alkoxide and a tartrate ester generate a chiral catalyst. The active aggregation state can depend on conditions.',
        'Ti alkoxide + tartrate',
        'Chiral titanium complex',
      ),
      change(
        'Substrate and oxidant bind',
        'The allylic alcohol binds through oxygen and is positioned near activated hydroperoxide.',
        'Allylic alcohol + ROOH',
        'Bound alkoxide / peroxide',
      ),
      change(
        'Face-selective oxygen transfer',
        'The bound peroxide transfers oxygen to the alkene. The tartrate environment controls the favored face.',
        'Bound allylic alkene',
        'Enantioenriched epoxide',
      ),
    ],
    'suzuki_coupling': [
      oxidativeAddition,
      change(
        'Transmetalation',
        'Base enables transfer of the organic group from boron to palladium. Pd remains in the same formal oxidation state during this step.',
        'Ar–Pd(II)–X + Ar′–B',
        'Ar–Pd(II)–Ar′',
      ),
      reductiveElimination,
    ],
    'mitsunobu_reaction': [
      flow(
        'Phosphine adds to the azo reagent',
        'Triphenylphosphine and the azodicarboxylate form a phosphonium betaine.',
        [
          ('Phosphine P lone pair', 'Electrophilic azo nitrogen'),
          ('Azo N=N π bond', 'Distal azo nitrogen'),
        ],
      ),
      change(
        'Alcohol activation',
        'Acid–base and substitution steps generate the conjugate-base nucleophile and an alkoxyphosphonium leaving group.',
        'Alcohol + acidic Nu–H',
        'Alkoxyphosphonium + Nu⁻',
      ),
      flow(
        'Backside displacement',
        'The nucleophile displaces the oxyphosphonium group. A stereogenic reacting carbon undergoes inversion.',
        [
          ('Nucleophile lone pair', 'Alcohol-derived carbon'),
          ('Substrate C–O σ bond', 'Oxyphosphonium oxygen'),
        ],
      ),
    ],
    'swern_oxidation': [
      change(
        'DMSO activation',
        'DMSO reacts with oxalyl chloride, forming chlorodimethylsulfonium chloride with release of CO and CO₂.',
        'DMSO + oxalyl chloride',
        'Me₂SCl⁺ Cl⁻ + CO + CO₂',
      ),
      flow(
        'Alkoxysulfonium formation',
        'Alcohol oxygen attacks sulfur and chloride leaves. Proton transfer affords an alkoxysulfonium salt.',
        [
          ('Alcohol O lone pair', 'Activated sulfur'),
          ('S–Cl σ bond', 'Chloride'),
        ],
      ),
      change(
        'Ylide and elimination',
        'Base forms the sulfur ylide. Its intramolecular elimination gives the carbonyl compound and dimethyl sulfide.',
        'Alkoxysulfonium salt',
        'Carbonyl compound + Me₂S',
      ),
    ],
    'birch_reduction': [
      flow(
        'First single-electron transfer',
        'A solvated electron enters the aromatic π system and generates a radical anion.',
        [('Solvated electron', 'Arene π* orbital')],
        singleElectron: true,
      ),
      change(
        'Protonation',
        'Alcohol protonates the radical anion to give a neutral cyclohexadienyl radical.',
        'Arene radical anion',
        'Cyclohexadienyl radical',
      ),
      flow(
        'Second single-electron transfer',
        'Reduction of the carbon radical generates an anion. This is a separate electron transfer.',
        [('Solvated electron', 'Cyclohexadienyl radical')],
        singleElectron: true,
      ),
      flow(
        'Final protonation',
        'The carbanion takes a proton from alcohol to yield a nonconjugated 1,4-diene.',
        [
          ('Carbanion electron pair', 'Alcohol proton'),
          ('Alcohol O–H σ bond', 'Alcohol oxygen'),
        ],
      ),
    ],
    'heck_coupling': [
      oxidativeAddition,
      change(
        'Alkene insertion',
        'The alkene coordinates and inserts into the Pd–aryl bond. A new C–C bond and a Pd–alkyl bond form by syn addition.',
        'Ar–Pd(II) + alkene',
        'Pd(II)–alkyl',
      ),
      change(
        'β-H elimination',
        'A syn-coplanar β-hydrogen transfers to Pd, generating the substituted alkene. Base helps regenerate Pd(0).',
        'Pd(II)–alkyl',
        'Substituted alkene + Pd–H',
      ),
    ],
    'corey_chaykovsky': [
      deprotonate(
        'Sulfur ylide formation',
        'Sulfonium C–H σ bond',
        'Ylide carbon',
      ),
      carbonylAddition('Betaine formation', 'Sulfur ylide carbon'),
      flow(
        'Epoxide closure',
        'The alkoxide attacks the carbon attached to sulfur in an intramolecular SN2 step.',
        [
          ('Alkoxide O lone pair', 'Carbon bonded to sulfur'),
          ('C–S σ bond', 'Departing sulfur group'),
        ],
      ),
    ],
    'stille_coupling': [
      oxidativeAddition,
      change(
        'Transmetalation',
        'An organic group transfers from tin to palladium. The ligands and conditions control the transfer pathway.',
        'Ar–Pd(II)–X + R–SnR₃',
        'Ar–Pd(II)–R',
      ),
      reductiveElimination,
    ],
  };
}
