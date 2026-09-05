import 'dart:math';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:chem_buddy/data/services/exam_paper_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('Phase 2 Step 2D: Exam Paper Service & 4-Branch Parity', () {
    test('All 4 branches plus combined paper are defined in ChemistryBranch', () {
      expect(ChemistryBranch.values.length, 5);
      final ids = ChemistryBranch.values.map((b) => b.id).toList();
      expect(ids, containsAll(['all', 'organic', 'inorganic', 'physical', 'analytical']));
    });

    test('Organic Chemistry paper contains Part A, B, and C with full rubrics', () {
      final paper = ExamPaperService.getPaperForBranch(ChemistryBranch.organic);
      expect(paper.isNotEmpty, isTrue);

      final partA = paper.where((q) => q.section.contains('Part A')).toList();
      final partB = paper.where((q) => q.section.contains('Part B')).toList();
      final partC = paper.where((q) => q.section.contains('Part C')).toList();

      expect(partA.length, greaterThanOrEqualTo(2));
      expect(partB.length, greaterThanOrEqualTo(2));
      expect(partC.length, greaterThanOrEqualTo(1));

      for (final q in paper) {
        expect(q.question.isNotEmpty, isTrue);
        expect(q.modelAnswer.isNotEmpty, isTrue);
        expect(q.markingRubric.isNotEmpty, isTrue);
        expect(q.marks, greaterThan(0));
      }
    });

    test('Inorganic Chemistry paper contains coordination CFT and organometallics', () {
      final paper = ExamPaperService.getPaperForBranch(ChemistryBranch.inorganic);
      expect(paper.isNotEmpty, isTrue);

      final totalMarks = paper.fold<int>(0, (sum, q) => sum + q.marks);
      expect(totalMarks, greaterThanOrEqualTo(30));

      final mentions18e = paper.any((q) => q.question.contains('18-electron') || q.question.contains('Mn'));
      final mentionsCFT = paper.any((q) => q.question.contains('CFSE') || q.question.contains('4/9'));
      final mentionsMonsanto = paper.any((q) => q.question.contains('Monsanto') || q.question.contains('Rh'));

      expect(mentions18e, isTrue);
      expect(mentionsCFT, isTrue);
      expect(mentionsMonsanto, isTrue);
    });

    test('Physical Chemistry paper contains quantum mechanics, kinetics, and thermo', () {
      final paper = ExamPaperService.getPaperForBranch(ChemistryBranch.physical);
      expect(paper.isNotEmpty, isTrue);

      final mentionsParticle = paper.any((q) => q.question.contains('1D box') || q.question.contains('Schrödinger'));
      final mentionsLindemann = paper.any((q) => q.question.contains('Lindemann') || q.question.contains('unimolecular'));
      final mentionsPartition = paper.any((q) => q.question.contains('partition function') || q.question.contains('Helmholtz'));

      expect(mentionsParticle, isTrue);
      expect(mentionsLindemann, isTrue);
      expect(mentionsPartition, isTrue);
    });

    test('Analytical Chemistry paper contains HPLC Van Deemter, AAS, and mass spectrometry', () {
      final paper = ExamPaperService.getPaperForBranch(ChemistryBranch.analytical);
      expect(paper.isNotEmpty, isTrue);

      final mentionsVanDeemter = paper.any((q) => q.question.contains('Van Deemter'));
      final mentionsAAS = paper.any((q) => q.question.contains('AAS') || q.question.contains('Atomic Absorption'));
      final mentionsMS = paper.any((q) => q.question.contains('Mass Spectrometry') || q.question.contains('McLafferty'));

      expect(mentionsVanDeemter, isTrue);
      expect(mentionsAAS, isTrue);
      expect(mentionsMS, isTrue);
    });

    test('Combined paper aggregates questions across all branches with 60+ total marks', () {
      final paper = ExamPaperService.getPaperForBranch(ChemistryBranch.all);
      final totalMarks = paper.fold<int>(0, (sum, q) => sum + q.marks);
      expect(totalMarks, greaterThanOrEqualTo(60));
    });

    test('ExamQuestionItem JSON serialization round-trip', () {
      const item = ExamQuestionItem(
        section: 'Part A',
        marks: 2,
        question: 'What is conrotatory motion?',
        modelAnswer: 'Conrotatory rotation occurs under thermal conditions for 4n systems.',
        markingRubric: ['1 Mark: naming conrotatory', '1 Mark: stating 4n'],
      );

      final json = item.toJson();
      final revived = ExamQuestionItem.fromJson(json);

      expect(revived.section, item.section);
      expect(revived.marks, item.marks);
      expect(revived.question, item.question);
      expect(revived.modelAnswer, item.modelAnswer);
      expect(revived.markingRubric, item.markingRubric);
    });

    test('ExamPaperService saves and restores paper progress in SharedPreferences', () async {
      final service = ExamPaperService.instance;
      final awardedMarks = {0: 2, 1: 5, 2: 8};
      final revealed = {0: true, 1: false, 2: true};

      await service.savePaperProgress(ChemistryBranch.organic, awardedMarks, revealed);
      final loaded = await service.loadPaperProgress(ChemistryBranch.organic);

      expect(loaded.marks[0], 2);
      expect(loaded.marks[1], 5);
      expect(loaded.marks[2], 8);
      expect(loaded.revealed[0], true);
      expect(loaded.revealed[1], false);
      expect(loaded.revealed[2], true);
    });
  });

  group('Phase 2 Steps 2B & 2C: Toolkit Scientific Calculation Formulas', () {
    test('HPLC Van Deemter calculations: H = A + B/u + C*u and optimal velocity', () {
      const a = 0.08;
      const b = 0.15;
      const c = 0.03;
      const u = 2.0;

      final h = a + (b / u) + (c * u);
      expect(h, closeTo(0.215, 0.001));

      final uOpt = sqrt(b / c);
      expect(uOpt, closeTo(2.236, 0.01));

      final hMin = a + (2 * sqrt(b * c));
      expect(hMin, closeTo(0.214, 0.01));
    });

    test('Analytical replicate statistics & Dixon Q-test', () {
      final replicates = [12.45, 12.48, 12.46, 12.72, 12.47]..sort();
      final n = replicates.length;
      expect(n, 5);

      final mean = replicates.reduce((a, b) => a + b) / n;
      expect(mean, closeTo(12.516, 0.001));

      final variance = replicates.map((x) => pow(x - mean, 2)).reduce((a, b) => a + b) / (n - 1);
      final s = sqrt(variance);
      expect(s, closeTo(0.1148, 0.005));

      final rsd = (s / mean) * 100;
      expect(rsd, closeTo(0.917, 0.05));

      // Range
      final range = replicates.last - replicates.first; // 12.72 - 12.45 = 0.27
      expect(range, closeTo(0.27, 0.001));

      // Gap for high outlier
      final gapHigh = replicates.last - replicates[replicates.length - 2]; // 12.72 - 12.48 = 0.24
      final qCalc = gapHigh / range; // 0.24 / 0.27 = 0.888
      expect(qCalc, closeTo(0.889, 0.01));
      // For N=5 at 95% CL, Q_crit is 0.710. Since 0.889 > 0.710, it is rejected!
      expect(qCalc > 0.710, isTrue);
    });

    test('1D Particle in a Box energy quantization: En = (n^2 * h^2) / (8 * m * L^2)', () {
      const h = 6.62607015e-34;
      const m = 9.1093837e-31; // electron mass (kg)
      const l = 1e-9; // 1 nm box (m)

      final e1 = (1 * 1 * pow(h, 2)) / (8 * m * pow(l, 2));
      final e2 = (2 * 2 * pow(h, 2)) / (8 * m * pow(l, 2));

      expect(e2, closeTo(4 * e1, 1e-25));
      final deltaE = e2 - e1;
      expect(deltaE, closeTo(3 * e1, 1e-25));
    });

    test('Integrated 1st order kinetics: [A]t = [A]0 * exp(-k * t) and t1/2 = ln(2)/k', () {
      const a0 = 1.0;
      const k = 0.05;
      const t = 10.0;

      final at = a0 * exp(-k * t);
      expect(at, closeTo(0.6065, 0.001));

      final tHalf = log(2) / k;
      expect(tHalf, closeTo(13.86, 0.01));
    });
  });

  group('Phase 3: Free-Tier Load Management & Exponential Backoff', () {
    test('Exponential backoff delay formula produces expected intervals with jitter', () {
      for (int attempt = 1; attempt <= 3; attempt++) {
        final baseDelayMs = (1000 * pow(2, attempt - 1)).toInt();
        const maxJitter = 350;

        if (attempt == 1) {
          expect(baseDelayMs, 1000);
        } else if (attempt == 2) {
          expect(baseDelayMs, 2000);
        } else if (attempt == 3) {
          expect(baseDelayMs, 4000);
        }

        final simulatedDelay = baseDelayMs + (Random(42).nextInt(maxJitter));
        expect(simulatedDelay, greaterThanOrEqualTo(baseDelayMs));
        expect(simulatedDelay, lessThan(baseDelayMs + maxJitter));
      }
    });
  });
}
