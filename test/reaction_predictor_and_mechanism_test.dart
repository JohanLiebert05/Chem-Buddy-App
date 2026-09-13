import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/core/chemistry/chemical_graph.dart';
import 'package:chem_buddy/core/chemistry/electron_arrow_model.dart';
import 'package:chem_buddy/core/chemistry/mechanism_svg_renderer.dart';
import 'package:chem_buddy/data/services/reaction_matcher_engine.dart';
import 'package:chem_buddy/services/reaction_predictor_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Chemical Graph & SVG Renderer Tests', () {
    test('ChemicalGraph calculates valid bounding box and centers', () {
      final graph = ChemicalGraph.createBenzene(cx: 100, cy: 100, r: 40);
      expect(graph.atoms.length, equals(6));
      expect(graph.bonds.length, equals(6));

      final bounds = graph.getBounds();
      expect(bounds.minX, lessThan(100));
      expect(bounds.maxX, greaterThan(100));
      expect(bounds.minY, lessThan(100));
      expect(bounds.maxY, greaterThan(100));
    });

    test('ElectronArrowModel resolves coordinates and curvature', () {
      final graph = ChemicalGraph.createAlkylHalide();
      const arrow = ElectronArrowModel(
        id: 'EF_TEST_01',
        sourceType: ElectronSourceType.lonePair,
        sourceIdentifier: 'LG',
        targetType: ElectronTargetType.atom,
        targetIdentifier: 'C_alpha',
        flowType: ElectronFlowType.lonePairAttack,
        curvature: 0.4,
      );

      final coords = arrow.resolveCoordinates(graph);
      expect(coords.start.dx, greaterThan(0));
      expect(coords.end.dx, greaterThan(0));
      expect(coords.control.dx, greaterThan(0));
    });

    test('MechanismSvgRenderer produces valid vector SVG markup', () {
      final graph = ChemicalGraph.createCarbonyl();
      const arrow = ElectronArrowModel(
        id: 'EF_001',
        sourceType: ElectronSourceType.lonePair,
        sourceIdentifier: 'O_carbonyl',
        targetType: ElectronTargetType.atom,
        targetIdentifier: 'C_carbonyl',
        flowType: ElectronFlowType.resonance,
      );

      final svg = MechanismSvgRenderer.renderStep(
        graph: graph,
        electronFlows: [arrow],
        stepTitle: 'Step 1: Nucleophilic Addition',
        stepDescription: 'Nucleophile attacks carbonyl carbon',
      );

      expect(svg, contains('<svg'));
      expect(svg, contains('xmlns="http://www.w3.org/2000/svg"'));
      expect(svg, contains('id="electron-arrows"'));
      expect(svg, contains('marker id="arrow-full-2e"'));
      expect(svg, contains('</svg>'));
    });

    test('MechanismSvgRenderer renders complete reaction scheme SVG', () {
      final rGraph = ChemicalGraph.createAlkylHalide();
      final pGraph = ChemicalGraph.createCarbonyl();

      final schemeSvg = MechanismSvgRenderer.renderReactionScheme(
        reactantGraph: rGraph,
        productGraph: pGraph,
        reagent: 'NaI',
        solvent: 'Acetone',
        temperature: '25°C',
        reactionName: 'SN2 Substitution Scheme',
      );

      expect(schemeSvg, contains('id="reactants"'));
      expect(schemeSvg, contains('id="reaction-arrow"'));
      expect(schemeSvg, contains('id="products"'));
      expect(schemeSvg, contains('NaI'));
      expect(schemeSvg, contains('Acetone, 25°C'));
    });
  });

  group('Reaction Matcher Engine - Deterministic Chemistry Tests', () {
    final matcher = ReactionMatcherEngine.instance;

    test('1. Predicts SN2 for bromoethane + NaI / Acetone', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: 'CCBr',
        reagents: 'NaI',
        solvent: 'Acetone',
        temperature: '25°C',
      );

      expect(res.isMatched, isTrue);
      expect(res.confidence, equals(ReactionConfidence.high));
      expect(res.reaction?.reactionId, equals('RXN_SN2_001'));
      expect(res.majorProductSmiles, equals('CCI'));
      expect(res.schemeSvg, isNotEmpty);
    });

    test('2. Predicts SN1 for tert-butyl bromide in polar protic solvent', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: 'CC(C)(C)Br',
        reagents: 'H2O',
        solvent: 'H2O / EtOH',
      );

      expect(res.isMatched, isTrue);
      expect(res.confidence, equals(ReactionConfidence.high));
      expect(res.reaction?.reactionId, equals('RXN_SN1_001'));
      expect(res.majorProductSmiles, equals('CC(C)(C)O'));
    });

    test('3. Predicts E2 elimination for alkyl halide with base + heat', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: 'CC(Br)C',
        reagents: 'NaOEt',
        temperature: 'Reflux (75°C)',
      );

      expect(res.isMatched, isTrue);
      expect(res.reaction?.reactionId, equals('RXN_E2_001'));
      expect(res.majorProductSmiles, equals('C=C'));
    });

    test('4. Predicts Carbonyl Reduction with NaBH4', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: 'CC(=O)C',
        reagents: 'NaBH4 / MeOH',
        solvent: 'MeOH',
      );

      expect(res.isMatched, isTrue);
      expect(res.confidence, equals(ReactionConfidence.high));
      expect(res.reaction?.reactionId, equals('RXN_NABH4_RED_001'));
      expect(res.majorProductSmiles, equals('CC(O)C'));
      expect(res.majorProductName, equals('Propan-2-ol'));
    });

    test('5. Predicts EAS Nitration of Benzene', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: 'c1ccccc1',
        reagents: 'HNO3 / H2SO4',
        temperature: '55°C',
      );

      expect(res.isMatched, isTrue);
      expect(res.confidence, equals(ReactionConfidence.high));
      expect(res.reaction?.reactionId, equals('RXN_EAS_NITRATION_001'));
      expect(res.majorProductSmiles, contains('N+](=O)[O-]'));
      expect(res.majorProductName, equals('Nitrobenzene'));
    });

    test('6. Predicts EAS Bromination of Benzene', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: 'c1ccccc1',
        reagents: 'Br2 / FeBr3',
      );

      expect(res.isMatched, isTrue);
      expect(res.reaction?.reactionId, equals('RXN_EAS_HALOGENATION_001'));
      expect(res.majorProductSmiles, equals('c1ccc(Br)cc1'));
      expect(res.majorProductName, equals('Bromobenzene'));
    });

    test('7. Predicts Friedel-Crafts Acylation', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: 'c1ccccc1',
        reagents: 'CH3COCl / AlCl3',
      );

      expect(res.isMatched, isTrue);
      expect(res.reaction?.reactionId, equals('RXN_FC_ACYLATION_001'));
      expect(res.majorProductSmiles, equals('CC(=O)c1ccccc1'));
      expect(res.majorProductName, equals('Acetophenone'));
    });

    test('8. Predicts Grignard Addition to Carbonyl', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: 'CC=O',
        reagents: 'MeMgBr / Et2O',
      );

      expect(res.isMatched, isTrue);
      expect(res.reaction?.reactionId, equals('RXN_GRIGNARD_ALD_001'));
      expect(res.majorProductSmiles, equals('CC(O)C'));
    });

    test('9. Predicts Fischer Esterification', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: 'CC(=O)O',
        reagents: 'EtOH / H2SO4',
      );

      expect(res.isMatched, isTrue);
      expect(res.reaction?.reactionId, equals('RXN_ESTER_FISCHER_001'));
      expect(res.majorProductSmiles, equals('CCOC(=O)C'));
      expect(res.majorProductName, contains('Ester'));
    });

    test('10. Predicts Diels-Alder Cycloaddition', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: 'C=CC=C',
        reagents: 'C=C (Ethylene dienophile)',
      );

      expect(res.isMatched, isTrue);
      expect(res.reaction?.reactionId, equals('RXN_DIELS_ALDER_001'));
      expect(res.majorProductSmiles, equals('C1=CCCCC1'));
    });

    test('11. Gracefully handles unknown or incompatible input without hallucination', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: 'c1ccccc1',
        reagents: 't-BuOK / Heat',
      );

      expect(res.isMatched, isFalse);
      expect(res.confidence, equals(ReactionConfidence.none));
      expect(res.unmatchedReason, contains('could not confidently match'));
      expect(res.suggestions, isNotEmpty);
    });

    test('12. Direct reaction ID lookup', () async {
      final res = await matcher.matchReaction(
        reactantsSmiles: '',
        reagents: '',
        optionalReactionName: 'RXN_WITTIG_001',
      );

      expect(res.isMatched, isTrue);
      expect(res.reaction?.reactionId, equals('RXN_WITTIG_001'));
      expect(res.reaction?.reactionName, contains('Wittig'));
    });
  });

  group('Postgraduate MSc Organic Synthesis Schema Tests', () {
    test('OrganicSynthesisPrediction parses postgraduate JSON schema accurately', () {
      final sampleJson = {
        'reaction_name': 'Aldol Condensation',
        'reaction_class': 'Enolate Chemistry / Carbonyl Addition',
        'reactants_smiles': ['CC(=O)C', 'CC(=O)C'],
        'reagents': 'NaOH, H2O, 25°C',
        'major_product': {
          'name': '4-Methylpent-3-en-2-one (Mesityl Oxide)',
          'smiles': 'CC(=CC(=O)C)C',
          'formula': 'C6H10O',
          'stereochemistry': 'E-alkene preferred'
        },
        'mechanism_steps': [
          {
            'step_number': 1,
            'step_title': 'Enolate Formation',
            'intermediate_smiles': 'C=C([O-])C',
            'description': 'Hydroxide deprotonates alpha proton of acetone generating resonance-stabilized enolate',
            'electron_pushing': 'OH- lone pair abstracts alpha-H; C-H bond collapses into C=C pi bond; C=O pi bond shifts to O'
          },
          {
            'step_number': 2,
            'step_title': 'Nucleophilic Carbonyl Addition',
            'intermediate_smiles': 'CC(C)(O)CC(=O)C',
            'description': 'Enolate nucleophilic alpha carbon attacks electrophilic carbonyl carbon of second acetone molecule',
            'electron_pushing': 'Enolate pi bond attacks electrophilic carbonyl carbon; C=O pi bond shifts onto oxygen'
          }
        ],
        'pedagogy': {
          'driving_force': 'Conjugation of alkene with carbonyl group in alpha,beta-unsaturated ketone',
          'regioselectivity_rule': 'Kinetic vs thermodynamic enolate control governed by base bulk and temperature',
          'viva_question': 'Why is dehydration of aldol addition products particularly facile compared to normal alcohol dehydration?',
          'viva_answer': 'Dehydration is facilitated by alpha-hydrogen acidity and forms conjugated alpha,beta-enone via E1cB pathway.'
        }
      };

      final prediction = OrganicSynthesisPrediction.fromJson(sampleJson, keyIndexUsed: 1, model: 'gemini-1.5-flash');

      expect(prediction.success, isTrue);
      expect(prediction.reactionName, equals('Aldol Condensation'));
      expect(prediction.reactionClass, equals('Enolate Chemistry / Carbonyl Addition'));
      expect(prediction.reactantsSmiles.length, equals(2));
      expect(prediction.majorProduct?.smiles, equals('CC(=CC(=O)C)C'));
      expect(prediction.majorProduct?.formula, equals('C6H10O'));
      expect(prediction.mechanismSteps.length, equals(2));
      expect(prediction.mechanismSteps.first.intermediateSmiles, equals('C=C([O-])C'));
      expect(prediction.mechanismSteps.first.electronPushing, contains('OH- lone pair'));
      expect(prediction.pedagogy?.drivingForce, contains('Conjugation'));
      expect(prediction.pedagogy?.vivaQuestion, contains('facile'));
      expect(prediction.keyIndexUsed, equals(1));
    });
  });
}
