import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/rdkit_service.dart';

void main() {
  group('RdkitService Tests', () {
    final service = RdkitService.instance;

    test('prewarmEngine initializes without throwing', () async {
      await expectLater(service.prewarmEngine(), completes);
    });

    test('calculateDescriptors computes accurate properties for Benzene', () async {
      final desc = await service.calculateDescriptors('c1ccccc1');

      expect(desc.formula, equals('C6H6'));
      expect(desc.molecularWeight, closeTo(78.11, 0.5));
      expect(desc.exactMass, closeTo(78.04, 0.5));
      expect(desc.dbe, equals(4.0));
      expect(desc.aromaticRings, equals(1));
      expect(desc.hbd, equals(0));
      expect(desc.hba, equals(0));
      expect(desc.lipinskiPass, isTrue);
      expect(desc.lipinskiViolations, isEmpty);
      expect(desc.elementalComposition['C'], closeTo(92.25, 1.0));
      expect(desc.elementalComposition['H'], closeTo(7.75, 1.0));
    });

    test('calculateDescriptors computes accurate properties for Aspirin', () async {
      // Aspirin: Acetylsalicylic acid (C9H8O4)
      final desc = await service.calculateDescriptors('CC(=O)Oc1ccccc1C(=O)O');

      expect(desc.formula, equals('C9H8O4'));
      expect(desc.molecularWeight, closeTo(180.16, 0.8));
      expect(desc.dbe, equals(6.0));
      expect(desc.hbd, greaterThanOrEqualTo(1)); // carboxylic -OH
      expect(desc.hba, equals(4)); // 4 oxygens
      expect(desc.lipinskiPass, isTrue);
      expect(desc.heavyAtomCount, equals(13)); // 9 C + 4 O
    });

    test('calculateDescriptors computes accurate properties for Caffeine', () async {
      // Caffeine: C8H10N4O2
      final desc = await service.calculateDescriptors('CN1C=NC2=C1C(=O)N(C(=O)N2C)C');

      expect(desc.formula, equals('C8H10N4O2'));
      expect(desc.molecularWeight, closeTo(194.19, 0.8));
      expect(desc.dbe, equals(6.0));
      expect(desc.hbd, equals(0));
      expect(desc.hba, equals(6)); // 4 N + 2 O
      expect(desc.lipinskiPass, isTrue);
    });

    test('validateValency detects valid structures and flags Texas Carbon', () async {
      // Valid molecules
      expect((await service.validateValency('c1ccccc1')).isValid, isTrue);
      expect((await service.validateValency('CCO')).isValid, isTrue);
      expect((await service.validateValency('CC(=O)O')).isValid, isTrue);

      // Texas Carbon (exceeding tetravalency)
      final texasCarbon = await service.validateValency('C(=O)(=O)(=O)');
      expect(texasCarbon.isValid, isFalse);
      expect(texasCarbon.errorMessage, contains('Texas Carbon'));

      // Hypervalent nitrogen
      final hyperN = await service.validateValency('N(=O)(=O)(=O)');
      expect(hyperN.isValid, isFalse);
      expect(hyperN.errorMessage, contains('Hypervalent Nitrogen'));

      // Empty structure
      expect((await service.validateValency('')).isValid, isFalse);
    });

    test('smilesToSvg generates valid vector markup', () async {
      final benzeneSvg = await service.smilesToSvg('c1ccccc1');
      expect(benzeneSvg, contains('<svg'));
      expect(benzeneSvg, contains('</svg>'));
      expect(benzeneSvg, contains('<line'));

      final ethanolSvg = await service.smilesToSvg('CCO');
      expect(ethanolSvg, contains('<svg'));
      expect(ethanolSvg, contains('</svg>'));

      final emptySvg = await service.smilesToSvg('');
      expect(emptySvg, contains('No structure'));
    });

    test('generate3DCoordinates produces standard coordinate payload', () async {
      final mol3D = await service.generate3DCoordinates('c1ccccc1');
      expect(mol3D, contains('element'));
      expect(mol3D, contains('"x"'));
      expect(mol3D, contains('"y"'));
      expect(mol3D, contains('"z"'));
    });
  });
}
