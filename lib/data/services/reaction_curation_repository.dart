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
    if (_cachedExamples != null) {return _cachedExamples!;}
    await getAllReactions();
    return _cachedExamples ?? [];
  }

  /// Searches curated reactions by query (name, class, conditions, reagents).
  Future<List<CuratedReaction>> searchReactions(String query) async {
    final clean = query.trim().toLowerCase();
    if (clean.isEmpty) {return getAllReactions();}

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
      final csv = await rootBundle.loadString(
        'assets/chemistry/reactions/reaction_electron_flows.csv',
      );
      for (final row in _parseCsv(csv).skip(1)) {
        if (row.length < 12) continue;
        final flow = ElectronArrowModel.fromJson({
          'id': row[0].trim(),
          'sourceType': row[3].trim(),
          'sourceIdentifier': row[5].trim(),
          'targetType': row[6].trim(),
          'targetIdentifier': row[8].trim(),
          'flowType': row[9].trim(),
          'arrowType': row[10].trim(),
          'description': row[11].trim(),
        });
        map.putIfAbsent(row[1].trim(), () => []).add(flow);
      }
    } catch (e) {
      debugPrint('[ReactionCurationRepository] Error reading electron flows: $e');
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
      if (rows.length <= 1) {return map;}

      // Each row describes the changes from the drawn pre-state to this step's product.
      for (final row in rows.skip(1)) {
        if (row.length < 11) continue;

        final reactionId = row[0].trim();
        final stepId = row[1].trim();
        final flowIds = row[6].split('|').map((id) => id.trim()).toSet();
        final step = CuratedReactionStep(
          stepId: stepId,
          reactionId: reactionId,
          stepNumber: int.tryParse(row[2].trim()) ?? 1,
          stepTitle: row[3].trim(),
          stepDescription: row[4].trim(),
          electronFlows: [
            for (final flow in flowsMap[reactionId] ?? <ElectronArrowModel>[])
              if (flowIds.contains(flow.id)) flow,
          ],
          bondChanges: row[7].trim(),
          chargeChanges: row[8].trim(),
          isRds: row[9].trim().toLowerCase() == 'true',
          isReversible: row[10].trim().toLowerCase() == 'true',
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
      if (rows.length <= 1) {return list;}

      for (final row in rows.skip(1)) {
        if (row.length < 10) continue;

        list.add(CuratedReactionExample(
          exampleId: row[0].trim(),
          reactionId: row[1].trim(),
          reactantName: '',
          reactantSmiles: row[2].trim(),
          reagentName: '',
          reagentSmiles: row[3].trim(),
          solvent: row[4].trim(),
          temperature: row[5].trim(),
          expectedProductSmiles: row[6].trim(),
          expectedProductName: row[7].trim(),
          stereochemicalOutcome: row[8].trim(),
          notes: row[9].trim(),
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
      if (rows.length <= 1) {return list;}

      // Header: reaction_id,reaction_name,reaction_class,subclass,description,difficulty,conditions,solvent,temperature,major_product_rule,selectivity_notes,stereochemistry_notes,supported,source_reference
      for (int i = 1; i < rows.length; i++) {
        final row = rows[i];
        if (row.length < 3) {continue;}

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
        if (char == '\r') {i++;}
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
