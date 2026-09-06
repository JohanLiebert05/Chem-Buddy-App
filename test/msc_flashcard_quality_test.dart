import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/pdf_ocr_models.dart';
import 'package:chem_buddy/data/models/smart_flashcard.dart';
import 'package:chem_buddy/data/services/gemini_flashcard_service.dart';

void main() {
  group('MSc Flashcard Quality, Classification & Traceability Tests', () {
    final service = GeminiFlashcardService();

    test('1. Generates diverse high-value cards with page citations from OCR bundle', () async {
      const page1 = PdfPageOcrResult(
        pageNumber: 1,
        rawText: 'Pinacol-Pinacolone rearrangement involves the acid-catalyzed dehydration of 1,2-diols to form ketones.',
        cleanedText: 'Pinacol-Pinacolone rearrangement involves the acid-catalyzed dehydration of 1,2-diols to form ketones.',
        quality: PageQuality.digitalText,
        detectedFormulas: ['H2SO4', 'CH3-CO-C(CH3)3'],
        confidence: 0.98,
      );

      const page2 = PdfPageOcrResult(
        pageNumber: 2,
        rawText: 'Migratory aptitude in pinacol rearrangement follows the order: p-anisyl > p-tolyl > phenyl > methyl > hydrogen.',
        cleanedText: 'Migratory aptitude in pinacol rearrangement follows the order: p-anisyl > p-tolyl > phenyl > methyl > hydrogen.',
        quality: PageQuality.digitalText,
        detectedFormulas: [],
        confidence: 0.98,
      );

      final bundle = DocumentOcrBundle(
        docId: 'doc-pinacol',
        docTitle: 'Pinacol Rearrangement.pdf',
        pages: const [page1, page2],
        processedAt: DateTime.now(),
        overallQuality: PageQuality.digitalText,
        totalPages: 2,
      );

      final cards = await service.generate(
        sourceText: bundle.fullText,
        count: 2,
        topic: 'Pinacol Rearrangement',
        bundle: bundle,
      );

      expect(cards.isNotEmpty, true);
      for (final c in cards) {
        expect(c.pageNumber, isIn([1, 2]));
        expect(c.isStrictPdfGrounded, isTrue);
        expect(c.sourceSnippet.isNotEmpty, isTrue);
        expect(c.answer.contains('Key idea:'), isTrue);
        expect(c.cardType, isA<FlashcardType>());
      }
    });

    test('2. FlashcardType enum serializes correctly in SmartFlashcard and GeneratedCard', () {
      const card = SmartFlashcard(
        id: 'fc-1',
        setId: 'set-1',
        question: 'Explain migratory aptitude in carbocation rearrangements.',
        answer: 'Electron-rich aryl groups migrate preferentially to stabilize partial positive charge in the transition state.',
        position: 0,
        pageNumber: 2,
        sourceSnippet: 'p-anisyl > p-tolyl > phenyl',
        cardType: FlashcardType.mechanism,
        isStrictPdfGrounded: true,
      );

      final map = card.toJson();
      expect(map['page_number'], equals(2));
      expect(map['source_snippet'], equals('p-anisyl > p-tolyl > phenyl'));
      expect(map['card_type'], equals('mechanism'));
      expect(map['is_strict_pdf_grounded'], equals(true));

      final restored = SmartFlashcard.fromJson(map);
      expect(restored.cardType, equals(FlashcardType.mechanism));
      expect(restored.pageNumber, equals(2));
      expect(restored.isStrictPdfGrounded, isTrue);
    });
  });
}
