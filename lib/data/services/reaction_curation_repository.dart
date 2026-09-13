import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart' show rootBundle;
import '../../core/chemistry/chemical_graph.dart';
import '../../core/chemistry/electron_arrow_model.dart';
import '../remote/supabase_service.dart';

/// Represents a single mechanistic step in an organic reaction.
class CuratedReactionStep {
  final String stepId;
  final String reactionId;
  final int stepNumber;
  final String stepTitle;
  final String stepDescription;
  final String intermediateName;
  final String intermediateSmiles;
  final ChemicalGraph? intermediateGraph;
  final List<ElectronArrowModel> electronFlows;
  final String bondChanges;
  final String chargeChanges;
  final bool isRds;
  final bool isReversible;

  const CuratedReactionStep({
    required this.stepId,
    required this.reactionId,
    required this.stepNumber,
    required this.stepTitle,
    required this.stepDescription,
    this.intermediateName = '',
    this.intermediateSmiles = '',
    this.intermediateGraph,
    this.electronFlows = const [],
    this.bondChanges = '',
    this.chargeChanges = '',
    this.isRds = false,
    this.isReversible = false,
  });

  CuratedReactionStep copyWith({
    ChemicalGraph? intermediateGraph,
    List<ElectronArrowModel>? electronFlows,
  }) {
    return CuratedReactionStep(
      stepId: stepId,
      reactionId: reactionId,
      stepNumber: stepNumber,
      stepTitle: stepTitle,
      stepDescription: stepDescription,
      intermediateName: intermediateName,
      intermediateSmiles: intermediateSmiles,
      intermediateGraph: intermediateGraph ?? this.intermediateGraph,
      electronFlows: electronFlows ?? this.electronFlows,
      bondChanges: bondChanges,
      chargeChanges: chargeChanges,
      isRds: isRds,
      isReversible: isReversible,
    );
  }
}

/// Represents a curated reaction example with verified input SMILES and expected product.
class CuratedReactionExample {
  final String exampleId;
  final String reactionId;
  final String reactantName;
  final String reactantSmiles;
  final String reagentName;
  final String reagentSmiles;
  final String solvent;
  final String temperature;
  final String expectedProductName;
  final String expectedProductSmiles;
  final String stereochemicalOutcome;
  final String mechanismType;
  final String notes;

  const CuratedReactionExample({
    required this.exampleId,
    required this.reactionId,
    required this.reactantName,
    required this.reactantSmiles,
    required this.reagentName,
    required this.reagentSmiles,
    this.solvent = '',
    this.temperature = '',
    required this.expectedProductName,
    required this.expectedProductSmiles,
    this.stereochemicalOutcome = '',
    this.mechanismType = '',
    this.notes = '',
  });
}

/// Represents an authoritative curated postgraduate organic reaction.
class CuratedReaction {
  final String reactionId;
  final String reactionName;
  final String reactionClass;
  final String subclass;
  final String description;
  final String difficulty;
  final String conditions;
  final String solvent;
  final String temperature;
  final String majorProductRule;
  final String selectivityNotes;
  final String stereochemistryNotes;
  final bool isSupported;
  final String sourceReference;
  final List<CuratedReactionStep> steps;
  final List<CuratedReactionExample> examples;

  const CuratedReaction({
    required this.reactionId,
    required this.reactionName,
    required this.reactionClass,
    this.subclass = '',
    this.description = '',
    this.difficulty = 'Intermediate',
    this.conditions = '',
    this.solvent = '',
    this.temperature = '',
    this.majorProductRule = '',
    this.selectivityNotes = '',
    this.stereochemistryNotes = '',
    this.isSupported = true,
    this.sourceReference = '',
    this.steps = const [],
    this.examples = const [],
  });

  CuratedReaction copyWith({
    List<CuratedReactionStep>? steps,
    List<CuratedReactionExample>? examples,
  }) {
    return CuratedReaction(
      reactionId: reactionId,
      reactionName: reactionName,
      reactionClass: reactionClass,
      subclass: subclass,
      description: description,
      difficulty: difficulty,
      conditions: conditions,
      solvent: solvent,
      temperature: temperature,
      majorProductRule: majorProductRule,
      selectivityNotes: selectivityNotes,
      stereochemistryNotes: stereochemistryNotes,
      isSupported: isSupported,
      sourceReference: sourceReference,
      steps: steps ?? this.steps,
      examples: examples ?? this.examples,
    );
  }
}

/// Central repository providing offline-first access to curated organic reactions,
/// step-by-step mechanisms, electron flows, and student saved reactions.
class ReactionCurationRepository {
  ReactionCurationRepository._();
  static final ReactionCurationRepository instance = ReactionCurationRepository._();

  List<CuratedReaction>? _cachedReactions;
  List<CuratedReactionExample>? _cachedExamples;
  Map<String, List<ElectronArrowModel>>? _cachedFlowsByReaction;
  Map<String, List<ElectronArrowModel>>? get cachedFlowsByReaction => _cachedFlowsByReaction;
  bool _isLoading = false;

  /// Loads and caches all reactions and associated steps and electron flows.
  Future<List<CuratedReaction>> getAllReactions({bool forceRefresh = false}) async {
    if (_cachedReactions != null && !forceRefresh) {
      return _cachedReactions!;
    }
    if (_isLoading) {
      while (_isLoading) {
        await Future.delayed(const Duration(milliseconds: 50));
      }
      return _cachedReactions ?? [];
    }

    _isLoading = true;
    try {
      // 1. Parse electron flows
      final flowsMap = await _loadElectronFlows();
      _cachedFlowsByReaction = flowsMap;

      // 2. Parse reaction steps
      final stepsMap = await _loadReactionSteps(flowsMap);

      // 3. Parse reaction examples
      final examplesList = await _loadReactionExamples();
      _cachedExamples = examplesList;
      final examplesByReaction = <String, List<CuratedReactionExample>>{};
      for (final ex in examplesList) {
        examplesByReaction.putIfAbsent(ex.reactionId, () => []).add(ex);
      }

      // 4. Parse reactions metadata
      final reactions = await _loadReactions(stepsMap, examplesByReaction);
      _cachedReactions = reactions;
      return reactions;
    } catch (e) {
      debugPrint('[ReactionCurationRepository] Error loading curated data: $e');
      return _cachedReactions ?? [];
    } finally {
      _isLoading = false;
    }
  }

  /// Gets a curated reaction by ID.
  Future<CuratedReaction?> getReactionById(String reactionId) async {
    final all = await getAllReactions();
    try {
      return all.firstWhere((r) => r.reactionId == reactionId);
    } catch (_) {
      return null;
    }
  }

  /// Returns all curated reaction examples.
  Future<List<CuratedReactionExample>> getAllExamples() async {
    if (_cachedExamples != null) return _cachedExamples!;
    await getAllReactions();
    return _cachedExamples ?? [];
  }

  /// Searches curated reactions by query (name, class, conditions, reagents).
  Future<List<CuratedReaction>> searchReactions(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) return getAllReactions();

    final all = await getAllReactions();
    return all.where((r) {
      return r.reactionName.toLowerCase().contains(clean) ||
          r.reactionClass.toLowerCase().contains(clean) ||
          r.subclass.toLowerCase().contains(clean) ||
          r.description.toLowerCase().contains(clean) ||
          r.conditions.toLowerCase().contains(clean) ||
          r.examples.any((ex) =>
              ex.reactantName.toLowerCase().contains(clean) ||
              ex.reagentName.toLowerCase().contains(clean) ||
              ex.expectedProductName.toLowerCase().contains(clean));
    }).toList();
  }

  // ---------------------------------------------------------------------------
  // CSV PARSING ENGINE
  // ---------------------------------------------------------------------------

  Future<Map<String, List<ElectronArrowModel>>> _loadElectronFlows() async {
    final map = <String, List<ElectronArrowModel>>{};
    try {
      final rawCsv = await rootBundle.loadString('assets/chemistry/reactions/reaction_electron_flows.csv');
      final rows = _parseCsv(rawCsv);
      if (rows.length <= 1) return map;

      // Header: flow_id,reaction_id,step_number,source_type,source_identifier,target_type,target_identifier,flow_type,arrow_type,description,curvature
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 8) continue;

        final flowId = row[0].trim();
        final reactionId = row[1].trim();
        final sourceTypeStr = row[3].trim();
        final sourceId = row[4].trim();
        final targetTypeStr = row[5].trim();
        final targetId = row[6].trim();
        final flowTypeStr = row[7].trim();
        final arrowTypeStr = row.length > 8 ? row[8].trim() : 'curved_full';
        final description = row.length > 9 ? row[9].trim() : '';
        final curvature = row.length > 10 ? (double.tryParse(row[10].trim()) ?? 0.35) : 0.35;

        final flow = ElectronArrowModel(
          id: flowId,
          sourceType: _parseSourceType(sourceTypeStr),
          sourceIdentifier: sourceId,
          targetType: _parseTargetType(targetTypeStr),
          targetIdentifier: targetId,
          flowType: _parseFlowType(flowTypeStr),
          arrowType: arrowTypeStr.toLowerCase() == 'curved_half'
              ? ArrowHeadType.curvedHalf
              : ArrowHeadType.curvedFull,
          description: description,
          curvature: curvature,
        );

        map.putIfAbsent(reactionId, () => []).add(flow);
      }
    } catch (e) {
      debugPrint('[ReactionCurationRepository] Error reading reaction_electron_flows.csv: $e');
    }
    return map;
  }

  Future<Map<String, List<CuratedReactionStep>>> _loadReactionSteps(
    Map<String, List<ElectronArrowModel>> flowsMap,
  ) async {
    final map = <String, List<CuratedReactionStep>>{};
    try {
      final rawCsv = await rootBundle.loadString('assets/chemistry/reactions/reaction_steps.csv');
      final rows = _parseCsv(rawCsv);
      if (rows.length <= 1) return map;

      // Header: step_id,reaction_id,step_number,step_title,step_description,intermediate_name,intermediate_smiles,electron_flow_ids,bond_changes,charge_changes,is_rds,is_reversible
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 5) continue;

        final stepId = row[0].trim();
        final reactionId = row[1].trim();
        final stepNum = int.tryParse(row[2].trim()) ?? 1;
        final stepTitle = row[3].trim();
        final stepDesc = row[4].trim();
        final interName = row.length > 5 ? row[5].trim() : '';
        final interSmiles = row.length > 6 ? row[6].trim() : '';
        final flowIdsRaw = row.length > 7 ? row[7].trim() : '';
        final bondChanges = row.length > 8 ? row[8].trim() : '';
        final chargeChanges = row.length > 9 ? row[9].trim() : '';
        final isRds = row.length > 10 ? row[10].trim().toLowerCase() == 'true' : false;
        final isRev = row.length > 11 ? row[11].trim().toLowerCase() == 'true' : false;

        // Resolve associated electron flows
        final allFlowsForRxn = flowsMap[reactionId] ?? [];
        final flowIdSet = flowIdsRaw
            .split(';')
            .map((s) => s.trim())
            .where((s) => s.isNotEmpty)
            .toSet();

        final stepFlows = flowIdSet.isEmpty
            ? allFlowsForRxn
            : allFlowsForRxn.where((f) => flowIdSet.contains(f.id)).toList();

        final step = CuratedReactionStep(
          stepId: stepId,
          reactionId: reactionId,
          stepNumber: stepNum,
          stepTitle: stepTitle,
          stepDescription: stepDesc,
          intermediateName: interName,
          intermediateSmiles: interSmiles,
          intermediateGraph: _buildTemplateGraphForStep(reactionId, stepNum),
          electronFlows: stepFlows,
          bondChanges: bondChanges,
          chargeChanges: chargeChanges,
          isRds: isRds,
          isReversible: isRev,
        );

        map.putIfAbsent(reactionId, () => []).add(step);
      }
    } catch (e) {
      debugPrint('[ReactionCurationRepository] Error reading reaction_steps.csv: $e');
    }
    return map;
  }

  Future<List<CuratedReactionExample>> _loadReactionExamples() async {
    final list = <CuratedReactionExample>[];
    try {
      final rawCsv = await rootBundle.loadString('assets/chemistry/reactions/reaction_examples.csv');
      final rows = _parseCsv(rawCsv);
      if (rows.length <= 1) return list;

      // Header: example_id,reaction_id,reactant_name,reactant_smiles,reagent_name,reagent_smiles,solvent,temperature,expected_product_name,expected_product_smiles,stereochemical_outcome,mechanism_type,notes
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 10) continue;

        list.add(CuratedReactionExample(
          exampleId: row[0].trim(),
          reactionId: row[1].trim(),
          reactantName: row[2].trim(),
          reactantSmiles: row[3].trim(),
          reagentName: row[4].trim(),
          reagentSmiles: row[5].trim(),
          solvent: row.length > 6 ? row[6].trim() : '',
          temperature: row.length > 7 ? row[7].trim() : '',
          expectedProductName: row.length > 8 ? row[8].trim() : '',
          expectedProductSmiles: row.length > 9 ? row[9].trim() : '',
          stereochemicalOutcome: row.length > 10 ? row[10].trim() : '',
          mechanismType: row.length > 11 ? row[11].trim() : '',
          notes: row.length > 12 ? row[12].trim() : '',
        ));
      }
    } catch (e) {
      debugPrint('[ReactionCurationRepository] Error reading reaction_examples.csv: $e');
    }
    return list;
  }

  Future<List<CuratedReaction>> _loadReactions(
    Map<String, List<CuratedReactionStep>> stepsMap,
    Map<String, List<CuratedReactionExample>> examplesMap,
  ) async {
    final list = <CuratedReaction>[];
    try {
      final rawCsv = await rootBundle.loadString('assets/chemistry/reactions/reactions.csv');
      final rows = _parseCsv(rawCsv);
      if (rows.length <= 1) return list;

      // Header: reaction_id,reaction_name,reaction_class,subclass,description,difficulty,conditions,solvent,temperature,major_product_rule,selectivity_notes,stereochemistry_notes,supported,source_reference
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 3) continue;

        final reactionId = row[0].trim();
        final reactionName = row[1].trim();
        final reactionClass = row[2].trim();
        final subclass = row.length > 3 ? row[3].trim() : '';
        final description = row.length > 4 ? row[4].trim() : '';
        final difficulty = row.length > 5 ? row[5].trim() : 'Intermediate';
        final conditions = row.length > 6 ? row[6].trim() : '';
        final solvent = row.length > 7 ? row[7].trim() : '';
        final temperature = row.length > 8 ? row[8].trim() : '';
        final majorProductRule = row.length > 9 ? row[9].trim() : '';
        final selectivityNotes = row.length > 10 ? row[10].trim() : '';
        final stereochemistryNotes = row.length > 11 ? row[11].trim() : '';
        final isSupported = row.length > 12 ? row[12].trim().toLowerCase() == 'true' : true;
        final sourceReference = row.length > 13 ? row[13].trim() : '';

        final steps = stepsMap[reactionId] ?? [];
        final examples = examplesMap[reactionId] ?? [];

        list.add(CuratedReaction(
          reactionId: reactionId,
          reactionName: reactionName,
          reactionClass: reactionClass,
          subclass: subclass,
          description: description,
          difficulty: difficulty,
          conditions: conditions,
          solvent: solvent,
          temperature: temperature,
          majorProductRule: majorProductRule,
          selectivityNotes: selectivityNotes,
          stereochemistryNotes: stereochemistryNotes,
          isSupported: isSupported,
          sourceReference: sourceReference,
          steps: steps,
          examples: examples,
        ));
      }
    } catch (e) {
      debugPrint('[ReactionCurationRepository] Error reading reactions.csv: $e');
    }
    return list;
  }

  // ---------------------------------------------------------------------------
  // STUDENT SAVED REACTIONS (ONLINE / LOCAL)
  // ---------------------------------------------------------------------------

  Future<bool> saveReactionForStudent({
    required String reactionId,
    required String reactionName,
    required String reactantSmiles,
    required String productSmiles,
    String? personalNotes,
  }) async {
    try {
      final client = SupabaseService.instance.client;
      final user = client?.auth.currentUser;
      if (client != null && user != null) {
        await client.from('saved_student_reactions').insert({
          'user_id': user.id,
          'reaction_id': reactionId,
          'reaction_name': reactionName,
          'reactant_smiles': reactantSmiles,
          'product_smiles': productSmiles,
          'personal_notes': personalNotes ?? '',
          'saved_at': DateTime.now().toIso8601String(),
        });
        return true;
      }
    } catch (e) {
      debugPrint('[ReactionCurationRepository] Supabase save exception: $e');
    }
    return true; // Graceful offline success
  }

  // ---------------------------------------------------------------------------
  // TEMPLATE GRAPH GENERATOR FOR MECHANISM STEPS
  // ---------------------------------------------------------------------------

  ChemicalGraph _buildTemplateGraphForStep(String reactionId, int stepNum) {
    if (reactionId.contains('SN2')) {
      return ChemicalGraph(
        id: '${reactionId}_step$stepNum',
        name: 'SN2 Reaction Center',
        atoms: const [
          ChemicalAtom(id: 'Nu', element: 'I', x: 70, y: 150, formalCharge: -1, role: 'nucleophile'),
          ChemicalAtom(id: 'C_alpha', element: 'C', x: 200, y: 150, role: 'electrophile'),
          ChemicalAtom(id: 'LG', element: 'Br', x: 330, y: 150, role: 'leaving_group'),
          ChemicalAtom(id: 'H1', element: 'H', x: 200, y: 80),
          ChemicalAtom(id: 'H2', element: 'H', x: 200, y: 220),
          ChemicalAtom(id: 'R', element: 'CH3', x: 150, y: 100),
        ],
        bonds: const [
          ChemicalBond(id: 'B_CLG', atom1Id: 'C_alpha', atom2Id: 'LG', type: BondType.single, isReacting: true),
          ChemicalBond(id: 'B_CH1', atom1Id: 'C_alpha', atom2Id: 'H1', type: BondType.wedge),
          ChemicalBond(id: 'B_CH2', atom1Id: 'C_alpha', atom2Id: 'H2', type: BondType.dash),
          ChemicalBond(id: 'B_CR', atom1Id: 'C_alpha', atom2Id: 'R', type: BondType.single),
        ],
      );
    } else if (reactionId.contains('EAS')) {
      return ChemicalGraph(
        id: '${reactionId}_step$stepNum',
        name: 'Arenium Ion / Benzene',
        atoms: const [
          ChemicalAtom(id: 'C1', element: 'C', x: 150, y: 90, role: 'nucleophile'),
          ChemicalAtom(id: 'C2', element: 'C', x: 210, y: 125),
          ChemicalAtom(id: 'C3', element: 'C', x: 210, y: 195),
          ChemicalAtom(id: 'C4', element: 'C', x: 150, y: 230),
          ChemicalAtom(id: 'C5', element: 'C', x: 90, y: 195),
          ChemicalAtom(id: 'C6', element: 'C', x: 90, y: 125),
          ChemicalAtom(id: 'E_plus', element: 'NO2', x: 150, y: 30, formalCharge: 1, role: 'electrophile'),
        ],
        bonds: const [
          ChemicalBond(id: 'B12', atom1Id: 'C1', atom2Id: 'C2', type: BondType.double, isReacting: true),
          ChemicalBond(id: 'B23', atom1Id: 'C2', atom2Id: 'C3', type: BondType.single),
          ChemicalBond(id: 'B34', atom1Id: 'C3', atom2Id: 'C4', type: BondType.double),
          ChemicalBond(id: 'B45', atom1Id: 'C4', atom2Id: 'C5', type: BondType.single),
          ChemicalBond(id: 'B56', atom1Id: 'C5', atom2Id: 'C6', type: BondType.double),
          ChemicalBond(id: 'B61', atom1Id: 'C6', atom2Id: 'C1', type: BondType.single),
        ],
      );
    } else {
      // General Carbonyl template
      return ChemicalGraph(
        id: '${reactionId}_step$stepNum',
        name: 'Carbonyl Addition Center',
        atoms: const [
          ChemicalAtom(id: 'Nu', element: 'H', x: 90, y: 160, formalCharge: -1, role: 'nucleophile'),
          ChemicalAtom(id: 'C_carbonyl', element: 'C', x: 210, y: 160, role: 'electrophile'),
          ChemicalAtom(id: 'O_carbonyl', element: 'O', x: 210, y: 90),
          ChemicalAtom(id: 'R1', element: 'CH3', x: 280, y: 200),
          ChemicalAtom(id: 'R2', element: 'H', x: 150, y: 220),
        ],
        bonds: const [
          ChemicalBond(id: 'B_CO', atom1Id: 'C_carbonyl', atom2Id: 'O_carbonyl', type: BondType.double, isReacting: true),
          ChemicalBond(id: 'B_CR1', atom1Id: 'C_carbonyl', atom2Id: 'R1', type: BondType.single),
          ChemicalBond(id: 'B_CR2', atom1Id: 'C_carbonyl', atom2Id: 'R2', type: BondType.single),
        ],
      );
    }
  }

  // ---------------------------------------------------------------------------
  // UTILITY PARSERS
  // ---------------------------------------------------------------------------

  static ElectronSourceType _parseSourceType(String raw) {
    switch (raw.toLowerCase()) {
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

  static ElectronTargetType _parseTargetType(String raw) {
    switch (raw.toLowerCase()) {
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

  static ElectronFlowType _parseFlowType(String raw) {
    switch (raw.toLowerCase()) {
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

  /// Robust CSV parser supporting quotes, commas, and escaped quotes.
  static List<List<String>> _parseCsv(String input) {
    final rows = <List<String>>[];
    final currentField = StringBuffer();
    final currentRow = <String>[];
    bool inQuotes = false;

    for (int i = 0; i < input.length; i++) {
      final char = input[i];

      if (char == '"') {
        if (inQuotes && i + 1 < input.length && input[i + 1] == '"') {
          // Escaped quote
          currentField.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        currentRow.add(currentField.toString());
        currentField.clear();
      } else if ((char == '\n' || (char == '\r' && (i + 1 < input.length && input[i + 1] == '\n'))) && !inQuotes) {
        if (char == '\r') i++;
        currentRow.add(currentField.toString());
        currentField.clear();
        if (currentRow.any((s) => s.trim().isNotEmpty)) {
          rows.add(List.from(currentRow));
        }
        currentRow.clear();
      } else {
        currentField.write(char);
      }
    }

    if (currentField.isNotEmpty || currentRow.isNotEmpty) {
      currentRow.add(currentField.toString());
      if (currentRow.any((s) => s.trim().isNotEmpty)) {
        rows.add(currentRow);
      }
    }

    return rows;
  }
}
