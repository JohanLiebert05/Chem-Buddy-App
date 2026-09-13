import 'dart:math' as math;
import 'chemical_graph.dart';
import 'electron_arrow_model.dart';

/// Configuration options for rendering chemical SVG mechanisms.
class MechanismSvgConfig {
  final double width;
  final double height;
  final String backgroundColor;
  final String defaultBondColor;
  final String reactingBondColor;
  final String arrowColor;
  final bool showFormalCharges;
  final bool showAtomRoles;
  final bool showStepCaptions;

  const MechanismSvgConfig({
    this.width = 600,
    this.height = 360,
    this.backgroundColor = '#0B1120',
    this.defaultBondColor = '#94A3B8',
    this.reactingBondColor = '#38BDF8',
    this.arrowColor = '#EC4899',
    this.showFormalCharges = true,
    this.showAtomRoles = true,
    this.showStepCaptions = true,
  });
}

/// High-contrast, scalable vector SVG renderer for chemical graphs and reaction mechanisms.
class MechanismSvgRenderer {
  const MechanismSvgRenderer();

  /// Renders a single mechanism step with reactant/intermediate structures, electron pushing arrows,
  /// and pedagogical captions.
  static String renderStep({
    required ChemicalGraph graph,
    required List<ElectronArrowModel> electronFlows,
    String stepTitle = '',
    String stepDescription = '',
    String? transitionStateNote,
    MechanismSvgConfig config = const MechanismSvgConfig(),
  }) {
    final buffer = StringBuffer();
    final bounds = graph.getBounds();

    // Auto-compute viewBox with safe margins
    final minX = math.min(bounds.minX - 50, 0.0);
    final minY = math.min(bounds.minY - 50, 0.0);
    final maxX = math.max(bounds.maxX + 50, config.width);
    final maxY = math.max(bounds.maxY + 70, config.height);
    final viewWidth = maxX - minX;
    final viewHeight = maxY - minY;

    buffer.writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="$minX $minY $viewWidth $viewHeight" width="100%" height="100%">');

    // Defs: Arrowhead markers & filter effects
    buffer.writeln('  <defs>');
    _appendArrowDefs(buffer, config);
    buffer.writeln('  </defs>');

    // Background
    buffer.writeln(
        '  <rect x="$minX" y="$minY" width="$viewWidth" height="$viewHeight" rx="16" fill="${config.backgroundColor}" stroke="#1E293B" stroke-width="1.5"/>');

    // Render Bonds
    buffer.writeln('  <g id="bonds">');
    for (final bond in graph.bonds) {
      _appendBondSvg(buffer, bond, graph, config);
    }
    buffer.writeln('  </g>');

    // Render Atoms & Formal Charges
    buffer.writeln('  <g id="atoms">');
    for (final atom in graph.atoms) {
      _appendAtomSvg(buffer, atom, config);
    }
    buffer.writeln('  </g>');

    // Render Curved Electron Arrows
    buffer.writeln('  <g id="electron-arrows">');
    for (final arrow in electronFlows) {
      _appendCurvedArrowSvg(buffer, arrow, graph, config);
    }
    buffer.writeln('  </g>');

    // Step Title & Pedagogical Caption Header
    if (config.showStepCaptions && (stepTitle.isNotEmpty || stepDescription.isNotEmpty)) {
      final textY = minY + 30;
      buffer.writeln('  <g id="caption" font-family="system-ui, -apple-system, sans-serif">');
      if (stepTitle.isNotEmpty) {
        final safeTitle = _escapeXml(stepTitle);
        buffer.writeln(
            '    <text x="${minX + 24}" y="$textY" fill="#38BDF8" font-size="14" font-weight="700" letter-spacing="0.5">$safeTitle</text>');
      }
      if (transitionStateNote != null && transitionStateNote.isNotEmpty) {
        final safeNote = _escapeXml(transitionStateNote);
        buffer.writeln(
            '    <rect x="${maxX - 160}" y="${minY + 12}" width="140" height="24" rx="6" fill="#8B5CF6" fill-opacity="0.2" stroke="#A78BFA" stroke-width="1"/>');
        buffer.writeln(
            '    <text x="${maxX - 90}" y="${minY + 28}" fill="#C4B5FD" font-size="11" font-weight="600" text-anchor="middle">$safeNote</text>');
      }
      buffer.writeln('  </g>');
    }

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  /// Renders a complete reaction scheme: Reactants + Reagents/Solvent -> Major Product
  static String renderReactionScheme({
    required ChemicalGraph reactantGraph,
    required ChemicalGraph productGraph,
    String reagent = '',
    String solvent = '',
    String temperature = '',
    String reactionName = '',
    MechanismSvgConfig config = const MechanismSvgConfig(width: 720, height: 260),
  }) {
    final buffer = StringBuffer();
    const totalWidth = 720.0;
    const totalHeight = 260.0;
    final rBounds = reactantGraph.getBounds();
    final pBounds = productGraph.getBounds();

    // Scale and position Reactants on left (0 to 280), Product on right (440 to 720)
    final rGraphScaled = reactantGraph
        .translate(-rBounds.minX, -rBounds.minY)
        .translate(40.0, 60.0);

    final pGraphScaled = productGraph
        .translate(-pBounds.minX, -pBounds.minY)
        .translate(460.0, 60.0);

    buffer.writeln(
        '<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 $totalWidth $totalHeight" width="100%" height="100%">');

    // Defs: Reaction Arrow
    buffer.writeln('  <defs>');
    buffer.writeln('    <marker id="rxn-arrowhead" markerWidth="10" markerHeight="10" refX="7" refY="3.5" orient="auto">');
    buffer.writeln('      <polygon points="0 0, 10 3.5, 0 7" fill="#38BDF8"/>');
    buffer.writeln('    </marker>');
    buffer.writeln('  </defs>');

    // Background
    buffer.writeln(
        '  <rect width="$totalWidth" height="$totalHeight" rx="16" fill="${config.backgroundColor}" stroke="#1E293B" stroke-width="1.5"/>');

    // Title
    if (reactionName.isNotEmpty) {
      final safeName = _escapeXml(reactionName);
      buffer.writeln(
          '  <text x="360" y="32" fill="#E2E8F0" font-size="15" font-weight="700" text-anchor="middle" font-family="system-ui, sans-serif">$safeName</text>');
    }

    // Reactants
    buffer.writeln('  <g id="reactants">');
    for (final bond in rGraphScaled.bonds) {
      _appendBondSvg(buffer, bond, rGraphScaled, config);
    }
    for (final atom in rGraphScaled.atoms) {
      _appendAtomSvg(buffer, atom, config);
    }
    buffer.writeln('  </g>');

    // Forward Reaction Arrow (center: X=310 to X=410, Y=140)
    const arrowY = 140.0;
    buffer.writeln('  <g id="reaction-arrow" font-family="system-ui, sans-serif">');
    buffer.writeln(
        '    <line x1="300" y1="$arrowY" x2="420" y2="$arrowY" stroke="#38BDF8" stroke-width="3" marker-end="url(#rxn-arrowhead)"/>');

    // Reagent above arrow
    if (reagent.isNotEmpty) {
      final safeReagent = _escapeXml(reagent);
      buffer.writeln(
          '    <text x="360" y="${arrowY - 14}" fill="#F472B6" font-size="13" font-weight="700" text-anchor="middle">$safeReagent</text>');
    }

    // Solvent / Temp below arrow
    final conditionsList = <String>[];
    if (solvent.isNotEmpty) conditionsList.add(solvent);
    if (temperature.isNotEmpty) conditionsList.add(temperature);
    if (conditionsList.isNotEmpty) {
      final condText = _escapeXml(conditionsList.join(', '));
      buffer.writeln(
          '    <text x="360" y="${arrowY + 22}" fill="#94A3B8" font-size="11" font-weight="500" text-anchor="middle">$condText</text>');
    }
    buffer.writeln('  </g>');

    // Product
    buffer.writeln('  <g id="products">');
    for (final bond in pGraphScaled.bonds) {
      _appendBondSvg(buffer, bond, pGraphScaled, config);
    }
    for (final atom in pGraphScaled.atoms) {
      _appendAtomSvg(buffer, atom, config);
    }
    buffer.writeln('  </g>');

    buffer.writeln('</svg>');
    return buffer.toString();
  }

  // ---------------------------------------------------------------------------
  // SVG HELPER METHODS
  // ---------------------------------------------------------------------------

  static void _appendArrowDefs(StringBuffer buffer, MechanismSvgConfig config) {
    // 2-electron double-barbed curved arrowhead marker
    buffer.writeln('    <marker id="arrow-full-2e" markerWidth="12" markerHeight="12" refX="9" refY="4" orient="auto">');
    buffer.writeln('      <path d="M 0 0 L 10 4 L 0 8 L 3 4 Z" fill="${config.arrowColor}"/>');
    buffer.writeln('    </marker>');

    // 1-electron single-barbed fishhook marker
    buffer.writeln('    <marker id="arrow-fishhook-1e" markerWidth="12" markerHeight="12" refX="9" refY="4" orient="auto">');
    buffer.writeln('      <path d="M 0 0 L 10 4 L 4 4 Z" fill="${config.arrowColor}"/>');
    buffer.writeln('    </marker>');

    // Active site glow filter
    buffer.writeln('    <filter id="glow-reacting" x="-30%" y="-30%" width="160%" height="160%">');
    buffer.writeln('      <feGaussianBlur stdDeviation="3" result="blur"/>');
    buffer.writeln('      <feMerge>');
    buffer.writeln('        <feMergeNode in="blur"/>');
    buffer.writeln('        <feMergeNode in="SourceGraphic"/>');
    buffer.writeln('      </feMerge>');
    buffer.writeln('    </filter>');
  }

  static void _appendBondSvg(
    StringBuffer buffer,
    ChemicalBond bond,
    ChemicalGraph graph,
    MechanismSvgConfig config,
  ) {
    final a1 = graph.getAtom(bond.atom1Id);
    final a2 = graph.getAtom(bond.atom2Id);
    if (a1 == null || a2 == null) return;

    final bondColor = bond.isReacting ? config.reactingBondColor : config.defaultBondColor;
    final strokeWidth = bond.isReacting ? 3.5 : 2.5;

    switch (bond.type) {
      case BondType.single:
        buffer.writeln(
            '    <line x1="${a1.x}" y1="${a1.y}" x2="${a2.x}" y2="${a2.y}" stroke="$bondColor" stroke-width="$strokeWidth" stroke-linecap="round"/>');
        break;

      case BondType.double:
        // Compute parallel offset lines
        final dx = a2.x - a1.x;
        final dy = a2.y - a1.y;
        final len = math.sqrt(dx * dx + dy * dy);
        if (len == 0) break;
        final perpX = -dy / len * 3.0;
        final perpY = dx / len * 3.0;

        buffer.writeln(
            '    <line x1="${a1.x + perpX}" y1="${a1.y + perpY}" x2="${a2.x + perpX}" y2="${a2.y + perpY}" stroke="$bondColor" stroke-width="$strokeWidth" stroke-linecap="round"/>');
        buffer.writeln(
            '    <line x1="${a1.x - perpX}" y1="${a1.y - perpY}" x2="${a2.x - perpX}" y2="${a2.y - perpY}" stroke="$bondColor" stroke-width="$strokeWidth" stroke-linecap="round"/>');
        break;

      case BondType.triple:
        final dx = a2.x - a1.x;
        final dy = a2.y - a1.y;
        final len = math.sqrt(dx * dx + dy * dy);
        if (len == 0) break;
        final perpX = -dy / len * 4.5;
        final perpY = dx / len * 4.5;

        buffer.writeln(
            '    <line x1="${a1.x}" y1="${a1.y}" x2="${a2.x}" y2="${a2.y}" stroke="$bondColor" stroke-width="$strokeWidth" stroke-linecap="round"/>');
        buffer.writeln(
            '    <line x1="${a1.x + perpX}" y1="${a1.y + perpY}" x2="${a2.x + perpX}" y2="${a2.y + perpY}" stroke="$bondColor" stroke-width="2.0" stroke-linecap="round"/>');
        buffer.writeln(
            '    <line x1="${a1.x - perpX}" y1="${a1.y - perpY}" x2="${a2.x - perpX}" y2="${a2.y - perpY}" stroke="$bondColor" stroke-width="2.0" stroke-linecap="round"/>');
        break;

      case BondType.aromatic:
        // Solid line + inner dashed circle / line
        final dx = a2.x - a1.x;
        final dy = a2.y - a1.y;
        final len = math.sqrt(dx * dx + dy * dy);
        if (len == 0) break;
        final perpX = -dy / len * 3.5;
        final perpY = dx / len * 3.5;

        buffer.writeln(
            '    <line x1="${a1.x}" y1="${a1.y}" x2="${a2.x}" y2="${a2.y}" stroke="$bondColor" stroke-width="$strokeWidth" stroke-linecap="round"/>');
        buffer.writeln(
            '    <line x1="${a1.x + perpX}" y1="${a1.y + perpY}" x2="${a2.x + perpX}" y2="${a2.y + perpY}" stroke="$bondColor" stroke-width="1.8" stroke-dasharray="3 3"/>');
        break;

      case BondType.wedge:
        // Tapered stereochemical wedge
        final dx = a2.x - a1.x;
        final dy = a2.y - a1.y;
        final len = math.sqrt(dx * dx + dy * dy);
        if (len == 0) break;
        final perpX = -dy / len * 5.0;
        final perpY = dx / len * 5.0;

        buffer.writeln(
            '    <polygon points="${a1.x} ${a1.y}, ${a2.x + perpX} ${a2.y + perpY}, ${a2.x - perpX} ${a2.y - perpY}" fill="$bondColor"/>');
        break;

      case BondType.dash:
        buffer.writeln(
            '    <line x1="${a1.x}" y1="${a1.y}" x2="${a2.x}" y2="${a2.y}" stroke="$bondColor" stroke-width="3.5" stroke-dasharray="3 3"/>');
        break;
    }
  }

  static void _appendAtomSvg(StringBuffer buffer, ChemicalAtom atom, MechanismSvgConfig config) {
    // Only render label if non-carbon or if carbon has charge/role
    final isExplicit = atom.element != 'C' || atom.formalCharge != 0 || atom.role != null;
    final color = _getAtomColor(atom.element);

    if (atom.role != null && config.showAtomRoles) {
      // Draw reacting glow halo
      final glowColor = atom.role == 'nucleophile' ? '#10B981' : '#F59E0B';
      buffer.writeln(
          '    <circle cx="${atom.x}" cy="${atom.y}" r="15" fill="$glowColor" fill-opacity="0.2" stroke="$glowColor" stroke-width="1.2" stroke-dasharray="3 2" filter="url(#glow-reacting)"/>');
    }

    if (isExplicit) {
      // Clear circle behind text for readability
      buffer.writeln(
          '    <circle cx="${atom.x}" cy="${atom.y}" r="12" fill="${config.backgroundColor}"/>');
      buffer.writeln(
          '    <text x="${atom.x}" y="${atom.y + 5}" fill="$color" font-size="15" font-weight="700" text-anchor="middle" font-family="system-ui, monospace">${atom.element}</text>');
    }

    // Formal charge badge
    if (config.showFormalCharges && atom.formalCharge != 0) {
      final isPos = atom.formalCharge > 0;
      final badgeColor = isPos ? '#3B82F6' : '#EF4444';
      final badgeText = isPos ? (atom.formalCharge == 1 ? '+' : '+${atom.formalCharge}') : (atom.formalCharge == -1 ? '−' : '−${atom.formalCharge.abs()}');
      final badgeX = atom.x + 10;
      final badgeY = atom.y - 10;

      buffer.writeln(
          '    <circle cx="$badgeX" cy="$badgeY" r="7.5" fill="$badgeColor"/>');
      buffer.writeln(
          '    <text x="$badgeX" y="${badgeY + 3.5}" fill="#FFFFFF" font-size="10" font-weight="800" text-anchor="middle" font-family="system-ui, sans-serif">$badgeText</text>');
    }
  }

  static void _appendCurvedArrowSvg(
    StringBuffer buffer,
    ElectronArrowModel arrow,
    ChemicalGraph graph,
    MechanismSvgConfig config,
  ) {
    final coords = arrow.resolveCoordinates(graph);
    final markerId = arrow.arrowType == ArrowHeadType.curvedHalf
        ? 'arrow-fishhook-1e'
        : 'arrow-full-2e';

    // Quadratic Bezier curve
    buffer.writeln(
        '    <path d="M ${coords.start.dx} ${coords.start.dy} Q ${coords.control.dx} ${coords.control.dy} ${coords.end.dx} ${coords.end.dy}" stroke="${arrow.strokeColor}" stroke-width="2.5" fill="none" stroke-linecap="round" marker-end="url(#$markerId)"/>');
  }

  static String _getAtomColor(String element) {
    switch (element.toUpperCase()) {
      case 'C':
        return '#E2E8F0';
      case 'H':
        return '#94A3B8';
      case 'O':
        return '#EF4444';
      case 'N':
        return '#38BDF8';
      case 'CL':
      case 'F':
        return '#10B981';
      case 'BR':
        return '#F59E0B';
      case 'I':
        return '#8B5CF6';
      case 'S':
        return '#FBBF24';
      case 'P':
        return '#EC4899';
      case 'MG':
      case 'LI':
      case 'NA':
      case 'K':
        return '#C084FC';
      default:
        return '#CBD5E1';
    }
  }

  static String _escapeXml(String input) {
    return input
        .replaceAll('&', '&amp;')
        .replaceAll('<', '&lt;')
        .replaceAll('>', '&gt;')
        .replaceAll('"', '&quot;')
        .replaceAll("'", '&apos;');
  }
}
