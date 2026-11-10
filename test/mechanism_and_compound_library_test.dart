import 'dart:convert';

import 'package:chem_buddy/core/chemistry/compound_structure_svg.dart';
import 'package:chem_buddy/data/services/chemical_name_database.dart';
import 'package:chem_buddy/data/services/reaction_curation_repository.dart';
import 'package:chem_buddy/data/services/reaction_mechanism_service.dart';
import 'package:chem_buddy/presentation/screens/compound_library_screen.dart';
import 'package:chem_buddy/presentation/widgets/electron_flow_diagram.dart';
import 'package:chem_buddy/presentation/widgets/mechanism_step_viewer.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test(
    'curation assigns source and target identifiers to their own step',
    () async {
      final repository = ReactionCurationRepository.instance;
      final reaction = await repository.getReactionById('RXN_SN2_001');
      expect(reaction, isNotNull);
      final step = reaction!.steps.single;
      expect(step.stepId, 'ST_SN2_01');
      expect(step.intermediateGraph, isNull);
      expect(step.electronFlows.map((flow) => flow.sourceIdentifier), [
        'Nu1',
        'C1-LG1',
      ]);
      expect(step.electronFlows.map((flow) => flow.targetIdentifier), [
        'C1',
        'LG1',
      ]);
      expect(reaction.examples.first.reactantSmiles, 'CCBr');
      expect(reaction.examples.first.expectedProductSmiles, 'CCI');
    },
  );

  test(
    'bundled records produce scalable structures with atom and bond geometry',
    () async {
      final asset = await rootBundle.loadString(
        'assets/chemistry/compound_structures.json',
      );
      final records = jsonDecode(asset) as Map<String, dynamic>;
      expect(records.length, greaterThanOrEqualTo(100));
      final diagrams = records.map(
        (name, data) => MapEntry(
          name,
          CompoundStructureSvg.fromMolfile(data['mol'] as String),
        ),
      );
      expect(diagrams.values.whereType<String>().length, records.length);
      expect(diagrams['Water'], contains('>O</text>'));
      expect(diagrams['Caffeine'], contains('<path'));
      expect(diagrams['Methane'], contains('>H</text>'));
      expect(diagrams['Sodium chloride'], contains('>Cl</text>'));
      expect(CompoundStructureSvg.fromMolfile('invalid'), isNull);
    },
  );

  test(
    'basic organic names resolve and tartaric stereoisomers stay distinct',
    () async {
      for (final (alias, name) in [
        ('propanedioic acid', 'Malonic acid'),
        ('MEK', 'Methyl ethyl ketone'),
        ('HCOOH', 'Formic acid'),
      ]) {
        expect(ChemicalNameDatabase.lookupByName(alias)?.commonName, name);
      }
      final asset = await rootBundle.loadString(
        'assets/chemistry/compound_structures.json',
      );
      final structures = jsonDecode(asset) as Map<String, dynamic>;
      for (final (alias, name, cid) in [
        ('L-tartaric acid', 'Tartaric acid', 444305),
        ('D-(-)-tartaric acid', 'D-Tartaric acid', 439655),
        ('mesotartaric acid', 'meso-Tartaric acid', 447315),
      ]) {
        final compound = ChemicalNameDatabase.lookupByName(alias);
        expect(compound?.commonName, name);
        expect(compound?.formula, 'C4H6O6');
        expect(structures[name]['cid'], cid);
      }
    },
  );

  testWidgets('step viewer renders authored arrows and advances', (
    tester,
  ) async {
    final mechanism = ReactionMechanismService.instance.find('sn2')!;
    await tester.runAsync(() async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: MechanismStepViewer(mechanism: mechanism),
            ),
          ),
        ),
      );
      await Future.wait(
        mechanism.steps.map((step) => rootBundle.loadString(step.svgAsset!)),
      );
    });
    await tester.pumpAndSettle();
    expect(find.byType(ElectronFlowDiagram), findsOneWidget);
    expect(find.text('hydroxide lone pair → C2'), findsOneWidget);
    await tester.ensureVisible(find.byTooltip('Next step'));
    await tester.tap(find.byTooltip('Next step'));
    await tester.pumpAndSettle();
    expect(find.text('Step 2 of 3'), findsOneWidget);
    expect(find.text('Trigonal bipyramidal TS'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });

  testWidgets('compound library finds aliases and opens an offline SVG', (
    tester,
  ) async {
    await tester.runAsync(() async {
      await tester.pumpWidget(const MaterialApp(home: CompoundLibraryScreen()));
      await rootBundle.loadString('assets/chemistry/compound_structures.json');
    });
    await tester.pumpAndSettle();
    await tester.enterText(find.byType(TextField), 'aspirin');
    await tester.pumpAndSettle();
    await tester.tap(find.text('Acetylsalicylic acid'));
    await tester.pumpAndSettle();
    expect(find.textContaining('PubChem CID 2244'), findsOneWidget);
    expect(find.byType(SvgPicture), findsOneWidget);
  });
}
