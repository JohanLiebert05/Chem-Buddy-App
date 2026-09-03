/// Catalog of vector SVG diagrams for MSc organic reaction mechanisms.
/// Formatted with high-contrast dark theme colors (#141224 background, #A78BFA purple labels,
/// #38BDF8 cyan chemical bonds, #F59E0B gold electron movement arrows, and #10B981 green products).
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
      default:
        return defaultGenericSvg(mechanismId);
    }
  }

  // 1. SN1 REACTION SVG
  static const String sn1Svg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  <defs>
    <marker id="arrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#F59E0B" />
    </marker>
    <marker id="cyan-arrow" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Step 1: Leaving Group Departure (Slow, RDS)</text>
  <text x="40" y="85" fill="#FFFFFF" font-family="sans-serif" font-size="14" font-weight="bold">CH₃</text>
  <line x1="75" y1="80" x2="105" y2="105" stroke="#38BDF8" stroke-width="2.5"/>
  <text x="110" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="15" font-weight="bold">C</text>
  <line x1="75" y1="135" x2="105" y2="115" stroke="#38BDF8" stroke-width="2.5"/>
  <text x="40" y="142" fill="#FFFFFF" font-family="sans-serif" font-size="14" font-weight="bold">CH₃</text>
  <line x1="125" y1="108" x2="160" y2="108" stroke="#EF4444" stroke-width="2.5"/>
  <text x="168" y="112" fill="#EF4444" font-family="sans-serif" font-size="15" font-weight="bold">Br</text>
  <line x1="118" y1="95" x2="118" y2="65" stroke="#38BDF8" stroke-width="2.5"/>
  <text x="110" y="60" fill="#FFFFFF" font-family="sans-serif" font-size="14" font-weight="bold">CH₃</text>
  <path d="M 142 100 Q 155 80 170 95" fill="none" stroke="#F59E0B" stroke-width="2" marker-end="url(#arrow)"/>
  <line x1="210" y1="108" x2="265" y2="108" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="220" y="98" fill="#F59E0B" font-family="sans-serif" font-size="11" font-weight="600">- Br⁻ (RDS)</text>
  <rect x="285" y="48" width="130" height="115" rx="10" fill="#1E1A38" stroke="#8B5CF6" stroke-dasharray="4,4"/>
  <text x="295" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Step 2: Planar 3° Carbocation</text>
  <text x="345" y="112" fill="#38BDF8" font-family="sans-serif" font-size="18" font-weight="bold">C⁺</text>
  <text x="300" y="75" fill="#FFFFFF" font-family="sans-serif" font-size="13">H₃C</text>
  <line x1="330" y1="75" x2="345" y2="100" stroke="#38BDF8" stroke-width="2"/>
  <text x="300" y="145" fill="#FFFFFF" font-family="sans-serif" font-size="13">H₃C</text>
  <line x1="330" y1="140" x2="345" y2="115" stroke="#38BDF8" stroke-width="2"/>
  <text x="390" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="13">CH₃</text>
  <line x1="365" y1="108" x2="385" y2="108" stroke="#38BDF8" stroke-width="2"/>
  <ellipse cx="352" cy="108" rx="8" ry="24" fill="none" stroke="#F59E0B" stroke-width="1.2" stroke-dasharray="2,2"/>
  <text x="445" y="70" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">Nu⁻ (Top face)</text>
  <path d="M 440 75 Q 395 75 365 95" fill="none" stroke="#F59E0B" stroke-width="2" marker-end="url(#arrow)"/>
  <text x="445" y="150" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">Nu⁻ (Bottom face)</text>
  <path d="M 440 145 Q 395 145 365 120" fill="none" stroke="#F59E0B" stroke-width="2" marker-end="url(#arrow)"/>
  <line x1="560" y1="108" x2="605" y2="108" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow)"/>
  <text x="568" y="98" fill="#10B981" font-family="sans-serif" font-size="11" font-weight="600">Fast</text>
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
  <defs>
    <marker id="arrow2" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#F59E0B" />
    </marker>
    <marker id="cyan-arrow2" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Concerted Bimolecular Nucleophilic Substitution (Walden Inversion)</text>
  <text x="40" y="112" fill="#10B981" font-family="sans-serif" font-size="16" font-weight="bold">:OH⁻</text>
  <path d="M 75 105 Q 120 75 160 100" fill="none" stroke="#F59E0B" stroke-width="2.2" marker-end="url(#arrow2)"/>
  <text x="80" y="70" fill="#F59E0B" font-family="sans-serif" font-size="11" font-weight="600">Backside Attack 180°</text>
  <text x="175" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="16" font-weight="bold">C</text>
  <line x1="172" y1="95" x2="160" y2="70" stroke="#38BDF8" stroke-width="2"/>
  <text x="150" y="65" fill="#FFFFFF" font-family="sans-serif" font-size="12">H</text>
  <line x1="172" y1="118" x2="160" y2="145" stroke="#38BDF8" stroke-width="2"/>
  <text x="150" y="155" fill="#FFFFFF" font-family="sans-serif" font-size="12">H</text>
  <line x1="188" y1="108" x2="225" y2="108" stroke="#EF4444" stroke-width="2.5"/>
  <text x="232" y="112" fill="#EF4444" font-family="sans-serif" font-size="15" font-weight="bold">Br</text>
  <path d="M 210 100 Q 225 85 240 98" fill="none" stroke="#F59E0B" stroke-width="2" marker-end="url(#arrow2)"/>
  <line x1="275" y1="108" x2="330" y2="108" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow2)"/>
  <rect x="350" y="45" width="190" height="120" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="360" y="32" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Trigonal Bipyramidal TS [‡]</text>
  <text x="365" y="112" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">δ⁻HO</text>
  <line x1="410" y1="108" x2="435" y2="108" stroke="#10B981" stroke-width="2" stroke-dasharray="3,3"/>
  <text x="440" y="112" fill="#FFFFFF" font-family="sans-serif" font-size="16" font-weight="bold">C</text>
  <line x1="458" y1="108" x2="485" y2="108" stroke="#EF4444" stroke-width="2" stroke-dasharray="3,3"/>
  <text x="492" y="112" fill="#EF4444" font-family="sans-serif" font-size="14" font-weight="bold">Brδ⁻</text>
  <text x="438" y="70" fill="#FFFFFF" font-family="sans-serif" font-size="12">H</text>
  <line x1="445" y1="75" x2="445" y2="95" stroke="#38BDF8" stroke-width="2"/>
  <text x="438" y="145" fill="#FFFFFF" font-family="sans-serif" font-size="12">H</text>
  <line x1="445" y1="135" x2="445" y2="118" stroke="#38BDF8" stroke-width="2"/>
  <line x1="560" y1="108" x2="605" y2="108" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow2)"/>
  <rect x="620" y="55" width="125" height="100" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="630" y="80" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">HO-CH₃ + Br⁻</text>
  <text x="630" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">100% Inversion</text>
  <text x="630" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Walden Inversion</text>
  <text x="630" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Rate = k[Sub][Nu]</text>
</svg>
""";

  // 3. E1 ELIMINATION SVG
  static const String e1Svg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  <defs>
    <marker id="arrow3" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#F59E0B" />
    </marker>
    <marker id="cyan-arrow3" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">E1 Elimination: Carbocation Formation followed by Base Deprotonation (Zaitsev Alkene)</text>
  <text x="40" y="110" fill="#FFFFFF" font-family="sans-serif" font-size="14" font-weight="bold">(CH₃)₂CH-C(CH₃)₂-Br</text>
  <line x1="225" y1="105" x2="275" y2="105" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow3)"/>
  <text x="235" y="95" fill="#F59E0B" font-family="sans-serif" font-size="11">- Br⁻ (RDS)</text>
  <rect x="290" y="50" width="170" height="110" rx="10" fill="#1E1A38" stroke="#8B5CF6"/>
  <text x="300" y="75" fill="#38BDF8" font-family="sans-serif" font-size="13">H-CH₂-C⁺(CH₃)₂</text>
  <text x="300" y="105" fill="#F59E0B" font-family="sans-serif" font-size="11">Base :B attacks β-H</text>
  <path d="M 335 130 Q 320 115 315 85" fill="none" stroke="#F59E0B" stroke-width="2" marker-end="url(#arrow3)"/>
  <text x="330" y="145" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">:B</text>
  <line x1="480" y1="105" x2="540" y2="105" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow3)"/>
  <text x="490" y="95" fill="#10B981" font-family="sans-serif" font-size="11">- HB⁺ (Fast)</text>
  <rect x="560" y="50" width="180" height="110" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="575" y="80" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">(CH₃)₂C=CH-CH₃</text>
  <text x="575" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Major Zaitsev Alkene</text>
  <text x="575" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Most substituted alkene</text>
  <text x="575" y="142" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Thermodynamic control</text>
</svg>
""";

  // 4. E2 ELIMINATION SVG
  static const String e2Svg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  <defs>
    <marker id="arrow4" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#F59E0B" />
    </marker>
    <marker id="cyan-arrow4" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">E2 Bimolecular Elimination: Anti-Periplanar Concerted Transition State</text>
  <text x="40" y="65" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">Base: B⁻</text>
  <path d="M 95 65 Q 125 65 140 85" fill="none" stroke="#F59E0B" stroke-width="2" marker-end="url(#arrow4)"/>
  <text x="140" y="95" fill="#FFFFFF" font-family="sans-serif" font-size="14">H</text>
  <line x1="145" y1="102" x2="160" y2="120" stroke="#38BDF8" stroke-width="2.2"/>
  <text x="165" y="130" fill="#38BDF8" font-family="sans-serif" font-size="15" font-weight="bold">C(α)</text>
  <line x1="195" y1="125" x2="230" y2="125" stroke="#38BDF8" stroke-width="2.5"/>
  <text x="235" y="130" fill="#38BDF8" font-family="sans-serif" font-size="15" font-weight="bold">C(β)</text>
  <line x1="250" y1="130" x2="270" y2="155" stroke="#EF4444" stroke-width="2.2"/>
  <text x="272" y="170" fill="#EF4444" font-family="sans-serif" font-size="14" font-weight="bold">Br</text>
  <path d="M 152 110 Q 185 105 195 120" fill="none" stroke="#F59E0B" stroke-width="2" marker-end="url(#arrow4)"/>
  <path d="M 255 140 Q 275 140 280 155" fill="none" stroke="#F59E0B" stroke-width="2" marker-end="url(#arrow4)"/>
  <text x="145" y="190" fill="#F59E0B" font-family="sans-serif" font-size="11">θ = 180° (Anti-periplanar)</text>
  <line x1="320" y1="125" x2="370" y2="125" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow4)"/>
  <rect x="385" y="48" width="165" height="115" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-dasharray="3,3"/>
  <text x="395" y="70" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">[B···H···C=C···Br]‡</text>
  <text x="395" y="95" fill="#E2E8F0" font-family="sans-serif" font-size="11">Concerted 1-Step</text>
  <text x="395" y="115" fill="#E2E8F0" font-family="sans-serif" font-size="11">Stereospecific</text>
  <text x="395" y="135" fill="#E2E8F0" font-family="sans-serif" font-size="11">Rate = k[Base][Sub]</text>
  <line x1="565" y1="125" x2="610" y2="125" stroke="#38BDF8" stroke-width="2" marker-end="url(#cyan-arrow4)"/>
  <rect x="625" y="55" width="120" height="100" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="635" y="85" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">R-CH=CH-R</text>
  <text x="635" y="110" fill="#E2E8F0" font-family="sans-serif" font-size="11">Alkene + BH + Br⁻</text>
  <text x="635" y="130" fill="#94A3B8" font-family="sans-serif" font-size="10.5">trans/cis ratio</text>
</svg>
""";

  // 5. CANNIZZARO REACTION SVG
  static const String cannizzaroSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  <defs>
    <marker id="arr5" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#F59E0B" />
    </marker>
    <marker id="carr5" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Cannizzaro Reaction: Base-Catalyzed Disproportionation via Hydride Transfer</text>
  <text x="35" y="70" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">:OH⁻</text>
  <path d="M 65 70 Q 95 70 105 90" fill="none" stroke="#F59E0B" stroke-width="2" marker-end="url(#arr5)"/>
  <text x="100" y="110" fill="#FFFFFF" font-family="sans-serif" font-size="14" font-weight="bold">Ar-CHO</text>
  <line x1="165" y1="105" x2="215" y2="105" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr5)"/>
  <rect x="230" y="48" width="145" height="115" rx="10" fill="#1E1A38" stroke="#8B5CF6"/>
  <text x="240" y="75" fill="#38BDF8" font-family="sans-serif" font-size="12" font-weight="bold">[Ar-CH(OH)O⁻]</text>
  <text x="240" y="100" fill="#F59E0B" font-family="sans-serif" font-size="11">Hydride Transfer</text>
  <text x="240" y="120" fill="#E2E8F0" font-family="sans-serif" font-size="11">(:H⁻ shifts to Ar-CHO)</text>
  <text x="240" y="140" fill="#EF4444" font-family="sans-serif" font-size="10.5">Rate Determining Step</text>
  <line x1="390" y1="105" x2="445" y2="105" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr5)"/>
  <rect x="460" y="48" width="130" height="115" rx="10" fill="#1E1A38" stroke="#8B5CF6"/>
  <text x="470" y="75" fill="#38BDF8" font-family="sans-serif" font-size="12">Ar-COOH</text>
  <text x="470" y="95" fill="#38BDF8" font-family="sans-serif" font-size="12">+ Ar-CH₂O⁻</text>
  <text x="470" y="125" fill="#10B981" font-family="sans-serif" font-size="11">Rapid H⁺ Transfer</text>
  <line x1="605" y1="105" x2="640" y2="105" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr5)"/>
  <rect x="655" y="48" width="95" height="115" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="662" y="75" fill="#10B981" font-family="sans-serif" font-size="11.5" font-weight="bold">Ar-COO⁻</text>
  <text x="662" y="95" fill="#94A3B8" font-family="sans-serif" font-size="10">(Acid salt)</text>
  <text x="662" y="125" fill="#10B981" font-family="sans-serif" font-size="11.5" font-weight="bold">Ar-CH₂OH</text>
  <text x="662" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10">(1° Alcohol)</text>
</svg>
""";

  // 6. ALDOL CONDENSATION SVG
  static const String aldolSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  <defs>
    <marker id="carr6" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Aldol Condensation: Enolate Addition followed by E1cB Dehydration</text>
  <text x="30" y="80" fill="#FFFFFF" font-family="sans-serif" font-size="13">R-CH₂-CHO</text>
  <text x="30" y="115" fill="#10B981" font-family="sans-serif" font-size="12">+ :B⁻ (-HB⁺)</text>
  <line x1="125" y1="100" x2="165" y2="100" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr6)"/>
  <rect x="180" y="55" width="125" height="90" rx="8" fill="#1E1A38" stroke="#8B5CF6"/>
  <text x="190" y="80" fill="#38BDF8" font-family="sans-serif" font-size="12" font-weight="bold">[R-CH=CH-O⁻]</text>
  <text x="190" y="105" fill="#F59E0B" font-family="sans-serif" font-size="11">Enolate Nucleophile</text>
  <line x1="315" y1="100" x2="355" y2="100" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr6)"/>
  <text x="320" y="90" fill="#FFFFFF" font-family="sans-serif" font-size="10">+ RCHO</text>
  <rect x="370" y="55" width="155" height="90" rx="8" fill="#1E1A38" stroke="#8B5CF6"/>
  <text x="380" y="80" fill="#38BDF8" font-family="sans-serif" font-size="12">R-CH(OH)-CH(R)CHO</text>
  <text x="380" y="105" fill="#10B981" font-family="sans-serif" font-size="11">β-Hydroxy Carbonyl (Aldol)</text>
  <line x1="535" y1="100" x2="575" y2="100" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr6)"/>
  <text x="540" y="90" fill="#F59E0B" font-family="sans-serif" font-size="10">Δ, -H₂O</text>
  <rect x="590" y="50" width="155" height="100" rx="8" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="600" y="80" fill="#10B981" font-family="sans-serif" font-size="13" font-weight="bold">R-CH=C(R)-CHO</text>
  <text x="600" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">α,β-Unsaturated Aldehyde</text>
  <text x="600" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Conjugated Enal/Enone</text>
</svg>
""";

  // 7. WITTIG REACTION SVG
  static const String wittigSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  <defs>
    <marker id="carr7" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Wittig Reaction: Phosphonium Ylide Addition via Oxaphosphetane Intermediate</text>
  <text x="30" y="80" fill="#38BDF8" font-family="sans-serif" font-size="14" font-weight="bold">Ph₃P=CH-R</text>
  <text x="30" y="105" fill="#FFFFFF" font-family="sans-serif" font-size="13">+ R'₂C=O</text>
  <line x1="145" y1="95" x2="200" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr7)"/>
  <text x="150" y="85" fill="#F59E0B" font-family="sans-serif" font-size="11">[2+2] cyclo</text>
  <rect x="220" y="48" width="170" height="115" rx="10" fill="#1E1A38" stroke="#F59E0B" stroke-width="1.5"/>
  <text x="230" y="75" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Oxaphosphetane (4-Ring)</text>
  <text x="260" y="105" fill="#FFFFFF" font-family="sans-serif" font-size="13">Ph₃P ── O</text>
  <text x="270" y="125" fill="#FFFFFF" font-family="sans-serif" font-size="13">│    │</text>
  <text x="260" y="145" fill="#FFFFFF" font-family="sans-serif" font-size="13">RCH ── CR'₂</text>
  <line x1="410" y1="95" x2="475" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr7)"/>
  <text x="415" y="85" fill="#EF4444" font-family="sans-serif" font-size="11">Retro-[2+2] (RDS)</text>
  <rect x="500" y="48" width="230" height="115" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="515" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">R'₂C=CH-R (Alkene)</text>
  <text x="515" y="105" fill="#38BDF8" font-family="sans-serif" font-size="13">+ Ph₃P=O (Triphenylphosphine oxide)</text>
  <text x="515" y="130" fill="#E2E8F0" font-family="sans-serif" font-size="11">Driving force: Extremely strong P=O bond</text>
  <text x="515" y="148" fill="#94A3B8" font-family="sans-serif" font-size="10.5">(Bond energy ≈ 540 kJ/mol)</text>
</svg>
""";

  // 8. DIELS-ALDER CYCLOADDITION SVG
  static const String dielsAlderSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  <defs>
    <marker id="carr8" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Diels-Alder [4+2] Cycloaddition: Concerted Suprafacial Cyclization & Endo Selectivity</text>
  <text x="40" y="85" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">s-cis Diene (4π)</text>
  <text x="40" y="125" fill="#FFFFFF" font-family="sans-serif" font-size="13">+ Dienophile (2π)</text>
  <line x1="180" y1="105" x2="235" y2="105" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr8)"/>
  <text x="190" y="95" fill="#F59E0B" font-family="sans-serif" font-size="11">Δ (Thermal)</text>
  <rect x="255" y="48" width="210" height="115" rx="10" fill="#1E1A38" stroke="#F59E0B"/>
  <text x="265" y="75" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Aromatic 6-Electron TS [‡]</text>
  <text x="265" y="100" fill="#E2E8F0" font-family="sans-serif" font-size="11">Concerted [4s + 2s] overlap</text>
  <text x="265" y="120" fill="#10B981" font-family="sans-serif" font-size="11">Secondary orbital interactions</text>
  <text x="265" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Favors Kinetic Endo isomer</text>
  <line x1="485" y1="105" x2="535" y2="105" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr8)"/>
  <rect x="555" y="48" width="180" height="115" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="570" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">Cyclohexene Derivative</text>
  <text x="570" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">New ring formed with</text>
  <text x="570" y="125" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">2 new σ-bonds & 1 π-bond</text>
  <text x="570" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Endo-adduct major</text>
</svg>
""";

  // 9. GRIGNARD REACTION SVG
  static const String grignardSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  <defs>
    <marker id="carr9" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Grignard Reaction: Organomagnesium Nucleophilic Addition & Acid Hydrolysis</text>
  <text x="40" y="85" fill="#38BDF8" font-family="sans-serif" font-size="14" font-weight="bold">R-MgX</text>
  <text x="40" y="115" fill="#FFFFFF" font-family="sans-serif" font-size="13">+ R'₂C=O</text>
  <line x1="140" y1="100" x2="195" y2="100" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr9)"/>
  <text x="145" y="90" fill="#F59E0B" font-family="sans-serif" font-size="10.5">Ether/THF</text>
  <rect x="215" y="48" width="180" height="115" rx="10" fill="#1E1A38" stroke="#8B5CF6"/>
  <text x="225" y="75" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Halomagnesium Alkoxide</text>
  <text x="225" y="105" fill="#FFFFFF" font-family="sans-serif" font-size="13">R'₂C(R) ── O⁻MgX⁺</text>
  <text x="225" y="130" fill="#94A3B8" font-family="sans-serif" font-size="11">New C-C σ-bond formed</text>
  <line x1="415" y1="100" x2="480" y2="100" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr9)"/>
  <text x="425" y="90" fill="#10B981" font-family="sans-serif" font-size="11">H₃O⁺ (Workup)</text>
  <rect x="500" y="48" width="230" height="115" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="515" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">R'₂C(R)-OH (Alcohol)</text>
  <text x="515" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Formaldehyde → 1° alcohol</text>
  <text x="515" y="125" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Aldehydes → 2° alcohol</text>
  <text x="515" y="145" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">Ketones/Esters → 3° alcohol</text>
</svg>
""";

  // 10. BECKMANN REARRANGEMENT SVG
  static const String beckmannSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  <defs>
    <marker id="carr10" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Beckmann Rearrangement: Acid-Catalyzed Anti-Migration of Ketoxime to Amide</text>
  <text x="40" y="80" fill="#38BDF8" font-family="sans-serif" font-size="13" font-weight="bold">Ketoxime: R(R')C=N-OH</text>
  <text x="40" y="105" fill="#FFFFFF" font-family="sans-serif" font-size="12">+ H⁺ (PCl₅ / H₂SO₄)</text>
  <line x1="210" y1="95" x2="260" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr10)"/>
  <rect x="280" y="48" width="180" height="115" rx="10" fill="#1E1A38" stroke="#F59E0B"/>
  <text x="290" y="75" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Anti-Periplanar Migration</text>
  <text x="290" y="100" fill="#E2E8F0" font-family="sans-serif" font-size="11">R group anti to -OH departs</text>
  <text x="290" y="120" fill="#38BDF8" font-family="sans-serif" font-size="11">Nitrilium Ion: [R-C≡N-R']⁺</text>
  <text x="290" y="140" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Stereospecific retention</text>
  <line x1="480" y1="95" x2="530" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr10)"/>
  <text x="485" y="85" fill="#10B981" font-family="sans-serif" font-size="11">H₂O, taut.</text>
  <rect x="550" y="48" width="180" height="115" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="565" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">R-CO-NH-R'</text>
  <text x="565" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">N-Substituted Amide</text>
  <text x="565" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Cyclohexanone oxime →</text>
  <text x="565" y="142" fill="#94A3B8" font-family="sans-serif" font-size="10.5">ε-Caprolactam (Nylon-6)</text>
</svg>
""";

  // 11. BENZOIN CONDENSATION SVG
  static const String benzoinSvg = """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 210" width="100%" height="100%">
  <defs>
    <marker id="carr11" viewBox="0 0 10 10" refX="6" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
      <path d="M 0 1 L 10 5 L 0 9 z" fill="#38BDF8" />
    </marker>
  </defs>
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="32" fill="#A78BFA" font-family="sans-serif" font-size="12.5" font-weight="bold">Benzoin Condensation: Cyanide-Catalyzed Umpolung of Aromatic Aldehyde</text>
  <text x="40" y="80" fill="#FFFFFF" font-family="sans-serif" font-size="13">Ph-CHO + :CN⁻</text>
  <line x1="165" y1="95" x2="215" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr11)"/>
  <rect x="235" y="48" width="165" height="115" rx="10" fill="#1E1A38" stroke="#F59E0B"/>
  <text x="245" y="75" fill="#F59E0B" font-family="sans-serif" font-size="12" font-weight="bold">Umpolung Intermediate</text>
  <text x="245" y="100" fill="#38BDF8" font-family="sans-serif" font-size="12">Ph-C⁻(OH)(CN)</text>
  <text x="245" y="125" fill="#E2E8F0" font-family="sans-serif" font-size="11">Reversed Polarity (d¹)</text>
  <text x="245" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Attacks 2nd Ph-CHO</text>
  <line x1="420" y1="95" x2="475" y2="95" stroke="#38BDF8" stroke-width="2" marker-end="url(#carr11)"/>
  <text x="430" y="85" fill="#10B981" font-family="sans-serif" font-size="11">- CN⁻</text>
  <rect x="495" y="48" width="230" height="115" rx="10" fill="#064E3B" fill-opacity="0.3" stroke="#10B981" stroke-width="1.2"/>
  <text x="510" y="78" fill="#10B981" font-family="sans-serif" font-size="14" font-weight="bold">Ph-CH(OH)-CO-Ph (Benzoin)</text>
  <text x="510" y="105" fill="#E2E8F0" font-family="sans-serif" font-size="11.5">α-Hydroxy Ketone</text>
  <text x="510" y="125" fill="#94A3B8" font-family="sans-serif" font-size="10.5">Reagent: NaCN / KCN in aq. EtOH</text>
  <text x="510" y="145" fill="#94A3B8" font-family="sans-serif" font-size="10.5">CN⁻ is unique nucleophile & leaving group</text>
</svg>
""";

  static String defaultGenericSvg(String title) => """
<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 760 160" width="100%" height="100%">
  <rect width="100%" height="100%" fill="#141224" rx="14" stroke="#2D284E" stroke-width="1.5"/>
  <text x="30" y="40" fill="#A78BFA" font-family="sans-serif" font-size="14" font-weight="bold">$title Mechanism Diagram</text>
  <text x="30" y="85" fill="#38BDF8" font-family="sans-serif" font-size="13">Reactants ──[ Reagent / Conditions ]──→ Reaction Intermediate ──→ Final Products</text>
  <text x="30" y="120" fill="#94A3B8" font-family="sans-serif" font-size="11.5">Stepwise curved arrow electron movement verified according to MSc syllabus.</text>
</svg>
""";
}
