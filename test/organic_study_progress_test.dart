import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/organic_study.dart';
import 'package:chem_buddy/data/services/organic_curriculum.dart';
import 'package:chem_buddy/data/services/organic_diagrams.dart';
import 'package:chem_buddy/data/services/organic_progress_repository.dart';

Map<String, dynamic> copy(Map<String, dynamic> value) =>
    jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
OrganicSession answered(int number, {int correct = 3, bool curious = false}) {
  final lesson = organicLessons[number - 1];
  return OrganicSession(
    lesson: number,
    minutes: 5,
    curious: curious,
    answers: {
      for (var i = 0; i < 3; i++)
        i: i < correct
            ? lesson.questions[i].answer
            : (lesson.questions[i].answer + 1) % 3,
    },
  );
}

void main() {
  test(
    'queued checkpoints keep stable answers and records as editing continues',
    () {
      final p = OrganicProgress(
        journal: {
          'organic_1': {'reflection': 'Earlier explanation'},
        },
        session: OrganicSession(lesson: 2, minutes: 5, answers: {0: 1}),
      );
      final snapshot = p.snapshot();
      p.session!.answers[0] = 2;
      p.journal['organic_1'] = {'reflection': 'Revised explanation'};
      expect(snapshot.session!.answers[0], 1);
      expect(
        snapshot.journal['organic_1']!['reflection'],
        'Earlier explanation',
      );
    },
  );
  test('a correct guess earns its score but returns for review, with the student’s reasoning saved', () async {
    Map<String, dynamic>? disk;
    final repo = OrganicProgressRepository(
      read: () => disk,
      write: (value) async {
        disk = copy(value);
      },
    );
    final p = repo.load()..nextClue = 'Look at the electron source.';
    final session = answered(1)
      ..prediction = 'Carbon can connect four groups.'
      ..reflection = 'Four shared pairs account for the bonds.';
    session.confidence[0] = 0;
    await repo.finish(p, session, organicLessons.first, DateTime(2026, 11, 3));
    final restored = repo.load();
    expect(restored.scores[1], 3);
    expect(restored.mistakes['1'], [0]);
    expect(restored.journal['organic_1']!['prediction'], session.prediction);
    expect(restored.journal['organic_1']!['reflection'], session.reflection);
    expect(restored.journal['organic_1']!['confidence'], {'0': 0});
    expect(restored.nextClue, 'Look at the electron source.');
  });
  test('Curious mistakes stay separate from the course review list', () async {
    Map<String, dynamic>? disk;
    final repo = OrganicProgressRepository(
      read: () => disk,
      write: (value) async {
        disk = copy(value);
      },
    );
    final p = repo.load();
    await repo.finish(
      p,
      answered(31, correct: 0, curious: true),
      organicLessons[30],
      DateTime(2026, 11, 3),
    );
    expect(p.mistakes, isEmpty);
    expect(p.journal.containsKey('curious_31'), true);
  });
  test('60 stable levels, 12 chapters, complete explanations and 180 unique checks', () {
    expect(organicLessons.length, 60);
    expect(organicLessons.map((l) => l.id).toSet().length, 60);
    expect(organicChapters.length, 12);
    expect(
      organicLessons
          .expand((l) => l.questions)
          .map((q) => q.prompt)
          .toSet()
          .length,
      180,
    );
    for (var i = 0; i < 60; i++) {
      final lesson = organicLessons[i];
      expect(lesson.number, i + 1);
      expect(lesson.chapter, organicChapters[i ~/ 5]);
      expect(
        '${lesson.simple} ${lesson.reasoning} ${lesson.example}'
            .split(' ')
            .length,
        greaterThan(70),
        reason: lesson.title,
      );
      expect(lesson.reasoning.length, greaterThan(100));
      expect(lesson.advanced.length, greaterThan(100));
      expect(lesson.example, isNotEmpty);
      expect(
        organicDiagrams.containsKey(lesson.diagram),
        true,
        reason: lesson.title,
      );
      expect(lesson.questions.length, 3);
      for (final q in lesson.questions) {
        expect(q.options.length, 3);
        expect(q.options.toSet().length, 3);
        expect(q.answer, inInclusiveRange(0, 2));
        expect(q.explanation, isNotEmpty);
      }
    }
  });
  test('time choices implement the requested 60:40 split', () {
    expect(StudyLength.values.map((v) => v.minutes), [5, 10, 15, 20]);
    expect(StudyLength.five.learnSeconds, 180);
    expect(StudyLength.five.practiseSeconds, 120);
    for (final v in StudyLength.values) {
      expect(v.learnSeconds + v.practiseSeconds, v.minutes * 60);
    }
  });
  test(
    'saving and reopening restores answers, reflection, stage and time',
    () async {
      Map<String, dynamic>? disk;
      final repo = OrganicProgressRepository(
        read: () => disk,
        write: (value) async {
          disk = copy(value);
        },
      );
      final p = repo.load();
      p.session = OrganicSession(
        lesson: 1,
        minutes: 15,
        phase: 1,
        section: 3,
        learnSeconds: 81,
        practiceSeconds: 18,
        answers: {0: organicLessons.first.questions.first.answer},
        reflection: 'A bond is an electron pair.',
      );
      p.activeSeconds = 99;
      await repo.save(p);
      final restored = repo.load();
      expect(restored.session!.minutes, 15);
      expect(restored.session!.phase, 1);
      expect(restored.session!.section, 3);
      expect(restored.session!.answers, p.session!.answers);
      expect(restored.session!.reflection, 'A bond is an electron pair.');
      expect(restored.activeSeconds, 99);
    },
  );
  test(
    'passed checks unlock levels; replays cannot farm XP or same-day streaks',
    () async {
      Map<String, dynamic>? disk;
      final repo = OrganicProgressRepository(
        read: () => disk,
        write: (v) async {
          disk = copy(v);
        },
      );
      final p = repo.load();
      expect(p.unlocked(1), true);
      expect(p.unlocked(2), false);
      await repo.finish(
        p,
        answered(1, correct: 2),
        organicLessons.first,
        DateTime(2026, 11, 2, 23, 50),
      );
      expect(p.unlocked(2), true);
      expect(p.xp, 60);
      expect(p.streak(DateTime(2026, 11, 2)), 1);
      await repo.finish(
        p,
        answered(1, correct: 2),
        organicLessons.first,
        DateTime(2026, 11, 2, 23, 59),
      );
      expect(p.xp, 60);
      expect(p.days.length, 1);
      await repo.finish(
        p,
        answered(1),
        organicLessons.first,
        DateTime(2026, 11, 3, 0, 1),
      );
      expect(p.xp, 70);
      expect(p.streak(DateTime(2026, 11, 3)), 2);
      await repo.finish(
        p,
        answered(1, correct: 0),
        organicLessons.first,
        DateTime(2026, 11, 4),
      );
      expect(p.scores[1], 3);
      expect(p.days.length, 2);
      expect(p.mistakes['1']!.length, 3);
      expect(repo.load().scores[1], 3);
    },
  );
  test(
    'failed, unfinished and locked attempts do not award completion',
    () async {
      final repo = OrganicProgressRepository(
        read: () => null,
        write: (_) async {},
      );
      final p = repo.load();
      await repo.finish(
        p,
        answered(1, correct: 1),
        organicLessons.first,
        DateTime(2026, 11, 2),
      );
      expect(p.completed, 0);
      expect(p.xp, 0);
      expect(p.days, isEmpty);
      expect(p.unlocked(2), false);
      await expectLater(
        repo.finish(
          p,
          OrganicSession(lesson: 1, minutes: 5),
          organicLessons.first,
          DateTime.now(),
        ),
        throwsStateError,
      );
      await expectLater(
        repo.finish(p, answered(3), organicLessons[2], DateTime.now()),
        throwsStateError,
      );
    },
  );
  test('Curious can explore locked topics without unlocking the course or farming streaks', () async {
    Map<String, dynamic>? disk;
    final repo = OrganicProgressRepository(
      read: () => disk,
      write: (v) async {
        disk = copy(v);
      },
    );
    final p = repo.load();
    await repo.finish(
      p,
      answered(31, curious: true),
      organicLessons[30],
      DateTime(2026, 11, 2),
    );
    expect(p.discoveries, {31});
    expect(p.completed, 0);
    expect(p.xp, 0);
    expect(p.days, isEmpty);
    expect(p.unlocked(32), false);
    expect(repo.load().discoveries, {31});
  });
  test('failed storage writes cannot award progress in memory', () async {
    final repo = OrganicProgressRepository(
      read: () => null,
      write: (_) async {
        throw StateError('Disk full');
      },
    );
    final p = repo.load()..session = answered(1);
    await expectLater(
      repo.finish(p, p.session!, organicLessons.first, DateTime.now()),
      throwsStateError,
    );
    expect(p.completed, 0);
    expect(p.days, isEmpty);
    expect(p.session, isNotNull);
  });
  test(
    'account changes block writes and stop reads of the old account',
    () async {
      var account = 'A';
      var writes = 0;
      final repo = OrganicProgressRepository(
        read: () => OrganicProgress(scores: {1: 3}).toJson(),
        write: (_) async {
          writes++;
        },
        currentAccount: () => account == 'A',
      );
      final p = repo.load();
      expect(p.completed, 1);
      account = 'B';
      expect(repo.load().completed, 0);
      await expectLater(repo.save(p), throwsStateError);
      expect(writes, 0);
    },
  );
  test(
    'local calendar streaks handle month boundaries and yesterday grace',
    () {
      final p = OrganicProgress(
        days: {'2026-10-31', '2026-11-01', '2026-11-02'},
      );
      expect(p.streak(DateTime(2026, 11, 2, 23, 59)), 3);
      expect(p.streak(DateTime(2026, 11, 3, 0, 1)), 3);
      expect(p.streak(DateTime(2026, 11, 4)), 0);
    },
  );
  test('malformed stored values do not create crashes or phantom levels', () {
    expect(OrganicProgress.decode('broken').completed, 0);
    final p = OrganicProgress.decode({
      'version': 1,
      'scores': {'1': -3, '2': '3', '61': 3},
      'session': {'lesson': 99, 'minutes': 0},
      'days': [null, 7, 'bad'],
      'discoveries': [0, '1', 61],
    });
    expect(p.completed, 0);
    expect(p.session, isNull);
    expect(p.days, isEmpty);
    expect(p.discoveries, isEmpty);
  });
  test(
    'all 60 levels can be completed sequentially and survive reload',
    () async {
      Map<String, dynamic>? disk;
      final repo = OrganicProgressRepository(
        read: () => disk,
        write: (v) async {
          disk = copy(v);
        },
      );
      var p = repo.load();
      for (var number = 1; number <= 60; number++) {
        expect(p.unlocked(number), true);
        await repo.finish(
          p,
          answered(number),
          organicLessons[number - 1],
          DateTime(2026, 11, 2).add(Duration(days: number - 1)),
        );
        p = repo.load();
      }
      expect(p.completed, 60);
      expect(p.xp, 4200);
      expect(p.streak(DateTime(2027, 1, 1)), 60);
    },
  );
}
