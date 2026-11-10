import '../../core/chemistry/mechanism_flow_frame.dart';
import '../../core/chemistry/reaction_center_drawings.dart';

MechanismFlowFrame enolate([String title = 'Enolate formation']) => flow(
  title,
  'Base removes the α-proton. The carbonyl π pair shifts to oxygen in the O-enolate representation.',
  [
    ('Base lone pair', 'α-H next to carbonyl'),
    ('α-C–H σ bond', 'Cα–carbonyl C π bond'),
    ('C=O π bond', 'Carbonyl oxygen'),
  ],
  drawing: ReactionCenterDrawings.enolate(),
);

MechanismFlowFrame carbonylAddition(String title, String donor) => flow(
  title,
  'The donor attacks the carbonyl carbon while the carbonyl π pair moves to oxygen.',
  [(donor, 'Carbonyl carbon'), ('C=O π bond', 'Carbonyl oxygen')],
  drawing:
      const {
        'Aldol C–C bond formation',
        'Betaine formation',
        'Addition to the aldehyde',
        'Hemiaminal formation',
        'Amine adds to aldehyde',
      }.contains(title)
      ? ReactionCenterDrawings.carbonylAddition(donor)
      : null,
);

MechanismFlowFrame michaelAttack() => flow(
  'Conjugate addition',
  'The carbon nucleophile adds at the β-carbon of the conjugated acceptor. The π system reorganizes to an enolate.',
  [
    ('Donor enolate carbon', 'Acceptor β-carbon'),
    ('Acceptor Cα=Cβ π bond', 'Cα–carbonyl C π bond'),
    ('Acceptor C=O π bond', 'Acceptor oxygen'),
  ],
  drawing: ReactionCenterDrawings.michael(),
);

MechanismFlowFrame protonateEnolate() => flow(
  'Protonation of the enolate',
  'The carbon resonance form takes a proton from a protic donor, giving the neutral carbonyl.',
  [
    ('Enolate carbon', 'Protic donor H'),
    ('Donor X–H σ bond', 'Donor heteroatom'),
  ],
);

MechanismFlowFrame acylCollapse(String leavingOxygen) => flow(
  'Tetrahedral intermediate collapses',
  'The oxygen lone pair restores the carbonyl while the leaving group takes its bond pair.',
  [
    ('Tetrahedral O lone pair', 'Re-forming C=O π bond'),
    ('Acyl–leaving group σ bond', leavingOxygen),
  ],
);

MechanismFlowFrame deprotonate(String title, String bond, String destination) =>
    flow(
      title,
      'A base accepts the proton as the original X–H bonding pair stays with the deprotonated site.',
      [('Base lone pair', 'Proton'), (bond, destination)],
    );

MechanismFlowFrame e1cbElimination(String title) => flow(
  title,
  'The carbon-centered enolate resonance form reforms the alkene while hydroxide leaves. The resulting alkene is conjugated with the carbonyl.',
  [
    ('α-Carbanion electron pair', 'Cα=Cβ π bond'),
    ('Cβ–O σ bond', 'Departing hydroxide oxygen'),
  ],
);

final favorskiiFrames = [
  enolate('Enolization away from halogen'),
  flow(
    'Cyclopropanone formation',
    'The carbon-centered enolate attacks the α-halo carbon intramolecularly. Loss of halide closes the three-membered ring.',
    [
      ('Enolate carbon electron pair', 'α-Carbon bearing halogen'),
      ('C–halogen σ bond', 'Departing halide'),
    ],
  ),
  carbonylAddition('Nucleophile traps cyclopropanone', 'Alkoxide O lone pair'),
  flow(
    'Ring opening',
    'Carbonyl re-formation cleaves a ring C–C bond. Protonation of the resulting carbanion gives the rearranged derivative.',
    [
      ('Tetrahedral O lone pair', 'Re-forming C=O π bond'),
      ('Ring C–C σ bond', 'Carbon at opened end'),
    ],
  ),
];

final ligandLoss = change(
  'Ligand dissociation',
  'Loss of a ligand can expose a site on the metal. The formal oxidation state stays the same.',
  'Saturated metal complex',
  'Unsaturated metal + ligand',
);
final oxidativeAddition = change(
  'Oxidative addition',
  'For the representative two-electron oxidative addition, the metal inserts into R–X and forms M–R and M–X. Its formal oxidation state increases by two.',
  'M + R–X',
  'R–M–X',
);
final coInsertion = flow(
  'Alkyl migration to coordinated CO',
  'A cis alkyl migrates onto the carbon of coordinated CO. The metal remains bonded to the new acyl ligand.',
  [('Metal–alkyl σ bond', 'Carbon of cis CO ligand')],
);
final reductiveElimination = change(
  'Reductive elimination',
  'The adjacent groups couple and leave the metal. The formal oxidation state decreases by two in this representative two-electron step.',
  'R–M–R′',
  'R–R′ + M',
);
