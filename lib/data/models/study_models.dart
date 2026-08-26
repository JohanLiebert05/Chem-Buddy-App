class DailyFocus {
  const DailyFocus({
    required this.subjectName,
    this.subjectId,
    required this.reason,
    required this.recommendedMinutes,
    required this.flashcardsDue,
    this.upcomingTestTitle,
    this.upcomingTestDate,
  });

  final String subjectName;
  final String? subjectId;
  final String reason;
  final int recommendedMinutes;
  final int flashcardsDue;
  final String? upcomingTestTitle;
  final DateTime? upcomingTestDate;

  Map<String, dynamic> toJson() => {
        'subject_name': subjectName,
        'subject_id': subjectId,
        'reason': reason,
        'recommended_minutes': recommendedMinutes,
        'flashcards_due': flashcardsDue,
        'upcoming_test_title': upcomingTestTitle,
        'upcoming_test_date': upcomingTestDate?.toIso8601String(),
      };

  factory DailyFocus.fromJson(Map<String, dynamic> json) => DailyFocus(
        subjectName: json['subject_name'] as String? ?? '',
        subjectId: json['subject_id'] as String?,
        reason: json['reason'] as String? ?? '',
        recommendedMinutes: json['recommended_minutes'] as int? ?? 0,
        flashcardsDue: json['flashcards_due'] as int? ?? 0,
        upcomingTestTitle: json['upcoming_test_title'] as String?,
        upcomingTestDate: DateTime.tryParse('${json['upcoming_test_date'] ?? ''}'),
      );
}

enum StudyStepType { revision, flashcards, quiz, reading }

class StudyStep {
  const StudyStep({
    required this.title,
    required this.description,
    required this.durationMinutes,
    required this.type,
    this.resourceId,
    this.completed = false,
  });

  final String title;
  final String description;
  final int durationMinutes;
  final StudyStepType type;
  final String? resourceId;
  final bool completed;

  Map<String, dynamic> toJson() => {
        'title': title,
        'description': description,
        'duration_minutes': durationMinutes,
        'type': type.name,
        'resource_id': resourceId,
        'completed': completed,
      };

  factory StudyStep.fromJson(Map<String, dynamic> json) {
    final rawType = '${json['type'] ?? 'revision'}';
    final type = StudyStepType.values.firstWhere(
      (e) => e.name == rawType,
      orElse: () => StudyStepType.revision,
    );
    return StudyStep(
      title: json['title'] as String? ?? '',
      description: json['description'] as String? ?? '',
      durationMinutes: json['duration_minutes'] as int? ?? 0,
      type: type,
      resourceId: json['resource_id'] as String?,
      completed: json['completed'] as bool? ?? false,
    );
  }
}

class StudyPlan {
  const StudyPlan({
    required this.id,
    required this.steps,
    required this.totalMinutes,
    required this.createdAt,
    this.subjectFocus,
  });

  final String id;
  final List<StudyStep> steps;
  final int totalMinutes;
  final DateTime createdAt;
  final String? subjectFocus;

  Map<String, dynamic> toJson() => {
        'id': id,
        'steps': steps.map((s) => s.toJson()).toList(),
        'total_minutes': totalMinutes,
        'created_at': createdAt.toIso8601String(),
        'subject_focus': subjectFocus,
      };

  factory StudyPlan.fromJson(Map<String, dynamic> json) {
    final rawSteps = json['steps'] as List<dynamic>? ?? [];
    return StudyPlan(
      id: json['id'] as String? ?? '',
      steps: rawSteps.map((s) => StudyStep.fromJson(Map<String, dynamic>.from(s as Map))).toList(),
      totalMinutes: json['total_minutes'] as int? ?? 0,
      createdAt: DateTime.tryParse('${json['created_at'] ?? ''}') ?? DateTime.now(),
      subjectFocus: json['subject_focus'] as String?,
    );
  }
}
