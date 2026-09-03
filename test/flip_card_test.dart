import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/flip_card_3d.dart';

void main() {
  group('FlipCard3D Widget Tests', () {
    testWidgets('renders front content initially by default', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlipCard3D(
              front: Text('FRONT_SIDE'),
              back: Text('BACK_SIDE'),
            ),
          ),
        ),
      );

      expect(find.text('FRONT_SIDE'), findsOneWidget);
    });

    testWidgets('renders back content when isFlipped is true', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: FlipCard3D(
              isFlipped: true,
              front: Text('FRONT_SIDE'),
              back: Text('BACK_SIDE'),
            ),
          ),
        ),
      );

      expect(find.text('BACK_SIDE'), findsOneWidget);
    });

    testWidgets('tapping flips card and fires onFlip callback', (tester) async {
      bool? flippedToBack;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: FlipCard3D(
              onFlip: (val) => flippedToBack = val,
              front: const Text('FRONT_SIDE'),
              back: const Text('BACK_SIDE'),
            ),
          ),
        ),
      );

      await tester.tap(find.byType(FlipCard3D));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(flippedToBack, isTrue);
    });
  });
}
