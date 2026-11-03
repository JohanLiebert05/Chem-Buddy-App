import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:chem_buddy/core/chemistry/spectroscopy_structure_svg.dart';
import 'package:chem_buddy/data/services/curious_catalog.dart';
import 'package:chem_buddy/data/services/curious_explanation_service.dart';
import 'package:chem_buddy/data/services/organic_diagrams.dart';
import 'package:chem_buddy/data/services/organic_progress_repository.dart';
import 'package:chem_buddy/data/services/spectroscopy_evidence_guide.dart';
import 'package:chem_buddy/data/services/spectroscopy_service.dart';
import 'package:chem_buddy/presentation/screens/curious_topic_screen.dart';
import 'package:chem_buddy/presentation/screens/study_mode_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Map<String, dynamic> response(CuriousTopic topic) => {
  'topic_id': topic.id,
  'example_smiles': topic.molecule.smiles,
  'explanation': 'A molecular orbital describes a quantum state, and its squared magnitude describes probability density.',
  'steps': [
    'Start from the six p orbitals on the benzene carbons.',
    'Combine them into molecular orbitals occupied by six pi electrons.',
  ],
  'common_mistake': 'The circle is not a literal electron race track.',
  'check_question': 'Does a pi cloud describe a visible solid shell?',
  'check_answer':
      'No. It represents a chosen model of electron probability density.',
};

void main() {
  test(
    '60 distinct questions include 48 new foundations and valid structures',
    () {
      expect(curiousTopics.length, 60);
      expect(curiousTopics.map((t) => t.id).toSet().length, 60);
      expect(curiousTopics.map((t) => t.question).toSet().length, 60);
      for (final topic in curiousTopics) {
        expect(topic.answer.length, greaterThan(100), reason: topic.id);
        expect(organicDiagrams.containsKey(topic.diagram), true);
        expect(
          SpectroscopyStructureSvg.depict(topic.molecule).svg,
          isNotNull,
          reason: topic.id,
        );
      }
      expect(curiousTopics[0].answer, contains('probability density'));
      expect(
        curiousTopics[1].answer,
        contains('Electrons do not need arrowheads'),
      );
    },
  );
  test(
    'surprises cover all 60 once and never repeat at the cycle boundary',
    () {
      final picker = CuriousSurprises(random: Random(6));
      final cycle = [
        for (var i = 0; i < 60; i++) picker.next(curiousTopics).id,
      ];
      expect(cycle.toSet().length, 60);
      expect(picker.next(curiousTopics).id, isNot(cycle.last));
      final themed = curiousTopics
          .where((t) => t.theme == 'Electrons')
          .toList();
      expect(
        [for (var i = 0; i < themed.length; i++) picker.next(themed)]
            .every((t) => t.theme == 'Electrons'),
        true,
      );
      expect(() => picker.next([]), throwsStateError);
    },
  );
  test(
    'AI explanation checks identity, structure, size and complete steps',
    () {
      final topic = curiousTopics.first;
      expect(
        CuriousExplanation.parse(
          jsonEncode(response(topic)),
          topic,
        ).steps.length,
        2,
      );
      for (final patch in [
        {'topic_id': 'another-question'},
        {'example_smiles': 'CCO'},
        {
          'steps': ['Too short'],
        },
        {'explanation': ''},
        {
          'steps': [1, 2],
        },
      ]) {
        expect(
          () => CuriousExplanation.parse(
            jsonEncode({...response(topic), ...patch}),
            topic,
          ),
          throwsFormatException,
        );
      }
      expect(
        () => CuriousExplanation.parse('x' * 25000, topic),
        throwsFormatException,
      );
    },
  );
  test(
    'online requests are authenticated, deduplicated and cached per account',
    () async {
      final topic = curiousTopics[1];
      var account = 'curious-test-A';
      var calls = 0;
      final pending = Completer<dynamic>();
      final service = CuriousExplanationService(
        account: () => account,
        invoke: (body) {
          calls++;
          expect(body['category'], 'chemistry_curiosity');
          expect(
            jsonDecode(body['prompt'])['example_smiles'],
            topic.molecule.smiles,
          );
          expect(body.toString(), isNot(contains('AQ.')));
          return pending.future;
        },
      );
      final a = service.expand(topic), b = service.expand(topic);
      pending.complete({'text': jsonEncode(response(topic))});
      await Future.wait([a, b]);
      await service.expand(topic);
      expect(calls, 1);
      account = 'curious-test-B';
      await service.expand(topic);
      expect(calls, 2);
    },
  );
  test(
    'signed-out and stale-account responses never become visible results',
    () async {
      final topic = curiousTopics[2];
      var owner = 'stale-A';
      final pending = Completer<dynamic>();
      final service = CuriousExplanationService(
        account: () => owner,
        invoke: (_) => pending.future,
      );
      final future = service.expand(topic);
      owner = 'stale-B';
      pending.complete({'text': jsonEncode(response(topic))});
      await expectLater(future, throwsStateError);
      final signedOut = CuriousExplanationService(
        account: () => null,
        invoke: (_) async => throw StateError('Should not call'),
      );
      await expectLater(signedOut.expand(topic), throwsStateError);
    },
  );
  test('absolute integrations reject impossible totals and incompatible references', () {
    List<ProtonSignal> signals(List<int> counts) => [
      for (var i = 0; i < 3; i++)
        ProtonSignal(shift: [2.60, 7.50, 7.95][i], integration: counts[i]),
    ];
    SpectroscopyAnalysisResult solve(List<int> counts) =>
        SpectroscopyService.analyzeSpectraStructured(
          formula: 'C8H8O',
          protonSignals: signals(counts),
          nmr13CPeaks: [26.6, 128.3, 128.6, 133.1, 137.1, 198.1],
        );
    final right = solve([3, 3, 2]);
    expect(
      right.supportedCompound?.commonName.toLowerCase(),
      contains('acetophenone'),
    );
    expect(
      right.candidateMatches.first.evidence,
      contains('¹H absolute integrations agree'),
    );
    expect(solve([4, 3, 2]).isValid, false);
    expect(solve([2, 3, 2]).supportedCompound, isNull);
    expect(SpectroscopyEvidenceGuide.parseIntegrations('3, 3, 2', 3), [
      3,
      3,
      2,
    ]);
    for (final text in ['3,2', '1.5,2,3', '-1,3,2', '0,3,2', 'NaN,3,2']) {
      expect(
        () => SpectroscopyEvidenceGuide.parseIntegrations(text, 3),
        throwsFormatException,
      );
    }
    final tips = SpectroscopyEvidenceGuide.suggest(
      result: right,
      proton: [2.6, 7.5, 7.95],
      carbon: [],
      ir: [],
      integrations: [3, 3, 2],
    );
    expect(tips.join(), contains('8 of 8'));
    expect(tips.join(), contains('HSQC'));
  });
  testWidgets(
    'theme surprise opens a real question and online explanation with structure',
    (tester) async {
      await tester.binding.setSurfaceSize(const Size(390, 844));
      addTearDown(() => tester.binding.setSurfaceSize(null));
      final repository = OrganicProgressRepository(
        read: () => null,
        write: (_) async {},
      );
      await tester.pumpWidget(
        MaterialApp(home: CuriousScreen(repository: repository)),
      );
      await tester.tap(find.widgetWithText(ChoiceChip, 'Electrons'));
      await tester.pumpAndSettle();
      await tester.ensureVisible(find.text('Surprise me'));
      await tester.tap(find.text('Surprise me'));
      await tester.pumpAndSettle();
      expect(find.byType(CuriousTopicScreen), findsOneWidget);
      expect(
        tester
            .widget<CuriousTopicScreen>(find.byType(CuriousTopicScreen))
            .topic
            .theme,
        'Electrons',
      );
      expect(tester.takeException(), isNull);
    },
  );
  testWidgets(
    'fresh explanation shows checked content and truthful failure fallback',
    (tester) async {
      final topic = curiousTopics.first;
      final repository = OrganicProgressRepository(
        read: () => null,
        write: (_) async {},
      );
      var fail = false;
      Future<void> mount(String owner) async {
        await tester.pumpWidget(
          MaterialApp(
            home: CuriousTopicScreen(
              key: ValueKey(owner),
              topic: topic,
              repository: repository,
              explanations: CuriousExplanationService(
                account: () => owner,
                invoke: (_) async {
                  if (fail) throw StateError('Provider unavailable');
                  return {'text': jsonEncode(response(topic))};
                },
              ),
            ),
          ),
        );
        await tester.pumpAndSettle();
        await tester.scrollUntilVisible(
          find.text('Explore further · new explanation'),
          500,
        );
        await tester.tap(find.text('Explore further · new explanation'));
        await tester.pumpAndSettle();
      }

      await mount('widget-success');
      await tester.scrollUntilVisible(find.text('Explore further'), 400);
      expect(find.text('Explore further'), findsOneWidget);
      expect(find.text(response(topic)['explanation']), findsOneWidget);
      fail = true;
      await mount('widget-failure');
      await tester.scrollUntilVisible(
        find.textContaining('Could not load a fresh explanation.'),
        400,
      );
      expect(
        find.textContaining('Could not load a fresh explanation.'),
        findsOneWidget,
      );
      expect(find.text('Explore further'), findsNothing);
      expect(tester.takeException(), isNull);
    },
  );
}
