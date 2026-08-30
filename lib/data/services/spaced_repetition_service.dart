import 'dart:math';
import '../models/smart_flashcard.dart';

/// Isolated, deterministic Anki / SM-2 Spaced Repetition Scheduling Engine for ChemBuddy.
class SpacedRepetitionService {
  const SpacedRepetitionService();

  /// Default daily study queue limits
  static const int defaultDailyNewCards = 10;
  static const int defaultDailyReviews = 50;

  /// Calculates the next state and review timestamp for a card given a student's rating.
  SmartFlashcard schedule({
    required SmartFlashcard card,
    required FlashcardRating rating,
    DateTime? now,
  }) {
    final currentTime = now ?? DateTime.now();
    double newEase = card.easeFactor;
    int newInterval = card.intervalDays;
    int newRepetitions = card.repetitionCount;
    int newLapses = card.lapseCount;
    FlashcardSrState newState = card.srState;
    DateTime nextReview;

    final isNewOrLearning = card.isNew || card.isLearning || card.repetitionCount == 0;

    switch (rating) {
      case FlashcardRating.again:
        newLapses += 1;
        newRepetitions = 0;
        newEase = max(1.3, newEase - 0.20);
        newInterval = 0;
        newState = card.isNew ? FlashcardSrState.learning : FlashcardSrState.lapse;
        // Schedule for immediate relearning (< 10 min)
        nextReview = currentTime.add(const Duration(minutes: 10));
        break;

      case FlashcardRating.hard:
        newEase = max(1.3, newEase - 0.15);
        if (isNewOrLearning) {
          newInterval = 1;
          newRepetitions = 1;
          newState = FlashcardSrState.learning;
        } else {
          newInterval = max(1, (newInterval * 1.2).round());
          newRepetitions += 1;
          newState = newInterval >= 21 ? FlashcardSrState.mature : FlashcardSrState.review;
        }
        nextReview = currentTime.add(Duration(days: newInterval));
        break;

      case FlashcardRating.good:
        if (isNewOrLearning) {
          newInterval = card.isNew ? 1 : 3;
          newRepetitions = 1;
          newState = FlashcardSrState.review;
        } else {
          if (newRepetitions == 1) {
            newInterval = 6;
          } else {
            newInterval = max(newInterval + 1, (newInterval * newEase).round());
          }
          newRepetitions += 1;
          newState = newInterval >= 21 ? FlashcardSrState.mature : FlashcardSrState.review;
        }
        nextReview = currentTime.add(Duration(days: newInterval));
        break;

      case FlashcardRating.easy:
        newEase = min(3.0, newEase + 0.15);
        if (isNewOrLearning) {
          newInterval = 4;
          newRepetitions = 1;
          newState = FlashcardSrState.review;
        } else {
          newInterval = max(newInterval + 2, (newInterval * newEase * 1.3).round());
          newRepetitions += 1;
          newState = newInterval >= 21 ? FlashcardSrState.mature : FlashcardSrState.review;
        }
        nextReview = currentTime.add(Duration(days: newInterval));
        break;
    }

    return card.copyWith(
      easeFactor: (newEase * 100).round() / 100, // round to 2 decimal places
      intervalDays: newInterval,
      srState: newState,
      repetitionCount: newRepetitions,
      lapseCount: newLapses,
      lastReviewedAt: currentTime,
      nextReviewAt: nextReview,
    );
  }

  /// Generates real-time preview labels (e.g., "< 10m", "1d", "3d", "8d") for the 4 rating buttons.
  ReviewSchedulePreview calculateSchedulePreview(SmartFlashcard card) {
    return ReviewSchedulePreview(
      againLabel: '< 10m',
      hardLabel: _formatInterval(_calculateInterval(card, FlashcardRating.hard)),
      goodLabel: _formatInterval(_calculateInterval(card, FlashcardRating.good)),
      easyLabel: _formatInterval(_calculateInterval(card, FlashcardRating.easy)),
    );
  }

  int _calculateInterval(SmartFlashcard card, FlashcardRating rating) {
    final isNewOrLearning = card.isNew || card.isLearning || card.repetitionCount == 0;
    switch (rating) {
      case FlashcardRating.again:
        return 0;
      case FlashcardRating.hard:
        if (isNewOrLearning) return 1;
        return max(1, (card.intervalDays * 1.2).round());
      case FlashcardRating.good:
        if (isNewOrLearning) return card.isNew ? 1 : 3;
        if (card.repetitionCount == 1) return 6;
        return max(card.intervalDays + 1, (card.intervalDays * card.easeFactor).round());
      case FlashcardRating.easy:
        if (isNewOrLearning) return 4;
        return max(card.intervalDays + 2, (card.intervalDays * card.easeFactor * 1.3).round());
    }
  }

  String _formatInterval(int days) {
    if (days <= 0) return '< 10m';
    if (days == 1) return '1d';
    if (days < 30) return '${days}d';
    if (days < 365) {
      final months = (days / 30).toStringAsFixed(1).replaceAll('.0', '');
      return '${months}mo';
    }
    final years = (days / 365).toStringAsFixed(1).replaceAll('.0', '');
    return '${years}y';
  }
}
