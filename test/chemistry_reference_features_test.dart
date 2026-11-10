import 'package:chem_buddy/presentation/screens/periodic_table_panel.dart';
import 'package:chem_buddy/presentation/screens/pubchem_lookup_screen.dart';
import 'package:chem_buddy/presentation/screens/virtual_labs_panel.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  testWidgets('periodic table finds an element by atomic number', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(
        const MaterialApp(home: Scaffold(body: _ListViewForTable())),
      );
      await rootBundle.loadString('assets/chemistry/periodic_elements.json');
    });
    await tester.pumpAndSettle();
    expect(find.text('Explore 118 elements'), findsOneWidget);
    await tester.enterText(find.byType(TextField), '26');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Iron'));
    await tester.pumpAndSettle();
    expect(find.text('26 · Iron (Fe)'), findsOneWidget);
  });

  testWidgets('virtual density lab requires both measurements', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(home: Scaffold(body: VirtualLabsPanel())),
    );
    await tester.tap(find.text('Identify an unknown metal'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Measure mass on the balance'));
    await tester.pumpAndSettle();
    expect(
      find.text('Which metal matches your calculated density?'),
      findsNothing,
    );
    await tester.tap(find.text('Lower the sample into the cylinder'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Aluminium · 2.70 g/cm³'));
    await tester.pumpAndSettle();
    expect(find.textContaining('which matches aluminium'), findsOneWidget);
  });

  testWidgets('PubChem uses the CID endpoint and displays a returned record', (
    tester,
  ) async {
    Uri? requestUri;
    final client = MockClient((request) async {
      requestUri ??= request.url;
      return http.Response(
        '{"PropertyTable":{"Properties":[{"CID":2519,"Title":"Caffeine","MolecularFormula":"C8H10N4O2"}]}}',
        200,
      );
    });
    await http.runWithClient(
      () => tester.pumpWidget(const MaterialApp(home: PubChemLookupScreen())),
      () => client,
    );
    await tester.enterText(find.byType(TextField), '2519');
    await tester.tap(find.text('Search PubChem'));
    await tester.pumpAndSettle();
    expect(requestUri?.host, 'pubchem.ncbi.nlm.nih.gov');
    expect(
      requestUri?.path,
      startsWith('/rest/pug/compound/cid/2519/property/'),
    );
    expect(find.text('Caffeine'), findsOneWidget);
    expect(find.text('Molecular formula · C8H10N4O2'), findsOneWidget);
  });
}

class _ListViewForTable extends StatelessWidget {
  const _ListViewForTable();

  @override
  Widget build(BuildContext context) =>
      ListView(children: const [PeriodicTablePanel()]);
}
