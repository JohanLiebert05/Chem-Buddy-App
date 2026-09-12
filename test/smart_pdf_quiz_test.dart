import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/models/pdf_study_models.dart';
import 'package:chem_buddy/data/services/pdf_ai_study_service.dart';
import 'package:chem_buddy/data/services/gemini_flashcard_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  const sampleCoordinationPdf = '''
[PAGE 1]
Crystal Field Theory (CFT) explains the bonding in transition metal complexes.
In an octahedral crystal field, the five degenerate d-orbitals split into two sets:
lower energy t2g orbitals (dxy, dyz, dxz) and higher energy eg orbitals (dx2-y2, dz2).
The energy difference between t2g and eg is denoted as Delta_o or 10 Dq.
Crystal Field Stabilization Energy (CFSE) depends on ligand field strength.
Strong field ligands like CN- and CO cause large Delta_o and form low-spin complexes.
Weak field ligands like I- and Cl- cause small Delta_o and form high-spin complexes.

[PAGE 2]
The spectrochemical series arranges ligands in order of increasing field strength:
I- < Br- < S2- < SCN- < Cl- < NO3- < F- < OH- < C2O4(2-) < H2O < NCS- < EDTA(4-) < NH3 < en < bpy < phen < NO2- < PPh3 < CN- < CO.
Jahn-Teller distortion occurs in non-linear molecules with electronically degenerate ground states.
For example, d9 Cu(II) octahedral complexes undergo tetragonal elongation (z-out distortion), where axial bonds are longer than equatorial bonds.
The magnetic moment is calculated using the spin-only formula: mu_s = sqrt(n(n+2)) BM, where n is the number of unpaired electrons.
''';

  group('Smart PDF Document Understanding & Concept Analysis Tests', () {
    test('1. analyzeDocumentForQuiz extracts domain, topics, and importance', () async {
      final service = PdfAiStudyService();
      final analysis = await service.analyzeDocumentForQuiz(
        sourceText: sampleCoordinationPdf,
        documentTitle: 'Coordination_Chemistry_Notes.pdf',
      );

      expect(analysis.detectedSubject, equals('Inorganic Chemistry'));
      expect(analysis.coreTopics.isNotEmpty, isTrue);

      // Verify at least one high importance topic
      final highTopics = analysis.highPriorityTopics;
      expect(highTopics.isNotEmpty, isTrue);

      // Verify page mapping
      expect(analysis.pageTopicMap.containsKey(1), isTrue);
      expect(analysis.pageTopicMap.containsKey(2), isTrue);

      // Verify key definitions and equations
      expect(analysis.keyDefinitions.isNotEmpty, isTrue);
    });

    test('2. classifyDocumentSubject accurately detects branch from content', () {
      final subject1 = PdfAiStudyService.classifyDocumentSubject(
        'IR spectroscopy, NMR chemical shift delta, spin-spin coupling J, mass spectrometry fragments',
        'Spectroscopy.pdf',
      );
      expect(subject1.detectedSubject, equals('Spectroscopy & Structure'));

      final subject2 = PdfAiStudyService.classifyDocumentSubject(
        'Enthalpy Delta H, Gibbs Free Energy Delta G, Carnot engine, chemical potential mu',
        'Thermodynamics.pdf',
      );
      expect(subject2.detectedSubject, equals('Physical Chemistry'));
    });
  });

  group('Strict PDF Grounding & Single Source of Truth Quiz Generation Tests', () {
    test('3. generateQuiz produces valid grounded quiz with PdfQuizConfig', () async {
      final service = PdfAiStudyService();
      const config = PdfQuizConfig(
        count: 10,
        difficulty: QuizDifficulty.mixed,
        mode: QuizMode.smartQuiz,
      );

      final quiz = await service.generateQuiz(
        sourceText: sampleCoordinationPdf,
        documentTitle: 'Coordination Chemistry',
        config: config,
      );

      expect(quiz.title, contains('Coordination Chemistry'));
      expect(quiz.questions.isNotEmpty, isTrue);
      expect(quiz.difficulty, equals(QuizDifficulty.mixed));
      expect(quiz.mode, equals(QuizMode.smartQuiz));

      for (final q in quiz.questions) {
        // Must have question text
        expect(q.question.isNotEmpty, isTrue);
        // Must have exactly 4 choices
        expect(q.options.length, equals(4));
        // Correct answer index within bounds
        expect(q.correctIndex >= 0 && q.correctIndex < 4, isTrue);
        // Explanation must be grounded and non-empty
        expect(q.explanation.isNotEmpty, isTrue);
        // No DISPLAY_MATH_0 leak!
        expect(q.question.contains('DISPLAY_MATH_0'), isFalse);
        expect(q.explanation.contains('DISPLAY_MATH_0'), isFalse);
        for (final opt in q.options) {
          expect(opt.contains('DISPLAY_MATH_0'), isFalse);
        }
      }
    });

    test('4. validateQuizQuestions sanitizes math tokens and ensures valid options', () {
      final service = PdfAiStudyService();
      final malformedQuestions = [
        const QuizQuestion(
          id: 'q1',
          question: 'What is the split in octahedral field? DISPLAY_MATH_0',
          options: ['t2g and eg', 't1u and a1g', 'eg and t1g', 't2g and eg'],
          correctIndex: 0,
          explanation: 'As shown in DISPLAY_MATH_0, d orbitals split into t2g and eg.',
          type: QuizQuestionType.conceptual,
          pageNumber: 1,
          topic: 'Crystal Field Theory',
        ),
        const QuizQuestion(
          id: 'q2',
          question: 'Broken question with insufficient options',
          options: ['Only one'],
          correctIndex: 0,
          type: QuizQuestionType.conceptual,
          explanation: 'Not enough choices',
        ),
      ];

      final validated = service.validateQuizQuestions(malformedQuestions);

      // Question 2 should be rejected because options < 2
      expect(validated.length, equals(1));

      final q1 = validated.first;
      // DISPLAY_MATH_0 should be stripped
      expect(q1.question.contains('DISPLAY_MATH_0'), isFalse);
      expect(q1.explanation.contains('DISPLAY_MATH_0'), isFalse);
      // Duplicate options should be fixed (must have 4 distinct options)
      expect(q1.options.length, equals(4));
      final uniqueOpts = q1.options.toSet();
      expect(uniqueOpts.length, equals(4));
    });

    test('5. generateWeakTopicQuiz creates targeted quiz on weak areas', () async {
      final service = PdfAiStudyService();
      final prevResult = QuizResult(
        id: 'r1',
        quizId: 'q1',
        quizTitle: 'Coordination Quiz',
        score: 1,
        totalQuestions: 2,
        accuracy: 50.0,
        weakTopics: const ['Jahn-Teller distortion', 'Spectrochemical series'],
        recommendedRevision: const ['Review CFT page 1'],
        userAnswers: const {0: 1, 1: 0},
        completedAt: DateTime.now(),
      );

      final weakQuiz = await service.generateWeakTopicQuiz(
        previousResult: prevResult,
        sourceText: sampleCoordinationPdf,
        documentTitle: 'Coordination Chemistry',
        docId: 'coord_doc_1',
      );

      expect(weakQuiz.title, contains('Weak Topics Practice'));
      expect(weakQuiz.mode, equals(QuizMode.weakTopics));
      expect(weakQuiz.questions.isNotEmpty, isTrue);
      // All questions must be valid
      for (final q in weakQuiz.questions) {
        expect(q.options.length, equals(4));
        expect(q.correctIndex >= 0 && q.correctIndex < 4, isTrue);
        expect(q.explanation.isNotEmpty, isTrue);
      }
    });

    test('6. Quiz strictly reflects PDF topic and NEVER generates unrelated HPLC questions', () async {
      final service = PdfAiStudyService();

      // 1. Coordination chemistry text
      final coordQuiz = await service.generateQuiz(
        sourceText: sampleCoordinationPdf,
        documentTitle: 'Coordination Chemistry',
        config: const PdfQuizConfig(count: 8),
      );

      expect(coordQuiz.questions.isNotEmpty, isTrue);
      for (final q in coordQuiz.questions) {
        final qText = '${q.question} ${q.explanation} ${q.options.join(" ")}'.toLowerCase();
        expect(qText.contains('hplc'), isFalse, reason: 'Off-topic HPLC question generated: ${q.question}');
        expect(qText.contains('c18 column'), isFalse, reason: 'Off-topic C18 question generated: ${q.question}');
        expect(qText.contains('van deemter'), isFalse, reason: 'Off-topic Van Deemter question generated: ${q.question}');
      }

      // 2. Organic text containing common words with "lc" (molecule, alcohol, calculation)
      const organicNoteWithLcWords = '''
[PAGE 1]
Nucleophilic substitution reactions depend heavily on molecular geometry.
In an SN2 mechanism, the nucleophile attacks the carbon center from the backside.
Alcohols are converted to alkyl halides using thionyl chloride (SOCl2) or phosphorus tribromide (PBr3).
The calculation of reaction yield is based on stoichiometry.
''';

      final organicQuiz = await service.generateQuiz(
        sourceText: organicNoteWithLcWords,
        documentTitle: 'Organic Substitution Reactions',
        config: const PdfQuizConfig(count: 5),
      );

      expect(organicQuiz.questions.isNotEmpty, isTrue);
      for (final q in organicQuiz.questions) {
        final qText = '${q.question} ${q.explanation} ${q.options.join(" ")}'.toLowerCase();
        expect(qText.contains('hplc'), isFalse, reason: 'Off-topic HPLC question generated for organic text: ${q.question}');
        expect(qText.contains('c18 column'), isFalse);
        expect(qText.contains('van deemter'), isFalse);
        expect(qText.contains('chromatograph'), isFalse);
      }
    });
  });

  group('Flashcard Service Cache & Acceleration Tests', () {
    test('7. GeminiFlashcardService in-memory cache accelerates repeated lookups', () async {
      final service = GeminiFlashcardService();
      const mockNote = 'Beer-Lambert law: A = epsilon * c * l, where A is absorbance, c is molar concentration.';

      final cards1 = await service.generate(
        sourceText: mockNote,
        count: 5,
        topic: 'Beer-Lambert Law',
      );

      final start2 = DateTime.now();
      final cards2 = await service.generate(
        sourceText: mockNote,
        count: 5,
        topic: 'Beer-Lambert Law',
      );
      final dur2 = DateTime.now().difference(start2).inMilliseconds;

      expect(cards1.length, equals(cards2.length));
      expect(cards1.first.question, equals(cards2.first.question));
      expect(dur2, lessThanOrEqualTo(100));
    });
  });
}