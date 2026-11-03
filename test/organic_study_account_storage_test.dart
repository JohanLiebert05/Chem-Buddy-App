import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:chem_buddy/data/local/local_store.dart';
import 'package:chem_buddy/data/models/organic_study.dart';
import 'package:chem_buddy/data/services/organic_progress_repository.dart';

void main() {
  test('real account-scoped Hive boxes isolate course data and restore it after switching back', () async {
    final dir = await Directory.systemTemp.createTemp(
      'chembuddy-organic-study-',
    );
    final root = Directory.systemTemp.resolveSymbolicLinksSync().toLowerCase();
    final target = dir.resolveSymbolicLinksSync().toLowerCase();
    expect(target.startsWith('$root${Platform.pathSeparator}'), true);
    addTearDown(() async {
      await Hive.close();
      await dir.delete(recursive: true);
    });
    Hive.init(dir.path);
    await Hive.openBox(HiveBoxes.accountControl);
    await HiveBoxes.switchAccount('organic-student-a');
    final a = OrganicProgressRepository.hive();
    final progress = OrganicProgress(
      scores: {1: 3},
      nextClue: 'Check electron movement first.',
      session: OrganicSession(
        lesson: 2,
        minutes: 10,
        phase: 1,
        questionIndex: 1,
        confidence: {0: 0},
        prediction: 'I think the carbonyl is electrophilic.',
      ),
    );
    await a.save(progress);
    await HiveBoxes.switchAccount('organic-student-b');
    final b = OrganicProgressRepository.hive();
    expect(b.load().completed, 0);
    expect(b.load().nextClue, isEmpty);
    await expectLater(a.save(progress), throwsStateError);
    expect(b.load().session, isNull);
    await HiveBoxes.switchAccount('organic-student-a');
    final restored = OrganicProgressRepository.hive().load();
    expect(restored.scores, {1: 3});
    expect(restored.session!.questionIndex, 1);
    expect(restored.session!.confidence, {0: 0});
    expect(restored.nextClue, 'Check electron movement first.');
  });
}
