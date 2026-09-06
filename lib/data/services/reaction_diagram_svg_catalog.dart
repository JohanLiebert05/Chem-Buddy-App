/// Catalog of vector SVG diagrams for MSc organic reaction mechanisms.
/// Formatted with high-contrast dark theme colors (#141224 background, #A78BFA purple labels,
/// #38BDF8 cyan chemical bonds, #F59E0B gold electron movement arrows, #F43F5E coral bond-breaking arrows,
/// and #10B981 green products).
class ReactionDiagramSvgCatalog {
  ReactionDiagramSvgCatalog._();

  static String getSvgFor(String mechanismId) {
    switch (mechanismId.toLowerCase()) {
      case 'sn1':
        return sn1Svg;
      case 'sn2':
        return sn2Svg;
      case 'e1':
        return e1Svg;
      case 'e2':
        return e2Svg;
      case 'cannizzaro':
        return cannizzaroSvg;
      case 'aldol':
        return aldolSvg;
      case 'wittig':
        return wittigSvg;
      case 'diels_alder':
      case 'diels-alder':
        return dielsAlderSvg;
      case 'grignard':
        return grignardSvg;
      case 'beckmann':
        return beckmannSvg;
      case 'benzoin':
        return benzoinSvg;
      case 'michael':
        return michaelSvg;
      case 'claisen':
        return claisenSvg;
      case 'baeyer_villiger':
      case 'baeyer-villiger':
        return baeyerVilligerSvg;
      case 'favorskii':
        return favorskiiSvg;
      case 'mannich':
        return mannichSvg;
      case 'pinacol':
      case 'pinacol_pinacolone':
      case 'pinacol-pinacolone':
        return pinacolSvg;
      case 'robinson':
      case 'robinson_annulation':
      case 'robinson-annulation':
        return robinsonSvg;
      case 'curtius':
        return curtiusSvg;
      case 'cope':
        return copeSvg;
      case 'claisen_sigmatropic':
      case 'claisen-sigmatropic':
        return claisenSigmatropicSvg;
      case 'fischer_indole':
      case 'fischer-indole':
        return fischerIndoleSvg;
      case 'paal_knorr':
      case 'paal-knorr':
        return paalKnorrSvg;
      case 'chichibabin':
        return chichibabinSvg;
      case 'oxidative_addition':
      case 'oxidative-addition':
        return oxidativeAdditionSvg;
      case 'migratory_insertion':
      case 'migratory-insertion':
        return migratoryInsertionSvg;
      case 'reductive_elimination':
      case 'reductive-elimination':
        return reductiveEliminationSvg;
      default:
        return defaultGenericSvg(mechanismId);
    }
  }

  // Common SVG Header Definitions
  static const String _svgHeader = """
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#F59E0B" />
    </marker>
    <marker id="coral-arrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#F43F5E" />
    </marker>
    <marker id="cyan-arrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
    <marker id="green-arrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#10B981" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
""";

  // 1. SN1 REACTION SVG
  static const String sn1Svg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Step 1: Heterolytic C-X Cleavage (Slow, RDS)</text>
  <text x="40" y="85" fill="#FFFFFF" font-family="sans-serif" font-size="14" font-weight="bold">CH₃</text>
  <line x1="75" y1="80" x2="105" y2="105" stroke="#38BDF8" stroke-width="2.5"/>
  <text x="110" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="15" font-weight="bold">C</text>
  <line x1="75" y1="135" x2="105" y2="115" stroke="#38BDF8" stroke-width="2.5"/>
  <text x="40" y="142" fill="#FFFFFF" font-family="sans-serif" font-size="14" font-weight="bold">CH₃</text>
  <line x1="125" y1="108" x2="160" y2="108" stroke="#EF4444" stroke-width="2.5"/>
  <text x="168" y="112" fill="#EF4444" font-family="sans-serif" font-size="15" font-weight="bold">:Br:</text>
  <line x1="118" y1="95" x2="118" y2="65" stroke="#38BDF8" stroke-width="2.5"/>
  <text x="110" y="60" fill="#FFFFFF" font-family="sans-serif" font-size="14" font-weight="bold">CH₃</text>
  <!-- Electron pushing arrow: C-Br bond pair leaves onto Br -->
  <path d="M 142 104 Q 155 82 172 95" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="210" y1="108" x2="265" y2="108" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="218" y="96" fill="#F59E0B" font-family="sans-serif" font-size="11" font-weight="600">- :Br:⁻ (RDS)</text>
  <rect x="285" y="48" width="130" height="115" rx="10" fill="#1E1A38" stroke="#8B5CF6" stroke-dasharray="4,4"/>
  <text x="295" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Step 2: Planar 3° Carbocation</text>
  <text x="345" y="112" fill="#38BDF8" font-family="sans-serif" font-size="18" font-weight="bold">C⁺</text>
  <text x="300" y="75" fill="#FFFFFF" font-family="sans-serif" font-size="13">H₃C</text>
  <line x1="330" y1="75" x2="345" y2="100" stroke="#38BDF8" stroke-width="2"/>
  <text x="300" y="145" fill="#FFFFFF" font-family="sans-serif" font-size="13">H₃C</text>
  <line x1="330" y1="140" x2="345" y2="115" stroke="#38BDF8" stroke-width="2"/>
  <text x="390" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="13">CH₃</text>
  <line x1="365" y1="108" x2="385" y2="108" stroke="#38BDF8" stroke-width="2"/>
  <ellipse cx="352" cy="108" rx="8" ry="24" fill="none" stroke="#F59E0B" stroke-width="1.2" stroke-dasharray="2,2"/>
  <text x="445" y="70" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">:Nu⁻ (Top)</text>
  <path d="M 440 75 Q 395 75 365 95" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <text x="445" y="150" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">:Nu⁻ (Bottom)</text>
  <path d="M 440 145 Q 395 145 365 120" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="560" y1="108" x2="605" y2="108" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="568" y="96" fill="#10B981" font-family="sans-serif" font-size="11" font-weight="600">Fast</text>
  <rect x="620" y="55" width="125" height="100" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="630" y="80" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">t-Bu-Nu</text>
  <text x="630" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Racemic Mixture</text>
  <text x="630" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">50% Inversion</text>
  <text x="630" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">50% Retention</text>
</svg>
""";

  // 2. SN2 REACTION SVG
  static const String sn2Svg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Concerted Bimolecular Nucleophilic Substitution (Walden Inversion)</text>
  <text x="35" y="112" fill="#10B981" font-family="sans-serif" font-size="16" font-weight="bold">:OH⁻</text>
  <!-- Electron pushing arrow: OH lone pair backside attacks carbon -->
  <path d="M 75 105 Q 120 72 165 98" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <text x="80" y="68" fill="#F59E0B" font-family="sans-serif" font-size="11" font-weight="600">Backside Attack (180°)</text>
  <text x="175" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="16" font-weight="bold">C</text>
  <line x1="172" y1="95" x2="160" y2="70" stroke="#38BDF8" stroke-width="2"/>
  <text x="150" y="65" fill="#FFFFFF" font-family="sans-serif" font-size="12">H</text>
  <line x1="172" y1="118" x2="160" y2="145" stroke="#38BDF8" stroke-width="2"/>
  <text x="150" y="155" fill="#FFFFFF" font-family="sans-serif" font-size="12">H</text>
  <line x1="188" y1="108" x2="225" y2="108" stroke="#EF4444" stroke-width="2.5"/>
  <text x="232" y="112" fill="#EF4444" font-family="sans-serif" font-size="15" font-weight="bold">:Br:</text>
  <!-- Electron pushing arrow: C-Br bond pair expelled -->
  <path d="M 205 102 Q 220 82 238 96" fill="none" stroke="#F43F5E" stroke-width="2.2" stroke-linecap="round" marker-end="url(#coral-arrow)"/>
  <line x1="275" y1="108" x2="330" y2="108" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="350" y="45" width="190" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="360" y="30" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Trigonal Bipyramidal TS [ ‡ ]</text>
  <text x="365" y="112" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">δ⁻HO</text>
  <line x1="410" y1="108" x2="435" y2="108" stroke="#10B981" stroke-width="2" stroke-dasharray="3,3"/>
  <text x="440" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="16" font-weight="bold">C</text>
  <line x1="458" y1="108" x2="485" y2="108" stroke="#EF4444" stroke-width="2" stroke-dasharray="3,3"/>
  <text x="492" y="112" fill="#EF4444" font-family="sans-serif" font-size="14" font-weight="bold">Brδ⁻</text>
  <text x="438" y="70" fill="#FFFFFF" font-family="sans-serif" font-size="12">H</text>
  <line x1="445" y1="75" x2="445" y2="95" stroke="#38BDF8" stroke-width="2"/>
  <text x="438" y="145" fill="#FFFFFF" font-family="sans-serif" font-size="12">H</text>
  <line x1="445" y1="135" x2="445" y2="118" stroke="#38BDF8" stroke-width="2"/>
  <line x1="560" y1="108" x2="605" y2="108" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="620" y="55" width="125" height="100" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="630" y="80" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">HO-CH₃ + :Br:⁻</text>
  <text x="630" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">100% Inversion</text>
  <text x="630" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Walden Inversion</text>
  <text x="630" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Rate = k[Sub][Nu]</text>
</svg>
""";

  // 3. E1 ELIMINATION SVG
  static const String e1Svg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">E1 Elimination: Carbocation Formation & Base Deprotonation (Zaitsev Alkene)</text>
  <text x="35" y="110" fill="#FFFFFF" font-family="sans-serif" font-size="13" font-weight="bold">(CH₃)₂CH-C(CH₃)₂-Br</text>
  <!-- Arrow: C-Br bond pair leaves -->
  <path d="M 160 102 Q 175 80 195 95" fill="none" stroke="#F43F5E" stroke-width="2" stroke-linecap="round" marker-end="url(#coral-arrow)"/>
  <line x1="210" y1="105" x2="265" y2="105" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="220" y="93" fill="#F59E0B" font-family="sans-serif" font-size="11">- :Br:⁻ (RDS)</text>
  <rect x="280" y="48" width="180" height="115" rx="10" fill="#1E1A38" stroke="#8B5CF6"/>
  <text x="290" y="75" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">H-CH₂-C⁺(CH₃)₂</text>
  <text x="290" y="100" fill="#F59E0B" font-family="sans-serif" font-size="11">Base :B attacks β-H</text>
  <text x="330" y="145" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">:B</text>
  <!-- Arrow 1: Base lone pair attacks β-H -->
  <path d="M 335 130 Q 320 115 315 85" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow 2: C-H bond pair collapses into C=C π-bond -->
  <path d="M 320 75 Q 345 60 365 72" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="480" y1="105" x2="540" y2="105" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="490" y="93" fill="#10B981" font-family="sans-serif" font-size="11">- HB⁺ (Fast)</text>
  <rect x="560" y="48" width="180" height="115" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="575" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">(CH₃)₂C=CH-CH₃</text>
  <text x="575" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Major Zaitsev Alkene</text>
  <text x="575" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Most substituted alkene</text>
  <text x="575" y="142" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Thermodynamically stable</text>
</svg>
""";

  // 4. E2 ELIMINATION SVG
  static const String e2Svg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Concerted E2: Anti-Periplanar Geometry (180° H-C-C-Br Dihedral Angle)</text>
  <rect x="30" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.2"/>
  <text x="45" y="70" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">B:⁻</text>
  <!-- Arrow 1: Base attacks anti β-H -->
  <path d="M 65 65 Q 85 55 105 70" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <text x="105" y="75" fill="#FFFFFF" font-family="sans-serif" font-size="13" font-weight="bold">H</text>
  <line x1="110" y1="80" x2="110" y2="105" stroke="#38BDF8" stroke-width="2"/>
  <text x="105" y="120" fill="#FFFFFF" font-family="sans-serif" font-size="14" font-weight="bold">C₁</text>
  <!-- Arrow 2: C-H bond pair forms C=C double bond -->
  <path d="M 112 90 Q 130 85 145 108" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="125" y1="115" x2="160" y2="115" stroke="#38BDF8" stroke-width="2.5"/>
  <text x="165" y="120" fill="#FFFFFF" font-family="sans-serif" font-size="14" font-weight="bold">C₂</text>
  <line x1="172" y1="125" x2="172" y2="150" stroke="#EF4444" stroke-width="2"/>
  <text x="165" y="162" fill="#EF4444" font-family="sans-serif" font-size="13" font-weight="bold">:Br:</text>
  <!-- Arrow 3: C-Br bond pair departs as bromide -->
  <path d="M 172 135 Q 190 145 200 160" fill="none" stroke="#F43F5E" stroke-width="2.2" stroke-linecap="round" marker-end="url(#coral-arrow)"/>
  <line x1="270" y1="108" x2="325" y2="108" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="280" y="96" fill="#F59E0B" font-family="sans-serif" font-size="11">Concerted [ ‡ ]</text>
  <rect x="345" y="48" width="180" height="120" rx="10" fill="#1E1A38" stroke="#8B5CF6"/>
  <text x="355" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">E2 Transition State [ ‡ ]</text>
  <text x="355" y="95" fill="#E2E8F0" font-family="sans-serif" font-size="11">B···H bond forming</text>
  <text x="355" y="115" fill="#38BDF8" font-family="sans-serif" font-size="11">C₁···C₂ π-bond forming</text>
  <text x="355" y="135" fill="#EF4444" font-family="sans-serif" font-size="11">C₂···Br bond breaking</text>
  <text x="355" y="152" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Strict anti-coplanar required</text>
  <line x1="545" y1="108" x2="595" y2="108" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="610" y="48" width="135" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="620" y="78" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">R-CH=CH-R'</text>
  <text x="620" y="102" fill="#E2E8F0" font-family="sans-serif" font-size="11">+ HB + :Br:⁻</text>
  <text x="620" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Zaitsev (small base)</text>
  <text x="620" y="142" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Hofmann (bulky base)</text>
</svg>
""";

  // 5. CANNIZZARO REACTION SVG
  static const String cannizzaroSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Cannizzaro Reaction: Base-Induced Disproportionation via Intermolecular Hydride (H⁻) Transfer</text>
  <text x="35" y="85" fill="#FFFFFF" font-family="sans-serif" font-size="13" font-weight="bold">Ph-CH=O</text>
  <text x="35" y="115" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">+ :OH⁻</text>
  <!-- Arrow: OH- attacks carbonyl carbon -->
  <path d="M 85 110 Q 95 85 105 82" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="130" y1="95" x2="175" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="190" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.2"/>
  <text x="200" y="70" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Hydride Transfer TS [ ‡ ] (RDS)</text>
  <text x="200" y="95" fill="#38BDF8" font-family="sans-serif" font-size="12">Ph-CH(O⁻)(OH) + Ph-CH=O</text>
  <!-- Arrow: O- lone pair reforms C=O and expels H- -->
  <path d="M 235 120 Q 250 105 270 120" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow: H- attacks 2nd aldehyde carbon -->
  <path d="M 275 120 Q 310 110 345 120" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <text x="200" y="148" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Direct intermolecular H⁻ transfer</text>
  <line x1="425" y1="95" x2="475" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="430" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">Proton Transfer</text>
  <rect x="490" y="48" width="250" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="505" y="75" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">Ph-COO⁻ (Benzoate Salt)</text>
  <text x="505" y="100" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">+ Ph-CH₂OH (Benzyl Alcohol)</text>
  <text x="505" y="125" fill="#E2E8F0" font-family="sans-serif" font-size="11">Redox Disproportionation</text>
  <text x="505" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Requires aldehydes without α-hydrogens</text>
</svg>
""";

  // 6. ALDOL CONDENSATION SVG
  static const String aldolSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Aldol Condensation: Enolate Addition followed by E1cB Dehydration</text>
  <text x="35" y="80" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">R-CH₂-CHO</text>
  <text x="35" y="115" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">:OH⁻ Base</text>
  <!-- Arrow: Base deprotonates alpha-C -->
  <path d="M 85 110 Q 100 95 105 85" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="140" y1="95" x2="190" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="145" y="85" fill="#F59E0B" font-family="sans-serif" font-size="10.5">- H₂O</text>
  <rect x="205" y="48" width="180" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.2"/>
  <text x="215" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Resonance Enolate</text>
  <text x="215" y="95" fill="#38BDF8" font-family="sans-serif" font-size="12">[R-C⁻H-CHO ⇌ R-CH=CH-O⁻]</text>
  <text x="215" y="120" fill="#FFFFFF" font-family="sans-serif" font-size="12">+ R-CHO (2nd Carbonyl)</text>
  <!-- Arrow: Enolate alpha-carbon attacks carbonyl -->
  <path d="M 270 100 Q 300 125 330 115" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="400" y1="95" x2="450" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="405" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">C-C Bond</text>
  <rect x="465" y="48" width="125" height="120" rx="10" fill="#1E1A38" stroke="#8B5CF6"/>
  <text x="475" y="75" fill="#38BDF8" font-family="sans-serif" font-size="12" font-weight="bold">β-Hydroxy Aldehyde</text>
  <text x="475" y="100" fill="#FFFFFF" font-family="sans-serif" font-size="11">R-CH(OH)-CH(R)-CHO</text>
  <!-- Arrow: E1cB elimination under heat -->
  <path d="M 520 105 Q 545 130 570 105" fill="none" stroke="#F59E0B" stroke-width="2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="600" y1="95" x2="635" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="602" y="85" fill="#EF4444" font-family="sans-serif" font-size="10">Δ -H₂O</text>
  <rect x="645" y="48" width="105" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="652" y="78" fill="#10B981" font-family="sans-serif" font-size="12" font-weight="bold">α,β-Enal</text>
  <text x="652" y="102" fill="#E2E8F0" font-family="sans-serif" font-size="10.5">RCH=C(R)CHO</text>
  <text x="652" y="125" fill="#94A3B8" font-family="sans-serif" font-size="9.5">Conjugated</text>
</svg>
""";

  // 7. WITTIG REACTION SVG
  static const String wittigSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Wittig Reaction: Phosphonium Ylide [2+2] Cycloaddition & Retro-[2+2] Alkene Synthesis</text>
  <text x="30" y="80" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">Ph₃P⁺-C⁻H-R (Ylide)</text>
  <text x="30" y="110" fill="#FFFFFF" font-family="sans-serif" font-size="13">+ R'₂C=O (Carbonyl)</text>
  <!-- Arrow 1: Ylide carbanion attacks carbonyl carbon -->
  <path d="M 120 80 Q 150 95 165 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow 2: Carbonyl O attacks phosphorus -->
  <path d="M 155 110 Q 130 95 100 80" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="175" y1="95" x2="225" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="180" y="85" fill="#F59E0B" font-family="sans-serif" font-size="10.5">[2+2] Cyclo</text>
  <rect x="240" y="48" width="180" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="250" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Oxaphosphetane 4-Ring</text>
  <text x="270" y="100" fill="#FFFFFF" font-family="sans-serif" font-size="13">Ph₃P ── O</text>
  <text x="280" y="120" fill="#FFFFFF" font-family="sans-serif" font-size="13">│    │</text>
  <text x="270" y="140" fill="#FFFFFF" font-family="sans-serif" font-size="13">RCH ── CR'₂</text>
  <!-- Arrow 3: P-C bond cleaves to form P=O -->
  <path d="M 275 105 Q 290 90 305 98" fill="none" stroke="#F43F5E" stroke-width="2.2" stroke-linecap="round" marker-end="url(#coral-arrow)"/>
  <!-- Arrow 4: C-O bond cleaves to form C=C -->
  <path d="M 310 125 Q 300 145 285 138" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="435" y1="95" x2="485" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="440" y="85" fill="#EF4444" font-family="sans-serif" font-size="10.5">Retro-[2+2] (RDS)</text>
  <rect x="500" y="48" width="240" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="515" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">R'₂C=CH-R (Alkene)</text>
  <text x="515" y="105" fill="#38BDF8" font-family="sans-serif" font-size="13">+ Ph₃P=O (Triphenylphosphine Oxide)</text>
  <text x="515" y="130" fill="#E2E8F0" font-family="sans-serif" font-size="11">Driving force: High P=O bond energy</text>
  <text x="515" y="148" fill="#94A3B8" font-family="sans-serif" font-size="10.5">(Bond energy ≈ 540 kJ/mol)</text>
</svg>
""";

  // 8. DIELS-ALDER CYCLOADDITION SVG
  static const String dielsAlderSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Diels-Alder [4+2] Cycloaddition: Concerted Suprafacial Electron Movement & Endo Selectivity</text>
  <rect x="30" y="48" width="170" height="120" rx="10" fill="#1E1A38" stroke="#38BDF8" stroke-width="1.2"/>
  <text x="45" y="75" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">s-cis Diene (4π)</text>
  <text x="45" y="125" fill="#FFFFFF" font-family="sans-serif" font-size="13">+ Dienophile (2π)</text>
  <!-- Cyclic electron pushing arrows -->
  <!-- Arrow 1: Diene top double bond to dienophile top -->
  <path d="M 125 70 Q 155 75 165 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow 2: Dienophile double bond to diene bottom -->
  <path d="M 160 130 Q 145 155 115 145" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow 3: Diene bottom double bond shifts to middle -->
  <path d="M 105 140 Q 90 105 110 80" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="215" y1="105" x2="265" y2="105" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="220" y="95" fill="#F59E0B" font-family="sans-serif" font-size="11">Δ (Thermal)</text>
  <rect x="280" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="290" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Aromatic 6π-Electron TS [ ‡ ]</text>
  <text x="290" y="96" fill="#E2E8F0" font-family="sans-serif" font-size="11">Concerted [4s + 2s] overlap</text>
  <text x="290" y="118" fill="#10B981" font-family="sans-serif" font-size="11">Secondary orbital interactions</text>
  <text x="290" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Favors Kinetic Endo isomer</text>
  <line x1="515" y1="105" x2="565" y2="105" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="580" y="48" width="165" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="592" y="78" fill="#10B981" font-family="sans-serif" font-size="13.5" font-weight="bold">Cyclohexene Ring</text>
  <text x="592" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11">Formed 2 new σ-bonds</text>
  <text x="592" y="125" fill="#E2E8F0" font-family="sans-serif" font-size="11">&amp; 1 new π-bond</text>
  <text x="592" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Stereospecific syn</text>
</svg>
""";

  // 9. GRIGNARD REACTION SVG
  static const String grignardSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Grignard Reaction: Organomagnesium Nucleophilic Carbanion Addition</text>
  <text x="35" y="80" fill="#38BDF8" font-family="sans-serif" font-size="14" font-weight="bold">Rδ⁻ ── MgXδ⁺</text>
  <text x="35" y="115" fill="#FFFFFF" font-family="sans-serif" font-size="13">+ R'₂Cδ⁺=Oδ⁻</text>
  <!-- Arrow 1: Nucleophilic R-Mg bond electrons attack carbonyl carbon -->
  <path d="M 90 85 Q 120 100 135 112" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow 2: Carbonyl C=O pi-bond shifts to Oxygen -->
  <path d="M 140 105 Q 155 90 170 100" fill="none" stroke="#F43F5E" stroke-width="2.2" stroke-linecap="round" marker-end="url(#coral-arrow)"/>
  <line x1="185" y1="100" x2="235" y2="100" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="190" y="90" fill="#F59E0B" font-family="sans-serif" font-size="10.5">Ether/THF</text>
  <rect x="250" y="48" width="190" height="120" rx="10" fill="#1E1A38" stroke="#8B5CF6"/>
  <text x="260" y="75" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Halomagnesium Alkoxide</text>
  <text x="260" y="105" fill="#FFFFFF" font-family="sans-serif" font-size="13">R'₂C(R) ── O⁻MgX⁺</text>
  <text x="260" y="130" fill="#94A3B8" font-family="sans-serif" font-size="11">New C-C σ-bond formed</text>
  <!-- Arrow 3: Acid hydrolysis protonation -->
  <path d="M 370 115 Q 400 135 420 115" fill="none" stroke="#F59E0B" stroke-width="2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="455" y1="100" x2="505" y2="100" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="460" y="90" fill="#10B981" font-family="sans-serif" font-size="11">H₃O⁺ (Workup)</text>
  <rect x="520" y="48" width="220" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="535" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">R'₂C(R)-OH (Alcohol)</text>
  <text x="535" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">HCHO → 1° alcohol</text>
  <text x="535" y="125" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">RCHO → 2° alcohol</text>
  <text x="535" y="145" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Ketones/Esters → 3° alcohol</text>
</svg>
""";

  // 10. BECKMANN REARRANGEMENT SVG
  static const String beckmannSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Beckmann Rearrangement: Acid-Catalyzed Stereospecific Anti-Migration to Nitrilium Ion</text>
  <text x="35" y="80" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">Ketoxime: R(R')C=N-OH</text>
  <text x="35" y="110" fill="#FFFFFF" font-family="sans-serif" font-size="12">+ H⁺ (PCl₅ / H₂SO₄) → -OH₂⁺</text>
  <!-- Arrow 1: Anti R group migrates to Nitrogen -->
  <path d="M 85 85 Q 115 65 140 82" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow 2: Water leaving group departs -->
  <path d="M 145 80 Q 165 65 180 80" fill="none" stroke="#F43F5E" stroke-width="2.2" stroke-linecap="round" marker-end="url(#coral-arrow)"/>
  <line x1="205" y1="95" x2="255" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="270" y="48" width="200" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="280" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Anti-Periplanar Migration [ ‡ ]</text>
  <text x="280" y="96" fill="#E2E8F0" font-family="sans-serif" font-size="11">R group anti to -OH departs</text>
  <text x="280" y="118" fill="#38BDF8" font-family="sans-serif" font-size="11">Nitrilium Ion: [R-C≡N⁺-R']</text>
  <text x="280" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Complete stereochemical retention</text>
  <line x1="485" y1="95" x2="535" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="490" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">H₂O, taut.</text>
  <rect x="550" y="48" width="190" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="565" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">R-CO-NH-R'</text>
  <text x="565" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">N-Substituted Amide</text>
  <text x="565" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Cyclohexanone oxime →</text>
  <text x="565" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">ε-Caprolactam (Nylon-6 precursor)</text>
</svg>
""";

  // 11. BENZOIN CONDENSATION SVG
  static const String benzoinSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Benzoin Condensation: Cyanide-Catalyzed Umpolung (Reversed Polarity) Nucleophilic Addition</text>
  <text x="35" y="80" fill="#FFFFFF" font-family="sans-serif" font-size="13">Ph-CH=O + :C≡N:⁻</text>
  <!-- Arrow 1: Cyanide attacks carbonyl -->
  <path d="M 85 85 Q 110 65 125 78" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="165" y1="95" x2="215" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="230" y="48" width="190" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="240" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Umpolung Carbanion (d¹)</text>
  <text x="240" y="96" fill="#38BDF8" font-family="sans-serif" font-size="12">Ph-C⁻(OH)(CN)</text>
  <!-- Arrow 2: Inverted nucleophile carbanion attacks 2nd benzaldehyde -->
  <path d="M 285 100 Q 320 120 350 100" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <text x="240" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">CN⁻ stabilizes α-carbanion</text>
  <line x1="435" y1="95" x2="485" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="440" y="85" fill="#10B981" font-family="sans-serif" font-size="11">- :CN⁻</text>
  <rect x="500" y="48" width="240" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="515" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">Ph-CH(OH)-CO-Ph (Benzoin)</text>
  <text x="515" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">α-Hydroxy Ketone product</text>
  <text x="515" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Reagent: NaCN / KCN in aq. EtOH</text>
  <text x="515" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">CN⁻ acts as catalyst &amp; leaving group</text>
</svg>
""";

  // 12. MICHAEL ADDITION SVG
  static const String michaelSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Michael Addition: Thermodynamically Controlled 1,4-Conjugate Addition of Stabilized Enolates</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="12.5" font-weight="bold">Donor: CH(CO₂Et)₂⁻</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">+ Acceptor: CH₂=CH-CO-R</text>
  <!-- Arrow 1: Michael donor attacks β-carbon of conjugated system -->
  <path d="M 85 85 Q 120 100 145 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow 2: C=C bond shifts to enol double bond -->
  <path d="M 155 110 Q 165 95 180 100" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="195" y1="95" x2="245" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="260" y="48" width="190" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.2"/>
  <text x="270" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Enolate Intermediate</text>
  <text x="270" y="96" fill="#38BDF8" font-family="sans-serif" font-size="11.5">R-C(O⁻)=CH-CH₂-CH(CO₂Et)₂</text>
  <text x="270" y="120" fill="#E2E8F0" font-family="sans-serif" font-size="11">Soft-soft nucleophilic interaction</text>
  <text x="270" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Thermodynamic 1,4-selectivity</text>
  <line x1="465" y1="95" x2="515" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="470" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">H⁺ (taut.)</text>
  <rect x="530" y="48" width="210" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="545" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">1,5-Dicarbonyl Adduct</text>
  <text x="545" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">R-CO-CH₂-CH₂-CH(CO₂Et)₂</text>
  <text x="545" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Key building block for</text>
  <text x="545" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Robinson annulation</text>
</svg>
""";

  // 13. CLAISEN ESTER CONDENSATION SVG
  static const String claisenSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Claisen Ester Condensation: Base-Promoted Nucleophilic Acyl Substitution via Tetrahedral Intermediate</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">2 CH₃CO₂Et + NaOEt</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">Enolate: [⁻CH₂CO₂Et]</text>
  <!-- Arrow 1: Ester enolate attacks 2nd ester carbonyl -->
  <path d="M 85 85 Q 120 100 145 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="185" y1="95" x2="235" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="250" y="48" width="200" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.2"/>
  <text x="260" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Tetrahedral Intermediate</text>
  <text x="260" y="96" fill="#38BDF8" font-family="sans-serif" font-size="12">CH₃-C(O⁻)(OEt)-CH₂CO₂Et</text>
  <!-- Arrow 2: O- reforms C=O and expels ethoxide -->
  <path d="M 310 105 Q 330 85 350 95" fill="none" stroke="#F43F5E" stroke-width="2.2" stroke-linecap="round" marker-end="url(#coral-arrow)"/>
  <text x="260" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">- :OEt⁻ (Elimination)</text>
  <line x1="465" y1="95" x2="515" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="530" y="48" width="210" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="545" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">CH₃COCH₂CO₂Et</text>
  <text x="545" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Ethyl Acetoacetate (EAA)</text>
  <text x="545" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">β-Keto Ester</text>
  <text x="545" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Driven by deprotonation of EAA</text>
</svg>
""";

  // 14. BAEYER-VILLIGER OXIDATION SVG
  static const String baeyerVilligerSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Baeyer-Villiger Oxidation: Peroxyacid Addition & Concerted Criegee Migration to Ester/Lactone</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">Ketone: R-CO-R'</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">+ m-CPBA / RCO₃H</text>
  <!-- Arrow 1: Peracid oxygen attacks carbonyl -->
  <path d="M 85 85 Q 115 100 135 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="175" y1="95" x2="225" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="240" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="250" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Criegee Intermediate [ ‡ ]</text>
  <text x="250" y="96" fill="#38BDF8" font-family="sans-serif" font-size="12">R-C(OH)(O-O-COAr)-R'</text>
  <!-- Arrow 2: R group migrates to peroxy Oxygen -->
  <path d="M 290 100 Q 320 85 350 95" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow 3: Weak O-O bond cleaves -->
  <path d="M 355 100 Q 380 90 400 105" fill="none" stroke="#F43F5E" stroke-width="2.2" stroke-linecap="round" marker-end="url(#coral-arrow)"/>
  <line x1="475" y1="95" x2="525" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="540" y="48" width="200" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="555" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">R-CO-O-R' (Ester)</text>
  <text x="555" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Migratory Aptitude:</text>
  <text x="555" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">3° alkyl > 2° alkyl ≈ Ph > 1° > Me</text>
  <text x="555" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Cyclic ketones → Lactones</text>
</svg>
""";

  // 15. FAVORSKII REARRANGEMENT SVG
  static const String favorskiiSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Favorskii Rearrangement: Base-Promoted Intramolecular Displacement via Cyclopropanone</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">α-Halo Ketone</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">R-CH(Cl)-CO-CH₂-R'</text>
  <!-- Arrow 1: Base deprotonates alpha prime carbon -->
  <path d="M 85 85 Q 110 100 135 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="175" y1="95" x2="225" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="180" y="85" fill="#F59E0B" font-family="sans-serif" font-size="10.5">- :Cl:⁻</text>
  <rect x="240" y="48" width="200" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="250" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Cyclopropanone (3-Ring)</text>
  <text x="250" y="96" fill="#38BDF8" font-family="sans-serif" font-size="12">Highly Strained 3-Membered Ring</text>
  <!-- Arrow 2: Nucleophile alkoxide attacks strained cyclopropanone -->
  <path d="M 310 115 Q 340 135 370 115" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="455" y1="95" x2="505" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="460" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">Ring Opening</text>
  <rect x="520" y="48" width="220" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="535" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">Branched Ester / Acid</text>
  <text x="535" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">R-CH(R')-CO₂R''</text>
  <text x="535" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Symmetrical cyclopropanone</text>
  <text x="535" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">opens to more stable carbanion</text>
</svg>
""";

  // 16. MANNICH REACTION SVG
  static const String mannichSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Mannich Reaction: 3-Component Condensation via Electrophilic Iminium Ion</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">HCHO + R₂NH + H⁺</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">→ [CH₂=N⁺R₂] (Iminium)</text>
  <!-- Arrow 1: Enol double bond attacks electrophilic iminium -->
  <path d="M 85 85 Q 120 100 145 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="175" y1="95" x2="225" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="240" y="48" width="200" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.2"/>
  <text x="250" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Aminoalkylation</text>
  <text x="250" y="96" fill="#38BDF8" font-family="sans-serif" font-size="12">Enol attacks [CH₂=N⁺R₂]</text>
  <text x="250" y="120" fill="#E2E8F0" font-family="sans-serif" font-size="11">C-C bond formation</text>
  <text x="250" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Acid or base catalysis</text>
  <line x1="455" y1="95" x2="505" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="520" y="48" width="220" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="535" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">Mannich Base</text>
  <text x="535" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">β-Amino Carbonyl Compound</text>
  <text x="535" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">R-CO-CH₂-CH₂-NR₂</text>
  <text x="535" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Thermal elimination → Enone</text>
</svg>
""";

  // 17. PINACOL-PINACOLONE REARRANGEMENT SVG
  static const String pinacolSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Pinacol Rearrangement: Acid-Catalyzed 1,2-Alkyl/Aryl Shift in 1,2-Diols</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">Pinacol (1,2-Diol)</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">(CH₃)₂C(OH)-C(OH)(CH₃)₂</text>
  <!-- Arrow 1: Protonated OH leaves as H2O -->
  <path d="M 85 85 Q 115 100 135 110" fill="none" stroke="#F43F5E" stroke-width="2.2" stroke-linecap="round" marker-end="url(#coral-arrow)"/>
  <line x1="175" y1="95" x2="225" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="180" y="85" fill="#F59E0B" font-family="sans-serif" font-size="10.5">- H₂O</text>
  <rect x="240" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="250" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">1,2-Methyl Shift [ ‡ ]</text>
  <text x="250" y="96" fill="#38BDF8" font-family="sans-serif" font-size="12">Me₃C ── C⁺(OH)Me</text>
  <!-- Arrow 2: Methyl shifts to carbocation -->
  <path d="M 285 100 Q 315 80 345 95" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow 3: OH lone pair forms C=O -->
  <path d="M 350 95 Q 365 75 385 85" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="475" y1="95" x2="525" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="480" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">- H⁺</text>
  <rect x="540" y="48" width="200" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="555" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">Pinacolone (Ketone)</text>
  <text x="555" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">(CH₃)₃C-CO-CH₃</text>
  <text x="555" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Oxonium ion resonance</text>
  <text x="555" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">provides thermodynamic drive</text>
</svg>
""";

  // 18. ROBINSON ANNULATION SVG
  static const String robinsonSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Robinson Annulation: Michael Addition Followed by Intramolecular Aldol Cyclization</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="12.5" font-weight="bold">Cyclohexanone Enolate</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">+ Methyl Vinyl Ketone (MVK)</text>
  <!-- Arrow 1: Michael addition to MVK -->
  <path d="M 85 85 Q 120 100 145 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="185" y1="95" x2="235" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="190" y="85" fill="#F59E0B" font-family="sans-serif" font-size="10.5">Michael</text>
  <rect x="250" y="48" width="200" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.2"/>
  <text x="260" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">1,5-Dicarbonyl Adduct</text>
  <text x="260" y="96" fill="#38BDF8" font-family="sans-serif" font-size="11.5">Intramolecular Aldol Attack</text>
  <!-- Arrow 2: Enolate attacks 2nd carbonyl to form 6-membered ring -->
  <path d="M 310 115 Q 340 135 370 115" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="465" y1="95" x2="515" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="470" y="85" fill="#EF4444" font-family="sans-serif" font-size="10.5">Δ -H₂O</text>
  <rect x="530" y="48" width="210" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="545" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">Fused Decalin Ring</text>
  <text x="545" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Fused 6-Membered Enone</text>
  <text x="545" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Core skeleton of steroid &amp;</text>
  <text x="545" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">terpene natural products</text>
</svg>
""";

  // 19. CURTIUS REARRANGEMENT SVG
  static const String curtiusSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Curtius Rearrangement: Thermal Decomposition of Acyl Azide to Isocyanate & 1° Amine</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">Acyl Azide: R-CO-N₃</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">[R-CO-N⁻-N⁺≡N]</text>
  <!-- Arrow 1: R group migrates to N while N2 leaves -->
  <path d="M 85 85 Q 115 65 140 82" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow 2: N2 departs -->
  <path d="M 145 80 Q 165 65 180 80" fill="none" stroke="#F43F5E" stroke-width="2.2" stroke-linecap="round" marker-end="url(#coral-arrow)"/>
  <line x1="185" y1="95" x2="235" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="190" y="85" fill="#F59E0B" font-family="sans-serif" font-size="10.5">Δ, -N₂ (g)</text>
  <rect x="250" y="48" width="200" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="260" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Isocyanate Intermediate</text>
  <text x="260" y="96" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">R-N=C=O</text>
  <text x="260" y="120" fill="#E2E8F0" font-family="sans-serif" font-size="11">Concerted retention of config</text>
  <text x="260" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">N₂ driving force (entropy)</text>
  <line x1="465" y1="95" x2="515" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="470" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">H₂O, -CO₂</text>
  <rect x="530" y="48" width="210" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="545" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">R-NH₂ (1° Amine)</text>
  <text x="545" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">+ CO₂ (g)</text>
  <text x="545" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">+ R'OH → Carbamates</text>
  <text x="545" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">+ R'NH₂ → Ureas</text>
</svg>
""";

  // 20. COPE REARRANGEMENT SVG
  static const String copeSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Cope Rearrangement: Thermal [3,3]-Sigmatropic Concerted Pericyclic Shift in 1,5-Hexadienes</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">1,5-Hexadiene Substrate</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">C₁=C₂-C₃-C₄-C₅=C₆</text>
  <!-- Cyclic 6-electron concerted electron flow -->
  <path d="M 85 85 Q 115 65 140 82" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <path d="M 145 80 Q 165 65 180 80" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="185" y1="95" x2="235" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="190" y="85" fill="#F59E0B" font-family="sans-serif" font-size="10.5">Δ, [3,3]</text>
  <rect x="250" y="48" width="210" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="260" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Chair-like 6-Electron TS [ ‡ ]</text>
  <text x="260" y="96" fill="#38BDF8" font-family="sans-serif" font-size="11.5">Concerted cleavage of C₃-C₄ σ-bond</text>
  <text x="260" y="118" fill="#10B981" font-family="sans-serif" font-size="11.5">Simultaneous C₁-C₆ σ-bond forming</text>
  <text x="260" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Chair conformation preferred over boat</text>
  <line x1="475" y1="95" x2="525" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="540" y="48" width="200" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="555" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">Isomeric 1,5-Hexadiene</text>
  <text x="555" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Equilibrium favors more</text>
  <text x="555" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">substituted / conjugated diene</text>
  <text x="555" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Oxy-Cope: Driven by enol tautomerism</text>
</svg>
""";

  // 21. CLAISEN SIGMATROPIC REARRANGEMENT SVG
  static const String claisenSigmatropicSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Claisen Sigmatropic: Thermal [3,3]-Rearrangement of Allyl Vinyl / Phenyl Ethers</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">Allyl Phenyl Ether</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">Ph-O-CH₂-CH=CH₂</text>
  <!-- Arrow 1: Concerted [3,3] sigmatropic cyclic shift -->
  <path d="M 85 85 Q 115 65 140 82" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <path d="M 145 80 Q 165 65 180 80" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="185" y1="95" x2="235" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="190" y="85" fill="#F59E0B" font-family="sans-serif" font-size="10.5">Δ (200 °C)</text>
  <rect x="250" y="48" width="210" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="260" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">6-Membered Chair TS [ ‡ ]</text>
  <text x="260" y="96" fill="#38BDF8" font-family="sans-serif" font-size="11.5">Concerted C-O cleavage &amp; C-C bond</text>
  <text x="260" y="118" fill="#E2E8F0" font-family="sans-serif" font-size="11">Forms ortho-dienone intermediate</text>
  <text x="260" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Allyl inversion (Cγ attaches to ring)</text>
  <line x1="475" y1="95" x2="525" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="480" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">Enolization</text>
  <rect x="540" y="48" width="200" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="555" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">ortho-Allyl Phenol</text>
  <text x="555" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Rearomatization provides</text>
  <text x="555" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">strong driving force</text>
  <text x="555" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Aliphatic: γ,δ-unsaturated carbonyl</text>
</svg>
""";

  // 22. FISCHER INDOLE SYNTHESIS SVG
  static const String fischerIndoleSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Fischer Indole Synthesis: Acid-Catalyzed Cyclization via [3,3]-Sigmatropic Rearrangement</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="12.5" font-weight="bold">Phenylhydrazine + Ketone</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">Ph-NH-N=C(Me)R (Hydrazone)</text>
  <!-- Arrow 1: Ene-hydrazine tautomerism and sigmatropic shift -->
  <path d="M 85 85 Q 115 65 140 82" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="185" y1="95" x2="235" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="190" y="85" fill="#F59E0B" font-family="sans-serif" font-size="10.5">ZnCl₂ / H⁺</text>
  <rect x="250" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="260" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">[3,3]-Sigmatropic Shift [ ‡ ]</text>
  <text x="260" y="96" fill="#38BDF8" font-family="sans-serif" font-size="11.5">Cleaves weak N-N σ-bond</text>
  <text x="260" y="118" fill="#E2E8F0" font-family="sans-serif" font-size="11">Creates key C-C aromatic bond</text>
  <text x="260" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Intramolecular aminal cyclization</text>
  <line x1="485" y1="95" x2="535" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="490" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">- NH₃ (g)</text>
  <rect x="550" y="48" width="190" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="565" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">2-Substituted Indole</text>
  <text x="565" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">10π Aromatic Heterocycle</text>
  <text x="565" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Core of Tryptophan, Serotonin,</text>
  <text x="565" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">&amp; Indole Alkaloid Drugs</text>
</svg>
""";

  // 23. PAAL-KNORR SYNTHESIS SVG
  static const String paalKnorrSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Paal-Knorr Pyrrole Synthesis: Condensation of 1,4-Dicarbonyl Compounds</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">1,4-Dicarbonyl Substrate</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">R-CO-CH₂-CH₂-CO-R</text>
  <!-- Arrow 1: Nucleophile adds to carbonyl -->
  <path d="M 85 85 Q 115 100 135 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="175" y1="95" x2="225" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="180" y="85" fill="#F59E0B" font-family="sans-serif" font-size="10.5">Reagent</text>
  <rect x="240" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.2"/>
  <text x="250" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Cyclic Hemiaminal / Diol</text>
  <text x="250" y="96" fill="#38BDF8" font-family="sans-serif" font-size="11.5">+ P₂O₅ / H₂SO₄ → Furan</text>
  <text x="250" y="118" fill="#10B981" font-family="sans-serif" font-size="11.5">+ R'NH₂ / (NH₄)₂CO₃ → Pyrrole</text>
  <text x="250" y="140" fill="#EF4444" font-family="sans-serif" font-size="11.5">+ P₄S₁₀ / Lawesson → Thiophene</text>
  <line x1="475" y1="95" x2="525" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="480" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">- 2 H₂O</text>
  <rect x="540" y="48" width="200" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="555" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">2,5-Dialkyl Heterocycle</text>
  <text x="555" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">6π Aromatic Heteroaromatic</text>
  <text x="555" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">X = O (Furan), NH (Pyrrole),</text>
  <text x="555" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">S (Thiophene)</text>
</svg>
""";

  // 24. CHICHIBABIN REACTION SVG
  static const String chichibabinSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Chichibabin Amination: Nucleophilic Aromatic Substitution of Pyridine with Sodamide</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">Pyridine Ring</text>
  <text x="35" y="112" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">+ :NH₂⁻ Na⁺ (Sodamide)</text>
  <!-- Arrow 1: Amide nucleophile attacks C2 of pyridine -->
  <path d="M 85 85 Q 115 100 135 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="175" y1="95" x2="225" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="180" y="85" fill="#F59E0B" font-family="sans-serif" font-size="10.5">Liquid NH₃</text>
  <rect x="240" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="250" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Meisenheimer-type Complex [ ‡ ]</text>
  <text x="250" y="96" fill="#38BDF8" font-family="sans-serif" font-size="11.5">Negative charge placed on N</text>
  <text x="250" y="118" fill="#E2E8F0" font-family="sans-serif" font-size="11">C2 attack is regioselective</text>
  <text x="250" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Hydride (H⁻) is leaving group</text>
  <line x1="475" y1="95" x2="525" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="480" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">- H₂ (g)</text>
  <rect x="540" y="48" width="200" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="555" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">2-Aminopyridine</text>
  <text x="555" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">S_NAr Mechanism</text>
  <text x="555" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Key intermediate for sulfa drugs</text>
  <text x="555" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">&amp; antihistamines</text>
</svg>
""";

  // 25. ORGANOMETALLIC: OXIDATIVE ADDITION SVG
  static const String oxidativeAdditionSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Oxidative Addition: Metal Center Oxidation (Mⁿ → Mⁿ⁺²) & Coordination Number Increase</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">L_n M⁰ (14e⁻ / 16e⁻)</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">+ Substrate: R ── X</text>
  <!-- Arrow 1: Metal d-orbital electrons insert into R-X sigma bond -->
  <path d="M 85 85 Q 115 100 135 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="175" y1="95" x2="225" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="240" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="250" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">3-Center 2-Electron TS [ ‡ ]</text>
  <text x="250" y="96" fill="#38BDF8" font-family="sans-serif" font-size="11.5">Concerted side-on approach</text>
  <text x="250" y="118" fill="#E2E8F0" font-family="sans-serif" font-size="11">Metal donates into σ*(R-X)</text>
  <text x="250" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Favored by electron-rich low-valent metals</text>
  <line x1="475" y1="95" x2="525" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="540" y="48" width="200" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="555" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">L_n Mᴵᴵ(R)(X)</text>
  <text x="555" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">16e⁻ / 18e⁻ Complex</text>
  <text x="555" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Formal OS increases by +2</text>
  <text x="555" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Coordination number +2</text>
</svg>
""";

  // 26. ORGANOMETALLIC: MIGRATORY INSERTION SVG
  static const String migratoryInsertionSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Migratory Insertion: Intramolecular Cis-Migration of Ligand R onto Coordinated CO / Alkene</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">L_n M(CO)(R)</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">Cis Coordinated Ligands</text>
  <!-- Arrow 1: R group migrates to carbonyl carbon -->
  <path d="M 85 85 Q 115 100 135 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="175" y1="95" x2="225" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="240" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="250" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">1,1-Migratory Transition State [ ‡ ]</text>
  <text x="250" y="96" fill="#38BDF8" font-family="sans-serif" font-size="11.5">R group migrates with retention</text>
  <text x="250" y="118" fill="#E2E8F0" font-family="sans-serif" font-size="11">Leaves vacant coordination site (□)</text>
  <text x="250" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Formal oxidation state unchanged</text>
  <line x1="475" y1="95" x2="525" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="480" y="85" fill="#10B981" font-family="sans-serif" font-size="10.5">+ L (Trapping)</text>
  <rect x="540" y="48" width="200" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="555" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">L_n M(COR)(L)</text>
  <text x="555" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Acyl Metal Complex</text>
  <text x="555" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Key step in Hydroformylation</text>
  <text x="555" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">&amp; Monsanto Acetic Acid Process</text>
</svg>
""";

  // 27. ORGANOMETALLIC: REDUCTIVE ELIMINATION SVG
  static const String reductiveEliminationSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Reductive Elimination: Metal Reduction (Mⁿ⁺² → Mⁿ) & C-C / C-H Coupling Product Release</text>
  <text x="35" y="78" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">L_n Mᴵᴵ(R)(R')</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">Cis-Oriented Ligands</text>
  <!-- Arrow 1: M-R bond electrons attack R' to form C-C bond -->
  <path d="M 85 85 Q 115 100 135 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <!-- Arrow 2: M-R' bond electrons return to metal center -->
  <path d="M 140 105 Q 160 85 175 95" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="185" y1="95" x2="235" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="240" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="250" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Concerted Coupling TS [ ‡ ]</text>
  <text x="250" y="96" fill="#38BDF8" font-family="sans-serif" font-size="11.5">Strict cis-geometry required</text>
  <text x="250" y="118" fill="#E2E8F0" font-family="sans-serif" font-size="11">R-R' σ-bond forming simultaneously</text>
  <text x="250" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Electron density returns to metal d-orbitals</text>
  <line x1="475" y1="95" x2="525" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="540" y="48" width="200" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="555" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">R ── R' (Coupled Product)</text>
  <text x="555" y="105" fill="#38BDF8" font-family="sans-serif" font-size="13">+ L_n M⁰ (Active Catalyst)</text>
  <text x="555" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Cross-Coupling product</text>
  <text x="555" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">(Suzuki, Heck, Negishi, Stille)</text>
</svg>
""";

  // GENERIC DEFAULT MECHANISM
  static String defaultGenericSvg(String name) {
    final cleanName = name.replaceAll('_', ' ').replaceAll('-', ' ').toUpperCase();
    return """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  $_svgHeader
  <text x="30" y="30" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Reaction Mechanism: $cleanName</text>
  <text x="35" y="80" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">Reactant Complex</text>
  <text x="35" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="12">Substrate + Reagent</text>
  <path d="M 85 85 Q 115 100 135 110" fill="none" stroke="#F59E0B" stroke-width="2.2" stroke-linecap="round" marker-end="url(#arrow)"/>
  <line x1="175" y1="95" x2="225" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="240" y="48" width="220" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="250" y="72" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Transition State / Intermediate [ ‡ ]</text>
  <text x="250" y="96" fill="#38BDF8" font-family="sans-serif" font-size="11.5">Electron redistribution &amp; bond reorganization</text>
  <text x="250" y="118" fill="#E2E8F0" font-family="sans-serif" font-size="11">Activation barrier determines reaction rate</text>
  <text x="250" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Governed by orbital symmetry &amp; thermodynamics</text>
  <line x1="475" y1="95" x2="525" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <rect x="540" y="48" width="200" height="120" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="555" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">Target Product</text>
  <text x="555" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Thermodynamically Favored</text>
  <text x="555" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">High selectivity &amp; yield</text>
  <text x="555" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">MSc Chemistry Mechanism</text>
</svg>
""";
  }
}
