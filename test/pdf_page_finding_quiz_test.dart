import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/pdf_study_models.dart';
import 'package:chem_buddy/data/services/pdf_ai_study_service.dart';
import 'package:chem_buddy/data/services/reaction_diagram_svg_catalog.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Page-Finding Quiz & Strict Grounding Tests', () {
    test('QuizQuestion properly serializes and deserializes pageNumber, sourceSnippet and isStrictPdfGrounded', () {
      const question = QuizQuestion(
        id: 'q_test_1',
        question: 'What is the rate-determining step in the Cannizzaro reaction?',
        options: [
          'Intermolecular hydride ion transfer',
          'Nucleophilic attack of OH-',
          'Proton transfer',
          'Solvent coordination',
        ],
        correctIndex: 0,
        explanation: 'Hydride transfer is the slow, rate-determining step.',
        type: QuizQuestionType.mechanism,
        topic: 'Cannizzaro Reaction',
        pageNumber: 3,
        sourceSnippet: 'The slow, rate-determining step is the direct intermolecular hydride transfer.',
        isStrictPdfGrounded: true,
      );

      final json = question.toJson();
      expect(json['page_number'], equals(3));
      expect(json['source_snippet'], contains('hydride transfer'));
      expect(json['is_strict_pdf_grounded'], isTrue);

      final fromJson = QuizQuestion.fromJson(json);
      expect(fromJson.pageNumber, equals(3));
      expect(fromJson.sourceSnippet, contains('hydride transfer'));
      expect(fromJson.isStrictPdfGrounded, isTrue);
      expect(fromJson.correctIndex, equals(0));
      expect(fromJson.type, equals(QuizQuestionType.mechanism));
    });

    test('ChemistryQuiz serializes isStrictPdfGrounded and pageRange', () {
      final quiz = ChemistryQuiz(
        id: 'quiz_test_1',
        title: 'Cannizzaro Mechanism Quiz',
        docId: 'doc_123',
        sourceFileName: 'Cannizzaro_Notes.pdf',
        questions: const [
          QuizQuestion(
            id: 'q1',
            question: 'Which aldehyde undergoes Cannizzaro reaction?',
            options: ['Benzaldehyde', 'Acetaldehyde', 'Acetone', 'Propanal'],
            correctIndex: 0,
            explanation: 'Aldehydes with no alpha-hydrogens undergo Cannizzaro reaction.',
            type: QuizQuestionType.reaction,
            pageNumber: 1,
            sourceSnippet: 'Benzaldehyde lacks alpha hydrogens.',
            isStrictPdfGrounded: true,
          ),
        ],
        createdAt: DateTime(2026, 9, 6),
        isStrictPdfGrounded: true,
        pageRange: 'Pages 1 - 5',
      );

      final json = quiz.toJson();
      expect(json['is_strict_pdf_grounded'], isTrue);
      expect(json['page_range'], equals('Pages 1 - 5'));

      final fromJson = ChemistryQuiz.fromJson(json);
      expect(fromJson.isStrictPdfGrounded, isTrue);
      expect(fromJson.pageRange, equals('Pages 1 - 5'));
      expect(fromJson.questions.first.pageNumber, equals(1));
    });

    test('PdfAiStudyService generateQuiz creates strictly page-grounded questions with citations', () async {
      final service = PdfAiStudyService();

      const sampleText = '''
Cannizzaro Reaction involves aldehydes without alpha hydrogens such as benzaldehyde reacting with concentrated alkali.
The rate determining step is the direct intermolecular hydride transfer from tetrahedral intermediate to another aldehyde.
Crossed Cannizzaro with formaldehyde selectively oxidizes formaldehyde to formic acid, reducing aromatic aldehyde to alcohol.
''';

      final quiz = await service.generateQuiz(
        sourceText: sampleText,
        documentTitle: 'Cannizzaro Reaction Study Material',
        count: 5,
      );

      expect(quiz.isStrictPdfGrounded, isTrue);
      expect(quiz.questions.length, equals(5));

      for (final q in quiz.questions) {
        expect(q.isStrictPdfGrounded, isTrue);
        expect(q.pageNumber, isNotNull);
        expect(q.pageNumber!, greaterThanOrEqualTo(1));
        expect(q.options.length, equals(4));
        expect(q.explanation.isNotEmpty, isTrue);
      }
    });
  });

  group('ReactionDiagramSvgCatalog 2D Curved Electron Arrow Tests', () {
    final mechanismIds = [
      'sn1', 'sn2', 'e1', 'e2', 'cannizzaro', 'aldol', 'wittig', 'diels_alder',
      'grignard', 'beckmann', 'benzoin', 'michael', 'claisen', 'baeyer_villiger',
      'favorskii', 'mannich', 'pinacol', 'robinson', 'curtius', 'cope',
      'claisen_sigmatropic', 'fischer_indole', 'paal_knorr', 'chichibabin',
      'oxidative_addition', 'migratory_insertion', 'reductive_elimination'
    ];

    for (final id in mechanismIds) {
      test('getSvgFor($id) returns valid SVG with electron pushing arrow paths and dark theme styling', () {
        final svg = ReactionDiagramSvgCatalog.getSvgFor(id);
        expect(svg.startsWith('<svg'), isTrue);
        expect(svg.trim().endsWith('</svg>'), isTrue);
        expect(svg.contains('xmlns="http://www.w3.org/2000/svg"'), isTrue);
        expect(svg.contains('fill="#141224"'), isTrue);
        expect(svg.contains('marker id="arrow"'), isTrue);
        expect(svg.contains('stroke="#F59E0B"'), isTrue);
        expect(svg.contains('marker-end="url(#arrow)"'), isTrue);
      });
    }
  });
}
