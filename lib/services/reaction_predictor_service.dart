import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';

import '../data/remote/supabase_service.dart';
import '../data/services/gemini_orchestrator.dart';

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

    // 1. Primary: Invoke Supabase Edge Function `predict-reaction`
    try {
      final client = SupabaseService.instance.client;
      if (client != null) {
        final response = await client.functions.invoke(
          'predict-reaction',
          body: {'reactants_smiles': cleanReactants},
        );

        if (response.status == 200 && response.data != null) {
          final dynamic rawData = response.data;
          final Map<dynamic, dynamic> data =
              rawData is Map ? rawData : jsonDecode(rawData.toString()) as Map<dynamic, dynamic>;

          if (data['success'] == true) {
            final productSmiles = (data['product_smiles'] as String?)?.trim() ?? '';
            var svgData = (data['svg_data'] as String?)?.trim() ?? '';

            // If edge function returned valid smiles but empty SVG, fetch from Cactus locally
            if (productSmiles.isNotEmpty && (svgData.isEmpty || !svgData.contains('<svg'))) {
              svgData = await fetchCactusSvg(productSmiles);
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
          } else if (data['error'] != null) {
            debugPrint('[ReactionPredictorService] Edge function returned error: ${data['error']}');
          }
        }
      }
    } catch (e) {
      debugPrint('[ReactionPredictorService] Supabase function invoke exception: $e');
    }

    // 2. Resilient Client-Side Fallback: 4-Key Gemini Orchestrator + Direct NIH Cactus Fetch
    // If Supabase function is not yet deployed or secrets are missing, this ensures 100% uptime.
    try {
      const systemInstruction =
          'You are an expert organic reaction outcome engine. Return ONLY the valid SMILES string of the single major organic product. Do not include markdown blocks, notes, or explanations.';
      final prompt =
          'Reactants: $cleanReactants\nPredict the single major organic product under standard reaction conditions. Return ONLY its SMILES string.';

      final aiRes = await GeminiOrchestrator.instance.ask(
        prompt: prompt,
        category: 'reaction_prediction',
        systemInstruction: systemInstruction,
        temperature: 0.1,
      );

      final cleanSmiles = _sanitizeSmiles(aiRes.text);
      if (cleanSmiles.isNotEmpty) {
        var svgData = await fetchCactusSvg(cleanSmiles);
        if (svgData.isEmpty) {
          svgData = _generateFallbackSvg(cleanSmiles);
        }

        final result = ReactionPredictionResult(
          success: true,
          productSmiles: cleanSmiles,
          svgData: svgData,
          keyIndexUsed: aiRes.keyIndexUsed,
          model: aiRes.model,
        );
        _memoryCache[cacheKey] = result;
        return result;
      }
    } catch (e) {
      debugPrint('[ReactionPredictorService] Fallback orchestrator error: $e');
    }

    return ReactionPredictionResult.failure(
      'Reaction product prediction temporarily unavailable across all 4 keys. Please verify your connection or try again in a moment.',
    );
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
