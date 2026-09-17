import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/pericyclic_service.dart';

void main() {
  group('PericyclicService Woodward-Hoffmann Rules Tests', () {
    test('4n Electrocyclic: Thermal Conrotatory vs Photo Disrotatory', () {
      final thermal = PericyclicService.predict(
        type: PericyclicType.electrocyclic,
        electrons: 4,
        condition: ReactionCondition.thermal,
      );
      expect(thermal.allowedMode, equals('Conrotatory'));
      expect(thermal.forbiddenMode, equals('Disrotatory'));
      expect(thermal.isThermallyAllowed, isTrue);

      final photo = PericyclicService.predict(
        type: PericyclicType.electrocyclic,
        electrons: 4,
        condition: ReactionCondition.photochemical,
      );
      expect(photo.allowedMode, equals('Disrotatory'));
      expect(photo.forbiddenMode, equals('Conrotatory'));
      expect(photo.isThermallyAllowed, isFalse);
    });

    test('4n+2 Electrocyclic: Thermal Disrotatory vs Photo Conrotatory', () {
      final thermal = PericyclicService.predict(
        type: PericyclicType.electrocyclic,
        electrons: 6,
        condition: ReactionCondition.thermal,
      );
      expect(thermal.allowedMode, equals('Disrotatory'));
      expect(thermal.forbiddenMode, equals('Conrotatory'));
      expect(thermal.isThermallyAllowed, isTrue);

      final photo = PericyclicService.predict(
        type: PericyclicType.electrocyclic,
        electrons: 6,
        condition: ReactionCondition.photochemical,
      );
      expect(photo.allowedMode, equals('Conrotatory'));
      expect(photo.forbiddenMode, equals('Disrotatory'));
    });

    test('Cycloadditions: [4+2] Diels-Alder thermal suprafacial vs [2+2] photochemical', () {
      final dielsAlder = PericyclicService.predict(
        type: PericyclicType.cycloaddition,
        electrons: 6,
        condition: ReactionCondition.thermal,
      );
      expect(dielsAlder.allowedMode, contains('[4s+2s]'));
      expect(dielsAlder.isThermallyAllowed, isTrue);

      final twoPlusTwo = PericyclicService.predict(
        type: PericyclicType.cycloaddition,
        electrons: 4,
        condition: ReactionCondition.photochemical,
      );
      expect(twoPlusTwo.allowedMode, contains('[2s+2s]'));
    });
    test('3D Examples: All 5 pericyclic 3D systems have valid coordinates and lobes', () {
      final examples = PericyclicService.threeDExamples;
      expect(examples.length, equals(5));

      for (final ex in examples) {
        expect(ex.title.isNotEmpty, isTrue);
        expect(ex.academicExplanation.isNotEmpty, isTrue);
        expect(ex.system.atoms.isNotEmpty, isTrue);
        expect(ex.system.bonds.isNotEmpty, isTrue);
        expect(ex.system.orbitals.isNotEmpty, isTrue);
        for (final orb in ex.system.orbitals) {
          expect(orb.lobes.every((l) => l.sign == 1 || l.sign == -1), isTrue);
        }
      }
    });

    test('Diels-Alder [4+2] 3D example includes Endo secondary orbital interaction', () {
      final da = PericyclicService.threeDExamples.firstWhere((e) => e.id == 'diels_alder_endo');
      expect(da.secondaryOrbitalNotes, isNotNull);
      expect(da.secondaryOrbitalNotes, contains('Secondary orbital overlap'));
      expect(da.system.atoms.any((a) => a.label.contains('Diene')), isTrue);
      expect(da.system.atoms.any((a) => a.label.contains('Dienophile')), isTrue);
    });

    test('FMO Regioselectivity 3D example highlights largest coefficients', () {
      final regio = PericyclicService.threeDExamples.firstWhere((e) => e.id == 'regioselectivity_fmo');
      expect(regio.title, contains('Regioselectivity'));
      expect(regio.stereochemicalRule, contains('Largest HOMO coefficient pairs with Largest LUMO coefficient'));
    });
  });
}
