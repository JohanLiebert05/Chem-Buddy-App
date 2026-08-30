import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/smart_flashcard.dart';
import 'package:chem_buddy/data/services/spaced_repetition_service.dart';

void main() {
  group('SpacedRepetitionService (Anki / SM-2 Engine)', () {
    const scheduler = SpacedRepetitionService();
    final now = DateTime(2026, 8, 30, 10, 0, 0);

    test('1. New card rated Good enters Review state with 1-day interval', () {
      const newCard = SmartFlashcard(
        id: 'c1',
        setId: 's1',
        question: 'What is Aldol condensation?',
        answer: 'Base-catalyzed enolate addition to carbonyl',
        position: 0,
      );

      final scheduled = scheduler.schedule(card: newCard, rating: FlashcardRating.good, now: now);

      expect(scheduled.srState, FlashcardSrState.review);
      expect(scheduled.intervalDays, 1);
      expect(scheduled.repetitionCount, 1);
      expect(scheduled.lastReviewedAt, now);
      expect(scheduled.nextReviewAt, now.add(const Duration(days: 1)));
    });

    test('2. New card rated Again stays in Learning state with short 10m interval', () {
      const newCard = SmartFlashcard(
        id: 'c2',
        setId: 's1',
        question: 'What is Cannizzaro reaction?',
        answer: 'Redox disproportionation of non-enolizable aldehydes',
        position: 1,
      );

      final scheduled = scheduler.schedule(card: newCard, rating: FlashcardRating.again, now: now);

      expect(scheduled.srState, FlashcardSrState.learning);
      expect(scheduled.intervalDays, 0);
      expect(scheduled.repetitionCount, 0);
      expect(scheduled.lapseCount, 1);
      expect(scheduled.nextReviewAt, now.add(const Duration(minutes: 10)));
    });

    test('3. Review card rated Good increases interval progressively', () {
      final reviewCard = SmartFlashcard(
        id: 'c3',
        setId: 's1',
        question: 'What is Diels-Alder reaction?',
        answer: '[4+2] cycloaddition',
        position: 2,
        srState: FlashcardSrState.review,
        intervalDays: 1,
        repetitionCount: 1,
        easeFactor: 2.5,
      );

      final scheduled = scheduler.schedule(card: reviewCard, rating: FlashcardRating.good, now: now);

      expect(scheduled.srState, FlashcardSrState.review);
      expect(scheduled.intervalDays, 6);
      expect(scheduled.repetitionCount, 2);
    });

    test('4. Review card rated Hard gives shorter interval than Good', () {
      final reviewCard = SmartFlashcard(
        id: 'c4',
        setId: 's1',
        question: 'Explain Crystal Field Theory splitting',
        answer: 'Octahedral splits into t2g and eg',
        position: 3,
        srState: FlashcardSrState.review,
        intervalDays: 10,
        repetitionCount: 3,
        easeFactor: 2.5,
      );

      final hardScheduled = scheduler.schedule(card: reviewCard, rating: FlashcardRating.hard, now: now);
      final goodScheduled = scheduler.schedule(card: reviewCard, rating: FlashcardRating.good, now: now);

      expect(hardScheduled.intervalDays, lessThan(goodScheduled.intervalDays));
      expect(hardScheduled.easeFactor, lessThan(reviewCard.easeFactor));
    });

    test('5. Review card rated Easy gives longer interval and increases ease factor', () {
      final reviewCard = SmartFlashcard(
        id: 'c5',
        setId: 's1',
        question: 'Formula for CFSE',
        answer: '[-0.4 * n(t2g) + 0.6 * n(eg)] * delta_o',
        position: 4,
        srState: FlashcardSrState.review,
        intervalDays: 10,
        repetitionCount: 3,
        easeFactor: 2.5,
      );

      final easyScheduled = scheduler.schedule(card: reviewCard, rating: FlashcardRating.easy, now: now);

      expect(easyScheduled.intervalDays, greaterThan(25));
      expect(easyScheduled.easeFactor, 2.65);
      expect(easyScheduled.srState, FlashcardSrState.mature);
    });

    test('6. Mature card rated Again enters Lapse state and resets interval', () {
      final matureCard = SmartFlashcard(
        id: 'c6',
        setId: 's1',
        question: 'NMR chemical shift of TMS',
        answer: '0.0 ppm',
        position: 5,
        srState: FlashcardSrState.mature,
        intervalDays: 30,
        repetitionCount: 5,
        easeFactor: 2.6,
      );

      final scheduled = scheduler.schedule(card: matureCard, rating: FlashcardRating.again, now: now);

      expect(scheduled.srState, FlashcardSrState.lapse);
      expect(scheduled.intervalDays, 0);
      expect(scheduled.repetitionCount, 0);
      expect(scheduled.lapseCount, 1);
      expect(scheduled.easeFactor, 2.4);
    });

    test('7. Preview calculations generate accurate labels', () {
      const newCard = SmartFlashcard(
        id: 'c7',
        setId: 's1',
        question: 'Beckmann rearrangement',
        answer: 'Oxime to amide',
        position: 6,
      );

      final preview = scheduler.calculateSchedulePreview(newCard);

      expect(preview.againLabel, '< 10m');
      expect(preview.hardLabel, '1d');
      expect(preview.goodLabel, '1d');
      expect(preview.easyLabel, '4d');
    });
  });
}
