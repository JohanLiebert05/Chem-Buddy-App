import 'dart:math';

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
    this.pageNumber,
    this.sourceSnippet,
  });

  final String id;
  final String title;
  final TopicPriority priority;
  final String explanation;
  final List<String> keyFormulas;
  final List<String> tags;
  final int? pageNumber;
  final String? sourceSnippet;

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
        if (pageNumber != null) 'page_number': pageNumber,
        if (sourceSnippet != null) 'source_snippet': sourceSnippet,
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
      pageNumber: json['page_number'] as int?,
      sourceSnippet: json['source_snippet'] as String?,
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

enum QuizDifficulty {
  easy,
  medium,
  hard,
  mixed;

  String get label {
    switch (this) {
      case QuizDifficulty.easy:
        return 'Easy';
      case QuizDifficulty.medium:
        return 'Medium';
      case QuizDifficulty.hard:
        return 'Hard';
      case QuizDifficulty.mixed:
        return 'Mixed';
    }
  }

  String get description {
    switch (this) {
      case QuizDifficulty.easy:
        return 'Foundational recall & core definitions';
      case QuizDifficulty.medium:
        return 'Conceptual understanding & mechanisms';
      case QuizDifficulty.hard:
        return 'Multi-step synthesis, calculations & advanced analysis';
      case QuizDifficulty.mixed:
        return 'Balanced (30% Easy, 50% Medium, 20% Hard)';
    }
  }
}

enum QuizMode {
  smartQuiz,
  importantTopics,
  custom,
  weakTopics;

  String get label {
    switch (this) {
      case QuizMode.smartQuiz:
        return '✨ Smart Quiz';
      case QuizMode.importantTopics:
        return '🔥 Important Questions';
      case QuizMode.custom:
        return '⚙️ Custom';
      case QuizMode.weakTopics:
        return '🎯 Practice Weak Topics';
    }
  }

  String get description {
    switch (this) {
      case QuizMode.smartQuiz:
        return 'Auto-tuned to PDF content, density, and chemistry domain';
      case QuizMode.importantTopics:
        return 'Focuses on high-priority exam and core concepts';
      case QuizMode.custom:
        return 'Manually customize question counts, difficulty, and types';
      case QuizMode.weakTopics:
        return 'Targeted practice from this PDF on previously missed topics';
    }
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
  trueFalse,
  fillInBlank;

  String get label {
    switch (this) {
      case QuizQuestionType.conceptual:
        return 'Conceptual';
      case QuizQuestionType.reaction:
        return 'Reaction';
      case QuizQuestionType.mechanism:
        return 'Mechanism';
      case QuizQuestionType.reagent:
        return 'Reagent';
      case QuizQuestionType.spectroscopy:
        return 'Spectroscopy';
      case QuizQuestionType.numerical:
        return 'Numerical';
      case QuizQuestionType.application:
        return 'Application';
      case QuizQuestionType.trueFalse:
        return 'True / False';
      case QuizQuestionType.fillInBlank:
        return 'Fill in Blank';
    }
  }
}

class PdfQuizConfig {
  const PdfQuizConfig({
    this.count = 10,
    this.difficulty = QuizDifficulty.mixed,
    this.questionTypes = const {
      QuizQuestionType.conceptual,
      QuizQuestionType.reaction,
      QuizQuestionType.mechanism,
      QuizQuestionType.spectroscopy,
      QuizQuestionType.numerical,
    },
    this.mode = QuizMode.smartQuiz,
    this.targetedTopics = const [],
  });

  final int count;
  final QuizDifficulty difficulty;
  final Set<QuizQuestionType> questionTypes;
  final QuizMode mode;
  final List<String> targetedTopics;

  PdfQuizConfig copyWith({
    int? count,
    QuizDifficulty? difficulty,
    Set<QuizQuestionType>? questionTypes,
    QuizMode? mode,
    List<String>? targetedTopics,
  }) {
    return PdfQuizConfig(
      count: count ?? this.count,
      difficulty: difficulty ?? this.difficulty,
      questionTypes: questionTypes ?? this.questionTypes,
      mode: mode ?? this.mode,
      targetedTopics: targetedTopics ?? this.targetedTopics,
    );
  }
}

class PdfConceptItem {
  const PdfConceptItem({
    required this.concept,
    required this.importance,
    this.pageNumber,
    this.summary,
  });

  final String concept;
  final String importance; // 'high', 'medium', 'low'
  final int? pageNumber;
  final String? summary;

  Map<String, dynamic> toJson() => {
        'concept': concept,
        'importance': importance,
        if (pageNumber != null) 'page_number': pageNumber,
        if (summary != null) 'summary': summary,
      };

  factory PdfConceptItem.fromJson(Map<String, dynamic> json) => PdfConceptItem(
        concept: ChemistryTextFormatter.format(json['concept'] as String? ?? ''),
        importance: json['importance'] as String? ?? 'medium',
        pageNumber: json['page_number'] as int?,
        summary: json['summary'] as String?,
      );
}

class PdfDocumentAnalysis {
  const PdfDocumentAnalysis({
    required this.docId,
    required this.docTitle,
    required this.detectedSubject,
    required this.coreTopics,
    this.reactionsAndReagents = const [],
    this.equationsAndFormulas = const [],
    this.keyDefinitions = const [],
    this.pageTopicMap = const {},
  });

  final String docId;
  final String docTitle;
  final String detectedSubject;
  final List<PdfConceptItem> coreTopics;
  final List<String> reactionsAndReagents;
  final List<String> equationsAndFormulas;
  final List<Map<String, String>> keyDefinitions;
  final Map<int, List<String>> pageTopicMap;

  List<PdfConceptItem> get highPriorityTopics =>
      coreTopics.where((c) => c.importance.toLowerCase() == 'high').toList();

  Map<String, dynamic> toJson() => {
        'doc_id': docId,
        'doc_title': docTitle,
        'detected_subject': detectedSubject,
        'core_topics': coreTopics.map((c) => c.toJson()).toList(),
        'reactions_and_reagents': reactionsAndReagents,
        'equations_and_formulas': equationsAndFormulas,
        'key_definitions': keyDefinitions,
        'page_topic_map': pageTopicMap.map((k, v) => MapEntry(k.toString(), v)),
      };

  factory PdfDocumentAnalysis.fromJson(Map<String, dynamic> json) {
    final rawTopics = json['core_topics'] as List? ?? const [];
    final rawDefs = json['key_definitions'] as List? ?? const [];
    final rawPageMap = json['page_topic_map'] as Map? ?? const {};

    final pageTopicMap = <int, List<String>>{};
    rawPageMap.forEach((k, v) {
      final page = int.tryParse('$k');
      if (page != null && v is List) {
        pageTopicMap[page] = v.map((e) => e.toString()).toList();
      }
    });

    return PdfDocumentAnalysis(
      docId: json['doc_id'] as String? ?? '',
      docTitle: json['doc_title'] as String? ?? 'Document',
      detectedSubject: json['detected_subject'] as String? ?? 'Chemistry',
      coreTopics: rawTopics.map((e) => PdfConceptItem.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      reactionsAndReagents: List<String>.from(json['reactions_and_reagents'] as List? ?? const []),
      equationsAndFormulas: List<String>.from(json['equations_and_formulas'] as List? ?? const []),
      keyDefinitions: rawDefs.map((e) => Map<String, String>.from(e as Map)).toList(),
      pageTopicMap: pageTopicMap,
    );
  }
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
    this.difficulty = QuizDifficulty.medium,
    this.numerical,
    this.pageNumber,
    this.sourceSnippet,
    this.isStrictPdfGrounded = false,
  });

  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  final QuizQuestionType type;
  final String topic;
  final QuizDifficulty difficulty;
  final NumericalBreakdown? numerical;
  final int? pageNumber;
  final String? sourceSnippet;
  final bool isStrictPdfGrounded;

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'options': options,
        'correct_index': correctIndex,
        'explanation': explanation,
        'type': type.name,
        'topic': topic,
        'difficulty': difficulty.name,
        if (numerical != null) 'numerical': numerical!.toJson(),
        if (pageNumber != null) 'page_number': pageNumber,
        if (sourceSnippet != null) 'source_snippet': sourceSnippet,
        'is_strict_pdf_grounded': isStrictPdfGrounded,
      };

  factory QuizQuestion.fromJson(Map<String, dynamic> json) {
    final rawType = '${json['type'] ?? 'conceptual'}';
    final type = QuizQuestionType.values.firstWhere(
      (e) => e.name.toLowerCase() == rawType.toLowerCase(),
      orElse: () => QuizQuestionType.conceptual,
    );

    final rawDiff = '${json['difficulty'] ?? 'medium'}';
    final difficulty = QuizDifficulty.values.firstWhere(
      (e) => e.name.toLowerCase() == rawDiff.toLowerCase(),
      orElse: () => QuizDifficulty.medium,
    );

    var optionsList = <String>[];
    if (json['options'] is List) {
      optionsList = (json['options'] as List)
          .map((e) => ChemistryTextFormatter.format(e.toString().trim()))
          .where((e) => e.isNotEmpty)
          .toList();
    } else if (json['options'] is Map) {
      final map = json['options'] as Map;
      final keys = ['A', 'B', 'C', 'D', 'a', 'b', 'c', 'd', '1', '2', '3', '4'];
      for (final k in keys) {
        if (map.containsKey(k) && map[k] != null) {
          final val = ChemistryTextFormatter.format(map[k].toString().trim());
          if (val.isNotEmpty && !optionsList.contains(val)) {
            optionsList.add(val);
          }
        }
      }
      if (optionsList.isEmpty) {
        optionsList = map.values.map((v) => ChemistryTextFormatter.format(v.toString().trim())).toList();
      }
    }

    var correctIdx = 0;
    if (json['correct_index'] is int) {
      correctIdx = (json['correct_index'] as int).clamp(0, max(0, optionsList.length - 1));
    } else if (json['correctAnswer'] != null || json['correct_answer'] != null) {
      final rawCorrect = '${json['correctAnswer'] ?? json['correct_answer']}'.trim().toUpperCase();
      if (rawCorrect == 'A' || rawCorrect == '0') {
        correctIdx = 0;
      } else if (rawCorrect == 'B' || rawCorrect == '1') {
        correctIdx = 1;
      } else if (rawCorrect == 'C' || rawCorrect == '2') {
        correctIdx = 2;
      } else if (rawCorrect == 'D' || rawCorrect == '3') {
        correctIdx = 3;
      } else {
        final found = optionsList.indexWhere((o) => o.toLowerCase() == rawCorrect.toLowerCase());
        if (found != -1) correctIdx = found;
      }
    }

    return QuizQuestion(
      id: json['id'] as String? ?? const Uuid().v4(),
      question: ChemistryTextFormatter.format(json['question'] as String? ?? ''),
      options: optionsList,
      correctIndex: correctIdx,
      explanation: ChemistryTextFormatter.format(json['explanation'] as String? ?? ''),
      type: type,
      topic: json['topic'] as String? ?? 'General Chemistry',
      difficulty: difficulty,
      numerical: json['numerical'] != null
          ? NumericalBreakdown.fromJson(Map<String, dynamic>.from(json['numerical'] as Map))
          : null,
      pageNumber: json['page_number'] as int?,
      sourceSnippet: json['source_snippet'] as String?,
      isStrictPdfGrounded: json['is_strict_pdf_grounded'] as bool? ?? false,
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
    this.isStrictPdfGrounded = false,
    this.pageRange,
    this.difficulty = QuizDifficulty.mixed,
    this.mode = QuizMode.smartQuiz,
  });

  final String id;
  final String title;
  final String docId;
  final String sourceFileName;
  final List<QuizQuestion> questions;
  final DateTime createdAt;
  final bool isStrictPdfGrounded;
  final String? pageRange;
  final QuizDifficulty difficulty;
  final QuizMode mode;

  int get questionCount => questions.length;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'doc_id': docId,
        'source_file_name': sourceFileName,
        'questions': questions.map((q) => q.toJson()).toList(),
        'created_at': createdAt.toIso8601String(),
        'is_strict_pdf_grounded': isStrictPdfGrounded,
        if (pageRange != null) 'page_range': pageRange,
        'difficulty': difficulty.name,
        'mode': mode.name,
      };

  factory ChemistryQuiz.fromJson(Map<String, dynamic> json) {
    final rawList = json['questions'] as List? ?? const [];
    final rawDiff = '${json['difficulty'] ?? 'mixed'}';
    final diff = QuizDifficulty.values.firstWhere(
      (e) => e.name.toLowerCase() == rawDiff.toLowerCase(),
      orElse: () => QuizDifficulty.mixed,
    );
    final rawMode = '${json['mode'] ?? 'smartQuiz'}';
    final mode = QuizMode.values.firstWhere(
      (e) => e.name.toLowerCase() == rawMode.toLowerCase(),
      orElse: () => QuizMode.smartQuiz,
    );

    return ChemistryQuiz(
      id: json['id'] as String? ?? const Uuid().v4(),
      title: json['title'] as String? ?? 'Chemistry Quiz',
      docId: json['doc_id'] as String? ?? '',
      sourceFileName: json['source_file_name'] as String? ?? '',
      questions: rawList.map((e) => QuizQuestion.fromJson(Map<String, dynamic>.from(e as Map))).toList(),
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      isStrictPdfGrounded: json['is_strict_pdf_grounded'] as bool? ?? false,
      pageRange: json['page_range'] as String?,
      difficulty: diff,
      mode: mode,
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

enum MasteryLevel {
  strong,   // > 75%
  moderate, // 50% - 75%
  weak,     // < 50%
}

extension MasteryLevelExtension on MasteryLevel {
  String get label {
    switch (this) {
      case MasteryLevel.strong:
        return 'Strong 🟢';
      case MasteryLevel.moderate:
        return 'Moderate 🟡';
      case MasteryLevel.weak:
        return 'Weak 🔴';
    }
  }
}

class TopicMastery {
  final String topicName;
  final int totalQuestions;
  final int correctCount;
  final double accuracy;
  final MasteryLevel level;

  const TopicMastery({
    required this.topicName,
    required this.totalQuestions,
    required this.correctCount,
    required this.accuracy,
    required this.level,
  });

  factory TopicMastery.fromStats({
    required String topicName,
    required int totalQuestions,
    required int correctCount,
  }) {
    final accuracy = totalQuestions > 0 ? (correctCount / totalQuestions) * 100 : 0.0;
    MasteryLevel level;
    if (accuracy >= 75) {
      level = MasteryLevel.strong;
    } else if (accuracy >= 50) {
      level = MasteryLevel.moderate;
    } else {
      level = MasteryLevel.weak;
    }

    return TopicMastery(
      topicName: topicName,
      totalQuestions: totalQuestions,
      correctCount: correctCount,
      accuracy: accuracy,
      level: level,
    );
  }
}

