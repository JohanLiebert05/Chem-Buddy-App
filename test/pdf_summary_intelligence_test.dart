import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/chemistry_knowledge_engine.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('PDF Attachment Executive Summary Intelligence Tests', () {
    test('generateDocumentSummary creates structured executive dossier for Organic Chemistry notes', () {
      const samplePdfText = """
# Department of Chemistry - Advanced Organic Chemistry Notes
## Module 3: Electrophilic Aromatic Substitution and Pericyclic Reactions
The nitration of benzene proceeds through the generation of nitronium ion (NO2+) via HNO3 and H2SO4.
The Diels-Alder reaction represents a concerted [4+2] cycloaddition between a conjugated diene and a dienophile.
Stereochemistry is governed by the Alder Endo Rule.
Also discussed: Aldol condensation of acetaldehyde and acetone, and Wittig reaction using phosphonium ylides.
Beer-Lambert Law: A = ε · c · l applies in spectral tracking.
""";

      final summary = ChemistryKnowledgeEngine.generateDocumentSummary(samplePdfText, 'Organic_Chemistry_Module_3.pdf');
      expect(summary, contains('Executive Summary & Analysis'));
      expect(summary, contains('Organic_Chemistry_Module_3.pdf'));
      expect(summary, contains('Organic Chemistry & Reaction Mechanisms'));
      expect(summary, contains('Diels-Alder [4+2] Cycloaddition'));
      expect(summary, contains('Suggested Questions You Can Ask ChemBuddy'));
    });

    test('generateDocumentSummary handles Physical & Analytical Chemistry notes', () {
      const physicalPdfText = """
# Physical Chemistry & Chemical Kinetics
Thermodynamics of Solutions: Gibbs free energy equation ΔG° = ΔH° - TΔS° = -RT ln K.
Electrochemistry: Nernst equation E = E° - (RT/nF) ln Q.
Arrhenius activation energy: k = A e^(-Ea/RT).
Normality and molarity in redox titrations with KMnO4.
""";

      final summary = ChemistryKnowledgeEngine.generateDocumentSummary(physicalPdfText, 'Physical_Chemistry_Ch4.pdf');
      expect(summary, contains('Physical Chemistry & Thermodynamics'));
      expect(summary, contains('Nernst Equation'));
      expect(summary, contains('Gibbs Free Energy'));
      expect(summary, contains('Suggested Questions'));
    });
  });
}
