import 'package:uuid/uuid.dart';

class FrequentTopic {
  final String topic;
  final int appearedCount;
  final String years;
  final String importance; // 'very_high', 'high', 'medium'

  const FrequentTopic({
    required this.topic,
    required this.appearedCount,
    this.years = '',
    required this.importance,
  });

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'appeared_count': appearedCount,
    'years': years,
    'importance': importance,
  };

  factory FrequentTopic.fromJson(Map<String, dynamic> json) => FrequentTopic(
    topic: (json['topic'] as String? ?? 'Core Chemistry').trim(),
    appearedCount: (json['appeared_count'] as num? ?? 1).toInt(),
    years: json['years'] as String? ?? '',
    importance: (json['importance'] as String? ?? 'high').toLowerCase(),
  );
}

class PredictedQuestion {
  final String question;
  final int marks;
  final String questionType; // 'short', 'medium', 'long', 'mechanism'
  final String topic;
  final String importance; // 'very_high', 'high', 'medium'
  final String reason;
  final List<String> modelAnswerHints;

  const PredictedQuestion({
    required this.question,
    required this.marks,
    required this.questionType,
    required this.topic,
    required this.importance,
    this.reason = '',
    this.modelAnswerHints = const [],
  });

  Map<String, dynamic> toJson() => {
    'question': question,
    'marks': marks,
    'question_type': questionType,
    'topic': topic,
    'importance': importance,
    'reason': reason,
    'model_answer_hints': modelAnswerHints,
  };

  factory PredictedQuestion.fromJson(Map<String, dynamic> json) => PredictedQuestion(
    question: (json['question'] as String? ?? '').trim(),
    marks: (json['marks'] as num? ?? 5).toInt(),
    questionType: (json['question_type'] as String? ?? 'medium').toLowerCase(),
    topic: (json['topic'] as String? ?? 'General Chemistry').trim(),
    importance: (json['importance'] as String? ?? 'high').toLowerCase(),
    reason: (json['reason'] as String? ?? '').trim(),
    modelAnswerHints: List<String>.from(
      (json['model_answer_hints'] as List? ?? []).map((e) => e.toString()),
    ),
  );
}

class TopicFrequencySummary {
  final String topic;
  final String frequency; // 'high', 'medium', 'low'
  final String recommendedPriority; // 'Must study', 'Should study', 'Optional'

  const TopicFrequencySummary({
    required this.topic,
    required this.frequency,
    required this.recommendedPriority,
  });

  Map<String, dynamic> toJson() => {
    'topic': topic,
    'frequency': frequency,
    'recommended_priority': recommendedPriority,
  };

  factory TopicFrequencySummary.fromJson(Map<String, dynamic> json) => TopicFrequencySummary(
    topic: (json['topic'] as String? ?? '').trim(),
    frequency: (json['frequency'] as String? ?? 'medium').toLowerCase(),
    recommendedPriority: (json['recommended_priority'] as String? ?? 'Should study').trim(),
  );
}

class ImportantQuestionsPrediction {
  final String id;
  final String subjectName;
  final String universityName;
  final int paperCount;
  final DateTime createdAt;
  final List<FrequentTopic> frequentlyAskedTopics;
  final List<PredictedQuestion> predictedQuestions;
  final List<TopicFrequencySummary> topicFrequencySummary;
  final String examStrategy;
  final bool isCached;

  const ImportantQuestionsPrediction({
    required this.id,
    required this.subjectName,
    required this.universityName,
    required this.paperCount,
    required this.createdAt,
    required this.frequentlyAskedTopics,
    required this.predictedQuestions,
    required this.topicFrequencySummary,
    required this.examStrategy,
    this.isCached = false,
  });

  Map<String, dynamic> toJson() => {
    'id': id,
    'subject_name': subjectName,
    'university_name': universityName,
    'paper_count': paperCount,
    'created_at': createdAt.toIso8601String(),
    'frequently_asked_topics': frequentlyAskedTopics.map((t) => t.toJson()).toList(),
    'predicted_questions': predictedQuestions.map((q) => q.toJson()).toList(),
    'topic_frequency_summary': topicFrequencySummary.map((s) => s.toJson()).toList(),
    'exam_strategy': examStrategy,
    'is_cached': isCached,
  };

  factory ImportantQuestionsPrediction.fromJson(Map<String, dynamic> json) =>
      ImportantQuestionsPrediction(
        id: json['id'] as String? ?? const Uuid().v4(),
        subjectName: json['subject_name'] as String? ?? 'MSc Chemistry',
        universityName: json['university_name'] as String? ?? 'University',
        paperCount: (json['paper_count'] as num? ?? 3).toInt(),
        createdAt: DateTime.tryParse(json['created_at']?.toString() ?? '') ?? DateTime.now(),
        frequentlyAskedTopics: (json['frequently_asked_topics'] as List? ?? [])
            .map((e) => FrequentTopic.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        predictedQuestions: (json['predicted_questions'] as List? ?? [])
            .map((e) => PredictedQuestion.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        topicFrequencySummary: (json['topic_frequency_summary'] as List? ?? [])
            .map((e) => TopicFrequencySummary.fromJson(Map<String, dynamic>.from(e as Map)))
            .toList(),
        examStrategy: json['exam_strategy'] as String? ?? '',
        isCached: json['is_cached'] as bool? ?? false,
      );
}
