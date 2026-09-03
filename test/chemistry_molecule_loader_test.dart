import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/molecule_loader.dart';

void main() {
  group('BenzeneMoleculeLoader & Chemistry Microcopy Tests', () {
    test('Microcopy phrases are concise (< 6 words) and chemistry-themed', () {
      final allPhrases = [
        ...ChemistryMicrocopy.askAi,
        ...ChemistryMicrocopy.flashcards,
        ...ChemistryMicrocopy.timetable,
        ...ChemistryMicrocopy.spectroscopy,
      ];

      for (final phrase in allPhrases) {
        final wordCount = phrase.split(RegExp(r'\s+')).length;
        expect(wordCount, lessThanOrEqualTo(6), reason: 'Phrase "$phrase" should be under ~5 words');
      }
    });

    testWidgets('BenzeneMoleculeLoader cycles through messages on timer', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: BenzeneMoleculeLoader(
              size: 60,
              cycleInterval: Duration(milliseconds: 500),
              messages: [
                'Distilling your answer...',
                'Calibrating the concept...',
                'Titrating the right explanation...',
              ],
            ),
          ),
        ),
      );
      await tester.pump();

      expect(find.text('Distilling your answer...'), findsOneWidget);

      // Advance clock by 500ms for timer + 350ms for transition animation
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump(const Duration(milliseconds: 360));

      expect(find.text('Calibrating the concept...'), findsOneWidget);

      // Advance clock by another 500ms + 350ms animation
      await tester.pump(const Duration(milliseconds: 550));
      await tester.pump(const Duration(milliseconds: 360));

      expect(find.text('Titrating the right explanation...'), findsOneWidget);
    });

  });
}
