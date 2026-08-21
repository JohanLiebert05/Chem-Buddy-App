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

enum ReviewMode { all, difficult, skipped }

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
  });

  final String id;
  final String setId;
  final String question;
  final String answer;
  final String topic;
  final int position;
  final FlashcardUiState status;
  final String lastUserAnswer;

  SmartFlashcard copyWith({
    FlashcardUiState? status,
    String? lastUserAnswer,
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
      };

  factory SmartFlashcard.fromJson(Map<String, dynamic> json) {
    final raw = '${json['status'] ?? json['difficulty'] ?? 'unanswered'}';
    final status = FlashcardUiState.values.firstWhere(
      (e) => e.name == raw,
      orElse: () => FlashcardUiState.unanswered,
    );
    return SmartFlashcard(
      id: json['id'] as String,
      setId: json['set_id'] as String? ?? json['setId'] as String? ?? '',
      question: json['question'] as String? ?? '',
      answer: json['answer'] as String? ?? '',
      topic: json['topic'] as String? ?? '',
      position: json['position'] as int? ?? 0,
      status: status,
      lastUserAnswer: json['last_user_answer'] as String? ?? json['lastUserAnswer'] as String? ?? '',
    );
  }
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
