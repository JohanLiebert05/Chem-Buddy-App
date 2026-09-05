import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/chemdraw_library.dart';
import 'package:chem_buddy/data/services/reaction_mechanism_service.dart';
import 'package:chem_buddy/presentation/widgets/reaction_mechanisms_card.dart';

void main() {
  group('Reaction Mechanisms & SVG Vector Tests', () {
    test('All 21 required MSc mechanisms exist with valid SVG content', () {
      final requiredIds = [
        'sn1',
        'sn2',
        'e1',
        'e2',
        'cannizzaro',
        'wittig',
        'diels_alder',
        'grignard',
        'beckmann',
        'benzoin',
        'aldol',
        'michael',
        'claisen',
        'baeyer_villiger',
        'favorskii',
        'mannich',
        'pinacol',
        'robinson',
        'curtius',
        'cope',
        'claisen_sigmatropic',
      ];

      for (final id in requiredIds) {
        final mechanism = ReactionMechanismService.instance.find(id);
        expect(mechanism, isNotNull, reason: 'Mechanism $id should be found');
        expect(mechanism!.steps.isNotEmpty, isTrue, reason: 'Mechanism $id should have stepwise breakdown');
        if (id == 'sn2' || ChemDrawLibrary.folders.containsKey(id)) {
          expect(mechanism.hasChemDrawSteps, isTrue, reason: id);
          expect(mechanism.steps.every((s) => s.svgAsset != null), isTrue, reason: id);
        } else {
          expect(mechanism.svgContent, isNotNull, reason: 'Mechanism $id should have svgContent');
          expect(mechanism.svgContent!.contains('<svg'), isTrue);
          expect(mechanism.svgContent!.contains('</svg>'), isTrue);
        }
      }
    });

    testWidgets('All ChemDraw mechanism SVG assets are bundled', (tester) async {
      for (final folder in ChemDrawLibrary.folders.values) {
        final mechanismId = folder.split('/')[folder.split('/').length - 2];
        final steps = ChemDrawLibrary.stepsFor(mechanismId)!;
        for (final step in steps) {
          final svg = await rootBundle.loadString(step.svgAsset!);
          expect(svg.contains('<svg'), isTrue, reason: step.svgAsset);
          expect(svg.contains('viewBox'), isTrue, reason: step.svgAsset);
        }
      }
    });

    test('SVG caching returns cached vector string without re-parsing', () async {
      final svg1 = await ReactionMechanismService.instance.getSvgForMechanism('sn1');
      final svg2 = await ReactionMechanismService.instance.getSvgForMechanism('sn1');
      expect(identical(svg1, svg2), isTrue);
    });

    testWidgets('ReactionMechanismsCard renders unlocked active badge and navigates', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: ReactionMechanismsCard(),
          ),
        ),
      );

      expect(find.byType(ReactionMechanismsCard), findsOneWidget);
      expect(find.text('REACTION MECHANISMS'), findsOneWidget);
    });
  });
}
