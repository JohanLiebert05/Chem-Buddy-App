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

    test('3. Synthesizes flashcards strictly from LC Solutions / Analytical PDF without unrelated organic concepts', () async {
      const lcNotes = '''
Shimadzu LC Solutions System Manual & HPLC Operation Guide.
Instrument: Prominence HPLC Modular System
Column: C18 Octadecylsilane (250 mm x 4.6 mm, 5 µm particle size)
Flow Rate: 1.0 mL/min
Detector: UV-Vis Photodiode Array (PDA) operating at 254 nm
Mobile Phase: Acetonitrile and 0.1% Phosphoric Acid in Water (60:40 v/v)
Autosampler Injection Volume: 20 µL
Column Oven Temperature: 40 °C
Retention Time (t_R) of sample analyte is 4.5 minutes.
System suitability requires column theoretical plates N > 2000 and peak symmetry factor As < 1.5.
Peak area integration is used for quantitative determination against standard calibration curves.
''';

      final cards = await service.generate(
        sourceText: lcNotes,
        count: 5,
        topic: 'LC Solutions',
      );

      expect(cards.length, 5);
      // All cards must be grounded strictly in LC Solutions
      for (final card in cards) {
        expect(
          card.question.contains('SN1') || card.question.contains('SN2') || card.question.contains('Diels-Alder'),
          false,
          reason: 'Card should not contain generic organic questions: ${card.question}',
        );
      }

      // Check that cards contain LC Solutions content
      final allText = cards.map((c) => '${c.question} ${c.answer}').join(' ');
      expect(
        allText.contains('Column') ||
            allText.contains('Flow Rate') ||
            allText.contains('Detector') ||
            allText.contains('HPLC') ||
            allText.contains('Shimadzu') ||
            allText.contains('Retention') ||
            allText.contains('C18'),
        true,
        reason: 'Cards must contain LC Solutions concepts: $allText',
      );
    });
  });
}
