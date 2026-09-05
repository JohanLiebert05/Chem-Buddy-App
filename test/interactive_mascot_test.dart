import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/widgets/interactive_mascot.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InteractiveMascot Widget Tests', () {
    testWidgets('Renders properly in idle, thinking, and celebrating moods', (tester) async {
      for (final mood in MascotMood.values) {
        await tester.pumpWidget(
          MaterialApp(
            home: Scaffold(
              body: Center(
                child: InteractiveMascot(
                  mood: mood,
                  size: 120,
                ),
              ),
            ),
          ),
        );
        expect(find.byType(InteractiveMascot), findsOneWidget);
      }
    });

    testWidgets('Tapping the mascot triggers speech bubble with study quip and callback', (tester) async {
      bool tapped = false;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: InteractiveMascot(
                mood: MascotMood.idle,
                size: 130,
                onTap: () => tapped = true,
              ),
            ),
          ),
        ),
      );

      // Initially, no dialogue bubble
      expect(find.byType(Text), findsNothing);

      // Tap mascot
      await tester.tap(find.byType(InteractiveMascot));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));

      // Callback triggered
      expect(tapped, isTrue);

      // Speech bubble text appears with one of the study quips
      expect(find.byType(Text), findsOneWidget);

      // Advance clock past 3.5s auto-dismiss + allow 200ms AnimatedSwitcher transition
      await tester.pump(const Duration(milliseconds: 3600));
      await tester.pump(const Duration(milliseconds: 300));
      expect(find.byType(Text), findsNothing);
    });
  });
}
