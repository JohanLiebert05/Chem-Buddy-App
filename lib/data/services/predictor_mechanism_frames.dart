import '../../core/chemistry/mechanism_flow_frame.dart';
import 'mechanism_lesson_steps.dart';

final predictorMechanismFrames = <String, List<MechanismFlowFrame>>{
  'RXN_ALDOL_001': [
    enolate(),
    carbonylAddition('Aldol C–C bond formation', 'Enolate carbon'),
    protonateAlkoxide,
  ],
  'RXN_E1CB_001': [enolate(), e1cbElimination('Expel hydroxide')],
  'RXN_DIECKMANN_001': [
    enolate('Generate the diester enolate'),
    carbonylAddition('Intramolecular ester attack', 'Tethered enolate carbon'),
    acylCollapse('Alkoxide oxygen'),
    change(
      'Acid workup',
      'The cyclic β-keto ester is trapped as its enolate under the basic reaction conditions. Acid workup protonates the enolate.',
      'Cyclic β-keto ester enolate',
      'Neutral cyclic β-keto ester',
    ),
  ],
  'RXN_GRIGNARD_EST_001': [
    carbonylAddition('First addition to the ester', 'Grignard C–Mg bond pair'),
    acylCollapse('Ester alkoxy oxygen'),
    carbonylAddition(
      'Second addition to the ketone',
      'Grignard C–Mg bond pair',
    ),
    protonateAlkoxide,
  ],
  'RXN_ESTER_FISCHER_001': [
    flow(
      'Carbonyl activation',
      'A protonated carbonyl is more electrophilic.',
      [
        ('Carbonyl O lone pair', 'Acid proton'),
        ('Acid X–H σ bond', 'Acid conjugate base'),
      ],
    ),
    carbonylAddition('Alcohol addition', 'Alcohol O lone pair'),
    flow(
      'Water loss',
      'Proton transfers convert one hydroxyl into a water leaving group. Collapse gives a protonated ester.',
      [
        ('Tetrahedral O lone pair', 'Re-forming C=O π bond'),
        ('Acyl C–OH₂⁺ σ bond', 'Departing water oxygen'),
      ],
    ),
    deprotonate(
      'Regenerate acid catalyst',
      'Ester oxonium O–H σ bond',
      'Carbonyl oxygen',
    ),
  ],
  'RXN_ACYL_CHLOR_001': [
    carbonylAddition(
      'Alcohol adds to the acyl chloride',
      'Alcohol O lone pair',
    ),
    acylCollapse('Departing chloride'),
    deprotonate('Ester formation', 'Oxonium O–H σ bond', 'Ester alkoxy oxygen'),
  ],
  'RXN_AMIDE_FORM_001': [
    carbonylAddition('Amine adds to activated acyl group', 'Amine N lone pair'),
    acylCollapse('Leaving-group atom'),
    deprotonate(
      'Neutral amide formation',
      'Acylammonium N–H σ bond',
      'Amide nitrogen',
    ),
  ],
  'RXN_EAS_NITRATION_001': [
    flow(
      'Nitronium formation',
      'Acid protonates nitric acid. Water leaves from protonated nitric acid while an oxygen lone pair helps form the second N=O bond.',
      [
        ('N–OH₂⁺ σ bond', 'Departing water oxygen'),
        ('Anionic oxygen lone pair', 'Second N=O π bond'),
      ],
    ),
    flow(
      'Arene captures nitronium',
      'An arene π pair forms C–N. One nitronium π pair moves to oxygen as the arenium ion forms.',
      [
        ('Arene π bond', 'Nitronium nitrogen'),
        ('One nitronium N=O π bond', 'Nitronium oxygen'),
      ],
    ),
    restoreArene,
  ],
  'RXN_EAS_HALOGENATION_001': [
    change(
      'Polarize the halogen',
      'A Lewis acid such as FeBr₃ activates Br₂. A free bromine cation is unnecessary in this representation.',
      'Br₂ + FeBr₃',
      'Lewis-acid activated Br₂',
    ),
    flow(
      'Arene attacks activated bromine',
      'The ring attacks the more electrophilic bromine and forms an arenium ion.',
      [
        ('Arene π bond', 'Electrophilic bromine'),
        ('Br–Br σ bond', 'Lewis-acid bound bromine'),
      ],
    ),
    restoreArene,
  ],
  'RXN_FC_ALKYLATION_001': [
    change(
      'Activate the alkyl halide',
      'A Lewis acid polarizes the C–X bond. Whether a discrete carbocation forms depends on the substrate and conditions.',
      'R–X + AlCl₃',
      'Activated alkyl electrophile',
    ),
    flow(
      'C–C bond formation',
      'The arene captures the alkyl electrophile to form a σ-complex. Carbocation-like electrophiles can rearrange.',
      [('Arene π bond', 'Electrophilic alkyl carbon')],
    ),
    restoreArene,
  ],
  'RXN_FC_ACYLATION_001': [
    change(
      'Acylium formation',
      'The Lewis acid assists halide departure from the acyl chloride.',
      'RCOCl + AlCl₃',
      'Acylium + AlCl₄⁻',
    ),
    flow(
      'Arene captures the acylium',
      'An arene π pair adds to the acyl carbon. For the triple-bond resonance form, one C≡O π pair moves to oxygen.',
      [
        ('Arene π bond', 'Acylium carbon'),
        ('One acylium C≡O π pair', 'Acylium oxygen'),
      ],
    ),
    restoreArene,
    change(
      'Aqueous workup',
      'Workup releases the aryl ketone from its Lewis acid complex.',
      'Lewis-acid-bound ketone',
      'Aryl ketone',
    ),
  ],
  'RXN_NABH4_RED_001': [
    carbonylAddition('Borohydride addition', 'Borohydride B–H σ bond'),
    protonateAlkoxide,
  ],
  'RXN_LIALH4_RED_001': [
    carbonylAddition('First hydride adds to the ester', 'Al–H σ bond'),
    acylCollapse('Ester alkoxy oxygen'),
    carbonylAddition('Second hydride adds to the aldehyde', 'Al–H σ bond'),
    change(
      'Aqueous workup',
      'Workup protonates both alkoxides. The acyl portion gives a primary alcohol, and the ester alkoxy group gives its corresponding alcohol.',
      'Aluminium-bound alkoxides',
      'Primary alcohol + R′OH',
    ),
  ],
  'RXN_PCC_OXID_001': [
    change(
      'Chromate ester formation',
      'The alcohol forms a chromate ester under the reaction conditions.',
      'Alcohol + Cr(VI) reagent',
      'Chromate ester',
    ),
    flow(
      'Carbonyl formation',
      'Base removes the hydrogen on the oxygen-bearing carbon. The C–H electrons form C=O as the O–Cr bond breaks.',
      [
        ('Base lone pair', 'H on alcohol carbon'),
        ('Alcohol carbon C–H σ bond', 'New C=O π bond'),
        ('O–Cr σ bond', 'Chromium leaving fragment'),
      ],
    ),
  ],
  'RXN_EPOXIDATION_001': [
    change(
      'Concerted oxygen transfer',
      'The alkene accepts the terminal peroxy oxygen. Two C–O bonds form as the O–O bond breaks in one concerted step. The alkene geometry is retained in the epoxide.',
      'Alkene + peroxyacid',
      'Epoxide + carboxylic acid',
    ),
  ],
  'RXN_HYDROBORATION_001': [
    flow(
      'Syn B–H addition',
      'Boron bonds to the less hindered carbon in the common terminal-alkene case. The B–H bond transfers hydrogen to the other carbon in the same step.',
      [('Alkene C=C π bond', 'Boron'), ('B–H σ bond', 'Other alkene carbon')],
    ),
    flow(
      'Oxidation and migration',
      'Hydroperoxide adds to boron. Alkyl migration to oxygen and O–O cleavage occur with retention at the migrating carbon.',
      [
        ('Migrating B–C σ bond', 'B-bound peroxide oxygen'),
        ('Peroxide O–O σ bond', 'Departing hydroxide oxygen'),
      ],
    ),
    change(
      'Hydrolysis',
      'Hydrolysis releases the alcohol from boron.',
      'Alkoxyborane',
      'Alcohol',
    ),
  ],
  'RXN_OXYMERCURATION_001': [
    change(
      'Mercurinium ion formation',
      'The alkene reacts with electrophilic Hg(II) to form a bridged mercurinium ion.',
      'Alkene + Hg(II)',
      'Bridged mercurinium ion',
    ),
    flow(
      'Water opens the bridge',
      'Water attacks the more substituted carbon in the common case. The corresponding C–Hg bond opens, followed by deprotonation.',
      [
        ('Water O lone pair', 'More substituted carbon'),
        ('Attacked C–Hg σ bond', 'Mercury'),
      ],
    ),
    change(
      'Demercuration',
      'Borohydride replaces the carbon–mercury bond with C–H. The demercuration step can involve radicals.',
      'Organomercury alcohol',
      'Alcohol',
    ),
  ],
  'RXN_CAT_HYDROGENATION_001': [
    change(
      'Adsorption',
      'In heterogeneous hydrogenation, H₂ dissociates on the catalyst surface and the alkene adsorbs.',
      'Alkene + H₂',
      'Surface-bound alkene + H',
    ),
    change(
      'Hydrogen delivery',
      'Surface hydrogen is added to the adsorbed alkene. Addition is commonly syn. The saturated product desorbs.',
      'Surface-bound alkene + H',
      'Saturated product',
    ),
  ],
  'RXN_DIAZOTIZATION_001': [
    change(
      'Nitrosating species formation',
      'Acid converts nitrite to nitrous acid and generates a nitrosating electrophile, represented here as NO⁺.',
      'Nitrite + acid',
      'Nitrosonium electrophile',
    ),
    flow(
      'N-nitrosation',
      'The aromatic amine attacks nitrosonium at nitrogen. Proton transfer gives the N-nitrosamine.',
      [
        ('Arylamine N lone pair', 'Nitrosonium nitrogen'),
        ('One N≡O π pair', 'Nitrosonium oxygen'),
      ],
    ),
    change(
      'Diazonium formation',
      'Proton transfers give the diazohydroxide. Protonation and water loss afford the arenediazonium ion.',
      'N-nitrosamine',
      'Arenediazonium ion',
    ),
  ],
  'RXN_SANDMEYER_001': [
    flow(
      'Copper-mediated reduction',
      'Cu(I) transfers an electron to the arenediazonium species. Nitrogen extrusion generates an aryl radical.',
      [('Cu(I) electron', 'Arenediazonium acceptor')],
      singleElectron: true,
    ),
    change(
      'Group transfer',
      'The aryl radical acquires halogen or cyanide in the copper-mediated pathway. Details depend on the copper reagent and conditions.',
      'Aryl radical + copper species',
      'Ar–X or Ar–CN + N₂',
    ),
  ],
  'RXN_KNOEVENAGEL_001': [
    enolate('Activate the methylene donor'),
    carbonylAddition('Addition to the aldehyde', 'Active-methylene carbanion'),
    change(
      'Dehydration',
      'Proton transfer and elimination give the conjugated alkene. This describes the direct base-catalyzed pathway. Amine catalysts may use additional iminium steps.',
      'β-Hydroxy intermediate',
      'Conjugated alkene + H₂O',
    ),
  ],
};

final protonateAlkoxide = flow(
  'Protonate the alkoxide',
  'A protic donor transfers a proton to oxygen during workup.',
  [
    ('Alkoxide O lone pair', 'Protic donor H'),
    ('Donor X–H σ bond', 'Donor heteroatom'),
  ],
);

final restoreArene = flow(
  'Restore aromaticity',
  'Base removes the proton from the substituted ring carbon. The C–H pair restores the aromatic π system.',
  [
    ('Base lone pair', 'H on substituted carbon'),
    ('Arenium C–H σ bond', 'Restored arene π bond'),
  ],
);
