import 'dart:convert';

import 'package:flutter/services.dart';

class PeptideReference {
  const PeptideReference({
    required this.name,
    required this.aliases,
    required this.sequence,
    required this.description,
    required this.cid,
    required this.formula,
    required this.mass,
    required this.mol2d,
    required this.mol3d,
    this.pdbId,
    this.ccdId,
  });

  final String name;
  final List<String> aliases;
  final String sequence;
  final String description;
  final int cid;
  final String formula;
  final double mass;
  final String mol2d;
  final String mol3d;
  final String? pdbId;
  final String? ccdId;

  String get source3dLabel {
    if (pdbId case final id?) {
      return 'RCSB PDB $id · solution NMR model 1 · heavy atoms only';
    }
    if (ccdId case final id?) {
      return 'RCSB Chemical Component Dictionary $id · idealized coordinates';
    }
    return 'PubChem computed conformer · one possible geometry';
  }

  Uri? get source3dUri {
    if (pdbId case final id?) {
      return Uri.https('www.rcsb.org', '/structure/$id');
    }
    if (ccdId case final id?) return Uri.https('www.rcsb.org', '/ligand/$id');
    return null;
  }

  factory PeptideReference.fromJson(Map<String, dynamic> json) =>
      PeptideReference(
        name: json['name'] as String,
        aliases: List<String>.from(json['aliases'] as List),
        sequence: json['sequence'] as String,
        description: json['description'] as String,
        cid: json['cid'] as int,
        formula: json['formula'] as String,
        mass: (json['mass'] as num).toDouble(),
        mol2d: json['mol2d'] as String,
        mol3d: json['mol3d'] as String,
        pdbId: json['pdbId'] as String?,
        ccdId: json['ccdId'] as String?,
      );

  static Future<List<PeptideReference>> load() async {
    final text = await rootBundle.loadString(
      'assets/chemistry/peptide_structures.json',
    );
    return (jsonDecode(text) as List)
        .cast<Map<String, dynamic>>()
        .map(PeptideReference.fromJson)
        .toList();
  }

  bool matches(String query) {
    String normalize(String value) =>
        value.trim().toLowerCase().replaceAll(RegExp('[–—−]'), '-');
    final clean = normalize(query);
    return [
      name,
      formula,
      sequence,
      cid.toString(),
      ...aliases,
    ].any((text) => normalize(text).contains(clean));
  }
}
