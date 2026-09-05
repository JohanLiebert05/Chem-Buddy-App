import 'package:flutter_test/flutter_test.dart';
import 'package:chem_buddy/data/services/chemical_name_database.dart';

void main() {
  group('Polymer and Biomolecule Classification & Molar Mass Tests', () {
    test('Sodium alginate is classified as biopolymer with repeat unit mass', () {
      final res = ChemicalNameDatabase.resolve('Sodium alginate');
      expect(res.isPolymerOrBiomolecule, isTrue);
      expect(res.compoundName, equals('Sodium alginate'));
      expect(res.repeatUnitFormula, equals('(C6H7NaO6)n'));
      expect(res.molarMass, closeTo(198.11, 0.1));
      expect(res.polymerExplanation, contains('variable degree of polymerization'));
    });

    test('Alginic acid and derivatives are recognized as biopolymers', () {
      final res = ChemicalNameDatabase.resolve('alginic acid');
      expect(res.isPolymerOrBiomolecule, isTrue);
      expect(res.repeatUnitFormula, equals('(C6H8O6)n'));
      expect(res.molarMass, closeTo(176.12, 0.1));
    });

    test('Polysaccharides (Cellulose, Starch, Glycogen, Chitosan) are properly classified', () {
      final cellulose = ChemicalNameDatabase.resolve('cellulose');
      expect(cellulose.isPolymerOrBiomolecule, isTrue);
      expect(cellulose.repeatUnitFormula, equals('(C6H10O5)n'));
      expect(cellulose.molarMass, closeTo(162.14, 0.1));

      final starch = ChemicalNameDatabase.resolve('starch');
      expect(starch.isPolymerOrBiomolecule, isTrue);
      expect(starch.repeatUnitFormula, equals('(C6H10O5)n'));

      final chitosan = ChemicalNameDatabase.resolve('chitosan');
      expect(chitosan.isPolymerOrBiomolecule, isTrue);
      expect(chitosan.molarMass, closeTo(161.16, 0.1));
    });

    test('Synthetic polymers (Polyethylene, Polystyrene, PVC, Nylon 6,6, PMMA) are recognized', () {
      final pe = ChemicalNameDatabase.resolve('polyethylene');
      expect(pe.isPolymerOrBiomolecule, isTrue);
      expect(pe.repeatUnitFormula, equals('(C2H4)n'));
      expect(pe.molarMass, closeTo(28.05, 0.1));

      final ps = ChemicalNameDatabase.resolve('polystyrene');
      expect(ps.isPolymerOrBiomolecule, isTrue);
      expect(ps.repeatUnitFormula, equals('(C8H8)n'));
      expect(ps.molarMass, closeTo(104.15, 0.1));

      final nylon = ChemicalNameDatabase.resolve('nylon 6,6');
      expect(nylon.isPolymerOrBiomolecule, isTrue);
      expect(nylon.molarMass, closeTo(226.32, 0.1));
    });

    test('Proteins and Nucleic Acids (BSA, Hemoglobin, DNA, RNA) have macromolecule data', () {
      final bsa = ChemicalNameDatabase.resolve('BSA');
      expect(bsa.isPolymerOrBiomolecule, isTrue);
      expect(bsa.compoundName, equals('Bovine Serum Albumin'));

      final dna = ChemicalNameDatabase.resolve('DNA');
      expect(dna.isPolymerOrBiomolecule, isTrue);
      expect(dna.molarMass, closeTo(330.0, 1.0));
    });

    test('Discrete small molecules continue to parse exact fixed formulas', () {
      final benzoic = ChemicalNameDatabase.resolve('benzoic acid');
      expect(benzoic.isPolymerOrBiomolecule, isFalse);
      expect(benzoic.canonicalFormula, equals('C7H6O2'));
      expect(benzoic.molarMass, closeTo(122.12, 0.1));

      final aspirin = ChemicalNameDatabase.resolve('aspirin');
      expect(aspirin.isPolymerOrBiomolecule, isFalse);
      expect(aspirin.canonicalFormula, equals('C9H8O4'));
      expect(aspirin.molarMass, closeTo(180.16, 0.1));

      final cuso4 = ChemicalNameDatabase.resolve('CuSO4·5H2O');
      expect(cuso4.isPolymerOrBiomolecule, isFalse);
      expect(cuso4.molarMass, closeTo(249.68, 0.2));
    });

    test('Query for Sodium Alginate does not falsely match Sodium', () {
      final res = ChemicalNameDatabase.resolve('Sodium Alginate');
      expect(res.canonicalFormula, isNot(equals('Na')));
      expect(res.molarMass, isNot(closeTo(22.99, 0.1)));
      expect(res.isPolymerOrBiomolecule, isTrue);
    });
  });
}
