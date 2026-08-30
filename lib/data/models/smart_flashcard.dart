/// UI and persistence states for a Smart Flashcard in a study session.
enum FlashcardUiState {
  unanswered,
  answering,
  submitted,
  revealed,
  easy,
  difficult,
  skipped,
  completed,
}

/// Anki / SM-2 Spaced Repetition card lifecycle states.
enum FlashcardSrState {
  newCard,   // Never reviewed
  learning,  // Currently in short learning steps
  review,    // Graduated to day-based interval reviews
  mature,    // Retained over multiple reviews (interval >= 21 days)
  lapse,     // Previously learned, but forgotten (Again pressed)
}

/// Anki-style 4-button recall rating choices.
enum FlashcardRating {
  again, // 🔴 "I didn't remember"
  hard,  // 🟠 "I remembered, but with difficulty"
  good,  // 🟢 "I remembered normally"
  easy,  // 🔵 "I remembered immediately"
}

enum ReviewMode { all, difficult, skipped, due, newCards, spacedRepetition }

class SmartFlashcardSet {
  const SmartFlashcardSet({
    required this.id,
    required this.title,
    required this.sourceFileName,
    required this.topic,
    required this.cardCount,
    required this.createdAt,
    this.updatedAt,
    this.userId,
  });

  final String id;
  final String? userId;
  final String title;
  final String sourceFileName;
  final String topic;
  final int cardCount;
  final DateTime createdAt;
  final DateTime? updatedAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'title': title,
        'source_file_name': sourceFileName,
        'topic': topic,
        'card_count': cardCount,
        'created_at': createdAt.toIso8601String(),
        'updated_at': (updatedAt ?? createdAt).toIso8601String(),
      };

  factory SmartFlashcardSet.fromJson(Map<String, dynamic> json) => SmartFlashcardSet(
        id: json['id'] as String,
        userId: json['user_id'] as String? ?? json['userId'] as String?,
        title: json['title'] as String? ?? 'Flashcards',
        sourceFileName: (json['source_file_name'] ?? json['sourceFileName'] ?? '') as String,
        topic: json['topic'] as String? ?? '',
        cardCount: json['card_count'] as int? ?? json['cardCount'] as int? ?? 0,
        createdAt: DateTime.tryParse('${json['created_at'] ?? json['createdAt'] ?? ''}') ?? DateTime.now(),
        updatedAt: DateTime.tryParse('${json['updated_at'] ?? json['updatedAt'] ?? ''}'),
      );
}

class SmartFlashcard {
  const SmartFlashcard({
    required this.id,
    required this.setId,
    required this.question,
    required this.answer,
    required this.position,
    this.topic = '',
    this.status = FlashcardUiState.unanswered,
    this.lastUserAnswer = '',
    this.nextReviewAt,
    this.easeFactor = 2.5,
    this.intervalDays = 0,
    this.srState = FlashcardSrState.newCard,
    this.repetitionCount = 0,
    this.lapseCount = 0,
    this.lastReviewedAt,
  });

  final String id;
  final String setId;
  final String question;
  final String answer;
  final String topic;
  final int position;
  final FlashcardUiState status;
  final String lastUserAnswer;
  final DateTime? nextReviewAt;
  final double easeFactor;
  final int intervalDays;
  final FlashcardSrState srState;
  final int repetitionCount;
  final int lapseCount;
  final DateTime? lastReviewedAt;

  bool get isNew => srState == FlashcardSrState.newCard && repetitionCount == 0 && lastReviewedAt == null;
  bool get isLearning => srState == FlashcardSrState.learning || srState == FlashcardSrState.lapse;
  bool get isMature => srState == FlashcardSrState.mature || intervalDays >= 21;
  bool get isDue {
    if (isNew) return false;
    if (nextReviewAt == null) return true;
    return !nextReviewAt!.isAfter(DateTime.now());
  }

  SmartFlashcard copyWith({
    FlashcardUiState? status,
    String? lastUserAnswer,
    DateTime? nextReviewAt,
    double? easeFactor,
    int? intervalDays,
    FlashcardSrState? srState,
    int? repetitionCount,
    int? lapseCount,
    DateTime? lastReviewedAt,
  }) {
    return SmartFlashcard(
      id: id,
      setId: setId,
      question: question,
      answer: answer,
      position: position,
      topic: topic,
      status: status ?? this.status,
      lastUserAnswer: lastUserAnswer ?? this.lastUserAnswer,
      nextReviewAt: nextReviewAt ?? this.nextReviewAt,
      easeFactor: easeFactor ?? this.easeFactor,
      intervalDays: intervalDays ?? this.intervalDays,
      srState: srState ?? this.srState,
      repetitionCount: repetitionCount ?? this.repetitionCount,
      lapseCount: lapseCount ?? this.lapseCount,
      lastReviewedAt: lastReviewedAt ?? this.lastReviewedAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'set_id': setId,
        'question': question,
        'answer': answer,
        'topic': topic,
        'difficulty': status.name,
        'status': status.name,
        'position': position,
        'last_user_answer': lastUserAnswer,
        'next_review_at': nextReviewAt?.toIso8601String(),
        'ease_factor': easeFactor,
        'interval_days': intervalDays,
        'sr_state': srState.name,
        'repetition_count': repetitionCount,
        'lapse_count': lapseCount,
        'last_reviewed_at': lastReviewedAt?.toIso8601String(),
      };

  factory SmartFlashcard.fromJson(Map<String, dynamic> json) {
    final rawStatus = '${json['status'] ?? json['difficulty'] ?? 'unanswered'}';
    final status = FlashcardUiState.values.firstWhere(
      (e) => e.name == rawStatus,
      orElse: () => FlashcardUiState.unanswered,
    );

    final rawSrState = json['sr_state'] as String?;
    FlashcardSrState srState;
    if (rawSrState != null) {
      srState = FlashcardSrState.values.firstWhere(
        (e) => e.name == rawSrState,
        orElse: () => FlashcardSrState.newCard,
      );
    } else {
      // Safe legacy initialization: If it has nextReviewAt and interval > 0, it was reviewed
      final interval = json['interval_days'] as int? ?? 0;
      final nextRev = json['next_review_at'] != null ? DateTime.tryParse('${json['next_review_at']}') : null;
      if (nextRev != null && interval > 0) {
        srState = interval >= 21 ? FlashcardSrState.mature : FlashcardSrState.review;
      } else {
        srState = FlashcardSrState.newCard;
      }
    }

    return SmartFlashcard(
      id: json['id'] as String,
      setId: json['set_id'] as String? ?? json['setId'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      position: json['position'] as int? ?? 0,
      status: status,
      lastUserAnswer: json['last_user_answer'] as String? ?? json['lastUserAnswer'] as String? ?? '',
      nextReviewAt: json['next_review_at'] != null ? DateTime.tryParse('${json['next_review_at']}') : null,
      easeFactor: (json['ease_factor'] as num?)?.toDouble() ?? 2.5,
      intervalDays: json['interval_days'] as int? ?? 0,
      srState: srState,
      repetitionCount: json['repetition_count'] as int? ?? 0,
      lapseCount: json['lapse_count'] as int? ?? 0,
      lastReviewedAt: json['last_reviewed_at'] != null ? DateTime.tryParse('${json['last_reviewed_at']}') : null,
    );
  }
}

class ReviewSchedulePreview {
  const ReviewSchedulePreview({
    required this.againLabel,
    required this.hardLabel,
    required this.goodLabel,
    required this.easyLabel,
  });

  final String againLabel;
  final String hardLabel;
  final String goodLabel;
  final String easyLabel;
}


class FlashcardAttempt {
  const FlashcardAttempt({
    required this.id,
    required this.flashcardId,
    required this.userAnswer,
    required this.selfRating,
    required this.createdAt,
    this.userId,
  });

  final String id;
  final String flashcardId;
  final String? userId;
  final String userAnswer;
  final String selfRating;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
        'id': id,
        'flashcard_id': flashcardId,
        'user_id': userId,
        'user_answer': userAnswer,
        'self_rating': selfRating,
        'created_at': createdAt.toIso8601String(),
      };

  factory FlashcardAttempt.fromJson(Map<String, dynamic> json) => FlashcardAttempt(
        id: json['id'] as String? ?? '',
        flashcardId: (json['flashcard_id'] ?? json['flashcardId'] ?? '') as String,
        userId: json['user_id'] as String? ?? json['userId'] as String?,
        userAnswer: (json['user_answer'] ?? json['userAnswer'] ?? '') as String,
        selfRating: (json['self_rating'] ?? json['selfRating'] ?? '') as String,
        createdAt: DateTime.tryParse('${json['created_at'] ?? json['createdAt'] ?? ''}') ?? DateTime.now(),
      );
}

class StudySession {
  const StudySession({
    required this.id,
    required this.flashcardSetId,
    required this.currentPosition,
    required this.completed,
    required this.startedAt,
    this.userId,
    this.completedAt,
    this.reviewMode = 'all',
  });

  final String id;
  final String? userId;
  final String flashcardSetId;
  final int currentPosition;
  final bool completed;
  final DateTime startedAt;
  final DateTime? completedAt;
  final String reviewMode;

  Map<String, dynamic> toJson() => {
        'id': id,
        'user_id': userId,
        'flashcard_set_id': flashcardSetId,
        'current_position': currentPosition,
        'completed': completed,
        'started_at': startedAt.toIso8601String(),
        'completed_at': completedAt?.toIso8601String(),
        'review_mode': reviewMode,
      };

  factory StudySession.fromJson(Map<String, dynamic> json) => StudySession(
        id: json['id'] as String,
        userId: json['user_id'] as String?,
        flashcardSetId: json['flashcard_set_id'] as String? ?? json['flashcardSetId'] as String? ?? '',
        currentPosition: json['current_position'] as int? ?? 0,
        completed: json['completed'] as bool? ?? false,
        startedAt: DateTime.tryParse('${json['started_at'] ?? ''}') ?? DateTime.now(),
        completedAt: DateTime.tryParse('${json['completed_at'] ?? ''}'),
        reviewMode: json['review_mode'] as String? ?? 'all',
      );
}

class GeneratedCard {
  const GeneratedCard({required this.question, required this.answer, required this.topic});
  final String question;
  final String answer;
  final String topic;
}
