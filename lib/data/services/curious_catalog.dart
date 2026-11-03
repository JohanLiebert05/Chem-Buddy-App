import 'dart:math';

import 'organic_curriculum.dart';
import 'spectroscopy_service.dart';

class CuriousTopic {
  const CuriousTopic(
    this.id,
    this.level,
    this.theme,
    this.question,
    this.answer,
    this.molecule,
  );
  final String id, theme, question, answer;
  final int level;
  final SpectroscopyCompoundEntry molecule;
  String get diagram => organicLessons[level - 1].diagram;
}

SpectroscopyCompoundEntry _m(String name, String formula, String smiles) =>
    SpectroscopyCompoundEntry(
      formula: formula,
      commonName: name,
      iupacName: name,
      structure: name,
      smiles: smiles,
      dbe: SpectroscopyService.parseFormula(formula).dbe,
      diagnosticIr: const [],
      nmr1H: const [],
      nmr13C: const [],
      msFragmentation: const [],
      alternativeIsomersRuledOut: const [],
      definitiveReasoning: '',
    );
final _benzene = _m('Benzene', 'C6H6', 'c1ccccc1');
final _methane = _m('Methane', 'CH4', 'C');
final _ethene = _m('Ethene', 'C2H4', 'C=C');
final _ethanol = _m('Ethanol', 'C2H6O', 'CCO');
final _acetone = _m('Propanone', 'C3H6O', 'CC(=O)C');
final _acid = _m('Ethanoic acid', 'C2H4O2', 'CC(=O)O');
final _bromoethane = _m('Bromoethane', 'C2H5Br', 'CCBr');
final _butadiene = _m('Buta-1,3-diene', 'C4H6', 'C=CC=C');
final _cyclohexane = _m('Cyclohexane', 'C6H12', 'C1CCCCC1');

CuriousTopic _t(
  int number,
  int level,
  String theme,
  String q,
  String a,
  SpectroscopyCompoundEntry m,
) => CuriousTopic('curious_$number', level, theme, q, a, m);

/// Original explanations. Diagrams are educational models, never photographs
/// of electrons. Existing course IDs and progress are deliberately unchanged.
final curiousTopics = List<CuriousTopic>.unmodifiable([
  _t(
    1,
    31,
    'Electrons',
    'How do electrons look in a benzene ring?',
    'Electrons are not tiny beads circling the hexagon. We describe their possible locations with quantum states. Benzene has six pi electrons in delocalised molecular orbitals above and below the ring plane. A shaded cloud represents probability density; the circle in a hexagon is a useful symbol, not a photograph or a race track.',
    _benzene,
  ),
  _t(
    2,
    9,
    'Electrons',
    'Why do electron arrows need arrowheads?',
    'The arrowhead records the destination of electron density; the tail records its source. A full curved arrow moves a pair in our bookkeeping, while a fishhook moves one electron. Electrons do not need arrowheads in nature. Chemists need the notation to distinguish bond making, bond breaking and direction.',
    _bromoethane,
  ),
  _t(
    3,
    1,
    'Bonds & shape',
    'Why does carbon usually make four bonds?',
    'Carbon has four valence electrons. Four shared pairs give neutral carbon an octet in familiar closed-shell organic molecules. Count bond orders: a double bond counts twice. Carbocations, radicals and carbanions show why four bonds is a common pattern rather than a rule without exceptions.',
    _methane,
  ),
  _t(
    4,
    2,
    'Bonds & shape',
    'Where did the carbon and hydrogen labels go in a skeletal drawing?',
    'An unlabelled corner or line end usually means carbon. Add enough hydrogens to satisfy its ordinary valence after counting bond orders. Heteroatoms are written explicitly. This convention saves space; it does not mean the missing letters or hydrogens have disappeared from the molecule.',
    _ethanol,
  ),
  _t(
    5,
    6,
    'Electrons',
    'Can we photograph an orbital like a tiny balloon?',
    'An orbital is a mathematical description of a quantum state, not a rubber container. Drawn lobes usually enclose a chosen fraction of probability density. Experiments can probe electron distributions under particular conditions, but a classroom lobe drawing is a model rather than an ordinary photograph.',
    _ethene,
  ),
  _t(
    6,
    6,
    'Bonds & shape',
    'Why is a double bond harder to twist?',
    'A double bond contains a sigma interaction and a pi interaction. Rotation disrupts sideways p-orbital overlap, costing energy. A single bond usually rotates much more easily. Double bonds can isomerise when enough energy or a suitable reaction pathway is supplied; they are not infinitely rigid.',
    _ethene,
  ),
  _t(
    7,
    8,
    'Electrons',
    'Are resonance structures different molecules?',
    'Resonance contributors keep the same atom connections and change only electron bookkeeping. The actual electronic state is not a molecule hopping back and forth between drawings. Contributors help describe delocalisation; they can have unequal importance depending on charge, octets and bond placement.',
    _benzene,
  ),
  _t(
    8,
    4,
    'Electrons',
    'Is a formal charge a measured charge on an atom?',
    'Formal charge assigns half of every bonding pair to each atom as a bookkeeping convention. Real electron density is shared unequally and partial charges depend on the model used. Distinguish the integer formal charge from a partial charge, and check that formal charges sum to the total molecular charge.',
    _ethanol,
  ),
  _t(
    9,
    7,
    'Electrons',
    'Why does oxygen pull electron density towards itself?',
    'Oxygen is more electronegative than carbon and hydrogen, so shared density in those bonds is polarised towards oxygen. Bond polarity helps explain electrophilic carbon and hydrogen-bond accepting sites. It does not mean an ordinary C–O bond has completely separated into ions.',
    _ethanol,
  ),
  _t(
    10,
    7,
    'Bonds & shape',
    'Does every molecule with polar bonds have a dipole?',
    'A molecular dipole is the vector sum of charge separation. Geometry matters: symmetric arrangements can cancel bond dipoles. Methane is a useful highly symmetric comparison. To predict polarity, inspect both the individual bonds and their three-dimensional arrangement rather than counting polar bonds alone.',
    _methane,
  ),
  _t(
    11,
    10,
    'Reactions',
    'Why is losing H plus different from losing a hydrogen atom?',
    'Removing a proton leaves the bonding electron pair behind on the conjugate base. Removing a neutral hydrogen atom takes one electron with it. These are different processes with different products and energies. Acid–base arrows therefore track electron pairs, while radical steps often use fishhooks.',
    _acid,
  ),
  _t(
    12,
    11,
    'Reactions',
    'Why is vinegar acidic but ethanol much less acidic?',
    'The acetate conjugate base distributes negative charge across two oxygens through resonance. Ethoxide lacks that comparable delocalisation. In the same solvent, the balance of conjugate-base stability favours much easier proton loss from ethanoic acid. Solvent and reference conditions still matter when comparing pKa values.',
    _acid,
  ),
  _t(
    13,
    12,
    'Electrons',
    'Does more resonance always mean more stability?',
    'Count meaningful electron delocalisation, not the number of drawings you can invent. Contributors that violate an octet or create unnecessary charge separation can contribute very little. Geometry and orbital alignment also matter. Resonance stabilisation is assessed relative to a sensible comparison, not by a drawing contest.',
    _acid,
  ),
  _t(
    14,
    13,
    'Reactions',
    'What makes a nucleophile want to attack?',
    'A nucleophile supplies an electron pair to an electron-poor site. Its rate of reaction depends on its orbitals, charge, solvent and steric access. Nucleophilicity describes reaction kinetics; basicity describes proton-transfer equilibrium. A strong base is not automatically the fastest nucleophile in every reaction.',
    _bromoethane,
  ),
  _t(
    15,
    13,
    'Reactions',
    'Why is a carbonyl carbon electrophilic?',
    'Oxygen polarises the carbonyl bond, leaving carbon relatively electron poor. The carbonyl pi-star orbital can accept electron density from a nucleophile. Bond formation at carbon is accompanied by redistribution of the pi pair towards oxygen; carbon must not be left with five ordinary bonds.',
    _acetone,
  ),
  _t(
    16,
    15,
    'Reactions',
    'Why does a favourable reaction sometimes need heating?',
    'A favourable overall free-energy change does not remove the activation barrier. Molecules must reach a suitable high-energy arrangement before products form. Heating can increase the fraction reaching that barrier, but can also change selectivity or cause competing reactions. Rate and equilibrium are different questions.',
    _bromoethane,
  ),
  _t(
    17,
    15,
    'Reactions',
    'How does a catalyst help without being used up overall?',
    'A catalyst participates in steps that provide a different pathway, then is regenerated. It lowers the relevant activation barriers without changing the equilibrium constant for the same overall reaction at the same temperature. Real catalysts can still deactivate, so regenerated in a mechanism does not mean indestructible.',
    _ethene,
  ),
  _t(
    18,
    16,
    'Bonds & shape',
    'Does rotating a bond make a new compound?',
    'Rotation about a suitable single bond usually gives a conformer of the same compound. Breaking and reconnecting bonds changes constitution; some restricted rotations can also create isolable stereoisomers. First ask whether connectivity changed, then ask about the timescale of interconversion.',
    _ethanol,
  ),
  _t(
    19,
    17,
    'Bonds & shape',
    'Why does cyclohexane prefer a chair instead of a flat hexagon?',
    'A flat six-membered ring would force unfavourable eclipsing and bond geometry. The chair permits near-tetrahedral angles and mostly staggered neighbouring bonds. A hexagon drawn on paper records connectivity; it does not assert that the physical ring is planar.',
    _cyclohexane,
  ),
  _t(
    20,
    17,
    'Bonds & shape',
    'Does a chair flip turn up into down?',
    'A chair flip exchanges axial and equatorial positions while retaining up/down orientation of a substituent relative to the ring. It also preserves the molecule’s stereochemical configuration. Confusing axial with up leads to incorrect cis/trans assignments; track both descriptors separately.',
    _cyclohexane,
  ),
  _t(
    21,
    18,
    'Bonds & shape',
    'Why can mirror-image molecules behave differently in the body?',
    'Enantiomers interact identically with an ideal achiral environment in many measurements, but enzymes and receptors are chiral. A mirror image may fit differently at a binding site. This does not mean every enantiomer pair has opposite biological effects; the particular molecule and target determine the outcome.',
    _ethanol,
  ),
  _t(
    22,
    18,
    'Bonds & shape',
    'Does every carbon with four bonds make a chiral centre?',
    'A typical tetrahedral stereogenic carbon needs four distinguishable substituent paths. Four bonds alone are not enough: methane and ethanol provide ordinary carbons without four different groups. Chirality can also arise without such a carbon, so inspect the whole structure rather than a single shorthand rule.',
    _ethanol,
  ),
  _t(
    23,
    19,
    'Bonds & shape',
    'Does R mean a molecule rotates light to the right?',
    'R and S describe configuration using a priority convention. The positive or negative sign of optical rotation is an experimental property under stated conditions. There is no general rule linking R to positive rotation or S to negative rotation. Assigning configuration cannot replace measuring rotation.',
    _ethanol,
  ),
  _t(
    24,
    21,
    'Reactions',
    'Why does an SN2 reaction attack from the back?',
    'Backside approach allows useful overlap between the incoming lone pair and the carbon–leaving-group antibonding orbital. Bond making and breaking occur in one elementary step. At a stereogenic centre this gives inversion of geometry; the final R/S label also depends on the product’s priority ordering.',
    _bromoethane,
  ),
  _t(
    25,
    22,
    'Reactions',
    'Why can the solvent change which reaction wins?',
    'Solvents stabilise ions, lone pairs and transition states differently. Polar protic solvents can strongly solvate small anionic nucleophiles; ionising solvents may assist pathways involving carbocations. Substrate, leaving group, reagent and temperature still matter. A solvent label alone cannot determine the product.',
    _bromoethane,
  ),
  _t(
    26,
    23,
    'Reactions',
    'Why does elimination need the right bond alignment?',
    'In a common E2 pathway, the C–H and C–leaving-group bonds are arranged antiperiplanar so their orbitals can reorganise into a pi bond. A cyclohexane chair can restrict which hydrogen has that geometry. Drawing the conformation can explain a product ratio that a simple substitution rule misses.',
    _bromoethane,
  ),
  _t(
    27,
    25,
    'Reactions',
    'Why is a reaction mechanism more than a list of arrows?',
    'A mechanism proposes elementary steps, intermediates and the electron flow connecting them. Every arrow must start from actual electrons, obey charge and atom balance, and fit the conditions. A tidy drawing is not proof: kinetics, stereochemistry and other evidence must also support the pathway.',
    _bromoethane,
  ),
  _t(
    28,
    26,
    'Reactions',
    'Why does an alkene react at its pi bond?',
    'An alkene pi interaction is relatively accessible to an electrophile. Addition can replace the pi bond with new sigma bonds through a particular pathway. Predicting regiochemistry requires examining the reagent and intermediate or transition state, rather than treating every addition as the same reaction.',
    _ethene,
  ),
  _t(
    29,
    27,
    'Reactions',
    'Why can bromine add to opposite faces of an alkene?',
    'A bridged bromonium intermediate blocks straightforward approach from its occupied face. Bromide can open it from the other face, giving the usual anti-addition relationship. Anti describes the relative addition pathway; whether the final sample is one stereoisomer or a mixture depends on the alkene and symmetry.',
    _ethene,
  ),
  _t(
    30,
    30,
    'Electrons',
    'What is the difference between a fishhook and a full curved arrow?',
    'A fishhook tracks one electron in a radical step. A full curved arrow tracks an electron pair. Homolytic bond cleavage is represented by one fishhook to each resulting radical, whereas heterolytic cleavage sends the pair to one partner. The symbols specify bookkeeping, not the literal trajectory of particles.',
    _ethene,
  ),
  _t(
    31,
    31,
    'Electrons',
    'Why does benzene have six equal carbon–carbon bonds?',
    'A localised alternating-bond drawing is incomplete. The delocalised electronic structure of benzene makes its equivalent carbon–carbon connections equal in the equilibrium structure. It is not three short bonds swapping rapidly with three long bonds. Vibrations and the measurement conditions still belong to a real molecular description.',
    _benzene,
  ),
  _t(
    32,
    31,
    'Electrons',
    'Why is the benzene circle drawn inside the ring?',
    'The circle is a compact symbol for aromatic delocalisation. It is placed inside the ring for readability, although the pi probability density lies above and below the ring plane and extends around the framework. Neither the circle nor a shaded cloud is a literal electron orbit.',
    _benzene,
  ),
  _t(
    33,
    31,
    'Electrons',
    'Do all ring molecules count as aromatic?',
    'A ring alone is insufficient. For the simple Hückel systems considered here, check continuous p-orbital conjugation, approximate planarity and a suitable 4n+2 pi-electron count. Cyclohexane has no such conjugated pi system. Its six-membered ring therefore does not make it aromatic.',
    _cyclohexane,
  ),
  _t(
    34,
    34,
    'Reactions',
    'Why can an aromatic ring resist addition yet undergo substitution?',
    'Simple addition can permanently destroy an aromatic pi system, while many substitution pathways lose aromaticity temporarily and restore it at the end. Reagents and conditions determine which pathway is possible. Aromatic stabilisation is an energetic consideration, not a promise that benzene never reacts.',
    _benzene,
  ),
  _t(
    35,
    36,
    'Reactions',
    'Where does the carbonyl pi pair go during nucleophilic addition?',
    'As a nucleophile forms a bond to carbonyl carbon, the pi pair is directed towards oxygen in the electron bookkeeping. The first addition product is often an alkoxide, followed by proton transfer under suitable conditions. Sending the arrow towards carbon while adding a fifth bond would give an invalid ordinary carbon valence.',
    _acetone,
  ),
  _t(
    36,
    40,
    'Reactions',
    'Why do esters and ketones react differently with nucleophiles?',
    'A ketone has carbon substituents and normally undergoes addition. An ester also has a heteroatom substituent that can leave from a tetrahedral intermediate under suitable conditions, enabling acyl substitution. Leaving-group ability, reagent strength and conditions decide whether addition, substitution or further reaction occurs.',
    _acetone,
  ),
  _t(
    37,
    41,
    'Electrons',
    'Why are hydrogens next to a carbonyl more acidic?',
    'Removing an alpha proton can form an enolate whose negative charge is delocalised between carbon and oxygen. That conjugate-base stabilisation can make these hydrogens more acidic than ordinary alkane hydrogens. Do not confuse an alpha C–H bond with an O–H bond; they produce different conjugate bases.',
    _acetone,
  ),
  _t(
    38,
    41,
    'Reactions',
    'Are keto and enol forms resonance contributors?',
    'No. Keto–enol tautomerism moves a proton and changes bond connectivity, so the forms are different species in equilibrium. Resonance contributors retain the same atom connections and differ only in electron placement. Draw the atoms and hydrogen positions before deciding which idea applies.',
    _acetone,
  ),
  _t(
    39,
    46,
    'Reactions',
    'Does oxidation always mean adding oxygen?',
    'Oxidation corresponds to an increase in formal oxidation state. In organic chemistry, adding bonds to electronegative atoms or removing C–H bonds often signals carbon oxidation. Removing two hydrogens from an alcohol to form a carbonyl can therefore be oxidation even without adding an oxygen atom.',
    _ethanol,
  ),
  _t(
    40,
    47,
    'Reactions',
    'Why can one reducing reagent leave another functional group alone?',
    'Different reagents have different reactivity, steric access and mechanisms. A mild hydride reagent may reduce a ketone while leaving some other groups unchanged under its usual conditions. Chemoselectivity is conditional: solvent, temperature, equivalents and neighbouring groups can change what actually happens.',
    _acetone,
  ),
  _t(
    41,
    51,
    'Electrons',
    'Are orbital colours positive and negative electric charges?',
    'The two colours in many orbital diagrams show opposite signs of a wavefunction, called phase. They do not mean one lobe is positively charged and the other negatively charged. Electron probability density depends on the squared magnitude; phase becomes important when orbital contributions combine constructively or destructively.',
    _ethene,
  ),
  _t(
    42,
    51,
    'Electrons',
    'What does an antibonding star actually mean?',
    'The star in pi-star or sigma-star identifies an antibonding orbital. Its phase pattern has a node between the relevant bonding regions, so occupying it generally weakens that bonding interaction. It is an allowed quantum state, not an extra physical bond or a warning that the molecule must explode.',
    _ethene,
  ),
  _t(
    43,
    55,
    'Electrons',
    'Can light change which reaction pathway is allowed?',
    'Absorbing light can populate an excited electronic state with a different orbital occupancy. Its reaction pathways and selection rules can differ from those of the ground state. Wavelength, sensitisation and competing relaxation matter. A light symbol above an arrow does not imply that every molecule follows the same photochemical reaction.',
    _ethene,
  ),
  _t(
    44,
    56,
    'Spectra & life',
    'Why do equivalent hydrogens often give one NMR signal?',
    'Chemically equivalent hydrogens experience the same time-averaged shielding under the measurement conditions. Symmetry and rapid motion can both matter. Signal count is not simply hydrogen count, and magnetic equivalence is a further condition relevant to splitting. Exchange and timescale can change what is observed.',
    _ethanol,
  ),
  _t(
    45,
    56,
    'Spectra & life',
    'Can a molecular formula reveal one unique structure?',
    'Usually not: the same formula can describe several constitutional isomers and stereoisomers. DBE constrains rings and multiple bonds but does not place them. Combine integration, shifts, splitting, carbon environments and connectivity experiments before assigning a structure; a formula match alone is only a starting point.',
    _ethanol,
  ),
  _t(
    46,
    56,
    'Spectra & life',
    'Why does an O–H NMR peak sometimes move or disappear?',
    'Exchangeable proton shifts depend strongly on solvent, concentration, temperature and hydrogen bonding. Exchange can broaden a signal, alter splitting or make it hard to observe. A suitable exchange experiment can support the assignment. An absent O–H peak alone does not rule out an alcohol.',
    _ethanol,
  ),
  _t(
    47,
    3,
    'Spectra & life',
    'Why do molecules with similar formulas smell different?',
    'Different connectivity and shape can change volatility and interactions with olfactory receptors. A molecular formula does not encode those spatial and bonding differences. Smell is also concentration dependent and subjective; never identify an unknown chemical by deliberately smelling it. Structural and analytical evidence is more useful.',
    _ethanol,
  ),
  _t(
    48,
    60,
    'Spectra & life',
    'Can a beautiful mechanism still be wrong?',
    'Yes. A diagram can satisfy valence yet propose a pathway unsupported by experiment. Compare rate laws, isotope effects, stereochemistry and plausible alternatives. A good mechanistic explanation states what the evidence supports, what it excludes and what remains uncertain, instead of treating an attractive drawing as proof.',
    _acetone,
  ),
  for (final (index, level) in const [
    31,
    8,
    32,
    30,
    33,
    20,
    17,
    43,
    48,
    52,
    53,
    58,
  ].indexed)
    _t(
      49 + index,
      level,
      'Deeper questions',
      organicLessons[level - 1].hook,
      organicLessons[level - 1].simple,
      switch (level) {
        17 || 58 => _cyclohexane,
        20 => _ethanol,
        30 => _ethene,
        52 || 53 => _butadiene,
        >= 36 => _acetone,
        _ => _benzene,
      },
    ),
]);

/// Shuffle bag: every eligible question appears once before a new cycle.
class CuriousSurprises {
  CuriousSurprises({Random? random}) : _random = random ?? Random();
  final Random _random;
  final _remaining = <CuriousTopic>[];
  String _signature = '';
  String? _last;
  CuriousTopic next(List<CuriousTopic> topics) {
    if (topics.isEmpty) throw StateError('Choose a theme with questions.');
    final signature = topics.map((t) => t.id).join(',');
    if (signature != _signature || _remaining.isEmpty) {
      _signature = signature;
      _remaining
        ..clear()
        ..addAll(topics)
        ..shuffle(_random);
      if (_remaining.length > 1 && _remaining.last.id == _last) {
        final first = _remaining.first;
        _remaining[0] = _remaining.last;
        _remaining[_remaining.length - 1] = first;
      }
    }
    final topic = _remaining.removeLast();
    _last = topic.id;
    return topic;
  }
}
