import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/study_analytics_service.dart';

void main() {
  group('StudyAnalyticsService & Topic Mastery Unit Tests', () {
    test('TopicMastery categorizes weak, moderate, and strong topics correctly', () {
      const weak = TopicMastery(
        topic: 'Organic Mechanisms',
        totalQuestions: 10,
        correctQuestions: 5,
        accuracy: 50.0,
      );
      expect(weak.isWeak, isTrue);
      expect(weak.isModerate, isFalse);
      expect(weak.isStrong, isFalse);

      const moderate = TopicMastery(
        topic: 'Coordination Chemistry',
        totalQuestions: 10,
        correctQuestions: 7,
        accuracy: 70.0,
      );
      expect(moderate.isWeak, isFalse);
      expect(moderate.isModerate, isTrue);
      expect(moderate.isStrong, isFalse);

      const strong = TopicMastery(
        topic: 'Spectroscopy',
        totalQuestions: 10,
        correctQuestions: 9,
        accuracy: 90.0,
      );
      expect(strong.isWeak, isFalse);
      expect(strong.isModerate, isFalse);
      expect(strong.isStrong, isTrue);
    });

    test('StudyAnalyticsSummary aggregates overall statistics correctly', () {
      const summary = StudyAnalyticsSummary(
        totalQuestionsAnswered: 45,
        totalCorrectAnswers: 36,
        overallQuizAccuracy: 80.0,
        totalQuizzesTaken: 5,
        flashcardsDueToday: 12,
        flashcardsReviewedToday: 15,
        flashcardsMatureCount: 28,
        flashcardsLearningCount: 6,
        totalFlashcards: 50,
        studyStreakDays: 7,
        weakTopics: [
          TopicMastery(
            topic: 'Pericyclic Reactions',
            totalQuestions: 10,
            correctQuestions: 4,
            accuracy: 40.0,
          ),
        ],
        moderateTopics: [],
        strongTopics: [
          TopicMastery(
            topic: 'NMR Spectroscopy',
            totalQuestions: 20,
            correctQuestions: 18,
            accuracy: 90.0,
          ),
        ],
        recentQuizResults: [],
      );

      expect(summary.totalQuestionsAnswered, equals(45));
      expect(summary.overallQuizAccuracy, equals(80.0));
      expect(summary.studyStreakDays, equals(7));
      expect(summary.weakTopics.length, equals(1));
      expect(summary.weakTopics.first.topic, equals('Pericyclic Reactions'));
      expect(summary.strongTopics.first.topic, equals('NMR Spectroscopy'));
    });
  });
}
