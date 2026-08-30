import 'smart_flashcard.dart';

/// Represents the structured AI evaluation of a student's typed active-recall answer.
class FlashcardAiEvaluation {
  const FlashcardAiEvaluation({
    required this.matchPercentage,
    required this.coveredTerms,
    required this.missedTerms,
    required this.feedback,
    required this.recommendedAction,
  });

  /// Semantic and chemical concept similarity score from 0 to 100
  final int matchPercentage;

  /// Mandatory key chemical terms adequately addressed in the student's answer
  final List<String> coveredTerms;

  /// Mandatory key chemical terms missing or inaccurate in the student's answer
  final List<String> missedTerms;

  /// Academic guidance and feedback highlighting chemical nuances
  final String feedback;

  /// Recommended Spaced Repetition rating (again, hard, good, easy)
  final FlashcardRating recommendedAction;

  String get recommendedLabel {
    switch (recommendedAction) {
      case FlashcardRating.again:
        return 'Again';
      case FlashcardRating.hard:
        return 'Hard';
      case FlashcardRating.good:
        return 'Good';
      case FlashcardRating.easy:
        return 'Easy';
    }
  }

  Map<String, dynamic> toJson() => {
        'match_percentage': matchPercentage,
        'covered_terms': coveredTerms,
        'missed_terms': missedTerms,
        'feedback': feedback,
        'recommended_action': recommendedAction.name,
      };

  factory FlashcardAiEvaluation.fromJson(Map<String, dynamic> json) {
    final rawScore = json['match_percentage'] ?? json['matchPercentage'] ?? json['score'] ?? 0;
    final matchPercentage = (rawScore as num).toInt().clamp(0, 100);

    final rawCovered = json['covered_terms'] ?? json['coveredTerms'] ?? json['matched_terms'] ?? [];
    final coveredTerms = (rawCovered is List)
        ? rawCovered.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final rawMissed = json['missed_terms'] ?? json['missedTerms'] ?? json['unmatched_terms'] ?? [];
    final missedTerms = (rawMissed is List)
        ? rawMissed.map((e) => e.toString().trim()).where((e) => e.isNotEmpty).toList()
        : <String>[];

    final feedback = (json['feedback'] ?? json['notes'] ?? '').toString().trim();

    final explicitAction = json['recommended_action'] ?? json['recommendedAction'];
    FlashcardRating rating;
    if (explicitAction != null && explicitAction.toString().trim().isNotEmpty) {
      final act = explicitAction.toString().trim().toLowerCase();
      if (act.contains('again')) {
        rating = FlashcardRating.again;
      } else if (act.contains('hard')) {
        rating = FlashcardRating.hard;
      } else if (act.contains('good')) {
        rating = FlashcardRating.good;
      } else if (act.contains('easy')) {
        rating = FlashcardRating.easy;
      } else {
        rating = FlashcardRating.good;
      }
    } else {
      if (matchPercentage < 40) {
        rating = FlashcardRating.again;
      } else if (matchPercentage < 70) {
        rating = FlashcardRating.hard;
      } else if (matchPercentage >= 88) {
        rating = FlashcardRating.easy;
      } else {
        rating = FlashcardRating.good;
      }
    }

    return FlashcardAiEvaluation(
      matchPercentage: matchPercentage,
      coveredTerms: coveredTerms,
      missedTerms: missedTerms,
      feedback: feedback.isNotEmpty
          ? feedback
          : (matchPercentage >= 80
              ? 'Excellent recall! Your answer accurately captures the core chemical concepts and terminology.'
              : (matchPercentage >= 50
                  ? 'Good conceptual grasp. Review the missed terms to ensure complete exam-level precision.'
                  : 'Key reaction mechanisms or definitions were missing. Revisit the model answer and retry.')),
      recommendedAction: rating,
    );
  }
}
