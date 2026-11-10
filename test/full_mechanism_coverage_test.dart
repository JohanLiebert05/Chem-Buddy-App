import 'package:chem_buddy/data/models/reaction_models.dart';
import 'package:chem_buddy/data/services/mechanism_lessons.dart';
import 'package:chem_buddy/data/services/reaction_curation_repository.dart';
import 'package:chem_buddy/data/services/reaction_mechanism_service.dart';
import 'package:chem_buddy/presentation/widgets/animated_mechanism_viewer.dart';
import 'package:chem_buddy/presentation/widgets/electron_flow_diagram.dart';
import 'package:chem_buddy/presentation/widgets/mechanism_step_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:xml/xml.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  final library = ReactionMechanismService.instance;

  Future<void> checkSteps(String id, List<ReactionStep> steps) async {
    expect(steps, isNotEmpty, reason: id);
    for (final step in steps) {
      final label = '$id: ${step.title}';
      final asset = step.svgAsset;
      final svg =
          step.svgContent ??
          (asset == null ? null : await rootBundle.loadString(asset));
      expect(svg, isNotNull, reason: label);
      final document = XmlDocument.parse(svg!);
      expect(document.rootElement.name.local, 'svg', reason: label);
      expect(
        document.rootElement.getAttribute('viewBox'),
        isNotNull,
        reason: label,
      );
      if (step.svgContent != null && step.electronFlow.isNotEmpty) {
        final group = document
            .findAllElements('g')
            .singleWhere(
              (element) => element.getAttribute('id') == 'electron-arrows',
            );
        final arrows = group.findElements('path').toList();
        expect(arrows.length, step.electronFlow.length, reason: label);
        for (final (index, move) in step.electronFlow.indexed) {
          final marker = arrows[index].getAttribute('marker-end')!;
          expect(
            marker.contains('fishhook'),
            move.type == 'fishhook',
            reason: label,
          );
        }
      }
    }
  }

  test(
    'every Library and predictor entry has a complete playable lesson',
    () async {
      expect(library.mechanisms.length, greaterThanOrEqualTo(37));
      for (final mechanism in library.mechanisms) {
        await checkSteps(
          mechanism.id,
          MechanismLessons.librarySteps(mechanism.id) ?? mechanism.steps,
        );
      }

      final reactions = await ReactionCurationRepository.instance
          .getAllReactions();
      expect(reactions.length, greaterThanOrEqualTo(35));
      for (final reaction in reactions) {
        final libraryId = MechanismLessons.libraryIdForPredictor(
          reaction.reactionId,
        );
        final steps =
            MechanismLessons.predictorSteps(reaction.reactionId) ??
            (libraryId == null ? null : library.find(libraryId)?.steps);
        await checkSteps(reaction.reactionId, steps ?? []);
      }
    },
  );

  testWidgets('predictor plays an entry that previously had no steps', (
    tester,
  ) async {
    const reaction = CuratedReaction(
      reactionId: 'RXN_DIECKMANN_001',
      reactionName: 'Dieckmann condensation',
      reactionClass: 'Carbonyl condensation',
    );
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SingleChildScrollView(
            child: AnimatedMechanismViewer(reaction: reaction),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
    expect(find.byType(MechanismStepViewer), findsOneWidget);
    expect(find.byType(ElectronFlowDiagram), findsOneWidget);
    expect(find.text('Generate the diester enolate'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Next step'));
    await tester.tap(find.byTooltip('Next step'));
    await tester.pumpAndSettle();
    expect(find.text('Intramolecular ester attack'), findsOneWidget);
  });
}
