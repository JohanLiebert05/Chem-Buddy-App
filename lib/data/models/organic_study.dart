/// Offline, versioned teaching content. IDs remain stable when wording changes.
class OrganicQuestion {
  const OrganicQuestion(
    this.prompt,
    this.options,
    this.answer,
    this.explanation,
  );
  final String prompt;
  final List<String> options;
  final int answer;
  final String explanation;
}

class OrganicLesson {
  const OrganicLesson({
    required this.number,
    required this.chapter,
    required this.title,
    required this.hook,
    required this.simple,
    required this.reasoning,
    required this.advanced,
    required this.example,
    required this.diagram,
    required this.questions,
    this.mechanism,
  });
  final int number;
  final String chapter,
      title,
      hook,
      simple,
      reasoning,
      advanced,
      example,
      diagram;
  final String? mechanism;
  final List<OrganicQuestion> questions;
  String get id => 'organic_${number.toString().padLeft(2, '0')}';
}

enum StudyLength {
  five(5),
  ten(10),
  fifteen(15),
  twenty(20);

  const StudyLength(this.minutes);
  final int minutes;
  int get learnSeconds => minutes * 36;
  int get practiseSeconds => minutes * 24;
  static StudyLength decode(Object? value) =>
      values.firstWhere((v) => v.minutes == value, orElse: () => five);
}

class OrganicSession {
  OrganicSession({
    required this.lesson,
    required this.minutes,
    this.curious = false,
    this.phase = 0,
    this.section = 0,
    this.learnSeconds = 0,
    this.practiceSeconds = 0,
    Map<int, int>? answers,
    Map<int, int>? confidence,
    this.reflection = '',
    this.prediction = '',
    this.questionIndex = 0,
  }) : answers = answers ?? {},
       confidence = confidence ?? {};
  final int lesson, minutes;
  final bool curious;
  int phase, section, learnSeconds, practiceSeconds, questionIndex;
  String reflection, prediction;
  final Map<int, int> answers;
  final Map<int, int> confidence;
  Map<String, dynamic> toJson() => {
    'lesson': lesson,
    'minutes': minutes,
    'curious': curious,
    'phase': phase,
    'section': section,
    'learn': learnSeconds,
    'practice': practiceSeconds,
    'reflection': reflection,
    'prediction': prediction,
    'questionIndex': questionIndex,
    'confidence': confidence.map((k, v) => MapEntry('$k', v)),
    'answers': answers.map((k, v) => MapEntry('$k', v)),
  };
  static OrganicSession? decode(Object? value) {
    if (value is! Map ||
        value['lesson'] is! int ||
        value['lesson'] < 1 ||
        value['lesson'] > 60 ||
        ![5, 10, 15, 20].contains(value['minutes'])) {
      return null;
    }
    int bounded(String key, int max) =>
        value[key] is int ? (value[key] as int).clamp(0, max) : 0;
    final answers = <int, int>{};
    if (value['answers'] is Map) {
      for (final entry in (value['answers'] as Map).entries) {
        final key = int.tryParse('${entry.key}');
        if (key != null &&
            key >= 0 &&
            key < 3 &&
            entry.value is int &&
            entry.value >= 0 &&
            entry.value < 3) {
          answers[key] = entry.value;
        }
      }
    }
    return OrganicSession(
      lesson: value['lesson'],
      minutes: value['minutes'],
      curious: value['curious'] == true,
      phase: bounded('phase', 1),
      section: bounded('section', 5),
      learnSeconds: bounded('learn', 86400),
      practiceSeconds: bounded('practice', 86400),
      answers: answers,
      confidence: decodeChoices(value['confidence']),
      prediction: studyText(value['prediction']),
      questionIndex: bounded('questionIndex', 2),
      reflection: value['reflection'] is String
          ? (value['reflection'] as String).substring(
              0,
              (value['reflection'] as String).length.clamp(0, 4000),
            )
          : '',
    );
  }
}

class OrganicProgress {
  OrganicProgress({
    Map<int, int>? scores,
    Map<String, List<int>>? mistakes,
    Set<String>? days,
    Set<int>? discoveries,
    this.session,
    this.activeSeconds = 0,
    this.preferredMinutes = 5,
    this.nextClue = '',
    Map<String, Map<String, dynamic>>? journal,
  }) : scores = scores ?? {},
       mistakes = mistakes ?? {},
       days = days ?? {},
       discoveries = discoveries ?? {},
       journal = journal ?? {};
  final Map<int, int> scores;
  final Map<String, List<int>> mistakes;
  final Set<String> days;
  final Set<int> discoveries;
  OrganicSession? session;
  int activeSeconds, preferredMinutes;
  String nextClue;
  final Map<String, Map<String, dynamic>> journal;

  /// A checkpoint copies the small mutable session, not every saved explanation.
  /// Journal records are replaced at completion or on edits, not mutated in place.
  OrganicProgress snapshot() => OrganicProgress(
    scores: Map.of(scores),
    mistakes: mistakes.map((key, value) => MapEntry(key, List.of(value))),
    days: Set.of(days),
    discoveries: Set.of(discoveries),
    session: OrganicSession.decode(session?.toJson()),
    activeSeconds: activeSeconds,
    preferredMinutes: preferredMinutes,
    nextClue: nextClue,
    journal: Map.of(journal),
  );
  int get completed => scores.length;
  int get xp =>
      scores.values.fold(0, (sum, correct) => sum + 40 + correct * 10);
  bool unlocked(int number) => number == 1 || scores.containsKey(number - 1);
  int get nextLevel {
    for (var i = 1; i <= 60; i++) {
      if (!scores.containsKey(i)) return i;
    }
    return 60;
  }

  static String dayKey(DateTime date) =>
      '${date.year.toString().padLeft(4, '0')}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
  int streak(DateTime today) {
    var date = DateTime(today.year, today.month, today.day);
    if (!days.contains(dayKey(date))) {
      date = DateTime(date.year, date.month, date.day - 1);
    }
    var count = 0;
    while (days.contains(dayKey(date))) {
      count++;
      date = DateTime(date.year, date.month, date.day - 1);
    }
    return count;
  }

  Map<String, dynamic> toJson() => {
    'version': 1,
    'scores': scores.map((k, v) => MapEntry('$k', v)),
    'mistakes': mistakes,
    'days': days.toList()..sort(),
    'discoveries': discoveries.toList()..sort(),
    'session': session?.toJson(),
    'activeSeconds': activeSeconds,
    'preferredMinutes': preferredMinutes,
    'nextClue': nextClue,
    'journal': journal,
  };
  factory OrganicProgress.decode(Object? value) {
    if (value is! Map || value['version'] != 1) return OrganicProgress();
    final result = OrganicProgress(
      session: OrganicSession.decode(value['session']),
      preferredMinutes: StudyLength.decode(value['preferredMinutes']).minutes,
      nextClue: studyText(value['nextClue'], max: 500),
      activeSeconds: value['activeSeconds'] is int
          ? (value['activeSeconds'] as int).clamp(0, 100000000)
          : 0,
    );
    if (value['scores'] is Map) {
      for (final entry in (value['scores'] as Map).entries) {
        final n = int.tryParse('${entry.key}');
        if (n != null &&
            n >= 1 &&
            n <= 60 &&
            entry.value is int &&
            entry.value >= 2 &&
            entry.value <= 3) {
          result.scores[n] = entry.value;
        }
      }
    }
    if (value['days'] is List) {
      for (final day in value['days']) {
        if (day is String &&
            RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(day) &&
            DateTime.tryParse(day) != null) {
          result.days.add(day);
        }
      }
    }
    if (value['discoveries'] is List) {
      result.discoveries.addAll(
        (value['discoveries'] as List).whereType<int>().where(
          (n) => n >= 1 && n <= 60,
        ),
      );
    }
    if (value['mistakes'] is Map) {
      for (final e in (value['mistakes'] as Map).entries) {
        final n = int.tryParse('${e.key}');
        if (n != null && n >= 1 && n <= 60 && e.value is List) {
          result.mistakes['$n'] = (e.value as List)
              .whereType<int>()
              .where((q) => q >= 0 && q < 3)
              .toSet()
              .toList();
        }
      }
    }
    if (value['journal'] is Map) {
      for (final e in (value['journal'] as Map).entries) {
        if (e.key is! String ||
            !RegExp(r'^(organic|curious)_([1-9]|[1-5][0-9]|60)$')
                .hasMatch(e.key) ||
            e.value is! Map) {
          continue;
        }
        final record = e.value as Map;
        result.journal[e.key] = {
          'prediction': studyText(record['prediction']),
          'reflection': studyText(record['reflection']),
          'date': studyText(record['date'], max: 10),
          'confidence': decodeChoices(record['confidence'])
              .map((k, v) => MapEntry('$k', v)),
          'answers': decodeChoices(record['answers'])
              .map((k, v) => MapEntry('$k', v)),
        };
      }
    }
    return result;
  }
}

String studyText(Object? value, {int max = 4000}) =>
    value is String ? value.substring(0, value.length.clamp(0, max)) : '';
Map<int, int> decodeChoices(Object? value) {
  final result = <int, int>{};
  if (value is Map) {
    for (final e in value.entries) {
      final key = int.tryParse('${e.key}');
      if (key != null &&
          key >= 0 &&
          key < 3 &&
          e.value is int &&
          e.value >= 0 &&
          e.value < 3) {
        result[key] = e.value;
      }
    }
  }
  return result;
}
