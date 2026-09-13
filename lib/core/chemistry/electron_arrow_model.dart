import 'dart:math' as math;
import 'dart:ui';
import 'chemical_graph.dart';

/// Type of arrowhead for curved electron pushing arrows.
enum ArrowHeadType {
  curvedFull, // Standard 2-electron pair transfer (double-barbed)
  curvedHalf, // Single electron transfer / radical fishhook (single-barbed)
}

/// Source of the moving electron(s).
enum ElectronSourceType {
  lonePair,
  bond,
  piBond,
  negativeCharge,
  atom,
}

/// Destination target of the moving electron(s).
enum ElectronTargetType {
  atom,
  bond,
  positiveCharge,
  space,
}

/// Classification of the mechanistic electron transformation.
enum ElectronFlowType {
  lonePairAttack,
  bondBreak,
  piAttack,
  protonTransfer,
  elimination,
  bondFormation,
  resonance,
}

/// Represents a curved electron-pushing arrow in a reaction mechanism.
class ElectronArrowModel {
  final String id;
  final ElectronSourceType sourceType;
  final String sourceIdentifier; // e.g., 'Nu:lone_pair', 'B_CLG', 'C_alpha'
  final ElectronTargetType targetType;
  final String targetIdentifier; // e.g., 'C_carbonyl', 'B_forming', 'LG'
  final ElectronFlowType flowType;
  final ArrowHeadType arrowType;
  final String description;
  final double curvature; // -1.0 to 1.0 (positive curves upward/outward, negative curves downward/inward)
  final Offset? explicitSource;
  final Offset? explicitTarget;
  final Offset? explicitControl;
  final String strokeColor;

  const ElectronArrowModel({
    required this.id,
    required this.sourceType,
    required this.sourceIdentifier,
    required this.targetType,
    required this.targetIdentifier,
    required this.flowType,
    this.arrowType = ArrowHeadType.curvedFull,
    this.description = '',
    this.curvature = 0.35,
    this.explicitSource,
    this.explicitTarget,
    this.explicitControl,
    this.strokeColor = '#EC4899', // Vibrant electric pink/magenta for MSc mechanisms
  });

  /// Computes start, end, and quadratic Bezier control points from graph geometry.
  ({Offset start, Offset control, Offset end}) resolveCoordinates(ChemicalGraph graph) {
    Offset start = explicitSource ?? _resolveSourcePoint(graph);
    Offset end = explicitTarget ?? _resolveTargetPoint(graph);

    Offset control;
    if (explicitControl != null) {
      control = explicitControl!;
    } else {
      // Calculate perpendicular control point based on curvature
      final dx = end.dx - start.dx;
      final dy = end.dy - start.dy;
      final dist = math.sqrt(dx * dx + dy * dy);
      final midX = (start.dx + end.dx) / 2.0;
      final midY = (start.dy + end.dy) / 2.0;

      // Unit perpendicular vector (-dy, dx)
      final perpX = dist > 0 ? -dy / dist : 0.0;
      final perpY = dist > 0 ? dx / dist : -1.0;

      final curveOffset = (dist * curvature).clamp(-120.0, 120.0);
      control = Offset(midX + perpX * curveOffset, midY + perpY * curveOffset);
    }

    return (start: start, control: control, end: end);
  }

  Offset _resolveSourcePoint(ChemicalGraph graph) {
    // 1. Try resolving as atom
    final atom = graph.getAtom(sourceIdentifier);
    if (atom != null) {
      // Offset slightly for lone pairs
      if (sourceType == ElectronSourceType.lonePair ||
          sourceType == ElectronSourceType.negativeCharge) {
        return Offset(atom.x + 8.0, atom.y - 12.0);
      }
      return Offset(atom.x, atom.y);
    }

    // 2. Try resolving as bond
    final bond = graph.getBond(sourceIdentifier);
    if (bond != null) {
      final a1 = graph.getAtom(bond.atom1Id);
      final a2 = graph.getAtom(bond.atom2Id);
      if (a1 != null && a2 != null) {
        return Offset((a1.x + a2.x) / 2.0, (a1.y + a2.y) / 2.0);
      }
    }

    return const Offset(50.0, 50.0);
  }

  Offset _resolveTargetPoint(ChemicalGraph graph) {
    // 1. Try resolving as atom
    final atom = graph.getAtom(targetIdentifier);
    if (atom != null) {
      return Offset(atom.x, atom.y);
    }

    // 2. Try resolving as bond
    final bond = graph.getBond(targetIdentifier);
    if (bond != null) {
      final a1 = graph.getAtom(bond.atom1Id);
      final a2 = graph.getAtom(bond.atom2Id);
      if (a1 != null && a2 != null) {
        return Offset((a1.x + a2.x) / 2.0, (a1.y + a2.y) / 2.0);
      }
    }

    return const Offset(150.0, 50.0);
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'sourceType': sourceType.name,
        'sourceIdentifier': sourceIdentifier,
        'targetType': targetType.name,
        'targetIdentifier': targetIdentifier,
        'flowType': flowType.name,
        'arrowType': arrowType.name,
        'description': description,
        'curvature': curvature,
        if (explicitSource != null) 'sourceX': explicitSource!.dx,
        if (explicitSource != null) 'sourceY': explicitSource!.dy,
        if (explicitTarget != null) 'targetX': explicitTarget!.dx,
        if (explicitTarget != null) 'targetY': explicitTarget!.dy,
        'strokeColor': strokeColor,
      };

  factory ElectronArrowModel.fromJson(Map<String, dynamic> json) {
    Offset? explicitSrc;
    if (json['sourceX'] != null && json['sourceY'] != null) {
      explicitSrc = Offset((json['sourceX'] as num).toDouble(), (json['sourceY'] as num).toDouble());
    }
    Offset? explicitTgt;
    if (json['targetX'] != null && json['targetY'] != null) {
      explicitTgt = Offset((json['targetX'] as num).toDouble(), (json['targetY'] as num).toDouble());
    }

    return ElectronArrowModel(
      id: json['id'] as String,
      sourceType: _parseSourceType(json['sourceType'] as String?),
      sourceIdentifier: json['sourceIdentifier'] as String? ?? '',
      targetType: _parseTargetType(json['targetType'] as String?),
      targetIdentifier: json['targetIdentifier'] as String? ?? '',
      flowType: _parseFlowType(json['flowType'] as String?),
      arrowType: _parseArrowType(json['arrowType'] as String?),
      description: json['description'] as String? ?? '',
      curvature: (json['curvature'] as num?)?.toDouble() ?? 0.35,
      explicitSource: explicitSrc,
      explicitTarget: explicitTgt,
      strokeColor: json['strokeColor'] as String? ?? '#EC4899',
    );
  }

  static ElectronSourceType _parseSourceType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'lone_pair':
      case 'lonepair':
        return ElectronSourceType.lonePair;
      case 'bond':
        return ElectronSourceType.bond;
      case 'pi_bond':
      case 'pibond':
        return ElectronSourceType.piBond;
      case 'negative_charge':
      case 'negativecharge':
        return ElectronSourceType.negativeCharge;
      case 'atom':
        return ElectronSourceType.atom;
      default:
        return ElectronSourceType.lonePair;
    }
  }

  static ElectronTargetType _parseTargetType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'atom':
        return ElectronTargetType.atom;
      case 'bond':
        return ElectronTargetType.bond;
      case 'positive_charge':
      case 'positivecharge':
        return ElectronTargetType.positiveCharge;
      case 'space':
        return ElectronTargetType.space;
      default:
        return ElectronTargetType.atom;
    }
  }

  static ElectronFlowType _parseFlowType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'lone_pair_attack':
      case 'lonepairattack':
        return ElectronFlowType.lonePairAttack;
      case 'bond_break':
      case 'bondbreak':
        return ElectronFlowType.bondBreak;
      case 'pi_attack':
      case 'piattack':
        return ElectronFlowType.piAttack;
      case 'proton_transfer':
      case 'protontransfer':
        return ElectronFlowType.protonTransfer;
      case 'elimination':
        return ElectronFlowType.elimination;
      case 'bond_formation':
      case 'bondformation':
        return ElectronFlowType.bondFormation;
      case 'resonance':
        return ElectronFlowType.resonance;
      default:
        return ElectronFlowType.lonePairAttack;
    }
  }

  static ArrowHeadType _parseArrowType(String? raw) {
    switch (raw?.toLowerCase()) {
      case 'curved_half':
      case 'curvedhalf':
      case 'fishhook':
        return ArrowHeadType.curvedHalf;
      case 'curved_full':
      case 'curvedfull':
      default:
        return ArrowHeadType.curvedFull;
    }
  }
}
