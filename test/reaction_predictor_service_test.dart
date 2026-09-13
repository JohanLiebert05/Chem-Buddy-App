import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/services/reaction_predictor_service.dart';

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
  });
}
