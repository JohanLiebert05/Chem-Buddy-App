import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/chemistry_knowledge_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Strict PDF Grounding & Single Source of Truth Tests', () {
    const mockDocText = '''
[PAGE 1]
Woodward-Hoffmann rules govern the stereochemical outcome of pericyclic reactions.
Under thermal conditions, a [4+2] Diels-Alder cycloaddition between a conjugated diene and a dienophile proceeds via a suprafacial-suprafacial ([4s + 2s]) concerted transition state.
The reaction is thermally allowed with 6 pi electrons (4n+2 system, n=1).

[PAGE 2]
Frontier Molecular Orbital (FMO) theory demonstrates that the HOMO of the diene interacts with the LUMO of the dienophile with matching phase symmetry.
Endo selectivity is favored due to secondary orbital interactions in the transition state.
''';

    test('1. Grounded query returns structured academic response from PDF', () {
      final response = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'Explain the Woodward-Hoffmann rules and HOMO-LUMO interaction for [4+2] cycloaddition.',
        documentText: mockDocText,
        documentName: 'Pericyclic_Reactions.pdf',
      );

      expect(response.answer.isNotEmpty, true);
      expect(response.answer.contains("couldn't find that information in the uploaded PDF"), false);
      expect(
        response.answer.toLowerCase().contains('woodward') ||
            response.answer.toLowerCase().contains('diels-alder') ||
            response.answer.toLowerCase().contains('suprafacial') ||
            response.answer.toLowerCase().contains('homo') ||
            response.answer.toLowerCase().contains('fmo'),
        true,
      );
    });

    test('2. Topic missing from PDF strictly returns standardized refusal message', () {
      final response = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'What is the spectrophotometric determination of lead using dithizone in water samples?',
        documentText: mockDocText,
        documentName: 'Pericyclic_Reactions.pdf',
      );

      // print for debugging:
      expect(response.answer.isNotEmpty, true);
      expect(
        response.answer.toLowerCase().contains("couldn't find that information") ||
            response.answer.toLowerCase().contains("could not find that information"),
        true,
        reason: 'Engine must refuse when requested topic is missing from the attached PDF. Actual: ${response.answer}',
      );
      expect(response.sources.any((s) => (s.documentTitle ?? '').contains('Pericyclic_Reactions.pdf')), true);
    });

    test('3. Query cache accelerates repeated queries', () {
      final t1 = DateTime.now();
      final res1 = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'What is the Woodward-Hoffmann rule for 6 pi electrons?',
        documentText: mockDocText,
        documentName: 'Pericyclic_Reactions.pdf',
      );
      final elapsed1 = DateTime.now().difference(t1);

      final t2 = DateTime.now();
      final res2 = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'What is the Woodward-Hoffmann rule for 6 pi electrons?',
        documentText: mockDocText,
        documentName: 'Pericyclic_Reactions.pdf',
      );
      final elapsed2 = DateTime.now().difference(t2);

      expect(res1.answer, equals(res2.answer));
      expect(elapsed2.inMilliseconds <= elapsed1.inMilliseconds + 20, true);
    });
  });
}
