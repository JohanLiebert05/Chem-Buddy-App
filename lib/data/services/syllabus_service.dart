import '../models/syllabus_models.dart';
import '../remote/supabase_service.dart';

class SyllabusService {
  SyllabusService({SupabaseService? remote})
      : _remote = remote ?? SupabaseService.instance;

  final SupabaseService _remote;

  static const List<University> defaultUniversities = [
    University(id: 'general', name: 'General MSc Chemistry (Common Curriculum)', shortName: 'GENERAL', state: 'All India'),
    University(id: 'mu', name: 'University of Mumbai', shortName: 'MU', state: 'Maharashtra'),
    University(id: 'du', name: 'University of Delhi', shortName: 'DU', state: 'Delhi'),
    University(id: 'sppu', name: 'Savitribai Phule Pune University', shortName: 'SPPU', state: 'Maharashtra'),
    University(id: 'bu', name: 'Bangalore University', shortName: 'BU', state: 'Karnataka'),
    University(id: 'ou', name: 'Osmania University', shortName: 'OU', state: 'Telangana'),
    University(id: 'cu', name: 'University of Calcutta', shortName: 'CU', state: 'West Bengal'),
    University(id: 'unom', name: 'University of Madras', shortName: 'UNOM', state: 'Tamil Nadu'),
  ];

  Future<List<University>> fetchUniversities() async {
    final client = _remote.client;
    if (client != null && _remote.configured) {
      try {
        final rows = await client.from('universities').select().order('name');
        if (rows.isNotEmpty) {
          return (rows as List).map((j) => University.fromJson(Map<String, dynamic>.from(j as Map))).toList();
        }
      } catch (_) {}
    }
    return defaultUniversities;
  }

  Future<List<SyllabusSubject>> fetchSubjects(String universityId, {int? semester}) async {
    final client = _remote.client;
    if (client != null && _remote.configured) {
      try {
        var query = client.from('syllabus_subjects').select().eq('university_id', universityId);
        if (semester != null) {
          query = query.eq('semester', semester);
        }
        final rows = await query.order('sort_order');
        if (rows.isNotEmpty) {
          return (rows as List).map((j) => SyllabusSubject.fromJson(Map<String, dynamic>.from(j as Map))).toList();
        }
      } catch (_) {}
    }

    // Curated MSc Chemistry core curriculum fallback
    return _getFallbackSubjects(semester: semester);
  }

  Future<List<SyllabusUnit>> fetchUnits(String subjectId) async {
    final client = _remote.client;
    if (client != null && _remote.configured) {
      try {
        final rows = await client.from('syllabus_units').select().eq('subject_id', subjectId).order('unit_number');
        if (rows.isNotEmpty) {
          return (rows as List).map((j) => SyllabusUnit.fromJson(Map<String, dynamic>.from(j as Map))).toList();
        }
      } catch (_) {}
    }

    return _getFallbackUnits(subjectId);
  }

  Future<List<SyllabusTopic>> fetchTopics(String unitId) async {
    final client = _remote.client;
    if (client != null && _remote.configured) {
      try {
        final rows = await client.from('syllabus_topics').select().eq('unit_id', unitId).order('sort_order');
        if (rows.isNotEmpty) {
          return (rows as List).map((j) => SyllabusTopic.fromJson(Map<String, dynamic>.from(j as Map))).toList();
        }
      } catch (_) {}
    }

    return _getFallbackTopics(unitId);
  }

  List<SyllabusSubject> _getFallbackSubjects({int? semester}) {
    final all = [
      // Semester 1
      const SyllabusSubject(id: 'org_1', name: 'Advanced Organic Chemistry - I', code: 'CHEM-M101', semester: 1, description: 'Reaction mechanisms, stereochemistry, and reactive intermediates'),
      const SyllabusSubject(id: 'inorg_1', name: 'Inorganic Chemistry - I', code: 'CHEM-M102', semester: 1, description: 'Transition metal complexes, crystal field theory, and organometallics'),
      const SyllabusSubject(id: 'phys_1', name: 'Physical Chemistry - I', code: 'CHEM-M103', semester: 1, description: 'Quantum mechanics, chemical thermodynamics, and statistical mechanics'),
      const SyllabusSubject(id: 'spec_1', name: 'Spectroscopy - I', code: 'CHEM-M104', semester: 1, description: 'UV-Vis, IR, 1H-NMR, and Mass Spectrometry instrumentation & interpretation'),

      // Semester 2
      const SyllabusSubject(id: 'org_2', name: 'Advanced Organic Chemistry - II', code: 'CHEM-M201', semester: 2, description: 'Pericyclic reactions, photochemistry, and organometallic reagents'),
      const SyllabusSubject(id: 'inorg_2', name: 'Inorganic Chemistry - II', code: 'CHEM-M202', semester: 2, description: 'Bioinorganic chemistry, electronic spectra, and magnetic properties'),
      const SyllabusSubject(id: 'phys_2', name: 'Physical Chemistry - II', code: 'CHEM-M203', semester: 2, description: 'Chemical kinetics, surface chemistry, and electrochemistry'),
      const SyllabusSubject(id: 'ana_1', name: 'Analytical Chemistry', code: 'CHEM-M204', semester: 2, description: 'Chromatography (HPLC/GC), electroanalytical methods, and thermal analysis'),

      // Semester 3
      const SyllabusSubject(id: 'org_synth', name: 'Organic Synthesis & Retrosynthesis', code: 'CHEM-M301', semester: 3, description: 'Disconnection approach, protecting groups, and total synthesis'),
      const SyllabusSubject(id: 'het_chem', name: 'Heterocyclic Chemistry', code: 'CHEM-M302', semester: 3, description: 'Synthesis and reactivity of five- and six-membered heterocycles'),

      // Semester 4
      const SyllabusSubject(id: 'med_chem', name: 'Medicinal & Pharmaceutical Chemistry', code: 'CHEM-M401', semester: 4, description: 'Drug design, pharmacokinetics, and molecular pharmacology'),
      const SyllabusSubject(id: 'poly_chem', name: 'Polymer & Materials Chemistry', code: 'CHEM-M402', semester: 4, description: 'Polymerization kinetics, characterization, and nanomaterials'),
    ];

    if (semester != null) {
      return all.where((s) => s.semester == semester).toList();
    }
    return all;
  }

  List<SyllabusUnit> _getFallbackUnits(String subjectId) {
    if (subjectId.contains('org_1')) {
      return const [
        SyllabusUnit(id: 'u_org1_1', subjectId: 'org_1', name: 'Unit I: Stereochemistry & Conformation', unitNumber: 1, description: 'Chirality, topicity, conformational analysis of cyclic/acyclic systems'),
        SyllabusUnit(id: 'u_org1_2', subjectId: 'org_1', name: 'Unit II: Aliphatic Nucleophilic Substitution', unitNumber: 2, description: 'SN1, SN2, SNi mechanisms, neighbouring group participation (NGP)'),
        SyllabusUnit(id: 'u_org1_3', subjectId: 'org_1', name: 'Unit III: Aromatic Electrophilic & Nucleophilic Substitution', unitNumber: 3, description: 'Arenium ion mechanism, benzyne intermediates, SRN1'),
        SyllabusUnit(id: 'u_org1_4', subjectId: 'org_1', name: 'Unit IV: Reactive Intermediates', unitNumber: 4, description: 'Carbocations, carbanions, free radicals, carbenes, nitrenes'),
      ];
    } else if (subjectId.contains('org_2')) {
      return const [
        SyllabusUnit(id: 'u_org2_1', subjectId: 'org_2', name: 'Unit I: Pericyclic Reactions - Electrocyclic', unitNumber: 1, description: 'FMO and PMO methods, Woodward-Hoffmann rules'),
        SyllabusUnit(id: 'u_org2_2', subjectId: 'org_2', name: 'Unit II: Cycloadditions & Sigmatropic Shifts', unitNumber: 2, description: 'Diels-Alder, [2+2], [3,3]-Cope and Claisen rearrangements'),
        SyllabusUnit(id: 'u_org2_3', subjectId: 'org_2', name: 'Unit III: Organic Photochemistry', unitNumber: 3, description: 'Norrish Type I & II, Paterno-Buchi, Di-pi-methane rearrangement'),
      ];
    }

    return const [
      SyllabusUnit(id: 'u_gen_1', subjectId: 'gen', name: 'Unit I: Fundamental Principles & Mechanisms', unitNumber: 1),
      SyllabusUnit(id: 'u_gen_2', subjectId: 'gen', name: 'Unit II: Advanced Theoretical Concepts', unitNumber: 2),
      SyllabusUnit(id: 'u_gen_3', subjectId: 'gen', name: 'Unit III: Applications & Problem Solving', unitNumber: 3),
      SyllabusUnit(id: 'u_gen_4', subjectId: 'gen', name: 'Unit IV: Modern Advances & Instrumentation', unitNumber: 4),
    ];
  }

  List<SyllabusTopic> _getFallbackTopics(String unitId) {
    if (unitId == 'u_org1_2') {
      return const [
        SyllabusTopic(id: 't_sn1', unitId: 'u_org1_2', name: 'SN1 Mechanism & Carbocation Rearrangements', importance: 'high', hasMechanism: true, mechanismIds: ['sn1']),
        SyllabusTopic(id: 't_sn2', unitId: 'u_org1_2', name: 'SN2 Mechanism & Walden Inversion', importance: 'high', hasMechanism: true, mechanismIds: ['sn2']),
        SyllabusTopic(id: 't_ngp', unitId: 'u_org1_2', name: 'Neighbouring Group Participation (NGP) by Pi & Sigma bonds', importance: 'high', hasMechanism: true),
        SyllabusTopic(id: 't_sni', unitId: 'u_org1_2', name: 'SNi Mechanism in Thionyl Chloride Reactions', importance: 'medium', hasMechanism: true),
      ];
    } else if (unitId == 'u_org2_1') {
      return const [
        SyllabusTopic(id: 't_peri_1', unitId: 'u_org2_1', name: 'Woodward-Hoffmann Rules for Electrocyclic Closures', importance: 'high', hasMechanism: true, mechanismIds: ['woodward_hoffmann']),
        SyllabusTopic(id: 't_peri_2', unitId: 'u_org2_1', name: 'Conrotatory vs Disrotatory Modes in 4n and 4n+2 Systems', importance: 'high', hasMechanism: true),
        SyllabusTopic(id: 't_peri_3', unitId: 'u_org2_1', name: 'Correlation Diagrams & Frontier Molecular Orbital (FMO) Method', importance: 'medium'),
      ];
    } else if (unitId == 'u_org2_2') {
      return const [
        SyllabusTopic(id: 't_da', unitId: 'u_org2_2', name: 'Diels-Alder [4+2] Cycloaddition: Endo Rule & Regioselectivity', importance: 'high', hasMechanism: true, mechanismIds: ['diels_alder']),
        SyllabusTopic(id: 't_claisen', unitId: 'u_org2_2', name: '[3,3]-Sigmatropic Rearrangements (Claisen and Cope)', importance: 'high', hasMechanism: true, mechanismIds: ['claisen']),
      ];
    }

    return const [
      SyllabusTopic(id: 't_gen_1', unitId: 'u_gen', name: 'Core Foundations & Governing Principles', importance: 'high'),
      SyllabusTopic(id: 't_gen_2', unitId: 'u_gen', name: 'Reaction Energetics & Kinetics', importance: 'medium'),
      SyllabusTopic(id: 't_gen_3', unitId: 'u_gen', name: 'Analytical Spectroscopic Signatures', importance: 'high'),
      SyllabusTopic(id: 't_gen_4', unitId: 'u_gen', name: 'Exam Problem Solving & Numerical Derivations', importance: 'medium'),
    ];
  }
}
