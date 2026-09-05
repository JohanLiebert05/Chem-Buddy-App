import 'dart:math' as math;
import 'package:flutter/material.dart';

/// Representation of an atom in 3-dimensional Euclidean space.
class Atom3D {
  final String symbol;
  final double x;
  final double y;
  final double z;
  final Color? customColor;
  final double? customRadius;
  final String? hybridization;
  final String? formalCharge;
  final String? note;

  const Atom3D({
    required this.symbol,
    required this.x,
    required this.y,
    required this.z,
    this.customColor,
    this.customRadius,
    this.hybridization,
    this.formalCharge,
    this.note,
  });

  /// Standard CPK (Corey-Pauling-Koltun) colors adapted for dark-mode aesthetics.
  Color get cpkColor {
    if (customColor != null) return customColor!;
    switch (symbol.toUpperCase()) {
      case 'C':
        return const Color(0xFF4B5563); // Graphite slate carbon
      case 'H':
        return const Color(0xFFF1F5F9); // Luminous white hydrogen
      case 'O':
        return const Color(0xFFEF4444); // Vibrant ruby oxygen
      case 'N':
        return const Color(0xFF3B82F6); // Sapphire nitrogen
      case 'BR':
        return const Color(0xFFB91C1C); // Deep reddish-brown bromine
      case 'CL':
        return const Color(0xFF10B981); // Emerald chlorine
      case 'F':
        return const Color(0xFF06B6D4); // Cyan fluorine
      case 'I':
        return const Color(0xFF7C3AED); // Royal violet iodine
      case 'P':
        return const Color(0xFFF59E0B); // Amber phosphorus
      case 'S':
        return const Color(0xFFFBBF24); // Warm sulfur gold
      case 'MG':
        return const Color(0xFF14B8A6); // Metallic teal magnesium
      case 'K':
      case 'NA':
        return const Color(0xFFA855F7); // Alkali metal lilac
      default:
        return const Color(0xFF94A3B8); // Default metallic silver
    }
  }

  /// Relative covalent radius for rendering in Ångströms.
  double get covalentRadius {
    if (customRadius != null) return customRadius!;
    switch (symbol.toUpperCase()) {
      case 'H':
        return 0.32;
      case 'C':
        return 0.77;
      case 'N':
        return 0.71;
      case 'O':
        return 0.66;
      case 'F':
        return 0.57;
      case 'CL':
        return 0.99;
      case 'BR':
        return 1.14;
      case 'I':
        return 1.33;
      case 'P':
        return 1.07;
      case 'S':
        return 1.04;
      case 'MG':
        return 1.30;
      default:
        return 0.75;
    }
  }

  Atom3D copyWith({
    String? symbol,
    double? x,
    double? y,
    double? z,
    Color? customColor,
    double? customRadius,
    String? hybridization,
    String? formalCharge,
    String? note,
  }) {
    return Atom3D(
      symbol: symbol ?? this.symbol,
      x: x ?? this.x,
      y: y ?? this.y,
      z: z ?? this.z,
      customColor: customColor ?? this.customColor,
      customRadius: customRadius ?? this.customRadius,
      hybridization: hybridization ?? this.hybridization,
      formalCharge: formalCharge ?? this.formalCharge,
      note: note ?? this.note,
    );
  }
}

enum BondType3D {
  single,
  doubleBond,
  tripleBond,
  partial, // Transition state forming/breaking bond (rendered dashed)
  aromatic, // Resonance delocalized / benzene ring bond
}

/// Representation of a chemical bond between two atoms in 3D.
class Bond3D {
  final int atomIndex1;
  final int atomIndex2;
  final BondType3D type;
  final Color? customColor;

  const Bond3D({
    required this.atomIndex1,
    required this.atomIndex2,
    this.type = BondType3D.single,
    this.customColor,
  });

  bool get isDouble => type == BondType3D.doubleBond;
  bool get isTriple => type == BondType3D.tripleBond;
  bool get isPartial => type == BondType3D.partial;
  bool get isAromatic => type == BondType3D.aromatic;
}

/// A complete 3D molecular structure with auto-centering and scale calculation.
class Molecule3D {
  final String id;
  final String name;
  final String formula;
  final String? iupacName;
  final String? description;
  final List<Atom3D> atoms;
  final List<Bond3D> bonds;

  const Molecule3D({
    required this.id,
    required this.name,
    required this.formula,
    this.iupacName,
    this.description,
    required this.atoms,
    required this.bonds,
  });

  /// Calculates the center of mass (centroid) of the molecule.
  (double, double, double) get centroid {
    if (atoms.isEmpty) return (0.0, 0.0, 0.0);
    double sumX = 0, sumY = 0, sumZ = 0;
    for (final a in atoms) {
      sumX += a.x;
      sumY += a.y;
      sumZ += a.z;
    }
    final n = atoms.length;
    return (sumX / n, sumY / n, sumZ / n);
  }

  /// Returns a new Molecule3D centered at (0, 0, 0).
  Molecule3D centered() {
    final (cx, cy, cz) = centroid;
    final centeredAtoms = atoms.map((a) {
      return a.copyWith(x: a.x - cx, y: a.y - cy, z: a.z - cz);
    }).toList();

    return Molecule3D(
      id: id,
      name: name,
      formula: formula,
      iupacName: iupacName,
      description: description,
      atoms: centeredAtoms,
      bonds: bonds,
    );
  }

  /// Calculates max radial distance from the origin (radius of bounding sphere).
  double get maxRadius {
    double maxR2 = 0.0;
    for (final a in atoms) {
      final r2 = a.x * a.x + a.y * a.y + a.z * a.z;
      if (r2 > maxR2) maxR2 = r2;
    }
    return math.sqrt(maxR2);
  }
}

/// Educational stages for a reaction's 3D demonstration.
enum ReactionStage {
  reactant,
  intermediate,
  product,
}

extension ReactionStageExtension on ReactionStage {
  String get displayName {
    switch (this) {
      case ReactionStage.reactant:
        return 'Reactants';
      case ReactionStage.intermediate:
        return 'Intermediate / TS';
      case ReactionStage.product:
        return 'Products';
    }
  }

  String get emoji {
    switch (this) {
      case ReactionStage.reactant:
        return '🧪';
      case ReactionStage.intermediate:
        return '⚡';
      case ReactionStage.product:
        return '🎯';
    }
  }
}

/// The collection of 3D molecular structures for a given reaction.
class Reaction3DSet {
  final String reactionId;
  final String title;
  final Molecule3D reactant;
  final Molecule3D intermediate;
  final Molecule3D product;
  final String keyTransformationNote;

  const Reaction3DSet({
    required this.reactionId,
    required this.title,
    required this.reactant,
    required this.intermediate,
    required this.product,
    required this.keyTransformationNote,
  });

  Molecule3D getStage(ReactionStage stage) {
    switch (stage) {
      case ReactionStage.reactant:
        return reactant;
      case ReactionStage.intermediate:
        return intermediate;
      case ReactionStage.product:
        return product;
    }
  }
}
