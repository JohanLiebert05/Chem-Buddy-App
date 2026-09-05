import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/reaction_models.dart';
import 'package:chem_buddy/data/services/reaction_mechanism_service.dart';
import 'package:chem_buddy/data/services/reaction_diagram_svg_catalog.dart';
import 'package:chem_buddy/data/services/reaction_3d_database.dart';
import 'package:chem_buddy/data/services/pdf_ai_study_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Phase 1 - Heterocyclic Chemistry & 3D Lab Parity', () {
    test('ReactionMechanismService has heterocyclic reactions', () {
      final heteroList = ReactionMechanismService.instance.search(
        '',
        category: ReactionCategory.heterocyclic,
      );

      expect(heteroList.length, greaterThanOrEqualTo(3));
      final ids = heteroList.map((m) => m.id).toList();
      expect(ids, contains('fischer_indole'));
      expect(ids, contains('paal_knorr'));
      expect(ids, contains('chichibabin'));

      for (final m in heteroList) {
        expect(m.name.isNotEmpty, isTrue);
        expect(m.steps.isNotEmpty, isTrue);
        expect(m.reactants.isNotEmpty, isTrue);
        expect(m.products.isNotEmpty, isTrue);
      }
    });

    test('ReactionDiagramSvgCatalog returns authentic vector SVGs for heterocyclic mechanisms', () {
      final fischerSvg = ReactionDiagramSvgCatalog.getSvgFor('fischer_indole');
      expect(fischerSvg, contains('Fischer Indole Synthesis'));
      expect(fischerSvg, contains('<svg'));
      expect(fischerSvg, contains('</svg>'));

      final paalKnorrSvg = ReactionDiagramSvgCatalog.getSvgFor('paal_knorr');
      expect(paalKnorrSvg, contains('Paal-Knorr Pyrrole Synthesis'));

      final chichibabinSvg = ReactionDiagramSvgCatalog.getSvgFor('chichibabin');
      expect(chichibabinSvg, contains('Chichibabin Amination'));
    });

    test('Reaction3DDatabase contains 3D sets for all heterocyclic reactions', () {
      const ids = ['fischer_indole', 'paal_knorr', 'chichibabin'];
      for (final id in ids) {
        expect(Reaction3DDatabase.has3D(id), isTrue, reason: 'Missing 3D set for $id');
        final set3D = Reaction3DDatabase.get3DSet(id);
        expect(set3D, isNotNull);
        expect(set3D!.reactant.atoms.isNotEmpty, isTrue);
        expect(set3D.reactant.bonds.isNotEmpty, isTrue);
        expect(set3D.intermediate.atoms.isNotEmpty, isTrue);
        expect(set3D.intermediate.bonds.isNotEmpty, isTrue);
        expect(set3D.product.atoms.isNotEmpty, isTrue);
        expect(set3D.product.bonds.isNotEmpty, isTrue);
      }
    });
  });

  group('Phase 1 - PDF Content-Based Subject Classification', () {
    test('Correctly classifies Organic Chemistry snippet', () {
      const sample = '''
        The mechanism involves an electrophilic aromatic substitution where the carbocation 
        intermediate undergoes rearomatization. Nucleophilic attack by the enolate on the aldehyde 
        yields the aldol condensation product via dehydration.
      ''';
      final result = PdfAiStudyService.classifyDocumentSubject(sample, 'Organic Synthesis Notes.pdf');
      expect(result.detectedSubjectId, equals('organic'));
      expect(result.confidence, greaterThan(0.0));
    });

    test('Correctly classifies Inorganic Chemistry snippet', () {
      const sample = '''
        Crystal field stabilization energy (CFSE) in octahedral complexes of Co(III) with strong field 
        ligands like CN- results in low spin d6 configuration. Coordination number 6 geometry 
        exhibits Jahn-Teller distortion.
      ''';
      final result = PdfAiStudyService.classifyDocumentSubject(sample, 'Coordination Compounds.pdf');
      expect(result.detectedSubjectId, equals('inorganic'));
    });

    test('Correctly classifies Physical Chemistry snippet', () {
      const sample = '''
        The Gibbs free energy change delta G = delta H - T delta S governs spontaneity. 
        Integrated rate law for a first order chemical kinetics reaction demonstrates exponential decay 
        with half life independent of initial concentration.
      ''';
      final result = PdfAiStudyService.classifyDocumentSubject(sample, 'Thermodynamics & Kinetics.pdf');
      expect(result.detectedSubjectId, equals('physical'));
    });

    test('Correctly classifies Analytical Chemistry snippet', () {
      const sample = '''
        High performance liquid chromatography (HPLC) with reverse phase C18 column was coupled to GC-MS. 
        Absorbance followed Beer-Lambert law. Standard deviation and Dixon Q-test were calculated for error analysis.
      ''';
      final result = PdfAiStudyService.classifyDocumentSubject(sample, 'Instrumental Methods of Analysis.pdf');
      expect(result.detectedSubjectId, equals('analytical'));
    });
  });
}
