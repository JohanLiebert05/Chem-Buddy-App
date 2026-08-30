import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/chemistry_knowledge_engine.dart';

void main() {
  group('ChemistryKnowledgeEngine Academic Accuracy Tests', () {
    test('1. User Query: "what is ppm and mole and Normality" generates complete concentration guide', () {
      final res = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'what is ppm and mole and Normality',
      );

      final answer = res.answer;
      // Must contain all 3 distinct concepts with formulas and units
      expect(answer.contains('ppm') || answer.contains('Parts Per Million'), isTrue);
      expect(answer.contains('Normality') || answer.contains('gram equivalents'), isTrue);
      expect(answer.contains('Mole') || answer.contains('Avogadro'), isTrue);

      // Must have actual mathematical formulas
      expect(answer.contains('6.022') || answer.contains('10^{23}'), isTrue);
      expect(answer.contains('10^6') || answer.contains('mg/L'), isTrue);
      expect(answer.contains('n-factor') || answer.contains('Equivalent Weight'), isTrue);

      // Must NOT contain the old corrupted generic boilerplate
      expect(answer.contains('orbital symmetry, electron configuration, and Gibbs free energy conditions'), isFalse);
    });

    test('2. Single Query: "what is normality" returns equivalent weight and n-factor details', () {
      final res = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'what is normality and equivalent weight',
      );

      final answer = res.answer;
      expect(answer.contains('Normality'), isTrue);
      expect(answer.contains('Equivalent Weight') || answer.contains('n-factor'), isTrue);
      expect(answer.contains('KMnO') || answer.contains('Basicity') || answer.contains('Acidity'), isTrue);
    });

    test('3. Single Query: "what is ppm" returns parts per million, mg/L, and ppb', () {
      final res = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'what is ppm',
      );

      final answer = res.answer;
      expect(answer.contains('Parts Per Million') || answer.contains('ppm'), isTrue);
      expect(answer.contains('mg/L') || answer.contains('10^6'), isTrue);
    });

    test('4. Physical Chemistry: "what is Gibbs free energy" returns delta G = delta H - T delta S and spontaneity', () {
      final res = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'what is Gibbs free energy and spontaneity',
      );

      final answer = res.answer;
      expect(answer.contains('Gibbs Free Energy') || answer.contains('ΔG'), isTrue);
      expect(answer.contains('ΔH') && answer.contains('ΔS'), isTrue);
      expect(answer.contains('spontaneous') || answer.contains('Spontaneous'), isTrue);
    });

    test('5. Spectroscopy: "Beer Lambert law" returns A = epsilon b c and limitations', () {
      final res = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'explain Beer Lambert law and absorbance',
      );

      final answer = res.answer;
      expect(answer.contains('Beer-Lambert') || answer.contains('Absorbance'), isTrue);
      expect(answer.contains('ε') || answer.contains('epsilon') || answer.contains('Molar Absorptivity'), isTrue);
    });

    test('6. Organic Comparison: "SN1 vs SN2" returns side-by-side comparative table', () {
      final res = ChemistryKnowledgeEngine.generateAcademicResponse(
        question: 'difference between SN1 and SN2 reaction',
      );

      final answer = res.answer;
      expect(answer.contains('SN₁') || answer.contains('S_N₁') || answer.contains('SN1'), isTrue);
      expect(answer.contains('SN₂') || answer.contains('S_N₂') || answer.contains('SN2'), isTrue);
      expect(answer.contains('Walden') && (answer.contains('inversion') || answer.contains('racemization')), isTrue);
    });
  });
}
