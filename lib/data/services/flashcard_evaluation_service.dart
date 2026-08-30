import 'dart:convert';
import 'dart:math';
import 'package:flutter/foundation.dart';

import '../models/flashcard_evaluation.dart';
import '../models/smart_flashcard.dart';
import '../remote/supabase_service.dart';

class FlashcardEvaluationService {
  FlashcardEvaluationService({SupabaseService? remote}) : _remote = remote ?? SupabaseService.instance;

  final SupabaseService _remote;

  /// Evaluates the student's active-recall answer against the official reference answer and key terms.
  Future<FlashcardAiEvaluation> evaluate({
    required String userAnswer,
    required String officialAnswer,
    required List<String> keyTerms,
    String topic = 'Chemistry',
  }) async {
    final cleanUser = userAnswer.trim();
    if (cleanUser.isEmpty) {
      return FlashcardAiEvaluation(
        matchPercentage: 0,
        coveredTerms: const [],
        missedTerms: keyTerms,
        feedback: 'No answer provided. Take a moment to review the model answer and retry active recall.',
        recommendedAction: FlashcardRating.again,
      );
    }

    if (_remote.configured) {
      try {
        final prompt = '''Act as an expert MSc Chemistry examiner evaluating a student's active-recall flashcard answer.

QUESTION TOPIC: $topic
OFFICIAL REFERENCE ANSWER:
$officialAnswer

MANDATORY KEY CHEMICAL TERMS:
${keyTerms.map((t) => "- $t").join("\n")}

STUDENT'S TYPED ANSWER:
$cleanUser

TASK:
1. Calculate a semantic and chemical conceptual match percentage (0 to 100).
2. Determine which of the mandatory key chemical terms were adequately covered (covered_terms) and which were missed/inaccurate (missed_terms).
3. Provide 1 to 2 sentences of constructive academic feedback (feedback) explaining missed chemical nuances (e.g. electron transfer, oxidation state, reaction conditions, regioselectivity, rate law).
4. Recommend a spaced-repetition action (recommended_action: "again", "hard", "good", or "easy").

Return strictly valid JSON with this shape:
{
  "match_percentage": 85,
  "covered_terms": ["Term 1", "Term 2"],
  "missed_terms": ["Term 3"],
  "feedback": "Concise 1-2 sentence academic feedback",
  "recommended_action": "good"
}''';

        final raw = await _remote.invokeFunction(
          'ask-chembuddy',
          {
            'question': prompt,
            'document_name': 'Active Recall Flashcard Evaluation',
          },
          timeout: const Duration(seconds: 25),
        );

        if (raw is Map && raw['answer'] != null) {
          final eval = _parseAiEvaluation(raw['answer'].toString());
          if (eval != null) return eval;
        } else if (raw is Map) {
          final eval = FlashcardAiEvaluation.fromJson(Map<String, dynamic>.from(raw));
          return eval;
        }
      } catch (e) {
        debugPrint('[FlashcardEvaluationService] Cloud evaluation error ($e). Using local academic analysis.');
      }
    }

    // High-accuracy offline / local Academic Chemistry Evaluation
    return _localAcademicEvaluation(
      userAnswer: cleanUser,
      officialAnswer: officialAnswer,
      keyTerms: keyTerms,
      topic: topic,
    );
  }

  FlashcardAiEvaluation? _parseAiEvaluation(String rawText) {
    var text = rawText.trim();
    final fenceMatch = RegExp(r'```(?:json)?\s*([\s\S]*?)```', caseSensitive: false).firstMatch(text);
    if (fenceMatch != null && fenceMatch.group(1) != null) {
      text = fenceMatch.group(1)!.trim();
    }

    try {
      final decoded = jsonDecode(text);
      if (decoded is Map<String, dynamic>) {
        return FlashcardAiEvaluation.fromJson(decoded);
      }
    } catch (_) {
      final startIdx = text.indexOf('{');
      final endIdx = text.lastIndexOf('}');
      if (startIdx >= 0 && endIdx > startIdx) {
        try {
          final sub = text.substring(startIdx, endIdx + 1);
          final decoded = jsonDecode(sub);
          if (decoded is Map<String, dynamic>) {
            return FlashcardAiEvaluation.fromJson(decoded);
          }
        } catch (_) {}
      }
    }
    return null;
  }

  /// High-accuracy local semantic & keyword comparison algorithm
  FlashcardAiEvaluation _localAcademicEvaluation({
    required String userAnswer,
    required String officialAnswer,
    required List<String> keyTerms,
    required String topic,
  }) {
    final normUser = _normalize(userAnswer);
    final normOfficial = _normalize(officialAnswer);

    final covered = <String>[];
    final missed = <String>[];

    // 1. Key Term Matching (Exact, substring, and root matching)
    for (final term in keyTerms) {
      final normTerm = _normalize(term);
      if (normTerm.isEmpty) continue;

      final termWords = normTerm.split(RegExp(r'\s+')).where((w) => w.length > 2).toList();
      var isCovered = false;

      if (normUser.contains(normTerm)) {
        isCovered = true;
      } else if (termWords.isNotEmpty) {
        // If multi-word term, check how many words appear
        final matchedWords = termWords.where((w) => normUser.contains(w)).length;
        if (matchedWords >= (termWords.length >= 3 ? termWords.length - 1 : termWords.length)) {
          isCovered = true;
        }
      }

      if (isCovered) {
        covered.add(term);
      } else {
        missed.add(term);
      }
    }

    // 2. Token overlap and semantic richness
    final userTokens = normUser.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();
    final officialTokens = normOfficial.split(RegExp(r'\s+')).where((w) => w.length > 2).toSet();

    var overlapCount = 0;
    for (final tok in userTokens) {
      if (officialTokens.contains(tok)) {
        overlapCount++;
      }
    }

    final tokenOverlapRatio = officialTokens.isNotEmpty ? (overlapCount / officialTokens.length) : 0.0;
    final termRatio = keyTerms.isNotEmpty ? (covered.length / keyTerms.length) : tokenOverlapRatio;

    // Combined score: 65% key terms, 35% token/concept coverage
    final rawScore = (termRatio * 0.65 + tokenOverlapRatio * 0.35) * 100;
    final matchPercentage = rawScore.round().clamp(5, 100);

    // 3. Spaced repetition recommendation & academic feedback
    FlashcardRating rating;
    String feedback;

    if (matchPercentage >= 85) {
      rating = FlashcardRating.easy;
      feedback = 'Outstanding accuracy! Your response thoroughly captures all fundamental mechanisms and chemical terminology.';
    } else if (matchPercentage >= 70) {
      rating = FlashcardRating.good;
      feedback = missed.isNotEmpty
          ? 'Solid grasp of the core principle! Be sure to emphasize ${missed.take(2).join(" and ")} for complete exam precision.'
          : 'Good conceptual explanation. Retain this model answer for spaced review.';
    } else if (matchPercentage >= 40) {
      rating = FlashcardRating.hard;
      feedback = missed.isNotEmpty
          ? 'Partially correct. You missed critical concepts: ${missed.join(", ")}. Review the official chemical explanation.'
          : 'Partially correct explanation. Focus on standard chemical terminology and stoichiometry.';
    } else {
      rating = FlashcardRating.again;
      feedback = 'Your response lacked key chemical mechanisms or definitions (${missed.take(3).join(", ")}). Mark as Again to review soon.';
    }

    return FlashcardAiEvaluation(
      matchPercentage: matchPercentage,
      coveredTerms: covered,
      missedTerms: missed,
      feedback: feedback,
      recommendedAction: rating,
    );
  }

  String _normalize(String input) {
    return input
        .toLowerCase()
        .replaceAll(RegExp(r'[{}\[\]\(\)\\_\$]'), '')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }
}
