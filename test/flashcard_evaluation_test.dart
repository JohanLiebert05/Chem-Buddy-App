import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/flashcard_evaluation.dart';
import 'package:chem_buddy/data/models/smart_flashcard.dart';
import 'package:chem_buddy/data/services/flashcard_evaluation_service.dart';
import 'package:chem_buddy/presentation/widgets/flashcard_evaluation_modal.dart';

void main() {
  group('FlashcardEvaluationService & Model Tests', () {
    final service = FlashcardEvaluationService();

    const officialAnswer = r'The Cannizzaro reaction is the base-induced redox disproportionation of aldehydes lacking alpha-hydrogens, yielding a primary alcohol and a carboxylate salt via hydride transfer.';
    const keyTerms = [
      'Disproportionation',
      'Hydride Transfer',
      'Aldehydes lacking alpha-hydrogens',
      'Carboxylate Salt',
    ];

    test('1. Empty user answer yields 0% score and Again recommendation', () async {
      final eval = await service.evaluate(
        userAnswer: '',
        officialAnswer: officialAnswer,
        keyTerms: keyTerms,
      );

      expect(eval.matchPercentage, 0);
      expect(eval.coveredTerms.isEmpty, true);
      expect(eval.missedTerms.length, keyTerms.length);
      expect(eval.recommendedAction, FlashcardRating.again);
    });

    test('2. Complete high-accuracy answer yields high match percentage and Easy recommendation', () async {
      const userAnswer = 'It is the disproportionation of aldehydes lacking alpha-hydrogens in concentrated alkali, producing a primary alcohol and carboxylate salt through rate-determining hydride transfer.';

      final eval = await service.evaluate(
        userAnswer: userAnswer,
        officialAnswer: officialAnswer,
        keyTerms: keyTerms,
      );

      expect(eval.matchPercentage >= 80, true, reason: 'Match percentage was ${eval.matchPercentage}');
      expect(eval.coveredTerms.length >= 3, true);
      expect(eval.recommendedAction == FlashcardRating.good || eval.recommendedAction == FlashcardRating.easy, true);
      expect(eval.feedback.isNotEmpty, true);
    });

    test('3. Partial answer with missing terms yields Hard or Again recommendation and lists missed terms', () async {
      const userAnswer = 'It is a reaction where aldehydes without alpha hydrogens react with base to give alcohol.';

      final eval = await service.evaluate(
        userAnswer: userAnswer,
        officialAnswer: officialAnswer,
        keyTerms: keyTerms,
      );

      expect(eval.matchPercentage > 0 && eval.matchPercentage < 75, true);
      expect(eval.missedTerms.isNotEmpty, true);
      expect(eval.recommendedAction == FlashcardRating.hard || eval.recommendedAction == FlashcardRating.again, true);
    });

    test('4. FlashcardAiEvaluation JSON serialization roundtrip', () {
      const eval = FlashcardAiEvaluation(
        matchPercentage: 92,
        coveredTerms: ['Hydride Transfer', 'Disproportionation'],
        missedTerms: ['Carboxylate Salt'],
        feedback: 'Great mechanistic explanation.',
        recommendedAction: FlashcardRating.good,
      );

      final json = eval.toJson();
      expect(json['match_percentage'], 92);
      expect(json['covered_terms'], ['Hydride Transfer', 'Disproportionation']);
      expect(json['recommended_action'], 'good');

      final fromJson = FlashcardAiEvaluation.fromJson(json);
      expect(fromJson.matchPercentage, 92);
      expect(fromJson.coveredTerms.length, 2);
      expect(fromJson.missedTerms.first, 'Carboxylate Salt');
      expect(fromJson.recommendedAction, FlashcardRating.good);
    });
  });

  group('FlashcardEvaluationModal Widget Tests', () {
    testWidgets('Renders score circle, covered/missed chips, feedback, and action buttons', (tester) async {
      FlashcardRating? selectedRating;

      const eval = FlashcardAiEvaluation(
        matchPercentage: 88,
        coveredTerms: ['Disproportionation', 'Hydride Transfer'],
        missedTerms: ['Carboxylate Salt'],
        feedback: 'Make sure to also state the counter-ion / salt formation.',
        recommendedAction: FlashcardRating.good,
      );

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlashcardEvaluationModal(
              evaluation: eval,
              onApplyRating: (rating) {
                selectedRating = rating;
              },
            ),
          ),
        ),
      );

      await tester.pumpAndSettle();

      // Check Score
      expect(find.text('88%'), findsOneWidget);
      expect(find.text('AI Active Recall Evaluation'), findsOneWidget);

      // Check Covered & Missed Chips
      expect(find.text('✓ Disproportionation'), findsOneWidget);
      expect(find.text('✓ Hydride Transfer'), findsOneWidget);
      expect(find.text('✗ Carboxylate Salt'), findsOneWidget);

      // Check Feedback
      expect(find.text('Make sure to also state the counter-ion / salt formation.'), findsOneWidget);

      // Check Recommendation Badge
      expect(find.text('✨ AI Recommendation: Good'), findsOneWidget);

      // Tap Good button
      await tester.tap(find.text('Good'));
      await tester.pumpAndSettle();

      expect(selectedRating, FlashcardRating.good);
    });
  });
}
