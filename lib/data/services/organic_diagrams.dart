import 'dart:math' as math;

/// Original vector illustrations, rendered using the app's existing SVG engine.
/// Formulas are schematic teaching examples, not simulated experimental data.
class OrganicDiagram {
  const OrganicDiagram(this.title, this.caption, this.body);
  final String title, caption, body;
  String svg({
    String ink = '#282237',
    String accent = '#7351B5',
    String surface = '#F6F0FF',
  }) =>
      '''
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 640 320">
<rect width="640" height="320" rx="24" fill="$surface"/>
<g font-family="sans-serif" font-size="22" fill="$ink" stroke-linecap="round" stroke-linejoin="round">${body.replaceAll('@ink', ink).replaceAll('@accent', accent)}</g></svg>''';
}

String _t(num x, num y, String s, {int size = 22}) =>
    '<text x="$x" y="$y" text-anchor="middle" font-size="$size">${s.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;')}</text>';
String _line(num x, num y, num a, num b) =>
    '<path d="M$x $y L$a $b" fill="none" stroke="@ink" stroke-width="3"/>';
String _head(double x, double y, double fromX, double fromY) {
  final angle = math.atan2(y - fromY, x - fromX);
  final bx = x - 10 * math.cos(angle), by = y - 10 * math.sin(angle);
  final sx = 4.5 * math.sin(angle), sy = 4.5 * math.cos(angle);
  return '<path d="M$x $y L${bx + sx} ${by - sy} L${bx - sx} ${by + sy} Z" fill="@accent"/>';
}

String _arrow(String path) {
  // Explicit arrowheads work in the native vector renderer, which does not
  // implement SVG marker elements. Losing a head would change chemical meaning.
  final points = RegExp(r'-?\d+(?:\.\d+)?')
      .allMatches(path)
      .map((m) => double.parse(m[0]!))
      .toList();
  final n = points.length;
  return '<path d="$path" fill="none" stroke="@accent" stroke-width="3"/>'
      '${_head(points[n - 2], points[n - 1], points[n - 4], points[n - 3])}';
}

String _ring(
  double cx,
  double cy,
  int sides, {
  bool circle = false,
  bool plus = false,
}) {
  final pts = List.generate(sides, (i) {
    final a = -math.pi / 2 + i * 2 * math.pi / sides;
    return (cx + 55 * math.cos(a), cy + 55 * math.sin(a));
  });
  return '<polygon points="${pts.map((p) => '${p.$1},${p.$2}').join(' ')}" fill="none" stroke="@ink" stroke-width="3"/>'
      '${circle ? '<circle cx="$cx" cy="$cy" r="32" fill="none" stroke="@accent" stroke-width="2.5"/>' : ''}'
      '${plus ? _t(cx, cy + 8, '+') : ''}';
}

OrganicDiagram _flow(String title, String caption, List<String> steps) =>
    OrganicDiagram(
      title,
      caption,
      steps.indexed
          .map(
            (e) =>
                _t(320, 55 + e.$1 * 70, e.$2, size: 21) +
                (e.$1 < steps.length - 1
                    ? _arrow('M320 ${66 + e.$1 * 70} L320 ${91 + e.$1 * 70}')
                    : ''),
          )
          .join(),
    );

final organicDiagrams = <String, OrganicDiagram>{
  'aromatic_cloud': OrganicDiagram(
    'Where the pi density lies',
    'A perspective teaching sketch. Clouds show pi-electron probability density above and below the ring plane, not circular electron tracks.',
    '<ellipse cx="320" cy="83" rx="154" ry="40" fill="@accent" fill-opacity=".24"/>'
        '<ellipse cx="320" cy="237" rx="154" ry="40" fill="@accent" fill-opacity=".24"/>'
        '<polygon points="200,160 260,130 380,130 440,160 380,190 260,190" fill="none" stroke="@ink" stroke-width="3"/>'
        '${_t(320, 32, 'Pi density above the ring', size: 20)}${_t(320, 165, 'Ring plane', size: 18)}${_t(320, 306, 'Pi density below the ring', size: 20)}',
  ),
  'carbon': OrganicDiagram(
    'Four bonds, shared electrons',
    'Each line represents one shared electron pair. This is a connectivity sketch, not the tetrahedral shape.',
    _t(300, 165, 'C') +
        _t(300, 65, 'H') +
        _t(300, 265, 'H') +
        _t(180, 165, 'H') +
        _t(420, 165, 'H') +
        _line(300, 135, 300, 78) +
        _line(300, 180, 300, 235) +
        _line(205, 157, 280, 157) +
        _line(320, 157, 395, 157) +
        _t(320, 305, 'CH₄ · four C–H sigma bonds', size: 18),
  ),
  'skeleton': OrganicDiagram(
    'Read every endpoint and corner',
    'These two drawings describe the same unbranched four-carbon skeleton.',
    '<path d="M160 105 L260 55 L360 105 L460 55" fill="none" stroke="@ink" stroke-width="4"/>${_t(320, 180, 'CH₃—CH₂—CH₂—CH₃')}${_t(320, 255, '4 carbons · 10 hydrogens', size: 20)}',
  ),
  'groups': _flow(
    'Spot the functional group',
    'Read the whole group: an OH beside C=O is part of a carboxylic acid.',
    [
      'CH₃—CH₂—OH    alcohol',
      'CH₃—CH=O    aldehyde',
      'CH₃—C(=O)—OH    carboxylic acid',
    ],
  ),
  'charge': _flow(
    'Count bonds and lone pairs',
    'Common oxygen valence patterns; charge is formal electron accounting.',
    [
      'H₂O: 2 bonds + 2 lone pairs → 0',
      'H₃O⁺: 3 bonds + 1 lone pair → +1',
      'HO⁻: 1 bond + 3 lone pairs → −1',
    ],
  ),
  'dbe': _flow(
    'Same formula, different structures',
    'DBE restricts the possibilities; it does not uniquely identify an isomer.',
    [
      'C₂H₆O: DBE = (2×2 + 2 − 6)/2 = 0',
      'CH₃—CH₂—OH     ethanol',
      'CH₃—O—CH₃     dimethyl ether',
    ],
  ),
  'orbitals': OrganicDiagram(
    'Aligned p orbitals give pi overlap',
    'The lobes illustrate p-orbital alignment. Lobe colours indicate orbital phase, not electric charge.',
    '<ellipse cx="255" cy="85" rx="34" ry="57" fill="@accent" fill-opacity=".22"/><ellipse cx="385" cy="85" rx="34" ry="57" fill="@accent" fill-opacity=".22"/><ellipse cx="255" cy="230" rx="34" ry="57" fill="none" stroke="@accent" stroke-width="2"/><ellipse cx="385" cy="230" rx="34" ry="57" fill="none" stroke="@accent" stroke-width="2"/>${_line(270, 157, 370, 157)}${_t(255, 165, 'C')}${_t(385, 165, 'C')}${_t(320, 76, 'π', size: 24)}${_t(320, 145, 'σ', size: 19)}${_t(320, 303, 'Sideways overlap requires suitable alignment', size: 18)}',
  ),
  'resonance': OrganicDiagram(
    'Acetate: two contributors, one ion',
    'The atomic framework stays fixed. The real ion has delocalised charge and equivalent C–O bonds.',
    '${_t(145, 80, 'O')}${_t(145, 190, 'C')}${_t(55, 240, 'O⁻')}${_t(230, 240, 'CH₃')}${_line(138, 95, 138, 160)}${_line(152, 95, 152, 160)}${_line(125, 198, 75, 224)}${_line(165, 198, 207, 224)}${_t(495, 80, 'O⁻')}${_t(495, 190, 'C')}${_t(405, 240, 'O')}${_t(580, 240, 'CH₃')}${_line(495, 95, 495, 160)}${_line(473, 196, 424, 222)}${_line(480, 207, 430, 234)}${_line(515, 198, 558, 224)}<path d="M270 170 L365 170" fill="none" stroke="@accent" stroke-width="3"/>${_head(365, 170, 270, 170)}${_head(270, 170, 365, 170)}${_t(320, 300, 'Resonance arrow ≠ equilibrium between compounds', size: 18)}',
  ),
  'sn2': OrganicDiagram(
    'SN2: two pairs move in one step',
    'Full curved arrows represent electron pairs. The nucleophile attacks carbon as the C–Br pair moves to Br.',
    _t(95, 160, 'HO⁻ :') +
        _t(310, 160, 'CH₃') +
        _line(343, 153, 435, 153) +
        _t(467, 160, 'Br') +
        _arrow('M135 140 Q210 55 292 137') +
        _arrow('M385 149 Q424 78 460 134') +
        _t(320, 60, 'One concerted event', size: 20) +
        _t(320, 235, 'CH₃OH + Br⁻') +
        _t(320, 290, 'No carbocation intermediate', size: 19),
  ),
  'acid': OrganicDiagram(
    'Proton transfer: follow both pairs',
    'Ammonia donates a lone pair to H; the H–Cl bonding pair stays with chlorine.',
    _t(110, 158, 'H₃N:') +
        _t(320, 158, 'H') +
        _line(342, 150, 415, 150) +
        _t(455, 158, 'Cl') +
        _arrow('M150 135 Q230 55 304 135') +
        _arrow('M380 146 Q417 80 449 132') +
        _t(320, 245, 'NH₄⁺ + Cl⁻') +
        _t(320, 292, 'Net charge: 0 before and after', size: 18),
  ),
  'equilibrium': _flow(
    'Compare the acid on each side',
    'Use pKa values measured on compatible solvent scales.',
    [
      'HA + B⁻ ⇌ A⁻ + HB',
      'log₁₀K ≈ pKa(HB) − pKa(HA)',
      'Example: 10 − 5 = 5 → K ≈ 10⁵',
    ],
  ),
  'donor': _flow(
    'Find a donor and an acceptor',
    'The direction is electron-pair donation; the actual pathway also depends on geometry and conditions.',
    [
      'Electron-rich donor: a lone pair or pi bond',
      'Electron-poor acceptor: a suitable orbital',
      'Donor pair → new bond to the acceptor',
    ],
  ),
  'energy': OrganicDiagram(
    'A barrier and an intermediate',
    'Illustrative two-step profile. The horizontal axis is reaction progress, not elapsed time.',
    '${_line(75, 260, 580, 260)}${_line(75, 260, 75, 35)}<path d="M90 210 C140 210 145 70 195 70 S235 175 290 175 S340 95 390 95 S460 225 565 225" fill="none" stroke="@accent" stroke-width="4"/>${_t(195, 50, 'TS 1', size: 18)}${_t(390, 75, 'TS 2', size: 18)}${_t(285, 205, 'intermediate', size: 18)}${_t(330, 300, 'Reaction coordinate', size: 19)}',
  ),
  'conformation': OrganicDiagram(
    'Newman view: staggered anti butane',
    'Look along C2–C3. Front and back methyl groups are opposite; rotation preserves connectivity.',
    '<circle cx="320" cy="160" r="48" fill="none" stroke="@ink" stroke-width="3"/>${_line(320, 160, 320, 65)}${_line(320, 160, 235, 215)}${_line(320, 160, 405, 215)}${_line(320, 208, 320, 263)}${_line(278, 136, 240, 110)}${_line(362, 136, 400, 110)}<circle cx="320" cy="160" r="7" fill="@accent"/>${_t(320, 48, 'CH₃')}${_t(320, 290, 'CH₃')}${_t(218, 105, 'H')}${_t(422, 105, 'H')}${_t(210, 235, 'H')}${_t(430, 235, 'H')}',
  ),
  'chair': OrganicDiagram(
    'A chair is a three-dimensional conformation',
    'Schematic perspective: chair flipping exchanges axial/equatorial positions while retaining up/down configuration.',
    '<path d="M125 180 L225 120 L380 140 L490 80 L390 200 L235 180 Z" fill="none" stroke="@ink" stroke-width="4"/>${_line(225, 120, 225, 45)}${_t(225, 30, 'axial', size: 18)}${_line(225, 120, 145, 75)}${_t(103, 66, 'equatorial', size: 18)}${_t(320, 270, 'Axial ⇄ equatorial; up stays up', size: 21)}',
  ),
  'stereo': OrganicDiagram(
    'Wedges carry spatial information',
    'Solid wedge: towards you. Dashed bond: away. This drawing does not assign an R/S label.',
    '${_t(310, 170, 'C')}${_line(310, 137, 310, 65)}${_t(310, 48, 'OH')}${_line(310, 186, 310, 260)}${_t(310, 290, 'H')}<path d="M335 158 L450 120 L450 190 Z" fill="@accent"/><path d="M285 158 L165 110" fill="none" stroke="@ink" stroke-width="5" stroke-dasharray="5 9"/>${_t(500, 165, 'CH₂CH₃', size: 20)}${_t(115, 110, 'CH₃', size: 20)}',
  ),
  'nmr': OrganicDiagram(
    'Same carbon does not guarantee equivalence',
    'Use the substitution test for Ha and Hb. This is a labelled molecular fragment, not a measured spectrum.',
    _t(300, 160, 'C') +
        _t(155, 85, 'Hₐ') +
        _t(445, 85, 'Hᵦ') +
        _line(185, 100, 275, 140) +
        _line(325, 140, 415, 100) +
        _line(280, 175, 200, 210) +
        _line(320, 175, 400, 210) +
        _t(170, 220, 'R') +
        _t(430, 220, 'R′') +
        _t(320, 225, 'Replace Hₐ, then replace Hᵦ') +
        _t(320, 275, 'Compare the two complete products', size: 20),
  ),
  'e2': OrganicDiagram(
    'E2: three electron pairs move together',
    'Base takes beta H; C–H pair makes C=C; C–Br pair goes to Br. Alignment matters.',
    _t(90, 100, 'B:⁻') +
        _t(250, 90, 'H') +
        _t(250, 190, 'CH₂') +
        _t(405, 190, 'CH₂') +
        _t(550, 190, 'Br') +
        _line(250, 105, 250, 160) +
        _line(285, 182, 370, 182) +
        _line(440, 182, 520, 182) +
        _arrow('M125 87 Q183 30 237 67') +
        _arrow('M257 129 Q310 112 328 172') +
        _arrow('M480 176 Q520 110 543 161') +
        _t(320, 280, 'CH₂=CH₂ + HB + Br⁻', size: 22),
  ),
  'sn1': _flow(
    'SN1: ionise, attack, deprotonate',
    'A simplified solvolysis sequence. Real ion pairs can affect stereochemistry.',
    [
      '(CH₃)₃C—Br → (CH₃)₃C⁺ + Br⁻',
      '(CH₃)₃C⁺ + H₂O → (CH₃)₃C—OH₂⁺',
      'Base removes H⁺ → (CH₃)₃C—OH',
    ],
  ),
  'e1': _flow(
    'E1: ionisation before elimination',
    'A suitable carbocation loses a beta proton. The C–H pair forms the pi bond.',
    ['Leaving group departs → carbocation', 'R₂C⁺—CH₂R + :B', 'R₂C=CHR + BH⁺'],
  ),
  'competition': _flow(
    'Compare competing pathways',
    'A decision aid, not an unconditional product predictor. Include solvent, base, nucleophile and conformation.',
    [
      'Accessible carbon + nucleophile → consider SN2',
      'Feasible ionisation → consider SN1 / E1',
      'Base + suitable beta H → consider E2',
    ],
  ),
  'alkene': _flow(
    'Ordinary ionic HBr addition',
    'The more stabilised carbocation pathway often explains regioselectivity for simple substrates.',
    ['CH₂=CH—CH₃ + HBr', 'CH₃—C⁺H—CH₃ + Br⁻', 'CH₃—CH(Br)—CH₃'],
  ),
  'bromonium': OrganicDiagram(
    'Bromonium: a bridged intermediate',
    'Br− opens the bridge from the opposite face. The bridge-to-carbon bond breaks as nucleophile bonding develops.',
    _t(320, 65, 'Br⁺') +
        _t(220, 200, 'CH₂') +
        _t(420, 200, 'CH₂') +
        _line(300, 80, 235, 170) +
        _line(340, 80, 405, 170) +
        _line(255, 193, 385, 193) +
        _t(100, 270, 'Br⁻') +
        _arrow('M130 253 Q163 213 197 194') +
        _arrow('M259 131 Q220 54 290 52') +
        _t(440, 285, 'Anti opening', size: 20),
  ),
  'hydration': _flow(
    'Acid-catalysed hydration',
    'Water attack produces an oxonium ion; deprotonation gives the alcohol.',
    [
      'Propene + H⁺ → secondary carbocation',
      'H₂O attack → CH₃—CH(OH₂⁺)—CH₃',
      '−H⁺ → CH₃—CH(OH)—CH₃',
    ],
  ),
  'hydroboration': _flow(
    'Hydroboration, then oxidation',
    'For simple substrates: B and H add syn; oxidation replaces C–B by C–O with retention.',
    [
      'Propene + borane → organoborane',
      'B at less substituted end; H on same face',
      'Peroxide / base oxidation → propan-1-ol',
    ],
  ),
  'radical': _flow(
    'HBr radical-chain propagation',
    'Dots mark unpaired electrons. Use single-electron fishhook arrows when working through these steps.',
    [
      'Br· + CH₂=CHCH₃ → BrCH₂—C·H—CH₃',
      'BrCH₂—C·H—CH₃ + HBr',
      'BrCH₂—CH₂—CH₃ + Br·',
    ],
  ),
  'aromatic': OrganicDiagram(
    'Six pi electrons, different ring sizes',
    'Circles represent delocalisation, not literal electron tracks. Continuous p-orbital overlap is also required.',
    _ring(150, 125, 6, circle: true) +
        _ring(470, 125, 7, circle: true, plus: true) +
        _t(150, 220, 'Benzene: C₆H₆') +
        _t(470, 220, 'Tropylium: C₇H₇⁺') +
        _t(150, 265, '6 ring atoms · 6π', size: 20) +
        _t(470, 265, '7 ring atoms · 6π', size: 20),
  ),
  'eas': _flow(
    'Nitration restores aromaticity',
    'During ring attack on NO₂⁺, one N=O pi pair shifts towards oxygen to retain the nitrogen octet.',
    [
      'HNO₃ activation → NO₂⁺ + H₂O',
      'Benzene pi attack → sigma complex',
      'Base removes ring H⁺ → nitrobenzene',
    ],
  ),
  'directing': _flow(
    'Rate and position are separate questions',
    'For ordinary electrophilic substitution on halobenzenes, induction and resonance affect different comparisons.',
    [
      'Halogen withdraws inductively → deactivation',
      'Lone-pair resonance donation affects sigma complexes',
      'Relative orientation: ortho / para',
    ],
  ),
  'snar': _flow(
    'Activated SNAr: addition–elimination',
    'An appropriate ortho/para electron-withdrawing group supports the anionic pathway.',
    [
      'Nu⁻ adds to activated Ar—X',
      'Anionic sigma intermediate',
      'X⁻ leaves; aromaticity returns → Ar—Nu',
    ],
  ),
  'benzyne': _flow(
    'Benzyne: elimination–addition',
    'Strong-base conditions and an appropriate ortho hydrogen are required for the classical pathway.',
    [
      'Aryl halide: remove ortho H and leaving group',
      'Benzyne intermediate + nucleophile',
      'Protonation → substituted aromatic product',
    ],
  ),
  'carbonyl': OrganicDiagram(
    'Carbonyl addition: follow two pairs',
    'Nu: attacks carbon. The C=O pi pair moves to oxygen. R groups here are schematic substituents.',
    _t(110, 180, 'Nu:⁻') +
        _t(330, 180, 'C') +
        _t(330, 60, 'O') +
        _line(322, 80, 322, 150) +
        _line(338, 80, 338, 150) +
        _line(310, 190, 245, 235) +
        _line(350, 190, 415, 235) +
        _t(225, 260, 'R') +
        _t(435, 260, 'R') +
        _arrow('M150 159 Q238 82 306 154') +
        _arrow('M345 120 Q407 94 351 58') +
        _t(320, 305, 'Addition gives a tetrahedral alkoxide adduct', size: 18),
  ),
  'reduction': _flow(
    'Hydride addition, then protonation',
    'A transferred hydride equivalent is not free H⁺. Reagent compatibility determines selectivity.',
    [
      'R₂C=O + hydride reagent',
      'R₂CH—O⁻ (schematic adduct)',
      'Protonation → R₂CH—OH',
    ],
  ),
  'grignard': _flow(
    'A new carbon–carbon connection',
    'Carbon from the organomagnesium reagent bonds to carbonyl carbon; workup protonates oxygen.',
    [
      'CH₃CHO + CH₃MgBr',
      'C–C addition → magnesium alkoxide',
      'Protonating workup → (CH₃)₂CHOH',
    ],
  ),
  'imine': _flow(
    'Carbonyl + primary amine → imine',
    'Proton transfers connect the stages; acidity and water content affect the equilibrium.',
    [
      'RCHO + R′NH₂ → carbinolamine',
      'Activation / water loss → iminium',
      'Deprotonation → RCH=NR′',
    ],
  ),
  'acyl': _flow(
    'Acyl substitution: restore C=O',
    'Addition forms a tetrahedral intermediate. Collapse expels a suitable leaving group.',
    [
      'Nu attacks R—C(=O)—X',
      'Tetrahedral intermediate: R—C(O⁻)(Nu)—X',
      'C=O reforms; X leaves',
    ],
  ),
  'enolate': _flow(
    'Deprotonation beside a carbonyl',
    'The enolate contributors share one atomic framework and total charge.',
    [
      'Base removes an alpha H from CH₃COCH₃',
      '⁻CH₂—C(=O)—CH₃',
      'Resonance contributor: CH₂=C(O⁻)—CH₃',
    ],
  ),
  'aldol': _flow(
    'Aldol: join donor alpha C to acceptor C=O',
    'The donor retains its carbonyl. The acceptor’s carbonyl becomes the OH-bearing centre.',
    [
      'Ethanal enolate attacks another ethanal',
      'Protonation → CH₃CH(OH)CH₂CHO',
      'Optional dehydration → CH₃CH=CHCHO',
    ],
  ),
  'claisen': _flow(
    'Claisen: acyl substitution by an enolate',
    'Product deprotonation helps drive the classical equilibrium; acidic workup returns the neutral product.',
    [
      'Ester enolate attacks another ester',
      'Tetrahedral collapse expels alkoxide',
      'Workup → CH₃COCH₂CO₂Et',
    ],
  ),
  'michael': _flow(
    'Conjugate addition reaches beta carbon',
    'The acceptor pi system shifts during attack; protonation returns a carbonyl-containing product.',
    [
      'Nu⁻ + RCO—CH=CH₂',
      'Nu bonds to beta C → enolate-like adduct',
      'Protonation → RCO—CH₂—CH₂Nu',
    ],
  ),
  'oxidation': _flow(
    'Compare alcohol oxidation outcomes',
    'Reagent and conditions decide whether a primary alcohol stops at the aldehyde or oxidises further.',
    [
      'Primary: RCH₂OH → RCHO → RCO₂H',
      'Secondary: R₂CHOH → R₂C=O',
      'Tertiary: no usual C–H at OH-bearing C',
    ],
  ),
  'bv': _flow(
    'Baeyer–Villiger: oxygen insertion',
    'Peroxide addition precedes migration and O–O cleavage. A ring ketone can give a larger lactone ring.',
    [
      'Ketone + peracid → peroxide adduct',
      'Adjacent group migrates to oxygen',
      'Ester product; cyclic ketone → lactone',
    ],
  ),
  'beckmann': _flow(
    'Beckmann: geometry selects migration',
    'The group anti to the departing oxime group migrates to nitrogen in the standard pathway.',
    [
      'Ketoxime: activate OH',
      'Anti group migrates → nitrilium',
      'Capture / proton transfers → amide',
    ],
  ),
  'pinacol': _flow(
    'Pinacol: migrate with the bond pair',
    'Water departure and neighbouring-group migration reorganise the vicinal diol into a carbonyl compound.',
    [
      'Vicinal diol: activate one OH',
      'Water loss / adjacent bond migration',
      'Carbonyl formation and deprotonation',
    ],
  ),
  'diels': OrganicDiagram(
    'Diels–Alder: [4+2] gives a six-membered ring',
    'Two new sigma bonds form in the concerted model, leaving one ring double bond. Reactant stereochemistry matters.',
    '${_t(155, 72, 'Diene (s-cis)', size: 19)}${_t(485, 72, 'Dienophile', size: 19)}<path d="M200 115 L135 155 L135 225 L200 265 M195 125 L143 159 M143 221 L195 255 M430 150 L430 230 M442 150 L442 230" fill="none" stroke="@ink" stroke-width="3"/><path d="M200 115 L430 150 M200 265 L430 230" fill="none" stroke="@accent" stroke-width="2" stroke-dasharray="6 7"/>${_arrow('M167 135 Q235 75 315 132')}${_arrow('M435 190 Q440 275 315 247')}${_arrow('M167 245 Q85 190 135 190')}${_t(320, 305, '4π + 2π → cyclohexene framework', size: 18)}',
  ),
  'electrocyclic': _flow(
    'Count electrons, specify heat or light',
    'These are the simple thermal rules. Appropriate photochemical excitation reverses the selection pattern.',
    [
      'Thermal 4π → conrotatory',
      'Thermal 6π → disrotatory',
      'Track each terminal substituent in 3D',
    ],
  ),
  'sigmatropic': _flow(
    '[3,3]: one sigma connection relocates',
    'The six-electron rearrangement conserves atoms and reorganises the pi bonds with the sigma connection.',
    [
      'Label the six atoms of a 1,5-diene',
      'Cope: shift sigma connection + both pi bonds',
      'Check the new connectivity atom by atom',
    ],
  ),
  'photo': _flow(
    'Light changes orbital occupation',
    'Electronic excitation changes the state being analysed. A permitted pathway still competes with relaxation.',
    [
      'Ground-state molecule + photon',
      'Excited-state electronic configuration',
      'Reaction OR competing relaxation pathways',
    ],
  ),
  'isotope': _flow(
    'A rate comparison can probe bond motion',
    'Isotope effects constrain mechanisms but do not uniquely prove one without supporting evidence.',
    [
      'Compare otherwise matched C–H and C–D substrates',
      'Measure rates under matched conditions',
      'Kinetic isotope effect: kH / kD',
    ],
  ),
  'retro': _flow(
    'Plan backwards, check forwards',
    'A disconnection is an analysis tool. Translate the idealised fragments into compatible real reagents.',
    [
      'Target alcohol → identify a possible C–C disconnection',
      'Propose carbonyl + carbon-nucleophile partners',
      'Verify the forward reaction and functional groups',
    ],
  ),
};
