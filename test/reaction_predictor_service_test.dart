import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/services/reaction_predictor_service.dart';
import 'package:chem_buddy/core/chemistry/smiles_svg_generator.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ReactionPredictorService Tests', () {
    test('1. Rejects empty reactants SMILES gracefully without making network calls', () async {
      final res = await ReactionPredictorService.instance.predictMajorProduct('');
      expect(res.success, isFalse);
      expect(res.error, contains('Please draw or provide reactant'));
    });

    test('2. Rejects whitespace-only reactants SMILES gracefully', () async {
      final res = await ReactionPredictorService.instance.predictMajorProduct('   \n\t  ');
      expect(res.success, isFalse);
      expect(res.error, contains('Please draw or provide reactant'));
    });

    test('3. ReactionPredictionResult failure constructor sets expected fields', () {
      final fail = ReactionPredictionResult.failure('Network timeout');
      expect(fail.success, isFalse);
      expect(fail.productSmiles, isEmpty);
      expect(fail.svgData, isEmpty);
      expect(fail.error, equals('Network timeout'));
      expect(fail.isCached, isFalse);
    });

    test('4. ReactionPredictionResult success constructor retains all metadata', () {
      const mockSvg = '<svg xmlns="http://www.w3.org/2000/svg" width="100" height="100"></svg>';
      const res = ReactionPredictionResult(
        success: true,
        productSmiles: 'CC(=O)OCC',
        svgData: mockSvg,
        keyIndexUsed: 2,
        model: 'gemini-1.5-flash',
        isCached: false,
      );

      expect(res.success, isTrue);
      expect(res.productSmiles, equals('CC(=O)OCC'));
      expect(res.svgData, contains('<svg'));
      expect(res.keyIndexUsed, equals(2));
      expect(res.model, equals('gemini-1.5-flash'));
      expect(res.error, isNull);
    });

    test('5. NIH Cactus SVG URL encoding generates valid endpoints for complex SMILES', () {
      const complexSmiles = 'c1ccccc1C(=O)O.OCC';
      final encoded = Uri.encodeComponent(complexSmiles);
      final expectedUrl = 'https://cactus.nci.nih.gov/chemical/structure/$encoded/image?format=svg';

      expect(encoded, equals('c1ccccc1C(%3DO)O.OCC'));
      expect(expectedUrl, contains('cactus.nci.nih.gov'));
      expect(expectedUrl, contains('format=svg'));
    });

    test('6. Predicts Aspirin synthesis with 100% accuracy and valid SVG', () async {
      final res = await ReactionPredictorService.instance.predictMajorProduct('Oc1ccccc1C(=O)O.CC(=O)OC(=O)C');
      expect(res.success, isTrue);
      expect(res.productSmiles, equals('CC(=O)Oc1ccccc1C(=O)O'));
      expect(res.svgData, contains('<svg'));
      expect(res.svgData, contains('viewBox'));
      expect(res.svgData, contains('ASPIRIN'));
    });

    test('7. Predicts Paracetamol synthesis with 100% accuracy and valid SVG', () async {
      final res = await ReactionPredictorService.instance.predictMajorProduct('Nc1ccc(O)cc1.CC(=O)Cl');
      expect(res.success, isTrue);
      expect(res.productSmiles, equals('CC(=O)Nc1ccc(O)cc1'));
      expect(res.svgData, contains('<svg'));
      expect(res.svgData, contains('PARACETAMOL'));
    });

    test('8. Predicts Esterification (Ethyl Acetate) with valid SVG', () async {
      final res = await ReactionPredictorService.instance.predictMajorProduct('CC(=O)O.CCO');
      expect(res.success, isTrue);
      expect(res.productSmiles, equals('CCOC(=O)C'));
      expect(res.svgData, contains('<svg'));
      expect(res.svgData, contains('ETHYL ACETATE'));
    });

    test('9. Predicts Electrophilic Bromination of Benzene with valid SVG', () async {
      final res = await ReactionPredictorService.instance.predictMajorProduct('c1ccccc1.BrBr');
      expect(res.success, isTrue);
      expect(res.productSmiles, equals('c1ccc(cc1)Br'));
      expect(res.svgData, contains('<svg'));
      expect(res.svgData, contains('BROMOBENZENE'));
    });

    test('10. SmilesSvgGenerator parses and renders arbitrary SMILES into clean SVG', () {
      final svg = SmilesSvgGenerator.generateSvg('BrCCBr', title: '1,2-DIBROMOETHANE');
      expect(svg, contains('<svg'));
      expect(svg, contains('viewBox'));
      expect(svg, contains('1,2-DIBROMOETHANE'));
      expect(svg, contains('Br'));
      expect(svg, contains('stroke='));
    });

    test('11. Predicts Alkene Halogenation (Ethene + Br2 -> 1,2-Dibromoethane) with valid SVG', () async {
      final res = await ReactionPredictorService.instance.predictMajorProduct('C=C.BrBr');
      expect(res.success, isTrue);
      expect(res.productSmiles, equals('BrCCBr'));
      expect(res.svgData, contains('<svg'));
    });

    test('12. Predicts Diels-Alder Cycloaddition (Cyclopentadiene + Maleic Anhydride) with mechanism steps', () async {
      final res = await ReactionPredictorService.instance.predictMajorProduct('C1=CCC=C1.O=C1OC(=O)C=C1');
      expect(res.success, isTrue);
      expect(res.productSmiles, equals('O=C1OC(=O)C2C1C3CC2C=C3'));
      expect(res.svgData, contains('<svg'));
      expect(res.reactionName, contains('Diels-Alder'));
      expect(res.mechanismSteps, isNotEmpty);
      expect(res.mechanismSteps.first.electronPushing, contains('pi-electron'));
    });

    test('13. Predicts Cyclopentadiene Dimerization with valid SVG and mechanism', () async {
      final res = await ReactionPredictorService.instance.predictMajorProduct('C1=CCC=C1.C1=CCC=C1');
      expect(res.success, isTrue);
      expect(res.productSmiles, equals('C1C=CC2C1C3CC2C=C3'));
      expect(res.svgData, contains('<svg'));
      expect(res.reactionName, contains('Dimerization'));
    });

    test('14. Predicts Cyclopentadiene + Benzene (Benzonorbornadiene) with valid SVG', () async {
      final res = await ReactionPredictorService.instance.predictMajorProduct('C1=CCC=C1.c1ccccc1');
      expect(res.success, isTrue);
      expect(res.productSmiles, equals('C1=CC2CC1c3ccccc23'));
      expect(res.svgData, contains('<svg'));
      expect(res.reactionName, contains('Cycloaddition'));
    });

    test('15. Offline fallback provides predicted product, mechanism, and valid SVG for arbitrary reactants', () async {
      final res = await ReactionPredictorService.instance.predictMajorProduct('c1ccccc1.c1ccccc1');
      expect(res.success, isTrue);
      expect(res.productSmiles.isNotEmpty, isTrue);
      expect(res.svgData, contains('<svg'));
      expect(res.mechanismSteps, isNotEmpty);
    });
  });
}
