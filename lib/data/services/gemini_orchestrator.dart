import 'dart:convert';

import 'package:crypto/crypto.dart';

import '../../core/utils/chemistry_text_formatter.dart';
import '../models/rag_models.dart';
import '../remote/supabase_service.dart';

class OrchestratorResponse {
  final String text;
  final String model;
  final bool isCached;
  final int keyIndexUsed;
  final int totalKeys;
  final Duration latency;
  const OrchestratorResponse({
    required this.text,
    required this.model,
    required this.isCached,
    required this.keyIndexUsed,
    required this.totalKeys,
    required this.latency,
  });
}

/// Provider credentials and model failover are confined to the backend.
class GeminiOrchestrator {
  GeminiOrchestrator({SupabaseService? remote})
    : _remote = remote ?? SupabaseService.instance;
  static final instance = GeminiOrchestrator();
  final SupabaseService _remote;
  final Map<String, OrchestratorResponse> _cache = {};
  void clearCache() => _cache.clear();

  Future<OrchestratorResponse> ask({
    required String prompt,
    String category = 'general',
    String? systemInstruction,
    double temperature = 0.3,
    List<AiMessage>? history,
    String? documentContext,
    String? mode,
  }) async {
    final question = prompt.trim();
    if (question.isEmpty) {
      throw ArgumentError('Prompt cannot be empty.');
    }
    final started = DateTime.now();
    final request = <String, dynamic>{
      'prompt': question,
      'category': category,
      'system_instruction': systemInstruction,
      'temperature': temperature,
      'document_context': documentContext,
      'mode': mode,
      'max_output_tokens': 8192,
      'history':
          history
              ?.map((e) => {'role': e.role, 'content': e.content})
              .toList() ??
          [],
    };
    final userId = _remote.userId;
    if (userId == null) {
      return OrchestratorResponse(
        text: 'Error: Sign in to use cloud AI. Guest study data stays on this device.',
        model: 'unavailable',
        isCached: false,
        keyIndexUsed: 0,
        totalKeys: 0,
        latency: DateTime.now().difference(started),
      );
    }
    final key = sha256
        .convert(utf8.encode(jsonEncode([userId, request])))
        .toString();
    if (_cache.containsKey(key)) {
      final hit = _cache[key]!;
      return OrchestratorResponse(
        text: hit.text,
        model: hit.model,
        isCached: true,
        keyIndexUsed: hit.keyIndexUsed,
        totalKeys: hit.totalKeys,
        latency: DateTime.now().difference(started),
      );
    }
    try {
      final result = await _remote.invokeFunction(
        'ask-gemini-orchestrator',
        request,
        timeout: const Duration(seconds: 45),
        maxRetries: 2,
      );
      if (result is! Map ||
          result['text'] is! String ||
          (result['text'] as String).trim().isEmpty) {
        throw StateError('Empty AI response');
      }
      final response = OrchestratorResponse(
        text: ChemistryTextFormatter.format(result['text'] as String),
        model: result['model'] as String? ?? 'server',
        isCached: false,
        keyIndexUsed: (result['key_index'] as num?)?.toInt() ?? 0,
        totalKeys: (result['total_keys'] as num?)?.toInt() ?? 0,
        latency: DateTime.now().difference(started),
      );
      if (userId == _remote.userId) {
        if (_cache.length >= 50) {
          _cache.remove(_cache.keys.first);
        }
        _cache[key] = response;
      }
      return response;
    } catch (_) {
      return OrchestratorResponse(
        text: 'Error: Cloud AI is unavailable. Please sign in and try again.',
        model: 'unavailable',
        isCached: false,
        keyIndexUsed: 0,
        totalKeys: 0,
        latency: DateTime.now().difference(started),
      );
    }
  }

  Future<bool> pingHealth() async {
    try {
      await _remote.invokeFunction(
        'ask-gemini-orchestrator',
        {'prompt': 'ping'},
        timeout: const Duration(seconds: 5),
        maxRetries: 0,
      );
      return true;
    } catch (_) {
      return false;
    }
  }
}
