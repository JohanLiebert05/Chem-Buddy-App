import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/chemistry_knowledge_engine.dart';
import 'package:chem_buddy/data/services/reaction_predictor_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Organic Reaction Predictor & Mechanism Engine Tests', () {
    test('Predicts Nitration of Benzene with major product and mechanism steps', () {
      final res = ReactionPredictorEngine.predict('What is the reaction mechanism of benzene + HNO3 / H2SO4?');
      expect(res, isNotNull);
      expect(res!.majorProduct, contains('Nitrobenzene'));
      expect(res.mechanismSteps.length, greaterThanOrEqualTo(2));
      expect(res.mechanismSteps.first.title, contains('Nitronium'));
      expect(res.toAcademicMarkdown(), contains('Nitrobenzene'));
      expect(res.toAcademicMarkdown(), contains('Curved Arrows'));
    });

    test('Predicts Nitration of Toluene with ortho/para regioselectivity', () {
      final res = ReactionPredictorEngine.predict('predict the product of toluene + HNO3 and H2SO4');
      expect(res, isNotNull);
      expect(res!.majorProduct, contains('Nitrotoluene'));
      expect(res.selectivity, contains('Ortho/Para'));
    });

    test('Predicts Anti-Markovnikov HBr addition to propene in presence of peroxide', () {
      final res = ReactionPredictorEngine.predict('propene + HBr in presence of peroxide predict product and mechanism');
      expect(res, isNotNull);
      expect(res!.majorProduct, contains('1-Bromopropane'));
      expect(res.selectivity, contains('Anti-Markovnikov'));
      expect(res.mechanismSteps.any((s) => s.title.contains('Radical')), isTrue);
    });

    test('Predicts Markovnikov addition of HBr to propene without peroxide', () {
      final res = ReactionPredictorEngine.predict('propene + HBr');
      expect(res, isNotNull);
      expect(res!.majorProduct, contains('2-Bromopropane'));
      expect(res.selectivity, contains('Markovnikov'));
    });

    test('Predicts Claisen-Schmidt Crossed Aldol Condensation', () {
      final res = ReactionPredictorEngine.predict('acetone + benzaldehyde in dilute NaOH predict mechanism and end product');
      expect(res, isNotNull);
      expect(res!.majorProduct, contains('Benzylideneacetone'));
      expect(res.mechanismSteps.length, greaterThanOrEqualTo(3));
      expect(res.drivingForce, contains('conjugat'));
    });

    test('Predicts Cannizzaro Disproportionation of Benzaldehyde', () {
      final res = ReactionPredictorEngine.predict('benzaldehyde + 50% KOH Cannizzaro reaction');
      expect(res, isNotNull);
      expect(res!.majorProduct, contains('Benzyl Alcohol'));
      expect(res.majorProduct, contains('Potassium Benzoate'));
    });

    test('Predicts Diels-Alder Cycloaddition with cyclopentadiene and maleic anhydride', () {
      final res = ReactionPredictorEngine.predict('cyclopentadiene + maleic anhydride predict end product and stereochemistry');
      expect(res, isNotNull);
      expect(res!.majorProduct, contains('endo-Norbornene'));
      expect(res.selectivity, contains('Endo Rule'));
    });

    test('Predicts Friedel-Crafts Alkylation with 1,2-hydride shift rearrangement', () {
      final res = ReactionPredictorEngine.predict('benzene + 1-chloropropane / AlCl3 predict major product');
      expect(res, isNotNull);
      expect(res!.majorProduct, contains('Isopropylbenzene'));
      expect(res.selectivity, contains('Hydride Shift'));
    });

    test('Predicts Zaitsev vs Hofmann elimination for 2-bromobutane', () {
      final zaitsev = ReactionPredictorEngine.predict('2-bromobutane + alc. KOH heat');
      expect(zaitsev, isNotNull);
      expect(zaitsev!.majorProduct, contains('But-2-ene'));

      final hofmann = ReactionPredictorEngine.predict('2-bromobutane + t-BuOK tert-butoxide elimination');
      expect(hofmann, isNotNull);
      expect(hofmann!.majorProduct, contains('But-1-ene'));
    });

    test('ChemistryKnowledgeEngine seamlessly resolves reaction query with Prediction Engine', () {
      final response = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'Explain the mechanism and predict product for benzene + CH3COCl / AlCl3',
      );
      expect(response.answer, contains('Acetophenone'));
      expect(response.answer, contains('Acylium'));
      expect(response.sources.first.topic, contains('Friedel-Crafts'));
    });
  });
}
