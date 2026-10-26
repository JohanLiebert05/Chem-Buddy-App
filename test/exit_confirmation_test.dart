import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/exit_confirmation.dart';

void main() {
  testWidgets('root back asks once; Stay and dialog back preserve the app', (
    tester,
  ) async {
    var exits = 0;
    await tester.pumpWidget(
      MaterialApp(
        home: ExitConfirmation(
          enabled: true,
          onExit: () => exits++,
          child: const Scaffold(body: Text('Study space')),
        ),
      ),
    );
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Exit ChemBuddy?'), findsOneWidget);
    await tester.tap(find.text('Stay'));
    await tester.pumpAndSettle();
    expect(find.text('Exit ChemBuddy?'), findsNothing);
    expect(exits, 0);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(exits, 0);
    expect(find.text('Exit ChemBuddy?'), findsNothing);
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    await tester.tap(find.text('Exit'));
    await tester.pumpAndSettle();
    expect(exits, 1);
  });
  testWidgets('back on a child page navigates without asking to exit', (
    tester,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: ExitConfirmation(
          enabled: true,
          onExit: () {},
          child: Scaffold(
            body: Builder(
              builder: (context) => TextButton(
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute<void>(
                    builder: (_) => const Scaffold(body: Text('Child page')),
                  ),
                ),
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
    await tester.binding.handlePopRoute();
    await tester.pumpAndSettle();
    expect(find.text('Open'), findsOneWidget);
    expect(find.text('Exit ChemBuddy?'), findsNothing);
  });
}
