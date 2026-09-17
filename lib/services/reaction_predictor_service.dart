import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../data/remote/supabase_service.dart';
import '../data/services/gemini_orchestrator.dart';

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

  /// Hydrates vector SVGs from Cactus for major product and intermediate structures
  Future<OrganicSynthesisPrediction> _hydrateSvgs(OrganicSynthesisPrediction pred) async {
    PredictedProduct? prod = pred.majorProduct;
    if (prod != null && (prod.svgData.isEmpty || !prod.svgData.contains('<svg'))) {
      var svg = await fetchCactusSvg(prod.smiles);
      if (svg.isEmpty) svg = _generateFallbackSvg(prod.smiles);
      prod = prod.copyWith(svgData: svg);
    }

    final updatedSteps = <PredictedMechanismStep>[];
    for (final step in pred.mechanismSteps) {
      if (step.intermediateSmiles.isNotEmpty && (step.svgData.isEmpty || !step.svgData.contains('<svg'))) {
        final svg = await fetchCactusSvg(step.intermediateSmiles);
        updatedSteps.add(step.copyWith(svgData: svg.isNotEmpty ? svg : _generateFallbackSvg(step.intermediateSmiles)));
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

    // 1. Instant Offline Rule Engine (0 ms resolution for standard organic transformations)
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

    // 2. Ultra-Fast Client-Side 4-Key Gemini Orchestrator (Direct, with 4.5s timeout)
    try {
      const systemInstruction =
          'You are an expert organic reaction outcome engine. Return ONLY the valid SMILES string of the single major organic product. Do not include markdown blocks, notes, or explanations.';
      final prompt =
          'Reactants: $cleanReactants\nPredict the single major organic product under standard reaction conditions. Return ONLY its SMILES string.';

      final aiRes = await GeminiOrchestrator.instance
          .ask(
            prompt: prompt,
            category: 'reaction_prediction',
            systemInstruction: systemInstruction,
            temperature: 0.0,
          )
          .timeout(const Duration(milliseconds: 4500));

      final cleanSmiles = _sanitizeSmiles(aiRes.text);
      if (cleanSmiles.isNotEmpty) {
        final fallbackSvg = _generateFallbackSvg(cleanSmiles);

        final result = ReactionPredictionResult(
          success: true,
          productSmiles: cleanSmiles,
          svgData: fallbackSvg,
          keyIndexUsed: aiRes.keyIndexUsed,
          model: aiRes.model,
        );
        _memoryCache[cacheKey] = result;

        // Hydrate with Cactus 2D vector asynchronously in background
        fetchCactusSvg(cleanSmiles).then((svg) {
          if (svg.isNotEmpty && svg.contains('<svg')) {
            _memoryCache[cacheKey] = ReactionPredictionResult(
              success: true,
              productSmiles: cleanSmiles,
              svgData: svg,
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

    // 3. Fallback: Edge Function invocation if Gemini was unreachable
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
              svgData = _generateFallbackSvg(productSmiles);
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

  /// Instant offline prediction for common textbook organic reactions (0 ms resolution)
  ReactionPredictionResult? _tryOfflineReactionRule(String reactants) {
    final s = reactants.replaceAll(' ', '');
    final lower = s.toLowerCase();

    // 1. Aspirin Synthesis: Salicylic acid + Acetic Anhydride / Acetyl Chloride -> Aspirin
    final hasSalicylic = lower.contains('oc1ccccc1c(=o)o') ||
        lower.contains('c1ccc(c(c1)c(=o)o)o') ||
        lower.contains('o=c(o)c1ccccc1o');
    final hasAcetylatingAgent = lower.contains('cc(=o)oc(=o)c') ||
        lower.contains('cc(=o)cl') ||
        lower.contains('clc(c)=o') ||
        lower.contains('acetic');
    if (hasSalicylic && hasAcetylatingAgent) {
      const prod = 'CC(=O)Oc1ccccc1C(=O)O'; // Aspirin
      return ReactionPredictionResult(
        success: true,
        productSmiles: prod,
        svgData: _generateFallbackSvg(prod),
        isCached: true,
      );
    }
    // Salicylic acid alone (acetylating to Aspirin under standard synthesis prompt)
    if (lower == 'oc1ccccc1c(=o)o' || lower == 'c1ccc(c(c1)c(=o)o)o') {
      const prod = 'CC(=O)Oc1ccccc1C(=O)O';
      return ReactionPredictionResult(
        success: true,
        productSmiles: prod,
        svgData: _generateFallbackSvg(prod),
        isCached: true,
      );
    }

    // 2. Paracetamol Synthesis: 4-Aminophenol + Acetic Anhydride
    final has4Aminophenol = lower.contains('nc1ccc(o)cc1') || lower.contains('oc1ccc(n)cc1');
    if (has4Aminophenol && hasAcetylatingAgent) {
      const prod = 'CC(=O)Nc1ccc(O)cc1'; // Paracetamol
      return ReactionPredictionResult(
        success: true,
        productSmiles: prod,
        svgData: _generateFallbackSvg(prod),
        isCached: true,
      );
    }

    // 3. Esterification: Acetic Acid + Ethanol -> Ethyl Acetate
    if ((lower.contains('cc(=o)o') || lower.contains('cc(o)=o')) && (lower.contains('cco') || lower.contains('occ'))) {
      const prod = 'CCOC(=O)C';
      return ReactionPredictionResult(
        success: true,
        productSmiles: prod,
        svgData: _generateFallbackSvg(prod),
        isCached: true,
      );
    }

    // 4. Benzoic Acid + Methanol -> Methyl Benzoate
    if ((lower.contains('c1ccccc1c(=o)o') || lower.contains('o=c(o)c1ccccc1')) && (lower.contains('.co') || lower.contains('co.'))) {
      const prod = 'COC(=O)c1ccccc1';
      return ReactionPredictionResult(
        success: true,
        productSmiles: prod,
        svgData: _generateFallbackSvg(prod),
        isCached: true,
      );
    }

    // 5. Electrophilic Aromatic Substitution: Benzene
    final isBenzene = lower == 'c1ccccc1' || lower == 'c1=cc=cc=c1';
    if (isBenzene) {
      const prod = 'c1ccc(cc1)[N+](=O)[O-]'; // Nitrobenzene
      return ReactionPredictionResult(
        success: true,
        productSmiles: prod,
        svgData: _generateFallbackSvg(prod),
        isCached: true,
      );
    }
    if ((lower.contains('c1ccccc1') || lower.contains('c1=cc=cc=c1')) && (lower.contains('br') || lower.contains('brom'))) {
      const prod = 'c1ccc(cc1)Br'; // Bromobenzene
      return ReactionPredictionResult(
        success: true,
        productSmiles: prod,
        svgData: _generateFallbackSvg(prod),
        isCached: true,
      );
    }
    if ((lower.contains('c1ccccc1') || lower.contains('c1=cc=cc=c1')) && (lower.contains('cc(=o)cl') || lower.contains('clc(c)=o'))) {
      const prod = 'CC(=O)c1ccccc1'; // Acetophenone (Friedel-Crafts)
      return ReactionPredictionResult(
        success: true,
        productSmiles: prod,
        svgData: _generateFallbackSvg(prod),
        isCached: true,
      );
    }

    // 6. Aniline + Acetyl chloride -> Acetanilide
    if (lower.contains('nc1ccccc1') && hasAcetylatingAgent) {
      const prod = 'CC(=O)Nc1ccccc1';
      return ReactionPredictionResult(
        success: true,
        productSmiles: prod,
        svgData: _generateFallbackSvg(prod),
        isCached: true,
      );
    }

    // 7. Alkene Halogenation: Ethene + Br2 -> 1,2-Dibromoethane
    if ((lower == 'c=c' || lower == 'c=c.brbr' || lower.contains('c=c.br')) && lower.contains('br')) {
      const prod = 'BrCCBr';
      return ReactionPredictionResult(
        success: true,
        productSmiles: prod,
        svgData: _generateFallbackSvg(prod),
        isCached: true,
      );
    }

    // 8. Cyclohexene + Br2 -> 1,2-Dibromocyclohexane
    if (lower.contains('c1=ccccc1') && lower.contains('br')) {
      const prod = 'BrC1CCCCC1Br';
      return ReactionPredictionResult(
        success: true,
        productSmiles: prod,
        svgData: _generateFallbackSvg(prod),
        isCached: true,
      );
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

  static String _generateFallbackSvg(String smiles) {
    final safe = smiles.replaceAll('&', '&amp;').replaceAll('<', '&lt;').replaceAll('>', '&gt;');
    return '''<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 340 180" width="100%" height="100%">
  <rect width="340" height="180" rx="16" fill="#0F172A" stroke="#334155" stroke-width="1.5"/>
  <circle cx="170" cy="65" r="32" fill="#8B5CF6" fill-opacity="0.15" stroke="#A78BFA" stroke-width="1.5" stroke-dasharray="4 3"/>
  <text x="170" y="72" font-size="22" font-weight="bold" fill="#38BDF8" text-anchor="middle" font-family="sans-serif">PRODUCT</text>
  <text x="170" y="125" font-size="14" font-weight="700" fill="#E2E8F0" text-anchor="middle" font-family="monospace">$safe</text>
  <text x="170" y="148" font-size="11" font-weight="600" fill="#94A3B8" text-anchor="middle" font-family="sans-serif">Predicted Major Product (SMILES)</text>
</svg>''';
  }
}
