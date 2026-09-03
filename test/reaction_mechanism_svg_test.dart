import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/reaction_mechanism_service.dart';
import 'package:chem_buddy/presentation/screens/reaction_mechanism_screen.dart';
import 'package:chem_buddy/presentation/widgets/reaction_mechanisms_card.dart';

void main() {
  group('Reaction Mechanisms & SVG Vector Tests', () {
    test('All 10 required MSc mechanisms exist with valid SVG content', () {
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
      ];

      for (final id in requiredIds) {
        final mechanism = ReactionMechanismService.instance.find(id);
        expect(mechanism, isNotNull, reason: 'Mechanism $id should be found');
        expect(mechanism!.svgContent, isNotNull, reason: 'Mechanism $id should have svgContent');
        expect(mechanism.svgContent!.contains('<svg'), isTrue, reason: 'Mechanism $id svgContent should start with <svg');
        expect(mechanism.svgContent!.contains('</svg>'), isTrue, reason: 'Mechanism $id svgContent should end with </svg>');
        expect(mechanism.steps.isNotEmpty, isTrue, reason: 'Mechanism $id should have stepwise breakdown');
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
            body: SingleChildScrollView(
              child: ReactionMechanismsCard(),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('UNLOCKED 🧪'), findsOneWidget);
      expect(find.text('Explore Reaction Mechanisms ⚗️'), findsOneWidget);
      expect(find.textContaining('COMING SOON'), findsNothing);
    });
  });
}
