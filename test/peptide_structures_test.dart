import 'package:chem_buddy/core/chemistry/compound_conformer.dart';
import 'package:chem_buddy/core/chemistry/compound_structure_svg.dart';
import 'package:chem_buddy/core/widgets/molecule_3d/molecule_3d_viewer.dart';
import 'package:chem_buddy/data/models/peptide_reference.dart';
import 'package:chem_buddy/presentation/screens/peptide_library_screen.dart';
import 'package:chem_buddy/presentation/screens/pubchem_conformer_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'every offline peptide has a usable 2D diagram and a 3D model',
    () async {
      final peptides = await PeptideReference.load();
      expect(peptides.length, greaterThanOrEqualTo(18));
      for (final peptide in peptides) {
        final svg = CompoundStructureSvg.fromMolfile(peptide.mol2d);
        expect(svg, isNotNull, reason: peptide.name);
        expect(svg, contains('<path'), reason: peptide.name);
        final model = CompoundConformer.fromMolfile(
          peptide.mol3d,
          id: peptide.cid.toString(),
          name: peptide.name,
          formula: peptide.formula,
        );
        expect(model, isNotNull, reason: peptide.name);
        expect(model!.bonds, isNotEmpty, reason: peptide.name);
        expect(
          model.atoms.any((atom) => atom.z.abs() > .01),
          isTrue,
          reason: peptide.name,
        );
        final elements = <String, int>{};
        for (final atom in model.atoms) {
          if (atom.symbol != 'H') {
            elements.update(
              atom.symbol,
              (count) => count + 1,
              ifAbsent: () => 1,
            );
          }
        }
        final expected = {
          for (final match in RegExp(
            r'([A-Z][a-z]?)(\d*)',
          ).allMatches(peptide.formula))
            if (match[1] != 'H') match[1]!: int.tryParse(match[2]!) ?? 1,
        };
        expect(elements, expected, reason: peptide.name);
        expect(
          CompoundConformer.fromMolfile(
            peptide.mol2d,
            id: '2d',
            name: peptide.name,
            formula: peptide.formula,
          ),
          isNull,
          reason: 'Planar data must not become a 3D model',
        );
      }
      expect(
        peptides.singleWhere((row) => row.name == 'Oxytocin').pdbId,
        '7OFG',
      );
      expect(
        peptides
            .singleWhere((row) => row.name == 'Glutathione disulfide')
            .ccdId,
        'GDS',
      );
    },
  );

  testWidgets('find a peptide by common alias and switch to 3D', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: PeptideLibraryScreen()));
      await PeptideReference.load();
    });
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'GSH');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Glutathione'));
    await tester.pumpAndSettle();
    expect(find.text('2D diagram'), findsOneWidget);
    final detailScroll = find
        .descendant(
          of: find.byType(ListView).last,
          matching: find.byType(Scrollable),
        )
        .first;
    await tester.scrollUntilVisible(
      find.byType(SvgPicture),
      140,
      scrollable: detailScroll,
    );
    expect(find.byType(SvgPicture), findsOneWidget);
    await tester.ensureVisible(find.text('3D conformer'));
    await tester.tap(find.text('3D conformer'));
    await tester.pumpAndSettle();
    expect(find.byType(Molecule3DViewer), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('live PubChem viewer reports a missing conformer', (
    tester,
  ) async {
    Uri? request;
    await http.runWithClient(
      () => tester.pumpWidget(
        const MaterialApp(
          home: PubChemConformerScreen(
            cid: 439302,
            name: 'Oxytocin',
            formula: 'C43H66N12O12S2',
          ),
        ),
      ),
      () => MockClient((req) async {
        request = req.url;
        return http.Response('', 404);
      }),
    );
    await tester.pumpAndSettle();
    expect(request?.path, '/rest/pug/compound/cid/439302/SDF');
    expect(request?.queryParameters['record_type'], '3d');
    expect(
      find.textContaining('does not provide a 3D conformer'),
      findsOneWidget,
    );
  });
}
