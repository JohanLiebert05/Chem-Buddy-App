import 'package:chem_buddy/presentation/screens/spectroscopy_hub_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('solver reports invalid NMR instead of analyzing a partial list',
      (tester) async {
    await tester.binding.setSurfaceSize(const Size(1100, 1500));
    addTearDown(() => tester.binding.setSurfaceSize(null));
    await tester.pumpWidget(const ProviderScope(
      child: MaterialApp(home: SpectroscopyHubScreen()),
    ));
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.byKey(const ValueKey('Structure Solver')));
    await tester.tap(find.byKey(const ValueKey('Structure Solver')));
    await tester.pumpAndSettle();

    final protonField = find.byWidgetPredicate((widget) => widget is TextField &&
        widget.decoration?.labelText?.startsWith('¹H NMR Shifts') == true);
    await tester.ensureVisible(protonField);
    await tester.enterText(protonField, '2.6, bad, 7.5');
    await tester.pumpAndSettle();
    final analyze = find.text('Analyze spectra');
    await tester.ensureVisible(analyze);
    await tester.tap(analyze);
    await tester.pumpAndSettle();
    await tester.ensureVisible(find.text('Check Spectral Input'));
    expect(find.textContaining('"bad" is not a peak position'), findsOneWidget);

    // Editing invalid input clears the previous result until Analyze is pressed.
    await tester.ensureVisible(protonField);
    await tester.enterText(protonField, '2.6, 7.5, 7.95');
    await tester.pumpAndSettle();
    expect(find.text('Check Spectral Input'), findsNothing);
    expect(tester.takeException(), isNull);
  });
}
