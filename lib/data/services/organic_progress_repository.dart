import '../local/local_store.dart';

import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';

import '../models/organic_study.dart';

/// Uses the existing account-scoped settings box; adds no startup box or cloud
/// dependency. Capture the box so an old route can never write into a new account.
class OrganicProgressRepository {
  static final completions = ValueNotifier<int>(0);
  OrganicProgressRepository({
    required this.read,
    required this.write,
    bool Function()? currentAccount,
    this.accountChanges,
  }) : currentAccount = currentAccount ?? _always;
  final Object? Function() read;
  final Future<void> Function(Map<String, dynamic>) write;
  final bool Function() currentAccount;
  final Listenable? accountChanges;
  static bool _always() => true;
  factory OrganicProgressRepository.hive() {
    final account = HiveBoxes.activeAccount;
    final box = HiveBoxes.box(HiveBoxes.settings);
    final control = Hive.box(HiveBoxes.accountControl);
    Map<String, dynamic>? lastJournal;
    return OrganicProgressRepository(
      read: () {
        final raw = box.get('organic_study_v1');
        if (raw is! Map) return raw;
        return {
          ...raw,
          'journal':
              box.get('organic_study_journal_v1') ?? raw['journal'] ?? {},
        };
      },
      write: (data) async {
        final journal = Map<String, dynamic>.from(data['journal'] as Map);
        final checkpoint = Map<String, dynamic>.from(data)..remove('journal');
        final updates = <String, dynamic>{'organic_study_v1': checkpoint};
        if (lastJournal == null || !mapEquals(lastJournal, journal)) {
          updates['organic_study_journal_v1'] = journal;
        }
        // Batch related records. Five-second checkpoints do not rewrite the
        // growing journal, keeping native disk work small during animations.
        await box.putAll(updates);
        lastJournal = journal;
      },
      currentAccount: () =>
          account == HiveBoxes.activeAccount &&
          control.get('active') == account,
      accountChanges: control.listenable(keys: ['active']),
    );
  }
  OrganicProgress load() =>
      currentAccount() ? OrganicProgress.decode(read()) : OrganicProgress();
  Future<void> save(OrganicProgress value) {
    if (!currentAccount()) {
      return Future.error(
        StateError('The study account changed. Reopen Study Mode.'),
      );
    }
    return write(value.toJson());
  }

  /// Only a submitted, passed lesson earns completion/streak credit. Replays
  /// update best score without farming XP. Curious never unlocks course levels.
  Future<int> finish(
    OrganicProgress progress,
    OrganicSession session,
    OrganicLesson lesson,
    DateTime now,
  ) async {
    if (session.lesson != lesson.number ||
        session.answers.length != lesson.questions.length ||
        (!session.curious && !progress.unlocked(lesson.number))) {
      throw StateError('Complete the unlocked lesson first.');
    }
    final wrong = <int>[];
    for (var i = 0; i < lesson.questions.length; i++) {
      if (session.answers[i] != lesson.questions[i].answer) wrong.add(i);
    }
    final correct = lesson.questions.length - wrong.length;
    // Commit a copy only after persistence succeeds, so failed writes cannot
    // award progress or streaks in memory.
    final next = OrganicProgress.decode(progress.toJson());
    if (!session.curious) {
      next.mistakes['${lesson.number}'] = {
        ...wrong,
        ...session.confidence.entries
            .where((e) => e.value < 2)
            .map((e) => e.key),
      }.toList()..sort();
    }
    final journalKey =
        '${session.curious ? 'curious' : 'organic'}_${lesson.number}';
    next.journal[journalKey] = {
      'prediction': session.prediction,
      'reflection': session.reflection,
      'date': OrganicProgress.dayKey(now),
      'confidence': session.confidence.map((k, v) => MapEntry('$k', v)),
      'answers': session.answers.map((k, v) => MapEntry('$k', v)),
    };
    if (correct >= 2) {
      if (session.curious) {
        next.discoveries.add(lesson.number);
      } else {
        final previous = next.scores[lesson.number] ?? 0;
        if (correct > previous) next.scores[lesson.number] = correct;
        next.days.add(OrganicProgress.dayKey(now));
      }
    }
    next.session = null;
    await save(next);
    progress.scores
      ..clear()
      ..addAll(next.scores);
    progress.days
      ..clear()
      ..addAll(next.days);
    progress.mistakes
      ..clear()
      ..addAll(next.mistakes);
    progress.discoveries
      ..clear()
      ..addAll(next.discoveries);
    progress.journal
      ..clear()
      ..addAll(next.journal);
    progress.session = null;
    completions.value++;
    return correct;
  }
}
