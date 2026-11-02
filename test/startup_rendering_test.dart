import 'dart:async';

import 'package:chem_buddy/main.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('first frame is branded while services are still pending', (
    tester,
  ) async {
    final pending = Completer<Widget>();
    var calls = 0;
    await tester.pumpWidget(
      ChemBuddyBootstrap(
        initialize: () {
          calls++;
          return pending.future;
        },
      ),
    );
    expect(find.text('ChemBuddy'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(calls, 1);
    await tester.pump(const Duration(seconds: 4));
    expect(find.text('ChemBuddy'), findsOneWidget);
    pending.complete(const MaterialApp(home: Text('Account ready')));
    await tester.pump();
    expect(find.text('Account ready'), findsOneWidget);
    expect(find.text('ChemBuddy'), findsNothing);
  });

  testWidgets('storage failure offers retry without entering an unsafe app', (
    tester,
  ) async {
    var attempts = 0;
    await tester.pumpWidget(
      ChemBuddyBootstrap(
        initialize: () async {
          if (++attempts == 1) {
            throw StateError('Storage temporarily unavailable');
          }
          return const MaterialApp(home: Text('Recovered data'));
        },
      ),
    );
    await tester.pump();
    expect(find.text('Unable to open your saved data.'), findsOneWidget);
    await tester.tap(find.text('Try again'));
    await tester.pump();
    expect(attempts, 2);
    expect(find.text('Recovered data'), findsOneWidget);
  });
}
