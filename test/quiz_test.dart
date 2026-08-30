import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/pdf_ai_study_service.dart';
import 'package:chem_buddy/data/models/pdf_study_models.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chemistry Quiz Generation & Randomization Tests', () {
    final service = PdfAiStudyService();

    test('TEST 1: Cannizzaro topic quiz generates 5-10 questions with 4 options each', () async {
      const topic = 'Cannizzaro Reaction';
      const text = '''
The Cannizzaro reaction is a disproportionation reaction in which an aldehyde lacking alpha-hydrogens
undergoes simultaneous oxidation and reduction in the presence of strong base (e.g., KOH or NaOH).
One aldehyde molecule is oxidized to a carboxylic acid salt while the other is reduced to a primary alcohol.
Mechanism involves hydride transfer in the rate-determining step.
''';

      final quiz = await service.generateQuiz(
        sourceText: text,
        documentTitle: topic,
        count: 10,
      );

      expect(quiz.questions.length, greaterThanOrEqualTo(5));
      expect(quiz.questions.length, lessThanOrEqualTo(10));

      final indicesFound = <int>{};

      for (final q in quiz.questions) {
        expect(q.options.length, equals(4), reason: 'Every question must have exactly 4 options (A, B, C, D)');
        expect(q.correctIndex, greaterThanOrEqualTo(0));
        expect(q.correctIndex, lessThanOrEqualTo(3));
        expect(q.options[q.correctIndex].isNotEmpty, true);
        expect(q.explanation.isNotEmpty, true);
        indicesFound.add(q.correctIndex);
      }

      // Verify that the correct answer is NOT always option A (0)
      expect(indicesFound.length, greaterThan(1), reason: 'Correct answers must be randomized across A, B, C, D');
    });

    test('TEST 2: QuizQuestion.fromJson parses map/letter formats and cleans chemistry', () {
      final json = {
        'question': 'What is the product of 2 C6H5CHO + NaOH?',
        'options': [
          'C6H5CH2OH + C6H5COONa',
          'CH3COOH + C2H5OH',
          'C6H6 + CO2',
          'C6H5COOH only',
        ],
        'correct_index': 0,
        'explanation': 'Forms benzyl alcohol and sodium benzoate.',
        'topic': 'Cannizzaro Reaction',
      };

      final q = QuizQuestion.fromJson(json);
      expect(q.question.contains('2 C₆H₅CHO + NaOH'), true);
      expect(q.options.first.contains('C₆H₅CH₂OH + C₆H₅COONa'), true);
      expect(q.options.length, equals(4));
    });
  });
}
