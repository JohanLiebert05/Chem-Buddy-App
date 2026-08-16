class PdfDoc {
  const PdfDoc({
    required this.id,
    required this.filename,
    required this.displayName,
    required this.subjectId,
    required this.localPath,
    required this.dateAdded,
    this.lastOpened,
    this.lastPage = 0,
    this.favorite = false,
    this.fileSize = 0,
  });

  final String id;
  final String filename;
  final String displayName;
  final String subjectId;
  final String localPath;
  final DateTime dateAdded;
  final DateTime? lastOpened;
  final int lastPage;
  final bool favorite;
  final int fileSize;

  PdfDoc copyWith({
    String? displayName,
    String? subjectId,
    String? localPath,
    DateTime? lastOpened,
    int? lastPage,
    bool? favorite,
  }) {
    return PdfDoc(
      id: id,
      filename: filename,
      displayName: displayName ?? this.displayName,
      subjectId: subjectId ?? this.subjectId,
      localPath: localPath ?? this.localPath,
      dateAdded: dateAdded,
      lastOpened: lastOpened ?? this.lastOpened,
      lastPage: lastPage ?? this.lastPage,
      favorite: favorite ?? this.favorite,
      fileSize: fileSize,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'filename': filename,
        'displayName': displayName,
        'subjectId': subjectId,
        'localPath': localPath,
        'dateAdded': dateAdded.toIso8601String(),
        'lastOpened': lastOpened?.toIso8601String(),
        'lastPage': lastPage,
        'favorite': favorite,
        'fileSize': fileSize,
      };

  factory PdfDoc.fromJson(Map<String, dynamic> json) => PdfDoc(
        id: json['id'] as String,
        filename: json['filename'] as String,
        displayName: json['displayName'] as String,
        subjectId: json['subjectId'] as String? ?? 'other',
        localPath: json['localPath'] as String,
        dateAdded: DateTime.parse(json['dateAdded'] as String),
        lastOpened: json['lastOpened'] == null ? null : DateTime.parse(json['lastOpened'] as String),
        lastPage: json['lastPage'] as int? ?? 0,
        favorite: json['favorite'] as bool? ?? false,
        fileSize: json['fileSize'] as int? ?? 0,
      );
}

class FlashcardDraft {
  const FlashcardDraft({
    required this.id,
    required this.question,
    required this.answer,
    required this.updatedAt,
    this.subjectId,
    this.deck = 'Chem Buddy',
    this.tags = const [],
    this.equation = '',
  });

  final String id;
  final String question;
  final String answer;
  final DateTime updatedAt;
  final String? subjectId;
  final String deck;
  final List<String> tags;
  final String equation;

  FlashcardDraft copyWith({
    String? question,
    String? answer,
    DateTime? updatedAt,
    String? subjectId,
    String? deck,
    List<String>? tags,
    String? equation,
  }) {
    return FlashcardDraft(
      id: id,
      question: question ?? this.question,
      answer: answer ?? this.answer,
      updatedAt: updatedAt ?? this.updatedAt,
      subjectId: subjectId ?? this.subjectId,
      deck: deck ?? this.deck,
      tags: tags ?? this.tags,
      equation: equation ?? this.equation,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'question': question,
        'answer': answer,
        'updatedAt': updatedAt.toIso8601String(),
        'subjectId': subjectId,
        'deck': deck,
        'tags': tags,
        'equation': equation,
      };

  factory FlashcardDraft.fromJson(Map<String, dynamic> json) => FlashcardDraft(
        id: json['id'] as String,
        question: json['question'] as String,
        answer: json['answer'] as String,
        updatedAt: DateTime.parse(json['updatedAt'] as String),
        subjectId: json['subjectId'] as String?,
        deck: json['deck'] as String? ?? 'Chem Buddy',
        tags: List<String>.from(json['tags'] as List? ?? const []),
        equation: json['equation'] as String? ?? '',
      );
}

class AppReminder {
  const AppReminder({
    required this.id,
    required this.title,
    required this.when,
    required this.kind,
    this.notes = '',
  });

  final String id;
  final String title;
  final DateTime when;
  final String kind; // assignment | exam | practical | seminar | study
  final String notes;

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'when': when.toIso8601String(),
        'kind': kind,
        'notes': notes,
      };

  factory AppReminder.fromJson(Map<String, dynamic> json) => AppReminder(
        id: json['id'] as String,
        title: json['title'] as String,
        when: DateTime.parse(json['when'] as String),
        kind: json['kind'] as String? ?? 'study',
        notes: json['notes'] as String? ?? '',
      );
}

class NotificationPrefs {
  const NotificationPrefs({
    this.enabled = true,
    this.classReminders = true,
    this.dailyTimetable = false,
    this.assignmentReminders = true,
    this.examReminders = true,
    this.defaultMinutesBefore = 30,
  });

  final bool enabled;
  final bool classReminders;
  final bool dailyTimetable;
  final bool assignmentReminders;
  final bool examReminders;
  final int defaultMinutesBefore;

  NotificationPrefs copyWith({
    bool? enabled,
    bool? classReminders,
    bool? dailyTimetable,
    bool? assignmentReminders,
    bool? examReminders,
    int? defaultMinutesBefore,
  }) {
    return NotificationPrefs(
      enabled: enabled ?? this.enabled,
      classReminders: classReminders ?? this.classReminders,
      dailyTimetable: dailyTimetable ?? this.dailyTimetable,
      assignmentReminders: assignmentReminders ?? this.assignmentReminders,
      examReminders: examReminders ?? this.examReminders,
      defaultMinutesBefore: defaultMinutesBefore ?? this.defaultMinutesBefore,
    );
  }

  Map<String, dynamic> toJson() => {
        'enabled': enabled,
        'classReminders': classReminders,
        'dailyTimetable': dailyTimetable,
        'assignmentReminders': assignmentReminders,
        'examReminders': examReminders,
        'defaultMinutesBefore': defaultMinutesBefore,
      };

  factory NotificationPrefs.fromJson(Map<String, dynamic>? json) {
    if (json == null) return const NotificationPrefs();
    return NotificationPrefs(
      enabled: json['enabled'] as bool? ?? true,
      classReminders: json['classReminders'] as bool? ?? true,
      dailyTimetable: json['dailyTimetable'] as bool? ?? false,
      assignmentReminders: json['assignmentReminders'] as bool? ?? true,
      examReminders: json['examReminders'] as bool? ?? true,
      defaultMinutesBefore: json['defaultMinutesBefore'] as int? ?? 30,
    );
  }
}
