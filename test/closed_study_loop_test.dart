import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:chem_buddy/data/models/smart_flashcard.dart';
import 'package:chem_buddy/presentation/screens/exam_pattern_quiz_screen.dart';
import 'package:chem_buddy/presentation/screens/spectroscopy_hub_screen.dart';
import 'package:chem_buddy/presentation/screens/pericyclic_hub_screen.dart';

void main() {
  group('Closed Study Loop & MSc Features Tests', () {
    test('SmartFlashcard preserves sourceBacklink through toJson and fromJson', () {
      final card = SmartFlashcard(
        id: 'c1',
        setId: 's1',
        question: 'What is the Woodward-Hoffmann rule for [4+2]?',
        answer: 'Thermally allowed suprafacial-suprafacial',
        position: 0,
        sourceBacklink: 'Comprehensive AI chat derivation on Diels-Alder [4+2] cycloaddition.',
      );

      final json = card.toJson();
      expect(json['source_backlink'], equals('Comprehensive AI chat derivation on Diels-Alder [4+2] cycloaddition.'));

      final restored = SmartFlashcard.fromJson(json);
      expect(restored.sourceBacklink, equals(card.sourceBacklink));
    });

    testWidgets('ExamPatternQuizScreen renders university exam format and marks', (tester) async {
      tester.view.physicalSize = const Size(1200, 2400);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(tester.view.resetPhysicalSize);
      addTearDown(tester.view.resetDevicePixelRatio);

      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: ExamPatternQuizScreen(examTitle: 'Test Exam Paper'),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Test Exam Paper'), findsOneWidget);
      expect(find.textContaining('University Exam Pattern'), findsOneWidget);
      expect(find.textContaining('Part A'), findsWidgets);
      expect(find.textContaining('Part B'), findsWidgets);
    });


    testWidgets('SpectroscopyHubScreen renders NMR, IR, and Mass Spec tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: SpectroscopyHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Spectroscopy Hub'), findsOneWidget);
      expect(find.text('¹H / ¹³C NMR'), findsOneWidget);
      expect(find.text('FT-IR Frequencies'), findsOneWidget);
      expect(find.text('Mass Spec'), findsOneWidget);
      expect(find.text('Structure Solver'), findsOneWidget);
    });

    testWidgets('PericyclicHubScreen renders FMO Predictor and tabs', (tester) async {
      await tester.pumpWidget(
        const ProviderScope(
          child: MaterialApp(
            home: PericyclicHubScreen(),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Pericyclic Chemistry & FMO'), findsOneWidget);
      expect(find.text('FMO Predictor'), findsOneWidget);
      expect(find.text('Woodward-Hoffmann Rules'), findsOneWidget);
    });
  });
}
