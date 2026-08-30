import 'package:uuid/uuid.dart';
import '../../core/utils/chemistry_text_formatter.dart';

enum TopicPriority { veryHigh, high, medium }

class ImportantTopic {
  const ImportantTopic({
    required this.id,
    required this.title,
    required this.priority,
    required this.explanation,
    this.keyFormulas = const [],
    this.tags = const [],
  });

  final String id;
  final String title;
  final TopicPriority priority;
  final String explanation;
  final List<String> keyFormulas;
  final List<String> tags;

  String get priorityLabel {
    switch (priority) {
      case TopicPriority.veryHigh:
        return 'VERY HIGH PRIORITY';
      case TopicPriority.high:
        return 'HIGH PRIORITY';
      case TopicPriority.medium:
        return 'MEDIUM PRIORITY';
    }
  }

  String get priorityEmoji {
    switch (priority) {
      case TopicPriority.veryHigh:
        return '🔥';
      case TopicPriority.high:
        return '🟠';
      case TopicPriority.medium:
        return '🟡';
    }
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'priority': priority.name,
        'explanation': explanation,
        'key_formulas': keyFormulas,
        'tags': tags,
      };

  factory ImportantTopic.fromJson(Map<String, dynamic> json) {
    final rawPriority = '${json['priority'] ?? 'high'}';
    final priority = TopicPriority.values.firstWhere(
      (e) => e.name.toLowerCase() == rawPriority.toLowerCase(),
      orElse: () => TopicPriority.high,
    );
    return ImportantTopic(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: ChemistryTextFormatter.format(json['title'] as String? ?? 'Chemistry Topic'),
      priority: priority,
      explanation: json['explanation'] as String? ?? '',
      keyFormulas: List<String>.from(json['key_formulas'] as List? ?? const []),
      tags: List<String>.from(json['tags'] as List? ?? const []),
    );
  }
}

class PdfSummary {
  const PdfSummary({
    required this.id,
    required this.docId,
    required this.docName,
    required this.overview,
    required this.coreConcepts,
    required this.definitions,
    required this.reactionsAndEquations,
    required this.keyPoints,
    required this.examFocus,
    required this.quickRevision,
    required this.createdAt,
  });

  final String id;
  final String docId;
  final String docName;
  final String overview;
  final List<String> coreConcepts;
  final List<Map<String, String>> definitions; // term -> definition
  final List<String> reactionsAndEquations;
  final List<String> keyPoints;
  final List<String> examFocus;
  final List<String> quickRevision;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'doc_id': docId,
        'doc_name': docName,
        'overview': overview,
        'core_concepts': coreConcepts,
        'definitions': definitions,
        'reactions_and_equations': reactionsAndEquations,
        'key_points': keyPoints,
        'exam_focus': examFocus,
        'quick_revision': quickRevision,
        'created_at': createdAt.toIso8601String(),
      };

  factory PdfSummary.fromJson(Map<String, dynamic> json) {
    return PdfSummary(
      id: json['id'] as String? ?? const Uuid().v4(),
      docId: json['doc_id'] as String? ?? '',
      docName: json['doc_name'] as String? ?? 'Document',
      overview: json['overview'] as String? ?? '',
      coreConcepts: List<String>.from(json['core_concepts'] as List? ?? const []),
      definitions: (json['definitions'] as List? ?? const [])
          .map((e) => Map<String, String>.from(e as Map))
          .toList(),
      reactionsAndEquations: List<String>.from(json['reactions_and_equations'] as List? ?? const []),
      keyPoints: List<String>.from(json['key_points'] as List? ?? const []),
      examFocus: List<String>.from(json['exam_focus'] as List? ?? const []),
      quickRevision: List<String>.from(json['quick_revision'] as List? ?? const []),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
    );
  }
}

enum QuizQuestionType {
  conceptual,
  reaction,
  mechanism,
  reagent,
  spectroscopy,
  numerical,
  application,
}

class NumericalBreakdown {
  const NumericalBreakdown({
    this.given = '',
    this.formula = '',
    this.calculation = '',
    this.answer = '',
    this.unit = '',
  });

  final String given;
  final String formula;
  final String calculation;
  final String answer;
  final String unit;

  Map<String, dynamic> toJson() => {
        'given': given,
        'formula': formula,
        'calculation': calculation,
        'answer': answer,
        'unit': unit,
      };

  factory NumericalBreakdown.fromJson(Map<String, dynamic> json) {
    return NumericalBreakdown(
      given: json['given'] as String? ?? '',
      formula: json['formula'] as String? ?? '',
      calculation: json['calculation'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      unit: json['unit'] as String? ?? '',
    );
  }
}

class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    required this.type,
    this.topic = 'General Chemistry',
    this.numerical,
  });

  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final QuizQuestionType type;
  final String topic;
  final NumericalBreakdown? numerical;

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correct_index': correctIndex,
        'explanation': explanation,
        'type': type.name,
        'topic': topic,
        if (numerical != null) 'numerical': numerical!.toJson(),
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawType = '${json['type'] ?? 'conceptual'}';
    final type = QuizQuestionType.values.firstWhere(
      (e) => e.name.toLowerCase() == rawType.toLowerCase(),
      orElse: () => QuizQuestionType.conceptual,
    );

    return QuizQuestion(
      id: json['id'] as String? ?? const Uuid().v4(),
      question: ChemistryTextFormatter.format(json['question'] as String? ?? ''),
      options: (json['options'] as List? ?? const [])
          .map((e) => ChemistryTextFormatter.format(e.toString()))
          .toList(),
      correctIndex: json['correct_index'] as int? ?? 0,
      explanation: ChemistryTextFormatter.format(json['explanation'] as String? ?? ''),
      type: type,
      topic: json['topic'] as String? ?? 'General Chemistry',
      numerical: json['numerical'] != null
          ? NumericalBreakdown.fromJson(Map<String, dynamic>.from(json['numerical'] as Map))
          : null,
    );
  }
}

class ChemistryQuiz {
  const ChemistryQuiz({
    required this.id,
    required this.title,
    required this.docId,
    required this.sourceFileName,
    required this.questions,
    required this.createdAt,
  });

  final String id;
  final String title;
  final String docId;
  final String sourceFileName;
  final List<QuizQuestion> questions;
  final DateTime createdAt;

  int get questionCount => questions.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'doc_id': docId,
        'source_file_name': sourceFileName,
        'questions': questions.map((q) => q.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
      };

  factory ChemistryQuiz.fromJson(Map<String, dynamic> json) {
    final rawList = json['questions'] as List? ?? const [];
    return ChemistryQuiz(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Chemistry Quiz',
      docId: json['doc_id'] as String? ?? '',
      sourceFileName: json['source_file_name'] as String? ?? '',
      questions: rawList.map((e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
    );
  }
}

class QuizResult {
  const QuizResult({
    required this.id,
    required this.quizId,
    required this.quizTitle,
    required this.score,
    required this.totalQuestions,
    required this.accuracy,
    required this.weakTopics,
    required this.recommendedRevision,
    required this.userAnswers,
    required this.completedAt,
  });

  final String id;
  final String quizId;
  final String quizTitle;
  final int score;
  final int totalQuestions;
  final double accuracy;
  final List<String> weakTopics;
  final List<String> recommendedRevision;
  final Map<int, int> userAnswers; // question index -> chosen option index
  final DateTime completedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'quiz_id': quizId,
        'quiz_title': quizTitle,
        'score': score,
        'total_questions': totalQuestions,
        'accuracy': accuracy,
        'weak_topics': weakTopics,
        'recommended_revision': recommendedRevision,
        'user_answers': userAnswers.map((k, v) => MapEntry(k.toString(), v)),
        'completed_at': completedAt.toIso8601String(),
      };

  factory QuizResult.fromJson(Map<String, dynamic> json) {
    final rawAnswers = json['user_answers'] as Map? ?? const {};
    final answers = <int, int>{};
    rawAnswers.forEach((k, v) {
      final parsedKey = int.tryParse('$k');
      final parsedVal = int.tryParse('$v');
      if (parsedKey != null && parsedVal != null) {
        answers[parsedKey] = parsedVal;
      }
    });

    return QuizResult(
      id: json['id'] as String? ?? const Uuid().v4(),
      quizId: json['quiz_id'] as String? ?? '',
      quizTitle: json['quiz_title'] as String? ?? 'Quiz',
      score: json['score'] as int? ?? 0,
      totalQuestions: json['total_questions'] as int? ?? 0,
      accuracy: (json['accuracy'] as num?)?.toDouble() ?? 0.0,
      weakTopics: List<String>.from(json['weak_topics'] as List? ?? const []),
      recommendedRevision: List<String>.from(json['recommended_revision'] as List? ?? const []),
      userAnswers: answers,
      completedAt: DateTime.tryParse('${json['completed_at'] ?? ''}') ?? DateTime.now(),
    );
  }
}
