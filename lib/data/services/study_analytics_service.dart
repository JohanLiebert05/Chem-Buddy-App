import '../local/local_store.dart';
import '../models/pdf_study_models.dart';
import '../models/smart_flashcard.dart';

class TopicMastery {
  final String topic;
  final int totalQuestions;
  final int correctQuestions;
  final double accuracy;

  const TopicMastery({
    required this.topic,
    required this.totalQuestions,
    required this.correctQuestions,
    required this.accuracy,
  });

  bool get isWeak => accuracy < 60.0;
  bool get isModerate => accuracy >= 60.0 && accuracy < 75.0;
  bool get isStrong => accuracy >= 75.0;
}

class StudyAnalyticsSummary {
  final int totalQuestionsAnswered;
  final int totalCorrectAnswers;
  final double overallQuizAccuracy;
  final int totalQuizzesTaken;
  final int flashcardsDueToday;
  final int flashcardsReviewedToday;
  final int flashcardsMatureCount;
  final int flashcardsLearningCount;
  final int totalFlashcards;
  final int studyStreakDays;
  final List<TopicMastery> weakTopics;
  final List<TopicMastery> moderateTopics;
  final List<TopicMastery> strongTopics;
  final List<QuizResult> recentQuizResults;

  const StudyAnalyticsSummary({
    required this.totalQuestionsAnswered,
    required this.totalCorrectAnswers,
    required this.overallQuizAccuracy,
    required this.totalQuizzesTaken,
    required this.flashcardsDueToday,
    required this.flashcardsReviewedToday,
    required this.flashcardsMatureCount,
    required this.flashcardsLearningCount,
    required this.totalFlashcards,
    required this.studyStreakDays,
    required this.weakTopics,
    required this.moderateTopics,
    required this.strongTopics,
    required this.recentQuizResults,
  });
}

class StudyAnalyticsService {
  StudyAnalyticsService(this.store);
  final LocalStore store;

  StudyAnalyticsSummary computeSummary({int streakDays = 0}) {
    final quizResultsJson = store.all(store.quizResults);
    final quizResults = quizResultsJson
        .map((j) => QuizResult.fromJson(j))
        .toList()
      ..sort((a, b) => b.completedAt.compareTo(a.completedAt));

    var totalQuestions = 0;
    var totalCorrect = 0;

    final topicStats = <String, _TopicCounter>{};

    for (final res in quizResults) {
      totalQuestions += res.totalQuestions;
      totalCorrect += res.score;

      // Extract topic performance from questions if available or overall result
      final topicName = res.quizTitle.replaceAll(' Quiz', '').trim();
      final counter = topicStats.putIfAbsent(topicName, () => _TopicCounter());
      counter.total += res.totalQuestions;
      counter.correct += res.score;

      // Also record specific weak topics
      for (final weak in res.weakTopics) {
        if (weak.isNotEmpty) {
          final weakCounter = topicStats.putIfAbsent(weak, () => _TopicCounter());
          weakCounter.weakOccurrences++;
        }
      }
    }

    final overallAccuracy = totalQuestions > 0 ? (totalCorrect / totalQuestions) * 100.0 : 0.0;

    final weakList = <TopicMastery>[];
    final moderateList = <TopicMastery>[];
    final strongList = <TopicMastery>[];

    topicStats.forEach((name, counter) {
      if (counter.total == 0) {
        // If only marked as weak without count
        weakList.add(TopicMastery(
          topic: name,
          totalQuestions: 5,
          correctQuestions: 1,
          accuracy: 20.0,
        ));
      } else {
        final acc = (counter.correct / counter.total) * 100.0;
        final mastery = TopicMastery(
          topic: name,
          totalQuestions: counter.total,
          correctQuestions: counter.correct,
          accuracy: acc,
        );
        if (mastery.isWeak || counter.weakOccurrences > 0) {
          weakList.add(mastery);
        } else if (mastery.isModerate) {
          moderateList.add(mastery);
        } else {
          strongList.add(mastery);
        }
      }
    });

    // Flashcard stats
    final cards = store.all(store.smartCards).map((j) => SmartFlashcard.fromJson(j)).toList();
    final now = DateTime.now();
    final todayStart = DateTime(now.year, now.month, now.day);
    final todayEnd = todayStart.add(const Duration(days: 1));

    var dueCount = 0;
    var reviewedToday = 0;
    var matureCount = 0;
    var learningCount = 0;

    for (final c in cards) {
      if (c.srState == FlashcardSrState.mature) matureCount++;
      if (c.srState == FlashcardSrState.learning || c.srState == FlashcardSrState.lapse) learningCount++;

      if (c.lastReviewedAt != null &&
          c.lastReviewedAt!.isAfter(todayStart) &&
          c.lastReviewedAt!.isBefore(todayEnd)) {
        reviewedToday++;
      }

      if (c.isNew || (c.nextReviewAt != null && c.nextReviewAt!.isBefore(now))) {
        dueCount++;
      }
    }

    return StudyAnalyticsSummary(
      totalQuestionsAnswered: totalQuestions,
      totalCorrectAnswers: totalCorrect,
      overallQuizAccuracy: overallAccuracy,
      totalQuizzesTaken: quizResults.length,
      flashcardsDueToday: dueCount,
      flashcardsReviewedToday: reviewedToday,
      flashcardsMatureCount: matureCount,
      flashcardsLearningCount: learningCount,
      totalFlashcards: cards.length,
      studyStreakDays: streakDays,
      weakTopics: weakList,
      moderateTopics: moderateList,
      strongTopics: strongList,
      recentQuizResults: quizResults.take(5).toList(),
    );
  }
}

class _TopicCounter {
  int total = 0;
  int correct = 0;
  int weakOccurrences = 0;
}
