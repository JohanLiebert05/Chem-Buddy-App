import 'dart:convert';

import '../../core/chemistry/spectroscopy_structure_svg.dart';
import '../remote/supabase_service.dart';
import 'curious_catalog.dart';

class CuriousExplanation {
  const CuriousExplanation(
    this.explanation,
    this.steps,
    this.mistake,
    this.check,
    this.answer,
  );
  final String explanation, mistake, check, answer;
  final List<String> steps;
  static CuriousExplanation parse(String text, CuriousTopic topic) {
    if (text.length > 24000) {
      throw const FormatException('Explanation is too long.');
    }
    final decoded = jsonDecode(
      text
          .trim()
          .replaceFirst(RegExp(r'^```(?:json)?\s*'), '')
          .replaceFirst(RegExp(r'\s*```$'), ''),
    );
    if (decoded is! Map ||
        decoded['topic_id'] != topic.id ||
        decoded['example_smiles'] != topic.molecule.smiles) {
      throw const FormatException(
        'The explanation does not match this question and structure.',
      );
    }
    String field(String name, int max) {
      final value = decoded[name];
      if (value is! String || value.trim().length < 12 || value.length > max) {
        throw FormatException('Invalid explanation field: $name.');
      }
      return value.trim();
    }

    final steps = decoded['steps'];
    if (steps is! List ||
        steps.length < 2 ||
        steps.length > 6 ||
        steps.any(
          (s) => s is! String || s.trim().length < 12 || s.length > 1200,
        )) {
      throw const FormatException(
        'The explanation needs two to six complete steps.',
      );
    }
    if (SpectroscopyStructureSvg.depict(topic.molecule).svg == null) {
      throw const FormatException(
        'The example structure could not be checked.',
      );
    }
    return CuriousExplanation(
      field('explanation', 6000),
      List<String>.from(steps),
      field('common_mistake', 1500),
      field('check_question', 1000),
      field('check_answer', 1500),
    );
  }
}

typedef CuriousInvoke = Future<dynamic> Function(Map<String, dynamic>);

/// Authenticated backend rotates provider keys. No key is bundled in the app.
/// Small account-scoped memory cache avoids repeat charges on reopening a page.
class CuriousExplanationService {
  CuriousExplanationService({
    CuriousInvoke? invoke,
    String? Function()? account,
  }) : _invoke = invoke ?? _production,
       _account = account ?? (() => SupabaseService.instance.userId);
  final CuriousInvoke _invoke;
  final String? Function() _account;
  final _pending = <String, Future<CuriousExplanation>>{};
  static final _cache = <String, (DateTime, CuriousExplanation)>{};
  static Future<dynamic> _production(Map<String, dynamic> body) =>
      SupabaseService.instance.invokeFunction(
        'ask-gemini-orchestrator',
        body,
        timeout: const Duration(seconds: 45),
        maxRetries: 1,
      );

  Future<CuriousExplanation> expand(CuriousTopic topic) async {
    final owner = _account();
    if (owner == null) {
      throw StateError(
        'Sign in to explore further online. Your saved questions still work offline.',
      );
    }
    final key = '$owner:${topic.id}';
    final old = _cache[key];
    if (old != null &&
        DateTime.now().difference(old.$1) < const Duration(hours: 6)) {
      return old.$2;
    }
    if (_pending[key] case final running?) return running;
    final future = _request(topic, owner, key);
    _pending[key] = future;
    try {
      return await future;
    } finally {
      _pending.remove(key);
    }
  }

  Future<CuriousExplanation> _request(
    CuriousTopic topic,
    String owner,
    String key,
  ) async {
    final response = await _invoke({
      'category': 'chemistry_curiosity',
      'temperature': 0.3,
      'max_output_tokens': 2200,
      'prompt': jsonEncode({
        'task': 'Explain this organic chemistry curiosity for a student rebuilding foundations. Give a new worked explanation, not just a paraphrase.',
        'topic_id': topic.id,
        'question': topic.question,
        'reference': topic.answer,
        'example_name': topic.molecule.commonName,
        'example_formula': topic.molecule.formula,
        'example_smiles': topic.molecule.smiles,
      }),
      'system_instruction': 'You are a careful chemistry teacher. Return ONLY JSON with topic_id, example_smiles, explanation, steps (2–6 strings), common_mistake, check_question, check_answer. Copy topic_id and example_smiles exactly. Use the supplied molecule as an illustration or explicit comparison; do not claim it has properties it lacks. Explain electrons as quantum probability, not orbiting beads; distinguish curved pair arrows, fishhooks, reaction arrows and resonance arrows. State relevant conditions and limitations. Never invent experimental data or claim guaranteed accuracy. Do not output drawing markup, links, provider names or implementation terms. For reactions describe source and destination of electrons and conserve atoms, charge and ordinary valence. For non-reaction topics give reasoning steps, not a fabricated reaction.',
    });
    if (_account() != owner) {
      throw StateError('Your account changed. Reopen Curious.');
    }
    if (response is! Map || response['text'] is! String) {
      throw const FormatException('No complete explanation was returned.');
    }
    final result = CuriousExplanation.parse(response['text'] as String, topic);
    if (_cache.length >= 20) _cache.remove(_cache.keys.first);
    _cache[key] = (DateTime.now(), result);
    return result;
  }
}
