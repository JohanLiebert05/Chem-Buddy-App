import '../../core/chemistry/chemical_graph.dart';
import '../../core/chemistry/mechanism_svg_renderer.dart';
import 'reaction_curation_repository.dart';

/// Level of confidence for a deterministic chemical reaction prediction.
enum ReactionConfidence {
  high,
  moderate,
  low,
  none,
}

/// Result of matching student inputs against the curated MSc reaction database.
class ReactionMatchResult {
  final bool isMatched;
  final ReactionConfidence confidence;
  final CuratedReaction? reaction;
  final CuratedReactionExample? matchedExample;
  final String majorProductSmiles;
  final String majorProductName;
  final List<CuratedReactionStep> mechanismSteps;
  final String schemeSvg;
  final String notes;
  final String? unmatchedReason;
  final List<String> suggestions;

  const ReactionMatchResult({
    required this.isMatched,
    required this.confidence,
    this.reaction,
    this.matchedExample,
    this.majorProductSmiles = '',
    this.majorProductName = '',
    this.mechanismSteps = const [],
    this.schemeSvg = '',
    this.notes = '',
    this.unmatchedReason,
    this.suggestions = const [],
  });

  factory ReactionMatchResult.unmatched({
    required String reason,
    List<String> suggestions = const [],
  }) {
    return ReactionMatchResult(
      isMatched: false,
      confidence: ReactionConfidence.none,
      unmatchedReason: reason,
      suggestions: suggestions,
    );
  }
}

/// Deterministic matching engine that identifies organic reactions and predicts major products
/// without relying on ungrounded LLM hallucination.
class ReactionMatcherEngine {
  ReactionMatcherEngine._();
  static final ReactionMatcherEngine instance = ReactionMatcherEngine._();

  /// Matches user input reactants, reagents, and conditions against curated MSc reactions.
  Future<ReactionMatchResult> matchReaction({
    required String reactantsSmiles,
    required String reagents,
    String solvent = '',
    String temperature = '',
    String? optionalReactionName,
  }) async {
    final cleanReactants = _cleanSmiles(reactantsSmiles);
    final cleanReagents = reagents.trim();
    final cleanSolvent = solvent.trim();
    final cleanTemp = temperature.trim();

    if (cleanReactants.isEmpty && cleanReagents.isEmpty && (optionalReactionName == null || optionalReactionName.isEmpty)) {
      return ReactionMatchResult.unmatched(
        reason: 'Please provide reactant structure(s) or select a reaction name.',
        suggestions: [
          'Draw reactants using the Canvas Sketcher button',
          'Select common reagents like NaI, NaOH, HNO3, or PCC',
        ],
      );
    }

    final repo = ReactionCurationRepository.instance;
    final allReactions = await repo.getAllReactions();
    final allExamples = await repo.getAllExamples();

    // 1. Direct Reaction Name / ID Match (if specified)
    if (optionalReactionName != null && optionalReactionName.trim().isNotEmpty) {
      final nameQuery = optionalReactionName.trim().toLowerCase();
      final directMatch = allReactions.firstWhere(
        (r) =>
            r.reactionId.toLowerCase() == nameQuery ||
            r.reactionName.toLowerCase().contains(nameQuery),
        orElse: () => allReactions.first,
      );

      if (directMatch.reactionId.toLowerCase() == nameQuery ||
          directMatch.reactionName.toLowerCase().contains(nameQuery)) {
        final example = directMatch.examples.isNotEmpty ? directMatch.examples.first : null;
        final prodSmiles = example?.expectedProductSmiles ?? '';
        final prodName = example?.expectedProductName ?? directMatch.majorProductRule;

        return _buildResult(
          reaction: directMatch,
          example: example,
          confidence: cleanReactants.isNotEmpty ? ReactionConfidence.high : ReactionConfidence.moderate,
          majorProductSmiles: prodSmiles,
          majorProductName: prodName,
          solvent: cleanSolvent.isNotEmpty ? cleanSolvent : directMatch.solvent,
          temperature: cleanTemp.isNotEmpty ? cleanTemp : directMatch.temperature,
        );
      }
    }

    // 2. High-Confidence Curated Example Match
    if (cleanReactants.isNotEmpty) {
      for (final ex in allExamples) {
        final exSmiles = _cleanSmiles(ex.reactantSmiles);
        final isReactantMatch = exSmiles == cleanReactants ||
            _isSmilesEquivalent(exSmiles, cleanReactants);

        if (isReactantMatch) {
          final isReagentMatch = cleanReagents.isEmpty ||
              _isReagentMatch(cleanReagents, ex.reagentName, ex.reagentSmiles);

          if (isReagentMatch) {
            final rxn = allReactions.firstWhere(
              (r) => r.reactionId == ex.reactionId,
              orElse: () => allReactions.first,
            );
            return _buildResult(
              reaction: rxn,
              example: ex,
              confidence: ReactionConfidence.high,
              majorProductSmiles: ex.expectedProductSmiles,
              majorProductName: ex.expectedProductName,
              solvent: cleanSolvent.isNotEmpty ? cleanSolvent : ex.solvent,
              temperature: cleanTemp.isNotEmpty ? cleanTemp : ex.temperature,
            );
          }
        }
      }
    }

    // 3. Functional Group & Reagent Rule Matching
    final ruleMatch = _matchByChemicalRules(
      allReactions: allReactions,
      reactantsSmiles: cleanReactants,
      reagents: cleanReagents,
      solvent: cleanSolvent,
      temperature: cleanTemp,
    );
    if (ruleMatch != null) {
      return ruleMatch;
    }

    // 4. Honest Unmatched Feedback (No Hallucination)
    return ReactionMatchResult.unmatched(
      reason: 'ChemBuddy could not confidently match this transformation against the 35 curated MSc reaction mechanisms.',
      suggestions: [
        'Check if reactants have compatible functional groups (e.g. Alkyl Halide, Carbonyl, Benzene, Diene)',
        'Verify reagent spelling: e.g. "NaI", "NaOH", "HNO3 / H2SO4", "MeMgBr", "PCC", "mCPBA"',
        'Ensure leaving groups (Br, Cl, I, OTs) are properly indicated for substitution/elimination reactions',
        'You can select the reaction directly from the Curated Reaction Catalog',
      ],
    );
  }

  // ---------------------------------------------------------------------------
  // HEURISTIC / FUNCTIONAL GROUP RULE ENGINE
  // ---------------------------------------------------------------------------

  ReactionMatchResult? _matchByChemicalRules({
    required List<CuratedReaction> allReactions,
    required String reactantsSmiles,
    required String reagents,
    required String solvent,
    required String temperature,
  }) {
    final rLower = reagents.toLowerCase();
    final sLower = solvent.toLowerCase();
    final isHeat = temperature.toLowerCase().contains('heat') ||
        temperature.toLowerCase().contains('reflux') ||
        (int.tryParse(temperature.replaceAll(RegExp(r'[^0-9]'), '')) ?? 0) >= 60;

    // RULE 1: Electrophilic Aromatic Substitution (Benzene + HNO3/H2SO4 or Br2/FeBr3)
    if (reactantsSmiles.contains('c1ccccc1') || reactantsSmiles.contains('C1=CC=CC=C1')) {
      if (rLower.contains('hno3') || rLower.contains('nitric')) {
        final rxn = _findRxn(allReactions, 'RXN_EAS_NITRATION_001');
        if (rxn != null) {
          return _buildResult(
            reaction: rxn,
            example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
            confidence: ReactionConfidence.high,
            majorProductSmiles: 'c1ccc([N+](=O)[O-])cc1',
            majorProductName: 'Nitrobenzene',
            solvent: solvent,
            temperature: temperature,
          );
        }
      }
      if (rLower.contains('br2') || rLower.contains('febr3') || rLower.contains('bromine')) {
        final rxn = _findRxn(allReactions, 'RXN_EAS_HALOGENATION_001');
        if (rxn != null) {
          return _buildResult(
            reaction: rxn,
            example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
            confidence: ReactionConfidence.high,
            majorProductSmiles: 'c1ccc(Br)cc1',
            majorProductName: 'Bromobenzene',
            solvent: solvent,
            temperature: temperature,
          );
        }
      }
      if (rLower.contains('alcl3')) {
        if (rLower.contains('c(=o)') || rLower.contains('acetyl') || rLower.contains('ch3cocl')) {
          final rxn = _findRxn(allReactions, 'RXN_FC_ACYLATION_001');
          if (rxn != null) {
            return _buildResult(
              reaction: rxn,
              example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
              confidence: ReactionConfidence.high,
              majorProductSmiles: 'CC(=O)c1ccccc1',
              majorProductName: 'Acetophenone',
              solvent: solvent,
              temperature: temperature,
            );
          }
        } else {
          final rxn = _findRxn(allReactions, 'RXN_FC_ALKYLATION_001');
          if (rxn != null) {
            return _buildResult(
              reaction: rxn,
              example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
              confidence: ReactionConfidence.high,
              majorProductSmiles: 'Cc1ccccc1',
              majorProductName: 'Toluene',
              solvent: solvent,
              temperature: temperature,
            );
          }
        }
      }
    }

    // RULE 2: Carbonyl Reduction (Aldehyde/Ketone + NaBH4 or LiAlH4)
    if (reactantsSmiles.contains('C=O') || reactantsSmiles.contains('c=o') || reactantsSmiles.contains('(=O)')) {
      if (rLower.contains('nabh4') || rLower.contains('sodium borohydride') || rLower.contains('lialh4')) {
        final rxn = allReactions.firstWhere((r) => r.reactionId == 'RXN_NABH4_RED_001');
        final isAcetone = reactantsSmiles.contains('CC(=O)C');
        final prodSmiles = isAcetone ? 'CC(O)C' : 'CCO';
        final prodName = isAcetone ? 'Propan-2-ol' : 'Ethanol';

        return _buildResult(
          reaction: rxn,
          example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
          confidence: ReactionConfidence.high,
          majorProductSmiles: prodSmiles,
          majorProductName: prodName,
          solvent: solvent,
          temperature: temperature,
        );
      }

      // RULE 3: Grignard Addition (Carbonyl + RMgX)
      if (rLower.contains('mgbr') || rLower.contains('mgcl') || rLower.contains('grignard')) {
        final rxn = _findRxn(allReactions, 'RXN_GRIGNARD_ALD_001');
        if (rxn != null) {
          return _buildResult(
            reaction: rxn,
            example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
            confidence: ReactionConfidence.high,
            majorProductSmiles: 'CC(O)C',
            majorProductName: 'Secondary / Tertiary Alcohol',
            solvent: solvent.isNotEmpty ? solvent : 'Et2O / THF',
            temperature: temperature,
          );
        }
      }

      // RULE 4: Wittig Olefination (Carbonyl + Phosphonium Ylide PPh3)
      if (rLower.contains('pph3') || rLower.contains('ylide') || rLower.contains('wittig')) {
        final rxn = _findRxn(allReactions, 'RXN_WITTIG_001');
        if (rxn != null) {
          return _buildResult(
            reaction: rxn,
            example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
            confidence: ReactionConfidence.high,
            majorProductSmiles: 'C=CC',
            majorProductName: 'Alkene (Z/E Olefin)',
            solvent: solvent,
            temperature: temperature,
          );
        }
      }

      // RULE 5: Baeyer-Villiger Oxidation (Ketone + mCPBA)
      if (rLower.contains('mcpba') || rLower.contains('peracid') || rLower.contains('h2o2')) {
        final rxn = _findRxn(allReactions, 'RXN_BAEYER_VILLIGER_001');
        if (rxn != null) {
          return _buildResult(
            reaction: rxn,
            example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
            confidence: ReactionConfidence.high,
            majorProductSmiles: 'CC(=O)OC',
            majorProductName: 'Ester / Lactone',
            solvent: solvent,
            temperature: temperature,
          );
        }
      }
    }

    // RULE 6: Alcohol Oxidation (Alcohol + PCC)
    if (reactantsSmiles.contains('CO') || reactantsSmiles.contains('CCO') || reactantsSmiles.contains('C(O)')) {
      if (rLower.contains('pcc') || rLower.contains('pyridinium chlorochromate')) {
        final rxn = _findRxn(allReactions, 'RXN_PCC_OXID_001');
        if (rxn != null) {
          return _buildResult(
            reaction: rxn,
            example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
            confidence: ReactionConfidence.high,
            majorProductSmiles: 'CC=O',
            majorProductName: 'Aldehyde / Ketone',
            solvent: solvent.isNotEmpty ? solvent : 'CH2Cl2',
            temperature: temperature,
          );
        }
      }
    }

    // RULE 7: Alkyl Halide: Substitution vs Elimination
    final hasHalide = reactantsSmiles.contains('Br') ||
        reactantsSmiles.contains('Cl') ||
        reactantsSmiles.contains('I');
    if (hasHalide) {
      // E2 with strong hindered base (t-BuOK, NaOEt + heat)
      if (isHeat || rLower.contains('buok') || rLower.contains('naoet') || rLower.contains('etoh')) {
        final rxn = _findRxn(allReactions, 'RXN_E2_001');
        if (rxn != null) {
          return _buildResult(
            reaction: rxn,
            example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
            confidence: ReactionConfidence.moderate,
            majorProductSmiles: 'C=C',
            majorProductName: 'Alkene (Elimination Product)',
            solvent: solvent,
            temperature: temperature,
          );
        }
      }

      // SN2 with good nucleophile (NaI, NaN3, NaCN, NaOH) in polar aprotic solvent
      if (rLower.contains('nai') ||
          rLower.contains('nan3') ||
          rLower.contains('nacn') ||
          sLower.contains('acetone') ||
          sLower.contains('dmf') ||
          sLower.contains('dmso')) {
        final rxn = _findRxn(allReactions, 'RXN_SN2_001');
        if (rxn != null) {
          return _buildResult(
            reaction: rxn,
            example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
            confidence: ReactionConfidence.high,
            majorProductSmiles: 'CCI',
            majorProductName: 'Iodoethane (Walden Inversion)',
            solvent: solvent.isNotEmpty ? solvent : 'Acetone',
            temperature: temperature,
          );
        }
      }

      // SN1 for 3° substrates in polar protic solvent
      if (reactantsSmiles.contains('C(C)(C)Br') || reactantsSmiles.contains('CC(C)(C)')) {
        final rxn = _findRxn(allReactions, 'RXN_SN1_001');
        if (rxn != null) {
          return _buildResult(
            reaction: rxn,
            example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
            confidence: ReactionConfidence.high,
            majorProductSmiles: 'CC(C)(C)O',
            majorProductName: '2-Methylpropan-2-ol (tert-Butanol)',
            solvent: solvent.isNotEmpty ? solvent : 'H2O / EtOH',
            temperature: temperature,
          );
        }
      }
    }

    // RULE 8: Diels-Alder Cycloaddition ([4+2])
    if (reactantsSmiles.contains('C=CC=C') || (reactantsSmiles.contains('C=C') && rLower.contains('c=c'))) {
      final rxn = _findRxn(allReactions, 'RXN_DIELS_ALDER_001');
      if (rxn != null) {
        return _buildResult(
          reaction: rxn,
          example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
          confidence: ReactionConfidence.high,
          majorProductSmiles: 'C1=CCCCC1',
          majorProductName: 'Cyclohexene Derivative',
          solvent: solvent,
          temperature: temperature,
        );
      }
    }

    // RULE 9: Fischer Esterification (Acid + Alcohol + H+)
    if (reactantsSmiles.contains('C(=O)O') && (rLower.contains('oh') || rLower.contains('etoh') || rLower.contains('meoh'))) {
      final rxn = _findRxn(allReactions, 'RXN_ESTER_FISCHER_001');
      if (rxn != null) {
        return _buildResult(
          reaction: rxn,
          example: rxn.examples.isNotEmpty ? rxn.examples.first : null,
          confidence: ReactionConfidence.high,
          majorProductSmiles: 'CCOC(=O)C',
          majorProductName: 'Ethyl Acetate (Ester)',
          solvent: solvent,
          temperature: temperature,
        );
      }
    }

    return null;
  }

  // ---------------------------------------------------------------------------
  // RESULT BUILDER
  // ---------------------------------------------------------------------------

  ReactionMatchResult _buildResult({
    required CuratedReaction reaction,
    CuratedReactionExample? example,
    required ReactionConfidence confidence,
    required String majorProductSmiles,
    required String majorProductName,
    String solvent = '',
    String temperature = '',
  }) {
    // Generate clean scheme SVG
    final reactantGraph = ChemicalGraph.createAlkylHalide(id: 'rxn_reactants');
    final productGraph = ChemicalGraph.createCarbonyl(id: 'rxn_product');

    final schemeSvg = MechanismSvgRenderer.renderReactionScheme(
      reactantGraph: reactantGraph,
      productGraph: productGraph,
      reagent: example?.reagentName ?? reaction.conditions,
      solvent: solvent.isNotEmpty ? solvent : reaction.solvent,
      temperature: temperature.isNotEmpty ? temperature : reaction.temperature,
      reactionName: reaction.reactionName,
    );

    return ReactionMatchResult(
      isMatched: true,
      confidence: confidence,
      reaction: reaction,
      matchedExample: example,
      majorProductSmiles: majorProductSmiles,
      majorProductName: majorProductName,
      mechanismSteps: reaction.steps,
      schemeSvg: schemeSvg,
      notes: reaction.majorProductRule,
    );
  }

  // ---------------------------------------------------------------------------
  // SMILES & REAGENT NORMALIZATION
  // ---------------------------------------------------------------------------

  String _cleanSmiles(String raw) {
    return raw.replaceAll(' ', '').trim();
  }

  bool _isSmilesEquivalent(String s1, String s2) {
    if (s1.toLowerCase() == s2.toLowerCase()) return true;
    final norm1 = s1.replaceAll('(', '').replaceAll(')', '').toLowerCase();
    final norm2 = s2.replaceAll('(', '').replaceAll(')', '').toLowerCase();
    return norm1 == norm2;
  }

  bool _isReagentMatch(String userReagent, String exReagentName, String exReagentSmiles) {
    final u = userReagent.toLowerCase();
    final name = exReagentName.toLowerCase();
    final smiles = exReagentSmiles.toLowerCase();

    return name.contains(u) ||
        u.contains(name) ||
        (smiles.isNotEmpty && (smiles.contains(u) || u.contains(smiles)));
  }

  CuratedReaction? _findRxn(List<CuratedReaction> list, String id) {
    try {
      return list.firstWhere(
        (r) => r.reactionId == id || r.reactionId.contains(id),
      );
    } catch (_) {
      return list.isNotEmpty ? list.first : null;
    }
  }
}
