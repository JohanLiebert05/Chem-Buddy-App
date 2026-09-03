import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/app_card.dart';
import 'package:chem_buddy/core/theme/app_colors.dart';

void main() {
  group('AppCard & Design System Atomic Widgets Tests', () {
    testWidgets('AppCard renders child and responds to tap', (tester) async {
      var tapped = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: AppCard(
              onTap: () => tapped = true,
              child: const Text('Hello AppCard'),
            ),
          ),
        ),
      );

      expect(find.text('Hello AppCard'), findsOneWidget);
      await tester.tap(find.text('Hello AppCard'));
      await tester.pumpAndSettle();
      expect(tapped, isTrue);
    });

    testWidgets('StatCard displays value, label, icon and badge', (tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: StatCard(
              icon: Icons.bolt,
              value: '94%',
              label: 'Quiz Accuracy',
              badgeText: '+5%',
              badgeColor: AppColors.statusSuccess,
            ),
          ),
        ),
      );

      expect(find.text('94%'), findsOneWidget);
      expect(find.text('Quiz Accuracy'), findsOneWidget);
      expect(find.text('+5%'), findsOneWidget);
      expect(find.byIcon(Icons.bolt), findsOneWidget);
    });

    testWidgets('EmptyState renders title, subtitle, and action button', (tester) async {
      var actionTriggered = false;
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: EmptyState(
              icon: Icons.menu_book,
              title: 'No Documents Yet',
              subtitle: 'Upload lecture slides or MSc notes to start.',
              actionLabel: 'Upload Notes',
              onAction: () => actionTriggered = true,
            ),
          ),
        ),
      );

      expect(find.text('No Documents Yet'), findsOneWidget);
      expect(find.text('Upload lecture slides or MSc notes to start.'), findsOneWidget);
      expect(find.text('Upload Notes'), findsOneWidget);

      await tester.tap(find.text('Upload Notes'));
      await tester.pumpAndSettle();
      expect(actionTriggered, isTrue);
    });
  });
}
