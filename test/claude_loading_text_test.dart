import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/claude_loading_text.dart';

void main() {
  group('ClaudeThinkingMicrocopy Unit Tests', () {
    test('All microcopy streams have at least 5 reflective thinking steps', () {
      expect(ClaudeThinkingMicrocopy.askAi.length, greaterThanOrEqualTo(5));
      expect(ClaudeThinkingMicrocopy.quiz.length, greaterThanOrEqualTo(5));
      expect(ClaudeThinkingMicrocopy.flashcards.length, greaterThanOrEqualTo(5));
      expect(ClaudeThinkingMicrocopy.predictQuestions.length, greaterThanOrEqualTo(5));
      expect(ClaudeThinkingMicrocopy.summary.length, greaterThanOrEqualTo(4));
      expect(ClaudeThinkingMicrocopy.spectroscopy.length, greaterThanOrEqualTo(5));

      // Each category starts with Claude's signature "Thinking..."
      expect(ClaudeThinkingMicrocopy.askAi.first, 'Thinking...');
      expect(ClaudeThinkingMicrocopy.quiz.first, 'Thinking...');
      expect(ClaudeThinkingMicrocopy.flashcards.first, 'Thinking...');
      expect(ClaudeThinkingMicrocopy.predictQuestions.first, 'Thinking...');
      expect(ClaudeThinkingMicrocopy.summary.first, 'Thinking...');
      expect(ClaudeThinkingMicrocopy.spectroscopy.first, 'Thinking...');
    });

    test('Microcopy thoughts reflect intellectual, academic chemical reasoning', () {
      for (final thought in ClaudeThinkingMicrocopy.askAi) {
        expect(thought, isNotEmpty);
      }
      for (final thought in ClaudeThinkingMicrocopy.quiz) {
        expect(thought, isNotEmpty);
      }
      for (final thought in ClaudeThinkingMicrocopy.flashcards) {
        expect(thought, isNotEmpty);
      }
    });
  });

  group('ClaudeLoadingText & Thinking Widgets Tests', () {
    testWidgets('ClaudeShimmerText renders text with ShaderMask sweep', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ClaudeShimmerText('Analyzing chemical entities...'),
            ),
          ),
        ),
      );

      expect(find.text('Analyzing chemical entities...'), findsOneWidget);
      expect(find.byType(ShaderMask), findsOneWidget);

      // Advance animation frames to verify gradient translation
      await tester.pump(const Duration(milliseconds: 300));
      await tester.pump(const Duration(milliseconds: 600));
    });

    testWidgets('ClaudeThinkingIndicator renders sparkling star, thinking header, and thoughts', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ClaudeThinkingIndicator(
                thoughts: ClaudeThinkingMicrocopy.quiz,
                isCard: true,
                thinkingHeader: 'Assembling Chemistry Quiz',
              ),
            ),
          ),
        ),
      );

      expect(find.byIcon(Icons.auto_awesome_rounded), findsOneWidget);
      expect(find.text('Assembling Chemistry Quiz'), findsOneWidget);
      expect(find.text('Thinking...'), findsOneWidget);

      // Advance clock by thoughtInterval to trigger thought cycle
      await tester.pump(const Duration(milliseconds: 2400));
      expect(find.text('Reviewing syllabus scope & core MSc examination objectives...'), findsOneWidget);
    });

    testWidgets('ClaudeThinkingBubble renders in assistant chat stream format', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Center(
              child: ClaudeThinkingBubble(
                thoughts: ClaudeThinkingMicrocopy.askAi,
              ),
            ),
          ),
        ),
      );

      expect(find.byType(ClaudeThinkingBubble), findsOneWidget);
      expect(find.byType(ClaudeThinkingIndicator), findsOneWidget);
      expect(find.text('Thinking'), findsOneWidget);

      // Advance clock to verify cycle without crash
      await tester.pump(const Duration(milliseconds: 2300));
    });
  });
}
