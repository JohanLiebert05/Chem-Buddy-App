import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/gemini_flashcard_service.dart';

void main() {
  group('GeminiFlashcardService JSON & Resilience Tests', () {
    final service = GeminiFlashcardService();

    test('1. Empty or very short PDF text throws descriptive error', () async {
      expect(
        () => service.generate(sourceText: 'short', count: 10),
        throwsA(isA<StateError>()),
      );
    });

    test('2. Synthesizes chemistry cards directly from notes when offline/fallback', () async {
      const notes = '''
Aldol condensation is defined as the reaction of an enolate ion with a carbonyl compound to form a beta-hydroxy aldehyde.
Cannizzaro reaction refers to the redox disproportionation of aldehydes lacking alpha hydrogens in alkaline medium.
Diels-Alder reaction involves a [4+2] cycloaddition yielding a cyclohexene derivative.
Crystal Field Theory explains splitting of d orbitals in transition metal complexes.
Selection rules state that Laporte forbidden transitions have lower extinction coefficients.
''';

      final cards = await service.generate(
        sourceText: notes,
        count: 5,
        topic: 'Organic Chemistry',
      );

      expect(cards.isNotEmpty, true);
      expect(cards.length, 5);
      expect(cards.any((c) => c.question.contains('Aldol') || c.question.contains('Define')), true);
    });
  });
}
