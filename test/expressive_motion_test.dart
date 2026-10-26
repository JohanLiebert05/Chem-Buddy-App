import 'package:chem_buddy/core/widgets/expressive_motion.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('A fast tap still shows a glass spring response', (tester) async {
    await tester.pumpWidget(MaterialApp(home: Scaffold(body: SpringPress(child: FilledButton(onPressed: () {}, child: const Text('Tap'))))));
    await tester.tap(find.text('Tap'));
    await tester.pump(const Duration(milliseconds: 16));
    final transform = tester.widget<Transform>(find.descendant(of: find.byType(SpringPress), matching: find.byType(Transform)).first);
    expect(transform.transform.storage[0], lessThan(.995));
    final glass = tester.widget<DecoratedBox>(find.descendant(of: find.byType(SpringPress), matching: find.byType(DecoratedBox)).first);
    expect((glass.decoration as BoxDecoration).gradient, isNotNull);
    await tester.pumpAndSettle();
  });

  testWidgets('Spring feedback settles and preserves the action', (
    tester,
  ) async {
    var taps = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SpringPress(
            child: FilledButton(
              onPressed: () => taps++,
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Open')),
    );
    await tester.pump(const Duration(milliseconds: 90));
    final pressed = tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(SpringPress),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .storage[0];
    expect(pressed, lessThan(1));
    expect(pressed, greaterThan(.95));
    await gesture.up();
    await tester.pumpAndSettle();
    expect(taps, 1);
    final settled = tester
        .widget<Transform>(
          find
              .descendant(
                of: find.byType(SpringPress),
                matching: find.byType(Transform),
              )
              .first,
        )
        .transform
        .storage[0];
    expect(settled, closeTo(1, .001));
  });
  testWidgets('Reduced motion and disabled buttons stay still', (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: MediaQuery(
          data: const MediaQueryData(disableAnimations: true),
          child: Scaffold(
            body: SpringPress(
              child: FilledButton(onPressed: () {}, child: const Text('Open')),
            ),
          ),
        ),
      ),
    );
    final gesture = await tester.startGesture(
      tester.getCenter(find.text('Open')),
    );
    await tester.pump(const Duration(milliseconds: 90));
    expect(
      tester
          .widget<Transform>(
            find
                .descendant(
                  of: find.byType(SpringPress),
                  matching: find.byType(Transform),
                )
                .first,
          )
          .transform
          .storage[0],
      1,
    );
    await gesture.up();
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: SpringPress(
            child: FilledButton(onPressed: null, child: Text('Disabled')),
          ),
        ),
      ),
    );
    expect(
      find.descendant(
        of: find.byType(SpringPress),
        matching: find.byType(Transform),
      ),
      findsNothing,
    );
    expect(tester.takeException(), isNull);
  });
}
