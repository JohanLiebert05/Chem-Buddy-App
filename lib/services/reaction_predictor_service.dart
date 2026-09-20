import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../core/chemistry/smiles_svg_generator.dart';
import '../data/remote/supabase_service.dart';
import '../data/services/gemini_orchestrator.dart';
import '../data/services/reaction_matcher_engine.dart';

/// Models for postgraduate MSc-level organic synthesis prediction
class OrganicSynthesisPrediction {
  final bool success;
  final String reactionName;
  final String reactionClass;
  final List<String> reactantsSmiles;
  final String reagents;
  final PredictedProduct? majorProduct;
  final List<PredictedMechanismStep> mechanismSteps;
  final PredictedPedagogy? pedagogy;
  final String? error;
  final bool isCached;
  final int? keyIndexUsed;
  final String? model;

  const OrganicSynthesisPrediction({
    required this.success,
    this.reactionName = 'Organic Reaction',
    this.reactionClass = '',
    this.reactantsSmiles = const [],
    this.reagents = '',
    this.majorProduct,
    this.mechanismSteps = const [],
    this.pedagogy,
    this.error,
    this.isCached = false,
    this.keyIndexUsed,
    this.model,
  });

  factory OrganicSynthesisPrediction.failure(String error) {
    return OrganicSynthesisPrediction(
      success: false,
      error: error,
    );
  }

  factory OrganicSynthesisPrediction.fromJson(
    Map<String, dynamic> json, {
    int? keyIndexUsed,
    String? model,
    bool isCached = false,
  }) {
    final majorProductMap = json['major_product'] as Map<String, dynamic>? ?? {};
    final stepsList = json['mechanism_steps'] as List<dynamic>? ?? [];
    final pedagogyMap = json['pedagogy'] as Map<String, dynamic>? ?? {};

    final reactantsRaw = json['reactants_smiles'];
    List<String> reactants = [];
    if (reactantsRaw is List) {
      reactants = reactantsRaw.map((e) => e.toString()).toList();
    } else if (reactantsRaw is String && reactantsRaw.isNotEmpty) {
      reactants = [reactantsRaw];
    }

    return OrganicSynthesisPrediction(
      success: true,
      reactionName: json['reaction_name'] as String? ?? 'Organic Transformation',
      reactionClass: json['reaction_class'] as String? ?? '',
      reactantsSmiles: reactants,
      reagents: json['reagents'] as String? ?? '',
      majorProduct: PredictedProduct.fromJson(majorProductMap),
      mechanismSteps: stepsList
          .map((s) => PredictedMechanismStep.fromJson(s as Map<String, dynamic>))
          .toList(),
      pedagogy: PredictedPedagogy.fromJson(pedagogyMap),
      keyIndexUsed: keyIndexUsed,
      model: model,
      isCached: isCached,
    );
  }
}

class PredictedProduct {
  final String name;
  final String smiles;
  final String formula;
  final String stereochemistry;
  final String svgData;

  const PredictedProduct({
    required this.name,
    required this.smiles,
    this.formula = '',
    this.stereochemistry = '',
    this.svgData = '',
  });

  factory PredictedProduct.fromJson(Map<String, dynamic> json) {
    return PredictedProduct(
      name: json['name'] as String? ?? 'Major Product',
      smiles: json['smiles'] as String? ?? '',
      formula: json['formula'] as String? ?? '',
      stereochemistry: json['stereochemistry'] as String? ?? '',
      svgData: json['svg_data'] as String? ?? '',
    );
  }

  PredictedProduct copyWith({String? svgData}) {
    return PredictedProduct(
      name: name,
      smiles: smiles,
      formula: formula,
      stereochemistry: stereochemistry,
      svgData: svgData ?? this.svgData,
    );
  }
}

class PredictedMechanismStep {
  final int stepNumber;
  final String stepTitle;
  final String intermediateSmiles;
  final String description;
  final String electronPushing;
  final String svgData;

  const PredictedMechanismStep({
    required this.stepNumber,
    required this.stepTitle,
    this.intermediateSmiles = '',
    required this.description,
    this.electronPushing = '',
    this.svgData = '',
  });

  factory PredictedMechanismStep.fromJson(Map<String, dynamic> json) {
    return PredictedMechanismStep(
      stepNumber: (json['step_number'] as num?)?.toInt() ?? 1,
      stepTitle: json['step_title'] as String? ?? 'Mechanism Step',
      intermediateSmiles: json['intermediate_smiles'] as String? ?? '',
      description: json['description'] as String? ?? '',
      electronPushing: json['electron_pushing'] as String? ?? '',
      svgData: json['svg_data'] as String? ?? '',
    );
  }

  PredictedMechanismStep copyWith({String? svgData}) {
    return PredictedMechanismStep(
      stepNumber: stepNumber,
      stepTitle: stepTitle,
      intermediateSmiles: intermediateSmiles,
      description: description,
      electronPushing: electronPushing,
      svgData: svgData ?? this.svgData,
    );
  }
}

class PredictedPedagogy {
  final String drivingForce;
  final String regioselectivityRule;
  final String vivaQuestion;
  final String vivaAnswer;

  const PredictedPedagogy({
    this.drivingForce = '',
    this.regioselectivityRule = '',
    this.vivaQuestion = '',
    this.vivaAnswer = '',
  });

  factory PredictedPedagogy.fromJson(Map<String, dynamic> json) {
    return PredictedPedagogy(
      drivingForce: json['driving_force'] as String? ?? '',
      regioselectivityRule: json['regioselectivity_rule'] as String? ?? '',
      vivaQuestion: json['viva_question'] as String? ?? '',
      vivaAnswer: json['viva_answer'] as String? ?? '',
    );
  }
}

/// Result of AI-driven forward chemical reaction product prediction.
class ReactionPredictionResult {
  final bool success;
  final String productSmiles;
  final String svgData;
  final String? error;
  final bool isCached;
  final int? keyIndexUsed;
  final String? model;

  const ReactionPredictionResult({
    required this.success,
    required this.productSmiles,
    required this.svgData,
    this.error,
    this.isCached = false,
    this.keyIndexUsed,
    this.model,
  });

  factory ReactionPredictionResult.failure(String error) {
    return ReactionPredictionResult(
      success: false,
      productSmiles: '',
      svgData: '',
      error: error,
    );
  }
}

/// Service that predicts major forward reaction products using 4-key Gemini load-balancing
/// and renders 2D molecule SVGs using the NIH Cactus Cheminformatics API.
class ReactionPredictorService {
  ReactionPredictorService._();
  static final ReactionPredictorService instance = ReactionPredictorService._();

  final Map<String, ReactionPredictionResult> _memoryCache = {};
  final Map<String, OrganicSynthesisPrediction> _synthesisCache = {};

  static const String masterSynthesisSystemInstruction = '''You are an expert postgraduate MSc-level organic synthesis engine.

Analyze the given reactant(s) and reaction conditions provided in the user prompt (or extracted from the image).
Search standard organic chemistry literature, named reaction compendiums, and synthesis databases to determine the authentic major reaction pathway.

STRICT INSTRUCTIONS:
1. Do not hallucinate mechanisms or force transformations into incorrect templates.
2. If only reactants are provided without reagents, predict the most thermodynamically and kinetically favored intrinsic reaction (e.g., self-condensation, tautomerization, pericyclic rearrangement) or state the required standard reagent in "reaction_notes".
3. Return ONLY a valid JSON object conforming exactly to the schema below. Never add conversational intros, explanations outside the JSON, or markdown code blocks (e.g., do not wrap in ```json).
4. All SMILES strings MUST be canonical, valid, and chemically accurate.
5. In each mechanism step, explicitly specify the nucleophilic source and electrophilic target for curved electron-pushing arrows.

JSON SCHEMA:
{
  "reaction_name": "Standard IUPAC / Named Reaction",
  "reaction_class": "e.g., Electrophilic Aromatic Substitution, Pericyclic, Aldol Condensation",
  "reactants_smiles": ["canonical_smiles_1", "canonical_smiles_2"],
  "reagents": "Specific reagent/catalyst, solvent, temperature",
  "major_product": {
    "name": "IUPAC or standard chemical name",
    "smiles": "canonical_product_smiles",
    "formula": "e.g., C8H7NO3",
    "stereochemistry": "e.g., syn-addition, anti-elimination, racemic, retention"
  },
  "mechanism_steps": [
    {
      "step_number": 1,
      "step_title": "Short title (e.g., Generation of Electrophile)",
      "intermediate_smiles": "canonical_smiles_or_empty_if_transient",
      "description": "Clear step explanation with MSc-level rigor",
      "electron_pushing": "Curved arrow description: e.g., Lone pair on O attacks carbonyl carbon; pi bond breaks to oxygen"
    }
  ],
  "pedagogy": {
    "driving_force": "Thermodynamic / kinetic rationale (e.g., Restoration of aromaticity, resonance stabilization)",
    "regioselectivity_rule": "e.g., Markovnikov, Zaitsev, Ortho/Para orientation via +M resonance",
    "viva_question": "One advanced oral viva examination question testing mechanistic nuance",
    "viva_answer": "Concise postgraduate model answer"
  }
}''';

  /// Predicts the major organic product and complete step-by-step mechanism in valid JSON.
  Future<OrganicSynthesisPrediction> predictFullReaction({
    required String reactantsSmiles,
    String reagents = '',
    String solvent = '',
    String temperature = '',
  }) async {
    final cleanReactants = reactantsSmiles.trim();
    if (cleanReactants.isEmpty) {
      return OrganicSynthesisPrediction.failure('Please draw or provide reactant structure(s).');
    }

    final cacheKey = '$cleanReactants|$reagents|$solvent|$temperature'.toLowerCase();
    if (_synthesisCache.containsKey(cacheKey)) {
      return _synthesisCache[cacheKey]!;
    }

    final conditionsList = <String>[];
    if (reagents.trim().isNotEmpty) conditionsList.add('Reagent: ${reagents.trim()}');
    if (solvent.trim().isNotEmpty) conditionsList.add('Solvent: ${solvent.trim()}');
    if (temperature.trim().isNotEmpty) conditionsList.add('Temperature: ${temperature.trim()}');
    final conditionsStr = conditionsList.isNotEmpty ? conditionsList.join(', ') : 'Infer standard conditions';

    // 1. Primary: Invoke Supabase Edge Function `predict-reaction`
    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        final response = await client.functions.invoke(
          'predict-reaction',
          body: {
            'reactants_smiles': cleanReactants,
            'reagents': reagents.trim(),
            'solvent': solvent.trim(),
            'temperature': temperature.trim(),
            'full_mechanism': true,
          },
        );

        if (response.status == 200 && response.data != null) {
          final dynamic rawData = response.data;
          final Map<dynamic, dynamic> data =
              rawData is Map ? rawData : jsonDecode(rawData.toString()) as Map<dynamic, dynamic>;

          if (data['success'] == true && data['reaction'] != null) {
            final reactionMap = Map<String, dynamic>.from(data['reaction'] as Map);
            var prediction = OrganicSynthesisPrediction.fromJson(
              reactionMap,
              keyIndexUsed: (data['key_index_used'] as num?)?.toInt(),
              model: data['model'] as String?,
            );

            // Ensure SVGs are populated
            prediction = await _hydrateSvgs(prediction);
            _synthesisCache[cacheKey] = prediction;
            return prediction;
          }
        }
      }
    } catch (e) {
      debugPrint('[ReactionPredictorService] Edge function full reaction exception: $e');
    }

    // 2. Resilient Client-Side Fallback: 4-Key Gemini Orchestrator
    try {
      final userPrompt = '''User Reaction Input:
- Reactants / Structure: $cleanReactants
- Reagents / Solvent / Conditions: $conditionsStr

Identify the major organic product and generate the complete step-by-step reaction mechanism in valid JSON.''';

      final aiRes = await GeminiOrchestrator.instance.ask(
        prompt: userPrompt,
        category: 'reaction_synthesis',
        systemInstruction: masterSynthesisSystemInstruction,
        temperature: 0.1,
      );

      final parsed = _parseJsonMap(aiRes.text);
      if (parsed != null && parsed.isNotEmpty) {
        var prediction = OrganicSynthesisPrediction.fromJson(
          parsed,
          keyIndexUsed: aiRes.keyIndexUsed,
          model: aiRes.model,
        );

        prediction = await _hydrateSvgs(prediction);
        _synthesisCache[cacheKey] = prediction;
        return prediction;
      }
    } catch (e) {
      debugPrint('[ReactionPredictorService] Fallback synthesis orchestrator error: $e');
    }

    return OrganicSynthesisPrediction.failure(
      'Unable to predict reaction mechanism across all available synthesis engines. Please check your internet connection or verify the input SMILES.',
    );
  }

  /// Hydrates vector SVGs for major product and intermediate structures
  Future<OrganicSynthesisPrediction> _hydrateSvgs(OrganicSynthesisPrediction pred) async {
    PredictedProduct? prod = pred.majorProduct;
    if (prod != null && (prod.svgData.isEmpty || !prod.svgData.contains('<svg'))) {
      var svg = await fetchCactusSvg(prod.smiles);
      if (svg.isEmpty) svg = SmilesSvgGenerator.generateSvg(prod.smiles, title: prod.name);
      prod = prod.copyWith(svgData: svg);
    }

    final updatedSteps = <PredictedMechanismStep>[];
    for (final step in pred.mechanismSteps) {
      if (step.intermediateSmiles.isNotEmpty && (step.svgData.isEmpty || !step.svgData.contains('<svg'))) {
        var svg = await fetchCactusSvg(step.intermediateSmiles);
        if (svg.isEmpty) svg = SmilesSvgGenerator.generateSvg(step.intermediateSmiles, title: step.stepTitle);
        updatedSteps.add(step.copyWith(svgData: svg));
      } else {
        updatedSteps.add(step);
      }
    }

    return OrganicSynthesisPrediction(
      success: pred.success,
      reactionName: pred.reactionName,
      reactionClass: pred.reactionClass,
      reactantsSmiles: pred.reactantsSmiles,
      reagents: pred.reagents,
      majorProduct: prod,
      mechanismSteps: updatedSteps,
      pedagogy: pred.pedagogy,
      error: pred.error,
      isCached: pred.isCached,
      keyIndexUsed: pred.keyIndexUsed,
      model: pred.model,
    );
  }

  static Map<String, dynamic>? _parseJsonMap(String raw) {
    try {
      var clean = raw.trim();
      clean = clean.replaceAll(RegExp(r'```(?:json)?\n?([\s\S]*?)```', caseSensitive: false), r'$1').trim();
      final firstBrace = clean.indexOf('{');
      final lastBrace = clean.lastIndexOf('}');
      if (firstBrace != -1 && lastBrace != -1 && lastBrace > firstBrace) {
        clean = clean.substring(firstBrace, lastBrace + 1);
      }
      return jsonDecode(clean) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[ReactionPredictorService] JSON parse error: $e');
      return null;
    }
  }

  /// Predicts the single major organic product for the given reactant SMILES (supports dot-separated reactants).
  Future<ReactionPredictionResult> predictMajorProduct(String reactantsSmiles) async {
    final cleanReactants = reactantsSmiles.trim();
    if (cleanReactants.isEmpty) {
      return ReactionPredictionResult.failure('Please draw or provide reactant structure(s).');
    }

    final cacheKey = cleanReactants.toLowerCase();
    if (_memoryCache.containsKey(cacheKey)) {
      final cached = _memoryCache[cacheKey]!;
      return ReactionPredictionResult(
        success: cached.success,
        productSmiles: cached.productSmiles,
        svgData: cached.svgData,
        isCached: true,
        keyIndexUsed: cached.keyIndexUsed,
        model: cached.model,
      );
    }

    // 1. Instant Offline Rule Engine (0 ms resolution for 45+ standard MSc organic transformations)
    final offlineRule = _tryOfflineReactionRule(cleanReactants);
    if (offlineRule != null) {
      _memoryCache[cacheKey] = offlineRule;
      // Background Cactus SVG fetch for high-fidelity vector enhancement without blocking
      fetchCactusSvg(offlineRule.productSmiles).then((svg) {
        if (svg.isNotEmpty && svg.contains('<svg')) {
          _memoryCache[cacheKey] = ReactionPredictionResult(
            success: true,
            productSmiles: offlineRule.productSmiles,
            svgData: svg,
            isCached: true,
          );
        }
      }).catchError((_) {});
      return offlineRule;
    }

    // 2. High-Confidence Curated MSc Reaction Database Match
    try {
      final match = await ReactionMatcherEngine.instance.matchReaction(
        reactantsSmiles: cleanReactants,
        reagents: '',
      );
      if (match.isMatched && match.majorProductSmiles.isNotEmpty) {
        final prodSmiles = match.majorProductSmiles;
        final svg = match.schemeSvg.isNotEmpty && match.schemeSvg.contains('<svg')
            ? match.schemeSvg
            : SmilesSvgGenerator.generateSvg(
                prodSmiles,
                title: match.majorProductName.isNotEmpty ? match.majorProductName : 'PREDICTED PRODUCT',
              );
        final result = ReactionPredictionResult(
          success: true,
          productSmiles: prodSmiles,
          svgData: svg,
          isCached: true,
        );
        _memoryCache[cacheKey] = result;
        return result;
      }
    } catch (e) {
      debugPrint('[ReactionPredictorService] ReactionMatcherEngine check error: $e');
    }

    // 3. Ultra-Fast Client-Side 4-Key Gemini Orchestrator (Direct, with 5.5s timeout)
    try {
      const systemInstruction = '''You are an authoritative postgraduate MSc-level organic synthesis engine.
Your task is to predict the single MAJOR organic reaction product given the reactant SMILES and optional reaction conditions.

STRICT INSTRUCTIONS:
1. Return ONLY the valid canonical SMILES string of the single major organic product.
2. Do NOT include markdown formatting, code blocks (e.g. no ```), labels, or explanations.
3. Obey fundamental organic chemistry principles:
   - Valency: Carbon must have 4 bonds, Nitrogen 3 (or 4 with [N+]), Oxygen 2 (or 1 with [O-]), Halogens 1.
   - Aromaticity: Lowercase letters (c, n, o, s) for aromatic rings (e.g., benzene is c1ccccc1).
   - Regiochemistry: Markovnikov / Zaitsev rules, ortho/para directing (+M/-I) vs meta directing (-M/-I) on benzene.
   - Stereochemistry: syn/anti addition or retention/inversion where applicable.
4. Examples:
   - Reactants: c1ccccc1.CC(=O)Cl -> CC(=O)c1ccccc1
   - Reactants: c1ccccc1.BrBr -> c1ccc(cc1)Br
   - Reactants: CC(=O)Oc1ccccc1C(=O)O -> CC(=O)Oc1ccccc1C(=O)O
   - Reactants: C=CC=C.C=C -> C1=CCCCC1
   - Reactants: CC=C.BrBr -> CC(Br)CBr
   - Reactants: c1ccccc1C=O.[CH3-].[Mg+2].[Br-] -> CC(O)c1ccccc1
''';

      final prompt = '''Reactant(s) SMILES: $cleanReactants
Predict the single major organic product under standard reaction conditions.
Return ONLY the canonical product SMILES string:''';

      final aiRes = await GeminiOrchestrator.instance
          .ask(
            prompt: prompt,
            category: 'reaction_prediction',
            systemInstruction: systemInstruction,
            temperature: 0.0,
          )
          .timeout(const Duration(milliseconds: 5500));

      final cleanSmiles = _sanitizeSmiles(aiRes.text);
      if (cleanSmiles.isNotEmpty) {
        final svg = SmilesSvgGenerator.generateSvg(cleanSmiles, title: 'PREDICTED PRODUCT');

        final result = ReactionPredictionResult(
          success: true,
          productSmiles: cleanSmiles,
          svgData: svg,
          keyIndexUsed: aiRes.keyIndexUsed,
          model: aiRes.model,
        );
        _memoryCache[cacheKey] = result;

        // Hydrate with Cactus 2D vector asynchronously in background
        fetchCactusSvg(cleanSmiles).then((cactusSvg) {
          if (cactusSvg.isNotEmpty && cactusSvg.contains('<svg')) {
            _memoryCache[cacheKey] = ReactionPredictionResult(
              success: true,
              productSmiles: cleanSmiles,
              svgData: cactusSvg,
              keyIndexUsed: aiRes.keyIndexUsed,
              model: aiRes.model,
            );
          }
        }).catchError((_) {});

        return result;
      }
    } catch (e) {
      debugPrint('[ReactionPredictorService] Fast Gemini orchestrator error or timeout: $e');
    }

    // 4. Fallback: Edge Function invocation if Gemini was unreachable
    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        final response = await client.functions.invoke(
          'predict-reaction',
          body: {'reactants_smiles': cleanReactants},
        ).timeout(const Duration(seconds: 4));

        if (response.status == 200 && response.data != null) {
          final dynamic rawData = response.data;
          final Map<dynamic, dynamic> data =
              rawData is Map ? rawData : jsonDecode(rawData.toString()) as Map<dynamic, dynamic>;

          if (data['success'] == true) {
            final productSmiles = (data['product_smiles'] as String?)?.trim() ?? '';
            var svgData = (data['svg_data'] as String?)?.trim() ?? '';

            if (productSmiles.isNotEmpty && (svgData.isEmpty || !svgData.contains('<svg'))) {
              svgData = SmilesSvgGenerator.generateSvg(productSmiles, title: 'PREDICTED PRODUCT');
            }

            final result = ReactionPredictionResult(
              success: true,
              productSmiles: productSmiles,
              svgData: svgData,
              keyIndexUsed: (data['key_index_used'] as num?)?.toInt(),
              model: data['model'] as String?,
            );
            _memoryCache[cacheKey] = result;
            return result;
          }
        }
      }
    } catch (e) {
      debugPrint('[ReactionPredictorService] Edge function fallback error: $e');
    }

    return ReactionPredictionResult.failure(
      'Reaction product prediction temporarily unavailable. Please verify your connection or try again.',
    );
  }

  /// Instant offline prediction for common textbook MSc organic reactions (0 ms resolution)
  ReactionPredictionResult? _tryOfflineReactionRule(String reactants) {
    final s = reactants.replaceAll(' ', '');
    final lower = s.toLowerCase();

    ReactionPredictionResult makeResult(String prodSmiles, {String? title}) {
      return ReactionPredictionResult(
        success: true,
        productSmiles: prodSmiles,
        svgData: SmilesSvgGenerator.generateSvg(prodSmiles, title: title ?? 'PREDICTED PRODUCT'),
        isCached: true,
      );
    }

    // 1. Aspirin Synthesis: Salicylic acid + Acetic Anhydride / Acetyl Chloride -> Aspirin
    final hasSalicylic = lower.contains('oc1ccccc1c(=o)o') ||
        lower.contains('c1ccc(c(c1)c(=o)o)o') ||
        lower.contains('o=c(o)c1ccccc1o');
    final hasAcetylatingAgent = lower.contains('cc(=o)oc(=o)c') ||
        lower.contains('cc(=o)cl') ||
        lower.contains('clc(c)=o') ||
        lower.contains('acetic');
    if (hasSalicylic && hasAcetylatingAgent) {
      return makeResult('CC(=O)Oc1ccccc1C(=O)O', title: 'ASPIRIN');
    }
    // Salicylic acid alone
    if (lower == 'oc1ccccc1c(=o)o' || lower == 'c1ccc(c(c1)c(=o)o)o') {
      return makeResult('CC(=O)Oc1ccccc1C(=O)O', title: 'ASPIRIN');
    }

    // 2. Paracetamol Synthesis: 4-Aminophenol + Acetic Anhydride
    final has4Aminophenol = lower.contains('nc1ccc(o)cc1') || lower.contains('oc1ccc(n)cc1');
    if (has4Aminophenol && hasAcetylatingAgent) {
      return makeResult('CC(=O)Nc1ccc(O)cc1', title: 'PARACETAMOL');
    }

    // 3. Esterification: Acetic Acid + Ethanol -> Ethyl Acetate
    if ((lower.contains('cc(=o)o') || lower.contains('cc(o)=o')) && (lower.contains('cco') || lower.contains('occ'))) {
      return makeResult('CCOC(=O)C', title: 'ETHYL ACETATE');
    }

    // 4. Esterification: Acetic Acid + Methanol -> Methyl Acetate
    if ((lower.contains('cc(=o)o') || lower.contains('cc(o)=o')) && (lower.contains('.co') || lower.contains('co.'))) {
      return makeResult('COC(=O)C', title: 'METHYL ACETATE');
    }

    // 5. Benzoic Acid + Methanol -> Methyl Benzoate
    if ((lower.contains('c1ccccc1c(=o)o') || lower.contains('o=c(o)c1ccccc1')) && (lower.contains('.co') || lower.contains('co.'))) {
      return makeResult('COC(=O)c1ccccc1', title: 'METHYL BENZOATE');
    }

    // 6. Benzoic Acid + Ethanol -> Ethyl Benzoate
    if ((lower.contains('c1ccccc1c(=o)o') || lower.contains('o=c(o)c1ccccc1')) && (lower.contains('cco') || lower.contains('occ'))) {
      return makeResult('CCOC(=O)c1ccccc1', title: 'ETHYL BENZOATE');
    }

    // 7. Electrophilic Aromatic Substitution: Benzene
    final isBenzene = lower == 'c1ccccc1' || lower == 'c1=cc=cc=c1';
    if (isBenzene) {
      return makeResult('c1ccc(cc1)[N+](=O)[O-]', title: 'NITROBENZENE');
    }
    if ((lower.contains('c1ccccc1') || lower.contains('c1=cc=cc=c1')) && (lower.contains('br') || lower.contains('brom'))) {
      return makeResult('c1ccc(cc1)Br', title: 'BROMOBENZENE');
    }
    if ((lower.contains('c1ccccc1') || lower.contains('c1=cc=cc=c1')) && (lower.contains('cl2') || lower.contains('cl.cl') || lower.contains('chlor'))) {
      return makeResult('c1ccc(cc1)Cl', title: 'CHLOROBENZENE');
    }
    if ((lower.contains('c1ccccc1') || lower.contains('c1=cc=cc=c1')) && (lower.contains('cc(=o)cl') || lower.contains('clc(c)=o'))) {
      return makeResult('CC(=O)c1ccccc1', title: 'ACETOPHENONE');
    }
    if ((lower.contains('c1ccccc1') || lower.contains('c1=cc=cc=c1')) && (lower.contains('ccl') || lower.contains('clc') || lower.contains('cbr'))) {
      return makeResult('Cc1ccccc1', title: 'TOLUENE');
    }
    if ((lower.contains('c1ccccc1') || lower.contains('c1=cc=cc=c1')) && (lower.contains('s(=o)') || lower.contains('so3') || lower.contains('h2so4'))) {
      return makeResult('c1ccc(cc1)S(=O)(=O)O', title: 'BENZENESULFONIC ACID');
    }

    // 8. Toluene + HNO3 -> 4-Nitrotoluene
    if (lower.contains('cc1ccccc1') && (lower.contains('n') || lower.contains('nitr'))) {
      return makeResult('Cc1ccc([N+](=O)[O-])cc1', title: '4-NITROTOLUENE');
    }

    // 9. Aniline + Acetyl chloride -> Acetanilide
    if (lower.contains('nc1ccccc1') && hasAcetylatingAgent) {
      return makeResult('CC(=O)Nc1ccccc1', title: 'ACETANILIDE');
    }

    // 10. Aniline Diazotization: Aniline + NaNO2/HCl -> Benzenediazonium
    if (lower.contains('nc1ccccc1') && (lower.contains('nano2') || lower.contains('no2') || lower.contains('hcl'))) {
      return makeResult('c1ccccc1[N+]#N', title: 'BENZENEDIAZONIUM');
    }

    // 11. Phenol Bromination: Phenol + Br2 -> 2,4,6-Tribromophenol / 4-Bromophenol
    if (lower.contains('oc1ccccc1') && lower.contains('br')) {
      return makeResult('Oc1c(Br)cc(Br)cc1Br', title: '2,4,6-TRIBROMOPHENOL');
    }

    // 12. Phenol + NaOH + CO2 (Kolbe-Schmitt) -> Salicylic acid
    if (lower.contains('oc1ccccc1') && (lower.contains('co2') || lower.contains('o=c=o') || lower.contains('naoh'))) {
      return makeResult('Oc1ccccc1C(=O)O', title: 'SALICYLIC ACID');
    }

    // 13. Phenol + CHCl3 + KOH (Reimer-Tiemann) -> Salicylaldehyde
    if (lower.contains('oc1ccccc1') && (lower.contains('chcl3') || lower.contains('clc(cl)cl'))) {
      return makeResult('Oc1ccccc1C=O', title: 'SALICYLALDEHYDE');
    }

    // 14. Phenol + MeI (Williamson Ether) -> Anisole
    if (lower.contains('oc1ccccc1') && (lower.contains('.ci') || lower.contains('ic.') || lower.contains('ci.'))) {
      return makeResult('COc1ccccc1', title: 'ANISOLE');
    }

    // 15. Phenol + EtBr / EtI (Williamson Ether) -> Phenetole
    if (lower.contains('oc1ccccc1') && (lower.contains('ccbr') || lower.contains('cci') || lower.contains('brcc'))) {
      return makeResult('CCOc1ccccc1', title: 'PHENETOLE');
    }

    // 16. Benzoic acid + SOCl2 -> Benzoyl chloride
    if ((lower.contains('c1ccccc1c(=o)o') || lower.contains('o=c(o)c1ccccc1')) && (lower.contains('socl2') || lower.contains('os(cl)cl') || lower.contains('pcl5'))) {
      return makeResult('c1ccccc1C(=O)Cl', title: 'BENZOYL CHLORIDE');
    }

    // 17. Aldol Condensation: Acetaldehyde self-condensation -> Crotonaldehyde
    if (lower == 'cc=o' || lower == 'cc=o.cc=o' || lower == 'cc(=o)h') {
      return makeResult('CC=CC=O', title: 'CROTONALDEHYDE');
    }

    // 18. Claisen-Schmidt: Benzaldehyde + Acetone -> Benzylideneacetone
    if ((lower.contains('c1ccccc1c=o') || lower.contains('o=cc1ccccc1')) && (lower.contains('cc(=o)c') || lower.contains('cc(c)=o'))) {
      return makeResult('c1ccccc1C=CC(=O)C', title: 'BENZYLIDENEACETONE');
    }

    // 19. Cannizzaro Reaction: Benzaldehyde + KOH/NaOH -> Benzyl alcohol + Benzoic acid
    if (lower == 'c1ccccc1c=o' || lower == 'o=cc1ccccc1') {
      return makeResult('c1ccccc1CO', title: 'BENZYL ALCOHOL');
    }

    // 20. Benzoin Condensation: Benzaldehyde + KCN -> Benzoin
    if ((lower.contains('c1ccccc1c=o') || lower.contains('o=cc1ccccc1')) && (lower.contains('kcn') || lower.contains('c#n') || lower.contains('cn.'))) {
      return makeResult('c1ccccc1C(=O)C(O)c1ccccc1', title: 'BENZOIN');
    }

    // 21. Carbonyl + Hydroxylamine: Cyclohexanone + NH2OH -> Cyclohexanone oxime
    if ((lower.contains('c1ccccc1=o') || lower.contains('o=c1ccccc1') || lower.contains('c1ccccc1')) && (lower.contains('no') || lower.contains('on') || lower.contains('nh2oh'))) {
      if (lower.contains('c1ccccc1=o') || lower.contains('o=c1ccccc1')) {
        return makeResult('C1CCCCC1=NO', title: 'CYCLOHEXANONE OXIME');
      }
    }

    // 22. Grignard Addition: Acetone + MeMgBr -> tert-Butanol
    if ((lower.contains('cc(=o)c') || lower.contains('cc(c)=o')) && (lower.contains('mg') || lower.contains('me-') || lower.contains('cmg'))) {
      return makeResult('CC(C)(C)O', title: 'tert-BUTANOL');
    }

    // 23. Grignard Addition: Benzaldehyde + MeMgBr -> 1-Phenylethanol
    if ((lower.contains('c1ccccc1c=o') || lower.contains('o=cc1ccccc1')) && (lower.contains('mg') || lower.contains('cmg'))) {
      return makeResult('CC(O)c1ccccc1', title: '1-PHENYLETHANOL');
    }

    // 24. Carbonyl Reduction: Acetophenone + NaBH4 -> 1-Phenylethanol
    if ((lower.contains('cc(=o)c1ccccc1') || lower.contains('c1ccccc1c(=o)c')) && (lower.contains('nabh4') || lower.contains('lialh4') || lower.contains('bh4') || lower.contains('h-'))) {
      return makeResult('CC(O)c1ccccc1', title: '1-PHENYLETHANOL');
    }

    // 25. Carbonyl Reduction: Acetone + NaBH4 -> 2-Propanol
    if ((lower.contains('cc(=o)c') || lower.contains('cc(c)=o')) && (lower.contains('nabh4') || lower.contains('lialh4') || lower.contains('h-'))) {
      return makeResult('CC(O)C', title: '2-PROPANOL');
    }

    // 26. Nitro Reduction: Nitrobenzene + Fe/HCl or Sn/HCl -> Aniline
    if (lower.contains('c1ccc(cc1)[n+](=o)[o-]') && (lower.contains('fe') || lower.contains('sn') || lower.contains('pd') || lower.contains('h2'))) {
      return makeResult('c1ccccc1N', title: 'ANILINE');
    }

    // 27. Alkene Halogenation: Ethene + Br2 -> 1,2-Dibromoethane
    if ((lower == 'c=c' || lower == 'c=c.brbr' || lower.contains('c=c.br')) && lower.contains('br')) {
      return makeResult('BrCCBr', title: '1,2-DIBROMOETHANE');
    }

    // 28. Alkene Halogenation: Cyclohexene + Br2 -> 1,2-Dibromocyclohexane
    if (lower.contains('c1=ccccc1') && lower.contains('br')) {
      return makeResult('BrC1CCCCC1Br', title: '1,2-DIBROMOCYCLOHEXANE');
    }

    // 29. Markovnikov Addition: Propene + HBr -> 2-Bromopropane
    if ((lower.contains('cc=c') || lower.contains('c=cc')) && lower.contains('hbr') && !lower.contains('perox') && !lower.contains('o-o')) {
      return makeResult('CC(Br)C', title: '2-BROMOPROPANE (Markovnikov)');
    }

    // 30. Anti-Markovnikov Addition: Propene + HBr + Peroxide -> 1-Bromopropane
    if ((lower.contains('cc=c') || lower.contains('c=cc')) && lower.contains('hbr') && (lower.contains('perox') || lower.contains('o-o'))) {
      return makeResult('CCCBr', title: '1-BROMOPROPANE (Anti-Markovnikov)');
    }

    // 31. Alkene Hydration: Propene + H2O/H+ -> 2-Propanol
    if ((lower.contains('cc=c') || lower.contains('c=cc')) && (lower.contains('h2o') || lower.contains('oh2') || lower.contains('h+'))) {
      return makeResult('CC(O)C', title: '2-PROPANOL (Markovnikov)');
    }

    // 32. 1-Butene + HBr -> 2-Bromobutane
    if ((lower.contains('ccc=c') || lower.contains('c=ccc')) && lower.contains('br')) {
      return makeResult('CCC(Br)C', title: '2-BROMOBUTANE');
    }

    // 33. Diels-Alder: 1,3-Butadiene + Ethene -> Cyclohexene
    if ((lower.contains('c=cc=c') || lower.contains('c=c-c=c')) && (lower.contains('c=c') && !lower.contains('c=cc=c.c=cc=c'))) {
      return makeResult('C1=CCCCC1', title: 'CYCLOHEXENE (Diels-Alder)');
    }

    // 34. Diels-Alder: Cyclopentadiene + Maleic anhydride
    if (lower.contains('c1=ccc=c1') || (lower.contains('c1=cc=cc1') && lower.contains('o=c1oc(=o)c=c1'))) {
      return makeResult('O=C1OC(=O)C2C1C3CC2C=C3', title: 'NORBORNENE ANHYDRIDE (Diels-Alder)');
    }

    // 35. SN2 Substitution: 1-Bromobutane + NaCN -> Pentanenitrile
    if (lower.contains('ccccbr') && (lower.contains('nacn') || lower.contains('c#n') || lower.contains('kcn'))) {
      return makeResult('CCCCC#N', title: 'PENTANENITRILE');
    }

    // 36. SN2 Substitution: 1-Bromobutane + NaOH -> 1-Butanol
    if (lower.contains('ccccbr') && (lower.contains('naoh') || lower.contains('oh-') || lower.contains('koh'))) {
      return makeResult('CCCCO', title: '1-BUTANOL');
    }

    // 37. Finkelstein: 1-Chloropropane + NaI -> 1-Iodopropane
    if (lower.contains('ccccl') && (lower.contains('nai') || lower.contains('i-') || lower.contains('ki'))) {
      return makeResult('CCCI', title: '1-IODOPROPANE (Finkelstein)');
    }

    // 38. SN1 Solvolysis: tert-Butyl bromide + H2O -> tert-Butanol
    if ((lower.contains('cc(c)(c)br') || lower.contains('brc(c)(c)c')) && (lower.contains('h2o') || lower.contains('oh2'))) {
      return makeResult('CC(C)(C)O', title: 'tert-BUTANOL (SN1)');
    }

    // 39. E2 Elimination: tert-Butyl bromide + strong base -> Isobutylene
    if ((lower.contains('cc(c)(c)br') || lower.contains('brc(c)(c)c')) && (lower.contains('tbuk') || lower.contains('base') || lower.contains('naoet') || lower.contains('koh'))) {
      return makeResult('CC(=C)C', title: 'ISOBUTYLENE (E2)');
    }

    // 40. Alcohol Oxidation: Benzyl alcohol + PCC -> Benzaldehyde
    if (lower.contains('c1ccccc1co') && (lower.contains('pcc') || lower.contains('pdc') || lower.contains('dmp'))) {
      return makeResult('c1ccccc1C=O', title: 'BENZALDEHYDE');
    }

    // 41. Alcohol Oxidation: Benzyl alcohol + KMnO4 -> Benzoic acid
    if (lower.contains('c1ccccc1co') && (lower.contains('kmno4') || lower.contains('cro3') || lower.contains('jones'))) {
      return makeResult('c1ccccc1C(=O)O', title: 'BENZOIC ACID');
    }

    // 42. Secondary Alcohol Oxidation: 2-Propanol + PCC -> Acetone
    if ((lower == 'cc(o)c' || lower == 'oc(c)c') && (lower.contains('pcc') || lower.contains('cro3') || lower.contains('jones') || lower.contains('kmno4'))) {
      return makeResult('CC(=O)C', title: 'ACETONE');
    }

    // 43. Primary Alcohol Oxidation: Ethanol + PCC -> Acetaldehyde
    if (lower == 'cco' && (lower.contains('pcc') || lower.contains('pdc'))) {
      return makeResult('CC=O', title: 'ACETALDEHYDE');
    }

    return null;
  }

  /// Fetches 2D vector SVG directly from NIH Cactus Cheminformatics API
  static Future<String> fetchCactusSvg(String smiles) async {
    try {
      final encoded = Uri.encodeComponent(smiles);
      final uri = Uri.parse('https://cactus.nci.nih.gov/chemical/structure/$encoded/image?format=svg');
      final httpClient = HttpClient()..connectionTimeout = const Duration(seconds: 7);
      final request = await httpClient.getUrl(uri);
      request.headers.set('User-Agent', 'ChemBuddy-MSc/1.0');
      request.headers.set('Accept', 'image/svg+xml,text/xml,*/*');

      final response = await request.close();
      if (response.statusCode == 200) {
        final svgText = await response.transform(utf8.decoder).join();
        if (svgText.contains('<svg') || svgText.contains('xmlns')) {
          return svgText;
        }
      }
    } catch (e) {
      debugPrint('[ReactionPredictorService] Cactus fetch warning: $e');
    }
    return '';
  }

  static String _sanitizeSmiles(String raw) {
    var s = raw.trim();
    // Remove markdown code blocks
    s = s.replaceAll(RegExp(r'```(?:smiles|smi|text)?\n?([\s\S]*?)```', caseSensitive: false), r'$1').trim();
    // Remove label prefixes
    s = s.replaceAll(RegExp(r'^(?:SMILES|Product|Major Product|Result)\s*[:=-]\s*', caseSensitive: false), '').trim();
    final lines = s.split('\n').map((l) => l.trim()).where((l) => l.isNotEmpty && !l.toLowerCase().startsWith('note:')).toList();
    if (lines.isNotEmpty) s = lines.first;
    s = s.replaceAll(RegExp(r'''^["'`]|["'`]$'''), '').trim();
    s = s.replaceAll(RegExp(r'[.;]+$'), '').trim();
    return s;
  }
}
