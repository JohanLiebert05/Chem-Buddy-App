import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/exam_paper_service.dart';

void main() {
  group('Module 3: Exam Mode & Rubric Evaluator Tests', () {
    test('comprehensive70MarkPaper has exact 70 marks split into Part A (20M), Part B (30M), Part C (20M)', () {
      final paper = ExamPaperService.comprehensive70MarkPaper;

      final partA = paper.where((q) => q.marks == 2).toList();
      final partB = paper.where((q) => q.marks == 5).toList();
      final partC = paper.where((q) => q.marks == 10).toList();

      expect(partA.length, equals(10), reason: 'Part A must have exactly 10 questions');
      expect(partB.length, equals(6), reason: 'Part B must have exactly 6 questions');
      expect(partC.length, equals(2), reason: 'Part C must have exactly 2 questions');

      final partAMarks = partA.fold<int>(0, (sum, q) => sum + q.marks);
      final partBMarks = partB.fold<int>(0, (sum, q) => sum + q.marks);
      final partCMarks = partC.fold<int>(0, (sum, q) => sum + q.marks);

      expect(partAMarks, equals(20), reason: 'Part A must be 10 * 2 = 20 marks');
      expect(partBMarks, equals(30), reason: 'Part B must be 6 * 5 = 30 marks');
      expect(partCMarks, equals(20), reason: 'Part C must be 2 * 10 = 20 marks');

      final totalMarks = paper.fold<int>(0, (sum, q) => sum + q.marks);
      expect(totalMarks, equals(70), reason: 'Total paper marks must equal 70 CBCS marks');
    });

    test('getPaperForBranch returns valid papers for all branches with comprehensive paper for all', () {
      final allPaper = ExamPaperService.getPaperForBranch(ChemistryBranch.all);
      final allMarks = allPaper.fold<int>(0, (sum, q) => sum + q.marks);
      expect(allMarks, equals(70), reason: 'Comprehensive blueprint must have 70 marks');

      for (final branch in ChemistryBranch.values) {
        final questions = ExamPaperService.getPaperForBranch(branch);
        expect(questions, isNotEmpty);
        for (final q in questions) {
          expect(q.markingRubric, isNotEmpty);
          expect(q.mandatoryKeywords, isNotEmpty);
        }
      }
    });

    test('evaluateStudentAnswer calculates marks, matches keywords, and awards high score for comprehensive answer', () {
      final question = ExamPaperService.comprehensive70MarkPaper.firstWhere(
        (q) => q.question.toLowerCase().contains('sharpless'),
      );

      final studentAnswer = '''
Sharpless asymmetric epoxidation involves an allylic alcohol reacting with tert-butyl hydroperoxide (TBHP) 
in the presence of titanium(IV) isopropoxide Ti(OiPr)4 and a chiral tartrate ester, specifically (+)-diethyl tartrate or (-)-DET.
The dimeric chiral titanium-tartrate complex creates an asymmetric environment achieving >90% enantiomeric excess (ee). 
The stereochemical mnemonic dictates that (+)-DET delivers oxygen from the bottom (alpha) face when allylic alcohol is oriented horizontally.
''';

      final result = ExamPaperService.evaluateStudentAnswer(
        question: question,
        studentAnswer: studentAnswer,
      );

      expect(result.maxScore, equals(5.0));
      expect(result.score, greaterThanOrEqualTo(4.0));
      expect(result.percentage, greaterThanOrEqualTo(80.0));
      expect(result.matchedKeywords.length, greaterThanOrEqualTo(3));
      expect(result.detectedPitfalls, isEmpty);
    });

    test('evaluateStudentAnswer detects pitfalls and deducts penalties', () {
      final question = ExamPaperService.comprehensive70MarkPaper.firstWhere(
        (q) => q.question.toLowerCase().contains('sharpless'),
      );

      final weakAnswer = '''
Sharpless epoxidation is applied to unfunctionalized alkenes without allylic OH.
The reaction also involves reversing delivery faces.
''';

      final result = ExamPaperService.evaluateStudentAnswer(
        question: question,
        studentAnswer: weakAnswer,
      );

      expect(result.detectedPitfalls, isNotEmpty);
      expect(result.detectedPitfalls.any((p) => p.contains('unfunctionalized alkenes') || p.contains('delivery faces')), isTrue);
      expect(result.score, lessThan(question.marks / 2.0));
      expect(result.missingKeywords, isNotEmpty);
    });

    test('evaluateStudentAnswer awards zero for empty answer with constructive feedback', () {
      final question = ExamPaperService.comprehensive70MarkPaper.first;
      final result = ExamPaperService.evaluateStudentAnswer(
        question: question,
        studentAnswer: '',
      );

      expect(result.score, equals(0.0));
      expect(result.percentage, equals(0.0));
      expect(result.feedback.contains('No answer provided'), isTrue);
    });
  });
}
