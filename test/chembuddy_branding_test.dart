import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/branding/chembuddy_mascot.dart';
import 'package:chem_buddy/core/widgets/branding/chembuddy_logo.dart';
import 'package:chem_buddy/core/widgets/branding/chembuddy_wordmark.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ChemBuddy Branding & Mascot Tests', () {
    testWidgets('ChemBuddyMascot renders in all 7 states without throwing', (tester) async {
      for (final state in MascotState.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChemBuddyMascot(
                state: state,
                size: MascotSize.medium,
                animate: false,
              ),
            ),
          ),
        );
        expect(find.byType(ChemBuddyMascot), findsOneWidget);
      }
    });

    testWidgets('ChemBuddyMascot renders in all standard sizes', (tester) async {
      for (final size in MascotSize.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: ChemBuddyMascot(
                state: MascotState.idle,
                size: size,
                animate: false,
              ),
            ),
          ),
        );
        expect(find.byType(ChemBuddyMascot), findsOneWidget);
      }
    });

    testWidgets('MascotThinking renders title and thinking microcopy', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MascotThinking(
              title: 'Synthesizing reaction',
              thoughts: ['Analyzing orbital symmetry...'],
            ),
          ),
        ),
      );
      expect(find.text('Synthesizing reaction'), findsOneWidget);
      expect(find.byType(ChemBuddyMascot), findsOneWidget);
    });

    testWidgets('MascotLoading renders title and subtitle', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: MascotLoading(
              title: 'Generating Chemistry Quiz',
              subtitle: 'Extracting 10 questions',
            ),
          ),
        ),
      );
      expect(find.text('Generating Chemistry Quiz'), findsOneWidget);
      expect(find.text('Extracting 10 questions'), findsOneWidget);
      expect(find.byType(ChemBuddyMascot), findsOneWidget);
    });

    testWidgets('MascotEmptyState renders title, description, and handles CTA tap', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MascotEmptyState(
              title: 'No PDFs in Library',
              description: 'Import your syllabus notes to start studying.',
              buttonLabel: 'Import PDF',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('No PDFs in Library'), findsOneWidget);
      expect(find.text('Import your syllabus notes to start studying.'), findsOneWidget);
      expect(find.text('Import PDF'), findsOneWidget);

      await tester.tap(find.text('Import PDF'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('MascotSuccess renders congratulations and action CTA', (tester) async {
      bool tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MascotSuccess(
              title: 'Quiz Completed! 100%',
              subtitle: 'Full marks in Organometallics',
              buttonLabel: 'Review Model Answers',
              onAction: () => tapped = true,
            ),
          ),
        ),
      );

      expect(find.text('Quiz Completed! 100%'), findsOneWidget);
      expect(find.text('Full marks in Organometallics'), findsOneWidget);
      await tester.tap(find.text('Review Model Answers'));
      await tester.pump();
      expect(tapped, isTrue);
    });

    testWidgets('MascotError renders message and handles retry callback', (tester) async {
      bool retried = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: MascotError(
              message: 'Rate limit encountered. Please retry in 10s.',
              onRetry: () => retried = true,
            ),
          ),
        ),
      );

      expect(find.text('Rate limit encountered. Please retry in 10s.'), findsOneWidget);
      await tester.tap(find.text('Rebalance & Try Again'));
      await tester.pump();
      expect(retried, isTrue);
    });

    testWidgets('ChemBuddyLogo and ChemBuddyWordmark render smoothly', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: Column(
              children: [
                ChemBuddyLogo(size: 60, animated: false),
                ChemBuddyWordmark(fontSize: 24),
              ],
            ),
          ),
        ),
      );

      expect(find.byType(ChemBuddyLogo), findsOneWidget);
      expect(find.byType(ChemBuddyWordmark), findsOneWidget);
      expect(find.text('ChemBuddy'), findsOneWidget);
      expect(find.text('MSC CHEMISTRY'), findsOneWidget);
    });
  });
}
