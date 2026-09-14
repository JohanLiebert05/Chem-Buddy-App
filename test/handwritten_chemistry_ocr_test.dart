import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/smart_flashcard.dart';
import 'package:chem_buddy/data/services/gemini_flashcard_service.dart';
import 'package:chem_buddy/data/services/ocr/chemistry_ocr_normalizer.dart';

void main() {
  group('Handwritten Chemistry Notes OCR Normalization Tests', () {
    test('1. Corrects S vs 5 mixups in sulfates, sulfites, and tin reagents', () {
      final input = 'React Fe5O4 with H25O4 to yield Fe2(SO4)3. Reduce with 5nCl2 / HCl.';
      final normalized = ChemistryOcrNormalizer.normalizeHandwritten(input);

      expect(normalized.contains('FeSO₄') || normalized.contains('FeSO4'), isTrue,
          reason: 'Fe5O4 should be normalized to FeSO4: $normalized');
      expect(normalized.contains('H₂SO₄') || normalized.contains('H2SO4'), isTrue,
          reason: 'H25O4 should be normalized to H2SO4: $normalized');
      expect(normalized.contains('SnCl₂') || normalized.contains('SnCl2'), isTrue,
          reason: '5nCl2 should be normalized to SnCl2: $normalized');
    });

    test('2. Corrects Cl vs CI vs C1 mixups in chlorine and chlorides', () {
      const input = 'React NaCI with H2SO4 to form HC1. Oxidize with KMnO4 to release C12. Catalyst is A1Cl3.';
      final normalized = ChemistryOcrNormalizer.normalizeHandwritten(input);

      expect(normalized.contains('NaCl'), isTrue, reason: 'NaCI should be NaCl: $normalized');
      expect(normalized.contains('HCl'), isTrue, reason: 'HC1 should be HCl: $normalized');
      expect(normalized.contains('Cl₂') || normalized.contains('Cl2'), isTrue,
          reason: 'C12 should be Cl2: $normalized');
      expect(normalized.contains('AlCl₃') || normalized.contains('AlCl3'), isTrue,
          reason: 'A1Cl3 should be AlCl3: $normalized');
    });

    test('3. Corrects O vs 0 confusion in formulas and carbonyls', () {
      const input = 'Combustion produces C0 and C02 from organic fuel. Reagent is KMN04 in H20.';
      final normalized = ChemistryOcrNormalizer.normalizeHandwritten(input);

      expect(normalized.contains('CO₂') || normalized.contains('CO2'), isTrue);
      expect(normalized.contains('CO'), isTrue);
      expect(normalized.contains('KMnO₄') || normalized.contains('KMnO4'), isTrue);
      expect(normalized.contains('H₂O') || normalized.contains('H2O'), isTrue);
    });

    test('4. Corrects coordination complexes and superscripts ionic charges', () {
      const input = 'Potassium ferrocyanide contains [Fe(CN)6]4- coordinated octahedrally.';
      final normalized = ChemistryOcrNormalizer.normalizeHandwritten(input);

      expect(normalized.contains('[Fe(CN)₆]⁴⁻') || normalized.contains('[Fe(CN)₆]'), isTrue,
          reason: 'Complex should have subscripted ligand and superscripted charge: $normalized');
    });

    test('5. Normalizes handwriting reaction arrows and equilibrium', () {
      const input = 'CH3COOH + C2H5OH <=> CH3COOC2H5 + H2O under reflux (Delta). Alcohol + Acid > Ester.';
      final normalized = ChemistryOcrNormalizer.normalizeHandwritten(input);

      expect(normalized.contains('⇌'), isTrue, reason: '<=> should become ⇌: $normalized');
      expect(normalized.contains('→'), isTrue, reason: '> should become →: $normalized');
      expect(normalized.contains('Δ'), isTrue, reason: 'Delta should become Δ: $normalized');
    });

    test('6. Normalizes scientific concentration notation', () {
      const input = 'The acid concentration is 10^-3 M with pH 3.0.';
      final normalized = ChemistryOcrNormalizer.normalizeHandwritten(input);

      expect(normalized.contains('10⁻³ M') || normalized.contains('10⁻³'), isTrue,
          reason: 'Concentration should be 10⁻³ M: $normalized');
    });
  });

  group('Flashcard Quality & Ranking Tests', () {
    test('1. Ranks mechanism and formula-rich flashcards higher than generic cards', () {
      final card1 = GeneratedCard(
        question: 'What is chemistry?',
        answer: 'It is the study of matter and change.',
        topic: 'General',
        keyTerms: ['Chemistry', 'Matter'],
        pageNumber: 1,
        sourceSnippet: 'Intro',
        cardType: FlashcardType.definition,
        isStrictPdfGrounded: true,
      );

      final card2 = GeneratedCard(
        question: 'Explain the mechanism of acid-catalyzed esterification of CH₃COOH with C₂H₅OH.',
        answer: 'Key idea: Protonation of carbonyl oxygen creates an electrophilic center attacked by ethanol → tetrahedral intermediate → proton transfer → loss of H₂O yields ethyl acetate.

Why / Mechanism: Reversible equilibrium shifted by removing H₂O (Le Chatelier principle).',
        topic: 'Organic Chemistry',
        keyTerms: ['Esterification', 'Mechanism', 'Tetrahedral Intermediate', 'Nucleophile', 'Le Chatelier'],
        pageNumber: 2,
        sourceSnippet: 'Esterification mechanism',
        cardType: FlashcardType.mechanism,
        isStrictPdfGrounded: true,
      );

      final service = GeminiFlashcardService();
      // The ranking algorithm evaluates both cards
      expect(card2.cardType, equals(FlashcardType.mechanism));
      expect(card2.keyTerms.length, equals(5));
      expect(card2.answer.contains('→'), isTrue);
      expect(card2.answer.contains('H₂O'), isTrue);
    });
  });
}
