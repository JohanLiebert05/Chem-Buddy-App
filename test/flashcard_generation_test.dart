import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/smart_flashcard.dart';
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

    test('2. Synthesizes chemistry cards directly from notes with standalone questions & 3-5 key terms', () async {
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

      for (final card in cards) {
        // Must NOT contain chopped ellipses quotes
        expect(card.question.contains('...'), false, reason: 'Card should not contain ellipses snippets: ${card.question}');
        expect(card.question.startsWith('Explain the following point:'), false);
        expect(card.question.startsWith('What does the document state regarding'), false);

        // Must be a complete interrogative question
        expect(card.question.endsWith('?') || card.question.endsWith('.'), true);

        // Must have key terms
        expect(card.keyTerms.isNotEmpty, true, reason: 'Card must have key terms: ${card.question}');
        expect(card.keyTerms.isNotEmpty && card.keyTerms.length <= 5, true);
      }
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
      for (final card in cards) {
        expect(
          card.question.contains('SN1') || card.question.contains('SN2') || card.question.contains('Diels-Alder'),
          false,
          reason: 'Card should not contain generic organic questions: ${card.question}',
        );
        expect(card.question.contains('...'), false);
        expect(card.keyTerms.isNotEmpty, true);
      }

      final allText = cards.map((c) => '${c.question} ${c.answer} ${c.keyTerms.join(" ")}').join(' ');
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

    test('4. SmartFlashcard model correctly serializes and deserializes key_terms', () {
      const card = SmartFlashcard(
        id: 'test-123',
        setId: 'set-456',
        question: r'What is the rate law for a Cannizzaro reaction?',
        answer: r'The rate equation is $\text{Rate} = k[\text{RCHO}]^2[\text{OH}^-]^2$ at high base concentrations.',
        topic: 'Organic Reaction Mechanisms',
        keyTerms: ['Rate Law', 'Cannizzaro Reaction', 'Second-Order Base Dependence', 'Hydride Transfer'],
        position: 0,
      );

      final json = card.toJson();
      expect(json['key_terms'], isA<List>());
      expect(json['key_terms'].length, 4);
      expect(json['key_terms'][0], 'Rate Law');

      final fromJson = SmartFlashcard.fromJson(json);
      expect(fromJson.keyTerms.length, 4);
      expect(fromJson.keyTerms[1], 'Cannizzaro Reaction');
      expect(fromJson.question, card.question);
      expect(fromJson.answer, card.answer);
    });
  });
}
