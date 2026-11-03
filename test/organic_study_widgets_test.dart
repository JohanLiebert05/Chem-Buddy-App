import 'dart:convert';
import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/services.dart';
import 'package:chem_buddy/data/models/organic_study.dart';
import 'package:chem_buddy/data/services/organic_curriculum.dart';
import 'package:chem_buddy/data/services/organic_progress_repository.dart';
import 'package:chem_buddy/presentation/screens/study_mode_screen.dart';
import 'package:chem_buddy/presentation/screens/organic_lesson_screen.dart';

class _Disk {
  Map<String, dynamic>? data;
  bool fail = false;
  late final repository = OrganicProgressRepository(
    read: () => data,
    write: (value) async {
      if (fail) throw StateError('Disk full');
      data = jsonDecode(jsonEncode(value)) as Map<String, dynamic>;
    },
  );
}

class _Watch implements Stopwatch {
  int seconds = 0;
  @override
  bool isRunning = false;
  void advance(int value) {
    if (isRunning) seconds += value;
  }

  @override
  void start() => isRunning = true;
  @override
  void stop() => isRunning = false;
  @override
  void reset() => seconds = 0;
  @override
  Duration get elapsed => Duration(seconds: seconds);
  @override
  int get elapsedMicroseconds => seconds * 1000000;
  @override
  int get elapsedMilliseconds => seconds * 1000;
  @override
  int get elapsedTicks => seconds * frequency;
  @override
  int get frequency => 1000000;
}

Widget _app(Widget child, {bool dark = false, double scale = 1}) => MaterialApp(
  debugShowCheckedModeBanner: false,
  theme: ThemeData(
    useMaterial3: true,
    fontFamily: 'sans-serif',
    colorScheme: ColorScheme.fromSeed(
      seedColor: const Color(0xFF7351B5),
      brightness: dark ? Brightness.dark : Brightness.light,
    ),
  ),
  builder: (context, child) => MediaQuery(
    data: MediaQuery.of(
      context,
    ).copyWith(textScaler: TextScaler.linear(scale), disableAnimations: true),
    child: child!,
  ),
  home: child,
);

Future<void> _capture(WidgetTester tester, String name) async {
  if (!const bool.fromEnvironment('WRITE_STUDY_REVIEW')) return;
  final boundary = tester.renderObject<RenderRepaintBoundary>(
    find.byKey(const ValueKey('review-boundary')),
  );
  await tester.runAsync(() async {
    final image = await boundary.toImage(pixelRatio: 1.5);
    final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
    final dir = Directory('build/study-mode-review')
      ..createSync(recursive: true);
    File('${dir.path}/$name.png').writeAsBytesSync(
      bytes!.buffer.asUint8List(bytes.offsetInBytes, bytes.lengthInBytes),
    );
    image.dispose();
  });
}

void main() {
  testWidgets(
    'the reasoning sheet saves first thought, evidence and a next-visit clue while paused',
    (tester) async {
      final disk = _Disk();
      final p = disk.repository.load();
      final s = OrganicSession(lesson: 1, minutes: 5);
      p.session = s;
      await tester.pumpWidget(
        _app(
          OrganicLessonScreen(
            repository: disk.repository,
            progress: p,
            session: s,
            lesson: organicLessons.first,
          ),
        ),
      );
      await tester.tap(find.byTooltip('My reasoning'));
      await tester.pumpAndSettle();
      Finder field(String label) => find.byWidgetPredicate(
        (w) => w is TextField && w.decoration?.labelText == label,
      );
      await tester.enterText(
        field('My first thought'),
        'Carbon shares four pairs.',
      );
      await tester.enterText(
        field('What supports it?'),
        'The methane diagram has four bonds.',
      );
      await tester.ensureVisible(field('A question for next time'));
      await tester.enterText(
        field('A question for next time'),
        'Check the hidden hydrogens next.',
      );
      final save = find.text('Save and close');
      await tester.ensureVisible(save);
      await tester.tap(save);
      await tester.pumpAndSettle();
      final restored = disk.repository.load();
      expect(restored.session!.prediction, 'Carbon shares four pairs.');
      expect(
        restored.session!.reflection,
        'The methane diagram has four bonds.',
      );
      expect(restored.nextClue, 'Check the hidden hydrogens next.');
      expect(tester.takeException(), isNull);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  setUpAll(() async {
    if (const bool.fromEnvironment('WRITE_STUDY_REVIEW')) {
      final file = File('C:/Windows/Fonts/segoeui.ttf');
      if (file.existsSync()) {
        await (FontLoader('sans-serif')..addFont(
              Future.value(ByteData.sublistView(file.readAsBytesSync())),
            ))
            .load();
        await (FontLoader(
          'MaterialIcons',
        )..addFont(rootBundle.load('fonts/MaterialIcons-Regular.otf'))).load();
      }
    }
  });
  testWidgets('course has four durations and preserves the selected preference', (
    tester,
  ) async {
    final disk = _Disk();
    await tester.pumpWidget(_app(StudyModeScreen(repository: disk.repository)));
    for (final minutes in [5, 10, 15, 20]) {
      final choice = find.widgetWithText(ChoiceChip, '$minutes min');
      await tester.ensureVisible(choice);
      await tester.tap(choice);
      await tester.pumpAndSettle();
      expect(disk.repository.load().preferredMinutes, minutes);
      expect(
        find.text(
          '${(minutes * .6).round()} min explanation + ${(minutes * .4).round()} min practice',
        ),
        findsOneWidget,
      );
    }
    expect(tester.takeException(), isNull);
  });
  testWidgets(
    'complete a lesson through real controls, persist result and unlock level two',
    (tester) async {
      tester.view.physicalSize = const Size(430, 932);
      tester.view.devicePixelRatio = 1;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);
      final disk = _Disk();
      await tester.pumpWidget(
        _app(StudyModeScreen(repository: disk.repository)),
      );
      await tester.tap(find.text('Start level 1'));
      await tester.pumpAndSettle();
      expect(find.text('Carbon starts with four bonds'), findsOneWidget);
      await tester.tap(find.text('Practise'));
      await tester.pumpAndSettle();
      for (var i = 0; i < 3; i++) {
        final box = find.byKey(ValueKey('organic-question-$i'));
        final q = organicLessons.first.questions[i];
        final answer = find.descendant(
          of: box,
          matching: find.text(q.options[q.answer]),
        );
        await tester.ensureVisible(answer);
        await tester.tap(answer);
        await tester.pumpAndSettle();
        final check = find.descendant(
          of: box,
          matching: find.text('Check answer'),
        );
        await tester.ensureVisible(check);
        await tester.tap(check);
        await tester.pumpAndSettle();
        expect(disk.repository.load().session!.answers[i], q.answer);
        await tester.ensureVisible(box);
        await tester.pumpAndSettle();
        expect(
          find.descendant(of: box, matching: find.text(q.explanation)),
          findsOneWidget,
        );
        if (i < 2) {
          final next = find.text('Next question');
          await tester.ensureVisible(next);
          await tester.tap(next);
          await tester.pumpAndSettle();
        }
      }
      final finish = find.text('Finish level');
      await tester.ensureVisible(finish);
      await tester.tap(finish);
      await tester.pumpAndSettle();
      expect(disk.repository.load().scores[1], 3);
      expect(disk.repository.load().session, isNull);
      final back = find.text('Back to journey');
      await tester.ensureVisible(back);
      await tester.tap(back);
      await tester.pumpAndSettle();
      expect(find.byType(StudyModeScreen), findsOneWidget);
      await tester.scrollUntilVisible(
        find.byKey(const ValueKey('level-2')),
        400,
      );
      expect(
        tester.widget<ListTile>(find.byKey(const ValueKey('level-2'))).onTap,
        isNotNull,
      );
      expect(
        tester.widget<ListTile>(find.byKey(const ValueKey('level-3'))).onTap,
        isNull,
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'monotonic active time is saved; background and paused time do not count',
    (tester) async {
      final disk = _Disk();
      final watch = _Watch();
      final progress = disk.repository.load();
      final session = OrganicSession(lesson: 1, minutes: 5);
      progress.session = session;
      await tester.pumpWidget(
        _app(
          OrganicLessonScreen(
            repository: disk.repository,
            progress: progress,
            session: session,
            lesson: organicLessons.first,
            createStopwatch: () => watch,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Start / resume'));
      await tester.pump();
      watch.advance(8);
      await tester.pump(const Duration(seconds: 1));
      await tester.pump();
      expect(session.learnSeconds, 8);
      expect(disk.repository.load().activeSeconds, 8);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.paused);
      await tester.pump();
      watch.advance(120);
      await tester.pump(const Duration(minutes: 2));
      expect(session.learnSeconds, 8);
      tester.binding.handleAppLifecycleStateChanged(AppLifecycleState.resumed);
      await tester.pump();
      expect(watch.isRunning, false);
      await tester.tap(find.byTooltip('Start / resume'));
      await tester.pump();
      watch.advance(3);
      await tester.pump(const Duration(seconds: 1));
      expect(session.learnSeconds, 11);
      await tester.tap(find.byTooltip('Pause'));
      await tester.pump();
      expect(disk.repository.load().activeSeconds, 11);
      await tester.pumpWidget(const SizedBox());
      await tester.pump();
    },
  );
  testWidgets('timebox pauses and never automatically submits a quiz', (
    tester,
  ) async {
    final disk = _Disk();
    final watch = _Watch();
    final p = disk.repository.load();
    final s = OrganicSession(lesson: 1, minutes: 5, phase: 1);
    p.session = s;
    await tester.pumpWidget(
      _app(
        OrganicLessonScreen(
          repository: disk.repository,
          progress: p,
          session: s,
          lesson: organicLessons.first,
          createStopwatch: () => watch,
        ),
      ),
    );
    await tester.tap(find.byTooltip('Start / resume'));
    await tester.pump();
    watch.advance(121);
    await tester.pump(const Duration(seconds: 1));
    await tester.pump();
    expect(watch.isRunning, false);
    expect(s.answers, isEmpty);
    expect(p.completed, 0);
    expect(
      find.text('Timebox complete. Continue at your pace or change stage.'),
      findsOneWidget,
    );
    await tester.pumpWidget(const SizedBox());
    await tester.pump();
  });
  for (final dark in [false, true]) {
    testWidgets(
      'course and Curious stay readable at narrow width and enlarged text (${dark ? 'dark' : 'light'})',
      (tester) async {
        tester.view.physicalSize = const Size(360, 820);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        final disk = _Disk();
        for (final screen in [
          StudyModeScreen(repository: disk.repository),
          CuriousScreen(repository: disk.repository),
        ]) {
          await tester.pumpWidget(
            RepaintBoundary(
              key: const ValueKey('review-boundary'),
              child: _app(screen, dark: dark, scale: 1.6),
            ),
          );
          await tester.pumpAndSettle();
          expect(tester.takeException(), isNull);
          await _capture(
            tester,
            '${screen is CuriousScreen ? 'curious' : 'journey'}-${dark ? 'dark' : 'light'}',
          );
          await tester.pumpWidget(const SizedBox());
        }
      },
    );
  }
  testWidgets(
    'Curious starts an advanced topic without requiring course unlocks',
    (tester) async {
      final disk = _Disk();
      await tester.pumpWidget(_app(CuriousScreen(repository: disk.repository)));
      await tester.ensureVisible(find.text('How do electrons look in a benzene ring?'));
        await tester.tap(find.text('How do electrons look in a benzene ring?'));
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(find.text('Study the related 10-minute lesson'), 500);
        await tester.tap(find.text('Study the related 10-minute lesson'));
      await tester.pumpAndSettle();
      expect(find.byType(OrganicLessonScreen), findsOneWidget);
      expect(disk.repository.load().session!.curious, true);
      expect(disk.repository.load().session!.minutes, 10);
      expect(disk.repository.load().completed, 0);
    },
  );
  testWidgets(
    'an account change immediately hides the old lesson and stops its clock',
    (tester) async {
      final account = ValueNotifier<String>('A');
      addTearDown(account.dispose);
      var writes = 0;
      final repo = OrganicProgressRepository(
        read: () => null,
        write: (_) async {
          writes++;
        },
        currentAccount: () => account.value == 'A',
        accountChanges: account,
      );
      final p = repo.load();
      final s = OrganicSession(lesson: 1, minutes: 5);
      p.session = s;
      final watch = _Watch();
      await tester.pumpWidget(
        _app(
          OrganicLessonScreen(
            repository: repo,
            progress: p,
            session: s,
            lesson: organicLessons.first,
            createStopwatch: () => watch,
          ),
        ),
      );
      await tester.tap(find.byTooltip('Start / resume'));
      await tester.pump();
      account.value = 'B';
      await tester.pump();
      expect(watch.isRunning, false);
      expect(find.text('Carbon starts with four bonds'), findsNothing);
      expect(find.textContaining('Account changed.'), findsOneWidget);
      expect(writes, 0);
      await tester.pumpWidget(const SizedBox());
    },
  );
}
