import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/molecule_loader.dart';

void main() {
  group('BenzeneMoleculeLoader Widget Tests', () {
    testWidgets('renders loader without error', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BenzeneMoleculeLoader(size: 80),
          ),
        ),
      );

      expect(find.byType(BenzeneMoleculeLoader), findsOneWidget);
    });

    testWidgets('renders custom message if provided', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BenzeneMoleculeLoader(
              size: 60,
              message: 'Synthesizing chemistry concepts...',
            ),
          ),
        ),
      );

      expect(find.text('Synthesizing chemistry concepts...'), findsOneWidget);
    });
  });
}
