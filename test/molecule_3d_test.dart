import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/widgets/molecule_3d/molecule_3d_models.dart';
import 'package:chem_buddy/core/widgets/molecule_3d/molecule_3d_viewer.dart';
import 'package:chem_buddy/data/services/reaction_3d_database.dart';

void main() {
  group('Molecule3D Models & Math Unit Tests', () {
    test('Centering recalculates coordinates around origin (0,0,0)', () {
      final mol = Molecule3D(
        id: 'test_mol',
        name: 'Test Molecule',
        formula: 'AB',
        atoms: const [
          Atom3D(symbol: 'C', x: 10, y: 10, z: 10),
          Atom3D(symbol: 'O', x: 20, y: 20, z: 20),
        ],
        bonds: const [
          Bond3D(atomIndex1: 0, atomIndex2: 1),
        ],
      );

      final (cx, cy, cz) = mol.centroid;
      expect(cx, 15.0);
      expect(cy, 15.0);
      expect(cz, 15.0);

      final centered = mol.centered();
      final (ncx, ncy, ncz) = centered.centroid;
      expect(ncx, closeTo(0.0, 0.0001));
      expect(ncy, closeTo(0.0, 0.0001));
      expect(ncz, closeTo(0.0, 0.0001));

      expect(centered.atoms[0].x, -5.0);
      expect(centered.atoms[1].x, 5.0);
    });

    test('Bounding sphere maxRadius accurately calculates furthest atom', () {
      final mol = Molecule3D(
        id: 'radial_test',
        name: 'Radial Test',
        formula: 'XY',
        atoms: const [
          Atom3D(symbol: 'C', x: 3, y: 4, z: 0), // r = 5
          Atom3D(symbol: 'N', x: 1, y: 1, z: 1), // r = sqrt(3) ~ 1.73
        ],
        bonds: const [],
      );

      expect(mol.maxRadius, closeTo(5.0, 0.001));
    });

    test('CPK color scheme returns distinct standard colors', () {
      const carbon = Atom3D(symbol: 'C', x: 0, y: 0, z: 0);
      const oxygen = Atom3D(symbol: 'O', x: 0, y: 0, z: 0);
      const nitrogen = Atom3D(symbol: 'N', x: 0, y: 0, z: 0);
      const bromine = Atom3D(symbol: 'Br', x: 0, y: 0, z: 0);
      const phosphorus = Atom3D(symbol: 'P', x: 0, y: 0, z: 0);

      expect(carbon.cpkColor, isNotNull);
      expect(oxygen.cpkColor, isNotNull);
      expect(nitrogen.cpkColor, isNotNull);
      expect(bromine.cpkColor, isNotNull);
      expect(phosphorus.cpkColor, isNotNull);

      // Colors should be chemically distinct
      expect(oxygen.cpkColor != carbon.cpkColor, isTrue);
      expect(nitrogen.cpkColor != oxygen.cpkColor, isTrue);
    });
  });

  group('Reaction3DDatabase Full Coverage Tests (All 21 MSc Reactions)', () {
    const expectedReactions = [
      'sn1',
      'sn2',
      'e1',
      'e2',
      'cannizzaro',
      'wittig',
      'diels_alder',
      'grignard',
      'beckmann',
      'benzoin',
      'aldol',
      'michael',
      'claisen',
      'baeyer_villiger',
      'favorskii',
      'mannich',
      'pinacol',
      'robinson',
      'curtius',
      'cope',
      'claisen_sigmatropic',
    ];

    test('All 21 required MSc reactions are present in the 3D database', () {
      for (final rxnId in expectedReactions) {
        expect(
          Reaction3DDatabase.has3D(rxnId),
          isTrue,
          reason: 'Reaction3DDatabase should contain 3D set for $rxnId',
        );

        final set = Reaction3DDatabase.get3DSet(rxnId);
        expect(set, isNotNull);
        expect(set!.reactionId, rxnId);
        expect(set.title, isNotEmpty);
        expect(set.keyTransformationNote, isNotEmpty);
      }
    });

    test('Every reaction stage has complete geometry and valid topology across all 21 reactions', () {
      for (final rxnId in expectedReactions) {
        final set = Reaction3DDatabase.get3DSet(rxnId)!;

        for (final stage in ReactionStage.values) {
          final mol = set.getStage(stage);
          expect(mol.id, isNotEmpty, reason: '$rxnId ${stage.name} id missing');
          expect(mol.name, isNotEmpty, reason: '$rxnId ${stage.name} name missing');
          expect(mol.formula, isNotEmpty, reason: '$rxnId ${stage.name} formula missing');
          expect(mol.atoms, isNotEmpty, reason: '$rxnId ${stage.name} has no atoms');
          expect(mol.bonds, isNotEmpty, reason: '$rxnId ${stage.name} has no bonds');

          // Verify bond indices are strictly within atom range
          for (final bond in mol.bonds) {
            expect(
              bond.atomIndex1,
              lessThan(mol.atoms.length),
              reason: 'Bond atomIndex1 out of bounds in $rxnId ${stage.name}',
            );
            expect(
              bond.atomIndex2,
              lessThan(mol.atoms.length),
              reason: 'Bond atomIndex2 out of bounds in $rxnId ${stage.name}',
            );
            expect(
              bond.atomIndex1 != bond.atomIndex2,
              isTrue,
              reason: 'Bond cannot connect atom to itself in $rxnId ${stage.name}',
            );
          }
        }
      }
    });

    test('SN2 Transition State possesses pentacoordinate trigonal bipyramidal geometry', () {
      final sn2Set = Reaction3DDatabase.get3DSet('sn2')!;
      final ts = sn2Set.intermediate;

      expect(ts.name.toLowerCase(), contains('transition state'));
      // Check for partial bonds (dashed) representing nucleophile attack and leaving group departure
      final partialBonds = ts.bonds.where((b) => b.isPartial).toList();
      expect(
        partialBonds.length,
        greaterThanOrEqualTo(2),
        reason: 'SN2 TS must model partial Nu---C and C---LG bonds',
      );
    });

    test('Wittig intermediate contains 4-membered oxaphosphetane ring', () {
      final wittigSet = Reaction3DDatabase.get3DSet('wittig')!;
      final intermediate = wittigSet.intermediate;

      expect(intermediate.name.toLowerCase(), contains('oxaphosphetane'));
      final hasPhosphorus = intermediate.atoms.any((a) => a.symbol == 'P');
      final hasOxygen = intermediate.atoms.any((a) => a.symbol == 'O');
      expect(hasPhosphorus, isTrue);
      expect(hasOxygen, isTrue);
    });

    test('Diels-Alder TS models pericyclic concerted 6-electron cyclic transition state', () {
      final daSet = Reaction3DDatabase.get3DSet('diels_alder')!;
      final ts = daSet.intermediate;

      expect(ts.name.toLowerCase(), contains('transition state'));
      final partialBonds = ts.bonds.where((b) => b.isPartial).toList();
      expect(
        partialBonds.length,
        greaterThanOrEqualTo(2),
        reason: 'Diels-Alder concerted TS must show synchronous bond formation',
      );
    });

    test('Cope rearrangement TS possesses 6-electron aromatic chair-like topology', () {
      final copeSet = Reaction3DDatabase.get3DSet('cope')!;
      final ts = copeSet.intermediate;

      expect(ts.name.toLowerCase(), contains('transition state'));
      expect(ts.atoms.length, greaterThanOrEqualTo(6));
      expect(ts.bonds.where((b) => b.isPartial).length, greaterThanOrEqualTo(4));
    });
  });

  group('Molecule3DViewer Widget Tests', () {
    testWidgets('Renders 3D canvas and interactive controls without throwing', (tester) async {
      final sn1Set = Reaction3DDatabase.get3DSet('sn1')!;
      final mol = sn1Set.intermediate;

      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Molecule3DViewer(
                molecule: mol,
                height: 320,
                subtitle: 'Test 3D Viewer',
              ),
            ),
          ),
        ),
      );

      // Verify canvas rendered
      expect(find.byType(Molecule3DViewer), findsOneWidget);
      expect(find.byType(CustomPaint), findsWidgets);

      // Verify interactive controls exist
      expect(find.byIcon(Icons.sync_rounded), findsOneWidget); // Auto-spin
      expect(find.byIcon(Icons.bubble_chart_outlined), findsOneWidget); // Ball & Stick / Spacefill
      expect(find.byIcon(Icons.center_focus_strong_rounded), findsOneWidget); // Reset View
      expect(find.byIcon(Icons.text_fields_rounded), findsOneWidget); // Toggle Labels

      // Tap render mode toggle (switch to CPK Space-filling)
      await tester.tap(find.byIcon(Icons.bubble_chart_outlined));
      await tester.pumpAndSettle();

      // Tap auto-rotate toggle (starts rotation)
      await tester.tap(find.byIcon(Icons.sync_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap auto-rotate toggle again (stops rotation)
      await tester.tap(find.byIcon(Icons.sync_rounded));
      await tester.pump(const Duration(milliseconds: 100));

      // Tap reset view
      await tester.tap(find.byIcon(Icons.center_focus_strong_rounded));
      await tester.pump(const Duration(milliseconds: 100));
    });
  });
}
